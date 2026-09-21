# Phase Delegation

Optionally, whole *phases* can be delegated to a subagent to keep the driving session's context
small across a long feature. This is a mode, and it is orthogonal to interactive vs. one-shot.

It is a separate decision from the three reviews, which are delegated *always* — those, and
their task prompts, are in [review-prompts.md](review-prompts.md).

Check your available tools for a delegation mechanism before offering this — Claude Code and pi
both expose one, under names that vary by version. Do not assume a tool name.

---

## What can be delegated

Preflight, SHIP, Finalization, and Cleanup **always stay local** — they need live
back-and-forth with the user, or they make git-history decisions and hand work over. THINK
stays local too: it re-reads the plan, may re-slice it, and can hit decision gates.

**REVIEW after PR 01 does those same three things** — re-reads the plan, may re-slice it, can
hit a decision gate — because of the replanning walk that closes it. **It may still be
delegated.** A delegated REVIEW runs the walk itself and writes PR 01's `Replan walk` field (see
SKILL.md's REVIEW, which is authoritative on the walk): a minor reshape it writes and reports
with `STATUS: pr-ready`; a dropped PR or major resequence goes through the Escalation Contract
instead. On return the driver confirms the `Replan walk` field is filled — that field, not the
revised entries, is what shows the walk happened.

What can be delegated is the work between them, in units of a phase. **GREEN is the natural
unit** — it is the largest, most mechanical, and most context-hungry. MAKE ROOM and RED can
also be delegated. Delegating REVIEW as a whole is possible but rarely worth it: its own core
step is already a delegation, and the triage decisions in it are yours.

Note what changes versus a per-cycle flow: **a delegated GREEN is the entire implementation of
a PR.** The driver cannot meaningfully spot-check it mid-flight. What the driver verifies on
return is therefore concrete and checkable: the full suite is green, the batch tests all pass,
the milestone commits exist with named subsets, every observation in the pressure log has a
disposition (counter lines aside), and no test was modified outside an `amend batch` commit.
Verify those before proceeding — `git log --oneline` and one suite run answers all of them.

**A delegated RED owns a delegation of its own** — Review 1, which runs as two turns
([review-prompts.md](review-prompts.md), §"Review 1"). A subagent often cannot send a follow-up
message to a subagent *it* spawned; when yours cannot, use that section's stated fallback — a
second fresh subagent carrying the turn-1 reconstruction verbatim — and never collapse the two
turns into one prompt. What the driver verifies on return: both turns' artifacts are present (a
contract reconstruction, then divergences, trace table, setup census, worst assertion), every
finding was fixed or dismissed with a stated reason in the state file, and the per-test
verification was re-run and re-recorded after any interface amendment.

## Escalation contract

A delegated phase cannot pause to ask the user something — there is no one on the other end of
that process. Wherever the skill says to "surface to the user", "ask", or "get sign-off"
(dropping a plan item or PR, hypothesis revision, criteria correction, a deferred backlog item,
major resequencing — treat the instruction, not this list, as authoritative), a delegated phase
must instead:

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

---

## Driving the loop

Everything below belongs to the driver, not to a delegated phase.

Invoke the delegation mechanism one phase per call:

> Run exactly one phase — `<PHASE NAME>` — of the tdd-batch flow, following
> `<path this session read SKILL.md from>`. The state file is `<explicit path>`. Read the state
> file first, then SKILL.md's "State File", "Test Strategy", "The Pass" (your phase and the
> phases either side of it, for context), and "Phase Discipline", then this file
> (`references/phase-delegation.md`) from the top through the STATUS line list — everything
> after that belongs to the driver, not to you. If your phase delegates a review, its prompt is
> in `references/review-prompts.md`. You are a delegated subagent: no user is present; follow
> the Escalation Contract exactly. Run only your phase; do not start the next one, do not run
> SHIP or Finalization. End your output with the STATUS line.

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
