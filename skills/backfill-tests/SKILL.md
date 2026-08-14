---
name: backfill-tests
description: "Backfill a regression-test net onto existing but poorly-tested code by gutting a function and restoring it under test. Use when asked to add tests to, cover, pin, or safely characterize an untested or legacy function — especially before refactoring or changing it. The method: comment out the target's entire body, then repeatedly write ONE failing test for a single case and un-comment the smallest slice of the original code that makes it pass — restoring known-good logic verbatim rather than rewriting it — until every line is back under test. Bugs surfaced along the way are captured as skipped tests and fixed at the end. This is the inverse of writing new code test-first (see the tdd skill): here the implementation already exists and the tests are what's missing."
---

# Backfill Tests

You have a function that already works (well enough to ship) but has little or no test coverage. You want a test net around it — usually because you're about to change it and don't trust yourself not to break it silently.

The technique: **gut the function, then earn every line back under test.** Comment out the whole body. Now nothing works, and the only way to make any behavior return is to write a test that demands it and un-comment the code that provides it. Because you restore the *original* lines rather than writing new ones, each passing test pins behavior that already existed. When you reach the end, every line is back exactly as it was — now with tests wrapped around it.

This is deliberately the mirror image of the [tdd](../tdd/SKILL.md) skill. TDD writes a test for code that doesn't exist yet, then writes the code. Here the code exists and you write the missing tests, using commented-out code as the forcing function so you never write more test than you can immediately justify with a real, restored line.

## Why this isn't circular

The failure mode that makes this technique worthless: **reading the expected value off the implementation.** If you un-comment `return price * 1.2`, run it, see `120`, and write `assert total == 120`, you have tested nothing — the test can never disagree with the code, and it will "pass" even if the code is wrong.

Derive every expected value **independently** — from the spec, the ticket, the function's name and docstring, a hand-worked example, or your own understanding of what it's supposed to do. The restored line then either *agrees* (green — behavior confirmed and now pinned) or *disagrees* (you've found a bug — see Bug Discovery). The whole value of the technique lives in that possibility of disagreement. A test that cannot fail is not coverage.

Two kinds of test come out of this, and you should know which you're writing:

- **Specification test** — you know what the code *should* do; assert that. This is the default. Restoring the line confirms it or exposes a bug.
- **Characterization test** — you genuinely don't know the intended behavior (gnarly legacy math, an accreted edge case nobody remembers). Pin what the code *actually does* to lock it before refactoring, and label it as such in the test (e.g. a comment: `characterization — locks current behavior, not verified correct`). It asserts *stability*, never *correctness*.

Prefer specification tests. Fall back to characterization only for behavior whose intent you can't reconstruct — and flag those for a human, because a characterization test can happily enshrine a bug.

## Setup

1. **Preserve the original.** If the project uses git, confirm a clean working tree and commit (or note the current sha) first, so the pristine function is recoverable and you can diff against it at the end. If not on git, copy the target function verbatim into a scratch note before touching it. You must be able to prove, later, that what you restored is byte-for-byte what was there.
2. **Identify the test runner** and confirm the **full suite is green** as a baseline (`pytest`, `npm test`, `go test ./...`, `cargo test`, etc.). Read `package.json` / `pyproject.toml` / equivalent if unsure. A red baseline means you can't trust "green" later — get it green or get the user's sign-off on the known failures first.
3. **Pick the target** — **one** function or method (a tight cluster at most), not a whole module. This technique suits an untested, branchy, or tangled function you're about to refactor or extend; it does not suit brand-new code that doesn't exist yet (use [tdd](../tdd/SKILL.md) for that), or a function trivial enough that the ceremony costs more than it returns. If the target is huge, cover its collaborators one at a time rather than gutting everything at once. Skim it and note the distinct paths through it (branches, loops, early returns, error cases) — that's your rough menu of cases to cover; you don't need it complete, just enough to start.

## Gut the target

Comment out the **entire body**, leaving the signature intact. Keep the commented lines *in place* — you will un-comment them progressively, so they are your source of truth, not deletable clutter.

Leave a minimal placeholder so the file still compiles and the *only* thing failing is your test — not the parser. Use whatever is idiomatic for a not-yet-implemented function in the language: `raise NotImplementedError`, `throw new Error("gutted")`, `return null`, `panic("gutted")`, `t.b.d`. In typed languages the placeholder also satisfies the return type. See [references/language-notes.md](references/language-notes.md) for keeping gutted code compiling and for how to comment out blocks cleanly per language.

Run the suite. Existing tests that touched this function will now fail — that's expected and fine; they'll come back to green as you restore lines. If a *lot* of unrelated things break, the target has more reach than you thought — reconsider scope.

## The Cycle

Repeat RED → RESTORE, one case at a time, until the function is whole again.

### RED — one failing test for a single case

- Write **exactly one** test for **one** concrete case — the simplest untested path first (usually the happy path or the earliest early-return).
- **Derive the expected value independently** (see [Why this isn't circular](#why-this-isnt-circular)). Do not run the code and copy its output.
- Run it. **Confirm it fails, and fails for the right reason** — the behavior is missing because the body is gutted, not because of a typo, an import error, or a wrong assertion. A test that errors out on setup isn't red for the reason you want.

### RESTORE — un-comment the smallest slice that makes it pass

- Un-comment the **smallest slice of the original code** that turns this test green — ideally a single line. **Restore, don't rewrite.** The code presumably worked; your job is to un-hide it, not to author it.
- **Un-comment the inner statement before its surrounding conditional or loop when your test targets a single case.** Because you're only exercising one path, you can often restore the guarded body unconditionally and let a *later, contrasting* test force the guard back in. This is the core move — see the worked example in [references/worked-example.md](references/worked-example.md).
- Remove the placeholder once real restored `return`s cover the paths under test.
- Run the full suite. **Confirm the new test and every existing test pass.**

**If restoring makes it pass but you had to *change* the restored code to get there — stop.** One of three things is true, in rough order of likelihood:
1. Your test targets a case this slice doesn't actually handle → restore a *different*/larger slice, or pick a case that matches the code you have.
2. Your independently-derived expected value is wrong → recheck the spec, fix the test.
3. The original code is genuinely wrong → **Bug Discovery** (below). Rewriting commented-out original code to force a green is how this technique silently turns into "reimplement the function," which defeats the entire point.

**Never edit a test to make it pass.** If the test was wrong, fix it as a deliberate correction, not by weakening the assertion.

## Bug Discovery

Sometimes you write a specification test for behavior you're confident about, restore the line that should satisfy it — and it stays red, because the original code is actually buggy. **Do not fix it inline.** You are here to build the net, not to change behavior; a fix now is unpinned and conflates two jobs.

Instead:
- Keep the test asserting the **correct** (intended) behavior.
- Mark it **skipped / expected-to-fail** with a one-line reason pointing at the bug (`@pytest.mark.xfail(reason=…)`, `it.skip`, `t.Skip`, `#[ignore]`, `@Disabled` — see [references/language-notes.md](references/language-notes.md)).
- Restore the (buggy) original line anyway if it's needed for other paths, so behavior stays unchanged and the rest of the net can continue.
- Log it in the ledger (below). Keep moving.

Fixes happen at the end, once coverage exists to catch fallout — and gated on the user (see Finish).

## Tracking (lightweight ledger)

Keep a short running ledger — inline in the conversation is fine; a scratch note if the function is large. No heavyweight state file. Track just:
- **Cases covered** — one line each.
- **Lines still commented** — what's left to earn back.
- **Bugs found** — the skipped/xfail tests and their reasons.

Report it at each check-in so the user can see coverage growing and redirect.

## Finish

The function is fully backfilled when:
1. **Nothing is left commented** — every original line is either restored under a passing test, or consciously flagged (below). Diff the function against the pristine original from Setup: at this point — the net complete, no fixes applied yet — the restored body must be **byte-for-byte identical** to the original. Any drift at all is an accidental rewrite; investigate it. (Bug fixes come later, in the user-gated step below, and only then does the body legitimately diverge.)
2. **Every path has at least one test**, and the full suite is green (skipped bug-tests aside).
3. **Leftover-code check.** If some commented lines were never needed to pass any test *and* you can't construct a test that reaches them, they may be **dead / unreachable code** — a finding worth surfacing, not silently restoring to tidy the diff. Restore them to preserve behavior unless you and the user agree they're dead, but flag them either way.

Then present:
- The coverage added (tests, paths pinned).
- The **skipped bug-tests**, each with its reason.
- Any dead-code or characterization-only findings.

**Fixing the bugs is a separate, user-gated step.** For each skipped test, the user decides: fix now (un-skip it and make it pass — a normal small red-green change, now safe because the net exists), or defer it (leave it skipped as documented, tracked work). Don't roll into fixes unprompted; the deliverable of *this* technique is the net, not the repairs.

## Discipline (the invariants)

- **One test per RED.** One case at a time is what keeps each restored slice small and justified.
- **Verify RED fails for the right reason** — gutted behavior, not a broken test.
- **Restore, don't rewrite.** If a commented line needs *editing* to pass, you've mis-targeted the case, mis-derived the expected value, or found a bug. Never quietly reimplement.
- **Derive expected values independently.** Reading them off the code makes the test unfalsifiable — worthless.
- **Never edit a test to force green;** never inline-fix a discovered bug. Bugs become skipped tests, fixed later under the user's call.
- **Un-comment the smallest slice** — inner body before surrounding conditional/loop where a single case allows it.
- **The final body must match the original** except for sanctioned fixes. The diff is your proof you built a net rather than a new function.
