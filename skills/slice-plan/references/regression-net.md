# Regression net

A plan's acceptance criteria say what the feature does. The **regression net** says what the
feature must not break, and it can't come from a spec: a spec is written before any design, and
"who else renders this?" is a fact about the code. The plan holds the design hypothesis, so the
net is drawn here and re-drawn whenever the touched code changes.

The failure this prevents: a PR adds a dependency to a shared unit, such as a hook that now needs a
context provider. Its tests set up that dependency because the author believes it is always there,
and a consumer where it isn't breaks in production. Tests written by the author encode the
author's belief, and the belief is the bug.

## The trace

For every component, hook, context, route or shared function the design touches:

1. **List every place it is used.** Search for imports and call sites, not just the ones you know
   about, and follow them up to every route, page and role that reaches the unit.
2. **For each place, check that everything the unit depends on is present there**: the providers
   and contexts mounted above it, the routes it runs under, the data and permissions it gets. A
   dependency the design *adds* is the one to check everywhere.
3. **Read the history of the touched code** (`git log` on its files) for fixes and reverts. An
   earlier fix that a redo or refactor could silently undo is a criterion too.

Each consumer the change could break, and each earlier fix it could undo, becomes one net entry. A
consumer the change can't reach (no dependency of it changes) is not an entry.

## An entry

- **Pin behaviour, not look.** "An admin viewing a seller's account sees the plan card as today", not
  how it looks. Look can be legitimately in flux, for example during pending design-system work.
- **Name who observes it and where**, as an acceptance criterion does.
- **Proof level.** Would a unit test have to restate the assumption at risk? If so (provider and
  context wiring, routing, what is mounted where), the proof is `e2e`. If not (a shared unit's own
  logic), it's `unit`. A unit test whose render helper adds the provider proves nothing about a
  page that doesn't.
- **Owner.** The first PR that touches the consumer. The entry must exist, proven red, before that
  PR's code.

## Proven red

An entry counts only after its spec has failed for the right reason: against known-bad code where
there is some (the reverted change, the fix being protected), otherwise against a deliberate break
of exactly the dependency at risk, such as removing the provider or reverting the fix. A spec
that stays green under the break is not a net. Revert the break before going on.

Whether an `e2e` spec joins the permanent suite is a per-spec decision with the user, with no
default either way. An e2e spec is cheap to run for validation and costly to keep. One the user
does not keep stays untracked beside the plan, so it survives branch switches and squashes, and
is still run at every check.

## Re-trace

The net goes stale whenever the code being changed does, including a dependency added inside a
unit already in the set. Re-trace at every design and **at every change after review**: a
reviewer's comment produced the incident above. Re-tracing is unconditional, because a rule about
when it is needed is the place it gets skipped.
