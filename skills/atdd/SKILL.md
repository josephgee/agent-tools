---
name: atdd
description: "Executes one slice-plan slice acceptance-test-first, with a human design gate before any code. Use when a slice's design isn't settled enough to start a red-green loop — it warrants research, a written design the user reviews and signs off on, and human-runnable proof of the slice's behavior — or when asked for ATDD or acceptance-test-driven development. Flow: acceptance tests (human-executable proof first, agent-runnable where that doesn't weaken it), research and a reviewed design doc, user sign-off, unit tests then implementation, a blind code review iterated to clean, lint, then a final gate on acceptance tests, unit tests, lint and review. Runs in-session, hosted by slice-plan (with no plan file, use slice-plan first). Prefer tdd or tdd-batch when the interface is already clear and a design gate would be ceremony."
compatibility: "Requires slice-plan as host (it executes one slice and does no feature-level planning), plus design-principles and design-review, whose vocabulary RED's tests and both reviews use. Requires a way to delegate to an isolated subagent: research, the design review and the code review each run outside the session that wrote what they review, with no in-session fallback. Requires git."
metadata:
  soft-deps: slice-plan design-principles design-review
---

# ATDD — Acceptance-Test-Driven Development

This skill starts from the outside: the slice's *external* behavior, defined as acceptance tests
before any interface is proposed. Each test is first a proof a human can run and observe; the agent
runs it too wherever that doesn't weaken it (see ACCEPT). Between those tests and any code sits
research and a design doc, and a **human reviews and agrees to it before RED starts**. Once code is
being written, implementation is holistic, with milestone commits, a pressure log, and a discard
protocol for failed experiments. REVIEW is blind and iterates: the reviewer sees the diff and the
unit tests and nothing else, so its read of the code is not anchored to the plan that produced it,
and fixes are re-reviewed until clean.

One pass through six phases — ACCEPT → RESEARCH & DESIGN → RED → GREEN → REVIEW → SHIP — delivers
one slice.

## Hosted by slice-plan

This skill runs as a guest under slice-plan, which hands it an override block (its `atdd`
adaptation, in slice-plan's `references/hosted-handoff.md`) owing five things: stay on the branch
the host cut, leave the suite green with a passing test for the slice's behavior, write only your
own state file and Attempts line, commit as you go, and hand back before the squash. **Where the
block conflicts with a phase below, the block wins**, with one exception it grants: this skill runs
its own REVIEW before hand-back (see REVIEW).

What that means here:

- **Setup is only the `Kind` check and the state file.** The block skips setup because the tree
  is clean, the baseline is green and the test runner is in the plan's Session; make no "begin"
  commit. The state file is committed with ACCEPT's commit. The lint command is not in the plan;
  REVIEW finds it.
- **The human design gate survives** the block's "skip your alignment gate": that gate is
  feature-level and already passed; this one is per slice.
- **Hand back `atdd — blocked: <what stopped it>`** — leaving the suite green and committing any
  complete work — when: the plan records this slice's `Kind` as `refactor` or `scaffolding` (a
  test-first loop has no legal first move; Setup checks it); the design shows the slice
  needs splitting; an earlier slice's test needs changing; or the user rejects the design at the
  gate and no revision converges. If RED already committed failing tests, get back to green first:
  delete RED's still-failing tests, keep the passing ones, and commit; the state file stays as the
  record. The host re-slices or abandons from there.
- **Keep decision context in the state file's `Learned` line**, which the host folds into the
  squash commit. Keep the design doc in the state file too, never a second file: the host's disk
  checks expect nothing new in the plans directory but your one state file.

## State File

Maintain a state file at `<plans-dir>/atdd-<feature-slug>-<NN>.md` — see
[state-format.md](state-format.md) for the format, directory choice (the plans directory
slice-plan is already using), and naming. It rides along in commits, so rolling back a commit
restores code and session state together; the boundary's squash keeps it out of the slice's diff.

**Rules in Force**, the header at the top of the state file, is copied verbatim at creation and
never edited. This body is read into the conversation once, and RESEARCH & DESIGN in particular can
run long enough to dilute or compact it out; the file survives that. Each phase below says when to
re-read the header; do it unconditionally. If a resumed state file's header is missing or differs
from the block in [state-format.md](state-format.md), replace it wholesale and verbatim before
continuing.

**Write** the state file at: creation; end of ACCEPT (the acceptance-test table); end of
RESEARCH & DESIGN (design summary, review findings, gate outcome); end of RED (per-test
verification and mutation check results); during GREEN, pressure-log appends only — milestone
commits carry the position; end of REVIEW (findings triaged, lint result); SHIP (hand-back line).
Keep the diff quiet: append entries and tick checkboxes, never reflow unchanged prose.

---

## Startup

Glob `atdd-<feature-slug>-[0-9][0-9].md` in the plans directory slice-plan is using. A state file
is identifiable by its `# ATDD Session State` heading even if renamed.

- **None found** — start fresh at Setup.
- **Exactly one** — read it. If its recorded slice behavior sentence differs from the plan's, it
  is stale (the host re-sliced): delete it and start fresh. Otherwise offer to resume: report the
  current phase and behavior sentence, confirm the checked-out branch matches, then continue from
  the recorded phase.
- **More than one** — list them (slice, last-updated) and ask which, or whether to start fresh.

### Setup

1. Read the slice's behavior sentence, criteria, `Kind` and the test runner from the plan file.
   If `Kind` is `refactor` or `scaffolding`, hand back `atdd — blocked: <kind> slice, no test-first
   move` now, before creating anything.
2. Create the state file, starting with the Rules in Force header copied verbatim from
   [state-format.md](state-format.md). Fill in the slice's behavior sentence and criteria from the
   plan — do not re-derive or re-negotiate them here. Do not commit it yet; ACCEPT's commit does.

---

## ACCEPT — Define Acceptance Tests

Before any research or design: enumerate the slice's external, observable behaviors and write one
acceptance test per behavior, each traceable to the slice's behavior sentence or a criterion it
advances — no "and" per test. There is no implementation yet to run them against; writing them
pins the target.

Two priorities, in order, and the second never compromises the first:

1. **Human-executable proof that the behavior was achieved.** Every row's proof is written to
   this bar first: exact steps a human runs and exactly what they'd see, in whatever form actually
   demonstrates *this* behavior — a curl and its response, a sequence of UI actions and what's on
   screen after, running a job and where to look at its effect (an output file, a log line, a row
   in a store). This is the acceptance test. Nothing below can shrink or reshape it.
2. **The same proof, agent-runnable, wherever that's possible without weakening priority 1.** Most
   curl-and-API and scripted-browser behaviors qualify as-is — the human proof and the agent proof
   are the same steps. Where they're not, leave the agent side blank rather than substituting an
   easier check that proves something narrower (a 200 status standing in for "the user sees the
   updated dashboard" is exactly the substitution to refuse).

For each behavior, record in the state file's acceptance-test table:

- **Behavior** — one sentence, external, observable.
- **Human proof** — required on every row: the steps and the expected observation, written first,
  to the format that actually proves this behavior. The table has one schema, not one per feature
  type; only this cell's content varies by what the slice is.
- **Agent proof** — the same steps (or an equivalent that proves the same thing) the agent can run
  itself, or blank if none exists without weakening priority 1 — never filled in with a narrower
  check just to have something here.
- **Status** — `pending` until SHIP.

A row with a blank agent proof is confirmed by the user at SHIP by walking the human proof, same
as a row with an agent proof is confirmed by actually running it.

Commit: `git add <state-file> && git commit -m "atdd: acceptance tests for <slice-slug>"`.

---

## RESEARCH & DESIGN — Investigate, Plan, Gate, Handoff

Research and the design doc iterate on each other — a design question sends you back to the
codebase or a web search, a research finding reshapes the design — so step 1 delegates them as one
unit. Step 5 needs the user live, so it stays in the host session.

1. **Research and draft, delegated as one unit.** Hand a subagent the slice's behavior sentence,
   its criteria, and ACCEPT's acceptance tests, and let it run the research-design loop to a
   finished draft inside its own context — read the codebase, search the web, consult whatever
   knowledge bases are available, revise the doc against what it finds. It returns one artifact:
   the design doc (context, proposed approach, the one real alternative considered and the line
   that decided against it, visuals where they'd clarify a flow or data shape a paragraph would only
   restate), plus pointers to the codebase paths it read. A throwaway skeleton implementation is
   optional inside this step — build one when it would make an idea concrete enough for the user to
   react to. Build it in a scratch directory outside the repo, never on the slice branch, so RED's
   `git add -A` cannot sweep it up; delete it once it has served that purpose.
2. **Delegate a design review of the draft to a second, fresh subagent** — not the one that
   drafted it, which is the wrong session to grade its own work. Prompt and bundle in
   [references/review-prompts.md](references/review-prompts.md), §"Design review" — read that
   section before spawning. It gets the draft doc, `design-principles`' vocabulary, and step 1's
   codebase pointers, and checks the design against both: does it fit established patterns here,
   does it hold up against SOLID / component-boundary / simple-design doctrine.
3. **Read the draft and the review findings into the host session, then triage** — fix, or
   dismiss with a stated reason, recorded in the state file. These are the only pieces of the
   research-and-design work that enter the orchestrator's context. If a finding demands more
   research, loop back through step 1. **Re-review (repeat step 2) when the revision changes the
   approach or the rejected alternative; otherwise skip it.**
4. **Re-read the Rules in Force header, then hold the human review gate, in the host session,
   never delegated.** Present the design doc and stop. It has already been vetted against
   design-principles and codebase patterns, so the gate is about direction and trade-offs. Also
   ask the user which acceptance proofs, if any, should be persisted as automated tests in the
   suite. There is no default: automated acceptance tests can be fragile, expensive, and specific
   to the environment, so it is a per-slice conversation. Record the answer in the state file's
   Design section; any you keep are written in RED like other tests. Whatever the answer, the
   slice needs at least one suite test that exercises its behavior sentence, so obligation 2's
   "passing test for the slice's behavior" is met; name which RED test that will be. Do not proceed to RED until
   the user agrees; silence is not agreement. On pushback, a small revision you make directly; one
   that needs more research or a rethink goes back through step 1, review included.
5. **Handoff.** Once agreed, write the design doc's substance into the state file, and only
   there — durable, not just conversational. The gate conversation itself can have consumed real
   context, so treat the write as a handoff to whatever session runs RED onward.

Commit: `git add <state-file> && git commit -m "atdd: design for <slice-slug>"`.

---

## RED — Unit Tests, Mutation-Checking Only the Ones That Pass Immediately

**Re-read the Rules in Force header first.**

1. **Write unit tests** against the agreed design, one per behavior the implementation needs,
   following `design-principles`' test-quality doctrine (FIRST, behavioral-not-wiring — assert
   observable outcomes, never that one object called another), plus any acceptance proofs the user
   chose to persist as suite tests at the gate. Everything below treats the two alike.
2. **Run each test against current code.** Two outcomes, and they're handled differently:
   - **Fails on the missing behavior** (not an import or fixture error) — this is the normal
     case. Record it and move on; a test proven to fail needs no further proof it can fail.
   - **Passes immediately** — the test never went red, so nothing has proven it actually
     exercises the behavior it claims to. This is the *only* case the mutation check below is
     for. It is not owed to every test, and it is not owed again later — a test that failed here
     and is made to pass in GREEN already has its proof, from having been seen red.
3. **Mutation check — immediately-passing tests only.** Temporarily edit the code the test
   targets so the behavior it claims to check is broken, run the test, confirm it now fails, then
   revert the edit exactly so the tree returns to its prior state. Record the result per test; one
   that doesn't fail under the mutation is not exercising what it claims — fix it or delete it
   before moving on. This is a manual edit/run/revert; no tool dependency.
4. Set the state file's phase to GREEN, then commit with
   `git add -A && git commit -m "atdd: red for <slice-slug>"`. That is the last state write until
   REVIEW, apart from pressure-log appends.

---

## GREEN — Implement

"RED's tests" below means every test written in RED, persisted acceptance proofs included.

- **Implement holistically.** You hold the whole set of RED's tests; design the implementation as
  one piece. Write nothing the tests do not demand.
- **The full suite runs twice in GREEN: entry and exit, never in between.** It's expensive; the
  loop below stays cheap on purpose.
  - **Entry** (once, before implementation starts): the host handed you a green suite, so the set
    of failing tests now must be exactly RED's still-red tests. Any other failure is drift —
    most likely a mutation-check revert that didn't land clean — and is fixed before you start.
  - **Exit**: GREEN does not end until a full-suite run is green. A regression this run turns up
    that the loop below never would have (something outside RED's tests broke) is fixed like any
    other red test, then the full suite runs again — it is not a flat run and does not feed the
    tripwire, which only counts RED's own tests.
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
  flat run since the last milestone, discard the experiment
  ([references/discard.md](references/discard.md)) and drop to a ladder — one failing test at a
  time — until the tests that entangled are passing, then return to holistic. Re-read the header
  as you drop.
- **Pressure log at every milestone**: append *ugliest thing you wrote since the last milestone?*
  and *most annoying test to satisfy so far?* — "nothing" is not a legal answer. Each gets a
  disposition: **steer now** (refactor immediately, never while flat lines are pending) or
  **hold** (REVIEW forces a decision).
- **Two lists take appends in GREEN** besides the pressure log, since a gap or a mis-specified
  test can surface at any moment: `Out of scope` and RED's `Amendments`. Never file either in the
  pressure log, where REVIEW step 0 would dismiss it.
- **Amendment protocol.** If a RED test turns out mis-specified, or a genuinely missing behavior
  within the slice's scope surfaces: halt, state the defect in one line, amend or add the test,
  re-verify it fails for the right reason, commit it alone — `atdd: amend — <reason>` (stage the
  test change by path; if implementation work is uncommitted, stash it first and pop it after).
  Never weaken a test inside an implementation commit. A gap outside the slice's scope is not this
  slice's to fix — add it to the state file's `Out of scope` list, which the host turns into plan
  backlog entries; don't act on it here.
- **Discarding.** Start every refactor step from a clean tree and commit each step that leaves
  every previously passing test passing. A refactor step that breaks a test that passed before it,
  and survives one repair attempt, is discarded per
  [references/discard.md](references/discard.md) — read it before the first refactor.

---

## REVIEW — Blind, Iterated, Then Lint

**Re-read the Rules in Force header first**, and again before each re-review round. The reviewer
sees the diff and the unit tests from RED, and nothing else — not the design doc, not the research
notes, not ACCEPT's table of acceptance proofs (a persisted one is a suite test in the diff, and is
seen like any other test). It reads the code the way a reviewer with no stake in the
plan that produced it would.

0. **Drain the pressure log.** Every `hold` gets a disposition now — fix, or dismiss with a
   reason — and the log ends this step empty.
1. **Delegate to a fresh subagent.** Prompt and bundle in
   [references/review-prompts.md](references/review-prompts.md), §"REVIEW's blind review" — read it
   before spawning. The diff base is the previous slice's branch, from the plan's Slices section
   (the Session's base branch, for slice 01). Each finding comes back tagged `structural-if-fixed` (fixing it would move
   responsibilities, add or merge types, or change contracts) or `local`.
2. **Triage every finding** into one of three: **fix** and re-run the suite; **dismiss** with a
   one-line reason; or **backlog** it. The blind reviewer cannot see the plan and will rank two
   kinds of finding highly; both are backlog entries however cheap. One asks to tighten an
   earlier slice's or the steel thread's test to assert exactly the current output — that test
   pins the seam, and tightening it deadlocks the next slice. The other asks for behavior this
   slice does not have, such as a missing error path. Record all three dispositions in the state
   file's REVIEW section; the host shows the user every dismissal. Every fix starts from a clean
   tree and commits after each green step; a fix that breaks a test that passed before it, and
   survives one repair attempt, is discarded per [references/discard.md](references/discard.md).
3. **Re-review on structure.** If any fix you applied was tagged `structural-if-fixed`, delegate
   another fresh round over the new diff and repeat from step 2. `local` fixes never re-enter.
   Hard cap: three rounds. A structural finding still open after round three, or a structural
   fix applied in round three (which no reviewer sees), goes in the state file's `Open at cap`
   list — surfaced to the user by the host, never dropped.
4. **Lint.** Find the project's lint command — check the project's scripts, Makefile, CI config
   and linter config files — and record it in the state file's Session. Run it over the diff; fix
   or justify every finding the same way, with the same discard rule. If the project has no
   linter, record `Lint: none found` and say so at SHIP; gate item 3 then passes vacuously.
5. Commit: `git add -A && git commit -m "atdd: review fixes for <slice-slug>"` if anything
   changed. Code changed after this point (SHIP's fixes) is unreviewed; list each such change
   under `Open at cap` as unreviewed.

---

## SHIP — Gate and Hand Back

**Re-read the Rules in Force header first.** Gate on all four, together, before touching the
boundary:

1. **Acceptance tests** — run every row from ACCEPT that has an agent proof, against the finished
   code; mark each `pass`/`fail` in the state file. For every row with a blank agent proof, walk
   the human proof with the user and record their confirmation — do not mark one `pass` yourself.
2. **Unit tests** — full suite green.
3. **Lint** — clean per REVIEW, or `none found`.
4. **Review** — REVIEW's findings all fixed, dismissed with a reason, backlogged, or listed under
   `Open at cap`.

A failure here means fix it and re-check all four, since a fix can regress another (acceptance
proofs included, after the last review fix). Every code change made at SHIP is unreviewed: list it
under `Open at cap` as unreviewed. Once all four hold, write the SHIP results into the state file
and commit everything (`git add -A`, message `atdd: ship <slice-slug>`), confirm `git status
--short` is clean, write the Attempts line `atdd — handed back` (or
`atdd — blocked: <what stopped it>`) in the plan slice-plan maintains, and hand back — no squash,
no PR; the host squashes, and presents your `Dismissed` and `Open at cap` lists to the user.
