# Review Prompts

**The reviews are always delegated.** Two per PR — the test-set review at RED, the whole-diff
design review at REVIEW — plus one end-of-feature review at completion. This is not a mode; it
is the design. Skipping one, or running it in this session, breaks the thing the review is for.

Optionally delegating a whole *phase* to keep the driving session small is a separate decision,
orthogonal to this one; it lives in [phase-delegation.md](phase-delegation.md).

Before RED's review, check your available tools for a delegation mechanism — Claude Code and pi
both expose one, under names that vary by version. Do not assume a tool name. Note whether it
can send a follow-up message to a subagent it already spawned: Review 1 is two turns.

---

## Why the reviews delegate

- **You wrote it.** You hold the rationale for every choice in the diff, so anything you
  remember deciding reads as already-adjudicated rather than as a smell. That bias runs toward
  under-reporting exactly what a review exists to catch. A reader given only the artifact has
  no prior commitment to defend. Authorship bias is the actual rubber-stamp mechanism, and
  fresh context is the only thing that removes it.
- **The RED review buys something self-review cannot produce at all**: a cold reader
  reconstructing the contract from the tests alone *is* the future consumer. If they cannot
  reconstruct it, the tests are unclear — and you can never generate that signal yourself,
  because you already know the contract.
- **The catalog is meant to be transient.** Loading the full design catalog into this session
  would leave it resident for the rest of the feature, quietly overriding the decision to keep
  judgment invoked rather than ambient.

Be clear-eyed about the trade: delegation costs *more* total tokens than reviewing in-session,
because each call is a cold start. What it buys is an unbiased reviewer and a driving session
that stays small. Two standing delegations per PR is the budget this skill is designed around —
it is still far below the per-test flow's per-cycle ceremony.

**Fresh context removes bias, not laziness.** Every review prompt below therefore demands
*artifacts* — tables, censuses, named worsts — not verdicts. A reviewer asked "any problems?"
answers "looks fine"; a reviewer asked for a filled trace table has to look.

---

## Review 1 — the test-set review (RED step 5)

Spawn one subagent. It gets the test files **plus the raising skeleton** — and no
implementation, because none exists. That absence is the point: this is the cheapest review in
the flow and the only one whose reviewer sees the contract exactly as a consumer will.

**Run it as two turns.** The first artifact is a contract reconstruction *from the tests alone*,
and a reviewer that has already read the intended contract cannot produce one — it has the
answer in context before it starts writing. Telling it to read the prompt in order does not fix
that; the whole prompt is in context at once. So the intent is withheld until the reconstruction
has come back.

**Turn 1 — spawn the subagent with this and nothing else:**

> Review a set of tests written test-first, before any implementation exists. Read only these
> files: `<test file paths>` and `<skeleton file paths>`. The implementation does not exist
> yet — the skeleton raises `NotImplementedError` (or equivalent) by design; do not treat that
> as a defect and do not write any code.
>
> From the tests alone, state the contract they imply: what the unit does, its inputs, outputs,
> error behavior, and any ordering or state assumptions. Write it as you understand it from the
> tests, not as you think it was meant. Where the tests leave something genuinely undetermined,
> say so rather than filling the gap.
>
> Do not modify any file. Report the reconstruction as your final output; a follow-up will
> arrive.

**Turn 2 — send this as a follow-up message to that same subagent**, once the reconstruction is
in hand:

> The intended contract: the PR's one-sentence behavior is `<PR sentence>`; the acceptance
> criteria it advances are `<criteria>`; the design hypothesis is `<hypothesis>`.
>
> Produce these artifacts in order. Do not substitute a summary judgment for any of them.
>
> **1. Divergences.** Compare your reconstruction against the intent above. Every divergence is
> a finding — it means the tests are ambiguous about something. List each one. Do not revise
> your reconstruction; it is the evidence.
>
> **2. Trace table.** One row per test: test name → the behavior or acceptance criterion it
> serves. The behaviors in this batch are: `<behavior list from THINK>`. A test with no row is
> speculative — flag it. A listed behavior with no test is a gap — flag that too.
>
> **3. Setup census.** How many tests share setup, what that shared setup is, and the single
> worst setup in the batch, named, with why it is worst.
>
> **4. Worst assertion**, named, with why — the one that would be hardest for a future reader
> to understand or that is most coupled to implementation detail rather than observable
> behavior.
>
> **5. Test-quality pass.** Invoke the `design-principles` skill and apply its `test-catalog.md`
> to the batch: FIRST, behavioral-not-wiring, mock-at-boundary, clarity of names.
>
> Rank all findings by severity. For each, say whether fixing it changes the **interface**
> (names, signatures, types, errors) or only the **tests**. Do not modify any file. Report the
> assessment as your final output.

Only if your delegation mechanism cannot send a follow-up message to an existing subagent:
spawn a second fresh subagent for turn 2, giving it the test and skeleton paths, the turn-1
reconstruction pasted in verbatim, and the turn-2 prompt above. Never collapse the two turns
into one prompt — that is the failure this split exists to prevent.

**Triage locally, and act now.** Interface findings are the whole reason this review happens
before implementation exists: amend the tests and skeleton, re-run the per-test verification
(RED step 3), and commit the revision. Test-only findings: fix, or dismiss with a stated
reason. Record dismissals in the state file — the REVIEW reviewer will see them, which is what
keeps a dismissal honest.

---

## Review 2 — the whole-diff design review (REVIEW step 3)

Spawn one subagent per round. Scope is the whole PR diff, state file excluded:

```bash
git diff <previous-pr-branch>...HEAD -- . ':(exclude)<state-file>'
```

`<previous-pr-branch>` is the squashed branch of PR NN−1 — **for PR 01, which has no
predecessor, use the recorded base branch instead**. (The `.` is required — a lone
`:(exclude)` pathspec errors on some git versions. At a one-shot boundary, use the PR's range:
`git diff <PR-(NN-1)-end>...HEAD -- . ':(exclude)<state-file>'`, and for PR 01 of a one-shot
run from the start, the base branch again.) Run the command from the repository root: the `.`
and the exclude are both relative to the working directory, so from a subdirectory the review
scope is silently narrower.

Unlike the isolated cold review this flow replaced, this reviewer gets **intent**: what the
design was trying to be, and what was consciously set aside. The question is not "find smells"
but "was the intent honored, and what pressure emerged."

> Invoke the `design-review` skill. Scope: `<the exact git diff command above, filled in>`,
> run from the repository root.
> Focus: the statement, name, function, and class altitudes. Do not review component or system
> altitude — a separate end-of-feature pass owns those. Scope and focus are given; do not
> resolve your own and do not ask for either.
>
> Context for the review — use it, do not re-derive it:
> - **Design hypothesis** (what this implementation was trying to be): `<hypothesis>`
> - **The batch as spec** (the tests are the specification of what this PR must do):
>   `<behavior list and test names>`
> - **Consciously deferred / dismissed so far** (do not report these as new findings; do say
>   if one now looks like the wrong call): `<dismissals, deferrals, backlog items touching
>   this diff>`
>
> Your central question: **does the implementation honor the hypothesis, and what design
> pressure emerged that the hypothesis does not account for?** A divergence between hypothesis
> and implementation is a finding in its own right — say which one you think is wrong.
>
> Also produce, explicitly: the **three largest new functions**, each with a one-sentence
> statement of its single responsibility — if a sentence needs "and", say so.
>
> Tag every finding exactly one of:
> - `structural-if-fixed` — fixing it would move responsibilities between units, add or merge
>   types, or change a contract.
> - `local` — rename, extraction, inlining, or cosmetic change confined to one unit.
>
> Rank by severity. Do not modify any file and do not fix anything you find. Report the rated
> assessment as your final output.

**The tags are load-bearing.** Re-entry into another review round is decided by the reviewer's
tag, not by your own classification of your fixes — that gate was moved out of the author's
hands deliberately. If any fix you applied was tagged `structural-if-fixed`, run one more round
on the new diff. Fixes of `local` findings never re-enter. **Cap: three rounds.** Anything
structural still open at the cap goes to the backlog and is surfaced at the boundary as an open
concern — never silently absorbed.

**Triage locally — the reviewer diagnoses, you decide.** Fix (suite green after; commit
each green step per SKILL.md's *Discarding an experiment*), dismiss with a stated reason, or
record in the backlog as a named entry. The report itself is not kept; the backlog entries and
the PR Log's review line are the durable record.

---

## Review 3 — the end-of-feature review (Progress, condition 4)

Runs once, at completion. Every PR already had its own whole-diff review, so this pass must not
re-sweep the codebase — that is the least useful place to spend the most accumulated context.
It looks only at what no single PR could show.

> Invoke the `design-review` skill. Scope: `git diff <base-branch>...<final-branch> -- .
> ':(exclude)<state-file>'`, run from the repository root. Focus: **cross-PR seams and the
> component and system altitudes only** — duplication where the two sides live in different PRs,
> dependency cycles, grab-bag packages, and rot symptoms assembled across several PRs that were
> each individually clean.
> Do NOT review the statement, name, function, or class altitudes: every PR in this feature
> already had a dedicated review at those altitudes, and re-reporting them wastes the pass.
> Scope and focus are given; do not resolve your own and do not ask for either.
>
> Context: the feature is `<feature definition>`; the final design hypothesis is
> `<hypothesis>`; the PRs were: `<one line each>`.
>
> Produce explicitly: any concept that appears in more than one PR under different names, and
> any module that gained responsibilities from more than one PR. Do not modify any file.
> Report the rated assessment as your final output.

If the feature is a single PR there are no cross-PR seams — narrow the focus to the component
and system altitudes alone. Findings go to the backlog and must be resolved before declaring
done; a substantial one becomes a new PR in the plan, never an amendment to a delivered one.
