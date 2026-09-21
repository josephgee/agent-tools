---
name: tdd
description: "Guides strict Test-Driven Development (TDD) as a learning loop, delivered as a stack of small reviewable PRs. Use when building a feature: decompose it into an ordered sequence of PR-sized behavioral increments, then drive each one through THINK-RED-GREEN-REFACTOR cycles — choose the next behavior, write one failing test, make it pass with the simplest possible code, then refactor and reflect — and SHIP it as a clean, independently reviewable commit before starting the next. Also use when asked to break a feature into small, reviewable, incrementally shippable pull requests."
compatibility: "Requires the slice-plan, design-principles, and design-review skills to be installed alongside it — the PR plan is drafted from slice-plan's slicing doctrine, and the design checks at REFACTOR, SHIP, and the end-of-feature pass depend on the other two, with no bundled fallback."
metadata:
  soft-deps: slice-plan design-principles design-review
---

# TDD

TDD is a learning loop. You start with a hypothesis about the right design and test it against reality one behavior at a time. Each cycle — writing a test, making it pass, then reflecting on the code — teaches you something. That learning feeds back into the design. Sometimes the design evolves gradually. Sometimes you learn enough to know the current approach is wrong and you start fresh. Both are expected outcomes, not failures.

Work is delivered as a stack of small PRs. There are three levels, and keeping them distinct is what makes the process work:

- **Acceptance criteria** are behavioral — they describe what the feature must do from the outside, as observed by a user or consumer. They are the fixed target. They do not describe how the feature is built.
- **The PR plan** is the delivery layer — an ordered sequence of independently reviewable increments, each changing observable product behavior, however small. Each PR is closed out and handed over before the next begins — or, on a standing go-ahead, the whole plan runs through and is reviewed once at the end (see [Execution modes](#execution-modes)).
- **Design hypothesis** is the implementation layer — your current best theory for how to build what the criteria require. It is expected to evolve as you learn.

Inside one PR you run cycles. At the end of one you cross a PR boundary — normally a SHIP with a review gate. The loop stops when every planned PR has been delivered, all acceptance criteria are satisfied by passing tests, and all learnings captured in the backlog are resolved. The discipline of one test at a time keeps the feedback tight; the discipline of one small PR at a time keeps the work reviewable.

## State File

Maintain a state file at `plans/tdd-<feature-slug>.md` throughout the session. This is the source of truth for resuming work, tracking design evolution, and managing context as the window grows. It is named after the effort so that parallel TDD sessions never collide, and it is committed with each cycle so that every cycle commit is a complete rollback point — `git reset --hard <cycle-commit>` restores the code *and* the session state together. It is kept out of every PR by the squash, not by `.gitignore`; [references/pr-workflow.md](references/pr-workflow.md) has the mechanism and the reason.

See [state-format.md](state-format.md) for the format when creating the file, and for how to choose the directory and slug.

**Read** the state file when starting up (to detect a prior session). Also re-read its **Rules in Force** header plus the PR Plan, Backlog, and Current Position sections at the start of every THINK, unconditionally — before choosing the next behavior, not only when you notice you've lost track. This is a fixed checkpoint, not a judgment call.

The Rules in Force header is the cycle's non-negotiable steps, written verbatim into the state file at creation and never edited afterwards. Re-reading it is not ceremony: this skill's body was loaded into the conversation once and sits in the compressible middle of the context, where a long session dilutes it and a compaction can drop it entirely — the symptom being TDD-shaped work that quietly stops proving the test fails first. The state file is on disk, so it survives compaction, and re-reading it puts the rules back at the end of the context where attention is strongest. If you resume a state file that predates the header, add it before the next cycle.

**Write** the state file (this is the canonical list of write points — the phase sections below restate each one at the moment it applies):
- When starting fresh (create it)
- During THINK — if the PR plan changes, write the updated plan before proceeding to RED
- At the start of RED — record the active test and current phase before writing any code
- At each phase transition — update current phase
- After completing REFACTOR — append cycle log entry, update criteria statuses, update design hypothesis, update the current PR's cycle list (check off the completed behavior; minor resequencing is fine here — significant changes belong in THINK), update backlog
- At SHIP — record the PR description, branch, and commit; mark the PR `ready`; open the next PR
- Driver Status — keep current at every phase transition (default `in-progress`); update immediately when escalating (`needs-user-input`, with a one-sentence `Reason`), when a PR is ready to hand over (`pr-ready`), or when conditions 1–3 hold and the end-of-feature review is still to run (`feature-complete`). See [Delegated Execution](#delegated-execution-subagent-mode).

Keep the file's diff quiet — append entries and tick checkboxes rather than reflowing prose. It rides along in every cycle commit, so a tidy diff keeps cycle history and the resume point legible.

---

## Startup

**First:** Look for existing state files — glob `tdd-*.md` in `plans/`, `docs/plans/`, and `.plans/`. A state file is identifiable by its `# TDD Session State` heading even if it has been renamed. Right after a squash (interactive SHIP or one-shot Finalization) the file is *untracked* — that is expected; the next cycle commit re-adds it. Do not commit or `git clean` it.

- **None found** — start fresh.
- **Exactly one** — offer to resume it.
- **More than one** — list them with feature name and last-updated date, and ask which to resume or whether to start a new effort. Multiple files are expected: efforts are named individually so they can run in parallel.

**If resuming:**
1. Read the state file. If its Rules in Force header is missing or differs in any way from the block in [state-format.md](state-format.md), replace it wholesale and verbatim now — it is fixed text with a single source, so replacing is not the drift the never-edit rule guards against.
2. Report to the user: feature, current PR and its position in the PR plan, current phase, active test if any, remaining criteria, remaining PRs, and current design hypothesis. If the project uses git, also confirm which branch of the stack is checked out and that it matches the state file.
3. Ask whether to resume from that position or start fresh (which creates a new state file, under a new slug, and begins a new session).
4. If resuming, skip to the current phase — do not repeat completed setup.

**If starting fresh** (no file, or user chose to restart), run the preflight before touching any code.

### Preflight

Establish and align on four things in order. Each builds on the previous — do not skip ahead.

**1. Feature definition**
Establish what is being built and why. If not provided, ask. Work toward clarity on:
- What is the feature, and what problem does it solve?
- What is in scope? What is explicitly out of scope?
- Who uses it and in what context?

If the definition is vague, help sharpen it before moving on. A vague feature definition produces vague acceptance criteria.

**2. Acceptance criteria**
Acceptance criteria are behavioral — they describe what the feature does from the outside, as observed by a user or consumer. They are not about internal structure. A good criterion could be satisfied by any valid implementation.

If not provided, derive candidates from the feature definition and propose them. For each criterion, confirm it is:
- *Behavioral*: describes an observable outcome, not an implementation detail
- *Specific*: clear enough that two people would agree whether it is satisfied
- *Testable*: expressible as a failing test
- *Scoped*: belongs to this feature, not a future one

Present the final list and ask the user to confirm it is correct and complete. Push back on criteria that describe internals, are untestable, or are out of scope.

**3. Design hypothesis**
The design hypothesis is the implementation layer — your current best theory for how to build what the criteria require. It covers internal structure: key types, modules, or functions; how responsibilities divide; how the pieces connect.

This is explicitly separate from the acceptance criteria and expected to evolve as you learn. Present it as a proposal, not a declaration. Invite the user's perspective. If they see it differently, discuss and reach a shared starting point before proceeding.

**4. PR plan**
Decompose the feature into an ordered sequence of PRs. Each PR is one independently reviewable change that delivers observable product behavior — however small. Trivial is fine; small and obviously correct beats large and plausibly correct.

Read [references/pr-slicing.md](references/pr-slicing.md) in full before drafting the plan, and with it the general slicing doctrine it defers to — `slice-plan`'s `references/slicing.md`, also in full, as that file directs. Together they cover the sizing test, how to split a PR that is too big, the steel thread that opens the sequence and its live-vs-inert merge-safety choice, and the slicing anti-patterns. Do not guess at the decomposition from this summary.

For each PR, state a one-sentence behavior (no "and"), the acceptance criteria it advances, and the cycles you expect it to take. The sequence follows the outside-in strategy — the first PR establishes an end-to-end path, later PRs replace stubs with real behavior, then add functionality, then cover edge cases — which naturally yields PR-shaped work.

Present the sequence as an ordered list and invite the user to adjust it. This is the highest-value thing for them to push back on: it decides what each reviewer will be asked to read. Record it in the state file. It is a starting point, not a commitment — it will evolve as you learn.

**Alignment gate**
Once all four are established, present a concise summary:

> **Feature**: [one or two sentences]
> **Acceptance criteria**: [bulleted list]
> **Design hypothesis**: [brief description]
> **PR plan**: [ordered PR sequence, one sentence each]
> **State file**: `plans/tdd-<feature-slug>.md`

Include the proposed slug so the user can correct it — it is permanent for the effort and names the branches too. Then ask: *"Are we aligned? Shall I proceed?"* Do not begin any cycles until the user explicitly confirms. If they answer with a standing go-ahead ("just run the whole thing"), start in one-shot mode — see [Execution modes](#execution-modes).

### Setup

After alignment is confirmed:

If the project uses git, confirm the working tree is clean before proceeding: `git status` should show no uncommitted changes unrelated to this session. Stash or commit any existing work first — TDD cycle commits should contain only cycle work.

1. **Identify the test runner.** Find the test framework and how to run tests (e.g., `npm test`, `pytest`, `cargo test`, `go test ./...`). Read `package.json`, `pyproject.toml`, or equivalent if unsure. If the test runner cannot be determined from project files, ask the user.
2. **Run the full test suite.** Confirm it passes cleanly. If there are pre-existing failures, surface them and get confirmation — you need a green baseline.
3. **Choose the plans directory.** Use whichever of `plans/`, `docs/plans/`, or `.plans/` the repo already has. Create `plans/` only if none exists. If more than one exists, ask which to use rather than guessing.
4. **Create the state file** at `<plans-dir>/tdd-<feature-slug>.md` with the Rules in Force header copied verbatim from [state-format.md](state-format.md), then session info, feature definition, acceptance criteria, initial design hypothesis, and the PR plan.
5. **Create the first PR's branch.** If the project uses git: `git switch -c tdd/<feature-slug>/01-<pr-slug>`. See [references/pr-workflow.md](references/pr-workflow.md) for the stack layout. Record the base branch in the state file — it is what PR 01 will be reviewed against.
6. **Commit the state file.** If the project uses git: `git add <state-file> && git commit -m "tdd: begin <feature name>"`. This is the baseline from which each cycle builds a rollback point. The state file rides along in every cycle commit and is unstaged again at every squash (see [references/pr-workflow.md](references/pr-workflow.md)), so it never appears in a PR — no `.gitignore` or `.gitattributes` change is needed.

---

## Test Strategy

These principles apply to every test written throughout the feature.

**Outside-in, E2E first**: Begin with a test that exercises the full feature end-to-end, even if behavior underneath is stubbed. This proves the feature works as a whole before filling in the details. Once the outer shell passes, work inward: replace stubs with real implementations, then add functionality, then cover edge cases. Testing outside-in keeps observable behavior as the primary concern at every stage.

**Merge-safe from the first PR onward**: Because each PR ships on its own, a stubbed end-to-end flow can expose a half-working path to real users. The first PR must therefore be either the thinnest *genuinely working* vertical slice, or an end-to-end skeleton that is **inert** — entry point unregistered, route not mounted, or behind an off-by-default flag. Decide which at planning time, record it in the PR Plan's `Merge safety` field, and reuse it in the PR description at SHIP. This constrains where you start; it does not change the outside-in strategy. The same field carries any *other* PR whose stubs stay flag-gated or unmounted — set it when that PR is planned or re-sliced, not only for PR 01.

**Behavioral, not wiring**: Tests should verify observable outcomes — return values, state changes, effects at the system boundary — not internal structure. A test that asserts "object A called object B's method" is a wiring test: it breaks when you refactor internals even when the feature still works correctly, and it doesn't tell you whether the feature does the right thing. Ask "did the feature behave correctly?" not "did it use the right objects internally?"

**Live objects over mocks**: Use real objects wherever practical. Mocks can be wired incorrectly, obscure real behavior, and produce false confidence. Reach for a mock when:
- Crossing a **system boundary**: external APIs, databases, file systems, message queues, third-party services
- The real thing is **prohibitively slow** for the test suite to run regularly

When you do mock, mock at the boundary — not deep inside your own code.

---

## The Cycle

Cycles run inside a PR. Repeat them until the current PR's behavior is fully delivered, then cross the PR boundary — SHIP in interactive mode, or the lightweight boundary steps in one-shot (see [Execution modes](#execution-modes)) — and move to the next PR. The feature is done when every planned PR has been delivered, all acceptance criteria have passing tests, all backlog items are resolved, dismissed, or deferred, and a final code review confirms the code is clean. See Progress for the full completion gate — this is a summary, not a second source of truth.

### Execution modes

THINK → RED → GREEN → REFACTOR is identical in both modes. Only what happens at a PR boundary differs.

**Interactive** (default): stop at every PR boundary. Run SHIP, present the finished PR, and wait for the user's review before starting the next PR. This is the reviewable-stack workflow the skill is built around.

**One-shot** (on a standing go-ahead — "keep going", "just finish it", "take it from here"): run the entire PR plan as one continuous stream of cycles, reviewed once at the end. In this mode:

- **Do not run per-PR SHIP.** No squash, no per-PR branch, no handoff at boundaries. History stays linear on the current branch.
- **At each boundary crossed**, do only the boundary-crossing steps flagged in SHIP — the delegated design review of that PR's cycle range, and writing its PR description into the state file — then record the boundary and continue. Fixes from the design review are ordinary cycle commits; the linear history absorbs them with no restack. Record the boundary *after* those fixes: the last cycle commit's sha, fix commits included, in that PR's plan entry's `Ends at` — Finalization squashes exactly up to that sha, so a fix left past it would ship in the next PR.
- **Every cycle commit is kept.** If the end review sends you back, `git reset --hard <cycle-commit>` rewinds to any point in the whole feature — code and session state together — and you resume from there, in either mode. In one-shot, a rewind invalidates every `Ends at` recorded at or after that point: re-record them as you cross those boundaries again, or Finalization builds the stack from shas that no longer describe the history.
- **When Progress conditions 1–3 are met**, run condition 4's end-of-feature review, take the user's single review, then **finalize**: build the squashed PR stack from the linear history (see [references/pr-workflow.md](references/pr-workflow.md)) and hand off.
- **`needs-user-input` decisions still stop the run** — a criteria correction, a blocked or invalidated plan. One-shot forgoes the *review* gates, not the *decision* gates.

The mode can be chosen at the alignment gate or any time after ("ok, just take it from here"). Given mid-feature, it applies from the current PR forward — PRs already shipped interactively keep their squashed branches, and Finalization only stacks the one-shot range. It holds until feature-complete. Switching back to interactive takes effect at the next boundary — but the PRs crossed in one-shot are still unsquashed linear history with no branches, so SHIP's single squash cannot close out the current PR alone: present the whole crossed range for review there, and on approval build its stack by running Finalization early (current PR included; see [references/pr-workflow.md](references/pr-workflow.md)). Normal interactive SHIP resumes from the next PR.

### THINK — Choose the Next Behavior

**First, re-read the state file's Rules in Force header and its PR Plan, Backlog, and Current Position sections.** Do this every time, unconditionally — do not rely on noticing you've lost track, and do not skip the header because you believe you already know the rules; that belief is exactly what erodes. Know the rules, which PR you are in, and what remains in it before choosing anything.

State in one sentence — no "and" — what the next useful behavior is.

**Check whether it belongs in this PR.** The behavior must serve the current PR's one-sentence statement. If it doesn't, it starts the next PR — do not absorb it into this one. Scope creep within a PR is the main way this process fails: the PR quietly grows until it is no longer reviewable. If the current PR's remaining work has turned out to be larger than planned, ship what is green and coherent now and move the remainder to a new PR immediately after it. Never keep extending a PR because the plan listed it as one item.

**Check the plan and backlog together.** The default is the next cycle in the current PR — but first check whether any backlog item should come before it (an edge case that blocks further progress, a design concern that must be resolved). If a backlog item belongs next, promote it into the current PR before proceeding; if it is really its own increment, add it to the PR plan instead.

**Never execute a stale plan item.** Before committing, ask: does this item still make sense given everything learned so far? If not, update the plan first:
- *Minor change* (resequencing cycles, promoting a backlog item, splitting a planned PR in two): update the plan silently and proceed.
- *Dropping a planned behavior or a planned PR*: surface it to the user — briefly state what was planned, why it is no longer needed, and what comes instead — before proceeding.
- *Major resequencing of the PR plan*: surface the revised plan to the user before proceeding.

Before writing anything, also ask: **is this behavior actually needed now?** If it exists only because the architecture in your head expects it, or because it feels like it "should" be there — that is speculation. Skip it and choose the next genuinely needed behavior instead.

### RED — Write One Failing Test

- Write **exactly one** new test for the behavior chosen in THINK. Writing the test is a design act — you are specifying the interface from the consumer's perspective.
- **If the test is awkward to write** — the setup is convoluted, the assertions are contorted, or it doesn't read clearly — treat that as a design signal, not friction to push through. Pause and ask: is the design making this hard? A test that is difficult to write often means something is wrong upstream. If the design needs to change, revise the hypothesis, update it in the state file, and briefly surface the change to the user before proceeding.
- **If you notice edge cases, future jobs, or refactors** while writing the test, add them to the backlog in the state file and stay focused on the current test. Do not act on them now.
- Update the state file: set phase to RED and record the active test.
- Run the tests. **Confirm the new test fails for the right reason** — the expected behavior is missing, not a compile error, import error, or typo in the assertion. If it fails for the wrong reason, fix the test before moving on. **If the test passes immediately**, it drove nothing — delete it, return to THINK, and choose a different behavior. The Rules in Force header says exactly this and is re-read every cycle; do not soften it into "keep it if it fills a coverage gap". A genuine coverage gap is a backlog item, not a green test smuggled into a RED step.

### GREEN — Make It Pass

- Update the state file: set phase to GREEN.
- Write the **simplest code** that makes the failing test pass. Simplest means: a hardcoded value if that passes, an `if` statement if that passes, the most embarrassingly obvious thing. Do not add code for cases the current test does not exercise — that is speculation, not implementation.
- **Simplest does not mean sloppy.** Language conventions still apply: imports in the right place, idiomatic constructs, correct file structure. Aim for minimal *behavior*, not minimal *craftsmanship*.
- **If you notice edge cases, future jobs, or refactors** while implementing, add them to the backlog and stay focused on making the current test pass.
- **If you discover the test cannot be satisfied without a structural change** — the simplest implementation would require redesigning something fundamental — do not over-implement. Add the design concern to the backlog, complete GREEN as best you can, and address the structural issue in REFACTOR or as a hypothesis revision before the next RED.
- Run the tests. **Confirm all tests pass** — the new one and every existing one. If there are regressions, fix the implementation. Do not modify the test to make it pass.

### REFACTOR — Improve and Reflect

- Update the state file: set phase to REFACTOR.

**When priorities conflict, apply Simple Design in this order:**
1. Tests pass
2. Intention is clear
3. No duplication
4. Fewest elements

Never sacrifice clarity to remove duplication. Never add abstractions for symmetry or hypothetical futures.

With all tests passing as your safety net, review production code and test code as two separate passes. Identify improvements on each side, then execute one side at a time — if something breaks, you know which side caused it. The only exception: a rename that touches both sides is fine.

Make one change at a time. Run tests after each. If a change breaks tests, revert it.

Apply the production code and test code review checklists from [references/refactor-checklist.md](references/refactor-checklist.md).

**Reflect on what you learned:**
After improving the code, assess: what did this cycle teach you about the design? Did anything surprise you? Does the hypothesis still hold, or has it shifted?

**Design pressure check** (one minute — smell detector, not architecture review):
Did this cycle introduce or intensify any of:
- A new branch by type, source, provider, mode, or role? (*Switch Statements*)
- A class or function now has two reasons to change? (*Divergent Change*)
- Test setup got harder because concerns are mixed? (*Feature Envy* / *Inappropriate Intimacy*)

If none: note "no design pressure" and move on. If any: either refactor now (smallest change that reduces pressure, while staying green) or log it in the backlog with a clear reason to revisit — name the smell in the backlog entry, it makes the entry more concrete and easier to act on later. No abstractions for pattern-matching or hypothetical futures — only when pressure is visible in the current code.

These three are deliberately narrow — the smells that most often show up within a single cycle's diff. If you sense pressure but none of the three fits, or want the precise term for a backlog entry, invoke the `design-principles` skill and consult its `design-catalog.md` for the precise name (Fowler's smells, Martin's *Clean Code* heuristics, component-level smells, Martin's symptoms of rot). Either way this is a quick naming lookup, not a scan — the full catalog belongs to the final review pass below, not the one-minute check.

**Capture backlog items:**
Review everything noticed during this cycle that wasn't acted on — edge cases not yet covered, refactors worth considering later, work that emerged as necessary. Add each to the backlog in the state file. This is the main moment for backlog capture: be deliberate about it, not incidental.

If any item is being marked deferred rather than open, surface it to the user now with the reason and where it is going. Do not wait until the completion review — the user should know about deferred work as soon as the decision is made.

**Update the state file:**
- Append a cycle log entry (test, behavior verified, what was learned, hypothesis change if any), tagged with the current PR.
- Mark any newly satisfied acceptance criteria with the PR that satisfied them.
- Update the design hypothesis if it changed.
- Update the current PR's cycle list: check off the completed behavior. Minor resequencing based on this cycle's learning is fine here. Dropping an item or major resequencing belongs in THINK, not silently in REFACTOR.
- Update the backlog (new items, and any resolved, dismissed, or deferred this cycle).
- Set phase to between-cycles and clear the active test.

If there is nothing to improve and nothing new to observe, say so explicitly. Silence is not a review.

**Commit the cycle.** If the project uses git, stage all changes — the new test, the implementation, the refactoring, and the updated state file — and commit together: `git add -A && git commit -m "tdd: <behavior from THINK>"`. This commit is a rollback point. If the feature later goes off track, `git reset --hard <hash>` returns to this exact state, including the design hypothesis, PR plan, and backlog at this moment.

**Then decide where to go next.** If the current PR's behavior is now fully delivered, proceed to SHIP. Otherwise return to THINK for the next cycle in this PR.

### SHIP — Close Out the PR

**Interactive mode.** In one-shot mode you do not run SHIP per PR — see [Execution modes](#execution-modes). The two steps marked *(both modes)* below still run once per boundary in one-shot; the rest is deferred to Finalization in [references/pr-workflow.md](references/pr-workflow.md).

Runs once per PR, after its final cycle. Read [references/pr-workflow.md](references/pr-workflow.md) for the git mechanics; this is the sequence.

**SHIP ends in a review gate.** A PR boundary is where a human reads the work, so treat it the way Preflight treats the alignment gate: present the finished PR — cycle commits still intact — and stop. This is the user's opportunity to reject the slicing, reorder what's left, redirect the design, or call the feature done early — and it is far cheaper for them to do that here than three PRs later. Do not roll into the next PR's cycles until they respond. **The squash happens only after this review, on the user's approval** — never before. It rewrites the PR to a single commit and the per-cycle checkpoints stop being reachable by name, so an unreviewed squash is exactly the thing this gate prevents.

- Update the state file: set phase to SHIP.
- **Confirm the full suite is green** and the working tree is clean apart from the state file (SHIP keeps writing to it). A PR that leaves tests failing is not shippable at any size.
- ***(both modes)*** **Review the whole PR diff** — the combined increment, not just the last cycle's changes; exclude the state file, which is session bookkeeping (the exact `git diff` is in [references/pr-workflow.md](references/pr-workflow.md)). Per-cycle REFACTOR only ever sees one cycle, so duplication introduced in the first cycle and repeated in the fourth survives it — this pass is the first thing that looks at the increment as a unit. Apply the [refactor-checklist](references/refactor-checklist.md) across the combined diff yourself, then **delegate the design review to a subagent** — see [references/delegated-execution.md](references/delegated-execution.md) for the task prompt and why this one delegates even though SHIP otherwise stays local. This pass's focus is the statement, name, function, and class altitudes — components and cross-PR seams belong to the end-of-feature pass, not this one — and the task prompt passes that focus explicitly. **Only if your environment has no delegation mechanism**, run the same review in this session: invoke the `design-review` skill yourself with the same explicit scope and focus, accepting that the catalog rides in this session's context for the rest of the feature. **Triage the findings yourself either way**: you know what was deliberate, so dismiss what was consciously deferred and say which, fix what is worth fixing now while staying green, and send the rest to the backlog as named entries. Each fix you make here is its own cycle commit.
- **Confirm the PR is genuinely mergeable on its own**: it changes observable behavior, it does not depend on a later PR to make sense, and anything stubbed underneath is inert or flag-gated.
- ***(both modes)*** **Write the PR description** into the state file — what changes, which criteria it advances, what is deliberately not here (stubs, deferred edge cases, flags), this PR's `Merge safety` line verbatim if it has one, and the base branch to open it against. It becomes the squashed commit's message body at squash time.
- **Present the PR and stop for review.** Report the one-sentence behavior, branch, base, what is deliberately left out, and what the next PR will do. This is the user's moment to reslice, reorder, redirect, or call the feature done. Wait for their response.
- **On approval, close out the PR** per [references/pr-workflow.md](references/pr-workflow.md): squash its cycle commits to one clean commit (subject = the behavior, body = the description), record the branch and squashed sha in the state file, mark the PR `ready`, set Driver Status to `pr-ready`, then open the next PR as `in-progress` and create its branch. The state file is left untracked after the squash and rides along again in the next PR's first cycle commit — expected; do not amend the squashed commit.
- **Confirm the handover**: the PR is ready on its branch, against its base. Do not push the branch or open the PR — that is the user's call. Then wait for the next instruction.

**If this was the last planned PR**, there is no next PR to open and no branch to create. Skip that step and go to the completion gate in Progress instead — which may itself add a PR to the plan, in which case branch from here and carry on.

---

## Design Evolution

As cycles accumulate, your understanding deepens. Four responses, escalating in scope — see [references/design-evolution.md](references/design-evolution.md) for the full treatment:

- **Incremental refinement** (in REFACTOR): renaming, restructuring, moving things. Tests protect you. No user involvement.
- **Hypothesis revision** (between cycles): several cycles — a *recurring* backlog smell, not one instance — show the design direction needs structural change. State the revised hypothesis, revisit the PR plan, and **present both to the user for acknowledgment before restructuring**. Restructuring can't rewrite a PR already handed over or merged — it happens forward.
- **Acceptance criteria correction**: implementation reveals a criterion is misspecified. Never silently adjust tests. **Surface it to the user immediately**; corrected criteria need sign-off before continuing.
- **Starting fresh**: the approach is fundamentally wrong — delete the implementation, keep the behavioral tests as the spec, restart with a new hypothesis. Not a failure; it means TDD worked.

The two "present to the user" points are **decision gates**, not review gates: in one-shot mode they are `needs-user-input` stops, not things a standing go-ahead waves past.

---

If you get stuck, see [references/when-stuck.md](references/when-stuck.md).

---

## Phase Discipline

These restate the non-negotiable invariants already enforced in the cycle above — a checklist, not a new source of rules. If you edit one, edit both. The state file's Rules in Force header is the compressed, on-disk copy of the sharpest of these; if you change an invariant here, change it in [state-format.md](state-format.md) too — but keep that header short, since it is re-read every cycle.

- **One test per RED phase.** Writing multiple tests at once removes the feedback loop.
- **Verify RED actually fails.** A test that passes immediately was useless — it didn't drive any implementation.
- **Verify GREEN with the full suite.** Passing in isolation while breaking other tests is not green.
- **Never modify a test during GREEN.** If the test was wrong, address it in REFACTOR or before the next RED — not by weakening the assertion to make it pass.
- **Never write more implementation than the test demands.** Code for the test in front of you, not the tests you anticipate.
- **Never execute a stale plan item.** If the next planned behavior no longer makes sense given what you have learned, update the plan before writing any test.
- **Always do REFACTOR.** Even "nothing to improve here" counts. Skipping it lets debt accumulate and learning go unnoticed.
- **Never plan a PR you cannot state in one sentence without "and."** If it needs two, it is two PRs.
- **In interactive mode, never start the next PR's cycles before the current one has shipped and the user has seen it.** SHIP is a gate, not a formality — an unshipped PR that keeps growing is the failure this process exists to prevent. One-shot mode (a standing go-ahead) is the deliberate exception: it runs the whole plan through and reviews once at the end.
- **Squash a PR's cycle commits only after that PR has been reviewed** — the per-PR review in interactive mode, the single end-of-feature review in one-shot. Never squash unreviewed history; keeping it intact is what makes a bad review recoverable.
- **Never leave the suite red at a PR boundary.** Green within a cycle is a checkpoint; green at a boundary is a precondition for handing the work to a reviewer.

---

## Progress

After each complete cycle, briefly state:
- What behavior the last test verified
- What you learned or observed about the design — even "no surprises" is useful
- Where the current PR stands — what remains before it ships
- Which acceptance criteria remain unsatisfied
- What you plan to target in the next cycle, giving the user a chance to redirect

In one-shot mode these still get stated — they are the running log the user scans if the end review sends them back — but no response is expected, and the boundary report shrinks to one line: `PR 02 done at <sha>, design review clean, on to PR 03`.

At each SHIP (interactive mode), report the PR itself: its behavior, branch, base, what is deliberately left out, and what the next PR does — then stop and wait. Per-cycle progress is a status update the user can skim; a PR boundary is a decision point, and the two should feel different. This is where they reslice, reorder, redirect, or call it done.

Declare the feature complete only when all four conditions are met:

1. **PR plan**: every planned PR has been delivered (shipped in interactive mode; its cycles complete and its boundary recorded in one-shot), or consciously dropped with a reason
2. **Acceptance criteria**: every criterion has passing test coverage
3. **Learnings**: every backlog item is resolved, dismissed, or deferred
4. **Code is clean**: a final pass over what no single PR could show. Every PR already had its own per-PR design review — at its SHIP in interactive mode, at its boundary in one-shot — so **do not re-sweep the codebase**; that work is done, and repeating it here, at the point of most accumulated context, is the least useful place to spend it. Look only at what first becomes visible at feature scale: **cross-PR seams**, where duplication most easily survives because no single PR's diff contains both sides of it, and the **component and system altitudes** — dependency cycles, grab-bag packages, and rot symptoms assembled across several PRs that were each individually clean. Delegate it exactly as SHIP does — scope: the topmost PR branch against the Session `Base branch`; focus: cross-PR seams and the component and system altitudes, stated explicitly in the task prompt so the reviewer does not re-cover what each per-PR review already saw (see [references/delegated-execution.md](references/delegated-execution.md)). **Only if your environment has no delegation mechanism**, invoke the `design-review` skill in this session with the same scope and focus. If the feature is a single PR, there are no cross-PR seams — narrow the focus to the component and system altitudes alone; the same delegate-or-run-here rule applies. New findings go to the backlog and must be resolved before declaring done; In **interactive** mode every PR has already been squashed and handed over by the time this pass runs, so a fix becomes another PR in the plan — never an amendment to one already delivered, at any size. In **one-shot** nothing is squashed yet, so fixes are ordinary cycle commits; see the `Ends at` note below.

Before declaring complete, do a final backlog review. For each open item, make a conscious decision:
- **Resolve it**: address it now, which may mean new cycles
- **Dismiss it**: decide it isn't needed, with a clear reason why
- **Defer it**: acknowledge it is real work but consciously move it out of this feature — state where it is going (a follow-up story, a known backlog, a specific future decision point) and surface it explicitly to the user; get acknowledgment before proceeding

An item left open without one of these decisions is not done — it is forgotten.

**In one-shot mode**, once the four conditions hold and this backlog review is done, present the whole feature for the user's single review — the one review gate the mode keeps. **Any commits made after the last PR's boundary — condition 4's fixes, and anything the user's review asks for — land past that PR's recorded `Ends at`, and Finalization squashes only up to `Ends at`, so they would end up in no PR branch at all. Update the last PR's `Ends at` to the final commit before finalizing.** On approval, run **Finalization** in [references/pr-workflow.md](references/pr-workflow.md) to build the squashed PR stack from the linear history, then proceed to Cleanup.

---

## Delegated Execution (Subagent Mode)

If your environment gives you a way to delegate a task to an isolated agent and get its result back before proceeding (Claude Code and pi both expose one, under names that vary by version — check your actual tool list rather than assuming), you can delegate each Cycle to a fresh subagent instead of running it directly, keeping this session's own context small no matter how many cycles the feature takes. Preflight, SHIP (interactive mode), Finalization (one-shot mode), and Cleanup stay local — apart from SHIP's design review and Progress condition 4's end-of-feature pass, both of which delegate — they involve git-history decisions and handovers the user should be part of. This mode is optional, is independent of interactive vs. one-shot, and can be mixed with running cycles directly within the same session.

**Delegating cycles is the optional part. Delegating the design reviews is not** — SHIP's review of the PR diff and Progress condition 4's end-of-feature pass — which runs *before* Cleanup, as a gate on declaring the feature complete — go to a subagent in both modes, because a session that wrote the code is the wrong context to review it from. That is a separate decision from this mode, and it applies even if you never delegate a single cycle.

See [references/delegated-execution.md](references/delegated-execution.md) for the full protocol: what stays local vs. delegated, the escalation contract a delegated cycle must follow when it hits a decision that needs the user, the STATUS line format, how the driving session runs the loop, and the design-review delegation that applies regardless of mode. Read it in full before offering or using this mode, or before delegating a review — do not guess at the escalation contract from this summary.

---

## Cleanup

Once the feature is declared complete:

1. **Verify** all acceptance criteria are checked off, every planned PR has been delivered (shipped in interactive mode, or finalized from the one-shot history) or consciously dropped, and all learnings have landed in code — in tests, naming, structure, or, for decision context and conscious deferrals, in the PR descriptions — not in code comments. If any are unresolved, do not clean up — run the cycles needed to close them first, then return here.
2. **Verify the stack.** Report each PR's branch, base, and status, so the user knows exactly what is outstanding and in what order it must merge. If earlier PRs have merged while later ones were being built, restack them now — see [references/pr-workflow.md](references/pr-workflow.md).
3. **Decide the state file's fate.** After the last squash it is untracked in the working tree — there is no cleanup commit to make either way. The choice is only whether to `rm` it or keep it on disk as a record of what was learned. Default is to delete it; the code and tests tell the whole story. Ask; don't assume.

The history is one commit per reviewable increment — reached PR-by-PR at each SHIP in interactive mode, or all at once in Finalization from one-shot. Either way, do not now collapse the stack into one commit; that would undo the point of slicing it.
