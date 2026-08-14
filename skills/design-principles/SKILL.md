---
name: design-principles
description: "A shared, neutral vocabulary of software design and test quality — Fowler's code smells, Martin's symptoms of design rot, SOLID, Beck's rules of simple design, and DRY/Pragmatic values, plus test-quality smells (FIRST, mock-at-boundary, behavioral-not-wiring). Load this to name design pressure precisely: what to call a smell, which principle a problem violates, or whether a test is well-formed. Consulted directly when the user asks about a smell/principle/test-quality term, and invoked as a shared catalog by other skills that review code (design-review) or weigh design options. This skill supplies the concepts only — the calling context supplies the posture (detect-and-rate vs weigh-options)."
---

# Design Principles — a shared lens

This skill is a **vocabulary**, not an activity. It holds the concepts — design smells,
rot symptoms, design principles, and test-quality properties — stated **neutrally**: what
each thing *is*, never what to do about it in your particular situation.

Whoever loads this file supplies the **posture**:
- A **reviewer** reads these as defects to detect in existing code, locate, and rate.
- A **designer** reads them as forces to weigh when comparing options not yet built.
- A **methodology/flow skill** reads them at whatever cadence its own process dictates.
- A **direct lookup** — the user asking what a term means — needs no posture: find the
  entry and answer from it.

The catalog never needs to know which of these you are. Except for a direct lookup, state
your posture in one line before you apply the entries, then apply them through that lens.

## What to load, and when

The references are split so you pull in only what the task needs. **Do not read all three
by default.**

1. **[references/design-catalog.md](references/design-catalog.md)** — Fowler's smells +
   Martin's rot symptoms. Load this whenever you are reasoning about the design of
   *production* code.

2. **[references/test-catalog.md](references/test-catalog.md)** — FIRST, mock-at-boundary,
   behavioral-not-wiring, tests that have outlived their job, test clarity. Load this
   **only when tests are in scope**. If your caller already determined what's in scope, use
   that. Otherwise decide by the files under consideration — for a diff target,
   `git diff --name-only <target>`; for a path target, whether test files live under the
   path — and load this file only if the set includes test files (by the project's test
   path/naming convention). A production-only change should not pull it in.

3. **[references/principles.md](references/principles.md)** — SOLID, Beck's four rules of
   simple design, DRY/Pragmatic values. Load this **when you need to name the *why*** —
   which principle a smell violates, or which principle should decide between two options —
   not during plain detection. The design catalog links into it where a smell has a
   principle behind it.

These three filenames are a **public interface**: consumer skills (`tdd`, `design-review`)
reference them by name from their own instructions. Renaming, splitting, or merging the
files under `references/` is a breaking change for those consumers — update every caller in
the same change.

## Using it well

- **Naming is the deliverable.** A precise name ("this is *Feature Envy*", "this trades
  Beck's rule 2 against rule 3") turns a vague unease into something a decision can be made
  about. Naming a smell is never itself a mandate to fix it.
- **Don't scan a whole catalog to pattern-match.** Reach for the specific entry you need.
  The catalogs are dictionaries, not checklists to run top to bottom.
