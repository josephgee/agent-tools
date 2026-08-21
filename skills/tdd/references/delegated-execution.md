# Delegated Execution (Subagent Mode)

Everything in the main skill describes running the Cycle directly, in the same session as Preflight. If your environment gives you a way to delegate a task to an isolated agent and get its result back before proceeding (Claude Code and pi both expose one, under names that vary by version), you can instead delegate each Cycle to a fresh subagent, keeping this session's own context small no matter how many cycles the feature takes. Check your available tools for such a mechanism before offering this mode — do not assume a specific tool name; different harnesses expose this capability differently.

This file covers two separate things. **Delegating the Cycle is the optional mode** described above. **Delegating the design reviews is not optional** and does not depend on that mode — see "Delegating a design review" below; it applies whether cycles run here or in subagents.

**What stays local, what gets delegated (cycle mode):**
- **Preflight** (feature definition, acceptance criteria, design hypothesis, PR plan, alignment gate) always runs in this session. It requires live back-and-forth with the user; a delegated subagent process cannot ask questions and wait for an answer.
- **SHIP** stays local. It squashes commits, creates branches, and hands a PR to the user — git-history decisions and a handover the user should be part of. **One sub-step is the exception**: the design review of the PR diff is always delegated, in both modes — see "Delegating a design review" below.
- **Cleanup** (stack verification, state file disposition) also stays local, for the same reason — with the same exception for its end-of-feature design review.
- **The Cycle** (THINK, RED, GREEN, REFACTOR) is the delegation unit. One subagent invocation runs exactly one complete cycle end to end, then stops.

**Escalation contract.** A delegated cycle cannot pause mid-way to ask the user something — there is no one on the other end of that process. Wherever the main skill says to "surface to the user," "ask the user," or "get sign-off" (see the callouts throughout SKILL.md that use that language — dropping a plan item or a planned PR, hypothesis revision, criteria correction, a deferred backlog item, and major resequencing are the recurring cases, but treat the instruction, not this list, as authoritative), a delegated cycle must instead:
1. Write the situation into the state-file field that already owns it: a hypothesis or criteria question goes into Design Hypothesis (append to History) or a note in Current Position; a slicing or sequencing question goes into the PR Plan entry it concerns; an edge case, hesitation, or deferred item goes into Backlog. Include enough detail for a human to decide without needing to reconstruct context.
2. Set `## Driver Status` to `needs-user-input` with a one-sentence `Reason`.
3. Stop — do not guess at the answer, and do not proceed past the decision point.

**PR boundaries are also a stopping point.** A delegated cycle never runs SHIP. When a cycle completes the current PR's behavior, the subagent updates the state file as normal, sets Driver Status to `pr-ready`, and stops. The driver runs SHIP locally. Equally, a delegated cycle must not start work belonging to the next PR: if THINK reveals that the next useful behavior is outside the current PR's one-sentence statement, that is the end of this PR — record it and report `pr-ready` rather than absorbing the work.

If, at the start of a cycle, all acceptance criteria are already satisfied, every planned PR has shipped, and the backlog is empty, treat that cycle as the final Progress review pass (see SKILL.md's Progress section) rather than a new test-driven behavior. If it finds nothing further, set Status to `feature-complete`. If it finds something, resolve what fits within the cycle, log the rest to the backlog, and set Status to `in-progress`.

At the end of every delegated cycle, whatever the outcome, end the final output with exactly one line:
- `STATUS: in-progress` — cycle completed normally, more cycles remain in this PR
- `STATUS: pr-ready` — the current PR's behavior is complete; the driver should run SHIP
- `STATUS: needs-user-input — <reason>` — stopped early, a human decision is needed
- `STATUS: feature-complete` — all PRs shipped, all acceptance criteria satisfied, backlog resolved, and the final code-clean review is done

**Driving the loop.** The local session acts as the driver: after Preflight and the initial commit, repeatedly invoke your environment's delegation mechanism (one cycle per call) with a task along these lines:

> Run exactly one TDD cycle (THINK → RED → GREEN → REFACTOR) following `<path this session read SKILL.md from — substitute the actual path>`. The state file is `<path to the state file — substitute the actual path>`. Read the state file first, then SKILL.md's "Test Strategy", "The Cycle", "Phase Discipline" and "Progress" sections, then this file (`references/delegated-execution.md`) from the top through the STATUS line list — everything after that belongs to the driver, not to you — before starting. You are a delegated subagent — no user is present; follow the Escalation Contract above exactly. Do not run SHIP and do not begin work belonging to the next PR. End your output with the STATUS line described above.

Pass the state file path explicitly — it is named after the effort, so a subagent cannot infer it, and more than one may exist in the repo.

After each call:
- Read the returned STATUS line. If it's missing, malformed, or not the exact final line, don't guess at intent — treat it as `needs-user-input` and read the state file directly to find out what happened. The STATUS line is a convenience; the state file is the record.
- `in-progress`: briefly report progress to the user per SKILL.md's Progress section, then invoke again for the next cycle. Check in with the user at whatever cadence feels right — every cycle, every few cycles, or only on request — this is a judgment call, not a fixed rule.
- `pr-ready`: stop delegating and run SHIP locally. SHIP ends in a review gate — present the finished PR and wait for the user before resuming the loop on the next PR's branch. This is the one point in the loop where a human is always expected, so don't treat it as a checkpoint you can skim past. If the user has given a standing go-ahead, report and continue without pausing.
- `needs-user-input`: stop looping. Surface the Reason and the relevant state-file detail to the user, resolve it together (which may mean writing a decision into the state file yourself), then resume the loop.
- `feature-complete`: stop looping and proceed to Cleanup as normal.

This mode is optional, and the two modes can be mixed within one session (e.g., delegate routine cycles, pull a tricky one back in-session to work directly). The state file and discipline are identical either way — only who executes each cycle differs.

## Delegating a design review

Two points in the flow hand a design review to a subagent rather than running it in this session: the PR diff review inside SHIP, and the end-of-feature pass in Cleanup. Both delegate even though SHIP and Cleanup otherwise stay local — and unlike cycle delegation, **this happens in both modes**, whether or not you are delegating cycles. The reason is not the token saving; it is that this session is the *wrong context* to review from:

- **You wrote the code.** You hold the rationale for every decision in the diff, so anything you remember deciding reads as already-adjudicated rather than as a smell. That bias runs toward under-reporting exactly the things a review exists to catch. A reader given only the diff has no prior commitment to defend.
- **The catalog is meant to be transient.** The per-cycle check is deliberately narrowed to three triggers so the full catalog is *not* in scope while cycling. SHIP is not terminal — the next PR's cycles follow it — so loading the full catalog here would leave it resident for the rest of the feature, quietly overriding that decision.

Be clear-eyed about the trade: delegation costs *more* total tokens, not fewer, since each call is a cold start that re-reads both the catalog and the diff. What it buys is a driver session that stays small and unbiased across the whole feature.

Spawn one subagent with a task along these lines:

> Invoke the `design-review` skill. Scope: `<the exact scope — e.g. the diff of <branch> against <base>>`. Focus: `<the altitudes this pass owns — from SHIP: the statement, name, function, and class altitudes; from Cleanup: cross-PR seams and the component and system altitudes>`. Scope and focus are given; do not resolve your own and do not ask for either. Report the rated assessment as your final output. Do not modify any file and do not fix anything you find.

Pass both explicitly and concretely. `design-review` is built to proceed without an interactive user, but only if it is told what to look at — left to infer a scope, it will assume a default and say so, which wastes the pass if the assumption is wrong. The focus is what keeps the two passes from overlapping: SHIP's reviewer stays below the component altitude, and Cleanup's looks only at what no single SHIP could see. Without it, the Cleanup reviewer would sweep every altitude of the whole feature diff — exactly the re-review of already-shipped work this flow is built to avoid.

Then **triage locally — the reviewer diagnoses, you decide.** You know what was deliberate: dismiss findings that were consciously deferred and say which, fix what is worth fixing now while keeping the suite green, and record the rest in the state file's Backlog as named entries. The report itself is not kept; the backlog entries are the durable record, the same as for any other finding.
