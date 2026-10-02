---
name: feature-spec
description: "Defines a feature or bug fix before it is planned or built: interviews the user one question at a time to settle what the correct behavior is, observed from outside, and what is and is not in scope, then writes a spec file of acceptance criteria with concrete examples, constraints, out-of-scope rulings, deferred questions, assumptions, and a non-binding design hypothesis. Keeps criteria to externally observable behavior, moving mechanisms ('add a column') into the hypothesis. Use when asked to write a spec, define a feature, write or review acceptance criteria or a user story, pin down what a bug fix should actually do, or settle scope before slicing or planning a feature. Also audits AC already written in a ticket. Not for refactors (no observable change to specify) or spikes (they produce knowledge, not behavior). Reads the codebase and other sources; writes only the spec file."
compatibility: "Requires git — the spec file is kept untracked via .git/info/exclude. Reads the codebase, and any ticket system, knowledge base or chat source the session has a tool for; writes to none of them without the user's yes."
---

# Feature Spec

Settle **what** a feature must do — observed from outside — and what it deliberately won't, before
anyone decides how to build it. The output is one spec file: acceptance criteria with concrete
examples, plus the constraints, scope rulings, open questions and assumptions around them. A
planning step downstream adopts it.

A **feature** here is a unit of deliverable user value. A bug fix is one: its criteria are the
intended behavior, plus regression criteria for what must not change. **Decline** a refactor — it
changes nothing observable, so there is nothing to specify — and a spike, whose product is
knowledge rather than behavior. Say why in one line.

Don't police size. If the feature turns out to be several, slicing will find that — a good
outcome, not a failure of the spec.

## The line between a criterion and a design

This is the skill's core judgment. Every acceptance criterion **names who observes it, and where**:

| Kind | Observer | Example |
|---|---|---|
| Functional AC | an actor at the system boundary — UI, API, CLI, an emitted file | "Exported CSV includes each user's timezone" |
| Non-functional AC | a measurement taken from outside | "p95 search latency < 200ms at 10k records" |
| Constraint | none needed — but it must cite who imposed it | "v1 API clients keep working unchanged — partner contracts" |
| Design | only a reader of the code or schema | "Add a `tz` column to users" |

When a candidate criterion is design, **reframe it**: ask "what breaks, for whom, if we don't?" The
answer is the criterion; the mechanism goes to Design Hypothesis. If nothing breaks for anyone, it
was never a requirement — drop it. For a grey case between a non-functional AC and a design choice,
break the tie with "would a different valid implementation fail this?" — but only as a tiebreaker:
whoever holds the design in mind will grade that question in its favor.

Design talk during the interview is expected — keep it, as hypothesis. When the user answers a
behavior question with a mechanism, record the mechanism under Design Hypothesis and ask the
behavior question again.

## Startup

Run `find plans docs/plans .plans -maxdepth 1 -name 'spec-*.md' 2>/dev/null`, pattern quoted, and
judge by the output, not the exit status. Never use an ignore-aware search (ripgrep, or a glob tool
built on it): spec files are in `.git/info/exclude`, so it skips them silently and you start a
duplicate.

- **Drafting specs** — list them (title, file) and ask whether this request continues one. To
  resume: read it in full; if its rules-in-force header is missing or differs from
  [spec-format.md](spec-format.md), replace it verbatim; then continue the interview from the first
  exit-check item it fails.
- **A signed-off spec the user wants changed** — check whether a plan has adopted it:
  `find plans docs/plans .plans -maxdepth 1 -name '*.md' -exec grep -l '<spec file name>' {} + 2>/dev/null`
  — any file it lists other than the spec itself is a plan that adopted it. If one
  has, the spec is frozen and the change belongs in that plan — say so, and don't edit the spec. If
  none has, reopen it: Status back to `drafting`, the header restored, and resume.
- Otherwise — start fresh.

## 1. Gather

Before asking anything, learn what you can yourself:

- **The input** — a one-liner, a pasted ticket or user story, a doc. If it already has acceptance
  criteria, list them as candidates to audit; don't discard them.
- **The codebase**, read-only — chiefly what it does *today* in the affected area. That is where
  regression criteria and "is this already handled?" come from. For a bug fix, find the current
  behavior in the code, so the interview argues about what it *should* be, not what it is.
- **Other sources** the session has a tool for — tickets, knowledge base, chat threads — read-only.

Note where each fact came from; it gets cited next to the item it supports. Don't run the suite,
create branches, or change any file but the spec.

Then **create the spec file** per [spec-format.md](spec-format.md), which sets where it goes and
how it is named: name it from the feature's title, write the rules-in-force header verbatim, set Kind and Status
(`drafting`), fill Problem and Sources from what you gathered, and add the path to
`.git/info/exclude`:
`printf '%s\n' "<plans-dir>/spec-<name>.md" >> "$(git rev-parse --git-path info/exclude)"`.

## 2. Interview

**One question at a time**, each with your recommended answer, so the user can just say yes — and
can easily say no. Never ask what you could look up. Write each answer into the file as soon as
it's settled; the file, not the conversation, is the record.

**Re-read the spec file before every write to it.** The header at its top carries the rules this
interview most often drifts from, and the file survives context compaction where this skill's text
may not.

Walk these branches in order, finishing each before the next:

1. **Problem** — who has it, why it matters now. For a bug: what happens, what should.
2. **Audit existing criteria**, if the input had any — each one kept, reframed, or moved to
   Constraints or Design Hypothesis, with the user's agreement.
3. **Actors and triggers** — who starts the behavior, through which interface.
4. **Main path** — as concrete examples: this input, this situation → the observer sees this.
5. **Edges** — empty, huge, duplicate, concurrent, malformed; missing permissions; first use.
6. **Failures** — what the observer sees when it goes wrong, not that "an error is handled".
7. **What must not change** — existing behavior near the change. Regression criteria, drawn from
   what the code does today.
8. **Scope** — rule on every entry in Scope Candidates: in (it becomes a criterion), out (with a
   reason), or deferred. Each leaves Scope Candidates when ruled.
9. **Constraints** — anything mandated from outside: compatibility, regulation, ops, contracts.
   Each needs a source; one without is a preference, and a preference about mechanism is design.

Assumptions, deferred questions and scope candidates accumulate throughout — record them when they
appear, not at the end. A candidate is anything that might or might not be part of the feature and
isn't settled on the spot; write it to Scope Candidates so it can't be forgotten.

**Sources against the user**: the user is the authority. When a source says otherwise, raise the
conflict as a question; never resolve it silently in either direction.

## 3. Exit check

Stop interviewing when the file passes all of these — not when the conversation feels finished.
Check each against the file itself:

1. Every AC passes the observer test and has at least one concrete example.
2. Every constraint cites its source.
3. Scope Candidates is empty — every candidate ruled in, out (with a reason), or deferred.
4. No deferred question blocks an AC — an AC that needs the answer is deferred with it, and you
   have said so to the user.
5. Every assumption names the AC that depend on it.

Any failure is the next question. If none fail, go to sign-off — don't keep probing for
completeness. More questions always exist; this list is the definition of enough.

## 4. Sign-off

1. Present the whole spec.
2. On the user's yes: delete the rules-in-force header and the (now empty) Scope Candidates
   section, and set Status to `signed off YYYY-MM-DD`. The file is now frozen; Startup says when it
   may reopen.
3. Ask whether to post the spec anywhere — a ticket, an issue, a doc — and offer only systems the
   session has a tool for. Post only on a yes; the local file stays regardless.
4. Hand off: name the file, and that the next step is planning or slicing the feature from it.
