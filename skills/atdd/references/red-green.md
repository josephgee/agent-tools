# ATDD — RED and GREEN, Delegated

You are running two phases of one slice, test-first: RED (unit tests) then GREEN (implementation).
The session that delegated to you — the *delegator* — has already agreed a design with the user,
and will review your code blind once you return. You never talk to the user; everything you need
is in the state file, and everything you leave is in the state file and in commits.

**Your brief is the state file** whose path you were given. Read its `Rules in Force` header (it
applies to you), `Session` (test runner, branch facts), `Acceptance Tests`, and `Design` (the
agreed approach, and which acceptance proofs the user chose to persist as suite tests). If its
`Current Position` says GREEN, RED is already done: skip to GREEN, whose entry check tells you
where things stand — the RED section's per-test table is the record of what each test was meant
to pin.

## Stopping and returning

You return exactly one line, and the tree is clean and committed whichever it is:

- **`exit: <sha>`** — GREEN's exit holds: RED's tests and the targeted tests are green.
- **`departure: <what, and why the design can't hold> at <sha>`** — the implementation needs
  something the agreed Design does not describe or contradicts: a new interface or type, a
  changed boundary or contract, a different data shape. Private helpers and internal structure
  inside the agreed shape are not departures. Stop at the moment you see it: discard uncommitted
  work per [discard.md](discard.md), write the departure as one line in the state file's
  `Current Position` notes, and commit the state file. Leave RED's tests in place; the delegator
  takes it to the user and may send a fresh session back to continue.
- **`blocked: <what stopped it> at <sha>`** — an earlier slice's test needs changing, or the slice
  turns out to need splitting. Get back to green before returning: delete RED's still-failing
  tests, keep the passing ones, record which went in the state file's `RED` section, and commit
  (`atdd: blocked — <reason>`). Do not write the plan's Attempts line or hand anything back
  further; the delegator does.

Never return with uncommitted changes. If a check fails on the way out, fix it before returning.

---

## RED — Unit Tests, Mutation-Checking Only the Ones That Pass Immediately

**Re-read the Rules in Force header first.**

1. **Write unit tests** against the agreed design, one per behavior the implementation needs,
   following `design-principles`' test-quality doctrine (FIRST, behavioral-not-wiring — assert
   observable outcomes, never that one object called another), plus any acceptance proofs the user
   chose to persist as suite tests. Everything below treats the two alike.
2. **Run each test against current code.** Two outcomes, and they're handled differently:
   - **Fails on the missing behavior** (not an import or fixture error) — this is the normal
     case. Record it and move on; a test proven to fail needs no further proof it can fail.
   - **Passes immediately** — the test never went red, so nothing has proven it actually
     exercises the behavior it claims to. This is the *only* case the mutation check below is
     for — a test that failed here and is made to pass in GREEN already has its proof.
3. **Mutation check — immediately-passing tests only.** Temporarily edit the code the test
   targets so the behavior it claims to check is broken, run the test, confirm it now fails, then
   revert the edit exactly so the tree returns to its prior state. Record the result per test; one
   that doesn't fail under the mutation is not exercising what it claims — fix it or delete it
   before moving on.
4. Set the state file's phase to GREEN, then commit with
   `git add -A && git commit -m "atdd: red for <slice-slug>"`. From here to GREEN's exit, state
   writes are appends only — pressure log, `Amendments`, `Out of scope` — and they ride the next
   commit.

---

## GREEN — Implement

"RED's tests" below means every test written in RED, persisted acceptance proofs included.

- **Implement holistically.** You hold the whole set of RED's tests; design the implementation as
  one piece, inside the agreed Design. Write nothing the tests do not demand.
- **Never run the full suite.** It's expensive, and it runs once after the slice is handed back.
  What you run instead:
  - **Entry** (before implementation starts): run only RED's tests. The failing set must be
    exactly RED's still-red tests; any other failure is drift — most likely a mutation-check
    revert that didn't land clean — and is fixed before you start.
  - **Exit**: GREEN ends when RED's tests and the **targeted tests** are green — the existing
    tests nearest the code you changed, picked with the runner's own file or directory filter.
    Run them once RED's tests all pass. A regression they turn up (something outside RED's tests
    broke) is fixed like any other red test; that run is not a flat run and does not feed the
    tripwire, which only counts RED's own tests. Then commit everything, the state file included
    (`atdd: green complete for <slice-slug>`, if anything is uncommitted), and return `exit`.
- **Run only RED's tests at every coherent stopping point during implementation** — this is the
  one check the two bullets below key off of, and it's what stays cheap. Do not run it only when
  you expect a milestone: a run that isn't expected to show progress is exactly the one that
  catches a flat run, and it only gets caught if you look. Every such run lands in one of the two
  bullets below, never neither.
- **Milestones.** If the run shows the set of passing RED tests grew, commit:
  `atdd: green <tests or count> for <slice-slug>`. Re-read the state file's Rules in Force header
  at every milestone commit.
- **Convergence tripwire.** If the run shows nothing new passing, that's a flat run — log it in
  the pressure log the moment it happens, don't wait for a milestone to notice in hindsight. A
  milestone resets the count; the run after an amend or a refactor commit is exempt. At the third
  flat run since the last milestone, discard the experiment ([discard.md](discard.md)) and drop
  to a ladder — one failing test at a time — until the tests that entangled are passing, then
  return to holistic. Re-read the header as you drop.
- **Pressure log at every milestone**: append *ugliest thing you wrote since the last milestone?*
  and *most annoying test to satisfy so far?* — "nothing" is not a legal answer. Each gets a
  disposition: **steer now** (refactor immediately, never while flat lines are pending) or
  **hold** (the delegator's review forces a decision).
- **Two lists take appends in GREEN** besides the pressure log, since a gap or a mis-specified
  test can surface at any moment: `Out of scope` and RED's `Amendments`. Never file either in the
  pressure log, which is drained to fixes and dismissals before review.
- **Amendment protocol.** If a RED test turns out mis-specified, or a genuinely missing behavior
  within the slice's scope surfaces: halt, state the defect in one line, amend or add the test,
  re-verify it fails for the right reason, commit it alone — `atdd: amend — <reason>` (stage the
  test change by path; if implementation work is uncommitted, stash it first and pop it after).
  Never weaken a test inside an implementation commit. A gap outside the slice's scope is not this
  slice's to fix — add it to the state file's `Out of scope` list, which becomes a plan backlog
  entry; don't act on it here. An amendment that only makes sense under a different design is a
  `departure`, not an amendment.
- **Discarding.** Start every refactor step from a clean tree and commit each step that leaves
  every previously passing test passing. A refactor step that breaks a test that passed before it,
  and survives one repair attempt, is discarded per [discard.md](discard.md) — read it before the
  first refactor.
