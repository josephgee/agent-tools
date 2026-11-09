# Resuming a build

Read when Startup finds a ledger, before anything else in the session. Section links point into
SKILL.md.

Read the ledger and the plan its Session names. **Confirm the plan still reads `Status: agreed`
and its criterion IDs match the ledger's Criteria section.** If either fails, the plan changed under
the build: stop, show the user the difference, and ask how to reconcile it before anything else.

Report the feature, the current PR and where it
stands, its strategy and attempts so far, any PR whose **Suite** is still `running:` (read its
status file now, per [background-suite.md](background-suite.md)), the criteria still unticked and
the PRs remaining. **Confirm the plan, the ledger and the reports are still excluded** —
`git -C "$top" check-ignore -q <path>` for the plan, the ledger and the current PR's report path
`<plans-dir>/handback-<feature-slug>-<NN>.md` (it need not exist), with `top=$(git rev-parse
--show-toplevel)` and repo-root-relative paths — and append only the line that is missing, as
Setup's one-liner writes it, before handing off to any guest. Without the `-C`, a check from a subdirectory returns a
false negative and you append a duplicate.

**A shipped PR whose Suite reads `red:` comes first**: a reopen was interrupted, and its fix may sit
uncommitted on that PR's branch. Finish it — [background-suite.md](background-suite.md), *Red after
approval* — before anything below.

**The current PR** is the first PR in the plan's list order not `shipped` in the ledger. If every
PR is shipped, go to [Feature complete](../SKILL.md#feature-complete). The branch you expect to be
on is its own for an `in progress` PR, and the previous PR's — the base branch, for PR 01 — for one
`chosen` or not started. If the worktree disagrees, say so and ask which is right before touching anything.

**A report at the current PR's report path comes next**: the guest finished, and the session ended
before the report was deleted. If the newest Attempts line is still open, copy it per
[Reading a report](../SKILL.md#reading-a-report); if that line is already closed with the report's
Outcome, it was copied — just delete it. Then route by the newest line.

Then re-enter [Running a PR](../SKILL.md#running-a-pr) by the ledger:

- **No entry** — step 1, choose the strategy.
- **`chosen`** — step 2, for the strategy already recorded; do not re-ask it. If
  `git branch --list <feature-slug>/NN-<pr-slug>` shows the branch, the session died after cutting
  it: switch to it and set `in progress` instead of cutting it again.
- **`in progress`** — read its **newest Attempts line**:
  - `<strategy> — in progress` → **step 3**, hand off to the recorded strategy again — a guest
    resumes from its own state file. Its branch exists and its strategy is chosen; re-asking either
    would re-cut a live branch and discard the answer.
  - `<strategy> — handed back` → **step 4, the boundary**. Check first whether the squash ran, with
    `git log --oneline <previous-pr-branch>..HEAD`, reading the commits' **subjects**:
    - one commit whose subject is the PR's behavior sentence, **and** the PR has a **Suite** field →
      the squash ran but approval is unrecorded: resume at step 3 after its squash. First run
      `git -C "$top" status --short`: anything there is a review change interrupted before its
      amend — show the user and ask whether to finish it, per *A change before approval* in
      [background-suite.md](background-suite.md), or discard it. Start the run only if Suite does
      not read `green:` or a live `running:`, and re-present;
    - one commit with any other subject, or no **Suite** field → the boundary from step 1;
    - more than one → an unsquashed hand-back: the boundary from step 1;
    - **none at all** → nothing was built or committed: re-enter at step 3.

    When you re-enter the boundary this way, say at its step 3 that the PR may already have been
    presented. Do not silently ask the user to approve the same PR twice.
  - `<strategy> — paused: design done` → wait on the previous PR's run
    ([background-suite.md](background-suite.md), *Waiting on it*), then *Hand off*'s resume: a
    fresh `<strategy> — in progress` line, and the block without the pause paragraph.
  - `<strategy> — blocked: …` →
    **[A guest that hands back blocked](../SKILL.md#a-guest-that-hands-back-blocked)**.
  - `<strategy> — abandoned: …` → the abandon was interrupted before its new strategy was
    recorded. Ask for the new strategy as step 1 does, set **Strategy** and append its
    `in progress` line, then **step 3**. The branch already exists: **do not re-cut it**.

**Before re-entering at step 3, check the tree is clean** — `git -C "$top" status --short`. The
block promises the next guest a clean tree and tells it to skip the preflight that would notice, so
a dead guest's uncommitted work becomes the new guest's first `git add -A`. If anything shows, show
the user and ask whether to keep it — commit it on the branch yourself first — or discard it with
the restore and clean in [abandon.md](abandon.md). Never hand off over a dirty tree.
