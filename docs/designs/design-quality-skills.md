# Design-quality skills: a lens and its consumers

## Problem

Design-review knowledge — Fowler's code smells, Martin's rot symptoms, SOLID, Beck's rules
of simple design, DRY/Pragmatic values, and test-quality smells (FIRST, mock-at-boundary,
behavioral-not-wiring) — originally lived as reference files **inside `tdd`**
(`references/design-smells.md`, the "Test Code" section of `refactor-checklist.md`).

The repo model — one directory per skill, consumed via symlinks of bare directory names,
**no manifest** (see `README.md`, `AGENTS.md`) — makes a skill's `references/` **private to
that skill**. So `backfill-tests`, `navigator`, or any future skill could only reuse that
knowledge by copying it, which drifts. The knowledge is shared substrate; it needed to be a
shared unit.

## Two directions of use

The same catalogs get consumed in two opposite directions:

- **Diagnostic / backward** — detect smells in code that already exists (a *review*).
- **Generative / forward** — weigh candidate designs against principles and smells (a
  *design/brainstorm* activity, not yet built).

That diagnosis-vs-solutioning split is a genuine **reuse** seam — two distinct activities,
triggered by different requests, sharing one catalog. That is what justifies extracting the
catalog into its own **lens skill** rather than duplicating it. (By contrast, test-vs-design
is *not* a reuse seam — you almost never review one without the other — it is only a
*loading* seam, handled by scope-gating references within the lens, not by splitting skills.)

## Architecture

```
design-principles (lens)            <- shared catalogs, neutral concepts, scope-gated refs
      ^                    ^
      | invoke             | invoke
design-review (activity)   [future] design/brainstorm (activity)
      ^
      | invoke for the deep pass (degrade to inline subset if the lens is absent)
tdd, backfill-tests (flow skills; keep their own cadence + inline fast-triggers)
```

- **`design-principles`** — the lens. A thin router `SKILL.md` over three references:
  `design-catalog.md` (smells + rot), `test-catalog.md` (test smells, loaded only when tests
  are in scope), `principles.md` (SOLID/Beck/DRY, loaded when naming the *why*). It states
  concepts only.
- **`design-review`** — the diagnostic activity. Resolves a target, determines scope +
  altitude, invokes the lens with a **detection** posture, emits a rated assessment. Scoped
  to explicit review requests (not ambient).
- **`tdd`** (and later `backfill-tests`) — flow skills that keep their tuned per-cycle
  triggers inline and invoke the lens for the deep end-of-increment / end-of-feature pass.

## The seam: lens holds concepts, consumers supply posture

The organizing rule. The lens holds each concept **neutrally** — what a smell *is*, never
what to do about it. Each consumer supplies its own **posture** at load time:

| Consumer        | Posture it brings                                    |
| --------------- | ---------------------------------------------------- |
| `design-review` | detection — "is this present here; name, locate, rate" |
| design/brainstorm (future) | weighting — "which option trips fewer of these" |
| flow skills     | cadence — *when* and *how often* to consult, per their process |

Posture is **per-activity and uniform across entries** — a reviewer treats every entry the
same way, so the posture is stated **once** by the consumer, not baked into all ~40 entries.
That is why the catalog is not dual-framed per entry: doing so would repeat one constant
dozens of times and roughly double the lazily-loaded token weight. The one exception is a
targeted `designing note:` on the few entries whose *forward* application isn't obvious from
the detection-flavored description (e.g. *Speculative Generality*, *Primitive Obsession*).

## Single-source + degrade (not self-contained)

The catalogs live in **one** place (`design-principles`). Flow skills do **not** keep their
own copies — self-contained copies would inevitably drift. Instead:

- flow skills keep only their **tuned inline subset** (e.g. `tdd`'s three per-cycle
  triggers) and **invoke** the lens for depth;
- because there is no manifest, the dependency is **soft** — a skill may be installed
  without the lens. Every consumer therefore **degrades gracefully**: the preferred path
  invokes `design-principles`; if it is unavailable, the inline subset is the floor. The
  preferred (invoke) path is written as the concrete instruction, per `AGENTS.md`.

### Activity skills must be non-blocking when invoked by a skill

`design-review` asks the user to pick a scope when a human invokes it directly without one.
But a skill-to-skill invocation may run with no interactive user (e.g. a subagent), so
blocking on that prompt would hang the caller or ask into a dead channel. The rule:
**scope is the caller's obligation** — a calling skill passes an explicit scope — and
`design-review` treats a missing scope from a caller as the caller's omission, proceeding
with a stated default (`uncommitted` if the tree is dirty, else `branch vs parent`) rather
than prompting. Only the direct-human path asks. `tdd`'s optional handoff passes the feature
branch against its base. (The lens itself never has this problem — it prompts for nothing,
taking scope from its caller or deciding from the changed files.)

## Status and planned consumers

Built:

- `skills/design-principles/` — lens.
- `skills/design-review/` — diagnostic activity.
- `tdd` rewired: its four deep-catalog references and `refactor-checklist.md` /
  `pr-workflow.md` now invoke the lens with a degrade fallback; the old private
  `design-smells.md` was deleted.

Planned (documented here, not yet built):

- **A generative design/brainstorm activity skill** — the forward consumer of the lens,
  applying a weighting posture to compare options. This is the second half of why the lens
  is a standalone skill.
- **Wire `backfill-tests` to the lens** the same way as `tdd`; its test-heavy cadence maps
  cleanly onto `test-catalog.md`.
