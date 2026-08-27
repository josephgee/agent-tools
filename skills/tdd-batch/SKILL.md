---
name: tdd-batch
description: "Batch-mode Test-Driven Development optimized for how agents work, delivered as a stack of small reviewable PRs. Use when building a feature and the user asks for tdd-batch, batch TDD, or agent-optimized TDD; if they ask for strict classic per-test TDD, use the tdd skill instead. Per PR: plan a batch of behaviors, write all their failing tests against a raising skeleton, get the test set reviewed by a fresh subagent, implement holistically with milestone commits and a pressure log, then run a whole-diff refactor and delegated design review before shipping. Also use when asked to break a feature into small, reviewable, incrementally shippable pull requests using batch TDD."
compatibility: "Requires the design-principles, design-review, and backfill-tests skills to be installed alongside it — the reviews and the MAKE ROOM phase depend on them, with no bundled fallback. Requires a way to delegate a task to an isolated subagent (the two per-PR reviews are delegated by design)."
metadata:
  soft-deps: design-principles design-review backfill-tests
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
[state-format.md](state-format.md) for the format, directory choice, and slug rules. It is
committed with milestone commits and kept out of every PR by the squash
([references/pr-workflow.md](references/pr-workflow.md) has the mechanism). The `tddb-` prefix
and its `# TDD Batch Session State` heading keep it distinct from the `tdd` skill's state
files, so both skills can run in the same repo without finding each other's sessions.

**Read** it at startup, and re-read the PR Plan, Backlog, and Current Position sections at the
start of every THINK — unconditionally, as a fixed checkpoint.

**Write** it at these points (the canonical list; the phases below restate each at the moment
it applies):

- When starting fresh (create it)
- End of THINK — the PR's behavior list and interface sketch; phase set to MAKE ROOM or RED
- End of RED — the per-test verification list, then review-triage outcomes; phase set to GREEN
- During GREEN — **pressure log appends only**; position is carried by milestone commits, not
  the state file
- End of REVIEW — pressure log drained, PR log entry, criteria statuses, hypothesis, backlog,
  PR description; phase set to boundary
- At SHIP — branch, squashed sha, statuses; next PR opened
- Driver Status — kept current at phase transitions; `needs-user-input` set immediately when
  escalating, with a one-sentence Reason

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

**If resuming:** read the state file; report feature, current PR and position, phase, remaining
criteria and PRs, current hypothesis; confirm the checked-out branch matches; ask whether to
resume or start fresh; if resuming, continue from the recorded phase — for mid-GREEN resume,
see [Resuming mid-PR](#resuming-mid-pr).

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
drafting it. Each PR: a one-sentence behavior (no "and"), the criteria it advances, and a
first guess at its batch (the behaviors its tests will cover). Present the ordered list —
this is the highest-value thing for the user to push back on.

**Alignment gate.** Present feature, criteria, hypothesis, PR plan, and the proposed slug
(permanent; names the state file and branches). Ask: *"Are we aligned? Shall I proceed?"* Do
not start until confirmed. A standing go-ahead ("just run it all") selects one-shot mode — see
[Execution modes](#execution-modes).

### Setup

1. Confirm a clean working tree (stash or commit unrelated work first).
2. Identify the test runner; ask if it cannot be determined from project files.
3. Run the full suite; get confirmation on any pre-existing failures — you need a green
   baseline.
4. Choose the plans directory (whichever of `plans/`, `docs/plans/`, `.plans/` exists; create
   `plans/` only if none; ask if several).
5. Create the state file.
6. Create the first PR's branch: `git switch -c tddb/<feature-slug>/01-<pr-slug>`. Record the
   base branch.
7. Commit the state file: `git add <state-file> && git commit -m "tddb: begin <feature>"`.

---

## Test Strategy

**Outside-in, E2E first**: the first PR establishes an end-to-end path; later PRs replace
stubs with real behavior, then add functionality, then edge cases.

**Merge-safe from the first PR**: the first PR is either the thinnest genuinely working
vertical slice or an **inert** skeleton (unregistered, unmounted, or flag-gated). Decide at
planning time; record it; say in the PR description what makes it safe.

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
([references/pr-workflow.md](references/pr-workflow.md)) to build the squashed stack.
`needs-user-input` decision gates still stop the run — one-shot forgoes review gates, not
decision gates. Switching modes mid-feature works as in the workflow reference.

### THINK — Plan the Batch

**First, re-read the PR Plan, Backlog, and Current Position sections of the state file.**
Every time, unconditionally.

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
   `tddb: make room for PR NN`.

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
   a test by accident. A raising stub makes every accidental pass loud. Keep the skeleton
   merge-safe per Test Strategy (inert or flag-gated if it is reachable).
3. **Verify per test, not per batch.** Run the suite. For *each* batch test, record in the
   state file: it fails, and the failure is the missing behavior — an assertion or expected
   effect — not a compile, import, or fixture error. **A test that passes against a raising
   skeleton is broken** — it is not exercising what it claims; fix it or delete it. This
   per-test check against the skeleton is where the tautology catch lives in this flow.
4. **Commit**: tests + skeletons + state file — `tddb: red batch for PR NN`.
5. **Delegate the test-set review** to a fresh subagent — the exact task prompt and context
   bundle are in [references/delegation.md](references/delegation.md); read that section
   before spawning. In brief, the reviewer gets the PR sentence, criteria, hypothesis, and the
   test files — no implementation exists, which is the point — and must produce artifacts, not
   opinions: a contract reconstruction from the tests alone (divergence from the hypothesis =
   the tests are ambiguous), a trace table (every test → behavior/criterion; no row =
   speculative), a setup census, and the worst assertion named. **Triage the findings
   yourself**: interface revisions happen *now* — amend tests and skeletons, re-run the
   per-test verification, commit. Dismissals need stated reasons, recorded in the state file.

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
  where everything is red and nothing is committed.
- **Pressure log — at every milestone commit**, append two lines to the state file's pressure
  log, answering: *ugliest thing you wrote since the last milestone?* and *most annoying test
  to satisfy so far?* Superlatives always have answers — "nothing" is not a legal reply;
  "X, and it's fine because Y" is. Each answer gets a disposition: **steer now** (refactor
  immediately, stay green) or **hold** (REVIEW will force a decision). Log any smell the
  moment it bites, too — a growing switch, a third repetition, hurting setup — don't wait for
  the milestone.
- **Convergence tripwire**: after **three consecutive full-suite runs with no decrease in the
  failing count**, stop the holistic pass. Drop to the ladder: pick one failing test, make it
  pass, run, commit, repeat. The ladder is a diagnostic mode, not a discipline — return to
  holistic once the entanglement is broken. Log the drop in the pressure log.
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

Set phase to REVIEW.

1. **Drain the pressure log.** Every held item gets a terminal disposition: **fix now** (own
   commit, suite green after), **dismiss** with a reason, or **promote to the backlog** (real,
   but not this PR's work). The pressure log must be empty when this phase ends — it does not
   outlive the PR; the backlog is the only cross-PR notebook.
2. **Self-refactor the whole PR diff** (state file excluded) with
   [references/refactor-checklist.md](references/refactor-checklist.md) and Simple Design
   priority: tests pass > intention clear > no duplication > fewest elements. Where the
   project has coverage tooling, run it over the diff: **any changed code path no test
   exercises is a finding** — dead, speculative, or missing a test; decide which. Where there
   is no tooling, walk the diff's branches and say so — never claim the mechanical check ran
   when it didn't. Do not manufacture trivial tests to silence coverage; a test added here
   must pass the same trace rule RED's review enforces.
3. **Delegate the whole-diff design review** — task prompt and bundle in
   [references/delegation.md](references/delegation.md). The reviewer gets the diff, the
   hypothesis, the dismissals and deferrals so far, and the batch as the spec; its question is
   *"does the implementation honor the hypothesis, and what design pressure emerged?"* — not a
   cold catalog scan. Its report tags each finding **`structural-if-fixed`** (fixing it would
   move responsibilities, add/merge types, or change contracts) or **`local`**.
4. **Triage every finding**: fix (own commit), dismiss with reason, or backlog. Then the
   re-entry rule, decided by the reviewer's tags, not yours: **if any fix you applied was
   tagged `structural-if-fixed`, delegate one more review round on the new diff.** Fixes of
   `local` findings never re-enter. Hard cap: three rounds total — anything structural still
   open after round three goes to the backlog and is surfaced at the boundary as an open
   concern, never silently.
5. **Write the state file**: PR log entry (behaviors delivered, what was learned, hypothesis
   change if any), newly satisfied criteria, hypothesis update, backlog updates, pressure log
   emptied, and the **PR description** (what changes, criteria advanced, what is deliberately
   not here, base branch). Set phase to boundary. Commit. If any backlog item was marked
   deferred, surface it to the user now, not at completion.

Then cross the boundary: SHIP in interactive mode; in one-shot, record `Ends at` and start the
next pass.

### SHIP — Close Out the PR (interactive mode)

SHIP is **gate, squash, and handover only** — the design review already ran in REVIEW; do not
re-review the diff here. Read [references/pr-workflow.md](references/pr-workflow.md) for the
git mechanics.

- Confirm the full suite is green and the tree is clean apart from the state file.
- Confirm the PR is genuinely mergeable alone: observable behavior, no dependence on a later
  PR, anything stubbed is inert or flag-gated.
- **Present the PR and stop.** One-sentence behavior, branch, base, what is deliberately left
  out, any open concern from REVIEW's round cap, and what the next PR does. This is the user's
  moment to reslice, reorder, redirect, or call the feature done. **The squash happens only on
  their approval — never before**; it collapses the milestone checkpoints.
- On approval: squash to one commit (subject = behavior, body = the description), record
  branch and sha, mark the PR `ready`, set Driver Status `pr-ready`, open the next PR and its
  branch per the workflow reference.
- Do not push or open the PR — that is the user's call.

**If this was the last planned PR**, go to the completion gate in [Progress](#progress).

### Resuming mid-PR

The state file records the phase; within GREEN it deliberately records nothing else. To resume
in GREEN: the last milestone commit is the position — its message names the passing subset —
and the pressure log holds the in-flight observations. Re-run the suite to re-establish which
batch tests remain red, then continue the holistic pass. Do not reconstruct position from
memory; the commits are the record.

---

## Design Evolution

Understanding deepens as passes accumulate. Four responses, escalating — full treatment in
[references/design-evolution.md](references/design-evolution.md):

- **Incremental refinement** (in GREEN's steer-now and REVIEW): tests protect you; no user
  involvement.
- **Hypothesis revision** (between passes): a *recurring* smell across PRs — in pressure-log
  drains or backlog entries — shows the direction needs structural change. Present the revised
  hypothesis and revised PR plan together for acknowledgment before restructuring.
- **Acceptance criteria correction**: implementation reveals a criterion is misspecified.
  Never silently adjust tests; surface immediately, get sign-off.
- **Starting fresh**: the approach is fundamentally wrong — delete the implementation, keep
  the batch as the spec, restart with a new hypothesis. Cheap here by design: the tests
  already exist, and the slice bounds the loss to one PR. Not a failure.

The two "present to the user" points are **decision gates** — `needs-user-input` stops in
one-shot mode, not things a standing go-ahead waves past.

If you get stuck, see [references/when-stuck.md](references/when-stuck.md).

---

## Phase Discipline

Restatements of the invariants enforced above — a checklist, not a second rulebook. If you
edit one, edit both.

- **Every batch test verified failing for the right reason, per test, against a raising
  skeleton.** A test that passes against the skeleton is broken.
- **Never touch a test in GREEN outside the amendment protocol.** Amendments are separate,
  visible commits with stated reasons — never folded into implementation commits.
- **Green in GREEN means: prior suite green, passing-batch subset monotonically growing,
  subset named in the commit.** Full green is required only to leave the phase.
- **Write nothing the batch does not demand.** REVIEW's uncovered-path check enforces it;
  RED's trace rule keeps the batch itself honest.
- **No checkpoint accepts "nothing to report" as an answer to a superlative question.**
- **Three flat full-suite runs → the ladder.** Do not thrash holistically.
- **A batch never spans more than one planned PR.** Split the plan, not the fence.
- **The pressure log dies with the PR** — drained to fixes, dismissals, or the backlog.
- **REVIEW re-entry follows the reviewer's `structural-if-fixed` tags, capped at three
  rounds**; leftovers surface at the boundary, never silently.
- **Both per-PR reviews are delegated, always** — a session that wrote the tests or the code
  is the wrong context to review them from.
- **Never execute a stale plan item.**
- **Never leave the suite red at a PR boundary.**
- **Squash only after the PR has been reviewed** — per-PR in interactive, once at the end in
  one-shot.

---

## Progress

After each phase transition, state briefly: where the pass stands, what the pressure log or
reviews surfaced, which criteria remain, and what comes next. At each boundary (interactive),
report the PR as SHIP describes and stop — a boundary is a decision point and should feel
different from a status update. In one-shot, the boundary report is one line:
`PR 02 done at <sha>, review round(s): N, on to PR 03`.

Declare the feature complete only when all four hold:

1. **PR plan**: every planned PR delivered or consciously dropped with a reason.
2. **Acceptance criteria**: every criterion has passing test coverage.
3. **Backlog**: every item resolved, dismissed with a reason, or deferred — deferred items
   surfaced to the user and acknowledged.
4. **Code is clean at feature scale**: one final delegated review of what no single PR could
   show — **cross-PR seams and the component/system altitudes only**; per-PR altitudes were
   covered by each pass's REVIEW and must not be re-swept. Task prompt in
   [references/delegation.md](references/delegation.md). Findings go to the backlog and must
   be resolved before declaring done; substantial ones become a new PR, never an amendment to
   a delivered one.

In one-shot mode, once these hold, present the whole feature for the user's single review;
on approval run Finalization, then Cleanup.

---

## Cleanup

1. **Verify** criteria, PRs, and backlog are closed and learnings have landed in code (tests,
   names, structure, or *why* comments for conscious deferrals). If not, run more passes
   first.
2. **Verify the stack**: report each PR's branch, base, and status; restack if earlier PRs
   merged (see [references/pr-workflow.md](references/pr-workflow.md)).
3. **Decide the state file's fate** — untracked after the last squash; default is delete, but
   ask.

The history is one commit per reviewable increment. Do not collapse the stack further.

---

## Delegated Execution

The two per-PR reviews and the end-of-feature review are **always** delegated — that is not a
mode, it is the design. Optionally, whole *phases* can also be delegated to keep the driving
session small across a long feature; GREEN is the natural unit. The escalation contract, STATUS
line, driver loop, and all task prompts live in
[references/delegation.md](references/delegation.md) — read it in full before delegating
anything; do not guess at the contract from this summary.
