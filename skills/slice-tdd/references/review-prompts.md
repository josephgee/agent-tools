# Slice TDD Review Prompts

## Design review

**Fresh, not blind**: this reviewer checks the draft against `design-principles`' vocabulary and
the codebase itself, so it needs pointers into the code. It is a different subagent from the
drafter because the session that produced the design is the least likely to see its blind spots.

**What the subagent receives**:

- The slice's behavior sentence — what every row of the target must trace to.
- The plan's Constraints — a design that breaks one is a finding however well it fits otherwise.
- The draft from DESIGN step 1: interface sketch, design doc, and the files it will modify.
- The target the design must deliver — ACCEPT's acceptance tests in `acceptance` mode, the draft's
  behavior list in `internal` mode.
- Pointers into the codebase paths the design touches, extends or read — handed off from that same
  step's research, not rediscovered from scratch.
- Access to `design-principles`' vocabulary (SOLID, component boundaries, Simple Design
  priorities, the design-rot symptom catalog).

**What it does not receive**: any pressure toward a particular answer — its job is to judge the
design against its target, on its merits and against this codebase's existing patterns, not to
bless it. It reads *beyond* the files the design modifies: a review held to the changed files
misses duplication of something the codebase already has, and patterns the neighbouring code
already set.

**Prompt shape**:

> Review this design draft before any code is written against it. You have the draft, the target
> it must satisfy (acceptance tests or a behavior list), and pointers into the parts of the
> codebase it touches or extends — read what you need there to judge fit, including the code
> *around* the files it modifies. First: does the design deliver every row of the target, and in
> a behavior list, does every row trace to the slice's behavior sentence? Does it break any of the
> plan's Constraints? Then: does the codebase
> already have something this duplicates — a helper, a type, a pattern for this kind of problem —
> that the design should reuse or follow instead? Then assess it against `design-principles`' vocabulary: does it follow
> this codebase's conventions, and does it preserve existing behavior while reshaping any structure
> that doesn't fit this change, rather than designing around it? Does it hold up against SOLID and the
> component-cohesion/coupling principles, does Simple Design's priority order (tests pass >
> intention clear > no duplication > fewest elements) suggest a smaller design. Report findings
> ranked by severity, each with what's wrong and why it matters — including "no findings, this
> fits" if that's the honest read. Then, as a separate section, a wiring table: one row per new
> parameter, dependency, global or shared value the design introduces, naming every receiver and
> whether each needs it, and flagging any vendor-specific name that reaches a layer that should be
> neutral — "none introduced" if there are none. Any row that fails also goes in the findings.

## REVIEW's blind review

**Why blind**: this reviewer's read of the code must not be anchored to the design doc that
produced it. It checks whether the diff holds up on its own, to someone who never saw the plan.

**What the subagent receives** — nothing beyond this:

- The diff for this slice:
  `git -C <absolute-repo-path> diff <previous-slice-branch>...HEAD -- . ':(exclude)<plans-dir>/'`,
  where `<previous-slice-branch>` is the previous slice's branch — or, for slice 01, the state
  file's Session `Base branch`. Resolve
  `git rev-parse --show-toplevel` yourself and paste the absolute path in; state it as the
  subagent's working directory, since a `$(...)` left unexpanded is evaluated in the subagent's own
  directory, possibly a different repository. The diff includes any earlier-slice test the
  executor updated — that change gets no other review.
- The unit tests from RED, and any pins from MAKE ROOM, as part of that diff.
- Access to `design-principles` and `design-review`'s vocabulary for naming what it finds.

**What it must not receive**: the design doc, the Design section of the state file (behavior
list included), ACCEPT's table of acceptance proofs (a persisted one appears as a suite test in the diff and is
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

Each re-review round is a *new* fresh subagent with the same bundle over the new diff; never
reuse the previous reviewer.
