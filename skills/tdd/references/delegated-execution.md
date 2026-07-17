# Delegated Execution (Subagent Mode)

Everything in the main skill describes running the Cycle directly, in the same session as Preflight. If your environment gives you a way to delegate a task to an isolated agent and get its result back before proceeding (for example, pi's `subagent` tool, Claude Code's `Task` tool, or an equivalent in whatever harness you're running in), you can instead delegate each Cycle to a fresh subagent, keeping this session's own context small no matter how many cycles the feature takes. Check your available tools for such a mechanism before offering this mode — do not assume a specific tool name; different harnesses expose this capability differently.

**What stays local, what gets delegated:**
- **Preflight** (feature definition, acceptance criteria, design hypothesis, plan, alignment gate) always runs in this session. It requires live back-and-forth with the user; a delegated subagent process cannot ask questions and wait for an answer.
- **Cleanup** (final squash, state file deletion) also stays local — it involves git-history decisions the user should make directly.
- **The Cycle** (THINK, RED, GREEN, REFACTOR) is the delegation unit. One subagent invocation runs exactly one complete cycle end to end, then stops.

**Escalation contract.** A delegated cycle cannot pause mid-way to ask the user something — there is no one on the other end of that process. Wherever the main skill says to "surface to the user," "ask the user," or "get sign-off" (see the callouts throughout SKILL.md that use that language — dropping a plan item, hypothesis revision, criteria correction, a deferred backlog item, and major resequencing are the recurring cases, but treat the instruction, not this list, as authoritative), a delegated cycle must instead:
1. Write the situation into the state-file field that already owns it: a hypothesis or criteria question goes into Design Hypothesis (append to History) or a note in Current Position; an edge case, hesitation, or deferred item goes into Backlog. Include enough detail for a human to decide without needing to reconstruct context.
2. Set `## Driver Status` to `needs-user-input` with a one-sentence `Reason`.
3. Stop — do not guess at the answer, and do not proceed past the decision point.

If, at the start of a cycle, all acceptance criteria are already satisfied and the backlog is empty, treat that cycle as the final Progress review pass (see SKILL.md's Progress section) rather than a new test-driven behavior. If it finds nothing further, set Status to `feature-complete`. If it finds something, resolve what fits within the cycle, log the rest to the backlog, and set Status to `in-progress`.

At the end of every delegated cycle, whatever the outcome, end the final output with exactly one line:
- `STATUS: in-progress` — cycle completed normally, more work remains
- `STATUS: needs-user-input — <reason>` — stopped early, a human decision is needed
- `STATUS: feature-complete` — all acceptance criteria satisfied, backlog resolved, and the final code-clean review is done

**Driving the loop.** The local session acts as the driver: after Preflight and the initial commit, repeatedly invoke your environment's delegation mechanism (one cycle per call) with a task along these lines:

> Run exactly one TDD cycle (THINK → RED → GREEN → REFACTOR) following `<path this session read SKILL.md from — substitute the actual path>`. The state file is `tdd-state.md` in the project root. Read the state file first, then SKILL.md's "Test Strategy", "The Cycle", and "Phase Discipline" and "Progress" sections, then this file (`references/delegated-execution.md`) in full, before starting. You are a delegated subagent — no user is present; follow the Escalation Contract above exactly. End your output with the STATUS line described above.

After each call:
- Read the returned STATUS line. If it's missing, malformed, or not the exact final line, don't guess at intent — treat it as `needs-user-input` and read the state file directly to find out what happened. The STATUS line is a convenience; the state file is the record.
- `in-progress`: briefly report progress to the user per SKILL.md's Progress section, then invoke again for the next cycle. Check in with the user at whatever cadence feels right — every cycle, every few cycles, or only on request — this is a judgment call, not a fixed rule.
- `needs-user-input`: stop looping. Surface the Reason and the relevant state-file detail to the user, resolve it together (which may mean writing a decision into the state file yourself), then resume the loop.
- `feature-complete`: stop looping and proceed to Cleanup as normal.

This mode is optional, and the two modes can be mixed within one session (e.g., delegate routine cycles, pull a tricky one back in-session to work directly). The state file and discipline are identical either way — only who executes each cycle differs.
