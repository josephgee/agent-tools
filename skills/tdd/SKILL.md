---
name: tdd
description: "Guides strict Test-Driven Development (TDD) as a learning loop, delivered as a stack of small reviewable PRs. Use when building a feature: decompose it into an ordered sequence of PR-sized behavioral increments, then drive each one through THINK-RED-GREEN-REFACTOR cycles — choose the next behavior, write one failing test, make it pass with the simplest possible code, then refactor and reflect — and SHIP it as a clean, independently reviewable commit before starting the next. Also use when asked to break a feature into small, reviewable, incrementally shippable pull requests."
compatibility: "Requires the design-principles and design-review skills to be installed alongside it — the design checks at REFACTOR, SHIP, and Cleanup depend on them, with no bundled fallback."
metadata:
  soft-deps: design-principles design-review
---

# TDD

TDD is a learning loop. You start with a hypothesis about the right design and test it against reality one behavior at a time. Each cycle — writing a test, making it pass, then reflecting on the code — teaches you something. That learning feeds back into the design. Sometimes the design evolves gradually. Sometimes you learn enough to know the current approach is wrong and you start fresh. Both are expected outcomes, not failures.

Work is delivered as a stack of small PRs. There are three levels, and keeping them distinct is what makes the process work:

- **Acceptance criteria** are behavioral — they describe what the feature must do from the outside, as observed by a user or consumer. They are the fixed target. They do not describe how the feature is built.
- **The PR plan** is the delivery layer — an ordered sequence of independently reviewable increments, each changing observable product behavior, however small. Each PR is closed out and handed over before the next begins.
- **Design hypothesis** is the implementation layer — your current best theory for how to build what the criteria require. It is expected to evolve as you learn.

Inside one PR you run cycles. At the end of one you run SHIP. The loop stops when every planned PR has shipped, all acceptance criteria are satisfied by passing tests, and all learnings captured in the backlog are resolved. The discipline of one test at a time keeps the feedback tight; the discipline of one small PR at a time keeps the work reviewable.

## State File

Maintain a state file at `plans/tdd-<feature-slug>.md` throughout the session. This is the source of truth for resuming work, tracking design evolution, and managing context as the window grows. It is named after the effort so that parallel TDD sessions never collide, and it is committed with the work so that every cycle commit is a complete rollback point.

See [state-format.md](state-format.md) for the format when creating the file, and for how to choose the directory and slug.

**Read** the state file when starting up (to detect a prior session). Also re-read the PR Plan, Backlog, and Current Position sections at the start of every THINK, unconditionally — before choosing the next behavior, not only when you notice you've lost track. This is a fixed checkpoint, not a judgment call.

**Write** the state file (this is the canonical list of write points — the phase sections below restate each one at the moment it applies):
- When starting fresh (create it)
- During THINK — if the PR plan changes, write the updated plan before proceeding to RED
- At the start of RED — record the active test and current phase before writing any code
- At each phase transition — update current phase
- After completing REFACTOR — append cycle log entry, update criteria statuses, update design hypothesis, update the current PR's cycle list (check off the completed behavior; minor resequencing is fine here — significant changes belong in THINK), update backlog
- At SHIP — record the PR description, branch, and commit; mark the PR `ready`; open the next PR
- Driver Status — keep current at every phase transition (default `in-progress`); update immediately when escalating (`needs-user-input`, with a one-sentence `Reason`), when a PR is ready to hand over (`pr-ready`), or when declaring the feature complete (`feature-complete`). See [Delegated Execution](#delegated-execution-subagent-mode).

Keep the file's diff quiet — append entries and tick checkboxes rather than reflowing prose. It rides along in every PR's diff, so its churn is a reviewer's problem. See [references/pr-workflow.md](references/pr-workflow.md).

---

## Startup

**First:** Look for existing state files — glob `tdd-*.md` in `plans/`, `docs/plans/`, and `.plans/`. A state file is identifiable by its `# TDD Session State` heading even if it has been renamed.

- **None found** — start fresh.
- **Exactly one** — offer to resume it.
- **More than one** — list them with feature name and last-updated date, and ask which to resume or whether to start a new effort. Multiple files are expected: efforts are named individually so they can run in parallel.

**If resuming:**
1. Read the state file.
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

Read [references/pr-slicing.md](references/pr-slicing.md) in full before drafting the plan. It covers the sizing test, how to split a PR that is too big, how to choose between a thin real slice and an inert skeleton for the first PR, and the slicing anti-patterns. Do not guess at the decomposition from this summary.

For each PR, state a one-sentence behavior (no "and"), the acceptance criteria it advances, and the cycles you expect it to take. The sequence follows the outside-in strategy — the first PR establishes an end-to-end path, later PRs replace stubs with real behavior, then add functionality, then cover edge cases — which naturally yields PR-shaped work.

Present the sequence as an ordered list and invite the user to adjust it. This is the highest-value thing for them to push back on: it decides what each reviewer will be asked to read. Record it in the state file. It is a starting point, not a commitment — it will evolve as you learn.

**Alignment gate**
Once all four are established, present a concise summary:

> **Feature**: [one or two sentences]
> **Acceptance criteria**: [bulleted list]
> **Design hypothesis**: [brief description]
> **PR plan**: [ordered PR sequence, one sentence each]
> **State file**: `plans/tdd-<feature-slug>.md`

Include the proposed slug so the user can correct it — it is permanent for the effort and names the branches too. Then ask: *"Are we aligned? Shall I proceed?"* Do not begin any cycles until the user explicitly confirms.

### Setup

After alignment is confirmed:

If the project uses git, confirm the working tree is clean before proceeding: `git status` should show no uncommitted changes unrelated to this session. Stash or commit any existing work first — TDD cycle commits should contain only cycle work.

1. **Identify the test runner.** Find the test framework and how to run tests (e.g., `npm test`, `pytest`, `cargo test`, `go test ./...`). Read `package.json`, `pyproject.toml`, or equivalent if unsure. If the test runner cannot be determined from project files, ask the user.
2. **Run the full test suite.** Confirm it passes cleanly. If there are pre-existing failures, surface them and get confirmation — you need a green baseline.
3. **Choose the plans directory.** Use whichever of `plans/`, `docs/plans/`, or `.plans/` the repo already has. Create `plans/` only if none exists. If more than one exists, ask which to use rather than guessing.
4. **Create the state file** at `<plans-dir>/tdd-<feature-slug>.md` with session info, feature definition, acceptance criteria, initial design hypothesis, and the PR plan.
5. **Create the first PR's branch.** If the project uses git: `git switch -c tdd/<feature-slug>/01-<pr-slug>`. See [references/pr-workflow.md](references/pr-workflow.md) for the stack layout. Record the base branch in the state file — it is what PR 01 will be reviewed against.
6. **Commit the state file.** If the project uses git: `git add <state-file> && git commit -m "tdd: begin <feature name>"`. This is the baseline from which each cycle builds a rollback point.
7. **Optionally offer** to mark the plans directory `linguist-generated=true` in `.gitattributes`, so the state file collapses by default in PR diffs. Offer it; don't add it unilaterally.

---

## Test Strategy

These principles apply to every test written throughout the feature.

**Outside-in, E2E first**: Begin with a test that exercises the full feature end-to-end, even if behavior underneath is stubbed. This proves the feature works as a whole before filling in the details. Once the outer shell passes, work inward: replace stubs with real implementations, then add functionality, then cover edge cases. Testing outside-in keeps observable behavior as the primary concern at every stage.

**Merge-safe from the first PR**: Because each PR ships on its own, a stubbed end-to-end flow can expose a half-working path to real users. The first PR must therefore be either the thinnest *genuinely working* vertical slice, or an end-to-end skeleton that is **inert** — entry point unregistered, route not mounted, or behind an off-by-default flag. Decide which at planning time, record it in the state file, and say in the PR description what makes it safe. This constrains where you start; it does not change the outside-in strategy.

**Behavioral, not wiring**: Tests should verify observable outcomes — return values, state changes, effects at the system boundary — not internal structure. A test that asserts "object A called object B's method" is a wiring test: it breaks when you refactor internals even when the feature still works correctly, and it doesn't tell you whether the feature does the right thing. Ask "did the feature behave correctly?" not "did it use the right objects internally?"

**Live objects over mocks**: Use real objects wherever practical. Mocks can be wired incorrectly, obscure real behavior, and produce false confidence. Reach for a mock when:
- Crossing a **system boundary**: external APIs, databases, file systems, message queues, third-party services
- The real thing is **prohibitively slow** for the test suite to run regularly

When you do mock, mock at the boundary — not deep inside your own code.

---

## The Cycle

Cycles run inside a PR. Repeat them until the current PR's behavior is fully delivered, then run SHIP and move to the next PR. The feature is done when every planned PR has shipped, all acceptance criteria have passing tests, all backlog items are resolved, dismissed, or deferred, and a final code review confirms the code is clean. See Progress for the full completion gate — this is a summary, not a second source of truth.

### THINK — Choose the Next Behavior

**First, re-read the PR Plan, Backlog, and Current Position sections of the state file.** Do this every time, unconditionally — do not rely on noticing you've lost track. Know which PR you are in and what remains in it before choosing anything.

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
- Run the tests. **Confirm the new test fails for the right reason** — the expected behavior is missing, not a compile error, import error, or typo in the assertion. If it fails for the wrong reason, fix the test before moving on. **If the test passes immediately**, it is testing existing behavior — return to THINK, choose a different behavior, and delete this test (or keep it only if it fills a genuine gap in existing coverage).

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

Runs once per PR, after its final cycle — not after every cycle. Read [references/pr-workflow.md](references/pr-workflow.md) for the mechanics; this is the sequence, not the commands.

**SHIP ends in a review gate.** A PR boundary is where a human reads the work, so treat it the way Preflight treats the alignment gate: present the finished PR and stop. This is the user's opportunity to reject the slicing, reorder what's left, redirect the design, or call the feature done early — and it is far cheaper for them to do that here than three PRs later. Do not roll into the next PR's cycles until they respond. If the user gives a standing go-ahead ("keep going, don't stop each time"), honour it and continue reporting at each SHIP without pausing.

- Update the state file: set phase to SHIP.
- **Confirm the full suite is green** and the working tree is clean. A PR that leaves tests failing is not shippable at any size.
- **Review the whole PR diff**, not just the last cycle's. Per-cycle REFACTOR only ever sees one cycle, so duplication introduced in the first cycle and repeated in the fourth survives it — this pass is the first thing that looks at the increment as a unit. Apply the [refactor-checklist](references/refactor-checklist.md) across the combined diff yourself, then **delegate the design review to a subagent** — see [references/delegated-execution.md](references/delegated-execution.md) for the task prompt and why this one delegates even though SHIP otherwise stays local. This pass's focus is the statement, name, function, and class altitudes — components and cross-PR seams belong to the end-of-feature pass, not this one — and the task prompt passes that focus explicitly. **Only if your environment has no delegation mechanism**, run the same review in this session: invoke the `design-review` skill yourself with the same explicit scope and focus, accepting that the catalog rides in this session's context for the rest of the feature. **Triage the findings yourself either way**: you know what was deliberate, so dismiss what was consciously deferred and say which, fix what is worth fixing now while staying green, and send the rest to the backlog as named entries. Do this before writing the PR description, so the fixes ride in the squashed commit.
- **Confirm the PR is genuinely mergeable on its own**: it changes observable behavior, it does not depend on a later PR to make sense, and anything stubbed underneath is inert or flag-gated.
- **Write the PR description** into the state file *before* squashing, so it is committed with the work: what changes, which criteria it advances, what is deliberately not here (stubs, deferred edge cases, flags), and the base branch to open it against.
- **Squash the cycle commits into one clean commit.** The commit subject is the PR's one-sentence behavior; the body is the PR description just written.
- **Update the state file again**: mark this PR `ready` with its branch and resulting commit sha, open the next PR as `in-progress`, reset Current Position to its first cycle, and set Driver Status to `pr-ready`. A commit cannot contain its own sha, so this edit stays uncommitted and rides along in the next PR's first cycle commit. That is expected — do not amend the squashed commit to absorb it.
- **Create the next PR's branch** from the commit just made, so cycles can resume on it once the gate clears. Driver Status returns to `in-progress` when that PR's first cycle begins.
- **Report to the user and stop**: the PR is ready, its branch and base, its one-sentence behavior, what is deliberately left out, and what the next PR will do. Do not push the branch or open the PR — that is the user's call. Then wait, unless they have given a standing go-ahead.

**If this was the last planned PR**, there is no next PR to open and no branch to create. Skip those two steps and go to the completion gate in Progress instead — which may itself add a PR to the plan, in which case branch from here and carry on.

---

## Design Evolution

As cycles accumulate, your understanding deepens. There are three levels of response to what you learn:

**Incremental refinement** (handled in REFACTOR): Small continuous improvements — renaming, restructuring, moving things. The tests protect you.

**Hypothesis revision** (handled between cycles): When several cycles reveal that the design direction needs structural change — not just cleanup — pause before the next THINK. A recurring backlog entry naming the same smell (named via the `design-principles` skill's `design-catalog.md`) across multiple cycles is a concrete version of this trigger — recurrence, not any single instance, is what elevates it from a local refactor to a hypothesis revision. State the revised hypothesis explicitly. A hypothesis revision almost always requires revisiting the PR plan — some planned PRs may no longer apply, new ones may be needed, the sequence may change. Present the revised hypothesis and the revised PR plan together to the user: what changed, what was learned that drove it, and what the new direction and sequence are. Get acknowledgment on both before restructuring. Then restructure the implementation to match the revised hypothesis. Tests that still describe valid behavior are kept; implementation can change freely. Confirm all tests pass, update the state file hypothesis and PR plan, then begin the next THINK.

Restructuring is bounded by what has already shipped. A PR that has been handed over — and especially one that has merged — cannot be quietly rewritten; the change has to happen forward, in the PR you are in now or a new one added to the plan. If the revision invalidates a PR still under review, say so to the user explicitly so they can stop reviewing it.

**Acceptance criteria correction**: Implementation occasionally reveals that a criterion is misspecified — untestable as written, contradicts another, or reflects a misunderstanding of the feature. Do not silently adjust tests to accommodate this. Surface it to the user immediately, discuss whether to correct, narrow, or remove the criterion, and update the state file. Corrected criteria require user sign-off before continuing.

**Starting fresh**: When you learn the current approach is fundamentally wrong, be willing to delete the implementation entirely and restart with a new design. The behavioral tests you have written remain — they are a specification of what the system must do, independent of how it does it. State the new design hypothesis in the state file, then use the existing tests to guide you through the next GREEN phase.

Starting fresh is not a failure. It means TDD worked: you learned something important before committing to the wrong design permanently.

---

If you get stuck, see [references/when-stuck.md](references/when-stuck.md).

---

## Phase Discipline

These restate the non-negotiable invariants already enforced in the cycle above — a checklist, not a new source of rules. If you edit one, edit both.

- **One test per RED phase.** Writing multiple tests at once removes the feedback loop.
- **Verify RED actually fails.** A test that passes immediately was useless — it didn't drive any implementation.
- **Verify GREEN with the full suite.** Passing in isolation while breaking other tests is not green.
- **Never modify a test during GREEN.** If the test was wrong, address it in REFACTOR or before the next RED — not by weakening the assertion to make it pass.
- **Never write more implementation than the test demands.** Code for the test in front of you, not the tests you anticipate.
- **Never execute a stale plan item.** If the next planned behavior no longer makes sense given what you have learned, update the plan before writing any test.
- **Always do REFACTOR.** Even "nothing to improve here" counts. Skipping it lets debt accumulate and learning go unnoticed.
- **Never plan a PR you cannot state in one sentence without "and."** If it needs two, it is two PRs.
- **Never start the next PR's cycles before the current one has shipped and the user has seen it.** SHIP is a gate, not a formality — an unshipped PR that keeps growing is the failure this process exists to prevent, and a PR boundary is where the user gets to redirect. The only exception is a standing go-ahead from the user.
- **Never leave the suite red at a PR boundary.** Green within a cycle is a checkpoint; green at SHIP is a precondition for handing the work to a reviewer.

---

## Progress

After each complete cycle, briefly state:
- What behavior the last test verified
- What you learned or observed about the design — even "no surprises" is useful
- Where the current PR stands — what remains before it ships
- Which acceptance criteria remain unsatisfied
- What you plan to target in the next cycle, giving the user a chance to redirect

At each SHIP, report the PR itself: its behavior, branch, base, what is deliberately left out, and what the next PR does — then stop and wait. Per-cycle progress is a status update the user can skim; a PR boundary is a decision point, and the two should feel different. This is where they reslice, reorder, redirect, or call it done.

Declare the feature complete only when all four conditions are met:

1. **PR plan**: every planned PR has shipped, or has been consciously dropped with a reason
2. **Acceptance criteria**: every criterion has passing test coverage
3. **Learnings**: every backlog item is resolved, dismissed, or deferred
4. **Code is clean**: a final pass over what no single PR could show. Every PR was already reviewed at its own SHIP, so **do not re-sweep the codebase** — that work is done, and repeating it here, at the point of most accumulated context, is the least useful place to spend it. Look only at what first becomes visible at feature scale: **cross-PR seams**, where duplication most easily survives because no single PR's diff contains both sides of it, and the **component and system altitudes** — dependency cycles, grab-bag packages, and rot symptoms assembled across several PRs that were each individually clean. Delegate it exactly as SHIP does — scope: the feature branch against its base; focus: cross-PR seams and the component and system altitudes, stated explicitly in the task prompt so the reviewer does not re-cover what each SHIP already saw (see [references/delegated-execution.md](references/delegated-execution.md)). **Only if your environment has no delegation mechanism**, invoke the `design-review` skill in this session with the same scope and focus. If the feature shipped as a single PR, there are no cross-PR seams — narrow the focus to the component and system altitudes alone; the same delegate-or-run-here rule applies. New findings go to the backlog and must be resolved before declaring done; if a finding is substantial, it becomes another PR in the plan rather than an amendment to one already shipped.

Before declaring complete, do a final backlog review. For each open item, make a conscious decision:
- **Resolve it**: address it now, which may mean new cycles
- **Dismiss it**: decide it isn't needed, with a clear reason why
- **Defer it**: acknowledge it is real work but consciously move it out of this feature — state where it is going (a follow-up story, a known backlog, a specific future decision point) and surface it explicitly to the user; get acknowledgment before proceeding

An item left open without one of these decisions is not done — it is forgotten.

---

## Delegated Execution (Subagent Mode)

If your environment gives you a way to delegate a task to an isolated agent and get its result back before proceeding (Claude Code and pi both expose one, under names that vary by version — check your actual tool list rather than assuming), you can delegate each Cycle to a fresh subagent instead of running it directly, keeping this session's own context small no matter how many cycles the feature takes. Preflight, SHIP, and Cleanup stay local apart from their design reviews — they involve git-history decisions and handovers the user should be part of. This mode is optional and can be mixed with running cycles directly within the same session.

**Delegating cycles is the optional part. Delegating the design reviews is not** — SHIP's review of the PR diff and Cleanup's end-of-feature pass go to a subagent in both modes, because a session that wrote the code is the wrong context to review it from. That is a separate decision from this mode, and it applies even if you never delegate a single cycle.

See [references/delegated-execution.md](references/delegated-execution.md) for the full protocol: what stays local vs. delegated, the escalation contract a delegated cycle must follow when it hits a decision that needs the user, the STATUS line format, how the driving session runs the loop, and the design-review delegation that applies regardless of mode. Read it in full before offering or using this mode, or before delegating a review — do not guess at the escalation contract from this summary.

---

## Cleanup

Once the feature is declared complete:

1. **Verify** all acceptance criteria are checked off, every planned PR has shipped or been consciously dropped, and all learnings have landed in code — in tests, naming, structure, or explicit *why* comments for conscious deferrals. If any are unresolved, do not clean up — run the cycles needed to close them first, then return here.
2. **Verify the stack.** Report each PR's branch, base, and status, so the user knows exactly what is outstanding and in what order it must merge. If earlier PRs have merged while later ones were being built, restack them now — see [references/pr-workflow.md](references/pr-workflow.md).
3. **Decide the state file's fate.** Default is to delete it — the code and tests tell the whole story. But the file is effort-named and lives in a durable plans directory, so keeping it as a record of what was learned is a reasonable choice. Ask; don't assume.

If deleting, the removal is its own commit on top of the last PR's branch — `git rm <state-file> && git commit -m "tdd: remove session artifact"` — because the last PR has already been squashed and reported as ready, and a shipped PR is not rewritten in place. Tell the user which it should be: folded into the final PR if that one has not been opened or reviewed yet, or a trivial follow-up PR if it has.

There is no end-of-feature squash. Each PR was already squashed to a single clean commit at SHIP, so the history is one commit per reviewable increment — which is the shape you want. Do not collapse the stack into one commit; that would undo the point of slicing it.
