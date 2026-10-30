---
name: refactor
description: "Refactors existing code on direct request — 'break up X', 'extract Y', 'clean up this function', 'untangle this' — as a behavior-preserving change held green by tests. First checks that the target has a test net that would actually catch a mistake, and hands off to backfill-tests when it doesn't. Then restructures in small committed steps, running the tests after each, applying a fixed standard for naming, function decomposition, top-down ordering, comments, and deletion. Use when the user asks to restructure code without changing what it does; not for adding behavior (use slice-plan) or for a review without changes (use design-review)."
compatibility: "Requires the design-principles skill, and backfill-tests for targets without a trustworthy net — no bundled fallback. Requires git."
metadata:
  soft-deps: design-principles backfill-tests
---

# Refactor

The user names a target and a direction — "break up `process_order`". You change its structure,
never its behavior, and the tests are what prove you didn't. A refactor without a net that would
catch a mistake is a rewrite with optimism; the first job is finding out which one you're doing.

## Setup

1. **Clean tree.** Note the current sha. If the tree is dirty, have the user commit or stash.
2. **Green baseline.** Run the full suite. A red baseline means green proves nothing later — get
   the user's sign-off on known failures before going on.
3. **Pin the scope.** The target is what the user named, plus whatever the change forces you to
   touch (its callers, for a signature change). Everything else you notice goes in the report's
   `Noticed, not done`. Any behavior change the request asks for is out of scope: say so, and
   route it to slice-plan once this refactor lands. A module-sized target is a sequence of function-sized ones: take them one
   at a time, net check included.

## Check the net

Coverage percentage is not the question. The question is: **if you break this code, does a test
go red?** Answer it directly:

1. Find the tests that exercise the target — by search for its name and its callers, or branch
   coverage scoped to the target file if the project has a coverage tool.
2. **Probe it.** Pick three to five points in the target that the coming refactor will move or
   reshape — a branch condition, a constant, a return value, the order of two guards that can
   both apply to one input. Each perturbation must change what the code does for some input;
   one that doesn't proves nothing either way. Perturb each, run the targeted tests, and revert
   with `git checkout -- <path>`. Each perturbation must turn a test red.

If `backfill-tests` already ran on this target, its "what isn't pinned" list names gaps left on
purpose. Don't probe those; carry them into the report's `Unpinned`.

Then:

- **Every probe went red** — proceed.
- **Any probe stayed green, or no tests exercise the target** — stop. Tell the user which
  behavior is unpinned (the probe that survived names it) and recommend running the
  `backfill-tests` skill on the target first. Do not write the missing tests yourself inside this
  skill — backfilling has its own bar and freezes production code, which this skill doesn't.
  If the user says proceed anyway, do so, and list every unpinned behavior in the report.
- **Tests go red under any internal change, including ones that preserve behavior** (they assert
  which collaborators got called) — say so before starting: they will fail during the refactor
  without meaning anything, and the net is thinner than it looks.

## Refactor in small steps

Each step is one named move — extract function, rename, inline, move, reorder, delete — small
enough that a red result points at it. After each step, run the targeted tests:

- **Green: commit it** — `refactor: <move>`. Each step is its own commit, so any one can be undone
  without losing the others.
- **Red: discard the step** with `git reset --hard HEAD` — the last commit is the last green step
  — don't debug forward. Then take a smaller step.

Run the full suite at the end. Red there: find the step with `git bisect` over the step commits,
and revert that commit.

- **Don't change behavior.** A bug you find stays in, logged for the report. A test you have to
  edit to get green is a behavior change or a wiring test — stop and tell the user which.
- **Don't touch the tests** beyond the mechanical consequences of a rename or move.

Apply [references/standard.md](references/standard.md) as you go, not as a pass at the end — it
is the standard the result is held to. For it, **the scope** is the code your steps rewrite, and
**the log** is the report below. When you need the precise name for why something is wrong (why a
function feels too big, which smell this is), use the `design-principles` skill's
`design-catalog.md`, starting at "When a unit feels too big".

**Stopping is a real outcome.** If the target, examined, has no nameable cause behind its size
or shape, say so and leave it. "Break up X" is a request to make X clearer, not a quota of
extracted functions.

## Finish

Done when the full suite is green, `git diff <sha>` touches production code (and only mechanical
test edits), and each change in it traces to the user's request or the standard.

Report briefly:

- **What changed** — the moves, in one line each, the commit range `<sha>..HEAD`, and the net line
  count. Offer to squash; don't push.
- **Decisions and hazards** — decision context and edit-site hazards (file:line) the standard
  routed here.
- **Unpinned** — behavior the net doesn't cover: gaps carried from backfill-tests, gaps the user
  chose to proceed past, and missing pins found while deleting.
- **Bugs found** — left in place, each with how to reproduce it.
- **Noticed, not done** — out-of-scope candidates, including `deletion candidate (unpinned)`
  entries from the standard.
