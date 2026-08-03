# TDD State File Format

The state file records the whole session: the feature, the PR plan, the design hypothesis as it
evolves, and where you are right now. It is committed with each completed cycle alongside the code
changes, creating a rollback point at every stage.

## Location and name

`<plans-dir>/tdd-<feature-slug>.md`

- **`<plans-dir>`** — whichever of `plans/`, `docs/plans/`, or `.plans/` the repo already has.
  Create `plans/` only if none exists. If more than one exists, ask rather than guessing.
- **`<feature-slug>`** — a short kebab-case name for the effort, derived from the confirmed
  feature definition (`csv-export`, `session-timeout`). Confirm it with the user at the alignment
  gate: it is permanent for the effort and also names the branches (`tdd/<feature-slug>/NN-...`).

Naming the file after the effort is what allows several TDD sessions to run in parallel — on
different branches or in different worktrees — without colliding on a shared path or conflicting
on merge.

---

```markdown
# TDD Session State

## Session
- **Feature slug**: <feature-slug>
- **Test runner**: `<command>`
- **Base branch**: <branch PR 01 is reviewed against>
- **Started**: YYYY-MM-DD
- **Last updated**: YYYY-MM-DD

## Feature

<One or two sentences: what is being built, what problem it solves, and what is out of scope.>

## Acceptance Criteria
- [ ] <criterion>
- [x] <criterion> — satisfied by PR 02
- [ ] <criterion> — partially advanced by PR 02

## Design Hypothesis

**Current (vN)**: <prose description of the current design: key types, modules, or
functions; how responsibilities divide; how the pieces connect>

### History
- **v1** — <description> — Revised after cycle N: <reason learned from the cycles>.
- **v2** — <description> — Abandoned after cycle N: <reason>.

## PR Plan

Ordered sequence of independently reviewable increments. Each delivers observable product
behavior, however small, and merges on its own. See `references/pr-slicing.md` for how to
decompose and re-slice; significant changes (dropping a PR, major resequencing) require surfacing
to the user before proceeding.

### PR 01 — <one-sentence behavior, no "and"> — `ready`
- **Branch**: `tdd/<feature-slug>/01-<pr-slug>` (base: `<base branch>`)
- **Commit**: <sha of the squashed commit, once shipped>
- **Kind**: behavioral
- **Criteria**: advances <which acceptance criteria>
- **Cycles**:
  - [x] <behavior>
  - [x] <behavior>
- **Description**:
  - **What changes**: <the observable behavior>
  - **Not here**: <stubs still in place, edge cases deferred, flags — or "nothing deliberately
    held back">

### PR 02 — <one-sentence behavior> — `in-progress`
- **Branch**: `tdd/<feature-slug>/02-<pr-slug>` (base: `tdd/<feature-slug>/01-<pr-slug>`)
- **Kind**: behavioral
- **Criteria**: advances <which acceptance criteria>
- **Cycles**:
  - [x] <behavior>
  - [ ] <behavior>

### PR 03 — <one-sentence behavior> — `planned`
- **Kind**: refactor — <required reason for any non-behavioral PR>
- **Criteria**: none — restructuring only
- **Cycles**:
  - [ ] <behavior>

### PR 04 — <one-sentence behavior> — `dropped`
- No longer needed: <reason>

## Cycle Log

### PR 02 / Cycle N
- **Test**: <test name or description>
- **Verified**: <behavior this test confirmed>
- **Learned**: <design insight from this cycle, or "no surprises">
- **Hypothesis**: <what changed in the hypothesis, or "none">

## Backlog

Items discovered during cycles that need future attention. Every item must reach a closed state
before the feature is declared complete.

- [ ] <description> — noted in cycle N
- [x] <description> — resolved in cycle N: <how it was addressed>
- [-] <description> — dismissed: <reason it does not need to be done>
- [>] <description> — deferred: <reason> / <where it is going — follow-up story, known backlog,
  future decision point>

## Current Position
- **PR**: NN
- **Phase**: <RED | GREEN | REFACTOR | SHIP | between-cycles>
- **Cycle**: N
- **Active test**: <test name or description — required when phase is RED or GREEN>
- **Notes**: <anything needed to resume mid-cycle, if applicable>

## Driver Status
- **Status**: <in-progress | needs-user-input | pr-ready | feature-complete>
- **Reason**: <required when Status is needs-user-input — one sentence, the specific decision
  needed. Blank otherwise.>
```

---

## Notes on Use

- **Keep the diff quiet.** This file is committed with the work, so it appears in every PR's diff.
  Append cycle log entries, tick checkboxes, and edit Current Position in place. Never re-wrap or
  re-order prose that has not actually changed. A good per-cycle diff is a few added lines and a
  flipped checkbox.
- **PR Plan statuses**: `planned` (not started), `in-progress` (cycles running), `ready` (shipped
  — squashed, described, awaiting the user), `merged`, `dropped` (with a reason). Keep shipped and
  dropped entries in place; they show how the plan evolved.
- **PR `Kind`** is `behavioral` by default. `refactor` or `scaffolding` requires a stated reason —
  every PR is expected to change observable behavior, and the exceptions should be visible.
- **PR descriptions** are written at SHIP and are the source for the commit message body. Fill in
  Branch and Commit as they become real; a `planned` PR has neither yet.
- **Hypothesis history** is append-only. Never delete prior versions — the history of what was
  learned and why the design changed is part of the record.
- **Cycle log** is append-only. Add a new `### PR NN / Cycle N` block after each completed
  REFACTOR. Cycle numbers run continuously across the whole feature, not per PR, so a cycle is
  always unambiguous.
- **Current Position** is the resume point. It must be accurate at all times. Update it at each
  phase transition and at the start of RED when the active test is chosen.
- **Acceptance criteria** use `[ ]` / `[x]` markdown checkboxes. Mark a criterion satisfied (with
  the PR that satisfied it) as soon as a passing test covers it. A criterion advanced by several
  PRs stays open with a note until the last of them lands.
- **Committed with each cycle.** Each git commit contains the code changes for that cycle plus the
  updated state file. Rolling back to a commit restores both the code and the full session state
  at that moment. At SHIP these cycle commits are squashed into the PR's single commit.
- **Backlog** uses four states: `[ ]` open, `[x]` resolved (with how), `[-]` dismissed (with
  reason), `[>]` deferred (with reason and destination). Every item must reach a closed state
  before the feature is declared complete.
- Dismissed items require a real reason — "dismissed: not needed" is not a reason.
- Deferred items must be explicitly surfaced to the user and acknowledged before the feature is
  declared complete. The user must know what real work is being moved out.
- **Driver Status** defaults to `in-progress` and is kept current at every phase transition, the
  same as Current Position. It changes to `needs-user-input` (a decision point requiring the user,
  with a one-sentence `Reason`), `pr-ready` (a PR has shipped and is awaiting handover), or
  `feature-complete` (all completion conditions in the skill's Progress section are met). It
  matters most when cycles are executed by a delegated subagent (see the skill's "Delegated
  Execution" section) — a driver loop reads it to decide whether to keep going, run SHIP, stop and
  surface something, or wrap up — but keep it accurate regardless of execution mode, so switching
  modes mid-session works without reconstructing state.
