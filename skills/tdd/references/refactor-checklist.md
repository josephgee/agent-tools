# REFACTOR Checklists

## Production Code

Apply the `refactor` skill's [references/standard.md](../../refactor/references/standard.md) —
read it now. Read the file directly; do **not** invoke the `refactor` skill, whose workflow
would demand a clean tree and start a test-net check of its own. **The scope** is the diff under
review: this cycle's, or the combined PR diff at SHIP. **The log** is the state file: decision
context goes on `Learned` (drained into the PR description at SHIP, or into the host's squash
commit when a host owns the PR); deletion candidates and edit-site hazards (`hazard: file:line,
why`, for the user to decide) go in the backlog; a missing pin is a test to add now.

## Test Code

Run these per-cycle triggers over the test you just wrote. Each maps to a fuller entry in
the `design-principles` skill's `test-catalog.md` — invoke it when you want the precise
definition or the reasoning behind one; the triggers below are the floor.

- **FIRST**: Fast (milliseconds), Independent (no shared state), Repeatable (same result on any machine), Self-validating (pass/fail, no human inspection)? Timely is already enforced by the cycle.
- **Behavioral, not wiring**: does the test assert an observable outcome, not that one object called another's method?
- **Mock smell**: mocking your own code rather than a system boundary? That is a coupling problem in production code, not a test problem — simplify the dependency.
- **Outlived its job**: has a later, more general test superseded an earlier bootstrap test; is this a transitional test for a now-complete refactor; or is it a deletion-driving test asserting the mere absence of something already removed? Remove any of these — see `test-catalog.md` for the full treatment of each, and keep a deletion test only if it asserts a genuine boundary behavior (e.g. "deprecated endpoint now returns 410").
- **Clarity**: do test names describe behavior (`rejects_expired_tokens`) not implementation (`test_token_validation_method`)? Is setup duplicated across tests?
