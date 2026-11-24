# The executor contract

**This file is the contract's single source.** Its one other rendering is the block in
[hosted-handoff.md](hosted-handoff.md), which restates these five obligations
as five numbered paragraphs in the same order, in the guest's voice. Change an obligation here and
change its paragraph there in the same edit.

Whatever builds a PR owes exactly five things:

1. **Stay on the branch the host cut**, and create no others.
2. **Leave the targeted tests green at the boundary, with a passing test for the PR's behavior.**
   The *targeted tests* are the PR's own tests plus the existing tests nearest the code it changed,
   picked with the runner's own file or directory filter. The executor never owes a full-suite run:
   that is the host's, once per PR, in the background
   ([background-suite.md](background-suite.md)). The test is not optional
   even for `direct`: the boundary ticks a criterion only where a passing test satisfies it. **For a
   `refactor` or `scaffolding` PR** the obligation is instead that the existing tests over the
   restructured code stay green. **For a `yolo` PR** the passing test is replaced by its acceptance
   proofs passing — agent-run or user-confirmed — and those tick its criteria. Those two carve-outs
   are the only ones.
   **The regression net is the exception: never edit a net spec.** The net specs the host names are
   part of the targeted tests, and one that turns red means this PR breaks another consumer: fix the
   code, or hand back `blocked`.
   **An earlier PR's test this PR breaks is the executor's to update** — routine, since each PR
   builds only what it needs. Change its **fixture** or call site wherever that absorbs it: an
   expectation edited to agree with the new behavior stops pinning its own PR's rule. Otherwise
   narrow the expectation to that PR's rule, never weaker. If this PR replaces the rule, delete the
   test, and if it ticked a criterion, make sure this PR's test still satisfies it. Commit the
   update alone, before the work that needs it, and report it.
3. **Build only its own PR, and write neither the plan nor the ledger.** Work the plan gives to a
   later PR is not this executor's to do, however much its own refactoring step wants it — report
   it and move on; doing it here empties that PR. Preserve existing behavior unless this PR's
   behavior sentence changes it; the structure behind it evolves as this PR needs.
4. **Commit its work on that branch.** The boundary squashes *commits*, not worktree state: an
   uncommitted PR fails the squash's `git commit` with "no changes added to commit".
5. **Hand back before the squash, with a report.** No boundary review, PR or squash of its own. A
   skill-shaped guest writes the report the block describes, and on `handed back` then makes a last
   commit removing any file of its own it committed, such as a state file — nothing of the guest's
   ships.
   **One exception: a guest whose own flow reviews its diff, iterating until clean** (`slice-tdd`
   today). It reports its review, and the boundary then skips its own (the boundary's step 2). Such a guest
   gets the adapted block in [hosted-handoff.md](hosted-handoff.md).

Obligations 2 and 4 describe a *finished* PR. **The one sanctioned way not to finish one is to hand
back `blocked`**: the executor gets its tests back to green, commits whatever complete work it has,
and reports `blocked: <what stopped it>`. A PR that needs splitting and a strategy with no move on
it are both this one outcome. The host owns what happens next.

## Which shape carries which obligation

All five are owed on every PR; what changes with the executor's shape is who carries each. Where
an obligation cannot bind the executor it does not lapse — it becomes the host's.

| | A skill-shaped guest | `direct` — you are the executor | `hand` / `navigator` — the user is |
|---|---|---|---|
| **1** branch | In the block. | Yours. | Tell the user the branch is cut; at the boundary, check none appeared — `git branch --list`. |
| **2** green + test | In the block. | Yours, test included. | The bar the user's work must meet: say so at handoff, confirm it at the boundary's step 1. A hosted `navigator` coaches to it. |
| **3** own PR only | In the block. | Yours. | State the behavior sentence at handoff, so a later PR's work is not done here. |
| **4** commit | In the block. | Yours. | **Yours**: confirm the work is committed, and commit it if not (SKILL.md, *Hand off*). |
| **5** hand back | In the block, with its report. | No hand-back act: write the `direct — handed back` line yourself, and run no squash, review or PR until the boundary's steps do. | The user says the PR is done; you write the line and run the boundary. A hosted `navigator` runs no review or squash of its own. |
