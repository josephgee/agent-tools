---
name: slice-tdd
description: "Builds one slice test-first under a host's handoff block, in `acceptance` mode (acceptance tests a human can run, human design gate) or `internal` mode (behavior list, no gate) — or, where a unit test could only restate the code, in `yolo` mode (`acceptance` without unit tests) — and hands back a report. Use when a build loop such as slice-loop hands a slice to `acceptance`, `internal` or `yolo` with its handoff block; without a block, it does nothing — point the user to a loop."
compatibility: "Requires a host that hands it the handoff block — slice-loop ships that block, and any loop that fills it in will do. Requires design-principles, design-review, backfill-tests and refactor (its standard is the TIDY production checklist). Requires subagent delegation, with no in-session fallback. Requires git."
metadata:
  soft-deps: design-principles design-review backfill-tests refactor
---

# Slice TDD

One slice, test-first, run so the main session holds almost nothing: every heavy step — research,
review, building — is delegated to a fresh subagent, and the main session keeps only triage and the
user's decisions. That is what lets a long slice list run in one session instead of a new session
per slice.

Two words are kept apart throughout: **the host** is the loop that handed you the block and gets
your report; **the main session** is you, running this skill, as opposed to the subagents you
delegate to.

Three modes, chosen by the host, differing in one thing — **what the slice is proven against**:

- **`acceptance`**: acceptance tests a human can run and observe, written before any
  design, and a **human design gate** before any code.
- **`internal`**: a behavior list, drafted with the design. No ACCEPT, no gate,
  no acceptance item at SHIP.
- **`yolo`**: ACCEPT's acceptance tests alone, with the gate — for a slice where a unit test could
  only restate the code (a query string passed through to a vendor). BUILD writes no unit tests:
  RED and GREEN become one IMPLEMENT phase, and TIDY checks no coverage.

Everything else is the same in all three. One pass — ACCEPT (not `internal`) → DESIGN → BUILD →
REVIEW → SHIP — delivers one slice. BUILD is one delegated unit: MAKE ROOM (pin and prepare untested code
about to change), RED, GREEN (IMPLEMENT in `yolo`), TIDY (refactor and coverage).

## Hosted

This skill runs only as a guest, under a host's handoff block. **With no block, do nothing**: say
this skill needs a host such as `slice-loop`, and stop. The block carries everything this skill
reads — the slice's behavior, `Kind`, criteria, Constraints, test runner, base branch, branch,
plans directory, feature slug, slice number (the block's PR number), mode, report path, design document and the plan's path, read-only — and owes five things: stay on
the branch the host cut, leave your targeted tests green with a passing test for the slice's
behavior, build only this slice and write no host file, commit as you go, and hand back before the
squash, with a report. The block names your mode — `acceptance`, `internal` or `yolo` — which is
also the name on your report's Outcome. It may carry a *pause* paragraph: then, after the design
commit, you report `<mode> — paused: design done`, and the host invokes you again to resume at
BUILD. **Where the block conflicts with a phase below, the block wins**, with one exception it
grants: this skill runs its own REVIEW before hand-back.

What that means here:

- **The human design gate (`acceptance`, `yolo`) survives** the block's "skip your alignment gate":
  that gate is feature-level and already passed; this one is per slice.
- **Report `<mode> — blocked: <what stopped it>`** — leaving your tests green, committing any
  complete work and keeping the state file — when Setup's `Kind` check fails; the design shows the
  slice needs splitting; MAKE ROOM outgrows a few commits; or, in `acceptance` or `yolo`, the user
  rejects the design at the gate and no revision converges. The host re-slices or abandons from
  there.

### The report

Write it to the block's report path in the block's six-heading format, every heading present
— `none` where empty. Fill it from the state file:

- **Outcome** — `<mode> — handed back`, `<mode> — blocked: …` or `<mode> — paused: design done`.
- **Review** — `reviewed`, then `## Review`'s `Dismissed`, `Backlogged`, `Open at cap` and
  `Out of scope` lists — **only once REVIEW step 6 has committed**. Before that, `none`, even if a
  `## Review` section exists: a partial review reported as `reviewed` makes the host skip its own.
- **Criteria proof** — the Design section's `Criteria tests`, each line with the result SHIP
  recorded on it; in `yolo`, each row's agent proof marked `read-only` or `mutating`.
- **Carry-forward** — `## Out of Scope` entries not already listed under this report's Review
  heading, and every `## Earlier Tests Updated` line.
- **Later-PR discoveries** — the `## Later-PR Discoveries` section.
- **Learned** — the `Learned` line.

A `paused` report carries `none` under every heading but Outcome. Leave the report untracked:
never `git add` it or delete it, even where `git status` lists it — it is the host's to remove.

## State File

Maintain a state file at `<plans-dir>/slice-tdd-<feature-slug>-<NN>.md`, with the values the
block gives, in the format of [state-format.md](state-format.md). It rides along in commits, so
rolling back a commit restores code and session state together, and the hand-back's last commit
removes it.

**Rules in Force**, the header at the top of the state file, is copied verbatim at creation and
never edited. This body is read into the conversation once, and a long slice dilutes or compacts it
out; the file survives that. Each phase below says when to re-read the header; do it
unconditionally. If a resumed state file's header is missing or differs from the header in
[state-format.md](state-format.md), replace it wholesale and verbatim before continuing.

Keep its diff quiet: append entries and tick checkboxes, never reflow unchanged prose.

**Every phase's closing commit sets `Current Position`'s phase to the next phase** — ACCEPT →
DESIGN → MAKE ROOM → RED → GREEN (IMPLEMENT in `yolo`) → TIDY → REVIEW → SHIP → HAND BACK — so the recorded
phase is always where work resumes. Setup records the first (ACCEPT, or DESIGN in `internal` mode).
A phase recorded as MAKE ROOM, RED, GREEN, IMPLEMENT or TIDY means BUILD: the main session delegates it, and the delegate resumes at that
phase.

---

## Startup

Look for `slice-tdd-<feature-slug>-<NN>.md` in the block's plans directory.

- **Not found** — if a report already sits at the block's report path, this slice was handed back:
  say so and stop. Otherwise start fresh at Setup.
- **Found** — read it. If its recorded slice behavior sentence or mode differs from the
  block's, it is stale (the host re-sliced or switched strategy): `git rm -f` it,
  commit that, and start fresh. Otherwise resume without asking — the host invoked you on this
  slice, which is the decision: confirm the checked-out branch matches Session's `Branch`, say in
  one line which phase you resume at, and continue from the recorded phase. Work after a phase's
  last commit is redone — including, in `acceptance` or `yolo` mode, a gate the user passed before the design
  commit landed: present the design again rather than assume the agreement.

### Setup

1. Read the block. If `Kind` is `refactor` or `scaffolding`, report
   `<mode> — blocked: <kind> slice, no test-first move` now, before creating anything.
2. Create the state file, starting with the Rules in Force header copied verbatim from
   [state-format.md](state-format.md). Fill in Session — mode, branch, base branch, test runner,
   plan, design,
   report path — and the slice's behavior sentence, criteria and Constraints, copied from the
   block, not re-derived or re-negotiated here: every delegate reads this file, not the block. Set its phase to ACCEPT
   (`acceptance`, `yolo`) or DESIGN (`internal`). Do not commit it yet; that phase's commit does.

---

## ACCEPT — Define Acceptance Tests (`acceptance` and `yolo` modes)

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

Record each behavior as a row of the state file's acceptance-test table, Status `pending`. In
`yolo` these rows are the slice's only proof, so priority 2 matters more: an agent proof that asks
the real system whether it accepts the change (a vendor's validate endpoint, a dry run) is worth
finding. Mark each agent proof `read-only` or `mutating` (it writes to a real system, such as
sending a test notification): BUILD reruns only the read-only ones.

Set the phase to DESIGN, then commit:
`git add <state-file> && git commit -m "slice-tdd: acceptance tests for <slice-slug>"`.

---

## DESIGN — Research, Draft, Review, Gate, Handoff

Research and the design doc iterate on each other — a design question sends you back to the
codebase or a web search, a research finding reshapes the design — so step 1 delegates them as one
unit. Only step 3's triage and `acceptance`'s gate run in the main session.

**If the block carries the pause paragraph, both delegates below are read-only:** add to each
bundle "the host's full-suite run is using this tree: run no tests, and write nothing inside the
repository." Reading code is fine; probing behavior by running it waits for BUILD.

1. **Research and draft, delegated as one unit.** Hand a subagent the slice's behavior sentence,
   its criteria, the Constraints, the Session's Design document if there is one (context, not a
   decision), and — unless `internal` — ACCEPT's acceptance tests, and let it run the
   research-design loop to a finished draft inside its own context — read the codebase, search the
   web, consult whatever knowledge bases are available, revise the doc against what it finds.
   Include in the bundle, verbatim: "Preserve existing behavior the behavior sentence doesn't
   change; existing structure is material, not a constraint — where its shape doesn't fit, reshape
   it rather than work around it." It returns one artifact, containing:
   - **In `internal` mode, the behavior list** — the individual observable behaviors that
     together deliver the behavior sentence, one sentence each, no "and", each traceable to the
     sentence or a criterion this slice advances. This is the slice's target, as ACCEPT's table is
     in `acceptance` mode. A behavior that does not trace is not this slice's.
   - **The interface sketch** — names, signatures, types and errors, as consumers will see them;
     every new parameter, dependency or global with each layer that receives it; and each branch
     decision with the one place it is made, passed on from there as data.
   - **The design doc** — context, proposed approach, the one real alternative considered and the
     line that decided against it, visuals where they'd clarify a flow or data shape a paragraph
     would only restate.
   - **Which suite test will exercise the behavior sentence**, so obligation 2's "passing test for
     the slice's behavior" is met, and **which test satisfies each criterion advanced** — one line
     per criterion; in `yolo`, the ACCEPT row instead.
   - **Anything it learned that changes work the plan gives a later PR.** Include the Session's
     Plan path in the bundle as read-only context for this: its later PRs show what is not this
     slice's work.
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
3. **Re-read the Rules in Force header, read the draft and the review findings into the main
   session, then triage** — fix, or
   dismiss with a stated reason, recorded in the state file. In `yolo`, a draft with logic of its
   own — a branch, a transformation — is a finding: that logic needs unit tests, so the slice
   needs another mode. These are the only pieces of the
   design work that enter the main session's context. If a finding demands more research, loop back
   through step 1. **Re-review (repeat step 2) when the revision changes the approach, the
   interface, or the rejected alternative; otherwise skip it.**
4. **`acceptance` and `yolo` modes: re-read the Rules in Force header, then hold the human review gate, in the main
   session, never delegated.** Present the design doc and stop. It has already been vetted against
   design-principles and codebase patterns, so the gate is about direction and trade-offs. Also
   ask the user which acceptance proofs, if any, should be persisted as automated tests in the
   suite. There is no default: automated acceptance tests can be fragile, expensive, and specific
   to the environment, so it is a per-slice conversation. Record the answer in the state file's
   Design section; any you keep are written in BUILD like other tests. Do not proceed to BUILD until
   the user agrees; silence is not agreement. On pushback, a small revision you make directly; one
   that needs more research or a rethink goes back through step 1, review included.

   `internal` mode has no gate: a design that needs a new interface or contract the slice did not
   expect surfaces later as BUILD's `departure`, which goes to the user then.
5. **Handoff.** Write the design's substance — behavior list (`internal`), interface sketch,
   design doc, the named behavior-sentence and criteria tests, the files to modify — into the state
   file, and only there; later-PR findings go to `## Later-PR Discoveries`. BUILD's delegate reads nothing else, so treat the write as a handoff.

Set the phase to MAKE ROOM, then commit:
`git add <state-file> && git commit -m "slice-tdd: design for <slice-slug>"`. If the block carries
the pause paragraph, follow it now.

---

## BUILD — MAKE ROOM, RED, GREEN and TIDY, Delegated as One Unit

BUILD is where the context goes: pinning tests, test runs, mutation checks, implementation
attempts, discards, refactors. None of it needs the user — amendments, out-of-scope gaps and the
pressure log all land in the state file, and position lives in commits — so the main session hands all of
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
2. **Back in the main session, read the state file, never the diff.** Re-read the Rules in Force header,
   and confirm `git status --short` is clean and `HEAD` is the returned sha. If either check fails,
   send a fresh subagent once more with the same bundle (it resumes from the state file); a second
   failure stops the slice — tell the user what you found, and do not hand back over a dirty tree.
3. **Act on the return.**
   - **`exit`** — go on to REVIEW. The code itself is read only by REVIEW's subagent.
   - **`departure`** — the implementation needs something the agreed design doesn't cover. Take
     it to the user, scoped to the departure — in `acceptance` or `yolo` mode as a re-run of the human gate (DESIGN
     step 4); in `internal` mode this is the first time the user sees the design, so show the
     interface sketch with it. Agreed: record it in the state file's Design section, commit, and
     delegate again. Rejected: delegate again with the user's constraint added to the Design
     section; if no implementation fits it, the delegate returns `blocked`.
   - **`blocked`** — the delegate has already got back to green. Report
     `<mode> — blocked: <what stopped it>` per *Hosted*.

---

## REVIEW — Blind, Iterated, Then Lint

**Re-read the Rules in Force header first**, and again before each re-review round. The reviewer
is blind: it sees the diff and its tests, nothing of the plan. The main session only triages: every fix and the lint run go to a **fix delegate**, whose
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
   before spawning. The diff base is the state file's Session `Base branch`. Each finding comes back tagged `structural-if-fixed`
   (fixing it would move responsibilities, add or merge types, or change contracts) or `local`.
2. **Triage every finding** into one of three: **fix**, **dismiss** with a one-line reason, or
   **backlog** it. The blind reviewer cannot see the plan and will rank two kinds of finding
   highly; both are backlog entries however cheap. One asks to tighten an earlier slice's or the
   steel thread's test to assert exactly the current output — that test pins the seam, not the
   content. The other asks for behavior this slice does not have,
   such as a missing error path. In `yolo`, dismiss a finding that asks for unit tests, citing the
   mode — unless it names logic the slice owns (a branch, a transformation): that is a `departure`,
   since the mode no longer fits, and goes to the user per BUILD step 3. Record the round in
   `Rounds`, and write fixes to the `## Review` section's `To fix` list, each with its tag, and
   dismissals and backlog entries to their lists; the host shows the user every
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

1. **Acceptance tests** (not `internal`) — run every row from ACCEPT that has an agent proof,
   against the finished code; set each row's Status to `pass`/`fail`. For every row with a
   blank agent proof, walk the human proof with the user and set `pass: user-confirmed` only on
   their confirmation.
2. **Unit tests** — the slice's tests (in `yolo`, only pins and persisted proofs) and the targeted
   tests for every change since the design commit (review and lint fixes included) green on the
   final code. Write each `Criteria tests` line's result onto it — `pass`, or the row's Status in
   `yolo` — for the report. Not the full suite: the host starts that in the background once you hand back.
3. **Lint** — clean per REVIEW, or `none found`.
4. **Review** — REVIEW's findings all fixed, dismissed with a reason, backlogged, or listed under
   `Open at cap`.

A failure here means fix it — as a `To fix` entry and a `review fixes` delegate, per REVIEW step
3 — and re-check every item, since a fix can regress another (acceptance proofs included, after the
last review fix); list each such fix per REVIEW step 6. Once all hold, **check `git status
--short` before adding anything**: running the acceptance proofs can leave files in the repo (a
downloaded response, a job's output), and `git add -A` would ship them — delete what the proofs
left, keep only the slice's own changes. Set the phase to HAND BACK, then commit (`git add -A`,
message `slice-tdd: ship <slice-slug>`).

## HAND BACK

The gate has passed; this phase only reports. A resume landing here never re-runs SHIP — its
`mutating` proofs would act on a real system twice.

1. **Write the report** to the block's report path, from the state file, Outcome
   `<mode> — handed back`.
2. **Then remove the state file**: `git rm -q <state-file> && git commit -m "slice-tdd: hand back
   <slice-slug>"`. Confirm `git status --short` shows nothing but the report: nothing of yours
   ships. In this order, an interruption between the two leaves a hand-back the host can see and a
   stray file its boundary removes; the reverse leaves neither, and a resume rebuilds the slice.

No squash, no PR; the host squashes, and presents your `Dismissed` and `Open at cap` lists to the
user. A `blocked` or `paused` report keeps the state file — you resume from it.
