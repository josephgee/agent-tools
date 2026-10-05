---
name: atdd
description: "Executes one slice-plan slice acceptance-test-first, with a human design gate before any code. Use when a slice delivers behavior a user can observe and should be proven through that external behavior — the default for user-facing slices, settled design or not, since a meaningful functionality change is when a design should be re-examined — or when asked for ATDD or acceptance-test-driven development. Flow: acceptance tests (human-executable proof first, agent-runnable where that doesn't weaken it), research and a reviewed design doc, user sign-off, unit tests then implementation, a blind code review iterated to clean, lint, then a final gate on acceptance tests, unit tests, lint and review. Runs in-session, hosted by slice-plan (with no plan file, use slice-plan first). Prefer tdd-batch for slices that are mostly edge cases, where external proof of each costs more to set up than it validates."
compatibility: "Requires slice-plan as host (it executes one slice and does no feature-level planning), plus design-principles and design-review, whose vocabulary RED's tests and both reviews use. Requires a way to delegate to an isolated subagent: research, the design review and the code review each run outside the session that wrote what they review, and RED and GREEN run delegated to keep their churn out, with no in-session fallback. Requires git."
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
the host cut, leave your targeted tests green with a passing test for the slice's behavior, write only your
own state file and Attempts line, commit as you go, and hand back before the squash. It may
also carry a *pause* paragraph: then, after the design commit, you record phase RED and hand back
`atdd — paused: design agreed`, and the host invokes you again to resume at RED. **Where the
block conflicts with a phase below, the block wins**, with one exception it grants: this skill runs
its own REVIEW before hand-back (see REVIEW).

What that means here:

- **Setup is only the `Kind` check and the state file.** The block skips setup because the tree
  is clean, the baseline is green and the test runner is in the plan's Session; make no "begin"
  commit. The state file is committed with ACCEPT's commit. The lint command is not in the plan;
  REVIEW finds it.
- **The human design gate survives** the block's "skip your alignment gate": that gate is
  feature-level and already passed; this one is per slice.
- **Hand back `atdd — blocked: <what stopped it>`** — leaving your tests green and committing any
  complete work — when: the plan records this slice's `Kind` as `refactor` or `scaffolding` (a
  test-first loop has no legal first move; Setup checks it); the design shows the slice
  needs splitting; an earlier slice's test needs changing; or the user rejects the design at the
  gate and no revision converges. If RED already committed failing tests, get back to green first:
  delete RED's still-failing tests, keep the passing ones, and commit; the state file stays as the
  record. (Inside RED and GREEN the delegate does this before it returns `blocked`.) The host re-slices or abandons from there.
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
verification and mutation check results); during GREEN, appends only, committed by GREEN's exit —
milestone commits carry the position; end of REVIEW (findings triaged, lint result); SHIP (hand-back line).
Keep the diff quiet: append entries and tick checkboxes, never reflow unchanged prose.

---

## Startup

Glob `atdd-<feature-slug>-[0-9][0-9].md` in the plans directory slice-plan is using. A state file
is identifiable by its `# ATDD Session State` heading even if renamed.

- **None found** — start fresh at Setup.
- **Exactly one** — read it. If its recorded slice behavior sentence differs from the plan's, it
  is stale (the host re-sliced): `git rm -f` it, commit that, and start fresh. Otherwise offer to resume: report the
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
unit. Step 4 needs the user live, so it stays in the host session.

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
   section before spawning. It gets the draft doc, ACCEPT's acceptance tests, `design-principles`'
   vocabulary, and step 1's codebase pointers, and checks the design against all of them: does it
   deliver every acceptance test, does it fit established patterns here, does it hold up against
   SOLID / component-boundary / simple-design doctrine.
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

## RED & GREEN — Delegated as One Unit

RED and GREEN are where the context goes: test runs, mutation checks, implementation attempts,
discards. None of it needs the user — amendments, out-of-scope gaps and the pressure log all land in
the state file, and position lives in commits — so the host hands both phases to one subagent and
keeps only what comes back. One subagent, not one per phase: GREEN's amendment protocol edits RED's
tests, and the session that wrote them knows what they were meant to pin; a resumed delegate gets
that from RED's per-test table instead. The phases themselves are in
[references/red-green.md](references/red-green.md), written for the subagent.

1. **Delegate to a fresh subagent** after the design commit, and whenever a resume lands in RED or
   GREEN (Startup, or a paused slice invoked again). Give it only: the absolute repo path, stated
   as its working directory; the state file's absolute path; and the absolute path of
   `references/red-green.md`, as its instructions. Do not hand it this file. It returns one line —
   `exit`, `departure` or `blocked`, each `at <sha>` — with the tree clean and committed.
2. **Back in the host, read the state file, never the diff.** Re-read the Rules in Force header,
   and confirm `git status --short` is clean and `HEAD` is the returned sha. If either check fails,
   send a fresh subagent once more with the same bundle (it resumes from the state file); a second
   failure stops the slice — tell the user what you found, and do not hand back over a dirty tree.
3. **Act on the return.**
   - **`exit`** — go on to REVIEW. The code itself is read only by REVIEW's subagent.
   - **`departure`** — the implementation needs something the agreed design doesn't cover. Take
     it to the user as a re-run of the human gate (RESEARCH & DESIGN step 4), scoped to the
     departure. Agreed: record it in the state file's Design section, commit, and delegate again.
     Rejected: delegate again with the user's constraint added to the Design section; if no
     implementation fits it, the delegate returns `blocked`.
   - **`blocked`** — the delegate has already got back to green. Write the Attempts line
     `atdd — blocked: <what stopped it>` and hand back per *Hosted by slice-plan*.

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
   (the Session's base branch, for slice 01). Each finding comes back tagged `structural-if-fixed`
   (fixing it would move responsibilities, add or merge types, or change contracts) or `local`.
2. **Triage every finding** into one of three: **fix** and re-run RED's tests and any tests
   touching the change (the full suite is the host's, after hand-back);
   **dismiss** with a one-line reason; or **backlog** it. The blind reviewer cannot see the plan
   and will rank two kinds of finding highly; both are backlog entries however cheap. One asks to tighten an
   earlier slice's or the steel thread's test to assert exactly the current output — that test
   pins the seam, and tightening it deadlocks the next slice. The other asks for behavior this
   slice does not have, such as a missing error path. Record all three dispositions in the state
   file's `## Review` section; the host shows the user every dismissal. Every fix starts from a clean
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
2. **Unit tests** — RED's tests and the targeted tests for every change since RED (review and
   lint fixes included) green on the final code. Not the full suite: the host starts that in the
   background once you hand back.
3. **Lint** — clean per REVIEW, or `none found`.
4. **Review** — REVIEW's findings all fixed, dismissed with a reason, backlogged, or listed under
   `Open at cap`.

A failure here means fix it and re-check all four, since a fix can regress another (acceptance
proofs included, after the last review fix). Every code change made at SHIP is unreviewed: list it
under `Open at cap` as unreviewed, and re-run the targeted tests before writing the hand-back
line, since it moved the code. Once all four hold, write the SHIP results into the state file
and commit everything (`git add -A`, message `atdd: ship <slice-slug>`), confirm `git status
--short` is clean, write the Attempts line `atdd — handed back: reviewed` (or
`atdd — blocked: <what stopped it>`) in the
plan slice-plan maintains, keeping any note the host left there, and hand back — no squash, no PR;
the host squashes, and presents your `Dismissed` and `Open at cap` lists to the user.
