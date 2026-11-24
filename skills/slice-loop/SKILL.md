---
name: slice-loop
description: "Builds an agreed slice-plan plan one PR at a time: chooses the implementation strategy separately for each PR — a test-first guest skill, the agent directly, the user by hand — cuts a stacked branch per PR, hands it to that executor, reviews and squashes it at the boundary, runs the full suite in the background, and rolls back a strategy that proves wrong without losing the record of what was tried. Use when there is an agreed slices-*.md plan to build, or the user asks to build, execute or continue a sliced plan. Does not plan: with no agreed plan, use slice-plan first."
compatibility: "Requires slice-plan — it reads its plan format and slicing doctrine, and builds only a plan it agreed. Requires design-review (and design-principles) and subagent delegation, for the boundary's design review of the PR diff; pin-impacted-flows, which lays and re-checks each PR's regression net; and git, whose branches and `git restore` make a strategy change reversible. Strategies: whatever the session has."
metadata:
  soft-deps: slice-plan design-principles design-review pin-impacted-flows
---

# Slice Loop

Build an agreed plan, one PR at a time. The plan says **what** each PR is; this skill decides **how
each gets built**, one PR at a time — a test-first guest, you directly, the user by hand — and can
change that at any boundary, or mid-PR by abandoning the attempt and restoring to the previous PR.

The loop is a **host**; a strategy is a **guest**. Whatever builds a PR — a guest skill, you, or
the user — is its **executor**, and owes [the executor contract](references/executor-contract.md),
read at every handoff.

Each entry in the plan's `## PRs` list is a **PR**: usually a slice of deliverable behavior,
sometimes — where its `Kind` says `refactor` or `scaffolding` — a change that isn't.

## Files

- **The plan** — written by `slice-plan`, in the format of its `plan-format.md`. `slice-plan` is a
  sibling of this skill's directory: read `../slice-plan/plan-format.md` and
  `../slice-plan/references/slicing.md` directly, relative to this file, and never invoke the
  `slice-plan` skill — it would start a planning session of its own. **You write to the plan only
  to re-slice** (*Re-slicing*, below).
- **The ledger** — this skill's own record, at `<plans-dir>/loop-<feature-slug>.md`, in the format
  of [ledger-format.md](ledger-format.md): strategies, attempts, suite runs, ticked criteria,
  backlog. It outlives every attempt, which is what lets a strategy change.
- **Reports** — `<plans-dir>/handback-<feature-slug>-<NN>.md`, written by a guest when it hands
  back, copied into the ledger, then deleted.

**None of the three is ever committed.** Setup adds each to `.git/info/exclude` — the plan is
already there. Untracked is the point: the record of a failed attempt has to survive the rollback
that erases the attempt, and untracked gets that for free, through every branch
switch, `git restore` and squash. Guests commit with `git add -A`, so the exclude is not optional.

**Rules in Force**, the header at the top of the ledger, is copied verbatim at creation and never
edited. This body is read into the conversation once, so a plan spanning many PRs dilutes it by
position and a compaction can drop it; the ledger is on disk, and re-reading the header puts the
rules back at the end of the context. **Re-read the *re-read set* — the header, the ledger's PR headings
plus the current PR's entry, and the plan's PRs section — at the start of every PR, at every
boundary, and before every abandon**, unconditionally. Earlier PRs' entries only grow; read them
in full at resume. If a resumed ledger's header is missing or differs from the fence in
[ledger-format.md](ledger-format.md), replace **the `## Rules in Force` section alone**, verbatim,
leaving every other section untouched — the Attempts history is the record no rollback recovers.

Write the ledger at each point [ledger-format.md](ledger-format.md), *When the host writes*, lists,
setting **Last updated** each time.

Every recipe here uses `top=$(git rev-parse --show-toplevel)` with repo-root-relative paths.
Pathspecs follow the working directory, so from a subdirectory a bare one silently matches nothing
and a transition ships or destroys the wrong files.

---

## Startup

Run `find plans docs/plans .plans -maxdepth 1 \( -name 'loop-*.md' -o -name 'slices-*.md' \) 2>/dev/null`
exactly — patterns quoted, judged by output, not exit status. Never an ignore-aware search: these
files are all in `.git/info/exclude`, so ripgrep skips them silently.

- **A ledger** — read [references/resume.md](references/resume.md) and follow it before anything
  else. With several, list them (feature, last updated) and ask which. If the user is bringing
  review comments on a shipped PR, see [Review comments](#review-comments-on-a-shipped-pr) instead.
- **No ledger, a plan with `Status: agreed`** — offer to build it: run Setup. With several, ask
  which.
- **Only `drafting` plans, or none** — there is nothing agreed to build. Send the user to
  `slice-plan`, and plan nothing yourself.

## Setup

1. **Read the plan** — confirm `Status: agreed`, and read its Feature, Acceptance Criteria,
   Constraints and PRs.
2. **Establish the ground.** Confirm a clean working tree — stash or commit unrelated work. Identify
   the test runner and run the full suite: PR 01's rollback rests on a green baseline. A
   pre-existing failure is the user's call — proceed around it, or stop. The plan does not change
   either way.
3. **Confirm the base branch** — what PR 01 is cut from and reviewed against; normally the current
   branch.
4. **Create the ledger**, in one write: the Rules in Force header copied verbatim from
   [ledger-format.md](ledger-format.md), the Session block complete, and the Criteria section
   listing every criterion ID from the plan, unticked. A ledger exists only once Setup has run, so
   resume never meets a half-set-up one.
5. **Exclude the ledger and the reports from git:**
   `printf '%s\n' "<plans-dir>/loop-<feature-slug>.md" "<plans-dir>/handback-<feature-slug>-*.md" >> "$(git rev-parse --git-path info/exclude)"`.
   Confirm with `git status --short` — the ledger should not appear.

---

## Running a PR

**The current PR** is the first PR, in the plan's list order, that the ledger does not record as
`shipped`. A PR with no ledger entry has not started.

### 1. Choose the strategy

Re-read the re-read set first.

**Ask the user which strategy this PR gets, and put the PR in front of them first** — they have
not memorized the plan or the ledger. The question opens with a brief, a few lines, from the plan
and ledger as they stand:

- `PR NN of <total> — <pr-slug>`, and what shipped just before it (`none yet` for PR 01).
- Its **Behavior**, **Kind** and **New** lines, quoted.
- Its **Advances** criteria — each ID *with its text* from the plan; a bare ID is the thing they
  would have to look up.
- Any earlier **Attempts** on this PR, with how each closed — after an abandon, this is why you
  are asking again.

Then check which skill-shaped strategies this session actually has, and give one recommendation
with a line of reason — the PR's shape is the evidence.

| Strategy | Shape | Suits a PR that |
|---|---|---|
| `acceptance` | skill (`slice-tdd`) | delivers behavior a user can observe — the default for such a PR. Its proof is the external, user-facing behavior, run the way a user would meet it; a human design gate precedes any code. Never a `refactor`/`scaffolding` PR. Runs in-session |
| `internal` | skill (`slice-tdd`) | is mostly edge cases and internal rules, where external proof of each would cost more than it is worth. Same flow as `acceptance` without the acceptance tests or the gate. Never a `refactor`/`scaffolding` PR. Runs in-session |
| `yolo` | skill (`slice-tdd`) | delivers behavior a unit test could only restate — config or a query passed through to another system, provable only by running it there. `acceptance` with no unit tests: the acceptance proofs alone tick its criteria. Rare — never for logic of your own. Never a `refactor`/`scaffolding` PR. Runs in-session |
| `direct` | you, directly | is one obvious edit, or scaffolding whose design carries no risk |
| `hand` | the user writes it | the user wants to write themselves — for the learning, or because they hold context you don't |
| `navigator` | skill; the user still writes | the user writes it and wants an agent coaching, questioning direction and catching skipped steps |

**Rank `acceptance` above `internal` for a user-facing PR even when its design is settled.**
`acceptance` buys validation through the behavior a user sees, and a design pass at the moment it
pays most — a meaningful functionality change is when simplifications and new abstractions surface.
"The unknowns are settled" is not a reason to recommend `internal`; "external proof of these cases
costs more than it proves" is.

**For a `refactor` or `scaffolding` PR, offer `direct`, or `hand`/`navigator`** — never
`acceptance`, `internal` or `yolo`: `slice-tdd` has no failing test to open with and hands back
`blocked`. If the user asks for one anyway, say so, and let them choose with that in front of them.

Record the answer in the ledger — the PR's entry with status `chosen`, its **Strategy**, and its
first **Attempts** line — before any code exists. Do not carry the previous PR's strategy forward silently, and do not
pick a default when the user hasn't answered: per-PR choice is the reason this skill exists.

### 2. Cut the branch

`git switch -c <feature-slug>/NN-<pr-slug> <previous-pr-branch>` — naming the start point rather
than trusting `HEAD`. **`<previous-pr-branch>`** is the previous PR's branch, the base branch for
PR 01. Every PR before the current one has shipped, so there is only ever one candidate — except
where a PR was dropped after its branch was cut; that branch is left behind and is never a base.

**Then set the PR's status from `chosen` to `in progress`** in the ledger before handing off. That
status asserts the branch exists: `chosen` sends a resume to this step, `in progress` past it.

### 3. Hand off

**Hand off only once the previous PR's suite run reads `0`**
([references/background-suite.md](references/background-suite.md), *Waiting on it*). **The one
exception is `slice-tdd`** (any mode), whose ACCEPT and design write no code: hand it off at once,
with the *pause* paragraph from [references/hosted-handoff.md](references/hosted-handoff.md) added
while the run is still going. It reports `paused: design done` after its design commit; wait for
`0`, append a fresh `<strategy> — in progress` line, and invoke it again with no pause paragraph —
its state file resumes it at BUILD.

**If the PR's plan entry has a Net line, lay its net before the handoff that starts code**, per
[Laying the net](#laying-the-net) — for a paused `slice-tdd`, before the resumed one. Laying runs
tests and breaks code on purpose, so it too waits for `0`.

State to the executor the PR's behavior sentence, the criteria it advances, the branch, the net's
proofs with their run command, and the
obligations of [the executor contract](references/executor-contract.md) in the form its shape
takes, per that file's *Which shape carries which obligation*. Then:

| Strategy shape | Handoff |
|---|---|
| A skill (`slice-tdd`, `navigator`, …) | Invoke it with the block from [references/hosted-handoff.md](references/hosted-handoff.md), filled in. For `acceptance`, `internal` and `yolo`, invoke `slice-tdd` with the block's *mode paragraph* naming which. The block is the only form of the contract a guest reads. |
| You, directly (`direct`) | Build the PR. The obligations are the whole spec. |
| The user, by hand | Say what the PR is and that the branch is cut, then stop and wait. Do not write code for a PR the user has taken. |

**What the host carries for `direct`, `hand` and `navigator`** — no report comes back from these:

- **Close the Attempts line yourself**, when the work is done and the targeted tests are green:
  `<strategy> — handed back`, or `<strategy> — blocked: <what stopped it>`. Record any backlog item
  or later-PR discovery in the ledger directly. Leave the line open and a resume rebuilds the PR.
- **For `hand` and `navigator`, first confirm the work is committed on the branch, and commit it
  yourself if it is not** — `git -C "$top" status --short` and
  `git log --oneline <previous-pr-branch>..HEAD`. An uncommitted PR fails the boundary's squash, and
  a resume reads zero commits as a PR never built. Committing work the user finished is not writing
  code — say that you are doing it.

**Run a skill-shaped guest in-session.** `slice-tdd`'s design gate needs the user live, and it
delegates its own heavy steps; `navigator` is the user's to watch. In-session also keeps the abandon
in reach. Delegate only a guest that needs neither — trade-off in
[references/hosted-handoff.md](references/hosted-handoff.md), *Delegated or in-session*.

### Reading a report

A skill-shaped guest that builds — not `navigator` — has handed back **only** when its report
exists at the path the block named, with all six headings. Read it as soon as the guest returns:

- **Missing, or a heading missing** — not handed back, whatever the guest said. Re-invoke it once
  with the same block; a second miss stops the PR — tell the user what is missing.
- **Complete** — copy it into the ledger: close the Attempts line with its Outcome (adding
  `reviewed` when its Review says so), and record its Review lists, Criteria proof, Carry-forward,
  Later-PR discoveries and Learned under the PR's entry. **Then delete the report.** Copy first:
  the report is the only record of these until the ledger has them.

Then judge the guest by disk, never by the report — per *Reading the result* in
[references/hosted-handoff.md](references/hosted-handoff.md). Act on the Outcome: `handed back` → the
boundary; `blocked` → [A guest that hands back blocked](#a-guest-that-hands-back-blocked);
`paused` → the hold above.

### 4. The boundary

Re-read the re-read set. Then:

1. Confirm the targeted tests and the net's `read-only` agent proofs are green and the PR's
   behavior is observable — for a `refactor` or `scaffolding` PR, that behavior is *unchanged*.
   **Then re-check the net**, per [Laying the net](#laying-the-net), over
   `git -C "$top" diff <previous-pr-branch>...HEAD`: the design moved since planning. A found
   regression is a consumer this PR breaks — under `direct`, fix the code and re-check; under any
   other strategy, it is `blocked`. **Do not run the full suite here**; step 3 starts
   it in the background. A red test here is not a boundary: treat it as `blocked`.
2. **Skip this step only if the newest Attempts line carries the whole token `reviewed` and the
   ledger holds that PR's copied Review lists.** When skipping, carry its `Dismissed` and
   `Open at cap` lists into step 3, and add its `Backlogged` and `Out of scope` items to the
   ledger's backlog.

   **Otherwise, delegate a design review to a fresh subagent.** Resolve `git rev-parse
   --show-toplevel` **yourself, first**, and paste the absolute path into the prompt — tell it to
   invoke the `design-review` skill over
   `git -C <absolute-repo-path> diff <previous-pr-branch>...HEAD`. Never send
   `$(git rev-parse --show-toplevel)` unexpanded: the subagent's shell evaluates it in its *own*
   working directory, and `design-review` returns a confident report about code you did not write.
   **State that path as the subagent's working directory.** Focus it on the statement, name,
   function and class altitudes — one PR is too small for component-level findings.
   **You triage the result** — fix what is cheap while the tests are green, **committing the fixes
   on the branch**, and turn the rest into ledger backlog entries. Two findings are backlog entries
   however cheap, and the reviewer, which cannot see the plan, will rank both highly: one that wants
   an earlier PR's or the steel thread's test tightened to assert exactly the current output (that
   test pins the seam, not the content — `slicing.md`, §"A thread's test must survive being
   thickened"), and one that asks for behavior this PR does not have (*Kitchen sink*, same file).
3. **Squash the PR to one commit — before the user sees it.** **First confirm the tree is clean**
   (`git -C "$top" status --short` shows nothing), and that
   `git -C "$top" diff --stat <previous-pr-branch> HEAD -- <plans-dir>/` adds no file a guest left
   there — a guest that broke obligation 5 would ship its state file. Remove one with `git rm` and
   commit before squashing.

   ```bash
   top=$(git rev-parse --show-toplevel)
   git -C "$top" reset --soft <previous-pr-branch>
   git -C "$top" commit -m "<behavior sentence>" -m "<Learned, if any>"
   ```

   Add a further `-m "<what is deliberately not here>"` only when the PR has an `inert:` Merge
   safety line.

   **Then start the full-suite run in the background**, per
   [The background suite run](#the-background-suite-run), present the PR for review and stop,
   telling the user the suite is running in this tree — with, when step 2 was skipped, the guest's
   dismissed findings and their reasons, and anything left open at its cap. This is where the user
   changes the design, rejects the slicing, reorders what's left, or calls the feature done early.

   **A change the user asks for here is an edit to this PR, on its branch — make it.** Stop the run,
   make the change, re-trace and run the net as step 1 does, rerun the tests it touches, amend it
   into the PR's one commit, and restart the
   run, per *A change before approval* in
   [references/background-suite.md](references/background-suite.md). If the change is structural —
   a signature, a moved responsibility, a new type or module — send the new diff through one
   design-review round as in step 2 before re-presenting. It is a re-slice instead only when it
   pulls in work another PR in the plan owns — then say which and ask.
4. On approval, **read the run's status file** — red here is *Red before approval* in
   [references/background-suite.md](references/background-suite.md); absent is fine, carry on.
5. **Update the ledger**: mark the PR `shipped`, close its Attempts line, tick each criterion its
   obligation-2 proof now satisfies — with the test or proof that does, copied from the report's
   Criteria proof where there was one; you make the call, not the report — and record backlog items.
6. **Re-slice if this PR's `Kind` is `thread`, or if a Later-PR discovery calls for it** — per
   *Re-slicing*, below. Every PR behind the thread was drawn before its findings existed.
7. **Verify the session can hand off cleanly here** — `git -C "$top" status --short` shows
   nothing, and `git -C "$top" check-ignore -q` still succeeds for the plan and the ledger. Fix
   either before stopping — unless the run is still going and the stray files are its output, which
   its leftovers step clears.

Then start the next PR at step 1 — including the strategy question.

### Laying the net

A PR's **Net** entries (from the plan's Regression Net) are acceptance proofs of how other flows
behave today. You lay them, whatever the strategy: the executor's own tests encode its beliefs
about where the code runs, which is what the net checks. **Delegate `pin-impacted-flows` to a
fresh subagent**, per that skill's *In a subagent*, with the absolute repo path resolved by you
first, from a clean tree with no background run going:

- **Before a PR's code** — `lay` mode, given the PR's Net entries from the plan.
- **To re-check** (the boundary, a change before approval, a review comment) — `lay` mode over the
  diff it names, given the ledger's Net section as the existing net. It re-traces, lays any new
  entry, and names the existing entries the change reaches: re-run those that are human-only or
  `mutating` with the user now.

Then work through its **Needs the user** list with the user, in-session. Copy its report into the ledger's Net section, and add each `read-only` agent proof to the
Session's **Net runner**. Kept proofs are committed on the branch as `net: <entry ID>`. A new entry
is also added to the plan's Regression Net and to this PR's Net line: the one plan write outside
re-slicing. Tell the user.

### Re-slicing

The one write this skill makes to the plan besides the net (*Laying the net*). Re-read `../slice-plan/references/slicing.md`,
*Re-slicing*, and edit the plan's `## PRs` section only, and only PRs the ledger shows not started
— or the current PR's own behavior sentence, narrowed to what is already delivered when the rest
moves to a new PR immediately after it. Feature, criteria and Constraints stay as agreed; changing
them is a new `slice-plan` session. A split or a narrowing is minor; a drop, a reorder, or widening
a PR into another's work goes to the user first. A
new PR takes the next free `NN`. Set the plan's **Last updated**.

### The background suite run

The full suite runs once per PR, in the background, in the working tree, launched at the
boundary's step 3. You hold the next PR's code until it reads `0`. Read
[references/background-suite.md](references/background-suite.md) once per launch, once per wait
(not at every poll), and on any red: it has the recipe, the rule that nothing outside the plans
directory changes while it runs, waiting, resuming, and fixing a red run.

### A guest that hands back blocked

`blocked: <what stopped it>` means the executor stopped without delivering the PR. It is not a
boundary and not yet an abandon. Re-read the re-read set, read the
reason, and take exactly one of three:

- **A precondition you own** — something the plan or the setup should have provided. Supply it on
  this branch, commit, append a fresh `<strategy> — in progress` line, and hand off again.
- **The PR is too big, or is two PRs.** Re-slice, per *Re-slicing*: narrow this PR to what is green
  and coherent now, and move the rest to a new PR immediately after it. Surface it to the user.
  Then go to the boundary if the narrowed PR is already delivered, or append a new
  `<strategy> — in progress` line and hand off again.
- **The strategy has no move on this PR** — a test-first guest on a `refactor` PR is the standing
  example. That is an abandon: propose it and follow the recipe below.

Do not re-invoke the same guest on an unchanged PR; it stops in the same place.

### Review comments on a shipped PR

When the user brings review comments on a PR the ledger shows `shipped` (usually from the hosted
PR, after they pushed), read [references/review-comments.md](references/review-comments.md) and
follow it for every comment. The fix goes on that PR's branch as new commits, then the later
branches are restacked. It never becomes a new PR, and never skips the re-trace, however small
the fix.

### Abandoning a strategy

Re-read the re-read set before any of this.

Abandon when the strategy itself is wrong for the PR — whether you concluded that yourself or a
guest reported `blocked` saying so, which is evidence and not the decision. **Propose it and wait
for the user's confirmation**: the recipe throws away uncommitted work and runs `git clean`. Ask
for the replacement strategy in the same message, with step 1's brief.

Once confirmed, follow [references/abandon.md](references/abandon.md): restore the worktree from
the previous PR's branch, commit the reversion the restore stages, and only then close the
abandoned Attempts line and set the new strategy — the ledger write is last because the new
strategy's open line is what a resume reads as "ready for step 3". The ledger is untracked, so the
restore never touches it: the record of the attempt survives the rollback that erases the attempt.
Do it as one uninterrupted step.

---

## Feature complete

Declare it when every PR in the plan is `shipped` in the ledger with its **Suite** `green` — wait
for the last run — every criterion is ticked (rerun any `read-only` `yolo` proof copied onto it),
and the backlog is drained: each item fixed, dismissed with a reason, or carried somewhere the user
names. **An item that needs a change to tracked code is a new PR**, appended to the plan per
*Re-slicing* and run like any other — never an amendment to a PR already shipped; that PR's review
is spent. (Two exceptions: a red background run, in
[references/background-suite.md](references/background-suite.md), and a reviewer's comment on the
hosted PR, in [references/review-comments.md](references/review-comments.md).)

Report the PRs as delivered, the strategy each ended up using, and every abandoned attempt with what
entangled it — the abandoned attempts are the part worth reading. Then run Cleanup.

## Cleanup

1. **Report the branch stack** — each PR's branch and its base — and offer to restack
   (`git rebase --onto <new-base> <old-base> <branch>`, from the bottom up) if an earlier PR was
   amended or merged after a later one was cut off it. Name separately any branch left behind by a
   dropped PR.
2. **Pushing and opening PRs is the user's call.** This skill produces a stack of local branches and
   stops there.
3. **Remove this feature's suite runs** — `rm -rf "<dir>"` for each `<dir>` a ledger **Suite** field
   names. Runs of other features share the parent `slice-suite` directory; touch nothing there you
   did not read from this ledger.
4. **Settle the ledger, the net and the plan — once the user says every PR has merged.** Until
   then review comments may still come in (*Review comments on a shipped PR*), and they need the
   ledger and the net. Delete each untracked net proof the ledger's Net section lists, with its
   exclude line. Offer to delete the ledger, and only then delete its exclude
   line and the reports' pattern line from `"$(git rev-parse --git-path info/exclude)"`, leaving
   every other line alone. If the user keeps it as the record of which strategy suited which PR,
   leave its exclude line in place. Then offer to retire the plan, per `plan-format.md`,
   *Retiring a plan*.
