# ATDD Review Prompts

## Design review

**Fresh, not blind**: this reviewer checks the draft against `design-principles`' vocabulary and
the codebase itself, so it needs pointers into the code. It is a different subagent from the
drafter because the session that produced the design is the least likely to see its blind spots.

**What the subagent receives**:

- The draft design doc from RESEARCH & DESIGN step 1.
- Pointers into the codebase paths the design touches or extends — handed off from that same
  step's research, not rediscovered from scratch.
- Access to `design-principles`' vocabulary (SOLID, component boundaries, Simple Design
  priorities, the design-rot symptom catalog).

**What it does not receive**: ACCEPT's acceptance tests, or any pressure toward a particular
answer — its job is to judge the design on its merits and against this codebase's existing
patterns, not to bless it.

**Prompt shape**:

> Review this design draft before it goes to the user for sign-off. You have the draft and
> pointers into the parts of the codebase it touches or extends — read what you need there to
> judge fit. Assess it against `design-principles`' vocabulary: does it respect existing
> boundaries and conventions in this codebase, does it hold up against SOLID and the
> component-cohesion/coupling principles, does Simple Design's priority order (tests pass >
> intention clear > no duplication > fewest elements) suggest a smaller design. Report findings
> ranked by severity, each with what's wrong and why it matters — including "no findings, this
> fits" if that's the honest read.

**Triage** (back in the host session): fix and revise the draft, or dismiss with a stated reason.
Record both in the state file's Design section, under **Design review**.

## REVIEW's blind review

**Why blind**: this reviewer's read of the code must not be anchored to the design doc that
produced it. It checks whether the diff holds up on its own, to someone who never saw the plan.

**What the subagent receives** — nothing beyond this:

- The diff for this slice:
  `git -C <absolute-repo-path> diff <previous-slice-branch>...HEAD -- . ':(exclude)<plans-dir>/'`,
  where `<previous-slice-branch>` is the base branch for slice 01. Resolve
  `git rev-parse --show-toplevel` yourself and paste the absolute path in; state it as the
  subagent's working directory, since a `$(...)` left unexpanded is evaluated in the subagent's own
  directory, possibly a different repository. The diff includes any earlier-slice test the host
  updated on this branch — that change gets no other review.
- The unit tests from RED, as part of that diff.
- Access to `design-principles` and `design-review`'s vocabulary for naming what it finds.

**What it must not receive**: the design doc, the RESEARCH & DESIGN section of the state file,
ACCEPT's table of acceptance proofs (a persisted one appears as a suite test in the diff and is
fine), or any framing of what this slice is "supposed to" do beyond what the
diff and tests say for themselves.

**Prompt shape**:

> Review this diff as a design-review pass (see the `design-review` skill for the standard and
> vocabulary). You are seeing only the code and its tests — no design document, no plan, no
> feature description. Assess it on its own terms: naming, structure, test quality (FIRST,
> behavioral-not-wiring), duplication, and whether the tests actually pin the behavior the code
> implements. Report findings ranked by severity, each with what's wrong and why it matters, and
> tag each one `structural-if-fixed` (fixing it would move responsibilities, add or merge types,
> or change contracts) or `local`. Do not speculate about intent you weren't given — review
> what's in front of you.

**Triage and re-entry** (back in the host session): follow SKILL.md's REVIEW steps 2 and 3, which
own the dispositions, the two always-backlog findings and the three-round cap. Each re-review
round is a *new* fresh subagent with the same bundle over the new diff; never reuse the previous
reviewer.
