---
name: tdd-batch
description: "Batch-mode Test-Driven Development optimized for how agents work, delivered as a stack of small reviewable PRs. Use when building a feature and the user asks for tdd-batch, batch TDD, or agent-optimized TDD; if they ask for strict classic per-test TDD, use the tdd skill instead. Per PR: plan a batch of behaviors, write all their failing tests against a raising skeleton, get the test set reviewed by a fresh subagent, implement holistically with milestone commits and a pressure log, then run a whole-diff refactor and delegated design review before shipping. Also use when asked to break a feature into small, reviewable, incrementally shippable pull requests using batch TDD."
compatibility: "Requires the slice-plan, design-principles, design-review, and backfill-tests skills to be installed alongside it — the PR plan is drafted from slice-plan's slicing doctrine, and the reviews and the MAKE ROOM phase depend on the other three, with no bundled fallback. Requires a way to delegate a task to an isolated subagent (the two per-PR reviews are delegated by design)."
metadata:
  soft-deps: slice-plan design-principles design-review backfill-tests
---

# TDD Batch

Test-first development, restructured around how agents work rather than how humans do. Humans
need one-test-at-a-time cycles for two reasons: limited working memory, and the fact that human
judgment is *ambient* — every small step gets reassessed for free. An agent inverts both: it can
hold a whole increment's design at once, and its judgment fires only when *invoked*. So this
skill keeps TDD's invariants — tests written first and confirmed failing, never weakening a test
to make it pass, small reviewable increments — and drops the per-test pacing. Design judgment
runs at a few fixed, high-leverage checkpoints instead of many low-leverage ones, and **no
checkpoint accepts an attestation**: every checkpoint question is phrased so that "nothing to
report" is not a legal answer.

Work is delivered as a stack of small PRs. Three levels stay distinct:

- **Acceptance criteria** — behavioral, outside-observable, the fixed target.
- **The PR plan** — an ordered sequence of independently reviewable increments, each changing
  observable product behavior. This layer is load-bearing here beyond what review needs: the
  PR's one-sentence behavior sizes the test batch, the batch fences the implementation, and the
  slice bounds the cost of a design insight that arrives late.
- **Design hypothesis** — the current best theory of the implementation, expected to evolve.

Each PR is delivered by **one pass** through five phases — THINK → MAKE ROOM → RED → GREEN →
REVIEW — then crosses the PR boundary (SHIP in interactive mode). The feature is done when
every planned PR is delivered, all criteria have passing tests, and the backlog is drained.

## State File

Maintain a state file at `<plans-dir>/tddb-<feature-slug>.md` throughout the session — see
[state-format.md](state-format.md) for the format, directory choice, and slug rules. Its writes
ride the next commit that already exists and never get one of their own (except Setup's
`begin`, which starts tracking the file); the squash keeps it out of every PR
([references/pr-workflow.md](references/pr-workflow.md), §"Keeping the state file out of the
PR"). The `tddb-` prefix and its `# TDD Batch Session State` heading keep it distinct from the
`tdd` skill's state files, so both skills can run in the same repo.

**Rules in Force**, the header at its top, is this flow's non-negotiable steps, copied verbatim
at creation and never edited. This body was read into the conversation once, so a long feature
dilutes it by position and a compaction can drop it; the file is on disk, and re-reading the
header puts the rules back at the end of the context. So **at the start of every THINK, re-read
the header plus the PR Plan, Backlog, and Current Position** — unconditionally, even if you
believe you know the rules; that belief is what erodes first. Re-read the header alone at every
milestone commit in GREEN, when GREEN drops to the ladder (a thrashing stretch makes no
milestone commits), and at the start of each REVIEW round. These are reads: GREEN stays dark
for writes apart from pressure-log appends. If a resumed state file has no header, or one that
differs from the block in [state-format.md](state-format.md), replace it wholesale and verbatim
before the next pass — it is fixed text with a single source, so replacing is not the drift the
never-edit rule guards against.

**Write** it at these points (the phases restate each where it applies): creation; end of
THINK (behavior list, interface sketch, next phase); end of RED (per-test verification, review
triage); during GREEN, pressure-log appends only — milestone commits carry the position; end
of REVIEW (log drained, PR log entry, criteria, hypothesis, backlog, PR description, and after
PR 01 the walk's `Replan walk` line plus any revised PR Plan entries); SHIP
(branch, squashed sha, statuses); and Driver Status at every phase transition, set to
`needs-user-input` with a one-sentence Reason the moment you escalate.

Keep the diff quiet: append entries and tick checkboxes; never reflow unchanged prose.

---

## Startup

**First:** glob `tddb-*.md` in `plans/`, `docs/plans/`, and `.plans/`. A state file is
identifiable by its `# TDD Batch Session State` heading even if renamed. (Files named
`tdd-*.md` with a `# TDD Session State` heading belong to the `tdd` skill — a different flow;
do not resume them with this one.) Right after a squash the file is *untracked* — expected; do
not commit or clean it.

- **None found** — start fresh.
- **Exactly one** — offer to resume it.
- **More than one** — list them (feature, last-updated) and ask which, or whether to start new.

**If resuming:** read the state file — if its Rules in Force header is missing or differs from
the block in [state-format.md](state-format.md), replace it now, verbatim; report feature,
current PR and position, phase, remaining criteria and PRs, current hypothesis; confirm the
checked-out branch matches; ask whether to resume or start fresh; if resuming, continue from
the recorded phase — for mid-GREEN resume, see [Resuming mid-PR](#resuming-mid-pr).

**If starting fresh**, run Preflight before touching code.

### Preflight

Establish four things in order — each builds on the previous:

**1. Feature definition.** What is being built, why, for whom; what is explicitly out of
scope. Sharpen a vague definition before moving on.

**2. Acceptance criteria.** Behavioral, specific, testable, scoped. Derive candidates if not
provided; push back on criteria that describe internals or are untestable. Present the final
list for confirmation.

**3. Design hypothesis.** Key types, modules, responsibilities, connections. A proposal, not a
declaration — expected to evolve.

**4. PR plan.** Read [references/pr-slicing.md](references/pr-slicing.md) in full before
drafting it, and with it the general slicing doctrine it defers to — `slice-plan`'s
`references/slicing.md`, also in full, as that file directs. Together they are the source;
do not draft the decomposition from memory of this summary. Each PR: a one-sentence behavior
(no "and"), the criteria it advances, and a first guess at its batch (the behaviors its tests
will cover). For PR 01 whenever it is a steel thread, and for any other PR that ships something
unreachable, also its `Merge safety`: `live`, or `inert: <what makes it unreachable>`. Test
Strategy below covers the steel-thread case; the same field carries every other PR that ships a
stub. Present the ordered list — this is the highest-value
thing for the user to push back on.

**Alignment gate.** Present feature, criteria, hypothesis, PR plan, and the proposed slug
(permanent; names the state file and branches). Ask: *"Are we aligned? Shall I proceed?"* Do
not start until confirmed. A standing go-ahead ("just run it all") selects one-shot mode — see
[Execution modes](#execution-modes).

### Setup

1. Confirm a clean working tree (stash or commit unrelated work first).
2. Identify the test runner; ask if it cannot be determined from project files.
3. Run the full suite; get confirmation on any pre-existing failures — you need a green baseline.
4. Choose the plans directory (whichever of `plans/`, `docs/plans/`, `.plans/` exists; create
   `plans/` only if none; ask if several).
5. Create the state file, starting with the Rules in Force header copied verbatim from
   [state-format.md](state-format.md).
6. Create the first PR's branch: `git switch -c tddb/<feature-slug>/01-<pr-slug>`. Record the
   base branch.
7. Commit the state file: `git add <state-file> && git commit -m "tddb: begin <feature>"`.

---

## Test Strategy

**Outside-in, E2E first over new ground**: the first PR establishes an end-to-end path; later
PRs replace stubs with real behavior, then add functionality, then edge cases. Where the
integration path already exists — a feature added to a mature system — there is no thread to
pull and the first PR is simply the thinnest behavior (`slicing.md`, §"The first slice: steel
thread").

**Merge-safe from the first PR**: where PR 01 is a steel thread, it is either a **live thread**
— the thinnest genuinely working vertical slice — or an **inert thread**, the same structure
kept unreachable
(unregistered, unmounted, or flag-gated) — see `slicing.md` §"Merge safety", which is
authoritative on the choice. Decide at planning time and record it in the PR Plan's
`Merge safety` field; REVIEW copies it into the PR description.

**Behavioral, not wiring**: assert observable outcomes — return values, state changes, effects
at the boundary — never that one object called another.

**Live objects over mocks**: mock only at system boundaries or where the real thing is
prohibitively slow, and never deep inside your own code.

---

## The Pass

One pass per PR. Phases run in order; a phase that doesn't apply is skipped with a one-line
note, never silently.

### Execution modes

The pass is identical in both modes; only the PR boundary differs.

**Interactive** (default): stop at every boundary. Run SHIP, present the finished PR, wait for
review before the next pass.

**One-shot** (on a standing go-ahead): run the whole plan as continuous passes, reviewed once
at the end. No per-PR SHIP, no per-PR branches; history stays linear. At each boundary, record
the PR's `Ends at` sha (its last commit, REVIEW fixes included) and continue — the PR
description was already written at REVIEW. When the completion conditions in
[Progress](#progress) are met, take the user's single review, then run Finalization
([references/pr-workflow.md](references/pr-workflow.md), §"Finalization") to build the squashed
stack. `needs-user-input` decision gates still stop the run — one-shot forgoes review gates,
not decision gates. Switching modes mid-feature works as in the workflow reference.

### Discarding an experiment

Uncommitted work is an experiment, and every phase can produce a failed one — refactors most
often. Two rules make throwing one away cheap:

- **Start every refactor step from a clean tree** (clean apart from the state file): commit
  whatever is green first, and commit each step that leaves every previously passing test
  passing — `tddb: refactor — <what>` in GREEN (MAKE ROOM keeps its own `make room` commit),
  `tddb: review fix — <what>` in REVIEW. Neither is a milestone. In GREEN the commit *before* a
  refactor is a milestone only if the passing batch subset grew since the last one; if it did
  not, there is nothing green to commit, so finish the implementation stretch first — and never
  refactor while flat lines are pending (GREEN's convergence tripwire owns that rule). The
  discard below then removes exactly one step, never good work beside it.
- **Discard when a trigger fires.** Either GREEN's convergence tripwire (three flat runs — see
  GREEN for what counts as one), or any refactor step — MAKE ROOM, GREEN's steer-now, REVIEW's
  self-refactor or a fix — that breaks a test that passed before it, where one repair attempt
  does not put it right.

To discard, restore everything except the state file, then remove new files. Commits stay;
everything else uncommitted goes:

```bash
top=$(git rev-parse --show-toplevel)
git -C "$top" restore --source=HEAD --staged --worktree -- . ':(exclude)<state-file>'
git -C "$top" clean -fd -- <source dirs>
```

Give `<state-file>` and `<source dirs>` as repo-root-relative paths and keep the `-C`: pathspecs
follow the working directory, so from a subdirectory the discard is silently partial and the
state-file exclusion stops matching. The state file is left alone, so pressure-log entries and
any uncommitted state write survive. Then append one `discarded` line to the Pressure Log
saying what entangled; it drains into the PR Log's `Discarded` field at REVIEW and is the only
trace the experiment leaves. Then resume: after the tripwire, drop to the ladder; after a
failed refactor, retry the change in smaller steps once, and if that fails too, put it in the
backlog.

### THINK — Plan the Batch

**First, re-read the state file's Rules in Force header and its PR Plan, Backlog, and Current
Position sections** — every time, unconditionally.

1. **Restate the PR's one-sentence behavior** (no "and"). Everything in this pass serves that
   sentence.
2. **Enumerate the PR's behaviors** — the individual observable behaviors that together
   deliver the sentence, one sentence each, no "and". Each must trace to the PR's sentence or
   an acceptance criterion this PR advances; a behavior that doesn't trace goes to the PR plan
   or backlog, not into this batch. Check the backlog for items that belong in this PR and
   promote them now. **A batch never spans more than one planned PR.** If the enumeration
   reveals the PR is bigger than planned, split the PR plan now — do not grow the batch.
3. **Sketch the interface** the behaviors imply, as consumers will see it: names, signatures,
   types, errors. Hypothesis, not commitment — writing the batch tests it, and the RED review
   challenges it.
4. **Never execute a stale plan item.** Minor reshaping: update the plan silently. Dropping a
   behavior or PR, or major resequencing: surface to the user first (a `needs-user-input` stop
   in one-shot mode).

**Write the state file**: behavior list and interface sketch; phase to MAKE ROOM if its gate
fires (judge that now), else RED.

### MAKE ROOM — Prepare the Ground (conditional)

**Gate — both conditions must hold:** this phase runs only if the pass will *modify* code that
(a) was **not written in this feature's earlier PRs** — feature-internal code is already
covered by construction — and (b) is **not already pinned by tests you trust** to catch a
behavior change. New files and pure additions never qualify. If the gate doesn't fire, say so
in one line and move on.

When it fires, in this order:

1. **Backfill first**: pin the current behavior of the code about to be disturbed — invoke the
   `backfill-tests` skill; it carries the quality bar (intent-derived expectations, proven
   falsifiable). Commit separately: `tddb: pin <what> before PR NN`.
2. **Then preparatory refactoring**: make the change easy before making the easy change.
   Behavior-preserving only; full suite green after each step. Commit separately:
   `tddb: make room for PR NN`. A step the suite rejects and one repair does not fix is a
   failed experiment — [discard it](#discarding-an-experiment).

If the preparatory refactor grows beyond a few commits, stop — it is its own PR; add it to the
plan ahead of this one and surface that.

### RED — Write the Batch

1. **Write all the batch's tests**, one per behavior from THINK, against the sketched
   interface. Writing them is a design act: if setup grows convoluted or assertions contort,
   that is the interface failing its first contact — revise the sketch now, while revision is
   free, and update the hypothesis in the state file if it shifted.
2. **Create the skeleton.** The batch must fail on assertions, not imports. Add inert stubs
   for the sketched interface: real signatures, bodies that **raise** (`NotImplementedError`
   or the language's equivalent) — never bodies returning `None`/`0`/empty, which can satisfy
   a test by accident. A raising stub makes every accidental pass loud. If the skeleton is
   reachable, keep it inert or flag-gated **for the duration of the pass** — a within-pass
   device, replaced during GREEN, with no state-file entry. `Merge safety` records only what
   **ships**: if this PR will still have a stub in place at the boundary and planning set no
   field, add it now.
3. **Verify per test, not per batch.** Run the suite. For *each* batch test, record in the
   state file: it fails, and the failure is the missing behavior — an assertion or expected
   effect — not a compile, import, or fixture error. **A test that passes against a raising
   skeleton is broken** — it is not exercising what it claims; fix it or delete it. This
   per-test check against the skeleton is where the tautology catch lives in this flow.
4. **Commit**: tests + skeletons + state file — `tddb: red batch for PR NN`.
5. **Delegate the test-set review** to a fresh subagent — prompts and context bundle are in
   [references/review-prompts.md](references/review-prompts.md), §"Review 1"; read that section
   before spawning. It runs as **two turns**, and the second is not optional: the reviewer
   reconstructs the contract from the test files alone (no implementation exists, which is the
   point) and is told the intended contract only once that reconstruction is back. It must
   produce artifacts, not opinions: the divergences between reconstruction and intent (each one
   = the tests are ambiguous), a trace table (no row = speculative test), a setup census, and
   the worst assertion named. **Triage the findings yourself**: interface revisions happen
   *now* — amend tests and skeletons, re-run the per-test verification, commit. Dismissals need
   stated reasons, recorded in the state file.

Set phase to GREEN — the last state write until REVIEW, apart from pressure-log appends.

### GREEN — Implement the Batch

- **Implement holistically.** You hold the whole batch; design the implementation as one
  piece. The scope fence is the batch: **write nothing the batch does not demand.** The
  anticipation was already written down as tests; code serving no test is speculation and will
  be flagged in REVIEW.
- **Milestones, not order.** Run the suite at coherent stopping points of your choosing and
  commit at each *green milestone*. Green in this phase means: **every test that passed before
  this PR still passes, and the set of passing batch tests only grows.** Name the newly
  passing tests in the message: `tddb: green <tests or count> of PR NN`. Never a long stretch
  where everything is red and nothing is committed. A milestone commit is the base a failed
  experiment gets thrown back to (see Discarding an experiment), so it belongs after a
  coherent chunk, not after every test — a commit per test is the ladder's rhythm, not the
  holistic pass's.
- **At every milestone commit, re-read the state file's Rules in Force header** before writing
  the pressure log. GREEN is the longest phase and the one whose rules decay furthest from the
  THINK that last read them; the milestone is the fixed beat that closes that gap, and you are
  touching the file anyway. This is a read — it does not reopen GREEN to other state writes.
- **Pressure log — at every milestone commit**, append two lines to the state file's pressure
  log, answering: *ugliest thing you wrote since the last milestone?* and *most annoying test
  to satisfy so far?* Superlatives always have answers — "nothing" is not a legal reply;
  "X, and it's fine because Y" is. Each answer gets a disposition: **steer now** (refactor
  immediately, stay green — never while flat lines are pending, see the tripwire below) or
  **hold** (REVIEW will force a decision). Log any smell the
  moment it bites, too — a growing switch, a third repetition, hurting setup — don't wait for
  the milestone.
- **Convergence tripwire — count it in writing.** This bullet is the rule; the header, Phase
  Discipline, and *Discarding an experiment* only point at it. A **flat run** is a full-suite
  run in which **no batch test newly passes** — append `flat run <N> of 3 — nothing new
  passing` to the pressure log. Do not hold the count in your head: GREEN is long, its runs are
  spread across it, and an uncounted tripwire never fires. Two exemptions, because neither is
  meant to make a batch test pass and counting them would push a healthy pass toward a discard:
  the run after an `amend batch` commit and the run after a `refactor` commit are not flat runs,
  whatever they show. A batch test newly passing clears the counter — if flat lines were
  pending, write `count reset — <test> now passing`; otherwise the milestone commit is record
  enough. And **never refactor while flat lines are pending**: committing one would carry the
  thrashing stretch past the discard. **At the third flat line** the holistic pass has failed —
  discard it ([Discarding an experiment](#discarding-an-experiment)), then drop to the ladder:
  pick one failing test, make it pass, run, commit, repeat. **Re-read the Rules in Force header
  as you drop** — a thrashing stretch produces no milestone commits, so it has no other
  re-read, and it is where the amendment protocol is most likely to get bent. The ladder is a
  diagnostic mode, not a discipline — return to holistic once the entanglement is broken.
- **Amendment protocol — the only legal way to touch a test in GREEN.** If a batch test turns
  out to be wrong (mis-specified expectation, wrong contract), or a genuinely missing behavior
  *within the PR's sentence* surfaces: halt implementation; state the defect or gap in one
  line; amend or add the test; re-verify it fails for the right reason against current code;
  commit it alone — `tddb: amend batch — <one-line reason>`. Weakening an assertion inside an
  implementation commit is the failure this protocol exists to prevent: amendments are always
  visible, always separate. A missing behavior *outside* the PR's sentence goes to the
  backlog. If an amendment reflects a misspecified *acceptance criterion*, that is never
  yours to decide — surface it to the user immediately (see Design Evolution).

GREEN ends when the full suite is green, batch included.

### REVIEW — Refactor and Converge

Set phase to REVIEW. Every fix or refactor step in it follows [Discarding an
experiment](#discarding-an-experiment): clean tree before, commit after each green step.
**Re-read the Rules in Force header at the start of REVIEW and again before every re-entry
round** — each delegated report lands in context here.

1. **Drain the pressure log.** Every held item gets a terminal disposition: **fix now** (suite
   green after), **dismiss** with a reason, or **promote to the backlog** (real, but not this
   PR's work). An entry logged at a discard instead drains into the PR Log's `Discarded` field.
   Counter lines (`flat run N of 3`, `count reset`) are not observations and need no
   disposition — erase them with the rest. The pressure log must be empty when this phase
   ends — it does not outlive the PR; the backlog is the only cross-PR notebook.
2. **Self-refactor the whole PR diff** (state file excluded) with
   [references/refactor-checklist.md](references/refactor-checklist.md) and Simple Design
   priority: tests pass > intention clear > no duplication > fewest elements. Where the
   project has coverage tooling, run it over the diff: **any changed code path no test
   exercises is a finding** — dead, speculative, or missing a test; decide which. Where there
   is no tooling, walk the diff's branches and say so — never claim the mechanical check ran
   when it didn't. Do not manufacture trivial tests to silence coverage; a test added here
   must pass the same trace rule RED's review enforces.
3. **Delegate the whole-diff design review** — prompt and bundle in
   [references/review-prompts.md](references/review-prompts.md), §"Review 2". The reviewer gets
   the diff, the hypothesis, the dismissals and deferrals so far, and the batch as the spec; its
   question is *"does the implementation honor the hypothesis, and what design pressure
   emerged?"*, not a cold catalog scan. Its report tags each finding **`structural-if-fixed`**
   (fixing it would move responsibilities, add/merge types, or change contracts) or **`local`**.
4. **Triage every finding**: fix, dismiss with reason, or backlog. Then the re-entry rule,
   decided by the reviewer's tags, not yours: **if any fix you applied was tagged
   `structural-if-fixed`, delegate one more review round on the new diff.** Fixes of `local`
   findings never re-enter. Hard cap: three rounds total — anything structural still open after
   round three goes to the backlog and is surfaced at the boundary as an open concern, never
   silently.
5. **Write the state file**: PR log entry (behaviors delivered, what was learned, hypothesis
   change if any, experiments discarded), newly satisfied criteria, hypothesis update, backlog
   updates, pressure log emptied, and the **PR description** (what changes, criteria advanced,
   what is deliberately not here, base branch — and, if this PR has a `Merge safety` line in
   the PR Plan, that line copied verbatim, so the reviewer is told what makes a stubbed flow
   safe to merge). Run the PR 01 walk below *before* setting phase to boundary — a resume that
   reads `boundary` goes straight to SHIP, silently losing the walk. Then set phase to boundary
   and leave the write
   uncommitted: the SHIP squash, or the next pass's first commit, picks it up. If any backlog
   item was marked deferred, surface it to the user now, not at completion.

**If this was PR 01, walk the remaining plan before crossing.** This is the authoritative
statement of the walk; every other mention of it points here. Re-read
[references/pr-slicing.md](references/pr-slicing.md) and the doctrine it points to, then check
every later PR against what PR 01 actually found — each was drawn before those findings existed,
and this is the highest-yield replanning moment in the feature.

**Always write PR 01's `Replan walk` field**, joining step 5's uncommitted write: what the walk
changed, with the revised PR Plan entries alongside it, or `plan stands` if nothing changed. The
field is the evidence in *both* branches — revised entries alone prove nothing, because THINK
reshapes the plan silently too, so a reader cannot tell a walk that ran from a THINK edit. And
the revised entries are what actually takes effect: THINK reads the PR Plan as the authority and
never executes a stale item, so a re-slice written nowhere does not happen.

Surface changes by THINK step 4's rule — minor reshaping is silent, a drop or major resequence
goes to the user. If that stops the pass, note `REVIEW steps 1–5 complete; resume at the walk` in
Current Position, or a resume re-enters REVIEW at step 1 and re-runs the self-refactor against
the round cap. The walk sits here, not in SHIP, because SHIP is interactive-only and one-shot
needs it more: no user is stopping to reslice. A single-PR feature records `plan stands` and
moves on.

Then cross the boundary: SHIP (interactive), or record `Ends at` and continue (one-shot).

### SHIP — Close Out the PR (interactive mode)

SHIP is **gate, squash, and handover only** — the design review already ran in REVIEW; do not
re-review the diff here. Read §"SHIP: closing out a PR" in
[references/pr-workflow.md](references/pr-workflow.md) for the git mechanics; the rest of that
file is for Setup, restacking, and Finalization.

- Confirm the full suite is green and the tree is clean apart from the state file.
- Confirm the PR is genuinely mergeable alone: observable behavior, no dependence on a later
  PR, anything stubbed is inert or flag-gated.
- **Present the PR and stop.** One-sentence behavior, branch, base, what is deliberately left
  out, any open concern from REVIEW's round cap, **the experiments discarded** (from the PR
  Log's `Discarded` field, each with what entangled it — say "none discarded" outright when
  there were none, so the user never has to open the state file), and what the next PR does.
  This is the user's moment to reslice, reorder, redirect, or call the feature done. **The
  squash happens only on their approval — never before**; it collapses the milestone
  checkpoints.
- On approval: squash to one commit (subject = behavior, body = the description), record
  branch and sha, mark the PR `ready`, set Driver Status `pr-ready`. Then open the next PR and
  its branch per the workflow reference — **unless this was the last planned PR**: there is no
  next PR to name a branch after, so create none (a stray branch trips Cleanup's stack report)
  and go to the completion gate in [Progress](#progress).
- Do not push or open the PR — that is the user's call.

### Resuming mid-PR

The state file records the phase; within GREEN it deliberately records nothing else. To resume
in GREEN: the last milestone commit is the position — its message names the passing subset —
and the pressure log holds the in-flight observations and the flat-run count. Re-run the suite
to re-establish which batch tests remain red, then continue the holistic pass. Do not
reconstruct position from memory; the commits are the record.

---

## Design Evolution

Understanding deepens as passes accumulate. Four responses, escalating — detail in
[references/design-evolution.md](references/design-evolution.md):

- **Incremental refinement** (GREEN's steer-now, REVIEW): tests protect you; no user involvement.
- **Hypothesis revision** (between passes): a *recurring* smell across PRs — in pressure-log
  drains or backlog entries — means the direction needs structural change. Present the revised
  hypothesis and PR plan together for acknowledgment before restructuring.
- **Acceptance criteria correction**: a criterion is misspecified. Never silently adjust tests;
  surface immediately, get sign-off.
- **Starting fresh**: the approach is fundamentally wrong — delete the implementation, keep the
  batch as the spec, restart with a new hypothesis. Cheap here by design; not a failure.

The two "present to the user" points are **decision gates** — `needs-user-input` stops in
one-shot mode, not things a standing go-ahead waves past. If you get stuck, see
[references/when-stuck.md](references/when-stuck.md).

---

## Phase Discipline

Restatements of the invariants enforced above — a checklist, not a second rulebook. If you
edit one, edit all three. The state file's Rules in Force header is the compressed, on-disk copy of
the sharpest of these — change it in [state-format.md](state-format.md) too, but keep it short,
since it is re-read every pass.

- **Every batch test verified failing for the right reason, per test, against a raising
  skeleton.** A test that passes against the skeleton is broken.
- **Never touch a test in GREEN outside the amendment protocol.** Amendments are separate,
  visible commits with stated reasons — never folded into implementation commits.
- **Green in GREEN means: prior suite green, passing-batch subset monotonically growing,
  subset named in the commit.** Full green is required only to leave the phase.
- **Write nothing the batch does not demand.** REVIEW's uncovered-path check enforces it;
  RED's trace rule keeps the batch itself honest.
- **No checkpoint accepts "nothing to report" as an answer to a superlative question.**
- **A failed experiment is thrown away, not patched.** Three flat runs in GREEN — a run where
  no batch test newly passes, counted in the pressure log — or a refactor step that breaks a
  previously passing test and survives one repair → restore everything but the state file,
  record what entangled. Do not thrash.
- **Start every refactor step from a clean tree, with no flat lines pending; commit each green
  step.** The discard then removes one step and nothing else. State-file writes never commit
  alone (except `begin`).
- **A batch never spans more than one planned PR.** Split the plan, not the fence.
- **The pressure log dies with the PR** — drained to fixes, dismissals, or the backlog.
- **REVIEW re-entry follows the reviewer's `structural-if-fixed` tags, capped at three
  rounds**; leftovers surface at the boundary, never silently.
- **Both per-PR reviews are delegated, always** — a session that wrote the tests or the code
  is the wrong context to review them from.
- **Never execute a stale plan item.**
- **Never leave the suite red at a PR boundary.**
- **Squash only on the user's approval** — per PR in interactive, once at the end in
  one-shot.

---

## Progress

After each phase transition, state briefly: where the pass stands, what the pressure log or
reviews surfaced, which criteria remain, and what comes next. At each boundary (interactive),
report the PR as SHIP describes and stop — a boundary is a decision point and should feel
different from a status update. In one-shot, the boundary report is one line:
`PR 02 done at <sha>, review round(s): N, discarded: M, on to PR 03`.

Declare the feature complete only when all four hold:

1. **PR plan**: every planned PR delivered or consciously dropped with a reason.
2. **Acceptance criteria**: every criterion has passing test coverage.
3. **Backlog**: every item resolved, dismissed with a reason, or deferred — deferred items
   surfaced to the user and acknowledged.
4. **Code is clean at feature scale**: one final delegated review of what no single PR could
   show — **cross-PR seams and the component/system altitudes only**; per-PR altitudes were
   covered by each pass's REVIEW and must not be re-swept. Task prompt in
   [references/review-prompts.md](references/review-prompts.md), §"Review 3". Findings go to
   the backlog and must be resolved before declaring done; substantial ones become a new PR,
   never an amendment to a delivered one.

In one-shot mode, once these hold, present the whole feature for the user's single review —
including every PR's discarded experiments, gathered from the PR Log, since the one-line
boundary reports only counted them; on approval run Finalization, then Cleanup.

---

## Cleanup

1. **Verify** criteria, PRs, and backlog are closed and learnings have landed in code (tests,
   names, structure, or *why* comments for conscious deferrals). If not, run more passes
   first.
2. **Verify the stack**: report each PR's branch, base, and status; restack if earlier PRs
   merged (see [references/pr-workflow.md](references/pr-workflow.md), §"Restacking").
3. **Decide the state file's fate** — untracked after the last squash; default is delete, but
   ask.

The history is one commit per reviewable increment. Do not collapse the stack further.

---

## Delegated Execution

The two per-PR reviews and the end-of-feature review are **always** delegated — not a mode, the
design; their prompts are in [references/review-prompts.md](references/review-prompts.md), so
read the section for the review you are about to run, not the whole file. Optionally, whole
*phases* can also be delegated to keep the driving session small across a long feature; GREEN
is the natural unit. Read [references/phase-delegation.md](references/phase-delegation.md) in
full before delegating a phase — do not guess at the contract from this summary.
