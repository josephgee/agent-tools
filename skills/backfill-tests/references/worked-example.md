# Worked example: un-comment the body before the conditional

This walks one small function all the way through the cycle, to make the central
move concrete: **when a test targets a single case, you can restore the guarded
body unconditionally first — as a bare default, with its guard still commented out
— and let a later contrasting test force the guard back in.** Language is Python;
the mechanic is identical everywhere.

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

Comment out the whole body; leave a placeholder so it still compiles and only our
test fails:

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

**RED.** Start with the express case. A cheap express order should cost 25.0.
Expected value derived from intent (express rate is 25.0), *not* read off the code:

```python
def test_express_shipping():
    assert shipping_cost(Order(total=40, express=True)) == 25.0
```

Run → fails with `NotImplementedError`. Red for the right reason.

**RESTORE.** The smallest slice that makes *this* case pass is the `return 25.0` —
but restored as a **bare default**, with its `if order.express:` guard left
commented. One case doesn't need the branching yet, so we strip the guard off the
body and drop the placeholder:

```python
def shipping_cost(order):
    # if order.total >= 100:
    #     return 0.0
    # if order.express:
    return 25.0
    # return 7.5
```

Run → green. This is the core move: a guarded body brought back unconditionally.
Every order now returns 25.0 — which is wrong in general, but correct for the only
case under test, and a later test is what will force the guard back.

## Cycle 2 — a contrasting case forces the guard back in

**RED.** A cheap, non-express order should cost the standard 7.5 — but right now
every order returns 25.0.

```python
def test_standard_shipping():
    assert shipping_cost(Order(total=40, express=False)) == 7.5
```

Run → fails: got `25.0`, expected `7.5`. This is the forcing function — the new
case can't pass unless the express body stops being the default.

**RESTORE.** Un-comment the `if order.express:` guard (re-indenting the `25.0`
return back under it) and the `return 7.5` default beneath it:

```python
def shipping_cost(order):
    # if order.total >= 100:
    #     return 0.0
    if order.express:
        return 25.0
    return 7.5
```

Run → both tests green. The `express` branch came back *because a test demanded
it*, not on speculation.

## Cycle 3 — the free-shipping threshold

**RED.** Large orders ship free. The case is chosen so the *free* rule must win
even when express is also true — that pins the *ordering* of the guards, not just
the top guard's existence:

```python
def test_free_shipping_over_threshold():
    assert shipping_cost(Order(total=150, express=True)) == 0.0
```

Run → fails: got `25.0` (express branch), expected `0.0`.

**RESTORE.** Un-comment the top guard:

```python
def shipping_cost(order):
    if order.total >= 100:
        return 0.0
    if order.express:
        return 25.0
    return 7.5
```

Run → all three green.

## Finish

Nothing is left commented. Diff against the original: **byte-for-byte identical.**
That's the proof we built a net rather than a new function. Three tests now pin the
three paths, and the guard ordering (free beats express) is locked by the cycle-3
case. We can change the thresholds now and the suite will catch a mistake.

## If cycle 3 had revealed a bug instead

Suppose the intended rule was "express is always 25.0, even over the free
threshold," but the code returns `0.0` for a large express order. Your cycle-3
specification test asserts the *intended* `25.0`, restoring the top guard leaves it
red (the code prioritises free shipping), and you've found a bug. You don't fix it
here. You mark the test expected-to-fail with a reason, restore the (buggy) original
guard so behavior is unchanged, log it in the ledger, and carry on. The fix is a
separate, user-gated step once the net exists.

```python
@pytest.mark.xfail(reason="bug: free-shipping threshold overrides express rate; should be 25.0")
def test_express_still_charged_over_threshold():
    assert shipping_cost(Order(total=150, express=True)) == 25.0
```
