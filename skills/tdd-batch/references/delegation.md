# Delegation

Two things live here, and they are separate decisions:

1. **The reviews are always delegated.** Two per PR — the test-set review at RED, the
   whole-diff design review at REVIEW — plus one end-of-feature review at completion. This is
   not a mode; it is the design. Skipping it or running the review in this session breaks the
   thing the review is for.
2. **Whole phases may optionally be delegated** to keep the driving session's context small
   across a long feature. GREEN is the natural unit. This is a mode, and it is orthogonal to
   interactive vs. one-shot.

Check your available tools for a delegation mechanism before offering either — Claude Code and
pi both expose one, under names that vary by version. Do not assume a tool name.

---

## Why the reviews delegate

- **You wrote it.** You hold the rationale for every choice in the diff, so anything you
  remember deciding reads as already-adjudicated rather than as a smell. That bias runs toward
  under-reporting exactly what a review exists to catch. A reader given only the artifact has
  no prior commitment to defend. Authorship bias is the actual rubber-stamp mechanism, and
  fresh context is the only thing that removes it.
- **The RED review buys something self-review cannot produce at all**: a cold reader
  reconstructing the contract from the tests alone *is* the future consumer. If they cannot
  reconstruct it, the tests are unclear — and you can never generate that signal yourself,
  because you already know the contract.
- **The catalog is meant to be transient.** Loading the full design catalog into this session
  would leave it resident for the rest of the feature, quietly overriding the decision to keep
  judgment invoked rather than ambient.

Be clear-eyed about the trade: delegation costs *more* total tokens than reviewing in-session,
because each call is a cold start. What it buys is an unbiased reviewer and a driving session
that stays small. Two standing delegations per PR is the budget this skill is designed around —
it is still far below the per-test flow's per-cycle ceremony.

**Fresh context removes bias, not laziness.** Every review prompt below therefore demands
*artifacts* — tables, censuses, named worsts — not verdicts. A reviewer asked "any problems?"
answers "looks fine"; a reviewer asked for a filled trace table has to look.

---

## Review 1 — the test-set review (RED step 5)

Spawn one subagent. It gets the PR sentence, the acceptance criteria this PR advances, the
design hypothesis, and the test files **plus the raising skeleton** — and no implementation,
because none exists. That absence is the point: this is the cheapest review in the flow and the
only one whose reviewer sees the contract exactly as a consumer will.

> Review a set of tests written test-first, before any implementation exists. Read only these
> files: `<test file paths>` and `<skeleton file paths>`. The implementation does not exist
> yet — the skeleton raises `NotImplementedError` (or equivalent) by design; do not treat that
> as a defect and do not write any code.
>
> Produce these artifacts in order. Do not substitute a summary judgment for any of them.
>
> **1. Contract reconstruction — do this FIRST, before reading anything below this line about
> the intended design.** From the tests alone, state the contract they imply: what the unit
> does, its inputs, outputs, error behavior, and any ordering or state assumptions. Write it as
> you understand it, not as you think it was meant.
>
> **2. Intended contract.** The PR's one-sentence behavior is: `<PR sentence>`. The acceptance
> criteria it advances are: `<criteria>`. The design hypothesis is: `<hypothesis>`. Now compare:
> every divergence between your reconstruction and this intent is a finding — it means the tests
> are ambiguous about something. List each divergence.
>
> **3. Trace table.** One row per test: test name → the behavior or acceptance criterion it
> serves. The behaviors in this batch are: `<behavior list from THINK>`. A test with no row is
> speculative — flag it. A listed behavior with no test is a gap — flag that too.
>
> **4. Setup census.** How many tests share setup, what that shared setup is, and the single
> worst setup in the batch, named, with why it is worst.
>
> **5. Worst assertion**, named, with why — the one that would be hardest for a future reader
> to understand or that is most coupled to implementation detail rather than observable
> behavior.
>
> **6. Test-quality pass.** Invoke the `design-principles` skill and apply its `test-catalog.md`
> to the batch: FIRST, behavioral-not-wiring, mock-at-boundary, clarity of names.
>
> Rank all findings by severity. For each, say whether fixing it changes the **interface**
> (names, signatures, types, errors) or only the **tests**. Do not modify any file. Report the
> assessment as your final output.

**Triage locally, and act now.** Interface findings are the whole reason this review happens
before implementation exists: amend the tests and skeleton, re-run the per-test verification
(RED step 3), and commit the revision. Test-only findings: fix, or dismiss with a stated
reason. Record dismissals in the state file — the REVIEW reviewer will see them, which is what
keeps a dismissal honest.

---

## Review 2 — the whole-diff design review (REVIEW step 3)

Spawn one subagent per round. Scope is the whole PR diff, state file excluded:

```bash
git diff <previous-pr-branch>...HEAD -- . ':(exclude)<state-file>'
```

(The `.` is required — a lone `:(exclude)` pathspec errors on some git versions. At a one-shot
boundary, use the PR's range: `git diff <PR-(NN-1)-end>...HEAD -- . ':(exclude)<state-file>'`.)

Unlike the isolated cold review this flow replaced, this reviewer gets **intent**: what the
design was trying to be, and what was consciously set aside. The question is not "find smells"
but "was the intent honored, and what pressure emerged."

> Invoke the `design-review` skill. Scope: `<the exact git diff command above, filled in>`.
> Focus: the statement, name, function, and class altitudes. Do not review component or system
> altitude — a separate end-of-feature pass owns those. Scope and focus are given; do not
> resolve your own and do not ask for either.
>
> Context for the review — use it, do not re-derive it:
> - **Design hypothesis** (what this implementation was trying to be): `<hypothesis>`
> - **The batch as spec** (the tests are the specification of what this PR must do):
>   `<behavior list and test names>`
> - **Consciously deferred / dismissed so far** (do not report these as new findings; do say
>   if one now looks like the wrong call): `<dismissals, deferrals, backlog items touching
>   this diff>`
>
> Your central question: **does the implementation honor the hypothesis, and what design
> pressure emerged that the hypothesis does not account for?** A divergence between hypothesis
> and implementation is a finding in its own right — say which one you think is wrong.
>
> Also produce, explicitly: the **three largest new functions**, each with a one-sentence
> statement of its single responsibility — if a sentence needs "and", say so.
>
> Tag every finding exactly one of:
> - `structural-if-fixed` — fixing it would move responsibilities between units, add or merge
>   types, or change a contract.
> - `local` — rename, extraction, inlining, or cosmetic change confined to one unit.
>
> Rank by severity. Do not modify any file and do not fix anything you find. Report the rated
> assessment as your final output.

**The tags are load-bearing.** Re-entry into another review round is decided by the reviewer's
tag, not by your own classification of your fixes — that gate was moved out of the author's
hands deliberately. If any fix you applied was tagged `structural-if-fixed`, run one more round
on the new diff. Fixes of `local` findings never re-enter. **Cap: three rounds.** Anything
structural still open at the cap goes to the backlog and is surfaced at the boundary as an open
concern — never silently absorbed.

**Triage locally — the reviewer diagnoses, you decide.** Fix (each its own commit, suite green
after), dismiss with a stated reason, or record in the backlog as a named entry. The report
itself is not kept; the backlog entries and the PR Log's review line are the durable record.

---

## Review 3 — the end-of-feature review (Progress, condition 4)

Runs once, at completion. Every PR already had its own whole-diff review, so this pass must not
re-sweep the codebase — that is the least useful place to spend the most accumulated context.
It looks only at what no single PR could show.

> Invoke the `design-review` skill. Scope: `git diff <base-branch>...<final-branch> -- .
> ':(exclude)<state-file>'`. Focus: **cross-PR seams and the component and system altitudes
> only** — duplication where the two sides live in different PRs, dependency cycles, grab-bag
> packages, and rot symptoms assembled across several PRs that were each individually clean.
> Do NOT review the statement, name, function, or class altitudes: every PR in this feature
> already had a dedicated review at those altitudes, and re-reporting them wastes the pass.
> Scope and focus are given; do not resolve your own and do not ask for either.
>
> Context: the feature is `<feature definition>`; the final design hypothesis is
> `<hypothesis>`; the PRs were: `<one line each>`.
>
> Produce explicitly: any concept that appears in more than one PR under different names, and
> any module that gained responsibilities from more than one PR. Do not modify any file.
> Report the rated assessment as your final output.

If the feature is a single PR there are no cross-PR seams — narrow the focus to the component
and system altitudes alone. Findings go to the backlog and must be resolved before declaring
done; a substantial one becomes a new PR in the plan, never an amendment to a delivered one.

---

## Optional: delegating phases

Preflight, SHIP, Finalization, and Cleanup **always stay local** — they need live
back-and-forth with the user, or they make git-history decisions and hand work over. THINK
stays local too: it re-reads the plan, may re-slice it, and can hit decision gates.

What can be delegated is the work between them, in units of a phase. **GREEN is the natural
unit** — it is the largest, most mechanical, and most context-hungry. MAKE ROOM and RED can
also be delegated. Delegating REVIEW as a whole is possible but rarely worth it: its own core
step is already a delegation, and the triage decisions in it are yours.

Note what changes versus a per-cycle flow: **a delegated GREEN is the entire implementation of
a PR.** The driver cannot meaningfully spot-check it mid-flight. What the driver verifies on
return is therefore concrete and checkable: the full suite is green, the batch tests all pass,
the milestone commits exist with named subsets, the pressure log has entries with dispositions,
and no test was modified outside an `amend batch` commit. Verify those before proceeding —
`git log --oneline` and one suite run answers all of them.

**Escalation contract.** A delegated phase cannot pause to ask the user something — there is no
one on the other end of that process. Wherever the skill says to "surface to the user", "ask",
or "get sign-off" (dropping a plan item or PR, hypothesis revision, criteria correction, a
deferred backlog item, major resequencing — treat the instruction, not this list, as
authoritative), a delegated phase must instead:

1. Write the situation into the state-file field that owns it: a hypothesis or criteria
   question into Design Hypothesis (append to History) or Current Position notes; a slicing
   question into the PR Plan entry it concerns; an edge case or deferral into Backlog. Include
   enough detail for a human to decide without reconstructing context.
2. Set `## Driver Status` to `needs-user-input` with a one-sentence `Reason`.
3. Stop — do not guess, do not proceed past the decision point.

**Phase boundaries are always a stopping point.** A delegated phase never runs the next one and
never runs SHIP or Finalization. A delegated GREEN that discovers the PR is bigger than planned
stops and reports rather than growing the batch.

End every delegated phase's output with exactly one line:

- `STATUS: phase-complete` — the phase finished; the driver runs the next one
- `STATUS: pr-ready` — REVIEW is complete and the PR is ready for its boundary
- `STATUS: needs-user-input — <reason>` — stopped early, a human decision is needed
- `STATUS: feature-complete` — every planned PR delivered, criteria satisfied, backlog
  resolved, end-of-feature review done

**Driving the loop.** Invoke the delegation mechanism one phase per call:

> Run exactly one phase — `<PHASE NAME>` — of the tdd-batch flow, following
> `<path this session read SKILL.md from>`. The state file is `<explicit path>`. Read the state
> file first, then SKILL.md's "Test Strategy", "The Pass" (your phase and the phases either
> side of it, for context), and "Phase Discipline", then this file
> (`references/delegation.md`) from the top through the STATUS line list — everything after
> that belongs to the driver, not to you. You are a delegated subagent: no user is present;
> follow the Escalation Contract exactly. Run only your phase; do not start the next one, do
> not run SHIP or Finalization. End your output with the STATUS line.

Pass the state file path explicitly — it is named after the effort, so a subagent cannot infer
it, and more than one may exist in the repo.

After each call: read the STATUS line; if it is missing or malformed, do not guess — treat it
as `needs-user-input` and read the state file directly. The STATUS line is a convenience; the
state file and the commits are the record.

- `phase-complete`: verify the return checks above if the phase was GREEN, report briefly, and
  delegate the next phase.
- `pr-ready`: **interactive** — run SHIP locally (present, wait, squash on approval, open the
  next PR). **One-shot** — record the PR's `Ends at` sha and start the next pass; no stop, no
  squash, no branch.
- `needs-user-input`: stop looping, surface the Reason and the relevant state-file detail,
  resolve with the user, then resume.
- `feature-complete`: stop looping. Interactive — proceed to Cleanup. One-shot — take the
  user's single review, run Finalization, then Cleanup.

Phase delegation can be mixed within a session: delegate a routine GREEN, pull a tricky one
back in-session. The state file and the discipline are identical either way — only who executes
the phase differs.
