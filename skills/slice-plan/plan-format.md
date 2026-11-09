# Slice Plan Format

A plan records **what** gets built: the feature, its acceptance criteria, its constraints, and the
ordered PRs that deliver it.

## Location and name

`<plans-dir>/slices-<feature-slug>.md`

- **`<plans-dir>`** — whichever of `plans/`, `docs/plans/`, or `.plans/` the repo already has.
  Create `plans/` only if none exists. If more than one exists, ask rather than guessing.
- **`<feature-slug>`** — a short kebab-case name derived from the confirmed feature definition
  (`csv-export`, `session-timeout`). Confirm it at the alignment gate: it is permanent, and a loop
  may use it to name branches.

The `slices-` prefix and the `# Slice Plan` heading let Startup find plans, renamed ones included.

**The plan is never committed.** Add its path to `.git/info/exclude` when the file is created:
`printf '%s\n' "<plans-dir>/slices-<feature-slug>.md" >> "$(git rev-parse --git-path info/exclude)"`,
then confirm `git status --short` does not list it. An executor's `git add -A` would otherwise
sweep it into a PR, and a loop's rollback would erase edits made to it.

## Who writes it

- **`slice-plan`**, from creation until `Status` is `agreed`. After that, only `Ticket` and
  *Differs from ticket* lines, when tickets are published or a ticket is edited — or to set it back
  to `drafting`, or to retire it.
- **A loop**, after `agreed`, and only to re-slice: the `## PRs` section — PRs it has not started,
  or narrowing the current one — following `slicing.md`'s *Re-slicing*. Feature, criteria and
  Constraints stay as agreed; changing them is a new planning session.

Set **Last updated** on every write.

## The file

A template, filled in as you go.

```markdown
# Slice Plan

- **Feature slug**: <feature-slug>
- **Status**: drafting
- **Spec**: <plans-dir>/spec-<name>.md, or `none`
- **Design**: <path to a design document>, or `none`
- **Split from**: <the parent feature's name or ticket ref>, or `none`
- **Started**: YYYY-MM-DD
- **Last updated**: YYYY-MM-DD

## Feature

<one or two sentences: what is being built, for whom, and what is explicitly out of scope>

## Acceptance Criteria

Behavioral and outside-observable: each names who observes it and where.

- AC1 — <criterion>
  - e.g. <concrete example, carried from the spec when there is one>

## Constraints

Mandates from outside the team, each with its source. `None.` when there are none.

- <mandate> — <who imposed it, and where it's recorded>

## PRs

### 01 — <pr-slug>
- **Behavior**: <one sentence, no "and">
- **Depends on**: none
- **Advances**: AC1
- **Kind**: thread
- **Merge safety**: live
- **Ticket**: PROJ-12

### 02 — <pr-slug>
- **Behavior**: <one sentence, no "and">
- **Depends on**: 01
- **Advances**: none
- **Kind**: refactor — <why it is too large to ride along with a slice>

### 03 — <pr-slug>
- **Behavior**: <one sentence, no "and">
- **Depends on**: 01, 02
- **Advances**: AC2
- **Ticket**: PROJ-12, PROJ-14
- **Differs from ticket**: PROJ-14 — <what it says> / <what this plan says instead>
```

## Header fields

| Field | Rule |
|---|---|
| Status | `drafting` until the user passes the alignment gate, then `agreed`. A loop builds only an `agreed` plan. A `drafting` plan found at Startup was never agreed: re-present it at the gate. Back to `drafting` only to change feature, criteria, Constraints or PRs — and, if a loop ledger (`loop-<feature-slug>.md`) exists, only on the user's yes, since a build is resting on them. |
| Spec | The spec this plan adopted. Adoption also sets the spec's own `Status` to `adopted: <this plan's path>`. |
| Design | Any design document, from whatever step wrote it. |
| Split from | Set on a plan created by splitting a larger feature. A child may split again. |

## PR fields

| Field | Rule |
|---|---|
| Heading | `### NN — <pr-slug>`. A PR you decide not to build is deleted, not marked. |
| Behavior | One sentence, no "and". Narrowing or splitting it is ordinary re-slicing; widening it into another PR's work goes to the user first. |
| Depends on | Comma-separated `NN`s of the PRs that must merge before this one, or `none`. Every dependency appears earlier in the list. Groups that share no dependency chain are the evidence for a split (`slicing.md`). |
| Advances | The criteria this PR moves, or `none` — which then requires a `Kind`. |
| Kind | Omitted for an ordinary slice. `thread` marks the steel thread, and a PR split off it at a seam — still slices; a loop re-slices after each ships. `refactor` or `scaffolding`, with a one-sentence reason, marks a PR that isn't a slice. |
| Merge safety | On the `thread` PR always — `live`, or `inert: <what makes it unreachable>` — and on any other PR that ships something unreachable. |
| Ticket | Tracker refs this PR serves. Many-to-many: one PR may serve several tickets, and several PRs may share one. |
| Differs from ticket | Where this plan disagrees with a ticket it can't change: the ref, what the ticket says, what the plan says. The plan wins locally; these are listed at the gate. Removed if the user has the ticket edited. |

Fields appear in the template's order, optional ones omitted.

**Numbering.** `NN` is assigned at planning and never reused — loops key their own records on it.
A PR inserted later takes the next free number and sits in sequence order, so `05` may appear
between `02` and `03`. Read order is the list; `NN` is an identity, not a position. A re-slice
re-points every `Depends on` it affects, and no dependency may follow its dependent.

## Splitting into child plans

When a split is agreed, write one plan per group **in place of the parent**: each with its own
slug and exclude line, `Status: drafting`, `Split from` set, its own Feature sentence, the parent's
Constraints, Spec and Design, and its PRs — `NN`s kept — and the criteria they advance, carried
over as a draft. Retire the parent if it was already written. The user picks which
child, if any, goes through its gate now; the rest wait at Startup.

## Retiring a plan

Delete the file, then delete its one line from `"$(git rev-parse --git-path info/exclude)"`,
leaving every other line alone. If the user keeps the plan as a record, keep the exclude line too:
a file that stays without it gets committed by the next `git add -A`.
