# Design Evolution

As passes accumulate, your understanding of the design deepens. There are four responses to
what you learn, escalating in scope. SKILL.md names them; this is the detail.

Where classic per-test TDD spreads these decisions across many small cycles, this flow
concentrates them: the interface is challenged at RED (before implementation exists), pressure
is logged during GREEN, and structure is decided at REVIEW. Each response below names the phase
that owns it.

## Incremental refinement

Handled inside a pass — GREEN's *steer now* dispositions and REVIEW's self-refactor. Small
continuous improvements: renaming, restructuring, moving things. The batch protects you. No
user involvement, no plan change.

## Interface revision

The response this flow has that a per-test flow does not, and the cheapest of all four:
**handled at RED, before any implementation exists.** The tests are written, the skeleton
raises, and nothing has been built on top of the sketch yet — so changing names, signatures,
types, or error behavior costs only the edit itself.

Two triggers, both at RED:

- **Writing the batch hurts.** Setup grows convoluted, assertions contort, the same awkward
  shape repeats across tests. Five tests needing the same contorted setup is a verdict, not a
  whisper — the aperture is the reason this signal is stronger here than one test at a time.
- **The delegated test-set review reports a contract divergence.** Its reviewer reconstructs
  the contract from the tests alone; where that reconstruction disagrees with the hypothesis,
  the interface is ambiguous to its future consumers.

Revise the sketch, amend tests and skeleton, re-run the per-test verification, commit, and note
the shift in the state file's hypothesis. No user sign-off is needed — this is design work
inside the agreed criteria. If the revision changes what the PR *delivers* rather than how it
is shaped, that is a plan change, not an interface revision: surface it.

## Hypothesis revision

Handled between passes. When the design *direction* needs structural change — not just cleanup
— pause before the next THINK.

The concrete trigger is **recurrence**: the same smell named across multiple PRs, in pressure
log drains, REVIEW findings, or backlog entries (named via the `design-principles` skill's
`design-catalog.md`). Recurrence, not any single instance, is what elevates it from a local
refactor to a hypothesis revision. A single PR's REVIEW hitting its three-round cap is also a
trigger — the review could not converge because the direction, not the code, is wrong.

1. State the revised hypothesis explicitly.
2. A revision almost always requires revisiting the PR plan — some planned PRs no longer apply,
   new ones are needed, the sequence changes.
3. **Present the revised hypothesis and the revised PR plan together to the user**: what
   changed, what was learned that drove it, the new direction and sequence. Get acknowledgment
   on both before restructuring. In one-shot mode this is a `needs-user-input` stop — a
   revision is a decision gate, not a review gate.
4. Restructure to match. Tests that still describe valid behavior are kept; implementation
   changes freely.
5. Confirm the suite is green, update the state file's hypothesis and PR plan, begin the next
   THINK.

**Restructuring is bounded by what has already shipped.** A PR handed over — and especially one
merged — cannot be quietly rewritten; the change happens forward, in the PR you are in or a new
one added to the plan. If the revision invalidates a PR still under review, tell the user so
they can stop reviewing it.

## Acceptance criteria correction

Implementation occasionally reveals that a criterion is misspecified — untestable as written,
contradicts another, or reflects a misunderstanding of the feature. **Do not silently adjust
tests to accommodate this.** The amendment protocol makes test changes legal and visible during
GREEN, which makes this failure mode *easier* to commit by accident: an amendment that quietly
redefines what the feature must do is a criteria change wearing a test change's clothes. Before
amending, ask whether the defect is in the test or in the criterion behind it.

Surface a criterion defect to the user immediately, discuss whether to correct, narrow, or
remove it, and update the state file. Corrected criteria require sign-off before continuing — a
`needs-user-input` stop in one-shot mode.

## Starting fresh

When you learn the current approach is fundamentally wrong, be willing to delete the
implementation entirely and restart with a new design. The batch remains — it is a
specification of what the system must do, independent of how. State the new hypothesis in the
state file, then use the existing tests to guide the next GREEN.

**This is cheaper here than in a per-test flow, deliberately.** The tests already exist and do
not need rewriting; the PR slice bounds the loss to one increment; and re-implementing against
a written batch costs less than the per-cycle ceremony it replaced. When the pressure log and
REVIEW both keep circling the same structural problem, prefer starting fresh over a third round
of patching.

Starting fresh is not a failure. It means the process worked: you learned something important
before committing to the wrong design permanently.
