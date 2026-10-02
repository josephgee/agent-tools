# Resuming a plan

Read when Startup finds a plan to resume, before anything else in the session. Section links point
into SKILL.md.

**If resuming:** read the plan; report the feature, the current slice and its position, its
strategy and attempts so far, any slice whose **Suite** is still `running:` (read its status
file now, per [references/background-suite.md](background-suite.md)), remaining
criteria and slices, and the current hypothesis; confirm the checked-out branch matches. **Confirm the plan is still excluded** —
`git -C "$(git rev-parse --show-toplevel)" check-ignore -q <plan-path>` — and if it is not, append
it with the same one-liner Setup uses, before handing off to any guest; the next `git add -A` would
otherwise commit it. Give `<plan-path>` repo-root-relative and under the name the file actually has
now, which a rename may have changed. Without the `-C`, a repo-root-relative path checked from a
subdirectory returns a false negative and you append a duplicate line.

**If the Session block's Base branch or Test runner is still a placeholder, Setup never ran** —
and the alignment gate was never passed either, since Setup follows it. The plan on disk is a draft
the user never agreed to; it is written before the gate on purpose, so a session that ended in
between leaves exactly this. Present the feature, criteria, hypothesis and slices at the alignment
gate as if newly drafted, then run [Setup](../SKILL.md#setup), before any of the routing below. Do not cut a
branch from a placeholder base.

**A shipped slice whose Suite reads `red:` comes first**: a reopen was interrupted, and its fix
may sit uncommitted on that slice's branch. Finish it —
[references/background-suite.md](background-suite.md), *Red after the squash*, whose
steps say how to tell where it stopped — before the branch check or any routing below.

**The current slice** is the first slice in list order that is not `shipped`. If every slice is
shipped, go to [Feature complete](../SKILL.md#feature-complete) instead. The branch you expect to be on is its
own for an `in progress` slice, and the previous slice's — the base branch, for slice 01 — for a
`planned` one. If the worktree disagrees, say so and ask which is right before touching anything: a
plan and a worktree that disagree is the one state no recipe here is safe in.

Then re-enter [Running a slice](../SKILL.md#running-a-slice) by that slice's status:

- **`planned`** — step 1, choose the strategy.
- **`in progress`** — read its **newest Attempts line**; the status alone does not say where you
  are:
  - `<strategy> — in progress` (with or without a `: <note>` the host left there) → step 3, hand
    off to the strategy already recorded and continue that line. Its branch exists and its
    strategy is chosen; re-asking either would re-cut a live branch and discard the answer.
  - `<strategy> — handed back` → **step 4, the slice boundary** — the guest already finished.
    Check first whether the squash ran, with `git log --oneline <previous-slice-branch>..HEAD`
    (`<previous-slice-branch>` is the previous slice's branch, the base branch for slice 01), and
    read the commits' **subjects**, not just the count:
    - one commit whose subject is the slice's behavior sentence → the squash ran; resume at the
      boundary's step 5;
    - one commit with any other subject → that is the guest's own work (a `direct` or `hand` slice
      is one commit by construction), or the host's own *Running a slice* step-2 update to an
      earlier slice's test, which means the guest built nothing. It is the update when the
      Attempts line notes one and the commit's diff touches only that test. The guest's work →
      the boundary from step 1; the update → *Running a slice* step 3, hand off. Counting commits
      alone would skip the design review and the user's approval and ship the slice under the
      guest's commit message;
    - more than one → the ordinary `tdd` handback, squash not yet run: the boundary from step 1;
    - **none at all** → the guest built nothing, or built it and never committed: re-enter at
      *Running a slice* step 3. Re-invoking a guest with commits present would rerun a slice
      already built.

    The count cannot tell a re-entry from a first pass, so when you re-enter the boundary this way,
    say at its step 3 that the slice may already have been presented and this review is a re-run
    after an interruption. Do not silently ask the user to approve the same slice twice.
  - `atdd — paused: design agreed` → the previous slice's run was still going when `atdd`
    reached code. Wait on it ([references/background-suite.md](background-suite.md),
    *Waiting on it*), then *Hand off*'s resume: any earlier-test update step 2 held back, a
    fresh `atdd — in progress` line, and the block without the pause paragraph.
  - `<strategy> — blocked: …` →
    **[A guest that hands back blocked](../SKILL.md#a-guest-that-hands-back-blocked)**. Deal with what
    stopped it first; re-invoking it on an unchanged slice stops it in the same place.
  - `<strategy> — abandoned: …` followed by a new strategy's open line → **step 3**. The branch
    already exists and the new strategy runs on it: **do not re-cut it**. The abandon appends that
    open line only after redoing the earlier-slice test update, so the branch should already be
    green — confirm the update noted on the abandoned line is present, and redo it if it is not.

**Before re-entering at step 3, check the tree is clean** — `git -C "$top" status --short`, with
`top=$(git rev-parse --show-toplevel)`. The handoff block promises the next guest a clean tree and
tells it to skip the preflight where it would have noticed otherwise, so a dead guest's uncommitted
work becomes the new guest's first `git add -A`. If anything outside the plans directory shows,
show the user the changed files and ask whether to keep them — commit them on the branch yourself
first — or discard them with the restore and clean in [abandon.md](abandon.md). Never hand off over a dirty
tree.
