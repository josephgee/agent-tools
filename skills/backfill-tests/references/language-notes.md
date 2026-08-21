# Language notes

Per-ecosystem specifics for three steps of the loop: finding un-covered lines, marking a
discovered bug, and (optionally) running a full mutation sweep. When in doubt, check the
project's actual configuration rather than assuming from these tables.

## Coverage, for the one-shot blind-spot scan

Run coverage over the target's own tests, restricted to the target file — a whole-suite report is
noise you have to search. Ask for **branch** coverage: line coverage is near-useless here, since an
`if` with no `else` reports 100% from a single test through the true path.

Read only the zeroes. A covered line is not a pinned line — coverage records that code *ran*, not
that anything asserted about it — so the percentage tells you nothing about the quality of the net
and is not a thing to move. The skill's three outcomes for an unhit branch (test it / leave it and
report it / flag it as possibly dead) are all valid endings; two of them leave the number lower.

| Ecosystem | Command |
|-----------|---------|
| Python | `pytest --cov=<module> --cov-branch --cov-report=term-missing <test-file>` (pytest-cov) |
| JS/TS (Jest) | `jest --coverage --collectCoverageFrom='<path>' <test-file>` |
| JS/TS (Vitest) | `vitest run --coverage --coverage.include='<path>' <test-file>` |
| Go | `go test -coverprofile=c.out -covermode=count ./<pkg> && go tool cover -func=c.out` (`-html=c.out` for line detail) |
| Rust | `cargo llvm-cov --lcov` (or `cargo tarpaulin`) |
| Java/Kotlin | JaCoCo — `mvn test jacoco:report` / `gradle test jacocoTestReport` |
| Ruby | SimpleCov, configured in `spec_helper.rb`; `--branch-coverage` for branches |
| C# | `dotnet test /p:CollectCoverage=true /p:Include='[asm]Type'` (coverlet) |

If no coverage tool is configured, don't install one uninvited. Do the blind-spot scan by reading
the body against your ledger instead — it is the same question asked by hand, and on a single
function it is not much slower.

## Marking a discovered-bug test skipped / expected-to-fail

Keep the test asserting the **correct** behavior so it stays a ready-made red test for whoever
fixes the bug. Prefer expected-to-fail over a plain skip where the framework offers it — an xfail
that starts unexpectedly *passing* tells you the bug got fixed. Always include the reason, and a
ticket reference if there is one.

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

## Mutation testing (optional end-of-pass sweep)

The per-test perturbation in the main loop is the required check. If the project *already* has one
of these configured, a scoped run at the end is a stronger sweep — surviving mutants name behaviors
nothing asserts. Scope it to the target; whole-repo runs are slow enough to be unusable in a
session. Don't add one of these to a project that doesn't have it as part of a backfill.

| Ecosystem | Tool | Scoped run |
|-----------|------|-----------|
| Python | mutmut / cosmic-ray | `mutmut run` — scope via `--paths-to-mutate <path>` or the project's mutmut config, depending on version |
| JS/TS | Stryker | `stryker run --mutate '<path>'` |
| Java/Kotlin | PIT | `mvn org.pitest:pitest-maven:mutationCoverage -DtargetClasses=<Class>` |
| C# | Stryker.NET | `dotnet stryker --mutate '<path>'` |
| Ruby | mutant | `mutant run --subject <Class#method>` |
| Go | go-mutesting | `go-mutesting ./<pkg>` |
| Rust | cargo-mutants | `cargo mutants --file <path>` |
