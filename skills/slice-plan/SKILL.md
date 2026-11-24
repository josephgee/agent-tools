---
name: slice-plan
description: "Plans a feature as an ordered sequence of independently reviewable PRs — mostly vertical slices of deliverable behavior, the occasional refactor — with the dependencies between them, then stops at an agreed plan file without building anything. Use when asked to plan, scope, slice or break down a feature, bug fix or ticket before building it; to decide whether a feature should split into smaller features; or to turn a feature into independent tickets. Adopts a signed-off spec, or treats existing tickets as source material. Building the plan is a separate loop's job."
compatibility: "Requires git — the plan file is kept untracked via .git/info/exclude. Reads the codebase, and any ticket system the session has a tool for; writes to a ticket only on the user's yes for that edit."
---

# Slice Plan

Decide **what** gets built and in what reviewable pieces, then stop. The output is one agreed plan
file — feature, acceptance criteria, constraints, and an ordered list of PRs with their
dependencies — in the format of [plan-format.md](plan-format.md).

Terms used throughout:

- **Slice** — an end-to-end piece of deliverable functionality, possibly trivial.
- **PR** — one independently reviewable change: usually one slice, sometimes a refactor or
  scaffolding change kept separate because it reviews better alone.
- **Feature** — a small set of slices delivered together. Sized by a judgment of scope against
  value; a feature too big by that judgment splits into smaller features.

## Startup

Run `find plans docs/plans .plans -maxdepth 1 -name 'slices-*.md' 2>/dev/null`, keeping the
pattern quoted and judging by the output rather than the exit status: an unquoted
`plans/slices-*.md` matching nothing makes zsh print "no matches found" and never run `find`, and
a missing plans directory makes `find` exit non-zero even when it found a plan. If that finds
nothing, run `grep -rl "# Slice Plan" plans/ docs/plans/ .plans/ 2>/dev/null` — a renamed file is
still a plan. Never a plain ignore-aware search: the plan is in `.git/info/exclude`, so ripgrep
skips it silently.

Also look for specs: `find plans docs/plans .plans -maxdepth 1 -name 'spec-*.md' 2>/dev/null`. Only
a spec whose `Status` reads `signed off` is ready to plan; mention a `drafting` one, and ignore an
`adopted:` one.

- **A `drafting` plan** — the gate was never passed. Offer to resume it at the gate.
- **An `agreed` plan** — say so, and offer the next steps under *After the gate*. Changing its
  feature, criteria, constraints, net or PRs means setting it back to `drafting` and passing the gate
  again — if a `loop-<feature-slug>.md` ledger exists beside it, only on the user's yes: a build
  rests on it.
- **Nothing**, or the user wants something new — run the planning session, offering any ready spec
  as its input.

With more than one candidate, list them (feature, status, last updated) and ask.

## Planning session

### Inputs

- **A signed-off spec** — adopt it. Its Problem and Out of Scope become the Feature; its Acceptance
  Criteria are copied verbatim with their IDs and examples; its Constraints become the plan's.
  Present what was adopted for confirmation — don't re-interview. Name the spec in the plan's
  **Spec** field, and set **Design** to the spec's path if its design hypothesis is worth keeping
  in view. Never edit the spec, except its `Status` at the gate.
- **Existing tickets** — source material, not adopted verbatim: a ticket has not been through a
  sign-off that made its criteria observable. Derive the feature and criteria from it through steps
  1–2, record its ref on the PRs that serve it, and record every place the plan ends up disagreeing
  with it (*Differs from ticket*, in [plan-format.md](plan-format.md)). The plan wins locally. If a
  ticket is too vague or contested to sharpen in a few questions, suggest the `feature-spec` skill
  first, if the session has it.
- **Conversation** — steps 1–2 from scratch.

### 1. Feature definition

What is being built, why, for whom; what is explicitly out of scope. Sharpen a vague definition
before moving on — it produces vague criteria otherwise. Note any constraint mandated from outside
— compatibility, regulation, a contract — with who imposed it.

### 2. Acceptance criteria

Behavioral, specific, testable, scoped — they describe what the feature does from the outside, and
any valid implementation could satisfy them. **Each names who observes it and where** — an actor
at the system boundary, or a measurement taken from outside. One only a reader of the code could
observe ("add a `tz` column") is design: ask what breaks, for whom, without it — that answer is the
criterion. Present the list for confirmation.

### 3. PR sequence

Read [references/slicing.md](references/slicing.md) **in full** before drafting — the sizing test,
the steel thread that opens the sequence, the splitting moves, the anti-patterns. Do not draft from
memory. Read enough of the codebase to judge whether PR 01 must be a steel thread — marked
`Kind: thread` if so.
Fill each PR's fields per [plan-format.md](plan-format.md).

### 4. Regression net

Read [references/regression-net.md](references/regression-net.md) and run its trace over the code
the drafted PRs touch. Write each entry to the plan's Regression Net, and put its ID on the
**Net** line of the PR that owns it. A spec's `(regression)` criteria stay acceptance criteria;
the net covers what only the code shows. If the spec says other roles see the surface, trace their
pages first.

### 5. Split check

Run the check in [references/slicing.md](references/slicing.md), *When to split the feature*,
against the drafted list. If it suggests a split, propose the grouping with its reason and let the
user decide. On a split, follow *Splitting into child plans* in [plan-format.md](plan-format.md):
write the children instead of this plan, then take the one the user picks through the gate below.

### Write it down before the gate

Steps 1–5 exist only in the conversation otherwise, and a compaction loses them. Choose the plans
directory, create the plan file with `Status: drafting`, and exclude it from git — both per
[plan-format.md](plan-format.md).

### Alignment gate

Present the feature, criteria, constraints, the regression net with each entry's proof level and
owner, the PR sequence with its dependencies, every *Differs from ticket* line, and the proposed slug — permanent. If a spec was adopted and its `Status` does not
already read `adopted:` (an earlier child of the same split settled it), list its Deferred and
Assumptions entries too: the plan does not carry them, so ask where each goes — into the
Feature's out-of-scope sentence, onto a ticket (on a yes), or dropped. Ask: *"Are we
aligned?"*

- **Yes** — set `Status: agreed`, and set the adopted spec's `Status` to
  `adopted: <plan path>`, unless an earlier child already did, so Startup never offers it again.
- **Changes** — make them and re-present. A changed slug renames the file and its exclude line.
- **Declined outright** — retire the plan per [plan-format.md](plan-format.md), or Startup offers
  it next session.

## After the gate

Stop. Offer next steps, starting none:

- **Build it** — with a loop skill the session has (`slice-loop`, if installed), in this session or
  a fresh one; everything the loop needs is on disk.
- **Publish tickets** — only with a tool the session has for the tracker, and only on the user's
  yes for each write. What becomes a ticket — the feature, each child feature of a split, or each
  PR — is the user's call. Each carries its behavior, its criteria in full and its dependencies, so
  it stands alone. Once the user says the tickets have taken over, offer to retire the plan.
- **Stop here** — the plan stays on disk for later.
