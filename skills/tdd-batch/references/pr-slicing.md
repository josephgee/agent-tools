# PR Slicing

How to decompose a feature into an ordered sequence of PRs. Read this when building the PR plan
during Preflight, and again whenever the plan needs re-slicing mid-feature.

A **PR** here means one independently reviewable change: a diff a reviewer can read start to
finish, understand, and approve without needing the rest of the feature in front of them. If the
project has no forge, it still means the same thing — the unit of review doesn't depend on the
tooling.

**In this flow the slice is load-bearing beyond review.** The PR's one-sentence behavior sizes
the test batch; the batch fences the implementation; and the slice bounds the cost of a design
insight that arrives late, since starting fresh throws away at most one PR's implementation. A
PR sliced too large produces a batch too large to hold, a fence too loose to constrain, and a
late insight that costs real work. Get this right and the rest of the flow is cheap.

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
- a worked example (CSV export), and how and when to re-slice.

It says **slice** where this skill says **PR**: the same unit, one independently reviewable
increment of observable behavior. It is deliberately strategy-neutral — it says nothing about
tests, batches or phases. The rest of this file is the part specific to delivering those slices
as batched THINK → MAKE ROOM → RED → GREEN → REVIEW passes.

`slice-plan` is a **hard dependency** of this skill — it is installed wherever this skill is, and
there is no bundled copy of its doctrine here. If it is genuinely absent, stop and say so rather
than slicing from memory; a decomposition invented on the spot is the failure mode this flow is
least able to absorb, because the batch inherits every sizing error the slice makes.

## Batch size is the extra sizing signal

Apply the sizing test in `slicing.md`, then add one criterion of this flow's own:

- **Its batch is typically 2–6 behaviors** — one test each. More than that is a signal, not a
  hard limit: a batch you cannot hold in mind while implementing is the same problem as a PR a
  reviewer cannot hold in mind while reading.

`slicing.md`'s "when in doubt, split" applies here with one addition: an oversized PR also means
a batch that stops fencing anything.

In `slicing.md`'s worked example, PR 1 ("export endpoint returns an empty CSV") would carry a
batch of *endpoint responds 200; content-type is text/csv; body is the header row only.* That is
the shape to aim for: three or four one-line behaviors under one behavior sentence.

## Refactor PRs, against MAKE ROOM

`slicing.md` says to try once to attach a restructuring to a behavioral change before planning a
`refactor` or `scaffolding` slice of its own. In this flow that attempt has a named home: **MAKE
ROOM already absorbs small preparatory restructuring into the pass that needs it.** A `refactor`
PR is for what MAKE ROOM would swamp, not for anything a pass could carry.

## Inert first PR vs RED's raising skeleton

The first PR's merge-safety choice — live thread or inert thread — is covered in `slicing.md`.
What matters here is not confusing it with a device of the inner loop.

**RED's raising skeleton is a within-pass device**: raising stubs exist so the batch fails on
assertions rather than imports, and they are replaced during GREEN of that same pass. An **inert
first PR** is a shipping decision about reachability, recorded in the state file and stated in the
PR description. A PR whose raising stubs are still reachable at SHIP is not shippable — make it
inert or make it real.

## Batch creep

The intra-pass form of `slicing.md`'s "slicing to suit a strategy", which only this flow can
have:

- **Batch creep.** Discovering more behaviors at THINK and widening the PR to fit them. The batch
  is sized by the slice, never the reverse — split the plan instead.

## Re-slicing, in pass terms

`slicing.md` has the general treatment. What is specific here:

- **What you learn in a pass** is the input. A pass that turns out to need a design the plan
  didn't anticipate is the usual way a planned PR reveals itself as two.
- **At the end of REVIEW after PR 01, walk the remaining plan once** against what PR 01 actually
  found — the highest-yield replanning moment in the feature, since every PR behind it was drawn
  before those findings existed. `../../slice-plan/references/slicing.md` is the doctrine for
  that pass; SKILL.md's REVIEW is authoritative on when it runs and what it must write.
- **Discovering the current PR is too big — at THINK**, when enumerating behaviors: split the
  plan before writing the batch. This is the cheapest moment and the one the flow is designed to
  catch it in.
- **Discovering it mid-GREEN**: the in-scope discovery goes through the amendment protocol only
  if it serves the PR's one sentence. If it doesn't, it is the next PR — backlog it and keep the
  fence. Never keep extending a batch because the plan said it was one item.
