# feature-spec: defining a feature before slicing it

## Problem

`slice-plan` opens with a feature definition and acceptance criteria, but in two short paragraphs.
That is enough for a well-understood feature, and not enough for a vague one: the criteria come out
vague, or worse, technical — "we will have a `tz` column" — which is design, not behavior, and not a
non-functional requirement either. `feature-spec` is the upstream step that does this properly: an
interview that settles what the correct behavior is, and what is and isn't in scope, written to a
spec file `slice-plan` adopts.

## Scope

- **Feature** — a unit of deliverable user value that `slice-plan` will be run on. Bug fixes count
  (the AC is the intended behavior, plus regression AC for what must not change). Refactors don't —
  no observable change, nothing to specify. Spikes don't — their product is knowledge, not
  behavior; a separate skill if anything.
- **Size is not policed.** Slicing may find the feature is several; that is a good slice outcome.
  One spec feeds one plan for now — splitting a spec across plans is deferred (below).
- **Input** — anything: a one-liner, a pasted ticket or user story, an existing doc. Existing AC
  are audited through the observer test (kept, reframed, or moved to Constraints / Design
  hypothesis), not discarded.
- **Sources** — the codebase, read-only, chiefly to learn what it does *today* (regression AC, "is
  this already handled?"). Any other source the session has — ALM, knowledge base, Slack — likewise
  read-only. Anything taken from a source cites it; the user is the authority, and a source that
  contradicts them is raised as a question, not silently resolved.
- **Not touched** — no suite runs, branches or edits. Clean tree and green baseline stay
  `slice-plan`'s.
- **Externalization** — no integrations. At sign-off the skill asks whether to post the spec to a
  ticket system the session has a tool for; it posts only on a yes.

## The line between AC and design

**Observer test:** every criterion names who observes it and where.

| Kind | Observer | Example |
|---|---|---|
| Functional AC | an actor at the system boundary (UI, API, CLI, an emitted file) | "Exported CSV includes each user's timezone" |
| Non-functional AC | a measurement taken from outside | "p95 search latency < 200ms at 10k records" |
| Constraint | none needed, but must cite an external source | "v1 API clients keep working unchanged — partner contracts" |
| Design | only a reader of the code or schema | "Add a `tz` column to users" → Design hypothesis |

**Reframing move:** for a candidate that fails, ask "what breaks, for whom, if we don't?" The
answer is the AC; the mechanism goes to the hypothesis. If nothing breaks for anyone, it was never
a requirement. The swap test ("would another valid implementation fail this?") is a tiebreaker for
the NFR/design grey zone only — on its own it's graded by someone already holding the design.

Design sketching during the interview is expected and kept — as a non-binding **Design
hypothesis** that seeds `slice-plan` step 3. When the user answers a behavior question with a
mechanism, record the mechanism there and re-ask the behavior question.

## Terms

- **Out of scope** — behavior decided against, with a reason. A decision.
- **Assumption** — believed true, unverified; names the AC that change if it's false. Needs checking.
- **Deferred** — a question not yet answered; needs deciding. May not block any AC — an AC that
  can't be written without the answer is deferred with it, said out loud.
- **AC format** — a sentence naming the observer, plus concrete examples beneath it. Given/When/Then
  is allowed inside an example with multi-step setup, never required: precision lives in the
  examples, not the template.

## Exit

A checklist the agent verifies from the file, then the user's sign-off:

1. Every AC passes the observer test and has at least one concrete example.
2. Every constraint cites its source.
3. Every scope candidate the interview surfaced is ruled in, out (with reason), or deferred.
4. No deferred item blocks an AC.
5. Every assumption names the AC that depend on it.
6. The user reviews the whole spec and says yes — that freezes it.

Deliberately not grill-me's "until shared understanding": that has no stopping point, and a spec
skill is prep by nature. The interview continues only while it finds checklist failures. This is
also why the interview is built into the skill rather than delegating to `grill-me`.

## Spec file

`<plans-dir>/spec-<feature-slug>.md`, `<plans-dir>` chosen by `slice-plan`'s rule, slug confirmed
at sign-off and reused by `slice-plan`. Untracked: the skill adds it to `.git/info/exclude` at
creation, or `slice-plan`'s clean-tree check trips on it, or a guest's `git add -A` sweeps it into
slice 01. Durable record, if wanted, is the ticket system.

A **snapshot**: frozen once a plan adopts it. After handoff AC change in the slice plan, never the
spec — two live files claiming the AC would drift. Signed off but not yet adopted, it may reopen to
drafting. A **Scope Candidates** working section holds unruled candidates so exit check 3 is
checkable from the file; it must be empty at exit and is deleted at sign-off.

**Rules-in-force header** (~8 lines: observer test, reframing move, deferred-never-blocks,
design-to-hypothesis) at the top while drafting, re-read before writing each AC, stripped at
sign-off so the frozen spec — and anything pasted from it — is clean.

## slice-plan changes

- Startup offers an existing `spec-*.md` in plans-dir, as it offers a resumable plan.
- Steps 1–2 adopt a spec rather than re-deriving: Problem and Out of scope → Feature; AC verbatim
  with IDs and examples; Constraints → a new `## Constraints` section in plan-format; Design hypothesis seeds
  step 3. Confirm, don't re-interview.
- No spec → steps 1–2 as today. `feature-spec` is optional; neither skill depends on the other.
- Step 2 gains the observer test in a line, so the no-spec path holds the same AC/design line.
- Executors are told to read Constraints (hosted-handoff prompt).
- Deferred and Assumptions are not adopted. Cleanup lists them for the user to carry, then offers to
  delete the spec or move it out of plans-dir — kept in place, Startup would re-offer it forever.

## Deferred

- A spike skill.
- Splitting: slicing that finds one spec is really several features. slice-plan needs a way for a
  second plan to adopt the rest of a spec's AC (Startup offering partly-claimed specs, a distinct
  slug per plan, per-plan claimed IDs, Cleanup counting plans).
