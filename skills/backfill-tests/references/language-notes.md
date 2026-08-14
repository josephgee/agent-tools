# Language notes

Two mechanical problems recur across languages: keeping a gutted function
compiling, and marking a discovered-bug test as skipped/expected-to-fail. Quick
references below. When in doubt, check the project's actual test framework rather
than assuming from these.

## Keeping a gutted function compiling

Commenting out a body often leaves a function that no longer returns its declared
type or satisfies the compiler. Drop in an idiomatic "not implemented" placeholder
so the *only* thing failing is your test — not the parser or type checker. Remove
the placeholder once restored `return`s cover the paths under test.

| Language    | Placeholder                                  |
|-------------|----------------------------------------------|
| Python      | `raise NotImplementedError`                  |
| JS/TS       | `throw new Error("gutted");`                 |
| Go          | `panic("gutted")`                            |
| Rust        | `unimplemented!()` or `todo!()`              |
| Java/Kotlin | `throw new UnsupportedOperationException();` |
| Ruby        | `raise NotImplementedError`                  |
| C#          | `throw new NotImplementedException();`       |
| C/C++       | `abort();` (and a dummy `return {};` if the type demands it) |

Notes:
- **Loops and multi-line blocks**: comment the whole block out together. Restoring
  the inner body without its loop/guard is the point (see the worked example) — but
  keep the commented structure intact above/around it so you can un-comment the loop
  header in a later cycle without retyping it.
- **Statically-typed early returns**: if the placeholder is unreachable after you
  restore a `return`, the compiler may warn about dead code — that's your cue to
  delete the placeholder.
- **Guard clauses / exhaustiveness**: some compilers (Rust `match`, Kotlin `when`,
  switch exhaustiveness) won't accept a partially-restored block. If restoring one
  arm won't compile without the others, restore the minimal compiling unit and let
  tests drive *which values* you assert, rather than which lines exist.

## Marking a discovered-bug test skipped / expected-to-fail

When a specification test exposes a real bug, keep it asserting the **correct**
behavior and mark it so the suite stays green while documenting the defect. Prefer
"expected to fail" over a plain skip where the framework offers it — an xfail that
starts unexpectedly *passing* tells you the bug got fixed.

| Framework            | Skip                              | Expected-to-fail                                  |
|----------------------|-----------------------------------|---------------------------------------------------|
| pytest (Python)      | `@pytest.mark.skip(reason=…)`     | `@pytest.mark.xfail(reason=…, strict=True)`       |
| unittest (Python)    | `@unittest.skip(reason)`          | `@unittest.expectedFailure`                       |
| Jest / Vitest (JS)   | `it.skip(…)` / `test.skip(…)`     | `it.failing(…)` (Jest) / `test.fails(…)` (Vitest) |
| Go                   | `t.Skip("reason")`                | — (use `t.Skip` with the reason)                  |
| Rust                 | `#[ignore = "reason"]`            | `#[should_panic]` only if it actually panics      |
| JUnit 5 (Java)       | `@Disabled("reason")`             | — (use `@Disabled` with the reason)               |
| Kotlin (JUnit5)      | `@Disabled("reason")`             | —                                                 |
| RSpec (Ruby)         | `skip "reason"` / `xit`           | `pending "reason"`                                |
| xUnit (C#)           | `[Fact(Skip = "reason")]`         | —                                                 |

Always include the reason and, ideally, a pointer to the bug (ticket, or a one-line
description of the wrong behavior). The skipped test is documentation of a known
defect *and* the ready-made red test for whoever fixes it later.
