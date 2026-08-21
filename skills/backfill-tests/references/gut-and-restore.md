# Escalation: gut-and-restore

A heavier alternative to the main loop's write-a-test-then-perturb cycle. Instead of *checking*
that each test could fail, you make it structurally impossible for it to have passed for free:
comment the function's body out entirely, then un-comment it slice by slice, each slice earned by a
test that was red before it.

## Before starting

The gate lives in the main skill, and both of its conditions must already hold: the perturbation
check can't give a clear answer — the function too tangled (deep nesting, mutation through shared
state, overlapping guards) to tell which lines a given test exercises, so there's nothing obvious to
perturb — *and* the code critical enough to justify the price below. If you're here without both, go
back and run the main loop.

Know the price you're paying. This technique edits the user's production code as its core move, on
code they said they don't trust themselves to break; it costs roughly an order of magnitude more;
and an abandoned pass leaves the file half-gutted. Those are real prices, paid for a guarantee the
cheap perturbation check mostly already buys.

Say so before starting — the user should know their source file is about to be temporarily
dismantled.

## The mechanic

**Gut it.** Comment out the entire body, signature intact. Keep the commented lines *in place* —
they are your source of truth and you'll un-comment them progressively, so they are not deletable
clutter. Add a minimal placeholder so the file still parses and type-checks and the only thing
failing is your test:

| Language    | Placeholder                                  |
|-------------|----------------------------------------------|
| Python      | `raise NotImplementedError`                  |
| JS/TS       | `throw new Error("gutted");`                 |
| Go          | `panic("gutted")`                            |
| Rust        | `unimplemented!()` or `todo!()`              |
| Java/Kotlin | `throw new UnsupportedOperationException();` |
| Ruby        | `raise NotImplementedError`                  |
| C#          | `throw new NotImplementedException();`       |
| C/C++       | `abort();` (plus a dummy `return {};` if the type demands it) |

Run the suite. Existing tests touching the target now fail — expected; they come back as you
restore. If a *lot* of unrelated things break, the target has more reach than you thought:
reconsider scope.

**Then repeat RED → RESTORE, one case at a time:**

- **RED** — write exactly one test for one case, expected value derived independently as always.
  Confirm it fails *for the right reason* (missing behavior, not an import error or typo). If it
  passes without you restoring anything, it drove no progress — drop it unless it pins a genuinely
  distinct edge case.
- **RESTORE** — un-comment the **smallest slice of the original** that turns it green, ideally one
  line. Restore, don't rewrite. Where your test targets a single path, un-comment the *inner
  statement before its surrounding guard or loop* and let a later contrasting test force the guard
  back in — that is the core move, shown below. Drop the placeholder once real `return`s cover the
  paths under test. Rerun the full suite.

**If you had to *change* a restored line to get green, stop.** In rough order of likelihood: your
test targets a case that slice doesn't handle (restore a different slice, or pick a matching case);
your expected value is wrong (recheck the spec); or the original code is genuinely buggy (xfail it
per the main skill and restore the buggy line anyway). Editing commented-out original code to force
green is how this quietly becomes "reimplement the function," which defeats the whole point.

**Never edit a test to make it pass.** Fix a wrong test as a deliberate correction, not by weakening
the assertion.

**Statically-typed gotchas.** Some compilers won't accept a partially-restored block — Rust `match`
arms, Kotlin `when` exhaustiveness, switch exhaustiveness. Restore the minimal compiling unit and
let the tests drive *which values you assert* rather than which lines exist. If the placeholder
becomes unreachable after a restored `return`, the dead-code warning is your cue to delete it.

## Finishing

Nothing left commented: every original line either restored under a passing test, or flagged as
possible dead code (surface it — don't silently restore it to tidy the diff, and don't contort a
test to reach it). Then diff the function against the pre-gut commit. Before any bug fixes, the
body should be **identical** to the original; that diff is the proof you built a net rather than a
new function. Small formatting drift from re-indentation is worth fixing before you hand over, and
any *semantic* difference is an accidental rewrite — investigate it.

From there, the main skill's Finish applies unchanged.

---

# Worked example

One small function all the way through, to make the central move concrete: **when a test targets a
single case, restore the guarded body unconditionally first — as a bare default, with its guard
still commented — and let a later contrasting test force the guard back in.** Python here; the
mechanic is identical everywhere.

## The target

```python
def shipping_cost(order):
    if order.total >= 100:
        return 0.0
    if order.express:
        return 25.0
    return 7.5
```

No tests. We're about to change the thresholds, so we want each path pinned first.

## Gut it

```python
def shipping_cost(order):
    raise NotImplementedError  # gutted
    # if order.total >= 100:
    #     return 0.0
    # if order.express:
    #     return 25.0
    # return 7.5
```

## Cycle 1 — a guarded body, restored without its guard

**RED.** Start with the express case. A cheap express order should cost 25.0 — derived from intent
(express rate is 25.0), *not* read off the code:

```python
def test_express_shipping():
    assert shipping_cost(Order(total=40, express=True)) == 25.0
```

Run → fails with `NotImplementedError`. Red for the right reason.

**RESTORE.** The smallest slice that passes *this* case is `return 25.0` — restored as a **bare
default**, its `if order.express:` guard left commented, placeholder dropped:

```python
def shipping_cost(order):
    # if order.total >= 100:
    #     return 0.0
    # if order.express:
    return 25.0
    # return 7.5
```

Run → green. Every order now returns 25.0 — wrong in general, correct for the only case under test.

## Cycle 2 — a contrasting case forces the guard back in

**RED.** A cheap non-express order should cost the standard 7.5, but everything returns 25.0:

```python
def test_standard_shipping():
    assert shipping_cost(Order(total=40, express=False)) == 7.5
```

Run → fails: got `25.0`. That is the forcing function — this case can't pass while the express body
is the default.

**RESTORE.** Un-comment the guard (re-indenting the `25.0` return under it) and the default beneath:

```python
def shipping_cost(order):
    # if order.total >= 100:
    #     return 0.0
    if order.express:
        return 25.0
    return 7.5
```

Run → both green. The branch came back *because a test demanded it*.

## Cycle 3 — the free-shipping threshold

**RED.** Large orders ship free. Choose the case so *free* must win even when express is also true —
that pins the guards' **ordering**, not just the top guard's existence:

```python
def test_free_shipping_over_threshold():
    assert shipping_cost(Order(total=150, express=True)) == 0.0
```

Run → fails: got `25.0`. **RESTORE** the top guard → all three green, function whole, diff against
the original clean. Three tests pin three paths plus the precedence between two of them.

## If cycle 3 had revealed a bug instead

Suppose the intended rule was "express is always 25.0, even over the free threshold." Your cycle-3
specification test asserts `25.0`, restoring the top guard leaves it red, and you've found a bug.
Don't fix it here: mark it expected-to-fail with a reason, restore the buggy guard so behavior is
unchanged, log it, carry on. The fix is a separate, user-gated step once the net exists.

```python
@pytest.mark.xfail(reason="bug: free-shipping threshold overrides express rate; should be 25.0")
def test_express_still_charged_over_threshold():
    assert shipping_cost(Order(total=150, express=True)) == 25.0
```
