# slice-split: separating planning from the build loop

## Problem

`slice-plan` does two jobs in one skill: deciding what gets built — the feature, its criteria, and
its cut into reviewable pieces — and hosting the loop that builds those pieces one at a time. The
coupling limits both.

- **Planning** is useful without building: scoping a feature, splitting it into deliverables,
  turning those into tickets. Today it can't stop at an agreed plan; it runs straight into the loop.
- **The loop** might want a different implementation entirely, possibly a script. Today it shares a
  file format, a body and a guest contract with the planner.

## Terms

| Term | Meaning | Sized by |
|---|---|---|
| **Feature** | A small set of slices delivered together | Scope and value — a judgment, provisional (below) |
| **Slice** | An end-to-end piece of deliverable functionality, possibly trivial | Its behavior |
| **PR** | The unit of review and build — usually one slice, sometimes a refactor or scaffolding PR | Reviewability |

A feature can split into child features. There is no separate "epic" level: the thing being split
is usually a feature found to be too big, and a fixed label would cause category confusion. A
tracker may call the parent an epic; that is its label, not ours. Parent and child are a
relationship (`Split from`), not a category, so a child can split again.

Today's `Kind: refactor` and `Kind: scaffolding` "slices" are PRs that aren't slices. The plan's
sequence is a list of PRs.

## The three skills

| Skill | Owns | Depends on |
|---|---|---|
| `slice-plan` | Feature, criteria, Constraints, the PR sequence, the split check, the alignment gate | Nothing |
| `slice-loop` (new) | Baseline and setup, strategy choice, branches, executor contract, boundary, background suite, abandon, cleanup | `slice-plan` (reads its format and `slicing.md`), `design-review`, git |
| `slice-tdd` | Building one PR test-first | Only the handoff block — no host skill |

The plan file is the only interface between `slice-plan` and `slice-loop`. A replacement loop reads
the same file; a planner never needs a loop installed.

Rejected: one file with a loop-owned section — simpler, but every loop, a script included, would
inherit the Attempts format.

## slice-plan

### Inputs

- **Signed-off spec** — adopted as today: criteria verbatim, no re-interview. On adoption the spec's
  `Status` changes from `signed off` to `adopted: <plan path>` — the one edit `slice-plan` ever
  makes to a spec. Its Deferred and Assumptions are listed at the gate and the user rules where
  each goes. After that the spec is inert: Startup offers only `signed off` specs, so deleting the
  plan never resurrects it, and the user deletes it whenever.
- **Tickets** — source material, never adopted verbatim: a ticket hasn't been through a sign-off
  that made its criteria observable. Feature and criteria go through the normal questions and the
  observer test. Too vague to sharpen in a few questions → suggest `feature-spec` first.
- **Conversation** — as today.

Tickets are read-only by default. Writing to one is a per-edit yes.

### Steps

1. **Define the feature and its criteria.**
2. **Slice into a PR sequence** per `slicing.md`, each PR with `Depends on: <NN…> | none`.
3. **Check for a split.** Two signals:
   - **Disconnected work** — groups of PRs sharing no `Depends on` chain. Each is a natural feature.
   - **A long list** — the scope-and-value judgment; a prompt for the user, not a rule.

   Slicing is how a split is discovered, so it comes first. Rejected: split-then-slice — the
   evidence for a split is the slice list.
4. **If split**, each group becomes a child feature with its own plan: `Split from: <parent>`, its
   PRs carried forward as a draft, reconfirmed at the child's own gate when it is built. The parent
   plan is retired. Rejected: re-slicing each child from scratch — cleaner, but repeats work
   that's usually still valid; re-slicing already catches what went stale. Provisional.
5. **Alignment gate.** Then mark the plan `Status: agreed` and **stop**, offering next steps — build
   it with a loop if one is installed, publish tickets, or stop — and starting none. Rejected:
   auto-starting the loop — saves one yes, but ties the planner to a loop.

### Plan contents

Feature, Acceptance Criteria, Constraints, PRs, plus:

- `Status: drafting | agreed` — replaces "placeholder base branch means no gate".
- `Design: <path> | none` — see *Design is not the plan's*.
- `Spec: <path> | none`.
- `Split from: <parent>` on a child plan.
- Per PR: behavior sentence, `Depends on`, criteria advanced, `Kind` (`thread` for the steel
  thread, so a loop knows when to re-slice; `refactor`/`scaffolding` where not a slice),
  `Merge safety` where relevant, `Ticket: <refs>` (many-to-many), and `Differs from ticket: <ref> —
  <what it says> / <what the plan says>` where the plan disagrees with a ticket.

Gone: Strategy, Attempts, Suite, criteria ticks, Backlog, the Session block's runner and base
branch, Rules in Force, Design Hypothesis.

**Plan wins locally over a ticket it can't change.** Disagreements are recorded and listed at the
gate; the ticket is edited only on a yes, which removes the line. Rejected: blocking until the
ticket is fixed (your work waits on someone else's schedule), and following the plan silently
(the ticket's owner finds out at acceptance).

### Design is not the plan's

The hypothesis is implementation, and a brainstorm or a divergent spike might produce design before
or after slicing. So design lives in its own optional file, named by `Design:`; the plan doesn't
care what wrote it. A design step goes before slicing when its outcome could change the slices,
after when it only changes how a PR is built (which `slice-tdd`'s DESIGN already covers per PR).
The planner still reads code to judge whether PR 01 needs a steel thread; it records nothing.

Rejected: an optional plan section — a spike run before slicing has no plan to write into.

Cost: with `Design: none`, nothing coordinates seams across PRs except the steel thread and the
re-slice after it. If that shows up as rework, run a design step first — don't put the hypothesis
back.

### Guidance files

- `slicing.md` — unchanged for PR sizing, so the legacy `tdd` skill that reads it is unaffected.
  Gains a short, provisional *When to split the feature* section for step 3. Its *Re-slicing*
  section becomes an interface: `slice-loop` reads it.
- `plan-format.md` — the format above, and the `Status`/retirement rules.

Rejected: a separate ticket-splitting skill, or a separate `scoping.md` — the split is one step
inside slicing, not a second sizing mode. Flips if splitting grows its own steps (stakeholder input,
estimation).

## slice-loop

- **Runs only** a plan with `Status: agreed`. No plan → send the user to `slice-plan`; it plans
  nothing itself.
- **Setup:** clean tree, green baseline, test runner, base branch, written to its own ledger. A red
  baseline is the user's call; the plan doesn't change. Cost: a red suite now surfaces after the
  gate, not before.
- **Ledger** — its own untracked file keyed on the plan's PR `NN`s: statuses, Strategy, Attempts,
  Suite, criteria ticks, backlog, and the Rules in Force header. Private to this loop.
- **Re-slicing** — edits the plan's PR list directly, unshipped PRs only, per `slicing.md`'s
  *Re-slicing*; feature, criteria and Constraints stay as agreed. Splits are minor; drops and
  reorders go to the user. The plan has two writers, never at once: planner until the gate, loop
  for re-slices. A script loop doesn't re-slice — it stops and reports. Rejected: invoking
  `slice-plan` per re-slice (loads a planning flow mid-build, may take over), and freezing the plan
  with deltas in the ledger (every loop would have to merge two files).
- **Cleanup** — deletes its ledger and reports, then offers to delete the plan and its exclude line.

## The guest hand-back

Guests never write to the loop's ledger. The loop asks for a report, checks it, and copies it.

1. **The loop asks.** The handoff block names a report path,
   `<plans-dir>/handback-<slug>-<NN>.md`, and six required headings. `none` is a valid answer; a
   missing heading is not.
2. **The loop checks.** A missing file or heading means not handed back: re-invoke once, then stop
   and tell the user what's missing.
3. **The loop copies** the report into its ledger before the squash or anything that could lose
   it, then deletes the file.

The report is excluded from git like the plan. Its existence is the only hand-back signal, so a
guest that dies right after finishing still reads as finished, and one that didn't finish resumes
from its own state file.

| Heading | Host uses it to |
|---|---|
| **Outcome** — `handed back`, `blocked: <reason>`, `paused: design done` | Choose the next step |
| **Review** — whether reviewed; dismissed and open-at-cap findings | Skip its own review; show the user |
| **Criteria proof** — each criterion and the test or proof that covers it | Tick criteria — the host still makes the call |
| **Carry-forward** — backlog and out-of-scope items | Keep them past the state file |
| **Later-PR discoveries** | Decide whether to re-slice |
| **Learned** | The squash commit message |

Never trusted from the report: branch, tree state and green targeted tests — the loop checks those
on disk. Not reported: how the guest worked (design doc, test runs, pressure log). `direct` and
`hand` PRs have no guest; the loop writes the same facts itself.

Rejected: a hand-back section in the guest's state file — the loop would have to know where each
guest keeps its state, which puts the coupling back.

## slice-tdd

Depends only on the handoff block, which carries behavior, criteria, `Kind`, Constraints, test
runner, base branch, branch, mode, `Design` pointer, report path, and the plan path as read-only
context (for "is this a later PR's work"). Drops `slice-plan` from `soft-deps` and `compatibility`;
says plainly it does nothing without a block. `slice-loop` owns the block template in its
`hosted-handoff.md`.

Cost: `./install-claude.sh slice-tdd` no longer pulls in a host; name `slice-loop` too. Rejected:
`slice-loop` as a hard dependency — any replacement loop would carry an unused skill.

## Migration

None needed: no in-flight plans existed on 2026-11-09.

## Provisional

- The scope-and-value judgment behind a split, and what a "long" PR list is — iterate before
  writing rules.
- Carrying PRs forward into child plans.

## Deferred

- Brainstorm and spike skills (they need only the `Design:` field).
- Writing to a tracker beyond a per-edit yes.
- A scripted loop.

## Order of work

1. `skills/slice-plan/plan-format.md` — the new format.
2. `slice-plan/SKILL.md` and `slicing.md`'s split section.
3. `slice-loop` — moved body, ledger format, the report.
4. `slice-tdd` — block-only dependency, report in place of Attempts writes.
5. `docs/workflow.md`, `README.md`, `feature-spec`'s adoption wording.
