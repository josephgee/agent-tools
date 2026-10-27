# TIDY Checklists

Applied once per slice, at TIDY, across the **whole slice diff** (state file excluded) — not per
test and not per milestone. The whole-diff aperture is the point: duplication introduced early in
GREEN and repeated late is only visible here.

This pass is yours, before the delegator's blind review. The reviewer covers design at depth; this
pass is the floor that keeps its report about design rather than about obvious cleanup you could
have done.

## Production Code

Apply the `refactor` skill's [references/standard.md](../../refactor/references/standard.md) —
read it now. Read the file directly; do **not** invoke the `refactor` skill, whose workflow
would demand a clean tree and start a test-net check of its own. **The scope** is the whole
slice diff. **The log** is the state file: decision context and edit-site hazards go on
`Learned` (the host folds it into the squash commit); deletion candidates go in `## Out of
Scope`; a missing pin is a test to add now. On top of the standard:

- **Duplication across RED's tests**: check their implementations against each other —
  behaviors written together tend to repeat each other's shapes — and check the diff against the
  code the Design's pointers name.
- **Holistic overgrowth**: a test set implemented holistically can quietly grow one function that
  does the work of three.

## Test Code

Run these over RED's tests as a set. Each maps to a fuller entry in the `design-principles`
skill's `test-catalog.md` — invoke it for the precise definition; the triggers below are the
floor.

- **FIRST**: Fast (milliseconds), Independent (no shared state), Repeatable (same result on any
  machine), Self-validating (pass/fail, no human inspection)? Timely is enforced by the flow.
- **Behavioral, not wiring**: does each test assert an observable outcome, not that one object
  called another's method?
- **Mock smell**: mocking your own code rather than a system boundary? That is a coupling
  problem in production code, not a test problem — simplify the dependency.
- **Set coherence**: do RED's tests share a consistent contract and vocabulary, or did the
  interface drift as they were written and amended? Drift here is a design signal the design
  review could not have seen, since it ran before any test existed.
- **Outlived its job**: has a later, more general test in the set superseded an earlier
  bootstrap test, or is a test transitional for a now-complete refactor? Remove it — see
  `test-catalog.md`.
- **Clarity**: do test names describe behavior (`rejects_expired_tokens`) not implementation
  (`test_token_validation_method`)? Is setup duplicated across the set? Five tests sharing a
  contorted setup is a verdict on the object under test, not only on the tests.
