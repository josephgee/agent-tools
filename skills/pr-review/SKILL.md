---
name: pr-review
description: "Reviews someone else's pull request for defects, design and tech debt, holding it to a leave-it-better standard: debt the PR adds, and debt already sitting in the code it changes, are both the author's to fix now; debt elsewhere is not theirs. Sorts findings into those three buckets, then walks the user through them one at a time while the user writes their own feedback. Use when the user is asked to review a PR. Not for reviewing the user's own changes (use design-review)."
compatibility: "Requires the design-review skill, and design-principles, which design-review itself requires, with no bundled fallback. Requires git, the gh CLI authenticated for the PR's host, and subagent delegation."
metadata:
  soft-deps: design-review design-principles
---

# PR Review

Review a PR the way the user reviews their own work: code a change touches is left better than it
was found. The PR adds no debt, and it does not leave debt in what it changes for later.

You review and walk the user through what you found. The user writes all feedback and posts it.
Never post, comment, approve or request changes on the PR yourself.

## 1. Get the PR without touching the user's tree

The user may be mid-work in this repo, so do not run `gh pr checkout`. Read the PR and find the
remote that hosts it (`origin` is a fork when the user works from one; then it is usually
`upstream`):

```bash
gh pr view <n> --json number,title,body,baseRefName,headRefOid,files
gh repo view --json nameWithOwner -q .nameWithOwner   # match this against:
git remote -v
```

The review lives at a fixed path, so any later command can rebuild it from the PR number alone:
`<review> = ${TMPDIR:-/tmp}/pr-review-<repo-dir-name>-<n>`, the worktree, and `<review>.md`, the
findings file. Write `<review>` out literally in every command; shell variables do not survive
between calls.

Remove any leftover from an earlier review, then create the worktree:

```bash
git worktree remove --force <review>; rm -f <review>.md
git fetch <remote> <baseRefName> "pull/<n>/head"
git worktree add --detach <review> <headRefOid>
```

If a fetch fails, stop and tell the user. Do not review a different ref. The worktree is the PR
as it stands: read it, never edit it.

Read the PR description. If it states the PR's intent, judge the design against that intent.

## 2. List the touched units

A **touched unit** is the smallest named unit that encloses a changed hunk in the PR's diff
(`git -C <review> diff <remote>/<baseRefName>...HEAD`). That is the function or method, or the
type when the change is to its fields or signature. In test files it is the test function. A
hunk inside no named unit, such as an import or a module-level constant, is its own unit. Write
the list as `file: unit` lines. Steps 3 and 4 depend on it.

## 3. Three reviews, in parallel

Run three fresh subagents, each with `<review>` as its working directory. Tell each to read code
only there, never in the user's checkout, and to report every location as `file:line` relative
to `<review>`. The first two invoke the `design-review` skill, run non-interactively and return
ranked findings:

- **Diff review**: scope `a PR`, `<n>`.
- **Touched-code review**: scope `a path`, the touched files. Give it step 2's list and tell it
  to report only findings inside those units.
- **Defect review**: give it the base ref, the PR description and step 2's list. Prompt: "Find
  functional defects in this PR: wrong results, unhandled errors or edge cases, broken contracts
  with callers, races, resource leaks, security holes. Read callers and callees of each touched
  unit, not only the diff, and include defects already present inside the touched units. Report
  each as `file:line`, the defect, and a concrete failure scenario: an input or state and the
  wrong outcome it produces. No scenario, no finding. Do not report design or style."

Running them in subagents keeps the sweeps out of this session. This session keeps only the
findings and the user's conversation.

## 4. Verify, merge and sort

Re-read the code at each defect's location and trace its failure scenario. Drop any defect whose
scenario does not hold there. A false bug report costs the author time and the user credibility.

Merge the two design reviews: findings on the same `file: unit` naming the same problem are one
finding.

Sort each surviving finding by checking its location at base,
`git -C <review> show <remote>/<baseRefName>:<file>`:

- **Added**: the problem is absent at base. The PR introduced it, so fixing it is the author's
  job in this PR.
- **Kept**: the problem is present at base inside a touched unit, even if the PR edited lines
  within it. The author is changing this code, so fixing it is also their job in this PR. Do not
  downgrade it because the author didn't cause it.
- **Nearby**: outside every touched unit. Only the defect review produces these, from callers and
  callees. Never present one as feedback for the author.

Also note any debt the PR **removes** from a touched unit, one line each. The user may want to
credit it, and it counts toward whether the PR leaves the code better.

Write `<review>.md`: first this header, verbatim, then the Added and Kept findings in step 6's
order, one checkbox each with its bucket, `file:line`, and its scenario or catalog name,
severity and fix direction.

```markdown
## Rules in force
- Never post, comment, approve or request changes on the PR.
- Answer questions by re-reading the code in the worktree, never from this file's summary.
- Do not draft feedback unless the user asks. The user writes it.
- Tick a concern's box when the user moves on.
- When the user ends the review: `git worktree remove <review>` and delete this file.
```

## 5. Overview

Give a one-line verdict: does the PR leave the code it touches better, the same, or worse? Then
give the count in each bucket (defects and design findings separately), the removed-debt lines,
and the Nearby lines for the user to file elsewhere if they want. Do not list the Added and Kept
findings yet; step 6 takes them one at a time.

## 6. Walk through the concerns

At the top of each concern, re-read `<review>.md`. It is on disk, so it survives compaction, and
re-reading puts its rules back in front of you.

Take the first unticked concern. Show the code at `file:line` from the worktree, then the finding:
its bucket and, for a defect, its failure scenario; for a design finding, its catalog name,
severity and the direction of a fix. Suggest `blocking` for a defect or a medium or high design
finding, and `nit` for a low one. Then stop for the user.

The user decides what each concern is worth and writes any feedback themselves. Answer their
questions by reading the code, and say so when the finding does not survive a question. Go on to
the next concern when the user says to.

The review ends when the user says so. Then remove the worktree and the findings file.
