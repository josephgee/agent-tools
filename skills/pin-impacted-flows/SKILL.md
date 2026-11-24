---
name: pin-impacted-flows
description: "Finds the flows a code change could break outside its own feature (other pages, roles and routes that use the same component, hook, context or shared function, and earlier fixes the change could undo), then pins each one with an acceptance proof of how it behaves today, proven to fail against a deliberate break. Use before or after changing shared code, when asked what a change could break, its blast radius, impacted flows, or regression risk, when re-checking a PR after review changes, or when a build loop asks for a regression net. Works on a diff, a branch, a PR, or a design's list of touched code. Not for pinning a unit's own logic with unit tests: that is test backfill."
compatibility: "Requires git. Agent-run proofs need a way to drive the system the way a user meets it (a browser driver, an API client, a CLI); without one, every proof is run by the user, which is slower but valid."
---

# Pin Impacted Flows

A change's own tests encode its author's beliefs about where the changed code runs. When the belief
is wrong, those tests pass and another flow breaks in production. The standing example: a PR adds a
plan check inside a shared hook that needs a context provider, and its tests mount that provider
because the author believes it is always there. A superadmin page renders the same card outside the
provider and throws.

This skill checks the belief instead of trusting it. It **traces** who else the change reaches, and
**lays** a net: one acceptance proof per impacted flow, pinning how that flow behaves today.

## Modes

The caller names one; standalone, ask, recommending `lay`.

- **`trace`**: read-only. Input is a diff (`git diff <base>...<branch>`, or a PR's), or a list of
  the code a design will touch. Output is the entry list (*Report*). Change nothing in the tree.
- **`lay`**: trace if no entries were given, then write and prove a proof for each entry (*Laying*).
  Needs a clean tree, with nothing else running in it.

Given an existing net (a list of entries with their proofs), both modes also say which existing
entries the change reaches.

## The trace

For every component, hook, context, route or shared function the change touches:

1. **List every place it is used.** Search for imports and call sites, not just the ones you know
   about, and follow them up to every route, page and role that reaches the unit.
2. **For each place, check that everything the unit depends on is present there**: the providers
   and contexts mounted above it, the routes it runs under, the data and permissions it gets. A
   dependency the change *adds* is the one to check everywhere, including inside a unit already
   known to be touched.
3. **Read the history of the touched code** (`git log` on its files) for fixes and reverts. An
   earlier fix the change could silently undo is an entry too.

Each consumer the change could break, and each earlier fix it could undo, becomes one entry. A
consumer that no changed dependency reaches is not one. If the risk is in a shared unit's own logic
rather than in what surrounds it, it isn't this skill's entry: say so in the report, as unit-test
backfill.

## An entry

An entry is an acceptance test for a flow the change is not meant to alter.

- **Behaviour, not look:** "An admin viewing a seller's account sees the plan card as today", not
  how the card looks. Look can be legitimately in flux, for example during design-system work.
- **Observer and place:** who sees it, and where.
- **At risk:** the dependency or earlier fix the change could break.
- **Human proof, first:** exact steps a person runs and exactly what they see. This is the test,
  and nothing below may shrink it.
- **Agent proof, where it can be done without weakening the human proof:** the same steps,
  scripted. If it can't, leave the agent side blank. Never substitute an easier check that proves
  something narrower: a 200 response standing in for "the admin sees the card" is the substitution
  to refuse. Mark each agent proof `read-only`, or `mutating` if it writes to a real system.

## Laying

For each entry, on the branch where it will run:

1. **Write its proofs, then run them on the code as it stands.** If the change hasn't landed yet,
   they pass. If it has and a proof fails, the change already breaks that flow. Report it as a
   found regression and don't lay over it.
2. **Prove it red.** Break exactly the dependency at risk (remove the provider, revert the earlier
   fix), run the proof, and check that it fails *because of that break* and not for some other
   reason. Then `git restore` the break and run it green again. A proof with no agent side is run
   by the user, or by you driving the system by hand. A proof that stays green under the break is
   rewritten, not kept.
3. **Ask the user, per agent proof, whether it joins the permanent suite.** There is no default.
   Automated acceptance tests catch real breaks and cost upkeep: environment-specific, slow, often
   fragile. A kept proof is committed on the branch. Otherwise, leave it where its runner finds it,
   append its path to `"$(git rev-parse --git-path info/exclude)"`, and confirm with
   `git check-ignore -q <path>`, so a later `git add -A` doesn't sweep it in.

**Re-running the net later:** run every `read-only` agent proof on every check. A human-only or
`mutating` proof is re-run only when a trace says the change reaches its dependency, since each
run costs the user's time. The trace itself is never skipped.

## In a subagent

A caller may run this skill in a subagent to keep the trace's reading out of its own context. The
caller names the repository's absolute path as your working directory. You cannot talk to the user
there, so **ask nothing**:

- Do everything that needs no one: the trace, writing the proofs, and proving every agent proof
  red.
- Leave every proof untracked and excluded (*Laying* step 3, the not-kept branch). Keeping one is
  the user's call, made through the caller.
- Return the report with a **Needs the user** section: each agent proof awaiting the keep decision,
  and each human-only proof with its steps, the exact break to apply, and what failing looks like.
  The tree is left clean, with every break restored.

The caller then works through that list with the user, applying and restoring each break itself,
and commits each proof the user keeps, deleting its exclude line.

## Report

```markdown
## Impacted flows — <what was traced: diff range, PR, or design>

### Entries
- R<n> — <observer> <behaviour> as today, at <place>
  - at risk: <dependency or earlier fix>
  - human: <steps → what they see>
  - agent: <command or path, read-only | mutating> | none
  - laid: committed | untracked: <path> — red against: <the break>   (lay only)

### Existing entries reached
<entry IDs whose dependency this change touches, or none>

### Found regressions
<a flow already broken by the change, with the failing proof, or none>

### Needs the user   (subagent only)
<agent proofs awaiting the keep decision; human-only proofs: steps, the break to apply, the failure to expect>

### Out of scope
<risks in a unit's own logic: unit-test backfill, not this net>
```

The caller records the report wherever it keeps state. Standalone, offer to save it beside the
branch's other notes, and list every untracked proof path so the user can delete it once the
change has merged.
