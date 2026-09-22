# REFACTOR Checklists

## Production Code

- **Duplication**: Same logic in more than one place? Consolidate it.
- **Naming**: Name the *meaning*, not the type (`remaining_attempts` not `retryInt`). Name the *behavior*, not the mechanism (`publish_validated` not `process_data`). Name the *condition* for booleans (`has_exceeded_limit`, not `flag`). If you must read the body to understand the name, rename it. If this cycle taught you something new about a concept, check whether the names still reflect that understanding.
- **Comments**: delete every comment in the diff. Where does the code need to be more expressive to make up for it? Do that. Decision context (why this change, what was rejected) goes in the state file's `Learned` line, not back into the code — drained into the PR description at SHIP, or into the host's squash commit when a host owns the PR. Last chance: if the site you just touched sits inside an existing, repeated convention of one-line comments (e.g. every other member of this enum already carries one), match it with one line rather than leave this the only unlabelled entry — that is surrounding-norm consistency winning, not a general excuse to keep a comment you'd otherwise delete.
- **Dead weight**: Code for hypothetical future needs? Remove it.
- **Structure**: Responsibilities in the right places? Anything doing too much?

## Test Code

Run these per-cycle triggers over the test you just wrote. Each maps to a fuller entry in
the `design-principles` skill's `test-catalog.md` — invoke it when you want the precise
definition or the reasoning behind one; the triggers below are the floor.

- **FIRST**: Fast (milliseconds), Independent (no shared state), Repeatable (same result on any machine), Self-validating (pass/fail, no human inspection)? Timely is already enforced by the cycle.
- **Behavioral, not wiring**: does the test assert an observable outcome, not that one object called another's method?
- **Mock smell**: mocking your own code rather than a system boundary? That is a coupling problem in production code, not a test problem — simplify the dependency.
- **Outlived its job**: has a later, more general test superseded an earlier bootstrap test; is this a transitional test for a now-complete refactor; or is it a deletion-driving test asserting the mere absence of something already removed? Remove any of these — see `test-catalog.md` for the full treatment of each, and keep a deletion test only if it asserts a genuine boundary behavior (e.g. "deprecated endpoint now returns 410").
- **Clarity**: do test names describe behavior (`rejects_expired_tokens`) not implementation (`test_token_validation_method`)? Is setup duplicated across tests?
