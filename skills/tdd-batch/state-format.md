# TDD Batch State File Format

The state file records the whole session: the feature, the PR plan, the design hypothesis as it
evolves, the current batch, and where you are right now. It rides along in commits so that
rolling back to a commit restores code and session state together. It is kept out of every PR
diff by the squash, not by `.gitignore` — `references/pr-workflow.md` ("Keeping the state file
out of the PR") is the authoritative explanation.

## Location and name

`<plans-dir>/tddb-<feature-slug>.md`

- **`<plans-dir>`** — whichever of `plans/`, `docs/plans/`, or `.plans/` the repo already has.
  Create `plans/` only if none exists. If more than one exists, ask rather than guessing.
- **`<feature-slug>`** — a short kebab-case name for the effort, derived from the confirmed
  feature definition (`csv-export`, `session-timeout`). Confirm it at the alignment gate: it is
  permanent and also names the branches (`tddb/<feature-slug>/NN-...`).

The `tddb-` prefix and the `# TDD Batch Session State` heading are what keep these sessions
distinct from the `tdd` skill's `tdd-*.md` / `# TDD Session State` files. The two flows are not
interchangeable mid-effort: never resume one skill's state file with the other. Naming files
after the effort is also what lets several sessions run in parallel without colliding.

---

```markdown
# TDD Batch Session State

## Rules in Force

Copied verbatim at creation. Re-read at the start of every THINK, at every milestone commit in
GREEN, when dropping to the ladder, and at the start of each REVIEW round. Never edited or
summarized.

- Every batch test verified **individually** against the raising skeleton: fails on its
  assertion or expected effect, never on an import or fixture error. One that passes is broken.
- Skeleton stubs **raise** — never a body returning `None`/`0`/empty.
- Write nothing the batch does not demand.
- Never touch a test in GREEN outside the amendment protocol: halt, state the defect, amend,
  re-verify, commit it alone.
- Milestone commit = prior suite green + passing batch subset only grew + that subset named.
  Never a long red stretch with nothing committed.
- Pressure log at every milestone: ugliest thing written, most annoying test. "Nothing" is not
  a legal answer to a superlative.
- Log each flat run (no batch test newly passed) here; the runs after an amend or refactor
  commit are exempt. At three: discard — restore all but this file, log what entangled.
- Start every refactor step from a clean tree (apart from this file), with no flat lines
  pending; commit each green step.
- REVIEW ends with the pressure log empty — fixed, dismissed with a reason, or backlogged.
- Both per-PR reviews go to a fresh subagent, always.
- A batch never spans more than one planned PR. Never execute a stale plan item.
- Suite green at every boundary. Squash only on the user's approval.

## Session
- **Feature slug**: <feature-slug>
- **Test runner**: `<command>`
- **Base branch**: <branch PR 01 is reviewed against>
- **Started**: YYYY-MM-DD
- **Last updated**: YYYY-MM-DD

## Feature

<One or two sentences: what is being built, what problem it solves, what is out of scope.>

## Acceptance Criteria
- [ ] <criterion>
- [x] <criterion> — satisfied by PR 02
- [ ] <criterion> — partially advanced by PR 02

## Design Hypothesis

**Current (vN)**: <key types, modules, or functions; how responsibilities divide; how the
pieces connect>

### History
- **v1** — <description> — Revised after PR 02: <what was learned that drove it>.
- **v2** — <description> — Abandoned after PR 03: <reason>.

## PR Plan

Ordered sequence of independently reviewable increments, each delivering observable product
behavior. See `references/pr-slicing.md` — and the general doctrine it points to — for how to
decompose and re-slice. Dropping a PR or
major resequencing surfaces to the user first.

### PR 01 — <one-sentence behavior, no "and"> — `ready`
- **Branch**: `tddb/<feature-slug>/01-<pr-slug>` (base: `<base branch>`)
- **Ends at**: <sha of this PR's last commit, REVIEW fixes included — recorded at the
  boundary; Finalization needs it in one-shot mode>
- **Commit**: <sha of the squashed commit, once shipped/finalized>
- **Kind**: behavioral
- **Criteria**: advances <which acceptance criteria>
- **Merge safety**: live | inert: <what makes it unreachable> — required on PR 01 when it is a
  steel thread, and on any other PR whose stubs are flag-gated or otherwise unreachable; set
  when the PR is planned, copied into the description at REVIEW
- **Batch**:
  - [x] <behavior> — `<test name>`
  - [x] <behavior> — `<test name>`
- **Review rounds**: 2 (round 2 triggered by `structural-if-fixed` fix: <what>)
- **Replan walk**: <PR 01 only, and always present there: what the walk changed, or "plan stands">
- **Description**:
  - **What changes**: <the observable behavior>
  - **Criteria advanced**: <which>
  - **Not here**: <stubs still in place, edge cases deferred, flags — or "nothing deliberately
    held back">
  - **Merge safety**: <if this PR has one: live, or inert and what makes it unreachable>
  - **Base**: <branch>

### PR 02 — <one-sentence behavior> — `in-progress`
- **Branch**: `tddb/<feature-slug>/02-<pr-slug>` (base: `tddb/<feature-slug>/01-<pr-slug>`)
- **Kind**: behavioral
- **Criteria**: advances <which>
- **Batch**:
  - [x] <behavior> — `<test name>`
  - [ ] <behavior> — `<test name>`

### PR 03 — <one-sentence behavior> — `planned`
- **Kind**: refactor — <required reason for any non-behavioral PR>
- **Criteria**: none — restructuring only

### PR 04 — <one-sentence behavior> — `dropped`
- No longer needed: <reason>

## Current Batch

The batch for the PR in progress. Rewritten wholesale at each THINK; it describes one PR only.

- **Interface sketch**: <names, signatures, types, errors the batch is written against>
- **RED verification** (recorded at RED step 3, one row per test):
  - `<test name>` — fails on assertion: <what was missing> ✓
  - `<test name>` — fails on expected effect: <what was missing> ✓
- **RED review triage**: <findings acted on now, and dismissals with reasons>

## Pressure Log

Intra-PR only. Appended during GREEN (at each milestone, whenever a smell bites, and at every
flat run — a full-suite run in which no batch test newly passes, SKILL.md's convergence
tripwire being the authority on what counts; its counter lives here because GREEN records
nothing else, and a `count reset` line is written only when a newly passing test ends a flat
run), drained to empty at REVIEW — every entry ends as a fix, a dismissal with a reason, or a
backlog item. It never outlives the PR; the Backlog below is the only cross-PR notebook.

- flat run 2 of 3 — nothing new passing
- count reset — `<test name>` now passing
- <ugliest thing / most annoying test — one line> — **steer now**: <what was done>
- <one line> — **hold**: <why it waits for REVIEW>
- <one line> — **held → backlog**: <entry it became>
- <what entangled> — **discarded**: <restored to <sha>; drains to the PR Log's Discarded>

## PR Log

### PR 02
- **Behaviors delivered**: <the batch, one line>
- **Learned**: <design insight from this pass, or "no surprises">
- **Hypothesis**: <what changed, or "none">
- **Discarded**: <experiments thrown away and what entangled them, or "none">
- **Reviews**: RED test-set — <headline findings>; REVIEW whole-diff — <headline findings>,
  <N> round(s)

## Backlog

Items discovered during passes that need future attention. Every item must reach a closed state
before the feature is declared complete.

- [ ] <description> — noted in PR 02
- [x] <description> — resolved in PR 03: <how>
- [-] <description> — dismissed: <reason it does not need doing>
- [>] <description> — deferred: <reason> / <where it is going>

## Current Position
- **PR**: NN
- **Phase**: <THINK | MAKE-ROOM | RED | GREEN | REVIEW | boundary>
- **Notes**: <anything needed to resume, if applicable — in GREEN this stays empty by design;
  the last milestone commit is the position>

## Driver Status
- **Status**: <in-progress | needs-user-input | pr-ready | feature-complete>
- **Reason**: <required when Status is needs-user-input — one sentence, the specific decision
  needed. Blank otherwise.>
```

---

## Notes on Use

- **Rules in Force is fixed text.** Written once, verbatim from the block above, when the file is
  created; never rewritten, trimmed, or re-derived from the skill afterwards — a header that
  drifts is worse than none. It exists because the skill body lives in the compressible part of
  the context and this file does not: re-reading it both survives compaction and moves the rules
  back to the end of the context, where attention is strongest. It is re-read at **four**
  points, because one pass covers a whole PR: at THINK; at every milestone commit in GREEN —
  GREEN is the longest phase, and the rules it most needs (the amendment protocol, the milestone
  definition, the discard rules) would otherwise be read once, before RED, and not again until
  the next PR; at the drop to the ladder, the one stretch of GREEN with no milestone commits;
  and at the start of each REVIEW round, where every delegated report lands in context. All
  four are *reads*; GREEN stays dark for writes apart from pressure-log appends. Keep the
  header short — it is re-read often. On resume, a header that is missing or differs from the
  block above is replaced wholesale (SKILL.md, Startup).
- **Keep the diff quiet.** Append entries, tick checkboxes, edit Current Position in place.
  Never re-wrap or re-order prose that has not changed.
- **State-file writes never commit alone**, except Setup's `begin`. They ride the next commit
  that already exists (`red batch`, a milestone, a REVIEW fix) — Preflight and plan revisions
  included. At a PR boundary there is no next commit: the end-of-REVIEW write stays
  uncommitted, and the squash or the next pass's first commit picks it up.
- **`Discarded` is the only trace of a thrown-away experiment.** The discard leaves no commit, so
  the PR Log entry is what shows a discard happened and why. `none` there means none did.
- **Write points are per-phase, not per-test.** End of THINK, end of RED, end of REVIEW, and at
  SHIP. **GREEN is deliberately dark** apart from pressure-log appends: position during GREEN
  lives in milestone commits, whose messages name the newly passing tests. This is a design
  decision, not an omission — recreating per-step state writes would rebuild the ceremony this
  skill exists to remove.
- **PR Plan statuses**: `planned`, `in-progress`, `ready` (squashed, described, awaiting the
  user), `merged`, `dropped` (with a reason). Keep shipped and dropped entries in place — they
  show how the plan evolved. In one-shot mode PRs stay `in-progress` until Finalization moves
  them to `ready` together.
- **PR `Kind`** is `behavioral` by default; `refactor` or `scaffolding` requires a stated
  reason.
- **Batch entries** pair a behavior with the test that covers it, so the trace rule (every test
  traces to a behavior or criterion) is checkable at a glance — that pairing is what the RED
  review's trace table is built from.
- **Current Batch is rewritten per PR**, not appended. Its history lives in the PR Log.
- **Pressure Log must be empty when a PR's REVIEW ends.** A non-empty log at a boundary means
  REVIEW did not finish. Its entries are superlative answers with dispositions — an entry
  reading "nothing" is malformed; the questions always have answers. `flat run N of 3` and
  `count reset` lines are counter entries, not observations: they are erased with the rest of
  the log at REVIEW and need no disposition — a discard they triggered is recorded in the PR
  Log's `Discarded`.
- **Review rounds** are recorded per PR because the re-entry rule is tag-driven: note what
  triggered each extra round, and note explicitly when the three-round cap was hit and what was
  pushed to the backlog as an open concern.
- **Hypothesis history is append-only.** Never delete prior versions.
- **PR Log is append-only**, one block per delivered PR.
- **Acceptance criteria** use `[ ]` / `[x]`. Mark satisfied (with the PR) as soon as a passing
  test covers it. A criterion advanced by several PRs stays open with a note until the last
  lands.
- **Backlog** uses four states: `[ ]` open, `[x]` resolved (with how), `[-]` dismissed (with
  reason), `[>]` deferred (with reason and destination). "Dismissed: not needed" is not a
  reason. Deferred items must be surfaced to the user and acknowledged.
- **Driver Status** defaults to `in-progress` and is kept current at every phase transition. It
  matters most when phases are delegated (see `references/phase-delegation.md`) — a driver loop
  reads it to decide whether to continue, run SHIP, stop, or wrap up — but keep it accurate
  regardless, so switching execution modes mid-session works without reconstructing state.
