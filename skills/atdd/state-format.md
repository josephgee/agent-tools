# ATDD State File Format

The state file records one slice's pass: its acceptance tests, the agreed design, RED's unit
tests and their mutation checks, GREEN's pressure log, and REVIEW's findings. It rides along in
commits, so rolling back a commit restores code and session state together.

## Location and name

`<plans-dir>/atdd-<feature-slug>-<NN>.md`   (`<NN>` is the slice's two-digit number)

- **`<plans-dir>`** — the same plans directory slice-plan is already using for this feature.
- **`<feature-slug>`** and **`<NN>`** — the plan's feature slug and this slice's number, both
  handed over by the host. A slice slug alone is only unique within one feature, so it is not the
  file name.

The `atdd-` prefix and the `# ATDD Session State` heading keep these files distinct from `tdd`'s
and `tdd-batch`'s, so any of the three can run in the same repo, even the same feature, without
colliding.

---

```markdown
# ATDD Session State

## Rules in Force

Copied verbatim at creation, never edited. Re-read before the human gate, at the start of RED, at
every GREEN milestone and ladder drop, before each REVIEW round, and at the start of SHIP.

- Acceptance tests come first, human proof first, never weakened to pass. Agent proof is additive
  and never a narrower substitute. A row with no agent proof is confirmed by the user walking the
  human proof at SHIP. At least one suite test must exercise the slice's behavior sentence.
- A fresh subagent reviews the design draft, never its author. No RED until the user agrees at the
  human gate; silence is not agreement.
- Mutation check (break the code under test, confirm it fails, revert exactly) only for a RED test
  that passes immediately. Never touch a test in GREEN outside the amendment protocol: halt,
  state the defect, amend, re-verify, commit it alone.
- Full suite once, at GREEN's exit, plus again only if code changed since; between, run RED's
  tests only. Milestone commit = RED's passing subset only grew, subset named. Pressure log at
  every milestone: "nothing" is not an answer. Three flat runs → discard per
  references/discard.md.
- REVIEW is delegated and blind (diff and unit tests only). A `structural-if-fixed` fix triggers
  a fresh round, max three; record every dismissal with a reason, and anything open at the cap.
  Backlog, never fix, a finding that tightens an earlier test or asks for behavior this slice lacks.
  Code changed after the last review is listed unreviewed.
- Hosted: own state file and Attempts line only, no new branch, no second file, commit as you go,
  no squash or PR — hand back.
- SHIP gates on all four together: acceptance tests, unit tests, lint, review.

## Session
- **Slice**: <feature-slug> <NN> <slice-slug>
- **Slice behavior**: <the one-sentence behavior from slice-plan's plan, copied verbatim>
- **Criteria advanced**: <which, from slice-plan's plan>
- **Test runner**: `<command>`
- **Last full-suite run**: none | green at <sha>
- **Lint command**: `<command>` | none found
- **Started**: YYYY-MM-DD
- **Last updated**: YYYY-MM-DD

## Acceptance Tests

| Behavior | Human proof | Agent proof | Status |
|---|---|---|---|
| <one sentence> | <steps + expected observation, whatever form proves this behavior> | <same steps run by the agent, or an equivalent> | pending |
| <one sentence> | <what a human does and looks at> | *(blank — no agent mechanism proves this without weakening the human proof)* | pending |

## Design

**Design review**: <findings, each fixed or dismissed with a reason — or "clean, nothing to
fix">

**Acceptance proofs persisted as suite tests** (asked at the gate): none | <which rows, and why>

**Gate**: not yet reached | passed on YYYY-MM-DD

<Design doc substance — approach, trade-off considered and rejected with the deciding line,
link to a throwaway skeleton if one was built and where it went (deleted, or kept as a
reference — say which).>

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

## Review

<!-- Add this whole section when REVIEW starts, not at creation: its presence tells the host a
review happened. -->

- **Rounds**: <N; what triggered each extra round — a `structural-if-fixed` fix, and which>
- **Fixed**: <one line each>
- **Dismissed**: <finding — reason, one line each; the host shows every one to the user>
- **Backlogged**: none | <finding — why it is not this slice's, one line each>
- **Open at cap**: none | <structural findings still open after round three, a round-three
  structural fix, and any change made after the last review, marked unreviewed>
- **Out of scope**: none | <gaps noticed in GREEN that are not this slice's to fix, one line each>
- **Lint**: clean | <findings and their disposition>

## SHIP

- **Acceptance tests**: <pass/fail per test, rows with no agent proof noted as user-confirmed>
- **Unit tests**: green | <what's still red>
- **Lint**: clean | <open items>
- **Review**: all findings fixed or dismissed | see `Open at cap`
- **Handed back**: `atdd — handed back: reviewed, suite green at <sha>` | `atdd — blocked: <what stopped it>`

## Learned

<Decision context worth carrying into the squash commit, or "no surprises". The host reads this
before it squashes.>

## Current Position
- **Phase**: <ACCEPT | RESEARCH-DESIGN | RED | GREEN | REVIEW | SHIP>
- **Notes**: <anything needed to resume — in GREEN this stays empty by design; the last
  milestone commit is the position>
```

---

## Notes on Use

- **Rules in Force is fixed text**, written once from the block above, never rewritten. On resume,
  a header that's missing or differs from the block is replaced wholesale.
- **The `## Review` section is the record the host reads**, alongside the token `reviewed` on the
  hand-back line, and the host skips its own review only when both exist. So the section is not
  created at Setup: add it, from the template, when REVIEW starts. Its mere presence claims a
  review was done.
- **State-file writes ride the next commit** — ACCEPT's table, the design write, RED's
  verification table, REVIEW's findings, SHIP's gate result. GREEN is dark apart from
  pressure-log appends: position during GREEN lives in milestone commit messages.
- **Acceptance Tests is written once at ACCEPT and only its Status column changes after**, at
  SHIP. The Behavior/Human proof/Agent proof columns don't change mid-slice — a change there means
  the slice's scope moved, which goes back through the host, not a silent table edit.
- **Pressure Log dies with the slice** — drained to fixes or dismissals. A gap that's real but out
  of scope for this slice goes in REVIEW's `Out of scope` list; the host turns it into a plan
  backlog entry.
