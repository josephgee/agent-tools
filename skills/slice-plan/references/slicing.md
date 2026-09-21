# Slicing

How to decompose a feature into an ordered sequence of slices. Read this in full when building
the plan, and again whenever the plan needs re-slicing mid-feature.

A **slice** is one independently reviewable change: a diff a reviewer can read start to finish,
understand, and approve without needing the rest of the feature in front of them. It normally
ships as one PR; if the project has no forge, it still means the same thing — the unit of review
doesn't depend on the tooling.

Slicing is decided before a strategy is chosen, and it does not change when the strategy does.
A slice executed by hand, by an agent one-shotting it, or by a test-first loop is the same slice:
the same behavior sentence, the same boundary, the same reviewer reading the same diff.

## The rule

**Every slice changes observable product behavior.** Something a user or a consumer of the system
can see is different after it merges. That is what makes it reviewable: a reviewer can ask "does
this do the right thing?" rather than "is this plausible groundwork for something I can't see?"

Trivial is fine. "The endpoint exists and returns an empty list" is a legitimate slice. "The
validator rejects empty names, nothing else" is a legitimate slice. The instinct is to bundle
these into something that feels substantial — resist it. Small and obviously correct beats large
and plausibly correct.

Refactor-only and scaffolding-only slices are the exception, not a peer option. Before planning
one, try once to attach it to a behavioral change instead. If it genuinely stands alone — a large
restructuring that would swamp the behavior riding on it — plan it, but record it in the plan as
a `refactor` or `scaffolding` slice, with a one-sentence reason.

## Sizing test

A slice is the right size when all of these hold:

- Its behavior states in **one sentence with no "and"**.
- A reviewer reads the whole diff in one sitting without needing a map.
- It needs no "here's the plan" preamble to be reviewable. If you'd have to explain the shape of
  the feature for the diff to make sense, it's too big or it's in the wrong order.
- Whoever executes it can finish it without designing a *multi-step approach* of their own. A
  slice that needs its own internal design plan is two slices. A strategy's own routine — a TDD
  flow enumerating the behaviors it will test, say — is that strategy's overhead, not evidence
  the slice is two.

When in doubt, split. The cost of one slice too many is a few minutes; the cost of one slice too
large is a review that doesn't actually happen.

## Splitting moves

When a slice is too big, these are the cuts that usually work:

- **Narrow the input range.** Handle one shape of input now, the rest later.
- **One case at a time.** One enum variant, one provider, one file format.
- **Happy path first.** Errors, validation, and edge cases become their own slices.
- **One consumer first.** Wire it up for a single caller before generalising.
- **One field before the whole form.** Partial surface area is a real behavior change.
- **Read before write.** Retrieval usually ships independently of mutation.

These all narrow what a slice does. A steel thread is already as narrow as behavior gets, so it
splits differently — see [The thread splits under you](#the-thread-splits-under-you).

## The first slice: steel thread

When a feature crosses ground that doesn't exist yet — a new endpoint, a new integration, a new
surface — slice 01 is a **steel thread**: one complete path through every component the feature
touches, doing the least possible at each. Request arrives, routes, hits the handler, touches
storage, renders, returns. Every seam is real; everything behind the seams is trivial.

The same first slice is called a **walking skeleton** (Cockburn), which names the other half of
it: every architectural component is present, however vestigial. Thread emphasises the path,
skeleton emphasises the parts. They are the same slice seen from two angles.

It goes first because the integration is where the unknowns live. The auth middleware that eats
your content-type header, the serializer the queue needs, the route the deploy doesn't pick up —
these surface while there is nothing built on top to unwind. A feature sliced without a thread
finds them in slice 04, with three slices of work resting on the wrong shape.

**Keep it embarrassingly thin.** One route, one record, one hardcoded value. The thread's job is
to prove the seams connect, and every bit of real behavior in it is behavior whose design you
committed to before learning anything.

**When the ground already exists** — adding a feature to a mature system where the integration
path is proven — slice 01 is simply the thinnest behavior. There is no thread to pull; the
seams are already connected and already exercised.

### The thread splits under you

Expect this. Slice 01 is planned with less knowledge than any other slice in the feature, because
it is the slice whose job is to acquire that knowledge — the unknowns it exists to surface are
surfacing *while you write it*. Finding mid-write that the thread is too big is the thread
working, not the plan failing, and it is the cheapest such discovery you will get: nothing is
built on top yet.

Split a thread at a **seam**, not at a behavior. The splitting moves above all narrow what a
slice does, and a thread already does almost nothing — there is nothing left to narrow. Instead
run the path as far as the last seam you can cross cheaply, and stop there:

> Thread planned as request → handler → store → response. The store turns out to need a
> migration and a connection pool. Slice 01 becomes request → handler → hardcoded response;
> crossing into the store becomes slice 02.

The stopping point becomes a stub behind a real interface, and the next slice crosses that one
seam. The path is shorter but still runs end to end — a thread that stops at a seam is still a
thread. A set of components with no path through them is not.

### Merge safety

A thread is a stubbed flow, and a stubbed flow can be unsafe to merge — it can expose a
half-working path to real users. Choose one of two dispositions for it and record which in the
plan:

- **Live thread** — the narrowest genuinely working path. Trivial output is fine; an empty list
  and a correct content type is a real answer. Preferred whenever the code reaches users on
  merge.
- **Inert thread** — the same structure, kept unreachable: entry point unregistered, route not
  mounted, or gated behind an off-by-default flag. Choose this when no real path is thin enough
  to be honest, and record in the plan exactly what makes it inert.

### A thread's test must survive being thickened

The thread is pinned by a test, and every later slice exists to make that thread do more. So
**the thread's test asserts only what the thread itself guarantees — the seam, not the content.**
"the response is CSV with a header row" survives rows arriving later; "the response is exactly
this header and nothing else" does not, and slice 02 breaks it on its first green.

This matters beyond tidiness. A test-first flow forbids leaving the suite red *and* forbids
changing a test to get green, so a broken inherited test can deadlock it between its own rules.
Over-specify the thread and you hand the next slice an unwinnable position.

When a later slice genuinely does invalidate an earlier slice's test — the behavior it pinned was
provisional and the plan always meant to replace it — that is a **plan-level event, not a test
being weakened to pass**. Make the update a deliberate change of its own, *before* the work that
invalidates it, so nothing is ever built over a red suite. And change the **fixture** rather than
the expectation wherever you can: an earlier test edited down to agree with the new behavior stops
pinning its own slice's rule and starts double-pinning the new one under its old name — green, two
tests failing for the same cause, and nothing left asserting what the earlier slice promised.
Record that you did it, wherever your flow records slice-level decisions.

Every subsequent slice thickens the thread at one point — replacing a stub with real behavior,
which is itself an observable change. That is why vertical slicing works downstream: there is a
spine to hang behavior on, and each slice is one honest increment along it rather than a new
excavation. It is also the rollback floor — an abandoned attempt on slice 02 restores to the
thread, which is a known-good end-to-end state rather than a green field.

## Anti-patterns

- **Horizontal layers.** "All the models," then "all the controllers." Each slice is unreviewable
  alone because nothing it does is observable. Slice vertically instead.
- **Wiring-only slices.** Plumbing with no behavior at either end.
- **Red at the boundary.** A slice that leaves the suite failing is not shippable, whatever its
  size.
- **Deferred observability.** A slice whose behavior can only be seen once a *later* slice merges.
  If you can't describe what changes for a user now, it's in the wrong order.
- **Kitchen sink.** An unrelated fix or cleanup riding along "while I'm in here." It belongs in
  its own slice or the backlog.
- **Load-bearing skeleton.** A steel thread that grows into the full architecture before any
  real behavior lands. The thread is scaffolding to be thickened, not a foundation to be poured.
- **Slicing to suit a strategy.** Sizing a slice around what its executor would prefer to chew —
  a batch that wants more behaviors, a one-shot that wants the whole feature. The reviewer sets
  the size; the strategy takes what it is given, or the slice is re-sliced for everyone.

## Worked example

Feature: users can export a report as CSV.

1. **Export endpoint returns an empty CSV** — route exists, correct content type and headers, no
   rows. Thinnest real vertical slice: it genuinely works, it just has nothing to say yet.
2. **Export includes the report's rows** — real data, default column set, default ordering.
3. **Export respects the caller's date range** — one filter, the one every caller uses.
4. **Export rejects a range wider than the configured maximum** — first error path, one rule.
5. **Export streams rather than buffering** — recorded as a `refactor` slice; behavior is
   unchanged but the restructuring is too large to ride along with a behavioral slice, and the
   memory ceiling is the stated reason.

Each line is one sentence with no "and." Each merges on its own. A reviewer of slice 3 needs to
know nothing about slice 4.

## Re-slicing

The plan evolves the same way the design hypothesis does. What you learn while executing a slice
can reveal that a planned slice is two slices, that one is unnecessary, or that the order is
wrong.

- **After the thread ships, re-slice the rest.** The highest-yield replanning moment in the
  feature: the thread has just converted its biggest unknowns into facts, and every slice behind
  it was drawn before those facts existed. Walk the remaining plan once against what the thread
  found. A plan that survives slice 01 untouched is more often unexamined than correct.
- **Splitting a planned slice in two** is minor — update the plan and proceed.
- **Dropping a planned slice, or reordering** shipped-relevant work surfaces to the user first,
  the same as any significant plan change.
- **Discovering the current slice is too big mid-flight** — stop extending it, ship what is green
  and coherent now, and move the remainder to a new slice immediately after it in the plan. A
  slice stays one item because a reviewer can read it, not because the plan said so.
