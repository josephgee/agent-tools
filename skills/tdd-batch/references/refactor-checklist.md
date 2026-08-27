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
- **Comments**: treat needing a comment as an apology — a signal the code didn't manage to say
  it clearly enough by itself. This is a posture for deciding *whether* to write one and how
  long it should be; never write the apology into the code, write the *why*. For every comment
  you are about to write, or find while reviewing, ask:
  1. **Did I add it because I needed it?** There should be a genuine *why* — a business rule, a
     non-obvious constraint, an external workaround, a conscious tradeoff — that cannot be
     recovered from the code itself. "Comments are good practice" is not a reason.
  2. **Am I repeating myself?** If it restates what the name, the type, or the surrounding code
     already makes clear — *what* or *how* rather than *why* — delete it.
  3. **Is the code structure asking for more clarity instead?** If the comment compensates for
     a function doing too much, a deep conditional, or a name that doesn't fit, that is a
     design-smell signal (name it via the `design-principles` skill's `design-catalog.md`) —
     fix the structure instead. The need for the comment usually disappears with it.

  A comment surviving all three earns its keep — kept as short as the apology requires. A long
  comment is more surface area to fall out of sync, and a stale comment is worse than none.
  Deferred backlog items often deserve a short *why* comment naming the known limitation.
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
