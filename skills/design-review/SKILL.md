---
name: design-review
description: "Reviews existing code for design and test-quality problems — naming smells and design-rot symptoms, locating them, and rating them by severity, then reporting a ranked assessment with a suggested direction for each. Use when the user explicitly asks for a design review, a design/quality critique of a diff, PR, branch, or path, or asks 'what's wrong with the design here'. This is a deliberate, focused pass the user chooses to run — not an ambient check to fire on every coding task, and distinct from a correctness/bug review. It diagnoses design; it does not hunt for functional bugs or rewrite the code."
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

### 2. Classify what's touched, and the altitude

- **What's touched**: does the scope include production code, test code, or both? Get the
  file list first — it decides which catalog you pull in. For a diff scope,
  `git diff --name-only <target>` (for `last commit`, `git show --name-only --format= HEAD`);
  for a path scope, list the files under the path.
- **Altitude**: `uncommitted` and `last commit` are read as a single diff; `branch vs
  parent` and a PR are read as a *unit* — which means also looking at the seams *between*
  commits, where duplication and divergent change most easily survive a per-commit view. A
  path scope is likewise read as a unit: whole files with no diff to anchor on, so seams
  between the files are in scope too.

### 3. Apply the lens with a detection posture

**State the posture, then load the catalog.** The posture for this skill is fixed:

> Read each entry as a defect that may be **present in this code**. For each one that
> matches, name it, point to where it lives, and judge how much it actually costs here.

Then **invoke the `design-principles` skill** for the catalog:
- always consult its `design-catalog.md` (smells + rot symptoms);
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
- (tests, if in scope) wiring tests, mocking your own code, tests named for implementation.

### 4. Report a rated assessment

Produce findings **ranked most-severe first**. For each:
- **Name** the smell/principle (the precise term from the catalog).
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
