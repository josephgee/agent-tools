# Navigator artifact format

Two files per effort, in `~/.claude/projects/<project>/memory/navigator/<slug>/`:

- `session.md` — lean, always-current live state. Read at startup and whenever unsure. Re-read,
  don't rely on memory.
- `history.md` — append-only detail log. Written at completion/pivot points, read only on demand
  (e.g. when asked "why did we decide X").

The split exists for context management: `session.md` is what gets loaded and re-read
constantly, so it must stay small. `history.md` can grow without bound because it's only read
when explicitly needed. This mirrors Claude Code's own `MEMORY.md` + topic-file pattern.

## `session.md` template

```markdown
# Navigator session: <slug>

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
