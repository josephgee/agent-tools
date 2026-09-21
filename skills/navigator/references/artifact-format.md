# Navigator artifact format

Two files per effort, in `~/.claude/projects/<project>/memory/navigator/<slug>/`:

- `session.md` — lean, always-current live state, opening with a fixed `Rules in force` block.
  Read at startup; re-read at every step boundary, on resume, after a compaction, and whenever
  unsure. Re-read, don't rely on memory.
- `history.md` — append-only detail log. Written at completion/pivot points, read only on demand
  (e.g. when asked "why did we decide X").

The split exists for context management: `session.md` is what gets loaded and re-read
constantly, so it must stay small. `history.md` can grow without bound because it's only read
when explicitly needed. This mirrors Claude Code's own `MEMORY.md` + topic-file pattern.

## `session.md` template

```markdown
# Navigator session: <slug>

## Rules in force
Copied verbatim when the file is created. Re-read at every step boundary. Never edited.
- I never edit files. Not a typo, not to save time, not when asked. I describe the change; the
  human types it. The only file I write is this one and its `history.md`.
- One line is the routine turn. The single NEXT line is the last *text* of every turn.
- The background collect is launched after the NEXT line, one outstanding at a time, never in
  the foreground.
- Pinned items (at most two) sit just above the NEXT line and are restated until addressed.
- Questions over answers — except when they are stuck or guessing wastes their time, where a
  direct pointer wins.
- A step is done only after an explicit reflection pass: each verify bullet named, with how it
  was checked. "Looks done" is not a reflection pass.
- Tangents go to the parking lot, not into the current step. The human decides order.
- Write this file at milestones only — a step completing or a real pivot.

## Goal
<what we're learning and why; rough shape of "done" — set at intro, rarely edited>

## Acceptance criteria
- [ ] <observable, concrete outcome>
- [ ] <observable, concrete outcome>

## Current design hypothesis
<current best theory of the approach. Mutable. When this changes, update here and log why in
history.md — do not silently overwrite.>

## Step plan
- [x] Step 1: <one-line summary of a completed step>
- [ ] Step 2: <current step — the active one carries its verification bullets below>
      - verify: <concrete, checkable bullet>
      - verify: <concrete, checkable bullet>
- [ ] Step 3: <planned step>

## Parking lot
- [ ] <side-task / tangent / thing not to forget, captured mid-step without derailing>
```

### The `Rules in force` block

Written once, verbatim from the template above, when the file is created — then never rewritten,
trimmed, or re-derived from the skill. It exists because the skill body is loaded into the
conversation once and then sits in the compressible middle of a long session's context, where it
is diluted by position and lost outright at compaction; the first casualty is usually the
never-write-code rule or the one-line output discipline. This file is on disk, so it survives
compaction, and re-reading it relocates the rules to the end of the context, where attention is
strongest.

Re-read it — as part of re-reading `session.md` — at every step boundary (before the reflection
pass, before the write), on resume, and after any context compaction. Keep it short: it is
re-read repeatedly, and a long block is just more of the noise it exists to counter. If you
resume an effort whose `session.md` predates this block, add it then.

### Keeping `session.md` lean

- **Completed steps compact to one line.** Once a step is done and its reflection passed, reduce
  it to `- [x] Step N: <summary> — done` and move any narrative detail to `history.md`.
- **Only the active step keeps its verification bullets inline.** Add a step's bullets when it
  becomes active, not for every future step up front.
- **Parking lot holds only unresolved items.** When an item is resolved or deferred, remove it
  from here and record the outcome in `history.md`.
- Target well under Claude Code's memory load ceiling (200 lines / 25KB). If it's growing,
  compact — the file does not shrink by itself.

## `history.md` format

Append-only. Newest entries at the bottom. Each entry is dated/ordered and self-contained:

```markdown
# Navigator history: <slug>

## <timestamp or step marker> — hypothesis pivot
Was: <prior hypothesis in a sentence>
Now: <new hypothesis>
Why: <what we learned that drove the change>

## <timestamp or step marker> — step N completed
Reflection: verified <bullet> by <how>; verified <bullet> by <how>.
Flagged: <anything a reflection pass found incomplete, and what was done about it>
Notes: <any narrative detail pruned from session.md>

## <timestamp or step marker> — parking-lot item resolved/deferred
Item: <the item>
Outcome: <resolved how, or deferred to where and why>
```

Never load this whole file into context routinely. Read the relevant section on demand.
