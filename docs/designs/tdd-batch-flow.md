# tdd batch flow: TDD's invariants without its pacing

**What was decided.** A **new skill, `tdd-batch`, competing with `tdd` — the existing skill
is not changed.** `tdd` remains the strict per-test flow; `tdd-batch` reworks the inner loop
from per-test RED–GREEN–REFACTOR cycles to a per-PR batch flow: a make-room phase on unpinned existing code, RED as a whole-PR test batch
against skeleton stubs with a **delegated test-set review**, holistic GREEN with milestone
commits and a pressure log, and a whole-diff refactor/re-review loop whose re-entry follows
the reviewer's structural tags. TDD's invariants survive untouched; the per-cycle ceremony is
dropped; every checkpoint obeys **produce-then-judge** — attestations like "no design
pressure" are illegal by construction. Everything below is why.

## Problem

Four defects observed in practice with the current skill:

- **Reviews are isolated.** The delegated per-PR design review arrives cold — no design
  intent, no record of what was consciously deferred — and produces nitpicks.
- **Design decisions are micro-isolated.** Each REFACTOR sees one cycle's diff. Duplication
  introduced in cycle one and repeated in cycle four is invisible to both.
- **Refactoring judgment is poor** — but the judgment isn't the defect, the aperture is. A
  single cycle's diff is too small for any structural signal to appear in.
- **Token expensive.** Every cycle pays a state re-read, a state write, a reflection ritual, a
  design-pressure check, and a commit. A five-cycle PR pays five of everything.

The diagnosis under all four, in two halves. Humans *need* small steps — limited working
memory can't hold the whole design while writing code. And small steps *pay off* for humans
because human judgment is **ambient**: every tiny step gets reassessed for free, without
deciding to. Agents invert both properties: context large enough to skip the small steps, and
judgment that fires only when **invoked**. So tight cycles give an agent the cost of the
pacing without the reassessment that made the pacing valuable — which is why the per-cycle
REFACTOR ritual underdelivered (scheduled reflection is an attempt to fake ambience, and it
gets perfunctory compliance), and why agent failure modes are different in kind: tautological
tests, over-implementation, quietly weakened assertions, scope drift.

The design principle that follows, and that shapes everything below: **since agent judgment
is invoked rather than ambient, invoke it few times at high-leverage apertures instead of
many times at low ones.** (This also predicts the flow's weakest element honestly: the
pressure log is another attempt at faked ambience — see the open question in the
emergent-design section.)

## Keep the invariants, drop the pacing

What TDD actually buys an agent, kept verbatim:

- Tests written **before** implementation, each **confirmed failing for the right reason**
  (the tautology catch).
- Full suite green; **never modify a test during GREEN**.
- One-sentence PR scope; squash only after review.
- Outside-in strategy, merge-safe first PR, behavioral-not-wiring, mock-at-boundary.

What gets dropped, because it targets human limits, not agent ones:

- Per-cycle state churn, reflection ritual, and design-pressure check.
- "Simplest code that passes this one test" — for an agent this produces hardcoded-return
  churn it immediately rewrites; the scope fence moves to the test batch (below).

## The flow, per PR

**0. Make room** — only when the PR touches existing code. First backfill tests on the code
about to be disturbed (invoke `backfill-tests`, which already carries the right quality bar —
new soft-dep), then preparatory refactoring to make the change easy. Both behavior-preserving,
committed before any new behavior. The current skill has no make-room step at all — it is
greenfield-shaped; this is a genuine gap being closed, not a relocation.

**1. Batch RED + delegated test-set review.** Write *all* the PR's tests against the interface
chosen in THINK; run them; confirm each fails for the right reason. Then **delegate a review
of the tests as a set** — the cheapest delegation the flow buys, because no implementation
exists yet: the delegate's whole context is the batch plus the hypothesis and criteria. It
checks shared setup pain, contract inconsistency, awkward assertions, the trace table — and
one thing self-review structurally cannot produce: a **consumer's-eye contract check**. A cold
reader who must infer the contract purely from the tests is simulating exactly the future
consumer; if the delegate can't reconstruct the contract, the tests are unclear. Revise the
interface on its findings now, before any implementation exists. This point is *stronger* than
per-test TDD gave: one awkward test is a whisper; five tests all needing the same contorted
setup is a verdict no single cycle could render. The batch also becomes the scope fence for
GREEN: implement nothing the batch doesn't demand. A batch is a better fence than "simplest
code for one test" because the anticipation is already written down as tests instead of
leaking into the implementation.

**2. Holistic GREEN + pressure log.** Implement the batch as one designed pass — the agent
holds the whole spec in context; mandating one-test-at-a-time would be the working-memory
prosthetic again. The invariant is not order but **checkpoints**: run the suite at coherent
milestones and commit at each green one (message only — no state write). No long stretch
where everything is red and nothing is committed. **If the batch won't converge** — failures
entangled, fixes thrashing — drop to one-test-at-a-time as a diagnostic ladder, not a
discipline. Emergent design lives in the writing, not the ordering: when a smell arises —
third repetition of a shape, a growing switch, setup starting to hurt — steer immediately, or
append one line to a pressure log in the state file. Append-only, no ritual, whenever
friction bites.

**3. Refactor / re-review loop.** After the batch is green:

1. Self-refactor consuming the pressure log plus the whole-diff checklist.
2. Delegated design review **with context**: the design hypothesis, the deliberate deferrals,
   and the tests-as-spec. The review question becomes "does the implementation honor the
   hypothesis, and what pressure emerged" — not a cold catalog scan. This is the fix for
   review isolation.
3. Triage every finding: fix, dismiss-with-reason, or backlog.
4. **Re-review only if the fixes changed structure** — moved responsibilities, new or merged
   types, changed contracts. Renames and extractions do not re-enter. To keep this gate out
   of the author's hands, the delegate tags each finding **"structural if fixed"** in its
   report — re-entry is decided by the reviewer's tag, not the author's self-classification.
   This condition is the convergence guarantee: structural fixes shrink round over round;
   expect two rounds, rarely three.

One-shot mode, the PR plan, slicing rules, and the decision gates are unchanged. SHIP keeps
its review gate, squash, and handover mechanics but **sheds its design-review step** — phase 3
owns the whole-diff review now, and running SHIP's on top of it would review the same diff
twice. The redesign is otherwise confined to what happens *inside* a PR.

**PR slicing is not merely preserved — it becomes load-bearing.** Decomposing a feature into
independently reviewable behavioral increments stays the delivery layer, exactly as today. But
where the old flow used the PR boundary only as a review gate, the batch flow hangs everything
on it: the PR's one-sentence behavior sizes the test batch, the batch fences GREEN, and the
slice bounds the sunk cost of a design that emerges too late. A batch must never span more
than one planned PR — batching the *ceremony* to PR grain is the design; batching the *scope*
past it would recreate the unreviewable-PR failure the slicing rules exist to prevent. Any
future edit that weakens `pr-slicing.md` weakens this whole flow.

## The emergent-design objection

The strongest objection: human TDD's value is watching smells arise and steering the design in
response, and a batch flow that designs up front then implements in one pass loses it. The
answer that shaped phase 2: **emergence comes from contact with the code — writing it — not
from the order it is written in or the ceremony around each step.** The smells arise on the
page either way; the pressure log keeps the noticing, and the whole-diff refactor pass is the
steering point. (An earlier draft mandated one-test-at-a-time GREEN to preserve emergence;
that was the working-memory prosthetic sneaking back in, and it fell to the same argument
that removed the per-cycle loop. What made dropping it safe is the slice: at one-sentence PR
scope, the largest thing a smell can arrive "too late" to steer is a few hundred lines, well
within one refactor pass's aperture.)

Two backstops bound the residual risk. PRs are one-sentence-scoped, so the maximum sunk cost of
a design that emerged too late is one small PR. And teardown is cheap for agents in a way it
never is for humans — rebuilding a PR-sized implementation against an already-written test
batch costs less than the per-cycle ceremony did. "Starting fresh" is already a sanctioned
outcome; the batch flow makes it cheaper to invoke.

Open question, honestly held: whether an invoked prompt gets an agent to *notice* as reliably
as ambient human reassessment does. The produce-then-judge rule (failure mode 6) is the
mitigation — superlative questions that always have answers, so "nothing to report" is never
a legal reply — but whether produced candidates surface the *real* pressure is the thing a
trial tests, and the reason to run one rather than pre-pay the old cost forever.

## Where YAGNI lives now

"Simplest code that passes this one test" was TDD's YAGNI mechanism, and it left with the
per-test loop. The batch flow replaces it with two explicit rules, one per direction
speculation can leak — and both are **checkable at a review point** rather than promised
during implementation, which is what the old rule never was for agents ("simplest" is a
judgment call agents fudge; the rules below are near-falsifiable):

- **Speculative tests** (a risk the per-test flow didn't have — the batch itself can bloat):
  the phase-1 test-set review includes a trace check — every test traces to the PR's
  one-sentence behavior or an acceptance criterion it advances. Anything else moves to a
  later PR or the backlog. This replaces THINK's per-test "is this behavior actually needed
  now?"
- **Speculative implementation**: phase 3 checks the fence mechanically — *any code path no
  test in the batch exercises is a finding*: dead, speculative, or missing a test, all three
  actionable. Speculative Generality is already in the `design-principles` catalog the
  delegated reviewer carries; this names it as a standing per-PR check rather than an
  occasional catch.

## Rejected alternatives

- **Micro-cycles minus per-cycle REFACTOR** (judgment moved to boundaries, loop kept) —
  keeps N× the state overhead and only half-fixes the aperture problem.
- **Full test-last** (implement, then backfill) — loses the confirmed-failing check, which is
  the one mechanism that catches an agent's tautological tests.
- **Per-test mini-REFACTOR pauses inside GREEN** — the old loop with fewer commits; the
  steering signal comes from writing the code, not from a scheduled pause after each test.
- **Mandated one-test-at-a-time GREEN** — held in an earlier draft to preserve emergent
  design; dropped because its remaining justification was failure localization, which a
  well-formed batch provides by itself (each test names its behavior) and which the
  convergence fallback provides on demand, exactly when it is needed.
- **Single fixed review pass, no loop** — cheaper per PR, but a structural fix is new
  unreviewed code; the structure-gated re-entry buys the safety while self-limiting cost.
- **Adversarial split** (test-writer agent never sees the implementation; implementer can't
  touch tests) — *parked, not dropped*. It attacks test-gaming harder than batching does, but
  whether it costs more tokens than it saves in review is unquantified. Revisit if trials show
  agents gaming the batch.

## Known failure modes → requirements on the rewrite

A critical pass over the flow for agent executability. Each entry is a way an agent running
this would improvise, silently defect, or rebuild the token cost — and the mechanic the
Cycle rewrite must therefore contain. Treat this section as the checklist the draft is
verified against.

1. **Batch RED doesn't compile.** N tests against a nonexistent interface all fail as
   import/compile errors — the "wrong reason" by the standing rule — and agents improvise
   badly in both directions (declare compile errors acceptable, or implement real behavior to
   make tests "fail properly"). *Required:* an explicit skeleton step — after writing the
   batch, create inert stubs (signatures, empty bodies) so every test fails on its assertion.
   And because stubs returning `None`/`0`/empty can accidentally satisfy tests, the
   failing-for-the-right-reason check runs **per test against the skeleton** — this is where
   the tautology catch now lives.

2. **Wrong test discovered mid-GREEN has no legal exit.** Batch flow can discover test 6 was
   mis-specified an hour in, with "never modify a test during GREEN" barring the door — and
   an agent with a hard invariant and no sanctioned path weakens the assertion silently.
   *Required:* an amendment protocol — halt, state the defect, amend the test in its own
   commit, re-confirm it fails against current code, log it. Visible amendment beats
   forbidden amendment.

3. **Phase 0's gate fires on every PR.** "Touches existing code" is true of every PR after
   the first, so `backfill-tests` would run constantly — rebuilding the token sink this
   design removes. *Required:* gate phase 0 to code being changed that is **outside this
   feature's own prior PRs** and whose behavior is not already pinned; feature-internal code
   is covered by construction.

4. **"Won't converge" has no trigger, and agents don't give up.** A description of thrash is
   not a condition; an agent will thrash indefinitely rather than self-diagnose. *Required:*
   a concrete tripwire — e.g., three consecutive full-suite runs with no decrease in the
   failing count → drop to the one-test ladder. (Same lesson as AGENTS.md's
   vague-branch-loses rule.)

5. **"Green milestone" contradicts the drilled invariant.** During phase 2 the suite is
   definitionally red (remaining batch tests), and "never commit on red" will make agents
   refuse to milestone-commit or feel licensed to commit anything. *Required:* redefine
   green for phase 2 — pre-existing suite green plus a monotonically growing subset of the
   batch green, the subset named in the commit message.

6. **Self-judged checkpoints, each biased toward finishing sooner.** Two structural
   answers, applied by kind:

   **Delegate what has an artifact.** The phase-1 test-set review and the phase-3 whole-diff
   review both go to fresh-context subagents — two standing delegations per PR, still far
   under the per-cycle era's spend, and phase 1 is the cheapest review the flow buys (no
   implementation exists; the delegate's context is the batch plus hypothesis and criteria,
   and its cold read *is* the consumer's-eye contract check). Authorship bias — the actual
   rubber-stamp mechanism — is absent in a fresh context. The re-review gate's structural
   classification also leaves the author's hands: the phase-3 delegate tags each finding
   "structural if fixed", and re-entry follows the tag.

   **Produce-then-judge what stays local.** The pressure log cannot be delegated — it is
   in-flight noticing during GREEN with no artifact yet to hand over — so it must not accept
   attestations. "No design pressure" survives because it is a legal zero-cost answer; make
   the null answer illegal by construction. **Superlatives always have answers** ("ugliest
   thing written this milestone", "most annoying test setup so far"): detection is
   mandatory, the *judgment* may still be "fine, because Y" — agents rubber-stamp detection
   but engage with evaluation once a candidate is on the table, and a dismissal-with-reason
   is auditable where silence never was. The same artifact demands (trace table filled not
   ticked, worst-assertion named) go to the delegates too — fresh context removes bias, not
   laziness. (Rejected: finding quotas — they manufacture defects; superlatives rank what
   exists. Rejected: keeping phase 1 local with produce-then-judge alone — the cold contract
   read is the one signal self-review structurally cannot produce, and it comes at the point
   of minimum reviewer context.)

7. **The untested-path check claims mechanical status without a mechanism.** Agents will
   eyeball the diff and declare it done. *Required:* run coverage where the project has it,
   named judgment where it doesn't. And the check must acknowledge the trace check: flagging
   every uncovered defensive branch pushes agents to write trivial tests, which phase 1 then
   has to reject — the two rules cite each other.

8. **Minor:** mid-phase-2 resume is thinner than per-cycle resume was — milestone commits
   carry the position, and the resume protocol must say so explicitly. Delegating "a phase"
   is a far larger unit than delegating a cycle; a delegated phase 2 is the entire
   implementation, which changes what the driver can meaningfully verify on return —
   `delegated-execution.md` needs its contract rethought, not just renamed.

## File plan: a new skill, `tdd-batch`

`skills/tdd/` is **not touched**. The new skill lives at `skills/tdd-batch/` (frontmatter
`name: tdd-batch`, per repo policy). Its `description` must differentiate the trigger from
`tdd`'s — both fire on "build a feature test-first", so the description leads with what
distinguishes it (batch-per-PR, agent-optimized, two delegated reviews per PR); in practice
a harness installs one of the two, and side-by-side trials pick per-session by name.

- `SKILL.md` — Preflight, Test Strategy, execution modes, and Design Evolution adapted from
  `tdd`; The Cycle is the batch flow (phases THINK → MAKE ROOM → RED → GREEN → REVIEW);
  Phase Discipline restated at batch grain. **SHIP has no design-review step** — REVIEW owns
  the whole-diff review; SHIP is gate, squash, and handover only.
- `state-format.md` — per-PR entries instead of per-cycle log entries; adds the pressure log.
- `references/` — copied from `tdd` where unchanged (`pr-slicing.md`, `pr-workflow.md` —
  references are private per skill by repo policy, so copy, and accept the drift risk);
  `refactor-checklist.md` adapted (consumed once per PR at REVIEW); `delegated-execution.md`
  rethought (delegation unit is a phase; two standing review delegations per PR with context
  bundles and produce-then-judge artifact demands).
- Frontmatter deps: `design-principles`, `design-review` (hard, as in `tdd`), plus
  `backfill-tests` (MAKE ROOM).

## Status

**Built.** `skills/tdd-batch/` exists: `SKILL.md`, `state-format.md`, and seven references
(`review-prompts.md`, `phase-delegation.md`, `refactor-checklist.md`, `when-stuck.md`,
`design-evolution.md`, `pr-slicing.md`, `pr-workflow.md`). `skills/tdd/` is untouched. The throwaway Cycle draft that
preceded it has been deleted — the skill files are the artifact now.

All eight failure modes above are answered in the built skill: raising skeletons and per-test
verification (1), the amendment protocol (2), MAKE ROOM's two-condition gate (3), the
three-flat-runs tripwire (4), green redefined for GREEN (5), two delegated reviews plus
superlative pressure-log prompts (6), coverage-or-named-judgment (7), and the mid-PR resume
section plus a rethought phase-delegation contract (8). The four open gaps closed as: THINK
produces the behavior list and interface sketch; the pressure log is intra-PR and dies at
REVIEW, leaving the backlog as the only cross-PR notebook; state writes are per-phase with
GREEN deliberately dark; and both review prompts are written out in `review-prompts.md`.

Decisions made during the build that this document did not ratify — the things to watch in
trials: raising stubs rather than empty ones; contract reconstruction *before* the reviewer
reads the hypothesis; in-scope missing behaviors joining the batch via the amendment protocol;
a hard three-round cap on review re-entry with leftovers surfaced at the boundary; GREEN
writing no state except the pressure log; and an added **interface revision** response in
design-evolution (the cheap RED-time revision a per-test flow has no equivalent for).

**Everything here is theory until used.** The plan is side-by-side trials against `tdd`. The
three claims most in need of evidence: whether superlative prompts surface *real* design
pressure or merely produce nominated candidates; whether the batch can be gamed in ways the
per-test flow could not (the parked adversarial split is the response if so); and whether two
delegated reviews per PR actually land under the per-cycle flow's total spend.
