# PR Workflow

The git mechanics for shipping a feature as a stack of small PRs. Read this at Setup (to create
the stack's first branch) and at every SHIP phase.

This file assumes git. If the project doesn't use git, the PR plan still governs *ordering and
sizing* — skip the branch and squash mechanics and treat each PR as a checkpoint where the suite
is green and the work is coherent enough to hand to a reviewer.

## The stack

Each PR is a branch off the previous PR's branch, so review can start on PR 1 while cycles
continue on PR 3.

```
main
 └── tdd/<feature-slug>/01-<pr-slug>
      └── tdd/<feature-slug>/02-<pr-slug>
           └── tdd/<feature-slug>/03-<pr-slug>
```

`<feature-slug>` is the same slug used for the state file, so branches and plan file stay
associated. Numbers are zero-padded and match the PR numbers in the state file's PR Plan.

**This skill does not push branches or open PRs.** SHIP ends with a clean commit on a branch and
a written PR description in the state file; publishing is the user's call. Report the branch name
and the base branch so they can open the PR against the right parent — with GitHub's stacked PR
support, setting PR *N*'s base to PR *N-1*'s branch is what makes the stack work, and GitHub
retargets the children automatically as parents merge.

## During cycles

Cycle commits are scaffolding. Commit after each REFACTOR as the skill describes — code, tests,
and the state file together — so every cycle is a rollback point:

```bash
git add -A && git commit -m "tdd: <behavior from THINK>"
```

`git reset --hard <cycle-commit>` restores both the code and the full session state at that
moment, because the state file is committed alongside.

## SHIP: closing out a PR

Run this only after the PR's last cycle is complete and the full suite is green.

**1. PR-level review pass.** Review the whole PR diff, not just the last cycle's changes:

```bash
git diff <previous-pr-branch>...HEAD
```

Per-cycle REFACTOR only sees one cycle at a time, so duplication introduced in cycle 1 and
repeated in cycle 4 survives it. This pass catches that. Apply the checklists in
[refactor-checklist.md](refactor-checklist.md) across the combined diff yourself; the design
review of the same diff is a separate, delegated step — SKILL.md's SHIP section and
[delegated-execution.md](delegated-execution.md) own it, including the scope and focus to
pass. Any fix here is its own commit, then re-run the suite.

**2. Write the PR description** into the state file's entry for this PR. Do this *before* squashing
so the description is committed with the work:

- **What changes** — the observable behavior, one or two sentences.
- **Criteria advanced** — which acceptance criteria this PR satisfies or moves forward.
- **What's deliberately not here** — stubs still in place, edge cases left to a later PR,
  anything inert or flag-gated. For an inert first PR, say exactly what makes it unreachable.
- **Base branch** — the previous PR's branch, or the base branch for PR 01.

**3. Squash to one commit.** Collapse the cycle commits into the reviewable unit:

```bash
git add -A
git reset --soft <previous-pr-branch>   # or the base branch, for PR 01
git commit
```

Write a real commit message: subject line is the PR's one-sentence behavior, body is the
description from step 2. The per-cycle rollback points inside this PR are gone after this — that
is intended, and it happens only once the PR is done.

**4. Record the result and start the next PR's branch:**

```bash
git switch -c tdd/<feature-slug>/<NN>-<pr-slug>
```

Update the state file: mark this PR `ready`, record its branch and the squashed commit's sha, set
the next PR `in-progress`, and reset Current Position to its first cycle. A commit cannot contain
its own sha, so this edit necessarily stays uncommitted and is picked up by the next PR's first
cycle commit. Don't amend the squashed commit to absorb it — that would rewrite a commit you have
already reported as ready.

## Restacking

When an earlier branch in the stack changes — review feedback, or the parent merged to the base
branch — the descendants need replaying onto the new parent.

**Record the old tip before you change anything:**

```bash
git rev-parse tdd/<feature-slug>/01-<pr-slug>
```

Then amend or merge as needed, and from the **topmost** branch in the stack:

```bash
git rebase --update-refs --onto <new-parent> <old-tip-recorded-above> <topmost-branch>
```

`--update-refs` moves every intermediate branch ref in the stack, so the whole chain follows in
one rebase. `<new-parent>` is the amended branch, or the base branch once the parent has merged.

Do not skip recording the old tip and rebase onto the changed branch directly — the pre-change
commits are no longer ancestors of it, so they get replayed as duplicates.

If any of these branches were already pushed, the restack rewrites them; they need
`git push --force-with-lease`. Say so when reporting, and leave the push to the user.

## Keeping the plan file's diff quiet

The state file is committed with the work, so it appears in every PR's diff. Keep that noise
small — it's the cost of having rollback include session state, and it's only acceptable if
reviewers can skim past it.

- **Append, don't reflow.** Add cycle log entries, tick checkboxes, append hypothesis history.
  Never re-wrap or re-order prose that hasn't actually changed.
- **Edit in place.** Update the existing Current Position and Driver Status lines rather than
  rewriting the section.
- A good plan-file diff for a cycle is a few added lines and a flipped checkbox.

**Optional:** offer to add the plans directory to `.gitattributes` so forges collapse it by
default in the diff view:

```
plans/** linguist-generated=true
```

Offer it at Setup; don't add it unilaterally. It's a repo-wide change, and some teams want the
plan visible in review.
