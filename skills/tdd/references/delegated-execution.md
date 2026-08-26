# Delegated Execution (Subagent Mode)

Everything in the main skill describes running the Cycle directly, in the same session as Preflight. If your environment gives you a way to delegate a task to an isolated agent and get its result back before proceeding (Claude Code and pi both expose one, under names that vary by version), you can instead delegate each Cycle to a fresh subagent, keeping this session's own context small no matter how many cycles the feature takes. Check your available tools for such a mechanism before offering this mode — do not assume a specific tool name; different harnesses expose this capability differently.

This file covers two separate things. **Delegating the Cycle is the optional mode** described above. **Delegating the design reviews is not optional** and does not depend on that mode — see "Delegating a design review" below; it applies whether cycles run here or in subagents.

**What stays local, what gets delegated (cycle mode):**
- **Preflight** (feature definition, acceptance criteria, design hypothesis, PR plan, alignment gate) always runs in this session. It requires live back-and-forth with the user; a delegated subagent process cannot ask questions and wait for an answer.
- **SHIP** (interactive mode) and **Finalization** (one-shot mode) stay local. They squash commits, create branches, and hand PRs to the user — git-history decisions and a handover the user should be part of. **One sub-step is the exception**: the design review of the PR diff is always delegated, in both modes — see "Delegating a design review" below.
- **Cleanup** (stack verification, state file disposition) also stays local, for the same reason — with the same exception for its end-of-feature design review.
- **The Cycle** (THINK, RED, GREEN, REFACTOR) is the delegation unit. One subagent invocation runs exactly one complete cycle end to end, then stops.

**Escalation contract.** A delegated cycle cannot pause mid-way to ask the user something — there is no one on the other end of that process. Wherever the main skill says to "surface to the user," "ask the user," or "get sign-off" (see the callouts throughout SKILL.md that use that language — dropping a plan item or a planned PR, hypothesis revision, criteria correction, a deferred backlog item, and major resequencing are the recurring cases, but treat the instruction, not this list, as authoritative), a delegated cycle must instead:
1. Write the situation into the state-file field that already owns it: a hypothesis or criteria question goes into Design Hypothesis (append to History) or a note in Current Position; a slicing or sequencing question goes into the PR Plan entry it concerns; an edge case, hesitation, or deferred item goes into Backlog. Include enough detail for a human to decide without needing to reconstruct context.
2. Set `## Driver Status` to `needs-user-input` with a one-sentence `Reason`.
3. Stop — do not guess at the answer, and do not proceed past the decision point.

**PR boundaries are a stopping point for the cycle, always.** A delegated cycle never runs SHIP or Finalization. When a cycle completes the current PR's behavior, the subagent updates the state file, records the last cycle commit's sha in that PR's plan entry, sets Driver Status to `pr-ready`, and stops. A delegated cycle must not start work belonging to the next PR: if THINK reveals the next useful behavior is outside the current PR's one-sentence statement, that is the end of this PR — record it and report `pr-ready` rather than absorbing the work.

What the *driver* does with `pr-ready` depends on mode: in interactive mode it runs SHIP locally (stop, review, squash on approval); in one-shot mode it runs only the boundary-crossing steps (delegated design review, PR description) and immediately delegates the next cycle — no stop, no squash, no branch. See the `pr-ready` handling under "Driving the loop".

If, at the start of a cycle, all acceptance criteria are already satisfied, every planned PR's cycles are complete, and the backlog is empty, treat that cycle as the final Progress review pass (see SKILL.md's Progress section) rather than a new test-driven behavior. If it finds nothing further, set Status to `feature-complete`. If it finds something, resolve what fits within the cycle, log the rest to the backlog, and set Status to `in-progress`.

At the end of every delegated cycle, whatever the outcome, end the final output with exactly one line:
- `STATUS: in-progress` — cycle completed normally, more cycles remain in this PR
- `STATUS: pr-ready` — the current PR's behavior is complete (interactive: driver runs SHIP; one-shot: driver does the boundary steps and continues)
- `STATUS: needs-user-input — <reason>` — stopped early, a human decision is needed
- `STATUS: feature-complete` — every planned PR's cycles are done, all acceptance criteria satisfied, backlog resolved, and the final code-clean review is done

**Driving the loop.** The local session acts as the driver: after Preflight and the initial commit, repeatedly invoke your environment's delegation mechanism (one cycle per call) with a task along these lines:

> Run exactly one TDD cycle (THINK → RED → GREEN → REFACTOR) following `<path this session read SKILL.md from — substitute the actual path>`. The state file is `<path to the state file — substitute the actual path>`. Read the state file first, then SKILL.md's "Test Strategy", "The Cycle" (through REFACTOR — skip SHIP), "Phase Discipline" and "Progress" sections, then this file (`references/delegated-execution.md`) from the top through the STATUS line list — everything after that belongs to the driver, not to you — before starting. You are a delegated subagent — no user is present; follow the Escalation Contract above exactly. Do not run SHIP or Finalization and do not begin work belonging to the next PR. If your cycle completes the current PR's behavior, record its last commit sha in that PR's plan entry before reporting `pr-ready`. End your output with the STATUS line described above.

Pass the state file path explicitly — it is named after the effort, so a subagent cannot infer it, and more than one may exist in the repo.

After each call:
- Read the returned STATUS line. If it's missing, malformed, or not the exact final line, don't guess at intent — treat it as `needs-user-input` and read the state file directly to find out what happened. The STATUS line is a convenience; the state file is the record.
- `in-progress`: briefly report progress to the user per SKILL.md's Progress section, then invoke again for the next cycle. Check in with the user at whatever cadence feels right — every cycle, every few cycles, or only on request — this is a judgment call, not a fixed rule.
- `pr-ready`:
  - **Interactive mode** — stop delegating and run SHIP locally. Present the finished PR and wait for the user's review; squash on approval; then resume the loop on the next PR's branch. This is the one point in the loop where a human is always expected — don't skim past it.
  - **One-shot mode** — do not stop. Run the boundary-crossing steps locally: delegate the design review of this PR's cycle range; commit any fixes as ordinary cycle commits and then update the PR's `Ends at` sha to the last of them — the subagent recorded the pre-review sha, and Finalization squashes exactly up to `Ends at`, so a fix left past a stale sha would ship in the *next* PR; write the PR description into the state file. Then delegate the next cycle. No squash, no branch — those are deferred to Finalization, which the driver runs locally once `feature-complete` lands.
- `needs-user-input`: stop looping. Surface the Reason and the relevant state-file detail to the user, resolve it together (which may mean writing a decision into the state file yourself), then resume the loop.
- `feature-complete`: stop looping. In interactive mode, proceed to Cleanup. In one-shot mode, take the user's single end-of-feature review, then run Finalization locally (see `references/pr-workflow.md`) before Cleanup.

Cycle delegation is optional and orthogonal to interactive vs. one-shot. Modes can be mixed within one session (delegate routine cycles, pull a tricky one back in-session). The state file and discipline are identical either way — only who executes each cycle differs.

## Delegating a design review

Three points in the flow hand a design review to a subagent rather than running it in this session: the PR diff review inside SHIP (interactive mode), the same per-PR review at each boundary (one-shot mode), and the end-of-feature pass in Cleanup. All delegate even though SHIP, Finalization, and Cleanup otherwise stay local — and unlike cycle delegation, **this happens whether or not you are delegating cycles**. The reason is not the token saving; it is that this session is the *wrong context* to review from:

- **You wrote the code.** You hold the rationale for every decision in the diff, so anything you remember deciding reads as already-adjudicated rather than as a smell. That bias runs toward under-reporting exactly the things a review exists to catch. A reader given only the diff has no prior commitment to defend.
- **The catalog is meant to be transient.** The per-cycle check is deliberately narrowed to three triggers so the full catalog is *not* in scope while cycling. The feature is not done at a boundary — more cycles follow — so loading the full catalog here would leave it resident for the rest of the feature, quietly overriding that decision.

Be clear-eyed about the trade: delegation costs *more* total tokens, not fewer, since each call is a cold start that re-reads both the catalog and the diff. What it buys is a driver session that stays small and unbiased across the whole feature.

Spawn one subagent with a task along these lines:

> Invoke the `design-review` skill. Scope: `<the exact scope — e.g. the diff of <branch> against <base>, produced with `git diff <base>...<branch> -- . ':(exclude)<state-file>'`; at a one-shot boundary, the PR's cycle range: `git diff <PR-(NN-1)-end>...HEAD -- . ':(exclude)<state-file>'`>`. Focus: `<the altitudes this pass owns — per-PR (SHIP or one-shot boundary): the statement, name, function, and class altitudes; end-of-feature (Cleanup): cross-PR seams and the component and system altitudes>`. Scope and focus are given; do not resolve your own and do not ask for either. Report the rated assessment as your final output. Do not modify any file and do not fix anything you find.

Pass both explicitly and concretely. `design-review` is built to proceed without an interactive user, but only if it is told what to look at — left to infer a scope, it will assume a default and say so, which wastes the pass if the assumption is wrong. The state-file exclusion (`. ':(exclude)<state-file>'` — the `.` is required) keeps its per-cycle churn out of the review; see `references/pr-workflow.md`. The focus is what keeps the passes from overlapping: the per-PR reviewer stays below the component altitude, and the end-of-feature one looks only at what no single PR could show. Without it, the end-of-feature reviewer would sweep every altitude of the whole feature diff — exactly the re-review of already-covered work this flow is built to avoid.

Then **triage locally — the reviewer diagnoses, you decide.** You know what was deliberate: dismiss findings that were consciously deferred and say which, fix what is worth fixing now while keeping the suite green, and record the rest in the state file's Backlog as named entries. The report itself is not kept; the backlog entries are the durable record, the same as for any other finding.
