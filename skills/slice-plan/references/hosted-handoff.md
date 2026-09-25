# Handing a slice to a skill

Skills like `tdd` and `tdd-batch` plan a whole feature, manage their own branches, and ship at
their own boundaries. Hosted here they run **one slice** and the plan keeps the rest.

## The override block

The block below is the **guest-facing rendering of the executor contract** in SKILL.md, *The
executor contract*, which is that contract's single source. It renders the five obligations **in
the contract's order, one numbered paragraph each**, in the guest's voice. It is the only form of
the contract a skill-shaped guest ever reads, so it stays self-contained and pasteable and must
never be turned into a pointer back to SKILL.md.

**Change an obligation in SKILL.md and change its numbered paragraph here in the same edit.** The
numbering is the check: a block carrying fewer than five numbered paragraphs has lost an
obligation, and counting says which. The unnumbered paragraphs are framing the host owes the guest
— what to skip, what to do when it cannot finish — and detail hanging off a numbered one; they are
not obligations and are not counted.

Give the block verbatim when invoking the guest, with the placeholders filled — except
`<your name>`, which is the guest's own name in its own voice; leave it for the guest, or
substitute the strategy name the plan's Attempts line needs. It is written *to* the guest, not
about it.

### Adapting it for a guest that reviews

A guest whose own flow reviews its diff before hand-back, iterating until clean (`atdd` today),
gets the block's ban on a guest-side review reversed. Give the block verbatim with **paragraph 5
replaced, whole, by this** (nothing else in the block changes; a guest's own per-slice gates, such
as `atdd`'s human design gate, are not the alignment gate the block skips and survive):

> **5. Hand back before the squash.** Do not squash, do not present a PR, and do not write a PR
> description. Do run your own review as your rules describe, before you hand back, and record it
> in a `## Review` section of your state file, with lists headed `Dismissed` (each finding with its
> reason), `Backlogged`, `Open at cap` (including any change made after your last review, marked
> unreviewed) and `Out of scope`. Never fix a finding that asks to tighten an earlier slice's or
> the steel thread's test, or that asks for behavior this slice does not have: those are
> `Backlogged`, however cheap. Put `reviewed` on your hand-back line. The host then skips its own
> boundary review and shows the user your dismissals, so keep them honest, one line each. Decision
> context you would otherwise send to a PR description goes in your state file's `Learned` line, as
> your own rules already say — the host reads it from there and folds it into the squash commit.

### Adapting it for `navigator`

`navigator` is different — it never edits files and the user writes every line — so hosted it is a
coaching strategy, not a building one. Its adapted block runs to **four** numbered paragraphs:
obligation **4 is deliberately absent**, because navigator edits nothing and so has nothing to
commit; the user's work on a `navigator` slice is the host's to confirm committed (SKILL.md,
*Hand off*, and the contract's per-shape table). The changes:

- **In paragraph 2, replace the stop condition** with: *"Coach the user through this slice. Write
  no code. Stop when they say the slice is done and the suite is green, then hand back."*
- **Reduce paragraph 3 to its scope half** — coach only this slice, and treat work the plan has
  given to a later slice as not this slice's. Drop the plan write-back list and the state-file
  detail that follows it: navigator writes nothing but its own session file, which lives at its own
  path wherever that skill puts it (under `~/.claude/projects/` in Claude Code) rather than the
  plans directory, and the host records its progress in the plan.
- **Drop paragraph 4 entirely**, and drop the `blocked` paragraph's "commit any complete work"
  clause with it.
- **In the `blocked` paragraph, the host writes that `Attempts` line too** — navigator says what
  stopped it and stops.

---

> You are executing **one slice** of an existing plan. The plan file is `<plan-file>` and this is
> slice **`<NN>`**. Read its Session, Feature, Acceptance Criteria, Design Hypothesis and Slices
> sections for context — Session records the test runner command, so you need not rediscover it.
>
> **Do not run your own planning, and do not run your own setup** — except for creating your
> state file, if your flow keeps one; that step survives, wherever it sits in your setup.
> Otherwise: the feature definition, acceptance criteria, design hypothesis and decomposition are
> already agreed and recorded. Skip your preflight, skip your alignment gate, and skip your setup
> section entirely — the working tree is already clean, the baseline is already green, the plans
> directory is already chosen, and the branch already exists. Make no "begin" commit.
>
> **Your plan is this one slice**, and its whole scope is: *`<behavior sentence>`*. It advances
> `<criteria>`. Any test an earlier slice left that this one invalidates has already been updated
> for you on this branch, so you start green and nothing this slice asks of you requires breaking
> an earlier slice's test. The numbered obligations below are the whole of what you owe.
>
> **1. Stay on the branch the host cut, and create no others.** It is already cut and checked out:
> **`<branch>`**. Do not create, rename or switch branches.
>
> **2. Leave the suite green when you hand back, with a passing test for this slice's behavior.**
> Stop when the suite is green and the behavior is observable — or, on a slice recording a `Kind`
> of `refactor` or `scaffolding`, when the existing suite is still green over the restructured
> code, which is the whole of the obligation there: no new behavior, so no new test. Green
> mid-slice is a checkpoint; green when you hand back is what the host's next rollback rests on.
> If an earlier slice's test turns out to need changing after all, it is the host's to change —
> hand back `blocked` rather than changing it, and never hand back with the suite red. If you ran
> the full suite green on your final code, say so on your hand-back line — `handed back: suite
> green at <sha>` (after any note the host left there, comma-separated) — and the boundary will
> not re-run it. Commit first and give the sha of the code you actually tested; the host checks
> it against your worktree.
>
> **3. Write only your designated plan fields, and build only your own slice.** In `<plan-file>`
> write only these: your slice's `Attempts` line, set to `<your name> — handed back` (or
> `handed back: <note>` if you have something the host must check at the boundary), keeping any
> note the host has already written on that line; design hypothesis changes that affect a *later*
> slice; and backlog items, unless your own state file holds them. Leave acceptance criteria, slice
> statuses and every other slice alone, and do not tick acceptance criteria anywhere — the host
> does that at the boundary, against a passing test. Build only your own slice, too: a
> restructuring the plan has already given to a later slice is not yours to do, so if the cleanup
> your own refactoring step wants is the whole of a slice further down the Slices section, log it
> and move on — doing it here empties that slice.
>
> *Under 3, if your flow keeps a state file:* create it at `<plans-dir>/` under your own naming
> convention, with the feature slug `<feature-slug>`. Where its format calls for a feature
> definition, acceptance criteria, a design hypothesis or a plan of increments, **copy them from
> the plan file rather than deriving them** — and its plan of increments is this one slice, not a
> sequence you invent; number that single increment `<NN>` to match the slice. If it also keeps a
> backlog, capture backlog items **there and not in the plan** — the host drains your file into the
> plan at the boundary, and an item written to both arrives twice. The fields your format fills at
> ship never become real here: a final commit sha, an end sha, a `ready` or `complete` status — the
> host squashes *after* you hand back, so leave them empty, leave the increment open, and do not go
> looking for the squash or invent a sha.
>
> **4. Commit your work on this branch as you go, and leave it committed when you hand back.** The
> host squashes committed *history*, not worktree state: an uncommitted slice leaves the branch
> zero commits ahead of its base, the squash's `git commit` fails with "no changes added to
> commit", and a resumed host reads zero commits as a slice you never built.
>
> **5. Hand back before the squash.** Do not squash, do not present a PR, do not write a PR
> description, and **do not run your own design review of the diff** — even one your instructions
> mark as mandatory in every execution mode. The host reviews and squashes this slice at its
> boundary; running yours reviews work the host has not accepted yet and asks the user to approve
> the same work twice. Decision context your refactor step would otherwise send to a PR
> description still goes in your state file's `Learned` line, as your own rules already say — the
> host reads it from there and folds it into the squash commit.
>
> **If you cannot finish the slice, hand back `blocked`.** That is the one sanctioned way not to
> finish one. It needs splitting; it turns out to need an earlier slice's test changed after all;
> your own rules leave you no move on it — all the same outcome. Leave the suite green, commit any
> complete work (or nothing, if there is none), set your slice's `Attempts` line to
> `<your name> — blocked: <what stopped you>`, and say the same when you hand back. Do not
> re-slice, do not change another slice's test, and do not hand back with the suite red: the first
> two are the host's, and the third is nobody's.

---

## Delegated or in-session

**Run a skill-shaped guest in a delegated subagent wherever the session supports it.** A guest's
body, its references and its own dependencies all load into whatever context runs it; in-session
that stacks on top of this skill's, once per slice, and an abandon is worse — the dead guest's
whole body stays in context while its replacement loads on top of it. Delegated, a slice comes back
as a result instead of as context.

Run a guest in-session when delegation isn't available, when it is `atdd` (its human design gate
needs the user live, and it spawns subagents of its own), when it is `navigator` and the user needs
to watch it work, **or when you expect to want the abandon**. A delegated guest is invisible until
it hands back: you cannot watch it throw its own work away and you cannot stop it mid-slice, so the
abandon is only reachable for an in-session guest. Delegation buys context at the cost of the
mid-slice exit — a slice over unproven ground is the one to keep in-session. It also costs the view
of how the guest worked, so judge a delegated guest by what it left on disk, per *Reading the
result* below.

## The guest's state file

The plan itself needs no handling at a transition — it is excluded and untracked throughout. A
skill-shaped guest's state file does: `tdd` and `tdd-batch` keep one in the plans directory and
**commit it with every cycle**, so it is tracked, and it would ship to the reviewer in the squash
and be found by the next slice's guest if left behind. Do not add it to the exclude — the guest
needs its own file tracked for its own rollbacks; the host just removes it at the boundary.

So at both transitions off a slice — the boundary and an abandon — drain anything worth keeping out
of it, then remove it. Most of it goes to the plan; its `Learned` line is the one exception —
that is decision context the guest's own refactor checklist sent there instead of a PR
description it was forbidden to write, and the plan is the wrong destination for it (it is not a
later slice's concern). A reviewing guest's `## Review` lists are the other exception:
`Dismissed` and `Open at cap` are presented to the user at the boundary (step 3), whatever the user
wants revisited becomes a plan backlog entry, and `Backlogged` and `Out of scope` become plan
backlog entries directly. Read it before the squash and fold it into the squash commit per the
boundary's step 4 — that is the shipped commit's PR description now, so that is where decision
context belongs. The squash's `git reset -- <plans-dir>/` keeps the file itself out of the shipped
commit; the boundary's step 6 deletes it, and in the abandon it is the first action — the
`git rm -f` at the top of the bash block, before the restore, so the reversion commit carries the
deletion away. A guest whose artifact lives
outside the repo by its own design — `navigator`, wherever that skill puts it, under
`~/.claude/projects/` in Claude Code — keeps it: drain, and leave the files alone.

## Reading the result

**A delegated guest returns a result, not a transcript**, and delegating is the default (SKILL.md,
*Hand off*). So judge it by what it left on disk, not by how it behaved. At the boundary, before
the design review:

- the suite is green (or its result reused, per the boundary's step 1) and no PR was presented;
- the commits are on the branch you cut, and `git branch --list` shows no branch the plan does not
  name, other than one left behind by a dropped slice;
- `ls <plans-dir>` shows nothing new but the guest's own state file — no second plan — and in
  your plan it touched nothing but its own slice's fields;
- `git -C "$(git rev-parse --show-toplevel)" status --short` is clean outside the plans
  directory.

The in-flight tells — a guest re-planning, a guest drifting towards shipping — are visible only to
a host running the guest in-session, which is the exception. Do not write a check that assumes
them.

**The disk checks are necessary but not sufficient, and the gap is structural.** A guest that
writes its own rules to disk and re-reads them each cycle — as `tdd` and `tdd-batch` both do, by
design, to survive compaction — is re-teaching itself the frame this block just removed, from a
more durable position than this block occupies. Over a slice of more than a few cycles the disk
wins. Keep hosted slices short, which the sizing test already requires, and treat drift found at
the boundary — a PR description written, a second branch, a plan of its own — as a sign the slice
was too big rather than the wording too weak.
