---
name: slice-tdd
description: "Executes one slice-plan slice test-first, in `acceptance` mode (acceptance tests a human can run, human design gate) or `internal` mode (behavior list, no gate). Use when slice-plan hands a slice to `acceptance` or `internal`; with no plan file, use slice-plan first."
compatibility: "Requires slice-plan as host, plus design-principles, design-review, backfill-tests and refactor (its standard is the TIDY production checklist). Requires subagent delegation, with no in-session fallback. Requires git."
metadata:
  soft-deps: slice-plan design-principles design-review backfill-tests refactor
---

# Slice TDD

One slice, test-first, run so the host session holds almost nothing: every heavy step — research,
review, building — is delegated to a fresh subagent, and the host keeps only triage and the user's
decisions. That is what lets a long slice list run in one host session instead of a new session per
slice.

Two modes, chosen by the host, differing in one thing — **what the slice is proven against**:

- **`acceptance`**: acceptance tests a human can run and observe, written before any
  design, and a **human design gate** before any code.
- **`internal`**: a behavior list, drafted with the design. No ACCEPT, no gate,
  no acceptance item at SHIP.

Everything else is the same in both. One pass — ACCEPT (`acceptance` only) → DESIGN → BUILD → REVIEW →
SHIP — delivers one slice. BUILD is one delegated unit: MAKE ROOM (pin and prepare untested code
about to change), RED, GREEN, TIDY (refactor and coverage).

## Hosted by slice-plan

This skill runs as a guest under slice-plan, which hands it an override block (its `slice-tdd`
adaptation, in slice-plan's `references/hosted-handoff.md`) owing five things: stay on the branch
the host cut, leave your targeted tests green with a passing test for the slice's behavior, write
only your own state file and Attempts line, commit as you go, and hand back before the squash. The
block names your mode — `acceptance` or `internal` — and that name is also `<strategy>` on every
Attempts line you write. It may also carry a *pause* paragraph: then, after the design commit, you
hand back `<strategy> — paused: design done`, and the host invokes you again to resume at BUILD. **Where the block conflicts with a phase below, the block wins**, with
one exception it grants: this skill runs its own REVIEW before hand-back (see REVIEW).

What that means here:

- **Setup is only the `Kind` check and the state file**; make no "begin" commit.
- **`acceptance`'s human design gate survives** the block's "skip your alignment gate": that gate is
  feature-level and already passed; this one is per slice.
- **Hand back `<strategy> — blocked: <what stopped it>`** — leaving your tests green and
  committing any complete work — when Setup's `Kind` check fails; the design shows the slice needs
  splitting; MAKE ROOM outgrows a few commits; or, in
  `acceptance`, the user rejects the design at the gate and no revision converges. The host re-slices or
  abandons from there.
- **Keep decision context in the state file's `Learned` line**, which the host folds into the
  squash commit. Keep the design doc in the state file too, never a second file: the host's disk
  checks expect nothing new in the plans directory but your one state file.

## State File

Maintain a state file at `<plans-dir>/slice-tdd-<feature-slug>-<NN>.md`, in the plans directory
slice-plan is using, in the format of [state-format.md](state-format.md). It rides along in
commits, so rolling back a commit restores code and session state together.

**Rules in Force**, the header at the top of the state file, is copied verbatim at creation and
never edited. This body is read into the conversation once, and a long slice dilutes or compacts it
out; the file survives that. Each phase below says when to re-read the header; do it
unconditionally. If a resumed state file's header is missing or differs from the block in
[state-format.md](state-format.md), replace it wholesale and verbatim before continuing.

Keep its diff quiet: append entries and tick checkboxes, never reflow unchanged prose.

**Every phase's closing commit sets `Current Position`'s phase to the next phase** — ACCEPT →
DESIGN → MAKE ROOM → RED → GREEN → TIDY → REVIEW → SHIP — so the recorded phase is always where
work resumes. Setup records the first (ACCEPT, or DESIGN in `internal` mode). A phase recorded as
MAKE ROOM, RED, GREEN or TIDY means BUILD: the host delegates it, and the delegate resumes at that
phase.

---

## Startup

Look for `slice-tdd-<feature-slug>-<NN>.md` in the plans directory slice-plan is using.

- **Not found** — start fresh at Setup.
- **Found** — read it. If its recorded slice behavior sentence or mode differs from the
  plan's and the block's, it is stale (the host re-sliced or switched strategy): `git rm -f` it,
  commit that, and start fresh. Otherwise resume without asking — the host invoked you on this
  slice, which is the decision: confirm the checked-out branch matches Session's `Branch`, say in
  one line which phase you resume at, and continue from the recorded phase. Work after a phase's
  last commit is redone — including, in `acceptance` mode, a gate the user passed before the design
  commit landed: present the design again rather than assume the agreement.

### Setup

1. Read the slice's behavior sentence, criteria, `Kind`, the plan's Constraints, and the
   Session's test runner and base branch from the plan file, and the mode and branch from the
   block. A slice with no `Kind` line is `behavioral`. If `Kind` is `refactor` or `scaffolding`,
   hand back `<strategy> — blocked: <kind> slice, no test-first move` now, before creating
   anything.
2. Create the state file, starting with the Rules in Force header copied verbatim from
   [state-format.md](state-format.md). Fill in Session — mode, branch, base branch, test runner —
   and the slice's behavior sentence, criteria and Constraints, copied from the plan, not
   re-derived or re-negotiated here: every delegate reads this file, not the plan. Set its phase to ACCEPT
   (`acceptance` mode) or DESIGN (`internal` mode). Do not commit it yet; that phase's commit does.

---

## ACCEPT — Define Acceptance Tests (`acceptance` mode only)

In `internal` mode, skip to DESIGN; the behavior list it drafts is the target this phase would
have set.

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

Record each behavior as a row of the state file's acceptance-test table, Status `pending`.

Set the phase to DESIGN, then commit:
`git add <state-file> && git commit -m "slice-tdd: acceptance tests for <slice-slug>"`.

---

## DESIGN — Research, Draft, Review, Gate, Handoff

Research and the design doc iterate on each other — a design question sends you back to the
codebase or a web search, a research finding reshapes the design — so step 1 delegates them as one
unit. Only step 3's triage and `acceptance`'s gate run in the host session.

**If the block carries the pause paragraph, both delegates below are read-only:** add to each
bundle "the host's full-suite run is using this tree: run no tests, and write nothing inside the
repository." Reading code is fine; probing behavior by running it waits for BUILD.

1. **Research and draft, delegated as one unit.** Hand a subagent the slice's behavior sentence,
   its criteria, the Constraints, and — in `acceptance` mode — ACCEPT's acceptance tests, and let it run the
   research-design loop to a finished draft inside its own context — read the codebase, search the
   web, consult whatever knowledge bases are available, revise the doc against what it finds.
   Include in the bundle, verbatim: "Preserve existing behavior the behavior sentence doesn't
   change; existing structure is material, not a constraint — where its shape doesn't fit, reshape
   it rather than work around it." It returns one artifact, containing:
   - **In `internal` mode, the behavior list** — the individual observable behaviors that
     together deliver the behavior sentence, one sentence each, no "and", each traceable to the
     sentence or a criterion this slice advances. This is the slice's target, as ACCEPT's table is
     in `acceptance` mode. A behavior that does not trace is not this slice's.
   - **The interface sketch** — names, signatures, types and errors, as consumers will see them.
   - **The design doc** — context, proposed approach, the one real alternative considered and the
     line that decided against it, visuals where they'd clarify a flow or data shape a paragraph
     would only restate.
   - **Which suite test will exercise the behavior sentence**, so obligation 2's "passing test for
     the slice's behavior" is met.
   - **The files the design will modify**, and pointers to every codebase path it read.

   A throwaway skeleton implementation is optional inside this step — built when it would make an
   idea concrete enough to react to. Build it in a scratch directory outside the repo, never on the
   slice branch, so BUILD's `git add -A` cannot sweep it up; delete it once it has served that
   purpose.
2. **Delegate a design review of the draft to a second, fresh subagent** — not the one that
   drafted it, which is the wrong session to grade its own work. Prompt and bundle in
   [references/review-prompts.md](references/review-prompts.md), §"Design review" — read that
   section before spawning. It reads the code *around* the change, not only the files the design
   modifies.
3. **Re-read the Rules in Force header, read the draft and the review findings into the host
   session, then triage** — fix, or
   dismiss with a stated reason, recorded in the state file. These are the only pieces of the
   design work that enter the host's context. If a finding demands more research, loop back
   through step 1. **Re-review (repeat step 2) when the revision changes the approach, the
   interface, or the rejected alternative; otherwise skip it.**
4. **`acceptance` mode: re-read the Rules in Force header, then hold the human review gate, in the host
   session, never delegated.** Present the design doc and stop. It has already been vetted against
   design-principles and codebase patterns, so the gate is about direction and trade-offs. Also
   ask the user which acceptance proofs, if any, should be persisted as automated tests in the
   suite. There is no default: automated acceptance tests can be fragile, expensive, and specific
   to the environment, so it is a per-slice conversation. Record the answer in the state file's
   Design section; any you keep are written in RED like other tests. Do not proceed to BUILD until
   the user agrees; silence is not agreement. On pushback, a small revision you make directly; one
   that needs more research or a rethink goes back through step 1, review included.

   `internal` mode has no gate: a design that needs a new interface or contract the slice did not
   expect surfaces later as BUILD's `departure`, which goes to the user then.
5. **Handoff.** Write the design's substance — behavior list (`internal`), interface sketch,
   design doc, the named behavior-sentence test, the files to modify — into the state file, and
   only there. BUILD's delegate reads nothing else, so treat the write as a handoff.

Set the phase to MAKE ROOM, then commit:
`git add <state-file> && git commit -m "slice-tdd: design for <slice-slug>"`. If the block carries
the pause paragraph, follow it now.

---

## BUILD — MAKE ROOM, RED, GREEN and TIDY, Delegated as One Unit

BUILD is where the context goes: pinning tests, test runs, mutation checks, implementation
attempts, discards, refactors. None of it needs the user — amendments, out-of-scope gaps and the
pressure log all land in the state file, and position lives in commits — so the host hands all of
it to one subagent and keeps only what comes back. One subagent, not one per phase: GREEN's
amendment protocol edits RED's tests, and the session that wrote them knows what they were meant to
pin; a resumed delegate gets that from RED's per-test table instead. The phases themselves are in
[references/build.md](references/build.md), written for the subagent.

1. **Delegate to a fresh subagent** after the design commit, and whenever a resume lands in BUILD
   (Startup, or a paused slice invoked again). Give it only: the absolute repo path, stated as its
   working directory; the state file's absolute path; and the absolute path of
   `references/build.md`, as its instructions. Do not hand it this file. It returns one line —
   `exit: <sha>`, `departure: <what> at <sha>` or `blocked: <what> at <sha>` — with the tree clean
   and committed.
2. **Back in the host, read the state file, never the diff.** Re-read the Rules in Force header,
   and confirm `git status --short` is clean and `HEAD` is the returned sha. If either check fails,
   send a fresh subagent once more with the same bundle (it resumes from the state file); a second
   failure stops the slice — tell the user what you found, and do not hand back over a dirty tree.
3. **Act on the return.**
   - **`exit`** — go on to REVIEW. The code itself is read only by REVIEW's subagent.
   - **`departure`** — the implementation needs something the agreed design doesn't cover. Take
     it to the user, scoped to the departure — in `acceptance` mode as a re-run of the human gate (DESIGN
     step 4); in `internal` mode this is the first time the user sees the design, so show the
     interface sketch with it. Agreed: record it in the state file's Design section, commit, and
     delegate again. Rejected: delegate again with the user's constraint added to the Design
     section; if no implementation fits it, the delegate returns `blocked`.
   - **`blocked`** — the delegate has already got back to green. Write the Attempts line
     `<strategy> — blocked: <what stopped it>` and hand back per *Hosted by slice-plan*.

---

## REVIEW — Blind, Iterated, Then Lint

**Re-read the Rules in Force header first**, and again before each re-review round. The reviewer
is blind: it sees the diff and its tests, nothing of the plan. The host only triages: every fix and the lint run go to a **fix delegate**, whose
instructions are [references/fix.md](references/fix.md).

**Entering REVIEW fresh** — no `## Review` section yet — add it from the template now, copy the
`## Out of Scope` section's entries into its `Out of scope` list, and start at step 0. **Resuming**
— the section exists — never re-add it: read `Rounds` and the lists, and continue where they show
the work stopped — a non-empty `To fix` resumes at step 3, and an empty one after a recorded round
at step 4's check. The round count carries over; a resume never resets the cap.

0. **Drain the pressure log.** Every `hold` gets a disposition now — fix, or dismiss with a
   reason, which goes to `## Review`'s `Dismissed` like any reviewer finding so the user sees it —
   and the log ends this step empty. Counter lines (`flat run N of 3`, `count reset`) are
   not observations and need none. A `hold` to fix joins step 2's `To fix` list.
1. **Delegate the review to a fresh subagent.** Prompt and bundle in
   [references/review-prompts.md](references/review-prompts.md), §"REVIEW's blind review" — read it
   before spawning. The diff base is the previous slice's branch, from the plan's Slices section
   (the state file's Session `Base branch`, for slice 01). Each finding comes back tagged `structural-if-fixed`
   (fixing it would move responsibilities, add or merge types, or change contracts) or `local`.
2. **Triage every finding** into one of three: **fix**, **dismiss** with a one-line reason, or
   **backlog** it. The blind reviewer cannot see the plan and will rank two kinds of finding
   highly; both are backlog entries however cheap. One asks to tighten an earlier slice's or the
   steel thread's test to assert exactly the current output — that test pins the seam, not the
   content. The other asks for behavior this slice does not have,
   such as a missing error path. Record the round in `Rounds`, and write fixes to the `## Review`
   section's `To fix` list, each with its tag, and dismissals and backlog entries to their lists; the host shows the user every
   dismissal. Commit the state file.
3. **Delegate the fixes.** Give a fresh subagent only: the absolute repo path, as its working
   directory; the state file's absolute path; the absolute path of `references/fix.md`, as its
   instructions; and the job `review fixes`. It returns `exit: <sha>`, `departure: <what> at
   <sha>` or `blocked: <what> at <sha>`, with the tree clean and committed, every `To fix` entry
   moved to `Fixed` or — a fix it had to discard — to `Open at cap`. Check its return as BUILD
   step 2 does. On `blocked`, act as BUILD step 3 does. On `departure`, take it to the user as
   BUILD step 3 does, then **re-send a fix delegate, not BUILD's**, with the agreed change or the
   user's constraint recorded in the Design section; an agreed departure counts as a
   `structural-if-fixed` fix for step 4.
4. **Re-review on structure.** If any entry now under `Fixed` was tagged `structural-if-fixed`,
   delegate another fresh review round over the new diff and repeat from step 2. `local` fixes
   never re-enter. Hard cap: three rounds. A structural finding still open after round three goes
   in the state file's `Open at cap` list — surfaced to the user by the host, never dropped.
5. **Lint, delegated.** Send a fresh fix delegate with the job `lint`: it finds the project's lint
   command, records it in Session, runs it over the diff, fixes what it can, and records the rest
   in the `Lint` line, each with a reason. Read that line and triage any reason you don't accept
   into `To fix` for one more `review fixes` delegate. No linter: the line reads `none found`, and
   the lint gate item passes vacuously.
6. **List what no reviewer saw.** Every fix applied after the last review round ran — that
   round's fixes, `local` ones included, and every lint fix — goes under `Open at cap` as
   `unreviewed: <change>`, one line each. Then set the phase to SHIP and commit the state file.
   SHIP's fixes join the list the same way.

---

## SHIP — Gate and Hand Back

**Re-read the Rules in Force header first.** Gate on every item, together, before touching the
boundary:

1. **Acceptance tests** (`acceptance` mode only) — run every row from ACCEPT that has an agent proof,
   against the finished code; set each row's Status to `pass`/`fail`. For every row with a
   blank agent proof, walk the human proof with the user and set `pass: user-confirmed` only on
   their confirmation.
2. **Unit tests** — the slice's tests and the targeted tests for every change since RED (review
   and lint fixes included) green on the final code. Not the full suite: the host starts that in
   the background once you hand back.
3. **Lint** — clean per REVIEW, or `none found`.
4. **Review** — REVIEW's findings all fixed, dismissed with a reason, backlogged, or listed under
   `Open at cap`.

A failure here means fix it — as a `To fix` entry and a `review fixes` delegate, per REVIEW step
3 — and re-check every item, since a fix can regress another (acceptance proofs included, after the
last review fix); list each such fix per REVIEW step 6. Once all hold, **check `git status
--short` before adding anything**: running the acceptance proofs can leave files in the repo (a
downloaded response, a job's output), and `git add -A` would ship them — delete what the proofs
left, keep only the slice's own changes. Commit (`git add -A`, message
`slice-tdd: ship <slice-slug>`), confirm `git status --short` is clean, and close the Attempts line
in the plan slice-plan maintains: `<strategy> — handed back: reviewed`, or, if the host left a note
there, `<strategy> — handed back: <note>, reviewed` (or `<strategy> — blocked: <what stopped it>`), and hand back — no squash, no PR; the host squashes, and presents your
`Dismissed` and `Open at cap` lists to the user.
