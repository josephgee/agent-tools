---
name: tdd
description: "Guides strict Test-Driven Development (TDD) as a learning loop. Use when building a feature via THINK-RED-GREEN-REFACTOR cycles: choose the next behavior, write one failing test, make it pass with the simplest possible code, then refactor and reflect on design. Repeat, evolving the design as you learn, until all acceptance criteria are met."
---

# TDD

TDD is a learning loop. You start with a hypothesis about the right design and test it against reality one behavior at a time. Each cycle — writing a test, making it pass, then reflecting on the code — teaches you something. That learning feeds back into the design. Sometimes the design evolves gradually. Sometimes you learn enough to know the current approach is wrong and you start fresh. Both are expected outcomes, not failures.

Two things stay distinct throughout:
- **Acceptance criteria** are behavioral — they describe what the feature must do from the outside, as observed by a user or consumer. They are the fixed target. They do not describe how the feature is built.
- **Design hypothesis** is the implementation layer — your current best theory for how to build what the criteria require. It is expected to evolve as you learn.

The loop stops when all acceptance criteria are satisfied by passing tests and all learnings captured in the backlog are resolved. The discipline of one test at a time keeps the feedback tight and the learning actionable.

## State File

Maintain a `tdd-state.md` file in the project root throughout the session. This is the source of truth for resuming work, tracking design evolution, and managing context as the window grows.

See [state-format.md](state-format.md) for the format when creating the file.

**Read** the state file when starting up (to detect a prior session). Also re-read the Plan, Backlog, and Current Position sections at the start of every THINK, unconditionally — before choosing the next behavior, not only when you notice you've lost track. This is a fixed checkpoint, not a judgment call.

**Write** the state file (this is the canonical list of write points — the phase sections below restate each one at the moment it applies):
- When starting fresh (create it)
- During THINK — if the plan changes, write the updated plan before proceeding to RED
- At the start of RED — record the active test and current phase before writing any code
- At each phase transition — update current phase
- After completing REFACTOR — append cycle log entry, update criteria statuses, update design hypothesis, update plan (check off the completed behavior; minor resequencing is fine here — significant changes belong in THINK), update backlog

---

## Startup

**First:** Check for `tdd-state.md` in the project root.

**If resuming** (file exists):
1. Read the state file.
2. Report to the user: feature, current phase, active test if any, remaining criteria, remaining plan, and current design hypothesis.
3. Ask whether to resume from that position or start fresh (which creates a new state file and begins a new session). If starting fresh and the project uses git, note that prior TDD commits remain in the history — when squashing at the end of the new session, scope the rebase to include all `tdd:` commits from both sessions.
4. If resuming, skip to the current phase — do not repeat completed setup.

**If starting fresh** (no file, or user chose to restart), run the preflight before touching any code.

### Preflight

Establish and align on three things in order. Each builds on the previous — do not skip ahead.

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

**4. Plan**
Sketch the intended order of cycles. The plan prioritizes getting an end-to-end flow working first — a test that exercises the full feature from the outside, even if behavior underneath is stubbed out. Then work inward: replace stubs with real behavior, add functionality, then cover edge cases and error conditions.

Present the plan as an ordered list and invite the user to adjust it. Record it in the state file. This is a starting point, not a commitment — it will evolve as you learn.

**Alignment gate**
Once all four are established, present a concise summary:

> **Feature**: [one or two sentences]
> **Acceptance criteria**: [bulleted list]
> **Design hypothesis**: [brief description]
> **Plan**: [ordered cycle sequence, E2E first]

Then ask: *"Are we aligned? Shall I proceed?"* Do not begin any cycles until the user explicitly confirms.

### Setup

After alignment is confirmed:

If the project uses git, confirm the working tree is clean before proceeding: `git status` should show no uncommitted changes unrelated to this session. Stash or commit any existing work first — TDD cycle commits should contain only cycle work.

1. **Identify the test runner.** Find the test framework and how to run tests (e.g., `npm test`, `pytest`, `cargo test`, `go test ./...`). Read `package.json`, `pyproject.toml`, or equivalent if unsure. If the test runner cannot be determined from project files, ask the user.
2. **Run the full test suite.** Confirm it passes cleanly. If there are pre-existing failures, surface them and get confirmation — you need a green baseline.
3. **Create the state file** with session info, feature definition, acceptance criteria, initial design hypothesis, and plan.
4. **Commit the state file.** If the project uses git, stage and commit: `git add tdd-state.md && git commit -m "tdd: begin <feature name>"`. This is the baseline from which each cycle builds a rollback point.

---

## Test Strategy

These principles apply to every test written throughout the feature.

**Outside-in, E2E first**: Begin with a test that exercises the full feature end-to-end, even if behavior underneath is stubbed. This proves the feature works as a whole before filling in the details. Once the outer shell passes, work inward: replace stubs with real implementations, then add functionality, then cover edge cases. Testing outside-in keeps observable behavior as the primary concern at every stage.

**Behavioral, not wiring**: Tests should verify observable outcomes — return values, state changes, effects at the system boundary — not internal structure. A test that asserts "object A called object B's method" is a wiring test: it breaks when you refactor internals even when the feature still works correctly, and it doesn't tell you whether the feature does the right thing. Ask "did the feature behave correctly?" not "did it use the right objects internally?"

**Live objects over mocks**: Use real objects wherever practical. Mocks can be wired incorrectly, obscure real behavior, and produce false confidence. Reach for a mock when:
- Crossing a **system boundary**: external APIs, databases, file systems, message queues, third-party services
- The real thing is **prohibitively slow** for the test suite to run regularly

When you do mock, mock at the boundary — not deep inside your own code.

---

## The Cycle

Repeat until all acceptance criteria have passing tests, all backlog items are resolved, dismissed, or deferred, and a final code review confirms the code is clean. See Progress for the full completion gate — this is a summary, not a second source of truth.

### THINK — Choose the Next Behavior

**First, re-read the Plan, Backlog, and Current Position sections of `tdd-state.md`.** Do this every time, unconditionally — do not rely on noticing you've lost track.

State in one sentence — no "and" — what the next useful behavior is.

**Check the plan and backlog together.** The default is the next plan item — but first check whether any backlog item should come before it (an edge case that blocks further progress, a design concern that must be resolved). If a backlog item belongs next, promote it to the plan before proceeding.

**Never execute a stale plan item.** Before committing, ask: does this item still make sense given everything learned so far? If not, update the plan first:
- *Minor change* (resequencing, promoting a backlog item): update the plan silently and proceed.
- *Dropping a planned behavior*: surface it to the user — briefly state what was planned, why it is no longer needed, and what comes instead — before proceeding.
- *Major resequencing*: surface the revised plan to the user before proceeding.

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
- A new branch by type, source, provider, mode, or role?
- A class or function now has two reasons to change?
- Test setup got harder because concerns are mixed?

If none: note "no design pressure" and move on. If any: either refactor now (smallest change that reduces pressure, while staying green) or log it in the backlog with a clear reason to revisit. No abstractions for pattern-matching or hypothetical futures — only when pressure is visible in the current code.

**Capture backlog items:**
Review everything noticed during this cycle that wasn't acted on — edge cases not yet covered, refactors worth considering later, work that emerged as necessary. Add each to the backlog in the state file. This is the main moment for backlog capture: be deliberate about it, not incidental.

If any item is being marked deferred rather than open, surface it to the user now with the reason and where it is going. Do not wait until the completion review — the user should know about deferred work as soon as the decision is made.

**Update the state file:**
- Append a cycle log entry (test, behavior verified, what was learned, hypothesis change if any).
- Mark any newly satisfied acceptance criteria.
- Update the design hypothesis if it changed.
- Update the plan: check off the completed behavior. Minor resequencing based on this cycle's learning is fine here. Dropping an item or major resequencing belongs in THINK, not silently in REFACTOR.
- Update the backlog (new items, and any resolved, dismissed, or deferred this cycle).
- Set phase to between-cycles and clear the active test.

If there is nothing to improve and nothing new to observe, say so explicitly. Silence is not a review.

**Commit the cycle.** If the project uses git, stage all changes — the new test, the implementation, the refactoring, and the updated state file — and commit together: `git add -A && git commit -m "tdd: <behavior from THINK>"`. This commit is a rollback point. If the feature later goes off track, `git reset --hard <hash>` returns to this exact state, including the design hypothesis, plan, and backlog at this moment.

---

## Design Evolution

As cycles accumulate, your understanding deepens. There are three levels of response to what you learn:

**Incremental refinement** (handled in REFACTOR): Small continuous improvements — renaming, restructuring, moving things. The tests protect you.

**Hypothesis revision** (handled between cycles): When several cycles reveal that the design direction needs structural change — not just cleanup — pause before the next THINK. State the revised hypothesis explicitly. A hypothesis revision almost always requires revisiting the plan — some planned items may no longer apply, new ones may be needed. Present the revised hypothesis and the revised plan together to the user: what changed, what was learned that drove it, and what the new direction and sequence are. Get acknowledgment on both before restructuring. Then restructure the implementation to match the revised hypothesis. Tests that still describe valid behavior are kept; implementation can change freely. Confirm all tests pass, update the state file hypothesis and plan, then begin the next THINK.

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

---

## Progress

After each complete cycle, briefly state:
- What behavior the last test verified
- What you learned or observed about the design — even "no surprises" is useful
- Which acceptance criteria remain unsatisfied
- What you plan to target in the next cycle, giving the user a chance to redirect

Declare the feature complete only when all three conditions are met:

1. **Acceptance criteria**: every criterion has passing test coverage
2. **Learnings**: every backlog item is resolved, dismissed, or deferred
3. **Code is clean**: conduct a dedicated final review of the full codebase — duplication, naming, structure, dead weight. This is a separate end-of-feature pass, not a repeat of per-cycle REFACTOR. Individual cycles clean up locally; this pass looks at the whole. New findings go to the backlog and must be resolved before declaring done.

Before declaring complete, do a final backlog review. For each open item, make a conscious decision:
- **Resolve it**: address it now, which may mean new cycles
- **Dismiss it**: decide it isn't needed, with a clear reason why
- **Defer it**: acknowledge it is real work but consciously move it out of this feature — state where it is going (a follow-up story, a known backlog, a specific future decision point) and surface it explicitly to the user; get acknowledgment before proceeding

An item left open without one of these decisions is not done — it is forgotten.

---

## Cleanup

Once the feature is declared complete:
1. Verify all acceptance criteria are checked off and all learnings have landed in code — in tests, naming, structure, or explicit *why* comments for conscious deferrals. If any are unresolved, do not delete the state file — run the cycles needed to close them first, then return here.
2. Delete `tdd-state.md`. The code and tests tell the whole story.
3. If the project uses git, remove and commit the deletion: `git rm tdd-state.md && git commit -m "tdd: remove session artifact"`.
4. **Optionally squash.** To produce a clean history without individual cycle commits, use `git rebase -i <hash-before-first-tdd-commit>` and squash or fixup the TDD commits into one (or a small number of meaningful commits). Find the target hash with `git log --oneline` — it is the commit immediately before the first `tdd: begin` entry. This removes the state file from history entirely, leaving only the finished feature.
