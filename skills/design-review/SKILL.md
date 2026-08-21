---
name: design-review
description: "Reviews existing code for design and test-quality problems — naming smells and design-rot symptoms, locating them, and rating them by severity, then reporting a ranked assessment with a suggested direction for each. Use when the user explicitly asks for a design review, a design/quality critique of a diff, PR, branch, or path, or asks 'what's wrong with the design here'. This is a deliberate, focused pass the user chooses to run — not an ambient check to fire on every coding task, and distinct from a correctness/bug review. It diagnoses design; it does not hunt for functional bugs or rewrite the code."
metadata:
  soft-deps: design-principles
---

# Design Review

A **diagnostic** pass: find where existing code is under design pressure, name it precisely,
and rate it — so the user can decide what's worth acting on. You diagnose; you do not fix
(unless the user then asks) and you do not chase functional bugs (that's a correctness
review).

Run this only when the user asks for it. It is not a per-cycle or per-commit reflex.

## Procedure

### 1. Resolve the target and scope

A review needs an **explicit scope** — "review my changes" is ambiguous across several
reasonable ones, and guessing wrong wastes the whole pass. Scope may come from the user or
from an invoking skill. Resolve it by who's asking:

- **Scope given** (named by the user, or passed by a caller): use it.
- **A human invoked this directly without one**: ask which of the list below before
  proceeding — do not guess.
- **Another skill invoked this skill without one**: that caller owns the choice — do **not**
  block on a user prompt it can't route (it may be running with no interactive user, e.g. a
  subagent). Proceed with a stated default — `uncommitted` if the working tree has
  uncommitted changes, otherwise `branch vs parent` — and name the scope you assumed so the
  caller's omission is visible in the report.

The scopes:

- **uncommitted** — working-tree changes, staged and unstaged (`git diff HEAD`; use
  `git diff` / `git diff --staged` to separate them).
- **last commit** — the most recent commit alone (`git show HEAD`).
- **branch vs parent** — everything the current branch adds over its base
  (`git diff <base>...HEAD`, with the base from `git merge-base HEAD <default-branch>`; if
  the base isn't obvious, ask for it rather than assuming — unless running non-interactively,
  in which case take the repo's default branch as the base and name that assumption in the
  report alongside the assumed scope).
- **a PR** — `gh pr diff <n>`.
- **a path** — the file(s)/directory as they stand, independent of git state (reviews
  existing code, not a diff).

If the chosen scope resolves to nothing (e.g. `uncommitted` on a clean tree), say so and
stop — do not silently widen to a different scope.

### 2. Classify what's touched, and the reading mode

- **What's touched**: does the scope include production code, test code, or both? Get the
  file list first — it decides which catalog you pull in. For a diff scope,
  `git diff --name-only <target>` (for `last commit`, `git show --name-only --format= HEAD`);
  for a path scope, list the files under the path.
- **Reading mode**: `uncommitted` and `last commit` are read as a single diff; `branch vs
  parent` and a PR are read as a *unit* — which means also looking at the seams *between*
  commits, where duplication and divergent change most easily survive a per-commit view. A
  path scope is likewise read as a unit: whole files with no diff to anchor on, so seams
  between the files are in scope too. (This is about how much history you read at once. It is
  unrelated to *altitude* in the catalog's sense — the structural level a problem lives at,
  from statements up to components — which the next step covers.)
- **Cross-component reach**: if the scope adds or changes imports/dependencies that cross a
  component or package boundary, the component-level lenses are in play and **the diff alone
  cannot show them**. A single added import can create a dependency cycle while every changed
  line looks fine.

  **Settle what counts as a component here first** — everything below depends on it. Take the
  boundaries from the project's own packaging units: workspace members, or module manifests
  (`go.mod`, `pyproject.toml`, `package.json`, `Cargo.toml`, `*.csproj`) and the directory each
  one governs. Failing those, use the top-level directories under the source root. If the
  project has no such structure — a flat repo, a single package — there are no component
  boundaries to cross: say so and skip this step. A component's *files* are the ones under its
  boundary; that is what "grep its files" means below.

  To check: grep the touched files for their import/require/use statements
  (`grep -nE '^\s*(import|from|require|use|#include)' <files>`), keep the ones naming a
  component other than the file's own, and for each of those check whether that component
  already depends — directly or transitively — back on this one. To check that: run the same
  grep over that component's files, looking for imports that name this one (a direct cycle);
  if there are none, take the *other* components its imports name and grep each of those the
  same way — one hop is enough to catch most transitive cycles, and note in the report that
  you checked to that depth. If a cycle turns up, you have a finding the diff cannot show. If
  the scope adds no boundary-crossing dependency, skip this step — most diffs don't.

### 3. Apply the lens with a detection posture

**State the posture, then load the catalog.** The posture for this skill is fixed:

> Read each entry as a defect that may be **present in this code**. For each one that
> matches, name it, point to where it lives, and judge how much it actually costs here.

Then **invoke the `design-principles` skill** for the catalog:
- always consult its `design-catalog.md` — Fowler's smells, the *Clean Code* heuristics,
  component-level smells, and the rot symptoms. Detection is the one posture that does sweep
  rather than look up a single entry, but sweep **by altitude**: cover the levels your scope
  actually touches (a single-file change rarely reaches the component level; a change moving
  code between packages starts there) rather than reading the file end to end;
- consult its `test-catalog.md` **only if** step 2 found test files in scope;
- consult its `principles.md` when you need to name *why* a finding is a problem or what the
  fix should preserve.

**Only if the `design-principles` skill is not available** in this environment, fall back to
the compact core list below — it is a floor, not a substitute for the full catalog:

- *Duplicate Code* / DRY violation — the same knowledge in more than one place.
- *Long Method* / *Large Class* — a unit doing too much to summarize in a sentence.
- *Divergent Change* — one place changing for several unrelated reasons.
- *Shotgun Surgery* — one change forcing scattered edits across many places.
- *Feature Envy* / *Inappropriate Intimacy* — a unit reaching into another's internals.
- *Switch Statements* — the same type/kind conditional repeated in many places.
- *Speculative Generality* — abstraction with no present caller.
- *Primitive Obsession* — raw primitives standing in for concepts that deserve a type.
- *Mixed abstraction levels* — high-level policy and low-level detail interleaved in one unit.
- *Missing abstraction* — a concept the code plainly has, but never named.
- *Dependency cycle* — components that depend on each other, directly or transitively.
- (tests, if in scope) wiring tests, mocking your own code, tests named for implementation.

On the fallback path you also lose the catalog's lenses for a unit that merely *looks* too big,
so carry them here — a long or densely branched unit is a finding only if one of these names a
cause: **comprehension cost** (a reader can't reconstruct what it does), **mixed abstraction
levels**, **missing abstraction**, or **more than one reason to change**. Cyclomatic complexity
is a reason to look, never a finding by itself.

### 4. Report a rated assessment

**Before ranking, apply the finding gate.** Size, length, and branching-density observations
are prompts to look, not findings. Promote one to a finding only when a lens names an actual
cause — from the catalog's "When a unit feels too big" cluster, or, on the fallback path, from
the lenses at the end of step 3. If nothing names it, drop it: do not report "this function is
long" as a finding in its own right, and do not inflate it into the nearest smell that
half-fits. Examining a unit and leaving it is a correct result.

The exception is a unit that clearly troubles you while no lens names why. Say exactly that, as
its own note rather than a rated finding — it points at a real gap in the catalog, and it is
more honest than either forcing a match or reporting the code as clean.

Produce findings **ranked most-severe first**. For each:
- **Name** the smell/principle (the precise term from the catalog), at the altitude it
  actually lives at. A symptom visible in one function may have its cause at the component
  level; name the cause, since that is what a fix has to address.
- **Location** — file and line/region.
- **Severity** — one of **high** / **medium** / **low**, judged by how much it costs *here*:
  high = actively causing rigidity/fragility or will soon; medium = a real cost, but
  contained and not yet compounding; low = cosmetic or speculative. A named smell is not
  automatically a defect; say so when a match is technically present but not worth acting on.
- **Direction** — one sentence on the shape of the fix (which principle it should restore),
  not a full rewrite.

Close with a one-line overall read (e.g. "sound overall; one high-severity coupling issue
worth addressing before this grows"). If nothing meaningful survives scrutiny, say that
plainly rather than manufacturing findings.
