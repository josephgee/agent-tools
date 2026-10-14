# TIDY Checklists

Applied once per slice, at TIDY, across the **whole slice diff** (state file excluded) — not per
test and not per milestone. The whole-diff aperture is the point: duplication introduced early in
GREEN and repeated late is only visible here.

This pass is yours, before the delegator's blind review. The reviewer covers design at depth; this
pass is the floor that keeps its report about design rather than about obvious cleanup you could
have done.

## Production Code

- **Duplication**: same logic in more than one place across the whole diff? Consolidate it.
  Check the implementations of RED's tests against each other specifically — behaviors written
  together tend to repeat each other's shapes. Check the diff against the code the Design's
  pointers name, too: a helper that already exists there is duplication.
- **Naming**: name the *meaning*, not the type (`remaining_attempts` not `retryInt`). Name the
  *behavior*, not the mechanism (`publish_validated` not `process_data`). Name the *condition*
  for booleans (`has_exceeded_limit`, not `flag`). If you must read the body to understand the
  name, rename it. If this pass taught you something new about a concept, check whether the
  names still reflect that understanding.
- **Comments**: delete every comment in the diff. Where does the code need to be more
  expressive to make up for it? Do that. Decision context (why this change, what was rejected)
  goes in the state file's `Learned` line, not back into the code — the host folds it into the
  squash commit. If a hazard can only be flagged at the edit site and no name, type, or failing
  test can carry it, do not keep a comment — add it (file:line, why) to `Learned` for the user to
  decide.
- **Dead weight / speculation**: TIDY's coverage step enforces the scope fence — any changed code
  path no test exercises is a finding. Here, look for what coverage cannot see: a parameter, a
  branch or a type that every test happens to exercise but that no test *needs*.
- **Structure**: responsibilities in the right places? Anything doing too much? A test set
  implemented holistically can quietly grow one function that does the work of three.

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
- **Clarity**: do test names describe behavior (`rejects_expired_tokens`) not implementation
  (`test_token_validation_method`)? Is setup duplicated across the set? Five tests sharing a
  contorted setup is a verdict on the object under test, not only on the tests.
