# Slice Plan Format

The slice plan records the feature, its acceptance criteria, and the ordered slices that deliver
it — plus, per slice, which implementation strategy is running it and which strategies were tried
and abandoned.

It is never committed. It stays untracked — via `.git/info/exclude`, set at Setup — from
creation to Cleanup, so that the record of a failed attempt survives the rollback that erases the
attempt. SKILL.md's *Plan File* section has the full reasoning.

A strategy may keep its own state file for intra-slice state — current phase, active test,
pressure log — under its own name, born and dying within one attempt. Many keep nothing at all.
The slice plan outlives every attempt, which is what lets the strategy change.

## Location and name

`<plans-dir>/slices-<feature-slug>.md`

- **`<plans-dir>`** — whichever of `plans/`, `docs/plans/`, or `.plans/` the repo already has.
  Create `plans/` only if none exists. If more than one exists, ask rather than guessing.
- **`<feature-slug>`** — a short kebab-case name for the effort, derived from the confirmed
  feature definition (`csv-export`, `session-timeout`). Confirm it at the alignment gate: it is
  permanent and also names the branches (`<feature-slug>/NN-<slice-slug>`).

The `slices-` prefix and the `# Slice Plan` heading keep these files distinct from an executing
skill's own state file. Naming files after the effort lets several efforts run in parallel.

---

## The Rules in Force header

Everything inside the fence below — the `# Slice Plan` title and the `## Rules in Force` section,
and nothing after it — is copied verbatim into a new plan file and never edited. It is the
**host's** rules-in-force, and only the host's: no executor ever reads it, every bullet is a host
obligation worded as the host's own check, and none of them states what an executor owes. Audit it
against the host's procedure in SKILL.md — never against the executor contract, which lives in
SKILL.md, *The executor contract*, and is rendered for guests in `references/hosted-handoff.md`.
Keep it short: it is re-read at every slice, boundary and abandon, and a long header is the context
rot it exists to counter.

**This section is the only part of a plan file that is ever replaced wholesale.** If a resumed
plan's header is missing or has drifted from the fence below, replace the `## Rules in Force`
section and leave every other section of that plan — Session, Feature, Acceptance Criteria, Design
Hypothesis, Slices, Backlog — exactly as it stands. The Attempts history under Slices is the one
thing no rollback recovers.

```markdown
# Slice Plan

## Rules in Force

Copied verbatim at creation. Re-read at the start of every slice, at every slice boundary, and
before every abandon. Never edited or summarized.

- One slice = one branch off the previous slice's branch (base branch for slice 01); never two.
- A behavior sentence narrows or splits freely; widening one is a re-slice, not an edit.
- Choose the strategy per slice, before its branch is cut; record it before any code. State the
  executor's obligations at every handoff, in the form its shape takes.
- No code on a slice — the earlier-slice test update (yours alone: this branch, fixture first,
  committed), the handoff, a paused `atdd`'s resume — until the previous slice's suite run reads
  `0`. The run uses this tree: change nothing outside the plans dir while it goes; stop it first.
- No boundary over a red test. Review, commit fixes, start the suite run, then present; squash only
  on the user's approval. Red after the squash: reopen, fix, amend, rebase the next slice onto it.
- To abandon, **propose it and get the user's confirmation first**, then run the abandon recipe
  (`references/abandon.md`) as one uninterrupted step.
- An attempt's line is closed in place, never removed and never duplicated.
- **The plan is never committed** — path in `info/exclude`. Never `git add` or `clean -x` it.
- Branch names only, never a commit sha: the squash rewrites them.
- The feature hypothesis is the plan's; a slice's internal design is the executor's.
- A slice the user has taken by hand is theirs — write no code in it; close its attempt line and
  confirm its work committed yourself.
```

## The rest of the file

A template, filled in as you go — not copied verbatim. **Write the Session block at creation,
along with the header**, with the feature slug and start date filled in and Base branch and Test
runner left as the placeholders below: `references/resume.md` reads a still-placeholder value as
"Setup never ran", so the placeholders are load-bearing and a plan created without a Session block
disables that detector.

```markdown
## Session
- **Feature slug**: <feature-slug>
- **Base branch**: <branch slice 01 is reviewed against — filled in at Setup>
- **Test runner**: `<command>` — filled in at Setup, once, so each executor need not rediscover it
- **Started**: YYYY-MM-DD
- **Last updated**: YYYY-MM-DD

## Feature

<one or two sentences: what is being built, for whom, and what is explicitly out of scope>

## Acceptance Criteria

Behavioral, outside-observable, the fixed target. Status is set only by a passing test.

- [ ] AC1 — <criterion>
- [x] AC2 — <criterion> — satisfied in slice 01

## Design Hypothesis

Feature-level only: the seams the slicing depends on — key modules, where responsibilities
divide, what each slice will find already in place. A slice's own internal design belongs to the
skill executing it. Superseded versions stay; they are why the later slices are shaped as they are.

- **v1** — <description> — superseded after slice 02: <what was learned>.
- **v2** — <description> — current.

## Slices

### 01 — <slice-slug> — shipped
- **Behavior**: <one sentence, no "and">
- **Advances**: AC2
- **Merge safety**: live
- **Suite**: green: /home/me/.cache/slice-suite/myrepo-<feature-slug>-01
- **Strategy**: tdd-batch
- **Attempts**:
  - tdd-batch — shipped

### 02 — <slice-slug> — in progress
- **Behavior**: <one sentence, no "and">
- **Advances**: AC1, AC3
- **Suite**: running: /home/me/.cache/slice-suite/myrepo-<feature-slug>-02
- **Strategy**: hand
- **Attempts**:
  - tdd-batch — abandoned: <what entangled, one line>
  - hand — handed back

### 03 — <slice-slug> — planned
- **Behavior**: <one sentence, no "and">
- **Advances**: none
- **Kind**: refactor — <why it is too large to ride along with a behavioral slice>
- **Strategy**: <chosen when its branch is cut>
- **Attempts**: none yet

## Backlog

Cross-slice notebook. Every item reaches a closed state before the feature is complete.

- [ ] <description> — noted in slice 02
- [x] <description> — resolved in slice 03: <how>
- [-] <description> — dismissed in slice 04: <why>
- [>] <description> — carried to <where the user named>
```

---

## When the host writes

Set **Last updated** at each of these:

- **Before the alignment gate** — create the file: the Rules in Force header, the Session block's
  feature slug and start date, the feature, criteria, hypothesis and slices.
- **Setup** — the test runner command and the base branch.
- **Choosing a strategy** — the slice's `Strategy` field and its first `Attempts` line.
- **Cutting the branch** — the slice's status to `in progress`, and any earlier slice's test the
  host updated there, noted on the `Attempts` line.
- **The slice boundary** — `Suite` set to `running: <dir>` at step 3, then slice status, its
  `Attempts` line closed, criteria ticked, hypothesis changes, and backlog items.
- **A background run's result** — `Suite` set to `green: <dir>` or
  `red: …, <dir>` when you read it, and back to `running: <dir>` at every restart.
- **An abandon** — the abandoned `Attempts` line and the new strategy.

These seven are the scheduled writes, not the only ones: the blocked path appends a fresh attempt
line or re-slices, and Feature complete may append a whole new slice. Set **Last updated** on those
too.

The exceptions are the fields an executor writes for itself: SKILL.md, *The executor contract*,
obligation 3.

## Slice record

| Field | Rule |
|---|---|
| Heading | `### NN — <slice-slug> — <status>`. Status is `planned`, `in progress`, or `shipped`. A slice you decide not to build is deleted from the plan, not marked — see SKILL.md, *Running a slice* step 2. |
| Behavior | One sentence, no "and". Narrowing or splitting it is ordinary re-slicing; widening it is a new slice. |
| Advances | The acceptance criteria this slice moves. `none` for a slice that moves no criterion — which must then carry a `Kind`. |
| Kind | `behavioral` by default, and then omitted entirely. `refactor` or `scaffolding` is written out with a one-sentence reason on the same line, and is the only thing that excuses a slice from shipping a new passing test. A slice whose `Advances` is `none` must carry one. A test-first strategy cannot run such a slice — see SKILL.md, *Running a slice* step 1. |
| Strategy | What is running the slice *now*. A skill name (`tdd`, `tdd-batch`, `navigator`), `direct` for the agent building it itself, or `hand` for the user writing it themselves. Chosen before the branch is cut. |
| Suite | The slice's full-suite run, started at the boundary's step 3 (`references/background-suite.md`): `running: <dir>`, then `green: <dir>`, `red: <failing tests>, <dir>`, or `green: fixed — <what>, <dir>` after a reopen — the directory always kept, since its status file is what the host's hold on the next slice reads and Cleanup deletes it. Absent until the boundary. A plan from before this field existed has none on its shipped slices; treat those as `green`. |
| Merge safety | Present on the steel thread always — `live`, or `inert: <what makes it unreachable>` — and on any other slice that ships something unreachable. Decided when the slice is planned; an `inert:` value is what the squash message says is deliberately not there. |
| Attempts | An indented list, one line per attempt, never removed; `none yet` is the placeholder for a slice with no strategy chosen and is replaced by the list at the first attempt. A line is **closed in place** as its state changes — `in progress` → `handed back`, `shipped`, `blocked: …`, or `abandoned: …`; only a genuinely new attempt adds a line. Values: `<strategy> — <in progress \| handed back \| shipped \| blocked: <what stopped it> \| abandoned: <what entangled>>`, plus `atdd — paused: design agreed` (SKILL.md, *Hand off*), closed in place and followed by a fresh `in progress` line when the host resumes it. `in progress`, `handed back` and `shipped` may carry a `: <note>` — used to record an earlier slice's test the host updated on this branch before handing off; `blocked` and `abandoned` already spend their colon, so their note goes in that text. A reviewing guest may also add the whole token `reviewed` to a `handed back` line, comma-separated after any note the host left there (SKILL.md, the executor contract's obligation 5); the host reads it as a whole token. `handed back` means the work is done and the host has not yet run the boundary; a skill-shaped guest writes it, and for `direct`, `hand` and `navigator` the host writes it. `blocked` means the executor stopped without delivering the slice — see SKILL.md, *A guest that hands back blocked*. The host closes the line to `shipped` at the boundary. |

The Attempts list is the reversibility record. Everything else about the slice is recoverable
from git; the fact that a strategy was tried and why it was abandoned is not.

**Numbering.** `NN` is assigned at planning and never reused — it names the branch. A slice
inserted mid-flight takes the next free number and sits in sequence order, so `05` may appear
between `02` and `03` in the list. Read order is the list; `NN` is an identity, not a position.

## What the record buys

Everything a rollback needs is a branch name. A slice 02 abandoned from `tdd-batch` and redone by
hand restores from `<slug>/01-<slice-slug>` — no sha anywhere, and the abandoned attempt is
still legible in the plan after the restore that produced it.
