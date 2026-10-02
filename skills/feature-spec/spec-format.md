# Feature Spec Format

The spec records what a feature must do, observed from outside, and what it deliberately won't —
the input a slicing plan adopts. It is a **snapshot**: written during the interview, frozen at the
user's sign-off, and never edited after. Changes to the criteria after handoff belong to whatever
plan adopted them, not here.

It is never committed. Add its path to `.git/info/exclude` when you create it — an untracked file
outside the exclude makes the working tree unclean for whatever runs next, and a later
`git add -A` would sweep it into a commit.

## Location and name

`<plans-dir>/spec-<name>.md`

- **`<plans-dir>`** — whichever of `plans/`, `docs/plans/`, or `.plans/` the repo already has.
  Create `plans/` only if none exists. If more than one exists, ask rather than guessing.
- **`<name>`** — a short kebab-case form of the feature's title (`csv-export`), chosen when you
  create the file. It names the file and nothing else: it is not part of the feature's definition,
  and a downstream plan names its own work however it likes.

## Rules-in-force header

Written verbatim at the top of the file when you create it, never edited, and **deleted at
sign-off** — the frozen spec, and anything pasted from it into a ticket, carries none of it.
Re-read the file before every write to it: the file is on disk, so these rules
survive context compaction, and re-reading puts them at the end of your context, where they bind.

```markdown
<!-- RULES IN FORCE — delete at sign-off -->
> **Rules in force** — re-read before every write to this file.
> 1. Every AC names who observes it and where: an actor at the system boundary, or a measurement
>    taken from outside. If only a reader of the code or schema could observe it, it is design —
>    move it to Design Hypothesis.
> 2. For one that fails rule 1, ask "what breaks, for whom, if we don't?" The answer is the AC.
> 3. Every AC has at least one concrete example.
> 4. A deferred question never blocks an AC — an AC that needs its answer is deferred with it.
> 5. A mandate is a Constraint only if it cites who imposed it; a preference is design.
> 6. Stop asking when the exit check passes. More questions always exist; the check defines enough.
<!-- END RULES -->
```

## Template

```markdown
# Feature Spec: <feature name>

- **Kind**: feature | bug fix
- **Status**: drafting | signed off YYYY-MM-DD
- **Sources**: <tickets, docs, threads drawn on — or "conversation only">

## Problem

<Who has the problem, what it is, why it matters now. For a bug fix: what happens today and
what should happen instead.>

## Acceptance Criteria

- **AC1** — <criterion, naming its observer>
  - e.g. <concrete input or situation> → <what the observer sees>
  - e.g. <edge case> → <what the observer sees>
- **AC2** — <criterion> *(regression)*
  - e.g. <existing behavior that must not change>

## Constraints

- <mandate> — <who imposed it, and where it's recorded>

## Scope Candidates

Working list while drafting; must be empty at the exit check, and is deleted at sign-off.

- <might-or-might-not be in scope> — raised by <user | source>

## Out of Scope

- <behavior not delivered> — <why: deferred to a separate feature, not worth it, owned elsewhere…>

## Deferred

- <open question> — <why it can wait; confirm it blocks no AC>

## Assumptions

- <believed true, unverified> — affects AC<n>, AC<m>

## Design Hypothesis

Not a requirement. Mechanisms that came up while settling behavior — likely seams, modules
involved, the approach leaned toward. A downstream plan starts its design from here and is free
to discard it.

- <sketch>
```

## Field rules

| Field | Rule |
|---|---|
| AC IDs | `AC1`, `AC2`, … — stable once assigned. Never renumber: a downstream plan cites them. A removed AC leaves a gap. |
| AC sentence | Names the observer — *who* and *through what*: a user in the UI, an API client, the operator reading a log, a load test. |
| AC examples | Concrete values, not categories ("user in Lisbon → `Europe/Lisbon`", not "a valid timezone"). Given/When/Then is allowed inside an example with multi-step setup; never required. |
| `(regression)` | Marks an AC pinning existing behavior that must not change. Derive these from what the code does today, not from memory. |
| Non-functional AC | Lives in Acceptance Criteria, not a separate section — it passes the same observer test, with a measurement as the observer. Give the threshold and the conditions. |
| Constraints | External source required. Without one it is a preference, and a preference about mechanism is Design Hypothesis. |
| Scope Candidates | Anything that might or might not be part of the feature, written here the moment it comes up unsettled. Leaves when ruled: in becomes an AC, out goes to Out of Scope, deferred to Deferred. |
| Out of Scope | Every entry has a reason. |
| Deferred | An open question, not a belief. Something believed true goes in Assumptions. |
| Assumptions | Each names the AC it affects. One that affects none is not worth recording. |
| Sources | Cite where a fact came from inline, next to the item it supports, as well as in the header list. |
| Empty sections | Keep the heading with `None.` — an empty section is a ruling, a missing one looks like an oversight. |
