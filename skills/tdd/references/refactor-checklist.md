# REFACTOR Checklists

## Production Code

- **Duplication**: Same logic in more than one place? Consolidate it.
- **Naming**: Name the *meaning*, not the type (`remaining_attempts` not `retryInt`). Name the *behavior*, not the mechanism (`publish_validated` not `process_data`). Name the *condition* for booleans (`has_exceeded_limit`, not `flag`). If you must read the body to understand the name, rename it. If this cycle taught you something new about a concept, check whether the names still reflect that understanding.
- **Comments**: Treat needing a comment as an apology — a signal that the code didn't manage to say it clearly enough by itself. This is a posture for deciding *whether* to write one and how long it should be; it is not a tone or phrasing to put in the comment itself — never write the apology ("sorry", "forgive this", etc.) into the code, write the *why*. For every comment you're about to write, or one you find while reviewing, ask three questions:
  1. **Did I add it because I needed it?** There should be a genuine *why* here — a business rule, a non-obvious constraint, an external workaround, a conscious tradeoff — that cannot be recovered from the code itself. "Comments are good practice" is not a reason.
  2. **Am I repeating myself?** If it restates what the name, the type, or the surrounding code already makes clear — explaining *what* or *how* rather than *why* — it's redundant. Delete it.
  3. **Is the code structure asking for more clarity instead?** If the comment exists to compensate for a method doing too much, a deep conditional, or a name that doesn't fit — that's a design-smell signal (see [references/design-smells.md](references/design-smells.md)) — fix the structure, extract a function, rename the variable. The need for the comment often disappears with it.

  A comment that survives all three earns its keep. Even then, keep it as short as the apology requires — a sentence, not a paragraph. Verbosity is its own smell: a long comment is more surface area to fall out of sync with the code, and a stale comment is worse than none, actively misleading the next reader (including you, next cycle). Deferred backlog items often deserve a short *why* comment explaining the known limitation.
- **Dead weight**: Code for hypothetical future needs? Remove it.
- **Structure**: Responsibilities in the right places? Anything doing too much?

## Test Code

- **FIRST**: Are all tests Fast (milliseconds), Independent (no shared state between tests), Repeatable (same result every run on any machine), Self-validating (pass or fail — no human inspection needed)? Timely is already enforced by the cycle.
- **Mock smell**: Mocking your own code rather than a system boundary? That is a coupling problem in production code, not a test problem — simplify the dependency.
- **Superseded tests**: Has a later, more general test made an earlier bootstrap test redundant? Remove the earlier one.
- **Transitional tests**: Written to verify a refactoring step that is now complete and covered elsewhere? Remove it.
- **Deletion-driving tests**: Was this test's purpose to drive removal of code — asserting something no longer exists, no longer runs, or no longer returns a value (a deleted field, a retired code path, a dead dependency)? That's a legitimate way to use RED/GREEN to drive a deletion, but the resulting test has no ongoing job once the deletion lands: it doesn't specify any behavior the system provides, only the absence of something that's already gone, so it can't catch a meaningful regression the way a behavioral test can. Its existence as a permanent artifact is itself a design smell — treat it the same as "Transitional tests" above. Delete the test once the deletion is verified; note the removal briefly in the cycle log. Keep a test only if it asserts a genuine observable behavior at the boundary (e.g. "deprecated endpoint now returns 410") rather than the sheer non-existence of removed internals.
- **Clarity**: Do test names describe behavior (`rejects_expired_tokens`) not implementation (`test_token_validation_method`)? Is setup duplicated across tests?
