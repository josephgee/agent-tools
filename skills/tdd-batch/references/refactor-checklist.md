# REVIEW Checklists

Applied once per PR, at REVIEW step 2, across the **whole PR diff** (state file excluded) —
not per test and not per milestone. The whole-diff aperture is the point: duplication
introduced early in the batch and repeated late is only visible here.

Run these yourself before delegating the design review. The delegate covers design at depth;
this pass is the floor that keeps the delegate's report about design rather than about
obvious cleanup you could have done.

## Production Code

- **Duplication**: same logic in more than one place across the whole diff? Consolidate it.
  Check the batch's implementations against each other specifically — behaviors written
  together tend to repeat each other's shapes.
- **Naming**: name the *meaning*, not the type (`remaining_attempts` not `retryInt`). Name the
  *behavior*, not the mechanism (`publish_validated` not `process_data`). Name the *condition*
  for booleans (`has_exceeded_limit`, not `flag`). If you must read the body to understand the
  name, rename it. If this pass taught you something new about a concept, check whether the
  names still reflect that understanding.
- **Comments**: delete every comment in the diff. Where does the code need to be more
  expressive to make up for it? Do that. Decision context (why this change, what was rejected)
  goes in the state file's `Learned` line, not back into the code — drained into the PR
  description when this ships, or into the host's squash commit when a host owns the PR.
  Last chance: if the site you just touched sits inside an existing, repeated convention of
  one-line comments (e.g. every other member of this enum already carries one), match it with
  one line rather than leave this the only unlabelled entry — that is surrounding-norm
  consistency winning, not a general excuse to keep a comment you'd otherwise delete.
- **Dead weight / speculation**: this is where the batch's scope fence is enforced. Any changed
  code path no batch test exercises is a finding — dead, speculative, or missing a test. Run
  coverage over the diff where the project has tooling; where it does not, walk the diff's
  branches and say that is what you did. Do not write trivial tests to silence it: a test added
  here must trace to a behavior or criterion, the same rule RED's review enforces.
- **Structure**: responsibilities in the right places? Anything doing too much? A batch
  implemented holistically can quietly grow one function that does the work of three.

## Test Code

Run these over the batch as a set. Each maps to a fuller entry in the `design-principles`
skill's `test-catalog.md` — invoke it for the precise definition; the triggers below are the
floor.

- **FIRST**: Fast (milliseconds), Independent (no shared state), Repeatable (same result on any
  machine), Self-validating (pass/fail, no human inspection)? Timely is enforced by the flow.
- **Behavioral, not wiring**: does each test assert an observable outcome, not that one object
  called another's method?
- **Mock smell**: mocking your own code rather than a system boundary? That is a coupling
  problem in production code, not a test problem — simplify the dependency.
- **Batch coherence** (specific to this flow): do the batch's tests share a consistent contract
  and vocabulary, or did the interface drift as the batch was written? Drift here is a design
  signal the RED review may have missed once implementation forced changes.
- **Outlived its job**: has a later, more general test superseded an earlier bootstrap test; is
  this a transitional test for a now-complete refactor; is it a deletion-driving test asserting
  the mere absence of something already removed? Remove any of these — keep a deletion test only
  if it asserts a genuine boundary behavior (e.g. "deprecated endpoint now returns 410").
- **Clarity**: do test names describe behavior (`rejects_expired_tokens`) not implementation
  (`test_token_validation_method`)? Is setup duplicated across the batch — and if the RED
  review's setup census flagged it, was it actually addressed?
