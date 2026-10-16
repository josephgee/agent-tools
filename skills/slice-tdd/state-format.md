# Slice TDD State File Format

Path: `<plans-dir>/slice-tdd-<feature-slug>-<NN>.md`, with the plans directory, feature slug and
two-digit slice number the host handed over.

---

```markdown
# Slice TDD Session State

## Rules in Force

Copied verbatim, never edited. Re-read before `acceptance`'s gate, at each BUILD phase, every GREEN
milestone and ladder drop, each delegate's return, each REVIEW round, and SHIP.

- `acceptance`: acceptance tests first, human proof never weakened, no BUILD until the user agrees.
  `internal`: the behavior list is the target; a departure goes to the user when BUILD returns it.
- The host triages and asks; delegates research, review, build and fix. It reads results and this
  file, never the diff. Every phase's closing commit sets the next phase.
- MAKE ROOM pins untested code before changing it. New interfaces get raising stubs; a RED test
  that passes immediately gets a mutation check. Touch a test in GREEN only by amendment, committed
  alone. Never the full suite. Pressure log at each milestone, "nothing" is not an answer. Each
  flat run is a written `flat run N of 3` line; at three, discard. TIDY deletes first and checks coverage.
- REVIEW is blind; a `structural-if-fixed` fix earns a fresh round, max three. Backlog, never fix,
  a finding that tightens an earlier test or asks for behavior this slice lacks.
- Hosted: own state file and Attempts line only, commit as you go, no squash or PR. SHIP gates on
  acceptance tests (`acceptance`), unit tests, lint and review together.

## Session
- **Mode**: acceptance | internal
- **Branch**: <the branch the host cut, from the block>
- **Base branch**: <the plan Session's base branch — slice 01's review diff base>
- **Slice**: <feature-slug> <NN> <slice-slug>
- **Slice behavior**: <the one-sentence behavior from slice-plan's plan, copied verbatim>
- **Criteria advanced**: <which, from slice-plan's plan>
- **Constraints**: <the plan's Constraints section, copied verbatim — they bind this slice, and
  delegates read this file, not the plan>
- **Test runner**: `<command>`
- **Lint command**: `<command>` | none found
- **Started**: YYYY-MM-DD
- **Last updated**: YYYY-MM-DD

## Acceptance Tests

<!-- acceptance mode only; omit this section in internal mode. -->

| Behavior | Human proof | Agent proof | Status |
|---|---|---|---|
| <one sentence> | <steps + expected observation, whatever form proves this behavior> | <same steps run by the agent, or an equivalent> | pending |
| <one sentence> | <what a human does and looks at> | *(blank — no agent mechanism proves this without weakening the human proof)* | pending |

## Design

**Behaviors** (internal mode only — the slice's target; each traces to the behavior sentence or
a criterion):
- <one sentence, no "and">

**Interface sketch**: <names, signatures, types, errors, as consumers see them>

**Files modified**: <paths the design changes — MAKE ROOM's gate reads this>

**Behavior-sentence test**: <the suite test that will exercise the slice's behavior sentence>

**Design review**: <findings, each fixed or dismissed with a reason — or "clean, nothing to
fix">

**Acceptance proofs persisted as suite tests** (acceptance mode, asked at the gate): none | <which rows,
and why>

**Gate**: not yet reached | passed on YYYY-MM-DD | none (internal)

<Design doc substance — approach, trade-off considered and rejected with the deciding line,
link to a throwaway skeleton if one was built and where it went (deleted, or kept as a
reference — say which). A departure agreed with the user after BUILD returned one is appended
here.>

## MAKE ROOM

- skipped — <one-line reason the gate did not fire> | pinned: <what, commit> ; refactored: <what,
  commit>

## RED

- **Unit tests** (one row per test — mutation check only appears on a row that passed
  immediately):
  - `<test name>` — fails on: <what was missing> ✓
  - `<test name>` — passed immediately — mutation check: <what was broken, confirmed failed,
    reverted> ✓
- **Amendments**: <any, with the one-line reason each>

## Pressure Log

Appended during GREEN (at each milestone, whenever a smell bites, and at every flat run),
drained to empty at REVIEW step 0 — every `hold` ends as a fix or a dismissal with a reason.

- flat run 2 of 3 — nothing new passing
- count reset — `<test name>` now passing
- <ugliest thing / most annoying test — one line> — **steer now**: <what was done>
- <one line> — **hold**: <why it waits for REVIEW>
- <what entangled> — **discarded**: <restored to <sha>>

## Out of Scope

Appended during GREEN and TIDY whenever a gap or an unpinned deletion candidate surfaces that is real but not this slice's to fix, one line
each. REVIEW copies these into `## Review`'s `Out of scope` list when it creates that section.

- none | <gap — why it is not this slice's>

## TIDY

- <what the whole-diff refactor changed and deleted>; net lines: +A −D; coverage: <tool and
  result | walked by hand — no tooling>

## Review

<!-- Add this whole section when REVIEW starts, not at creation: its presence tells the host a
review happened. -->

- **Rounds**: <N; what triggered each extra round — a `structural-if-fixed` fix, and which>
- **To fix**: <finding — `structural-if-fixed` | `local`, one line each; the fix delegate empties
  this list>
- **Fixed**: <one line each, written by the fix delegate>
- **Dismissed**: <finding — reason, one line each, pressure-log `hold`s dismissed at step 0
  included; the host shows every one to the user>
- **Backlogged**: none | <finding — why it is not this slice's, one line each>
- **Open at cap**: none | <structural findings still open after round three,
  `fix discarded: <finding> — <what entangled>`, and `unreviewed: <change>` for every fix applied
  after the last review round ran — that round's fixes, lint fixes, SHIP's fixes>
- **Out of scope**: none | <copied from `## Out of Scope` when this section is created>
- **Lint**: clean | none found | <findings left unfixed, each with its reason>

## Learned

<Decision context worth carrying into the squash commit, or "no surprises". The host reads this
before it squashes.>

## Current Position
- **Phase**: <ACCEPT | DESIGN | MAKE ROOM | RED | GREEN | TIDY | REVIEW | SHIP> — set by each
  phase's closing commit to the phase that comes next, so it is always where work resumes
- **Notes**: <a `departure`, as one line; otherwise empty>
```

---

## Notes on Use

- **The target is written once and only its Status column changes after** — ACCEPT's table at
  SHIP; the behavior list not at all. A change to a row's behavior means the slice's scope moved,
  which goes back through the host, not a silent edit.
