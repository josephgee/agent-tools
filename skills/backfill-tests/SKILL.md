---
name: backfill-tests
description: "Backfill a trustworthy regression-test net onto existing but poorly-tested code, usually right before refactoring or changing it. Use when asked to add tests to, cover, pin, or characterize an untested or legacy function. Enforces the standards that separate a real net from coverage theatre: expected values derived from intent rather than read off the implementation, every test proven falsifiable by perturbing the code it claims to exercise, assertions on observable behavior rather than on which collaborators got called, and specification tests kept distinct from characterization pins. Bugs found along the way are captured as expected-to-fail tests and fixed later under the user's call, never inline. This is the inverse of writing new code test-first (see the tdd skill): here the implementation already exists and the tests are what's missing."
compatibility: Requires the project to be a git repository — the production-code freeze check and perturbation reverts rely on git.
---

# Backfill Tests

A function works well enough to ship but has little or no test coverage, and you're about to
change it. You want a net that will actually catch you.

The hard part is not writing tests — an agent can produce fifty green assertions against any
function in one pass. The hard part is that most of those assertions pin nothing. They were
derived from the code, so they cannot disagree with it; or they assert which mocks got called, so
they break during the very refactor they exist to protect. **A suite like that is worse than no
suite, because it buys confidence it hasn't earned.**

So this skill is a bar, not a procedure. Meet the bar however the code makes sensible.

## The bar

Every test you add must satisfy all five. They are checkable — check them.

1. **The expected value is derived independently of the implementation.** From the function's
   name and docstring, the spec, the ticket, its call sites, a hand-worked example, or your own
   understanding of the domain. Never by running the code and copying its output — the one
   exception is a labeled characterization test (see 4), whose expected value *is* the observed
   behavior. If a specification test's expected value has no source other than "that's what it
   returns," you have written a pin nobody can triage when it fires: red can't tell them whether
   a promise broke or an incidental changed.
2. **The test is falsifiable, and you have proved it.** See [Prove it can fail](#prove-it-can-fail).
   Untested tests are the default failure mode of backfilling.
3. **It asserts behavior, not wiring.** Return values, changed state, effects at a real boundary.
   Not call counts, argument spies, or invocation order.
4. **It is labeled specification or characterization.** A *specification* test asserts what the
   code **should** do — the default, and the only kind that can find a bug. A *characterization*
   test pins what the code **actually** does because its intent is genuinely unrecoverable; it
   asserts stability, never correctness, and it can happily enshrine a bug. Mark those in the test,
   and make the label carry **why** intent was unrecoverable — `# characterization: nothing in the
   spec or the call sites explains the 0.0037 adjustment; locks current behavior, not verified
   correct`, never a bare `# characterization`. If you can't write that reason, you haven't earned
   the exception in item 1 — go back and derive the value. List them all at the end.
5. **It pins one behavior and is named for it.** `charges_express_rate`, not `test_case_2`.

Keep the suite FIRST as it grows — Fast, Independent, Repeatable, Self-validating — and refactor
the tests freely; they are new code and are not frozen.

### On mocks

A tangled legacy function is easiest to "cover" by mocking every collaborator and asserting the
call sequence. That produces wiring tests, which break under refactoring even when behavior is
unchanged — cries of wolf during exactly the change the net was built for.

Use real objects wherever practical. Reach for a mock only at a genuine system boundary — network,
database, filesystem, clock, third-party service — or when the real collaborator is too slow for
the suite to run often, and mock it *at* that boundary, never inside your own logic. If the
function can't be tested without mocking its internals, that is a finding: it names the seam the
coming refactor should address. Record it and write the simplest test you can manage.

## Setup

1. **Confirm the working tree is clean** and note the current commit sha. Production code stays
   frozen through this work (see [Freeze the production code](#freeze-the-production-code)) and a
   clean tree is what makes that checkable. If the tree is dirty, have the user commit or stash
   before starting.
2. **Identify the test runner and get the full suite green** as a baseline — `pytest`, `npm test`,
   `go test ./...`, `cargo test`. Read `package.json` / `pyproject.toml` / equivalent if unsure. A
   red baseline means "green" proves nothing later; fix it or get the user's sign-off on the known
   failures first.
3. **Pick one target** — a function, method, or tight cluster, not a module. If it's huge, take its
   collaborators one at a time. This technique suits untested, branchy, or tangled code you're
   about to change. It does not suit code that doesn't exist yet (use [tdd](../tdd/SKILL.md)) or
   code trivial enough that the ceremony costs more than it returns.

## Write down the promises first

Before reading the body closely, reconstruct what the function *promises* from everything except
its implementation: name, signature, docstring, call sites, existing tests, commit message, ticket.
Write that list down. It is where your expected values come from, and gathering it first is what
stops the implementation from anchoring them.

Then read the body and extend the list with the cases it reveals — branches, loops, early returns,
error paths, precedence between rules — but keep the two sources distinct in your head. A branch
you find in the code tells you a case *exists*; it does not tell you what the right answer is.

Work the list roughly in this order, one test at a time: happy path, then each branch and early
return, then edges and error cases, then interactions between rules (which guard wins when two
apply — those pin ordering, which refactors break most often).

## Prove it can fail

**A green test proves nothing until you have seen it red.** After each test passes:

1. Perturb the production code the test claims to exercise — flip a comparison, change a constant,
   invert a condition, return the neighbouring branch's value.
2. Rerun **that test**. It must fail.
3. Revert the perturbation (`git checkout -- <path>`) and confirm the test is green again.

If it stays green through the perturbation, it is not pinning what you think — it is asserting
something incidental (a default, a shared fixture, a branch never reached by that input). Fix the
test, don't move on.

This is per-test and takes seconds. Do it every time; it is the step that separates this from
coverage theatre. If the project has mutation-testing tooling installed, a full run over the target
at the end is a stronger sweep and worth doing as well — but it does not replace the per-test check,
which is what tells you *which* test was toothless while you still remember why you wrote it.

## Check for blind spots, once

When the promises list is covered, make **one** pass to find what you *missed* — behavior in the
code that never reached your list at all. Branch coverage scoped to the target file is the cheapest
way to see it ([references/language-notes.md](references/language-notes.md) has the command per
ecosystem); re-reading the body against your ledger works too.

This is a single scan, not a loop, and it has **no target number.** Coverage measures execution,
not assertion — a line can be fully covered by a test that pins nothing about it — so a high
percentage is not evidence of a net. Only a *zero* carries information: nothing exercises this
branch at all.

For each unhit branch, pick one of three, and be genuinely willing to pick the last two:

- **Write a test** — it's real behavior you missed. Test the behavior, not the line.
- **Leave it, and say so** — reaching it would need the kind of internal mocking you'd otherwise
  refuse (see [On mocks](#on-mocks)), or it's a defensive branch, a log line, trivial delegation, or
  framework boilerplate. Report it under "what isn't pinned."
- **Flag it as possibly dead** — you can't construct any input that reaches it. That's a finding to
  surface, not a puzzle to solve with a contorted test.

The question that settles it is never "is this line green." It is: **if the coming change breaks
this line, do I need the suite to tell me?** If no, leaving it unpinned is the correct outcome, not
a shortfall. A test written to turn a line green is worse than the gap it fills — it costs
maintenance, couples the suite to internals, and it is the first thing that will break during the
very refactor this net was built for.

## Freeze the production code

**Do not refactor, rename, tidy, or fix the target while backfilling.** The net's whole claim is
that it pins behavior that already exists; code changed during the pass is unpinned, and it
conflates two jobs. Cleanup is the *downstream* work this net exists to make safe.

The one sanctioned exception is the temporary perturbation in
[Prove it can fail](#prove-it-can-fail) — make it, watch the test go red, revert it before writing
the next test. Nothing else touches the target.

The invariant is checkable, so check it before you finish: `git diff <sha>` shows **test files
only**. Any production hunk is either an un-reverted perturbation or a change you didn't mean to
make — investigate it.

## When a test finds a bug

Sometimes a specification test you're confident in stays red because the original code is wrong.
**Do not fix it inline.** Instead:

- Keep the test asserting the **correct** behavior.
- Mark it expected-to-fail with a one-line reason naming the wrong behavior. Prefer xfail over a
  plain skip where the framework has one — an xfail that starts *passing* tells you the bug got
  fixed. Markers per framework: [references/language-notes.md](references/language-notes.md).
- Leave the buggy behavior in place, log it in the ledger, and carry on.

## Track it lightly

A running ledger in the conversation is enough (a scratch note if the target is large). No state
file. Track: behaviors pinned; behaviors still uncovered; bugs found (the xfail tests); findings —
awkward-to-test seams, suspected dead code, characterization-only pins. Report it at check-ins so
the user can redirect.

## Finish

Done when the promises list is covered, the blind-spot scan is done and every remaining gap is a
deliberate one you can name, the suite is green (xfailed bug tests aside), and `git diff` shows
tests only.

Present:
- **What's pinned** — the behaviors now covered.
- **What isn't** — behavior left unpinned on purpose, and why. This is a real part of the
  deliverable, not an apology: it tells the user exactly where the net has holes before they lean
  on it.
- **Bugs found** — each xfail test and its reason.
- **Findings** — untestable seams, suspected dead code, characterization-only pins.

**Fixing the bugs is a separate, user-gated step.** For each xfail, the user decides: fix now
(un-skip it, make it pass — a small red-green change, safe now that the net exists) or defer it as
documented, tracked work. Don't roll into fixes unprompted; the deliverable here is the net, not
the repairs. Afterwards the refactor can begin, held green by these tests — and *that* is where
production cleanup belongs. [tdd](../tdd/SKILL.md)'s refactor guidance applies to that pass.

## Escalation: gut-and-restore

There is a heavier technique — comment the body out entirely and un-comment it slice by slice, each
slice earned by a failing test — that makes falsifiability structural rather than checked. It is
described in [references/gut-and-restore.md](references/gut-and-restore.md).

**Use it only when both hold:** the perturbation check can't give you a clear answer — the function
is tangled enough (deep nesting, mutation through shared state, overlapping guards) that you can't
tell which lines a given test exercises, so you don't know what to perturb or how to read the result
— *and* the code is critical enough that a structural guarantee is worth the price. Otherwise don't:
it edits the user's production code as its core move, costs an order of magnitude more, and leaves
the file damaged if the pass is abandoned partway. The loop above is the path; this is the exception.
