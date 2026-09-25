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
  permanent and also names the branches (`slice/<feature-slug>/NN-<slice-slug>`).

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
- Strategy is chosen per slice, before its branch is cut, and recorded before any code.
- Before handing off, update any earlier slice's test this slice invalidates — yourself, on this
  branch, fixture first, committed. No executor may touch one.
- State the executor's obligations at every handoff, in the form that executor's shape takes.
- To abandon — **propose it and get the user's confirmation first** — drain and delete the guest's
  state file, restore from the previous slice's branch, clean new files, commit the reversion, redo
  the earlier-test update, then close the attempt line with what entangled. One uninterrupted step.
- An attempt's line is closed in place, never removed and never duplicated.
- **The plan is never committed** — path in `info/exclude`. Never `git add` or `clean -x` it.
- Branch names only, never a commit sha: the squash rewrites them.
- The feature hypothesis is the plan's; a slice's internal design is the executor's.
- A slice the user has taken by hand is theirs — write no code in it; close its attempt line and
  confirm its work committed yourself.
- No boundary over a red suite. Review, then present; squash only on the user's approval.
```

## The rest of the file

A template, filled in as you go — not copied verbatim. **Write the Session block at creation,
along with the header**, with the feature slug and start date filled in and Base branch and Test
runner left as the placeholders below: SKILL.md, *Startup*, reads a still-placeholder value as
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
- **Strategy**: tdd-batch
- **Attempts**:
  - tdd-batch — shipped

### 02 — <slice-slug> — in progress
- **Behavior**: <one sentence, no "and">
- **Advances**: AC1, AC3
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
- **The slice boundary** — slice status, its `Attempts` line closed, criteria ticked, hypothesis
  changes, and backlog items.
- **An abandon** — the abandoned `Attempts` line and the new strategy.

These six are the scheduled writes, not the only ones: the blocked path appends a fresh attempt
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
| Merge safety | Present on the steel thread always — `live`, or `inert: <what makes it unreachable>` — and on any other slice that ships something unreachable. Decided when the slice is planned; an `inert:` value is what the squash message says is deliberately not there. |
| Attempts | An indented list, one line per attempt, never removed; `none yet` is the placeholder for a slice with no strategy chosen and is replaced by the list at the first attempt. A line is **closed in place** as its state changes — `in progress` → `handed back`, `shipped`, `blocked: …`, or `abandoned: …`; only a genuinely new attempt adds a line. Values: `<strategy> — <in progress \| handed back \| shipped \| blocked: <what stopped it> \| abandoned: <what entangled>>`. `in progress`, `handed back` and `shipped` may carry a `: <note>` — used to record an earlier slice's test the host updated on this branch before handing off; `blocked` and `abandoned` already spend their colon, so their note goes in that text. A guest may also add the whole tokens `reviewed` and `suite green at <sha>` to a `handed back` line, comma-separated after any note the host left there (SKILL.md, the executor contract's obligations 2 and 5); the host reads them as whole tokens. `handed back` means the work is done and the host has not yet run the boundary; a skill-shaped guest writes it, and for `direct`, `hand` and `navigator` the host writes it. `blocked` means the executor stopped without delivering the slice — see SKILL.md, *A guest that hands back blocked*. The host closes the line to `shipped` at the boundary. |

The Attempts list is the reversibility record. Everything else about the slice is recoverable
from git; the fact that a strategy was tried and why it was abandoned is not.

**Numbering.** `NN` is assigned at planning and never reused — it names the branch. A slice
inserted mid-flight takes the next free number and sits in sequence order, so `05` may appear
between `02` and `03` in the list. Read order is the list; `NN` is an identity, not a position.

## Abandoning an attempt

Abandon when the strategy itself is wrong for the slice: it keeps throwing its own work away, or
what the slice needs is plainly a different shape of work than the strategy delivers. One failed
attempt at something *inside* a strategy is that strategy's own business. Propose the abandon and
get the user's confirmation before running any of the below.

**First** drain anything worth keeping out of the guest's state file into this plan, and remove
it with the `git rm -f` in the block below — a guest that committed at least once has that file
tracked (`tdd` and `tdd-batch` commit theirs every cycle), and staging its deletion here is what
lets the reversion commit at the end of the block carry it away, leaving no residue. Use a plain
`rm` **only** where the guest never committed at all, in which case the file is untracked and
`git rm` fails with `pathspec … did not match any files`. (A guest whose artifact lives outside
the repo keeps it — see `references/hosted-handoff.md`, *The guest's state file*.) The destination
for a short drain is the Attempts line you are
about to close — the reason the attempt failed belongs in its `abandoned: <what entangled>` text,
so write it there now rather than carrying it in your head across the restore; anything longer
goes in the Backlog or the Design Hypothesis. **Then** restore the worktree to the previous
slice's branch, remove new files, and commit the reversion the restore stages. Commits on the
current branch stay; the squash at ship collapses them all away.

**Derive `<source dirs>` rather than recalling them.** Run `git -C "$top" status --short` first
and take every untracked path outside the plans directory — a delegated guest is invisible while
it works, so a top-level directory it created is one you never saw appear and will not think to
name. `status --short` prints a mix of files and collapsed directories, so pass the **containing
directory** of each path it lists, not the paths themselves: a second stray file in a directory
`status` collapsed is otherwise left behind. **If the list comes out empty — the normal case when the executor committed its work — skip the
`clean` entirely.** `git clean -fd --` with nothing after the `--` has no pathspec to limit it and
cleans the whole repo, including untracked files in the plans directory that are nothing to do
with this feature. There is nothing to clean when nothing is untracked; run no command rather
than an unbounded one. **Except for a path at the repo root, where you pass
the path itself** — its containing directory is `.`, and `.` is never a member of `<source dirs>`,
nor is the plans directory: `git clean -fd -- .` deletes every untracked project document in the
plans directory, which is whichever one the repo already had and routinely holds documents nothing
to do with this feature. Then **show the derived list before it executes** — run
`git -C "$top" clean -fdn -- <source dirs>` and read what it would remove; the list is derived, not
recalled, and this is the last point at which a wrong entry is still harmless. Keep `-n` before the
`--`: after it, `-n` is a pathspec and the clean is real. Then:

```bash
top=$(git rev-parse --show-toplevel)
git -C "$top" rm -f -- <plans-dir>/<guest's state file>   # if it kept one and committed it
git -C "$top" restore --source=<previous-slice-branch> --staged --worktree -- . ':(exclude)<plans-dir>/'
git -C "$top" clean -fdn -- <source dirs>   # dry run: read this list before the next line
git -C "$top" clean -fd -- <source dirs>
git -C "$top" diff --cached --quiet || git -C "$top" commit -m "revert abandoned <strategy> attempt"
```

`<previous-slice-branch>` is the branch this slice was cut from — the base branch for slice 01.
The plan is untracked, so `restore` would not touch it either way; the exclusion is there so that
a guest state file you have *not* yet drained is not silently deleted by the restore. Drain first
and the exclusion costs nothing.

Give `<plans-dir>` and `<source dirs>` as repo-root-relative paths and keep the `-C`: pathspecs
follow the working directory, so from a subdirectory the restore either fails loudly —
`error: pathspec '.' did not match any file(s) known to git`, from a subdirectory holding no
tracked files — or is silently partial, from one that does, with the exclusion no longer matching.
The silent case is the one that loses the record, and it is the one you get from `src/`.

`<source dirs>` is whatever that derivation produced — typically directories the strategy wrote
code into, plus any repo-root file named as itself. It is never recalled from memory, never `.`,
never the plans directory, and when it is empty the `clean` does not run at all. A directory the guest created and you did not
name survives the clean, which is how abandoned code reaches the replacement strategy's first
`git add -A`. The exclude means `clean -fd` would spare the plan anyway, but `clean -fdx` does not,
and nothing here needs to touch that directory.

**`clean -fd` also spares ignored build output, by the same design.** The abandoned attempt's
compiled or generated artifacts — `__pycache__/`, `dist/`, `target/`, `.next/` — are still on disk
with their sources gone. Harmless where the toolchain invalidates by source hash, load-bearing
where it caches by path. Check for them after the clean and remove those by name; do not reach for
`-x`, which would take the plan with them.

If the guest had committed at least once, the restore stages the reversion of its code and the
block's last line commits it, so **nothing is staged afterwards** — and the squash at ship
collapses that commit away like the guest's own. Do not leave the reversion sitting in the index
instead: it is the only thing undoing the abandoned attempt's *committed* code, the replacement
guest is told the tree is already clean and to skip the preflight that would notice, and a guest
that tidies what looks like a dirty start discards it — after which the abandoned code ships
inside the squash, never reviewed as part of the slice. If the guest never committed, nothing was
staged and the commit is skipped; that is the expected result, not a failed restore. First-cycle
abandons are the common case, so this is the one you will usually see.

Either way, re-check `git -C "$top" status --short` afterwards: it should print **nothing at all**
outside the plans directory — no `??`, and nothing staged. A leftover `??` path is a directory the
clean missed, not a failed restore — clean it and re-check before going on.

**Then redo the earlier-slice test update** that *Running a slice* step 2 (SKILL.md) made on this
branch. The restore goes back to the previous slice's branch, which is *before* the host committed
that update — so it is gone, and the handoff block promises the next guest it starts green. The
note on the Attempts line you are about to close is the surviving record of what it was. Re-apply
it, get to green, and commit it on this branch.

**Only then**, on the restored tree, write the plan — no commit, it is untracked:

1. **Close the strategy's open Attempts line** in place, setting it to
   `<strategy> — abandoned: <what entangled>`. Do not append a second line and leave the
   `in progress` one standing — a stale open line reads as an attempt still running, and the
   resume path reads the newest line to decide where to re-enter.
2. Set the slice's **Strategy** to the new one and append `<new-strategy> — in progress`. **This
   line is written last, after the redo above**, and that order is load-bearing: it is what the
   resume path (SKILL.md, *Startup*) reads as "the branch is ready for a new strategy, go to
   step 3". Written before the redo, it routes a session that ends in between straight into a
   handoff over the red suite the block promises the guest it will not meet.

Then start the new strategy. Its state file is created fresh.

## What the record buys

Everything a rollback needs is a branch name. A slice 02 abandoned from `tdd-batch` and redone by
hand restores from `slice/<slug>/01-<slice-slug>` — no sha anywhere, and the abandoned attempt is
still legible in the plan after the restore that produced it.
