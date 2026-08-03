# PR Slicing

How to decompose a feature into an ordered sequence of PRs. Read this when building the PR plan
during Preflight, and again whenever the plan needs re-slicing mid-feature.

A **PR** here means one independently reviewable change: a diff a reviewer can read start to
finish, understand, and approve without needing the rest of the feature in front of them. If the
project has no forge, it still means the same thing — the unit of review doesn't depend on the
tooling.

## The rule

**Every PR changes observable product behavior.** Something a user or a consumer of the system
can see is different after it merges. That is what makes it reviewable: a reviewer can ask "does
this do the right thing?" rather than "is this plausible groundwork for something I can't see?"

Trivial is fine. "The endpoint exists and returns an empty list" is a legitimate PR. "The
validator rejects empty names, nothing else" is a legitimate PR. The instinct is to bundle these
into something that feels substantial — resist it. Small and obviously correct beats large and
plausibly correct.

Refactor-only and scaffolding-only PRs are the exception, not a peer option. Before planning one,
try once to attach it to a behavioral change instead. If it genuinely stands alone — a large
restructuring that would swamp the behavior riding on it — plan it, but label it in the plan as
`refactor` or `scaffolding` with a one-sentence reason.

## Sizing test

A PR is the right size when all of these hold:

- Its behavior states in **one sentence with no "and"**.
- A reviewer reads the whole diff in one sitting without needing a map.
- It needs no "here's the plan" preamble to be reviewable. If you'd have to explain the shape of
  the feature for the diff to make sense, it's too big or it's in the wrong order.
- It's typically 1–5 cycles. More than that is a signal, not a hard limit.

When in doubt, split. The cost of one PR too many is a few minutes; the cost of one PR too large
is a review that doesn't actually happen.

## Splitting moves

When a PR is too big, these are the cuts that usually work:

- **Narrow the input range.** Handle one shape of input now, the rest later.
- **One case at a time.** One enum variant, one provider, one file format.
- **Happy path first.** Errors, validation, and edge cases become their own PRs.
- **One consumer first.** Wire it up for a single caller before generalising.
- **One field before the whole form.** Partial surface area is a real behavior change.
- **Read before write.** Retrieval usually ships independently of mutation.

## The first PR and merge safety

Outside-in TDD starts with an end-to-end test, often over stubbed internals. That is still the
right place to start, but a stubbed flow can be unsafe to merge — it can expose a half-working
path to real users. Choose one of two forms for the first PR and record which in the state file:

- **Thinnest real vertical slice** — the narrowest genuinely working path through the whole
  feature. Preferred whenever the code reaches users on merge.
- **Inert skeleton** — the end-to-end structure with stubs underneath, kept unreachable: entry
  point unregistered, route not mounted, or gated behind an off-by-default flag. Choose this when
  no real path is thin enough to be honest, and say in the PR description exactly what makes it
  inert.

Every subsequent PR then replaces stubs with real behavior, which is itself an observable change —
the outside-in sequence naturally produces PR-shaped work.

## Anti-patterns

- **Horizontal layers.** "All the models," then "all the controllers." Each PR is unreviewable
  alone because nothing it does is observable. Slice vertically instead.
- **Wiring-only PRs.** Plumbing with no behavior at either end.
- **Red at the boundary.** A PR that leaves the suite failing is not shippable, whatever its size.
- **Deferred observability.** A PR whose behavior can only be seen once a *later* PR merges. If
  you can't describe what changes for a user now, it's in the wrong order.
- **Kitchen sink.** An unrelated fix or cleanup riding along "while I'm in here." It belongs in
  its own PR or the backlog.

## Worked example

Feature: users can export a report as CSV.

1. **Export endpoint returns an empty CSV** — route exists, correct content type and headers, no
   rows. Thinnest real vertical slice: it genuinely works, it just has nothing to say yet.
2. **Export includes the report's rows** — real data, default column set, default ordering.
3. **Export respects the caller's date range** — one filter, the one every caller uses.
4. **Export rejects a range wider than the configured maximum** — first error path, one rule.
5. **Export streams rather than buffering** — labelled `refactor`; behavior is unchanged but the
   restructuring is too large to ride along with a behavioral PR, and the memory ceiling is the
   stated reason.

Each line is one sentence with no "and." Each merges on its own. A reviewer of PR 3 needs to know
nothing about PR 4.

## Re-slicing

The PR plan evolves the same way the design hypothesis does. What you learn in a cycle can reveal
that a planned PR is two PRs, that one is unnecessary, or that the order is wrong.

- **Splitting a planned PR in two** is minor — update the plan and proceed.
- **Dropping a planned PR, or reordering** shipped-relevant work surfaces to the user first, the
  same as any significant plan change.
- **Discovering the current PR is too big mid-flight** — stop adding cycles to it, ship what is
  green and coherent now, and move the remainder to a new PR immediately after it in the plan.
  Never keep extending a PR because the plan said it was one item.
