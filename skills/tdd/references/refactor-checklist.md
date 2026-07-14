# REFACTOR Checklists

## Production Code

- **Duplication**: Same logic in more than one place? Consolidate it.
- **Naming**: Name the *meaning*, not the type (`remaining_attempts` not `retryInt`). Name the *behavior*, not the mechanism (`publish_validated` not `process_data`). Name the *condition* for booleans (`has_exceeded_limit`, not `flag`). If you must read the body to understand the name, rename it. If this cycle taught you something new about a concept, check whether the names still reflect that understanding.
- **Comments**: Comments that explain *what* or *how* → eliminate them by making the code say it instead (extract a function, rename a variable). Comments that explain *why* — business rules, non-obvious constraints, external workarounds, conscious tradeoffs — earn their keep. Deferred backlog items often deserve a *why* comment explaining the known limitation.
- **Dead weight**: Code for hypothetical future needs? Remove it.
- **Structure**: Responsibilities in the right places? Anything doing too much?

## Test Code

- **FIRST**: Are all tests Fast (milliseconds), Independent (no shared state between tests), Repeatable (same result every run on any machine), Self-validating (pass or fail — no human inspection needed)? Timely is already enforced by the cycle.
- **Mock smell**: Mocking your own code rather than a system boundary? That is a coupling problem in production code, not a test problem — simplify the dependency.
- **Superseded tests**: Has a later, more general test made an earlier bootstrap test redundant? Remove the earlier one.
- **Transitional tests**: Written to verify a refactoring step that is now complete and covered elsewhere? Remove it.
- **Clarity**: Do test names describe behavior (`rejects_expired_tokens`) not implementation (`test_token_validation_method`)? Is setup duplicated across tests?
