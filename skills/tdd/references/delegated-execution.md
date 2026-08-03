# Delegated Execution (Subagent Mode)

Everything in the main skill describes running the Cycle directly, in the same session as Preflight. If your environment gives you a way to delegate a task to an isolated agent and get its result back before proceeding (for example, pi's `subagent` tool, Claude Code's `Task` tool, or an equivalent in whatever harness you're running in), you can instead delegate each Cycle to a fresh subagent, keeping this session's own context small no matter how many cycles the feature takes. Check your available tools for such a mechanism before offering this mode — do not assume a specific tool name; different harnesses expose this capability differently.

**What stays local, what gets delegated:**
- **Preflight** (feature definition, acceptance criteria, design hypothesis, PR plan, alignment gate) always runs in this session. It requires live back-and-forth with the user; a delegated subagent process cannot ask questions and wait for an answer.
- **SHIP** stays local. It squashes commits, creates branches, and hands a PR to the user — git-history decisions and a handover the user should be part of.
- **Cleanup** (stack verification, state file disposition) also stays local, for the same reason.
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

> Run exactly one TDD cycle (THINK → RED → GREEN → REFACTOR) following `<path this session read SKILL.md from — substitute the actual path>`. The state file is `<path to the state file — substitute the actual path>`. Read the state file first, then SKILL.md's "Test Strategy", "The Cycle", "Phase Discipline" and "Progress" sections, then this file (`references/delegated-execution.md`) in full, before starting. You are a delegated subagent — no user is present; follow the Escalation Contract above exactly. Do not run SHIP and do not begin work belonging to the next PR. End your output with the STATUS line described above.

Pass the state file path explicitly — it is named after the effort, so a subagent cannot infer it, and more than one may exist in the repo.

After each call:
- Read the returned STATUS line. If it's missing, malformed, or not the exact final line, don't guess at intent — treat it as `needs-user-input` and read the state file directly to find out what happened. The STATUS line is a convenience; the state file is the record.
- `in-progress`: briefly report progress to the user per SKILL.md's Progress section, then invoke again for the next cycle. Check in with the user at whatever cadence feels right — every cycle, every few cycles, or only on request — this is a judgment call, not a fixed rule.
- `pr-ready`: stop delegating and run SHIP locally. SHIP ends in a review gate — present the finished PR and wait for the user before resuming the loop on the next PR's branch. This is the one point in the loop where a human is always expected, so don't treat it as a checkpoint you can skim past. If the user has given a standing go-ahead, report and continue without pausing.
- `needs-user-input`: stop looping. Surface the Reason and the relevant state-file detail to the user, resolve it together (which may mean writing a decision into the state file yourself), then resume the loop.
- `feature-complete`: stop looping and proceed to Cleanup as normal.

This mode is optional, and the two modes can be mixed within one session (e.g., delegate routine cycles, pull a tricky one back in-session to work directly). The state file and discipline are identical either way — only who executes each cycle differs.
