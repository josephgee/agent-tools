# PR Slicing

How to decompose a feature into an ordered sequence of PRs. Read this when building the PR plan
during Preflight, and again whenever the plan needs re-slicing mid-feature.

A **PR** here means one independently reviewable change: a diff a reviewer can read start to
finish, understand, and approve without needing the rest of the feature in front of them. If the
project has no forge, it still means the same thing — the unit of review doesn't depend on the
tooling.

## Read the slicing doctrine first

**Read `slice-plan/references/slicing.md` in full before drafting the PR plan** — `slice-plan` is
a sibling directory of this skill's own directory — resolve it relative to the directory you are
reading this file from: `../../slice-plan/references/slicing.md`. Read the file directly;
do **not** invoke the `slice-plan` skill, which would start a planning session of its own and try
to take this feature over. You want its reference file, not its workflow.

That file is the general doctrine, and this one does not repeat it. It covers:

- the rule that every slice changes observable product behavior, and when a `refactor` or
  `scaffolding` slice is allowed as an exception;
- the sizing test, and the splitting moves for a slice that is too big;
- the **steel thread** (walking skeleton) that opens a sequence over new ground, how to split a
  thread at a seam when it turns out too big, and the live-vs-inert merge-safety choice for it;
- why a steel thread's test must be written to survive later slices thickening it, and what
  to do when a later slice legitimately invalidates an earlier one's test;
- the slicing anti-patterns;
- a worked example, and how and when to re-slice.

It says **slice** where this skill says **PR**: the same unit, one independently reviewable
increment of observable behavior. It is deliberately strategy-neutral — it says nothing about
tests, cycles or phases. The rest of this file is the part that is specific to delivering those
slices as THINK-RED-GREEN-REFACTOR cycles.

`slice-plan` is a **hard dependency** of this skill — it is installed wherever this skill is, and
there is no bundled copy of its doctrine here. If it is genuinely absent, stop and say so rather
than slicing from memory; a decomposition invented on the spot is the failure mode this skill
exists to prevent.

## Cycle count is the extra sizing signal

Apply the sizing test in `slicing.md`, then add one criterion of this flow's own:

- **A PR is typically 1–5 cycles** — one behavior, one test, one cycle each. More than that is a
  signal, not a hard limit.

The signal is worth taking seriously because it is the earliest one available: a cycle list you
cannot enumerate at THINK is the same problem, seen sooner, as a diff a reviewer cannot hold in
mind at review. It only ever argues for a *smaller* PR — a cycle list is this flow's own
overhead, never a reason to widen one.

## The first PR, seen from the test side

Over new ground, outside-in TDD starts with an end-to-end test over stubbed internals. That
lands you on exactly the slice `slicing.md` calls a steel thread, arrived at from the test side
rather than the architecture side — the E2E test *is* what forces every seam to be real while
everything behind them stays trivial. Where the integration path already exists, `slicing.md`'s
carve-out applies and the first PR is simply the thinnest behavior.

Two things this flow owes that slice:

- **Record the merge-safety disposition in the PR Plan's `Merge safety` field.** Live thread (the
  narrowest genuinely working path) or inert thread (entry point unregistered, route not mounted,
  or flag-gated) — decide at planning time, and reuse it verbatim in the PR description at SHIP.
- **Let the stubs drive the sequence.** Every subsequent PR replaces a stub with real behavior,
  which is itself an observable change. That is why outside-in naturally produces PR-shaped work:
  the cycles of PR *n+1* have a spine to hang on rather than a green field.

## Re-slicing, in cycle terms

`slicing.md` has the general treatment. What is specific here:

- **A re-sliced PR needs its own `Merge safety`.** If a split or reorder produces a PR whose
  stubs stay flag-gated or unmounted, set the field on it then. The instruction above is scoped
  to PR 01; every *other* PR that ships something unreachable needs the field too, whether it was
  planned that way or became so in a re-slice.
- **What you learn in a cycle** is the input. A cycle that turns out to need a design the plan
  didn't anticipate is the usual way a planned PR reveals itself as two.
- **After the first PR ships, walk the remaining plan once** against what the thread found — the
  highest-yield replanning moment in the feature, and every PR behind it was drawn before those
  findings existed. Re-read `slicing.md` for that pass.
- **Discovering the current PR is too big mid-flight** — stop adding cycles to it, ship what is
  green and coherent now, and move the remainder to a new PR immediately after it in the plan.
  Never keep extending a PR because the plan said it was one item.
