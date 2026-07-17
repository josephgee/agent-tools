# TDD State File Format

This is the format for `tdd-state.md`, maintained in the project root. The file is committed with each completed cycle alongside the code changes, creating a rollback point at every stage. It is deleted at the end of the feature and the TDD commits may be squashed.

---

```markdown
# TDD Session State

## Session
- **Test runner**: `<command>`
- **Started**: YYYY-MM-DD
- **Last updated**: YYYY-MM-DD

## Feature

<One or two sentences: what is being built, what problem it solves, and what is out of scope.>

## Acceptance Criteria
- [ ] <criterion>
- [x] <criterion> — satisfied in cycle N
- [ ] <criterion>

## Design Hypothesis

**Current (vN)**: <prose description of the current design: key types, modules, or
functions; how responsibilities divide; how the pieces connect>

### History
- **v1** — <description> — Revised after cycle N: <reason learned from the cycles>.
- **v2** — <description> — Abandoned after cycle N: <reason>.

## Plan

Ordered cycle sequence. E2E flow first, then replace stubs with real behavior, then add functionality, then edge cases. Update as learning changes the approach — significant changes (dropping items, major resequencing) require surfacing to the user before proceeding.

- [ ] E2E: <describe the full end-to-end flow, even if some behavior is stubbed underneath>
- [ ] <replace stub / add real behavior: describe>
- [ ] <additional functionality: describe>
- [ ] <edge case or error condition: describe>
- [x] <completed behavior>
- [-] <dropped behavior> — no longer needed: <reason>

## Cycle Log

### Cycle N
- **Test**: <test name or description>
- **Verified**: <behavior this test confirmed>
- **Learned**: <design insight from this cycle, or "no surprises">
- **Hypothesis**: <what changed in the hypothesis, or "none">

## Backlog

Items discovered during cycles that need future attention. Every item must reach a closed state before the feature is declared complete.

- [ ] <description> — noted in cycle N
- [x] <description> — resolved in cycle N: <how it was addressed>
- [-] <description> — dismissed: <reason it does not need to be done>
- [>] <description> — deferred: <reason> / <where it is going — follow-up story, known backlog, future decision point>

## Current Position
- **Phase**: <RED | GREEN | REFACTOR | between-cycles>
- **Cycle**: N
- **Active test**: <test name or description — required when phase is RED or GREEN>
- **Notes**: <anything needed to resume mid-cycle, if applicable>

## Driver Status
- **Status**: <in-progress | needs-user-input | feature-complete>
- **Reason**: <required when Status is needs-user-input — one sentence, the specific decision needed. Blank otherwise.>
```

---

## Notes on Use

- **Hypothesis history** is append-only. Never delete prior versions — the history of what was learned and why the design changed is part of the record.
- **Cycle log** is append-only. Add a new `### Cycle N` block after each completed REFACTOR.
- **Current Position** is the resume point. It must be accurate at all times. Update it at each phase transition and at the start of RED when the active test is chosen.
- **Acceptance criteria** use `[ ]` / `[x]` markdown checkboxes. Mark a criterion satisfied (with cycle number) as soon as a passing test covers it.
- **Plan** uses `[ ]` open, `[x]` completed, `[-]` dropped (with reason). Keep completed and dropped items in place — they show where the plan was and how it evolved.
- **Committed with each cycle.** Each git commit contains the code changes for that cycle plus the updated state file. Rolling back to a commit restores both the code and the full session state at that moment.
- **Backlog** uses four states: `[ ]` open, `[x]` resolved (with how), `[-]` dismissed (with reason), `[>]` deferred (with reason and destination). Every item must reach a closed state before the feature is declared complete.
- Dismissed items require a real reason — "dismissed: not needed" is not a reason.
- Deferred items must be explicitly surfaced to the user and acknowledged before the feature is declared complete. The user must know what real work is being moved out.
- **Driver Status** defaults to `in-progress` and is kept current at every phase transition, the same as Current Position. It only changes to `needs-user-input` (a decision point was reached that requires the user, with a one-sentence `Reason`) or `feature-complete` (all three completion conditions in the skill's Progress section are met). It matters most when cycles are executed by a delegated subagent (see the skill's "Delegated Execution" section) — a driver loop reads it to decide whether to keep going, stop and surface something, or wrap up — but keep it accurate regardless of execution mode, so switching modes mid-session works without reconstructing state.
