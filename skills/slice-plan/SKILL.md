---
name: slice-plan
description: "Plans a feature as an ordered sequence of vertically sliced, independently reviewable increments, then hosts their execution while the implementation strategy is chosen separately for each slice. Use when the approach should differ slice by slice — a test-first loop for one, an agent one-shotting the next, the user writing another by hand — or when the slicing decision should be kept separate from how the code gets written. A skill that fixes one methodology for the whole feature (a TDD loop, say) is the better fit when the approach will not vary; this one exists for when it will. Maintains a strategy-agnostic plan file that outlives every attempt, so a strategy that turns out wrong rolls back to the previous slice without losing the record of what was tried."
compatibility: "Requires the design-review skill — and design-principles, which design-review itself requires — and a way to delegate a task to an isolated subagent — the slice boundary delegates a design review of the slice diff, with no bundled fallback. Requires git — reversibility across a strategy change is implemented with branches and `git restore`, and there is no fallback for a project without it. Strategies are whatever the session has available; this skill requires none of them in particular."
metadata:
  soft-deps: design-principles design-review
---

# Slice Plan

Two decisions are usually made at once and shouldn't be: **how a feature is cut into slices**, and
**how each slice gets built**. This skill owns the first and hosts the second.

Slicing is decided up front and holds for the whole feature. Strategy is chosen one slice at a
time — a test-first loop, an agent one-shotting it, the user writing it by hand — and can change at
any boundary, or mid-slice by abandoning the attempt and restoring to the previous slice.

The plan is a **host**; a strategy is a **guest**. The plan holds the feature, the criteria, the
slices, and the record of what was tried. Whatever actually builds a slice — a guest skill, you, or
the user — is its **executor**, and owes [the executor contract](#the-executor-contract).

## Plan File

Maintain a plan file at `<plans-dir>/slices-<feature-slug>.md` — see
[plan-format.md](plan-format.md) for the format, directory choice, and slug rules.

**The plan is never committed.** Setup adds its path to `.git/info/exclude`; it lives in the plans
directory for the whole feature, and Cleanup settles it. Rollback *exempts* the plan on purpose —
the record of a failed attempt has to survive the rollback that erases the attempt — and untracked
is what gets that for free: it survives every branch switch, every `git restore` and every squash
with no special handling. The exclude is not optional: guests commit with `git add -A` (`tdd` does,
every cycle), which would otherwise sweep the plan into a slice's history. `.git/info/exclude` is
local to the clone, so no tracked `.gitignore` is touched. The plan does not survive
`git clean -x`, so don't.

**Rules in Force**, the header at its top, is copied verbatim at creation and never edited. It is
the *host's* rules, read by no executor. This body is read into the conversation once, so a feature
spanning many slices dilutes it by position and a compaction can drop it; the file is on disk, and
re-reading the header puts the rules back at the end of the context. **Re-read the header plus the
Slices section at the start of every slice, at every slice boundary, and before every abandon** —
unconditionally, not when you notice you've lost track. If a resumed plan's header is missing or
differs from the fence under *The Rules in Force header* in [plan-format.md](plan-format.md),
replace **the `## Rules in Force` section alone**, verbatim, leaving every other section of that
plan untouched — the Attempts history under Slices is the record no rollback recovers.

**Write** the plan at six points at least — before the alignment gate, at Setup, on choosing a
strategy, on cutting the branch, at the slice boundary, and at an abandon — setting **Last
updated** at each, and at any other write too. Each step below says what it writes;
[plan-format.md](plan-format.md), *When the host writes*, lists them together. Which of those
fields an executor writes instead of the host is obligation 3 of
[the executor contract](#the-executor-contract); everything else is the host's.

---

## Startup

Run `find plans docs/plans .plans -maxdepth 1 -name 'slices-*.md' 2>/dev/null`, keeping the
pattern quoted and judging by the output rather than the exit status: an unquoted
`plans/slices-*.md` matching nothing makes zsh print "no matches found" and never run `find` at
all (`2>/dev/null` does not suppress that), and a missing plans directory makes `find` exit
non-zero even when it did find a plan. If that finds nothing, run
`grep -rl "# Slice Plan" plans/ docs/plans/ .plans/ 2>/dev/null` before concluding there is none —
a renamed file is still a plan file. Use `grep -r` (or `rg --no-ignore`), never a plain
ignore-aware search: the plan is in `.git/info/exclude`, so ripgrep skips it silently and you start
a second planning session over a live feature.

- **None found** — run the planning session below.
- **Exactly one** — offer to resume it.
- **More than one** — list them (feature, last-updated) and ask which, or whether to start new.

**If resuming:** read the plan; report the feature, the current slice and its position, its
strategy and attempts so far, remaining criteria and slices, and the current hypothesis; confirm
the checked-out branch matches. **Confirm the plan is still excluded** —
`git -C "$(git rev-parse --show-toplevel)" check-ignore -q <plan-path>` — and if it is not, append
it with the same one-liner Setup uses, before handing off to any guest; the next `git add -A` would
otherwise commit it. Give `<plan-path>` repo-root-relative and under the name the file actually has
now, which a rename may have changed. Without the `-C`, a repo-root-relative path checked from a
subdirectory returns a false negative and you append a duplicate line.

**If the Session block's Base branch or Test runner is still a placeholder, Setup never ran** —
and the alignment gate was never passed either, since Setup follows it. The plan on disk is a draft
the user never agreed to; it is written before the gate on purpose, so a session that ended in
between leaves exactly this. Present the feature, criteria, hypothesis and slices at the alignment
gate as if newly drafted, then run [Setup](#setup), before any of the routing below. Do not cut a
branch from a placeholder base.

**The current slice** is the first slice in list order that is not `shipped`. If every slice is
shipped, go to [Feature complete](#feature-complete) instead. The branch you expect to be on is its
own for an `in progress` slice, and the previous slice's — the base branch, for slice 01 — for a
`planned` one. If the worktree disagrees, say so and ask which is right before touching anything: a
plan and a worktree that disagree is the one state no recipe here is safe in.

Then re-enter [Running a slice](#running-a-slice) by that slice's status:

- **`planned`** — step 1, choose the strategy.
- **`in progress`** — read its **newest Attempts line**; the status alone does not say where you
  are:
  - `<strategy> — in progress` (with or without a `: <note>` the host left there) → step 3, hand
    off to the strategy already recorded and continue that line. Its branch exists and its
    strategy is chosen; re-asking either would re-cut a live branch and discard the answer.
  - `<strategy> — handed back` → **step 4, the slice boundary** — the guest already finished.
    Check first whether the squash ran, with `git log --oneline <previous-slice-branch>..HEAD`
    (`<previous-slice-branch>` is the previous slice's branch, the base branch for slice 01), and
    read the commits' **subjects**, not just the count:
    - one commit whose subject is the slice's behavior sentence → the squash ran; resume at the
      boundary's step 5;
    - one commit with any other subject → that is the guest's own work (a `direct` or `hand` slice
      is one commit by construction), or the host's own *Running a slice* step-2 update to an
      earlier slice's test, which means the guest built nothing — the boundary from step 1 in the
      first case, step 3 in the second. Counting commits alone would skip the design review and the
      user's approval and ship the slice under the guest's commit message;
    - more than one → the ordinary `tdd` handback, squash not yet run: the boundary from step 1;
    - **none at all** → the guest built nothing, or built it and never committed: re-enter at
      step 3. Re-invoking a guest with commits present would rerun a slice already built.

    The count cannot tell a re-entry from a first pass, so when you re-enter the boundary this way,
    say at its step 3 that the slice may already have been presented and this review is a re-run
    after an interruption. Do not silently ask the user to approve the same slice twice.
  - `<strategy> — blocked: …` →
    **[A guest that hands back blocked](#a-guest-that-hands-back-blocked)**. Deal with what
    stopped it first; re-invoking it on an unchanged slice stops it in the same place.
  - `<strategy> — abandoned: …` followed by a new strategy's open line → **step 3**. The branch
    already exists and the new strategy runs on it: **do not re-cut it**. The abandon appends that
    open line only after redoing the earlier-slice test update, so the branch should already be
    green — confirm the update noted on the abandoned line is present, and redo it if it is not.

**Before re-entering at step 3, check the tree is clean** — `git -C "$top" status --short`, with
`top=$(git rev-parse --show-toplevel)`. The handoff block promises the next guest a clean tree and
tells it to skip the preflight where it would have noticed otherwise, so a dead guest's uncommitted
work becomes the new guest's first `git add -A`. If anything outside the plans directory shows,
show the user the changed files and ask whether to keep them — commit them on the branch yourself
first — or discard them with the abandon recipe's restore and clean. Never hand off over a dirty
tree.

## Planning session

**First, establish the ground.** Confirm a clean working tree — stash or commit unrelated work.
Then identify the test runner and run the full suite: you need a green baseline, and any
pre-existing failure needs the user's confirmation before you plan around it. Finding a red suite
*after* the alignment gate invalidates a plan the user has already approved. Then establish four
things in order — each builds on the previous.

**1. Feature definition.** What is being built, why, for whom; what is explicitly out of scope.
Sharpen a vague definition before moving on — it produces vague criteria otherwise.

**2. Acceptance criteria.** Behavioral, specific, testable, scoped — they describe what the feature
does from the outside, and any valid implementation could satisfy them. Derive candidates if not
provided; push back on criteria that describe internals or that no observation would settle.
Present the final list for confirmation.

**3. Design hypothesis.** Feature-level only: the seams the slicing depends on — key modules, where
responsibilities divide, what each slice will find already in place. A proposal, not a declaration;
how any one slice is built internally belongs to its executor.

**4. Slice sequence.** Read [references/slicing.md](references/slicing.md) **in full** before
drafting it — the sizing test, the steel thread that opens the sequence, the splitting moves, the
anti-patterns. Do not draft from memory. For each slice: a one-sentence behavior with no "and", a
short `<slice-slug>` for its heading and branch name, and the criteria it advances — `none` for a
slice that advances none, which must then carry a `Kind` of `refactor` or `scaffolding` with a
one-sentence reason, since `Kind` decides both which strategies are legal for it and what green
means at its boundary. Record `Merge safety` on the steel thread always — `live`, or
`inert: <what makes it unreachable>` — and on any other slice that ships something unreachable.

Do not assign strategies here. Strategy is chosen slice by slice, at the moment each one starts,
when you know most about it.

**Write it down before the gate.** Steps 1–4 exist only in the conversation otherwise, and a
compaction before Setup loses the whole planning session. So now, before the gate:

1. Choose the plans directory: whichever of `plans/`, `docs/plans/`, `.plans/` exists; create
   `plans/` only if none does; ask if several do.
2. Create the plan file: the Rules in Force header copied verbatim from *The Rules in Force
   header* in [plan-format.md](plan-format.md), then the **Session block** with the feature slug
   and start date filled in and Base branch and Test runner left as their placeholders — Startup
   reads a still-placeholder value as "Setup never ran", so omitting the block resumes into the
   routing with no base branch — then the feature, criteria, hypothesis and slices.

**Alignment gate.** Present the feature, criteria, hypothesis, slice sequence, and the proposed
slug — permanent, and it names the plan file and every branch. Ask: *"Are we aligned? Shall I
proceed?"* Do not start slice 01 until confirmed.

If the gate changes the slug, rename the file — it names every branch too. If the user declines
the gate outright, delete it, or Startup finds it next session and offers to resume a feature
that was never agreed.

### Setup

1. Record the test runner command **and** the base branch — what slice 01 is reviewed against —
   in the plan, in one write. Both are placeholders until now, and the resume path reads either
   one still being a placeholder as "Setup never ran"; filling them separately opens a window
   where a resume re-presents an alignment gate the user already approved.
2. **Exclude it from git**:
   `printf '%s\n' "<plans-dir>/slices-<feature-slug>.md" >> "$(git rev-parse --git-path info/exclude)"`.
   A guest's `git add -A` would otherwise commit it. `--git-path` resolves correctly from a
   subdirectory and in a linked worktree, where `.git` is a file. Confirm with
   `git status --short` — the plan should not appear at all.
3. Cut no branch here: slice 01's is cut at step 2 of Running a slice, *after* its strategy is
   chosen, like every other slice's.

---

## Running a slice

### 1. Choose the strategy

Re-read the Rules in Force header and the Slices section first.

**Ask the user which strategy this slice gets.** Check which of the skill-shaped ones this session
actually has before recommending any, then offer one recommendation with a line of reason — the
slice's shape is the evidence.

| Strategy | Shape | Suits a slice that |
|---|---|---|
| `tdd` | skill | is over unproven ground, or where the design *is* the question — one test at a time surfaces it earliest. Never a `refactor`/`scaffolding` slice |
| `tdd-batch` | skill | has a clear batch of behaviors and a known shape, where per-test pacing is overhead. Never a `refactor`/`scaffolding` slice |
| `direct` | you, directly | is one obvious edit, or scaffolding whose design carries no risk |
| `hand` | the user writes it | the user wants to write themselves — for the learning, or because they hold context you don't |
| `navigator` | skill; the user still writes | the user writes it and wants an agent coaching, questioning direction and catching skipped steps rather than sitting silent |

**A test-first guest is not a legal strategy for a slice whose `Kind` is `refactor` or
`scaffolding`.** Its loop opens with a failing test for new behavior and such a slice has none to
write: a test of the restructured behavior passes the moment it is written, which its own rules say
to delete, and a test of the new internal structure is the internals-testing they forbid. Offer
`direct`, or `hand`/`navigator` if the user wants to write it — and do not list a test-first guest
as a second option. If the user asks for one anyway, say what will happen — no legal first move, so
it hands back `blocked` without running a cycle and you abandon it to `direct`, having paid for a
guest that built nothing — and let them choose with that in front of them.

`hand` and `navigator` both mean the user writes the code; the difference is whether anyone is
watching. Record the answer in the slice's **Strategy** field and open its first **Attempts** line,
both before any code exists. Do not carry the previous slice's strategy forward silently, and do
not pick a default when the user hasn't answered: per-slice choice is the reason this skill exists.

### 2. Cut the branch

`git switch -c slice/<feature-slug>/NN-<slice-slug> <previous-slice-branch>` — naming the start
point rather than trusting `HEAD`.

**`<previous-slice-branch>` means the previous slice's branch** — the base branch, for slice 01.
Every slice before the current one has shipped, so there is only ever one candidate — except
where a slice was dropped after its branch was cut; that branch is left behind and is never a
base.

**The plan owns branch naming**, not the strategy. A strategy that names branches itself has to
be told this one, because the abandon recipe restores from it by name.

**Then, before handing off, update any earlier slice's test this slice invalidates — yourself, on
this branch.** Read the behavior sentence against the tests earlier slices left: if delivering it
makes one of them assert something no longer true, that test is yours to change, because no
executor can both deliver the behavior and leave the suite green. Change the **fixture**, not the
expectation, wherever you can — an earlier test edited down to agree with the new behavior stops
pinning its own slice's rule and starts double-pinning this one under its old name. Get to green,
**commit the change on this branch** — the handoff promises the guest a clean tree, and the squash
collapses the commit into the slice's one — and note what you changed on the slice's Attempts line,
where the guest is told to leave it standing.

This should be rare: [references/slicing.md](references/slicing.md), §"A thread's test must survive
being thickened", says an earlier test should have been written to survive thickening, so one that
does not is usually over-specified rather than genuinely superseded — say so to the user in a
sentence, because the next slice will hit it again.

Then **set the slice's status to `in progress`** before handing off. That status asserts the branch
now exists: a slice still marked `planned` sends a resume back to step 1 to re-ask the strategy and
re-cut a branch that is already there. The plan is untracked and stays that way; the only commit
this step can produce is the earlier-test update above.

**To drop a slice**, delete it from the plan — ordinary re-slicing while it is still `planned`. If
its branch is already cut, abandon the attempt first; the branch is left behind and the next slice
cuts from the same `<previous-slice-branch>` this one did.

### 3. Hand off

State to the executor — the guest, yourself, or the user — the slice's behavior sentence, the
criteria it advances, the branch, and the obligations of
[the executor contract](#the-executor-contract) in the form that executor's shape takes, per
*Which shape carries which obligation*. Then:

| Strategy shape | Handoff |
|---|---|
| A skill (`tdd`, `tdd-batch`, `navigator`, …) | Invoke it with the override block from [references/hosted-handoff.md](references/hosted-handoff.md), filled in. Each of these skills plans a whole feature by default and will re-plan, re-branch and re-ship this slice without it. |
| You, directly (`direct`) | Build the slice. Nothing else is prescribed — the obligations are the whole spec. |
| The user, by hand | Say what the slice is and that the branch is cut, then stop and wait. Do not write code for a slice the user has taken. |

**What the host carries for `direct`, `hand` and `navigator`** — the executor there cannot write
the plan, and for the latter two was handed no contract at all:

- **Close the Attempts line yourself.** When the work is done and the suite is green, set it to
  `<strategy> — handed back`, or `<strategy> — blocked: <what stopped it>` if it could not be
  finished. Leave it open and a resume routes back to step 3 — which for `direct` means rebuilding
  a slice you already finished.
- **For `hand` and `navigator`, first confirm the work is committed on the branch, and commit it
  yourself if it is not** — `git -C "$(git rev-parse --show-toplevel)" status --short` and
  `git log --oneline <previous-slice-branch>..HEAD`. This is obligation 4, which the user never
  received and `navigator` by its own rules will not do. A finished slice left in the worktree
  fails the boundary's squash with "no changes added to commit", and a resume reads zero commits as
  a slice never built. Committing work the user finished is not writing code, so the rule that a
  hand slice is theirs does not bar it — say that you are doing it.

**Run a skill-shaped guest in a delegated subagent wherever the session supports it** — a delegated
slice comes back as a result instead of as context. Keep it in-session when delegation isn't
available, when it is `navigator` and the user needs to watch it work, **or when you expect to want
the abandon**, which a delegated guest puts out of reach. The trade-off in full, and the disk
checks that replace watching a guest work, are in
[references/hosted-handoff.md](references/hosted-handoff.md) — *Delegated or in-session*,
*Reading the result*.

### The guest's state file

The plan needs no handling at a transition — it is excluded and untracked throughout. A
skill-shaped guest's state file does: `tdd` and `tdd-batch` keep one in the plans directory and
commit it every cycle, so it is tracked. **At both transitions off a slice — the boundary and an
abandon — drain anything worth keeping out of it into the plan, then remove it**, at the boundary's
step 6 and, in the abandon, as its first action — the `git rm -f` at the top of the bash block,
before the restore, so the reversion commit carries the deletion away. Do not add it to the
exclude. The full rules, including the guest whose artifact lives outside the repo, are in
[references/hosted-handoff.md](references/hosted-handoff.md), *The guest's state file*.

Every recipe here uses `top=$(git rev-parse --show-toplevel)` with repo-root-relative paths.
Pathspecs follow the working directory, so from a subdirectory a bare one silently matches
nothing and the transition ships or destroys the wrong files.

### The executor contract

**This section is the contract's single source.** Every obligation an executor owes is stated here,
in full, and nowhere else. It has exactly one other rendering: the override block in
[references/hosted-handoff.md](references/hosted-handoff.md), which restates these five obligations
as five numbered paragraphs in the same order, in the guest's voice, and is the only form of the
contract a skill-shaped guest ever reads. Change an obligation here and change its paragraph there
in the same edit; a block with fewer than five numbered paragraphs has lost one, which is what the
numbering is for.

Whatever runs a slice owes exactly five things:

1. **Stay on the branch the host cut**, and create no others.
2. **Leave the suite green at the boundary, with a passing test for the slice's behavior.**
   Green mid-slice is a checkpoint; green at the boundary is the precondition for the next slice's
   rollback to mean anything. The test is not optional even for `direct`: the boundary ticks an
   acceptance criterion only where a passing test satisfies it. **For a slice whose `Kind` is
   `refactor` or `scaffolding`** the obligation is instead that the existing suite stays green over
   the restructured code — no new behavior, so no new test and no criterion to tick. That carve-out
   is the only one. There is none for an earlier slice's test: the host updates any this slice
   invalidates before handing off, at step 2 of Running a slice, so an executor never meets a red
   suite it did not cause. If one turns up anyway it hands back **blocked**, changing no test and
   never handing back red.
3. **Write only its designated plan fields, and build only its own slice.** The fields are its
   slice's Attempts line, hypothesis deltas that change a later slice, and backlog items, the last
   in its own state file instead if it keeps one with a backlog of its own. The host owns Strategy,
   statuses, criteria and every other slice — including the *work* of every other slice: a
   restructuring the plan has already given to a later slice is not this executor's to do, however
   much its own refactoring step wants it. Log it and move on; doing it here empties that slice.
4. **Commit its work on that branch.** The boundary squashes *commits*, not worktree state. An
   uncommitted slice leaves the branch zero commits ahead of `<previous-slice-branch>` and the
   squash's `git commit` fails — "no changes added to commit", or "nothing added to commit but
   untracked files present". The work is in the worktree, but nothing has been built as far as the
   boundary can see.
5. **Hand back before the squash**, with a green suite and no boundary review, PR or squash of its
   own. The plan owns all three; a strategy that runs its own asks the user to approve the same
   work twice.

Obligations 2 and 4 describe a *finished* slice. **The one sanctioned way not to finish one is to
hand back `blocked`**, and there is no other: the executor stops, gets the suite back to green
(reverting or simply not committing whatever turned it red), commits whatever complete work it has
or nothing if there is none, sets its Attempts line to `<strategy> — blocked: <what stopped it>`,
and says the same when it hands back. A slice that needs splitting, an earlier slice's test that
needs changing after all, and a strategy whose own rules leave it no move here are all this one
outcome. The host owns what happens next:
[A guest that hands back blocked](#a-guest-that-hands-back-blocked).

#### Which shape carries which obligation

All five are owed on every slice; what changes with the executor's shape is who carries each and
how it is delivered. A skill-shaped guest reads it in the block; for the other shapes you say it or
you carry it yourself. Where an obligation cannot bind the executor it does not lapse — it becomes
the host's. `navigator` is skill-shaped but the *user* executes, so it belongs in the third column
and its block is adapted to match (see the reference's *Adapting it for `navigator`*).

| | A skill-shaped guest | `direct` — you are the executor | `hand` / `navigator` — the user is |
|---|---|---|---|
| **1** branch | In the block. | Yours: you cut it, so stay on it and cut no other. | Tell the user the branch is already cut and that they need create none; at the boundary, check none appeared — `git branch --list`. |
| **2** green + test | In the block. | Yours, test included — a behavioral slice you build yourself still ships a passing test. | This is the bar the user's work has to meet: say so when you hand the slice over, and confirm it yourself at the boundary's step 1. A hosted `navigator` is told to coach to it. |
| **3** own fields, own slice | In the block; the guest writes its own Attempts line. | Yours — though as host you write the rest of the plan anyway. | The plan-fields half does not bind: the user writes no plan fields at all, and `navigator`'s own rules forbid it writing anything but its session file, so **you** write that Attempts line (see *Hand off*). The scope half still applies to the user — state the slice's behavior sentence when you hand it over, so a later slice's work does not get done here. |
| **4** commit | In the block. | Yours. | The user was handed no contract and `navigator` commits nothing by its own rules, so **you** carry it: before writing the `handed back` line, confirm the work is committed on the branch and commit it yourself if it is not (see *Hand off*). |
| **5** hand back before the squash | In the block. | There is no hand-back *act* — you are the host — but you still write the `direct — handed back` line yourself (see *Hand off*). It binds you as: no squash, no review, no PR until the boundary's own steps run, in order. | The user stops and says the slice is done; you run the boundary from there. A hosted `navigator` is told to run no review and no squash of its own. |

### 4. The slice boundary

Re-read the Rules in Force header and the Slices section. Then:

1. Confirm the suite is green and the slice's behavior is actually observable — for a slice whose
   `Kind` is `refactor` or `scaffolding`, that behavior is *unchanged* and the suite proves it.
   A red suite here is not a boundary: if the guest handed back `blocked`, go to
   [A guest that hands back blocked](#a-guest-that-hands-back-blocked); if it handed back red
   anyway, treat that as `blocked` and read it there too.
2. **Delegate a design review to a fresh subagent.** Resolve `git rev-parse --show-toplevel`
   **yourself, first**, and paste the resulting absolute path into the prompt — tell it to invoke
   the `design-review` skill over
   `git -C <absolute-repo-path> diff <previous-slice-branch>...HEAD -- . ':(exclude)<plans-dir>/'`
   (the base branch, for slice 01). Never send `$(git rev-parse --show-toplevel)` unexpanded: the
   subagent's shell evaluates it in its *own* working directory, possibly an entirely different
   repository, and `design-review` returns a confident, well-formed report about code you did not
   write. **State that absolute path as the subagent's working directory** and tell it to run every
   git command and file read there. Focus it on the statement, name, function and class altitudes —
   one slice is too small for component-level findings. The host owns this review, never the guest.
   The `:(exclude)` hides the plans directory wholesale, so a project document this slice
   legitimately changed goes unreviewed too — mention it at step 3 if so. The diff also carries any
   earlier-slice test you updated at step 2 of Running a slice: leave it in, as this is the only
   second pair of eyes that change gets.
   **You triage the result** — fix what is cheap while the suite is green, **committing the fixes
   on the branch** (step 4 squashes *commits*, so an uncommitted fix is dropped from the shipped
   commit and left dirty for the next slice), and turn the rest into named backlog entries.
   **Triage is scoped to this slice's own diff, and cheapness is not the only test.** Two findings
   are backlog entries however cheap, and the reviewer — a fresh subagent that cannot see the plan
   — will rank both highly: one that wants an earlier slice's or the steel thread's test tightened
   to assert exactly the current output (that test pins the seam, not the content; tightening it
   deadlocks the next slice — [references/slicing.md](references/slicing.md), §"A thread's test
   must survive being thickened"), and one that asks for behavior this slice does not have, such as
   a missing error path (*Kitchen sink*, same file). Never present the slice untriaged.
3. Present the slice for review and stop. This is where the user rejects the slicing, reorders
   what's left, redirects the design, or calls the feature done early — far cheaper here than
   three slices later.
4. On approval, squash the slice to one commit, dropping the plan file from it. **First confirm the
   tree is clean**: `git -C "$(git rev-parse --show-toplevel)" status --short` should show nothing
   outside the plans directory. `reset --soft` stages only what was committed, so anything else
   there is work the squash drops and leaves dirty for the next slice to sweep into its history.

   **Before resetting, read the guest's state file for a `Learned` line from this slice's work** (a
   skill-shaped guest's refactor checklist sends decision context there instead of a PR description
   it was forbidden to write — see `references/hosted-handoff.md`, *The guest's state file*). Skip
   this for a `direct` or `hand` slice, which keeps no such file. "No surprises" or empty is nothing
   to carry; anything else becomes a second `-m` below.

   ```bash
   top=$(git rev-parse --show-toplevel)
   git -C "$top" reset --soft <previous-slice-branch>
   git -C "$top" reset -- <plans-dir>/     # unstage the guest's state file
   git -C "$top" commit -m "<behavior sentence>" -m "<Learned line, if any>"
   ```

   The `reset -- <plans-dir>/` unstages the guest's committed state file so it does not ship to the
   reviewer; the plan was never tracked and needs nothing. It unstages the *whole* directory, so if
   this slice legitimately changed a project document living there, re-stage that file by name
   before committing — otherwise the change is silently dropped from the shipped commit and left
   dangling in the worktree. Keep the `-C` and give `<plans-dir>` repo-root-relative: from a
   subdirectory a bare `git reset -- plans/` matches nothing, **exits 0 and prints nothing**, and
   the guest's session notes go straight into the PR. Add a further
   `-m "<what is deliberately not here>"` only when the slice has an `inert:` Merge safety line.
5. Update the plan: mark the slice `shipped`, close its attempt line, tick any criteria a passing
   test now satisfies, record hypothesis changes and backlog items, and set **Last updated**.
6. **Delete the guest's state file** per [The guest's state file](#the-guests-state-file),
   draining anything worth keeping into the plan first. Delete only the guest's own file — the
   plans directory is whichever one the repo already had, so it routinely holds project documents
   nothing to do with this feature. One left behind is found by the *next* slice's guest, whose
   startup globs for exactly that filename and offers to resume slice 01's finished plan.
7. **If this was the steel thread, re-slice the rest before continuing** — re-read
   [references/slicing.md](references/slicing.md) and walk the remaining plan against what the
   thread found. Every slice behind it was drawn before those findings existed.

Then start the next slice at step 1 — including the strategy question.

### A guest that hands back blocked

`<strategy> — blocked: <what stopped it>` means the executor stopped without delivering the slice.
It is not a boundary — the behavior is not there — and it is not yet an abandon; the strategy may
be fine. Re-read the Rules in Force header and the Slices section, read the reason, and take
exactly one of three:

- **A precondition you own.** Most often an earlier slice's test this slice invalidates that you
  did not catch at step 2. Do what step 2 says — change it on this branch, fixture first, get to
  green, commit, note what you changed. Then hand off again at step 3. The blocked line stays
  closed where it is; a re-invocation is a new attempt, so append a fresh
  `<strategy> — in progress` line below it.
- **The slice is too big, or is two slices.** Re-slice: narrow this slice's behavior sentence to
  what is green and coherent now, move the rest to a new slice immediately after it, and re-read
  [references/slicing.md](references/slicing.md). Surface the re-slice to the user. Then go to the
  boundary if the narrowed slice is already delivered, or append a new `<strategy> — in progress`
  line and hand off again if it is not.
- **The strategy has no move on this slice** — a test-first guest on a `refactor` slice is the
  standing example. That is an abandon: propose it and follow the recipe below.

Do not re-invoke the same guest on an unchanged slice; it stops in the same place, having thrown
its first attempt away.

### Abandoning a strategy

Re-read the Rules in Force header and the Slices section before any of this. The restore rewinds
past the earlier-test update you made at *Running a slice* step 2, so re-doing it is part of the
recipe.

Abandon when the strategy itself is wrong for the slice — whether you concluded that yourself or a
guest handed back `blocked` saying so, which is evidence and not the decision. **Propose it and
wait for the user's confirmation**: the recipe throws away uncommitted work and runs `git clean`,
and judging a strategy a bad fit is the call this skill exists to leave with them.

Once confirmed, follow *Abandoning an attempt* in [plan-format.md](plan-format.md), in that order:
drain and delete the guest's state file, restore the worktree from the previous slice's branch,
commit the reversion the restore stages, redo the earlier-slice test update the restore rewound,
and only then close the abandoned Attempts line and set the new strategy — the plan write is last
because the new strategy's open line is what a resume reads as "ready for step 3". The
reversion is committed, not left in the index, so the replacement strategy inherits the genuinely
clean tree the handoff block promises it. The plan is untracked, so the restore never touches it —
the record of the attempt survives the rollback that erases the attempt, which is the whole
mechanism. Do it as one uninterrupted step; there is no half-abandoned state to resume from.

---

## Feature complete

Declare it when every slice is `shipped`, every acceptance criterion is ticked by a passing test,
and the backlog is drained — each item fixed, dismissed with a reason, or carried somewhere the
user names. **An item that needs a change to tracked code is not fixed here: it is a new slice**,
appended to the plan and run through Running a slice like any other — strategy, branch, boundary,
review — which un-declares the feature until it ships. Never an amendment to a slice already
squashed and presented, at any size; that slice's review is spent.

Report the slice sequence as delivered, the strategies each slice ended up using, and every
abandoned attempt with what entangled it — the abandoned attempts are the part worth reading, being
what the feature taught about which approach suits which slice. Then run Cleanup.

## Cleanup

1. **Report the branch stack** — each slice's branch and its base — and offer to restack
   (`git rebase --onto <new-base> <old-base> <branch>`, from the bottom up) if an earlier slice was
   amended or merged after a later one was cut off it. Name separately any branch left behind by an
   abandoned slice later deleted from the plan; nothing is based on it.
2. **Pushing and opening PRs is the user's call.** This skill produces a stack of local branches
   and stops there. Ask before publishing any of it.
3. **Settle the plan file.** It is untracked, as it has been all along. Offer to delete it — and
   only then, open the exclude file (`"$(git rev-parse --git-path info/exclude)"`) and delete that
   one line, leaving every other pattern alone. If the user keeps the plan for the record of which
   strategy suited which slice, **leave the exclude in place** or move the file out of the repo:
   stripping the exclude from a file that stays hands the next feature's guest, on its first
   `git add -A`, a plan file to commit.
