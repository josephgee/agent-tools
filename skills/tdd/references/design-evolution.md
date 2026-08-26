# Design Evolution

As cycles accumulate, your understanding of the design deepens. There are four responses to what
you learn, escalating in scope. SKILL.md names them; this is the detail.

## Incremental refinement

Handled in REFACTOR. Small continuous improvements — renaming, restructuring, moving things. The
tests protect you. No user involvement, no plan change.

## Hypothesis revision

Handled between cycles. When several cycles reveal that the design *direction* needs structural
change — not just cleanup — pause before the next THINK.

A recurring backlog entry naming the same smell across multiple cycles (named via the
`design-principles` skill's `design-catalog.md`) is the concrete trigger — **recurrence**, not any
single instance, is what elevates it from a local refactor to a hypothesis revision.

1. State the revised hypothesis explicitly.
2. A revision almost always requires revisiting the PR plan — some planned PRs no longer apply,
   new ones are needed, the sequence changes.
3. **Present the revised hypothesis and the revised PR plan together to the user**: what changed,
   what was learned that drove it, the new direction and sequence. Get acknowledgment on both
   before restructuring. In one-shot mode this is a `needs-user-input` stop (write both into the
   state file, set Driver Status, halt) — a revision is a decision gate, not a review gate.
4. Restructure the implementation to match. Tests that still describe valid behavior are kept;
   implementation changes freely.
5. Confirm all tests pass, update the state file hypothesis and PR plan, begin the next THINK.

**Restructuring is bounded by what has already shipped.** A PR that has been handed over — and
especially one that has merged — cannot be quietly rewritten; the change happens forward, in the
PR you are in now or a new one added to the plan. If the revision invalidates a PR still under
review, tell the user so they can stop reviewing it.

## Acceptance criteria correction

Implementation occasionally reveals that a criterion is misspecified — untestable as written,
contradicts another, or reflects a misunderstanding of the feature. **Do not silently adjust
tests to accommodate this.** Surface it to the user immediately, discuss whether to correct,
narrow, or remove the criterion, and update the state file. Corrected criteria require user
sign-off before continuing — a `needs-user-input` stop in one-shot mode.

## Starting fresh

When you learn the current approach is fundamentally wrong, be willing to delete the
implementation entirely and restart with a new design. The behavioral tests you have written
remain — they are a specification of what the system must do, independent of how it does it.
State the new design hypothesis in the state file, then use the existing tests to guide you
through the next GREEN phase.

Starting fresh is not a failure. It means TDD worked: you learned something important before
committing to the wrong design permanently.
