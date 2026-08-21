# Test Catalog — test-quality smells and properties

A vocabulary for the quality of *tests*, as distinct from the code under test. Stated
**neutrally**; the consumer supplies the posture. Load this only when tests are in scope.

## FIRST — the properties a good test has

From Martin's *Clean Code* ch. 9, which is also the source for much of this file's framing:
test code is held to the same standard as production code. A suite allowed to rot stops being
a safety net and becomes a second system to maintain — and then gets abandoned, taking the
protection with it.

- **Fast** — runs in milliseconds. A slow suite gets run less, and a suite run less catches less.
- **Independent** — no shared state between tests; order and selection don't change results.
- **Repeatable** — same result every run, on any machine, with no reliance on wall-clock, network, or ambient state.
- **Self-validating** — it passes or fails on its own; no human reads output to decide.
- **Timely** — written close to the code it covers (in TDD, before it).

## What a test should assert

- **Behavioral, not wiring** — a test should verify an observable outcome (a return value, a
  state change, an effect at the system boundary), not internal structure. A test that
  asserts "object A called object B's method" is a *wiring test*: it breaks when internals
  are refactored even though behavior is unchanged, and it never tells you whether the
  feature is actually correct. The question is "did the feature behave correctly?" not "did
  it use the right objects internally?"

- **One concept per test** — a test should pin a single behavior. A test asserting several
  unrelated things fails without telling you which one broke, and can't be named for what it
  proves. This is about concepts, not a literal one-assert rule: several assertions
  establishing one outcome are fine.

## Mocks

- **Live objects over mocks** — real objects wherever practical. Mocks can be wired
  incorrectly, obscure real behavior, and produce false confidence.
- **Mock only at a boundary** — reach for a mock when crossing a *system boundary* (external
  API, database, file system, message queue, third-party service) or when the real thing is
  prohibitively slow for the suite. Mock *at* that boundary, never deep inside your own code.
- **Mock smell** — mocking your own code rather than a system boundary is a *coupling*
  problem in the production code, not a test problem. The fix is to simplify the dependency,
  not to add the mock.

## Tests that have outlived their job

These are legitimately created, then become dead weight; a test kept past its purpose is
itself a design smell.

- **Superseded tests** — a later, more general test has made an earlier bootstrap/example
  test redundant. Remove the earlier one.
- **Transitional tests** — written to verify a refactoring step that is now complete and
  covered elsewhere. Remove it.
- **Deletion-driving tests** — a test whose purpose was to *drive a removal* by asserting
  that something no longer exists, runs, or returns a value (a deleted field, a retired code
  path, a dead dependency). Using RED/GREEN to drive a deletion is legitimate, but the
  resulting test has no ongoing job: it specifies the *absence* of something already gone,
  not any behavior the system provides, so it can't catch a meaningful regression. Delete it
  once the deletion is verified. Keep a test only if it asserts a genuine observable behavior
  at the boundary (e.g. "deprecated endpoint now returns 410") rather than the sheer
  non-existence of removed internals.

## Test clarity

- **Names describe behavior** — `rejects_expired_tokens`, not `test_token_validation_method`.
  If you must read the body to know what a test proves, the name is failing.
- **Build-Operate-Check** — a readable test has three visible parts: build the world it needs,
  perform the one action under test, check the outcome. When those blur together, a reader has
  to disentangle setup from assertion to see what is actually being proven. (Also met by
  Given/When/Then and Arrange/Act/Assert — the same shape under other names.)
- **Setup duplication** — setup copy-pasted across many tests is the same *Duplicate Code*
  smell as in production; consolidate it into fixtures/builders, but not so aggressively that
  a reader can no longer see what a given test depends on.
