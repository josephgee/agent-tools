# Slice TDD — BUILD, Delegated

You are building one slice, test-first, in four phases: MAKE ROOM (pin and prepare untested code
about to change, only if its gate fires), RED (unit tests), GREEN (implementation), TIDY (refactor
and coverage). The session that delegated to you — the *delegator* — has already agreed a design,
and will review your code blind once you return. You never talk to the user; everything you need
is in the state file, and everything you leave is in the state file and in commits.

**Your brief is the state file** whose path you were given. Read its `Rules in Force` header (it
applies to you), `Session` (mode, branch, test runner, and the Constraints, which bind your
code), the target — `Acceptance Tests` in
`atdd` mode, the behavior list in `Design` in `tdd-batch` mode — and `Design` (the agreed
approach, the interface sketch, the files it modifies, the test that will exercise the behavior
sentence, and in `atdd` mode which acceptance proofs the user chose to persist as suite tests).
Its `Current Position` phase — MAKE ROOM, RED, GREEN or TIDY — is where you start; every phase
before it is done. Each phase's closing commit sets the phase to the next one, so that field is
always the resume point.

**If the tree is dirty on entry**, a previous delegate died mid-step: discard the uncommitted work
per [discard.md](discard.md), then start at the recorded phase. In GREEN, its entry check then
re-establishes which tests remain red.

## Stopping and returning

You return exactly one line, and the tree is clean and committed whichever it is:

- **`exit: <sha>`** — TIDY is done: the slice's tests and the targeted tests are green.
- **`departure: <what, and why the design can't hold> at <sha>`** — the implementation needs
  something the agreed Design does not describe or contradicts: a new interface or type, a
  changed boundary or contract, a different data shape. Private helpers and internal structure
  inside the agreed shape are not departures. Stop at the moment you see it: discard uncommitted
  work per [discard.md](discard.md), write the departure as one line in the state file's
  `Current Position` notes, and commit the state file. Leave RED's tests in place; the delegator
  takes it to the user and may send a fresh session back to continue.
- **`blocked: <what stopped it> at <sha>`** — an earlier slice's test needs changing, the slice
  turns out to need splitting, or MAKE ROOM outgrows a few commits. Get back to green before
  returning: delete RED's still-failing tests, keep the passing ones, record which went in the
  state file's `RED` section, and commit (`slice-tdd: blocked — <reason>`). Do not write the plan's
  Attempts line or hand anything back further; the delegator does.

Never return with uncommitted changes. If a check fails on the way out, fix it before returning.

Every refactor step in any phase — MAKE ROOM's, GREEN's steer-now, TIDY's — starts from a clean
tree and commits each step that leaves every previously passing test passing. A step that breaks a
test that passed before it, and survives one repair attempt, is discarded per
[discard.md](discard.md) — read it before the first refactor.

---

## MAKE ROOM — Prepare the Ground (conditional)

**Re-read the Rules in Force header first.**

**Gate — both conditions must hold:** this phase runs only if the design will *modify* code (the
Design section's file list) that (a) was **not written in this feature's earlier slices** —
feature-internal code is already covered by construction — and (b) is **not already pinned by
tests you trust** to catch a behavior change. New files and pure additions never qualify. If the
gate doesn't fire, write `skipped — <one-line reason>` under the state file's `MAKE ROOM`, set
the phase to RED, commit the state file, and move on.

When it fires, in this order:

1. **Pin first**: pin the current behavior of the code about to be disturbed — invoke the
   `backfill-tests` skill; it carries the quality bar (intent-derived expectations, proven
   falsifiable). Commit: `slice-tdd: pin <what> before <slice-slug>`.
2. **Then the preparatory refactor**: make the change easy before making the easy change.
   Behavior-preserving only; targeted tests green after each step, the pins included. Commit:
   `slice-tdd: make room for <slice-slug>`.

If the preparatory refactor grows beyond a few commits, stop: it is a slice of its own. Return
`blocked: make room outgrew the slice — <what>` so the host can plan it ahead of this one.

Record what was pinned and refactored under the state file's `MAKE ROOM`, set the phase to RED,
and commit the state file.

---

## RED — Unit Tests, Proven Failing

**Re-read the Rules in Force header first.**

1. **Write unit tests** against the agreed design and interface sketch: in `tdd-batch` mode one per
   entry in the behavior list, in `atdd` mode one per behavior the implementation needs. Follow
   `design-principles`' test-quality doctrine (FIRST, behavioral-not-wiring — assert observable
   outcomes, never that one object called another), and add any acceptance proofs the user chose
   to persist as suite tests. Everything below treats them alike. Writing them is a design act: if
   setup grows convoluted or assertions contort, the interface is failing its first contact —
   revise it now, inside the agreed shape, or return `departure` if the fix leaves it.
2. **Stub every new interface with bodies that raise** (`NotImplementedError` or the language's
   equivalent): real signatures, so the tests fail on assertions, not imports. Never a body that
   returns `None`/`0`/empty, which can satisfy a test by accident. If a stub is reachable, keep it
   inert for the duration of BUILD; GREEN replaces it.
3. **Run each test against current code.** Two outcomes, handled differently:
   - **Fails on the missing behavior** — an assertion or expected effect, not an import, compile or
     fixture error. This is the normal case. Record it and move on; a test proven to fail needs no
     further proof it can fail.
   - **Passes immediately** — nothing has yet proven it exercises the behavior it claims to. On an
     edge-case slice over existing code this can be legitimate: the behavior may already hold.
     This is the *only* case the mutation check below is for.
4. **Mutation check — immediately-passing tests only.** Temporarily edit the code the test
   targets so the behavior it claims to check is broken, run the test, confirm it now fails, then
   revert the edit exactly so the tree returns to its prior state. Record the result per test; one
   that doesn't fail under the mutation is not exercising what it claims — fix it or delete it
   before moving on. (A test that passes against a raising stub never calls the stub, so it fails
   this check.)
5. Set the state file's phase to GREEN, then commit with
   `git add -A && git commit -m "slice-tdd: red for <slice-slug>"`. From here to GREEN's exit,
   state writes are appends only — pressure log, `Amendments`, `## Out of Scope` — and they ride the
   next commit.

---

## GREEN — Implement

**Re-read the Rules in Force header first.**

"RED's tests" below means every test written in RED, persisted acceptance proofs included.

- **Implement holistically.** You hold the whole set of RED's tests; design the implementation as
  one piece, inside the agreed Design. Write nothing the tests do not demand — TIDY's coverage
  check will find it.
- **Never run the full suite.** It's expensive, and it runs once after the slice is handed back.
  What you run instead:
  - **Entry** (before implementation starts): run only RED's tests. The failing set must be
    exactly RED's still-red tests; any other failure is drift — most likely a mutation-check
    revert that didn't land clean — and is fixed before you start.
  - **Exit**: GREEN ends when RED's tests and the **targeted tests** are green — the pins from
    MAKE ROOM plus the existing tests nearest the code you changed, picked with the runner's own
    file or directory filter. Run them once RED's tests all pass. A regression they turn up
    (something outside RED's tests broke) is fixed like any other red test; that run is not a flat
    run and does not feed the tripwire, which only counts RED's own tests. Then set the phase to
    TIDY and commit everything, the state file included
    (`slice-tdd: green complete for <slice-slug>`), and go on to TIDY.
- **Run only RED's tests at every coherent stopping point during implementation** — this is the
  one check the two bullets below key off of, and it's what stays cheap. Do not run it only when
  you expect a milestone: a run that isn't expected to show progress is exactly the one that
  catches a flat run, and it only gets caught if you look. Every such run lands in one of the two
  bullets below, never neither.
- **Milestones.** If the run shows the set of passing RED tests grew, commit:
  `slice-tdd: green <tests or count> for <slice-slug>`. Re-read the state file's Rules in Force
  header at every milestone commit.
- **Convergence tripwire — count it in writing.** If the run shows nothing new passing, that's a
  flat run: append `flat run <N> of 3 — nothing new passing` to the pressure log the moment it
  happens. Do not hold the count in your head; an uncounted tripwire never fires. A RED test newly
  passing clears the count — if flat lines were pending, write `count reset — <test> now passing`.
  The run after an amend or a refactor commit is exempt, whatever it shows. Never refactor while
  flat lines are pending: committing one would carry the thrashing stretch past the discard. At
  the third flat line, discard the experiment ([discard.md](discard.md)) and drop to a ladder —
  one failing test at a time — until the tests that entangled are passing, then return to
  holistic. Re-read the header as you drop.
- **Pressure log at every milestone**: append *ugliest thing you wrote since the last milestone?*
  and *most annoying test to satisfy so far?* — "nothing" is not a legal answer; "X, and it's fine
  because Y" is. Each gets a disposition: **steer now** (refactor immediately, never while flat
  lines are pending) or **hold** (the delegator's review forces a decision). Log any smell the
  moment it bites, too — a growing switch, a third repetition, hurting setup.
- **Two lists take appends in GREEN** besides the pressure log, since a gap or a mis-specified
  test can surface at any moment: the `## Out of Scope` section and RED's `Amendments`. Never file either in the
  pressure log, which is drained to fixes and dismissals before review.
- **Amendment protocol.** If a RED test turns out mis-specified, or a genuinely missing behavior
  within the slice's scope surfaces: halt, state the defect in one line, amend or add the test,
  re-verify it fails for the right reason, commit it alone — `slice-tdd: amend — <reason>` (stage
  the test change by path; if implementation work is uncommitted, stash it first and pop it
  after). Never weaken a test inside an implementation commit. A gap outside the slice's scope is
  not this slice's to fix — add it to the state file's `## Out of Scope` section, which becomes a plan
  backlog entry; don't act on it here. An amendment that only makes sense under a different design
  is a `departure`, not an amendment.

---

## TIDY — Refactor and Coverage

**Re-read the Rules in Force header first.**

1. **Refactor the whole slice diff** (state file excluded) with
   [tidy-checklist.md](tidy-checklist.md) — read it now — and Simple Design priority: tests pass >
   intention clear > no duplication > fewest elements. Clean tree before each step, commit after
   each green one: `slice-tdd: tidy — <what>`.
2. **Coverage over the diff.** Where the project has coverage tooling, run it over the slice's
   tests: **any changed code path no test exercises is a finding** — dead, speculative, or missing
   a test; decide which, and delete it or add the test. A test added here must trace to the
   behavior sentence, a criterion, or a target row; never a trivial test to silence the tool.
   Where there is no tooling, walk the diff's branches and say so — never claim the mechanical
   check ran when it didn't.
3. Record in the state file's `TIDY` line what changed, the slice's net lines
   (`git diff --shortstat` against the base, state file excluded), and how coverage was checked
   (tool, or walked by hand). Re-run the targeted tests, set the phase to REVIEW, commit
   (`slice-tdd: tidy for <slice-slug>`), and return `exit`.

Pressure-log `hold`s are not yours to drain; the delegator does that at REVIEW.
