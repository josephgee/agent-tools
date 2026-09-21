# PR Workflow

The git mechanics for shipping a feature as a stack of small PRs. Read this at Setup (to create
the stack's first branch), at every SHIP phase in interactive mode, and at Finalization in
one-shot mode.

This file assumes git. If the project doesn't use git, the PR plan still governs *ordering and
sizing* — skip the branch and squash mechanics and treat each PR as a checkpoint where the suite
is green and the work is coherent enough to hand to a reviewer.

**Interactive mode** squashes and hands off one PR at a time, at each SHIP. **One-shot mode** (a
standing go-ahead) runs the whole plan as one linear series of cycle commits and squashes them
into the stack all at once, at Finalization. "During cycles" applies to both; the SHIP section is
interactive-only; Finalization is one-shot-only.

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

**This skill does not push branches or open PRs.** SHIP (or Finalization) ends with a clean commit
per PR on its branch and a written PR description in the state file; publishing is the user's
call. Report the branch name and the base branch so they can open the PR against the right parent
— with GitHub's stacked PR support, setting PR *N*'s base to PR *N-1*'s branch is what makes the
stack work, and GitHub retargets the children automatically as parents merge.

## During cycles

Cycle commits are scaffolding. Commit after each REFACTOR as the skill describes — code, tests,
and the state file together — so every cycle is a rollback point:

```bash
git add -A && git commit -m "tdd: <behavior from THINK>"
```

`git reset --hard <cycle-commit>` restores both the code and the full session state at that
moment, because the state file is committed alongside. The state file is later kept out of the
PR by the squash — see [Keeping the state file out of the PR](#keeping-the-state-file-out-of-the-pr).

In **one-shot mode** the cycle commits are all that exist until Finalization: no per-PR squash,
no per-PR branch, one linear history on the current branch. As you cross each PR boundary, record
the last cycle commit's sha — review-fix commits included — in that PR's plan entry's `Ends at`;
Finalization needs it. The boundary's review pass covers just this PR's range, from the previous
boundary (or the base branch, for the range's first PR) to the tip:

```bash
git diff <PR-(NN-1)-end>...HEAD -- . ':(exclude)<state-file>'
```

(Three-dot, matching SHIP step 1; in this linear history it is the same as two-dot.)

## SHIP: closing out a PR (interactive mode)

Run this only after the PR's last cycle is complete and the full suite is green. One-shot mode
does not run SHIP — see [Finalization](#finalization-one-shot-mode).

**1. PR-level review pass.** Review the whole PR diff, not just the last cycle's changes —
excluding the state file, which is session bookkeeping rather than part of the change:

```bash
git diff <previous-pr-branch>...HEAD -- . ':(exclude)<state-file>'
```

The `.` is required — a lone `:(exclude)` pathspec errors on some git versions.

Per-cycle REFACTOR only sees one cycle at a time, so duplication introduced in cycle 1 and
repeated in cycle 4 survives it. This pass catches that. Apply the checklists in
[refactor-checklist.md](refactor-checklist.md) across the combined diff yourself; the design
review of the same diff is a separate, delegated step — SKILL.md's SHIP section and
[delegated-execution.md](delegated-execution.md) own it, including the scope (same state-file
exclusion) and focus to pass. Any fix here is its own commit, then re-run the suite.

**2. Write the PR description** into the state file's entry for this PR. It rides in the state
file and is stripped out at the squash, so it reaches the reviewer only as the squashed
commit's message body:

- **What changes** — the observable behavior, one or two sentences.
- **Criteria advanced** — which acceptance criteria this PR satisfies or moves forward.
- **What's deliberately not here** — stubs still in place, edge cases left to a later PR,
  anything inert or flag-gated. If this PR has a `Merge safety` line in its plan entry —
  PR 01 as a steel thread, live or inert, and any other PR whose stubs stay flag-gated or
  unmounted — reproduce it verbatim here.
- **Base branch** — the previous PR's branch, or the base branch for PR 01.

**3. Present the PR and stop for review.** Report the one-sentence behavior, branch, base, what
is deliberately left out, and what the next PR does. Wait for the user — this is where they
reslice, reorder, redirect, or call the feature done. The squash below waits on their approval:
it rewrites the PR to one commit and the per-cycle checkpoints stop being reachable by name.

**4. Squash to one commit** once approved. Collapse the cycle commits into the reviewable unit,
and drop the state file so its churn stays out of the PR:

```bash
git reset --soft <previous-pr-branch>   # or the base branch, for PR 01
git reset -- <state-file>               # unstage the state file (git restore --staged also works)
git commit
```

Unstaging leaves the state file untracked in the working tree with its latest content intact —
the next PR's first cycle commit re-adds it. Write a real commit message: subject line is the
PR's one-sentence behavior, body is the description from step 2. The per-cycle checkpoints inside
this PR are gone from `git log` after this (reflog still holds them briefly) — intended, and only
once the user has approved. The squashed commit is code and tests only.

**5. Record the result and start the next PR's branch:**

```bash
git switch -c tdd/<feature-slug>/<NN>-<pr-slug>
```

Update the state file: mark this PR `ready`, record its branch and the squashed commit's sha, set
the next PR `in-progress`, and reset Current Position to its first cycle. A commit cannot contain
its own sha, so this edit stays uncommitted and is picked up (with the state file itself) by the
next PR's first cycle commit. Don't amend the squashed commit to absorb it — that would rewrite a
commit you have already reported as ready.

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

## Finalization (one-shot mode)

One-shot mode reaches the feature-complete conditions with its range of PRs as one linear chain
of cycle commits on a single working branch — no per-PR squash, no per-PR branch. Finalization
turns that chain into the reviewable stack, once, **after** the user's single end-of-feature
review and approval (see SKILL.md's Progress section).

It can also run early, when the user switches back to interactive mid-one-shot: at the next
boundary, present the whole crossed range for review, then on approval run this same procedure
with N = the PR just finished. Normal interactive SHIP resumes from the next PR.

PR **K** is the first PR of the one-shot range: `01` if one-shot from the start, otherwise the PR
in progress when the standing go-ahead was given (its predecessors already squashed on their own
branches). `<base>` is PR K's base — the recorded base branch if K is `01`, else PR K−1's
squashed branch. From the state file you have, for each PR K…N in the range: its behavior, its
description, and `<PR-NN-end>`, the sha of its last cycle commit, recorded as you crossed the
boundary.

**Step 0 — set the state file aside and anchor every boundary.** The on-disk state file is the
newest version (every boundary's description and end sha, plus the end-of-feature review's edits)
and is uncommitted, so it would block the first branch switch. Save the newest copy, discard the
working-tree changes, get off the working branch, then force-plant a branch at each PR's end so
nothing is lost as you rewrite:

```bash
cp <state-file> <state-file>.finalizing                        # newest copy, restored in Step 3
git restore <state-file>                                       # discard the uncommitted edits (saved above)
git switch --detach
git branch -f tdd/<feature-slug>/<NN>-<pr-slug> <PR-NN-end>    # for every NN in K…N
```

Three things are load-bearing: without the `cp`+`restore`, Step 1's `git switch` aborts on the
dirty tracked file; the working branch normally already bears one of these `<NN>-<pr-slug>` names
(PR K's, or `01`'s if one-shot from the start) and sits at the full tip, so a plain `git branch`
errors and `--detach` is needed first; and skipping the `-f` repoint would leave PR K's branch at
the tip — Step 1 would then squash the *entire feature* into PR K.

**Step 1 — squash PR K** onto its base:

```bash
git switch tdd/<feature-slug>/<K>-<pr-slug>
git reset --soft <base>
git reset -- <state-file>          # keep the state file out of the squashed commit
git commit                          # subject: PR K behavior; body: PR K description
```

**Step 2 — for each subsequent PR NN (K+1 … N) in order**, squash this PR's range onto the
previous, now-squashed branch:

```bash
rm <state-file>                     # drop the stale untracked copy so the switch can proceed
git switch tdd/<feature-slug>/<NN>-<pr-slug>          # at <PR-NN-end>
git reset --soft tdd/<feature-slug>/<NN-1>-<pr-slug>
git reset -- <state-file>
git commit                          # subject: PR NN behavior; body: PR NN description
```

Do **not** rebase this PR's cycle commits onto the squashed branch first — every cycle commit
touches the state file and the squashed base deliberately lacks it, so a replay hits a
modify/delete conflict on each one. No replay is needed: the squashed NN−1 tree is
`<PR-NN-1-end>`'s tree minus the state file, so the soft reset stages exactly PR NN's cycle
changes, and the commit lands them on the squashed parent.

**Step 3 — restore and record.** Put the newest state file back, then update each finalized PR's
entry: mark it `ready`, record its branch and squashed sha.

```bash
mv <state-file>.finalizing <state-file>
```

Until this `mv`, `<state-file>.finalizing` is the recovery copy if Finalization dies partway —
its name doesn't match Startup's `tdd-*.md` glob, so it is never mistaken for a session. The
state file ends up untracked, as after any squash, holding its newest content. Hand it to
Cleanup.

**If this was an early Finalization** (mid-one-shot switch back to interactive): create the next
PR's branch from the last squashed branch — `git switch -c tdd/<feature-slug>/<N+1>-<pr-slug>` —
before resuming cycles, since interactive SHIP expects it to exist.

## Keeping the state file out of the PR

This is the one authoritative explanation — other files point here rather than restating it.

The state file is committed with every cycle so that `git reset --hard` on a cycle commit
restores the session state along with the code. It is kept out of what a reviewer sees by two
mechanisms, not by `.gitignore`:

- **Squashes drop it.** Every squash — interactive SHIP's step 4, or each squash in Finalization —
  runs `git reset -- <state-file>` (equivalently `git restore --staged <state-file>`) before the
  commit, so no squashed commit contains it. Each PR is reviewed as the range between squashed
  tips, and no squashed tip has the file, so it appears in no PR diff.
- **Review passes exclude it.** The PR-level `git diff` (SHIP step 1) and the delegated
  design-review scope both add `. ':(exclude)<state-file>'`, so the pre-squash review isn't
  cluttered by its churn.

Because it *is* in the cycle commits, keep its diff quiet — append cycle log entries, tick
checkboxes, edit Current Position and Driver Status in place, never reflow unchanged prose. A
good per-cycle diff for it is a few added lines and a flipped checkbox.

No `.gitattributes` / `linguist-generated` marking is needed: the file never reaches a PR diff,
so there is nothing for a forge to collapse.
