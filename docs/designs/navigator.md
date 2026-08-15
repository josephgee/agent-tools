# Design: Navigator (reversed-role learning pair)

Design rationale for the `navigator` skill. `skills/navigator/SKILL.md` and its `README.md` are
the source of truth for current behaviour; this doc records *why* the design is shaped the way
it is. Update it if reality diverges.

## Problem / intent

When learning an unfamiliar tech stack, the usual `tdd` skill pairing model (agent drives, human
navigates) is inverted: the human wants to drive — write all the code themselves, hands-on —
while an agent acts as **navigator**: coaching, questioning direction, catching missed steps, and
keeping a running plan, without ever writing code itself.

The human is heads-down in an editor, not watching the terminal, so the agent can't rely on being
asked. It watches the working tree and speaks up on its own; the human glances at the terminal
pane when they feel like it.

## Guardrail: the agent never writes code

Mechanism: **explicit, strong instruction in the skill** — "you are an observer/coach only, the
human drives, never edit files even if it would be faster or if asked to fix something small;
coach the human to make the change." Tool-level hardening (e.g. permission config denying
`Edit`/`Write` for the session) is a deferred step, added only if the soft instruction proves to
leak in practice.

## The working artifact

### Location

`~/.claude/projects/<project>/memory/navigator/<slug>/` — riding on Claude Code's existing
per-project auto-memory directory (keyed off the git repo, shared across worktrees, already
outside version control). Rejected alternative: storing in-repo, which raises gitignore friction
in public/shared repos for no benefit, since Claude Code already provides a machine-local,
non-tracked, project-scoped location for exactly this purpose.

`<slug>` is a **per-effort identifier** chosen during the intro conversation (e.g.
`learning-graphql`), not one fixed file per project — so multiple learning efforts in the same
repo over time don't overwrite each other, and old efforts stay resumable by name.

### Concurrency / confusion safeguards

- **Two-process collision** (e.g. accidentally starting two watchers against the same slug): the
  watcher takes a PID lock file and refuses to start a second instance against a live lock.
- **Cross-worktree / cross-session confusion**: since worktrees of the same repo already share
  one `memory/` directory (Claude Code's own design), the risk isn't data loss, it's the intro
  flow silently picking the wrong effort or creating an unwanted duplicate. Mitigation: the intro
  flow **always enumerates existing `navigator/<slug>/` folders first** and explicitly asks
  "resume one of these, or start new?" — never assumes.

### Structure (`session.md`, kept lean)

- **Goal & acceptance criteria** — set at intro, rarely edited after.
- **Current design hypothesis** — mutable; expected to change step by step. Pivots get logged,
  not silently overwritten.
- **Step plan** — sequential checklist. Each step carries a few concrete, verifiable bullets
  (defined when the step starts). A step only flips to done after an explicit **reflection pass**
  against those bullets — the agent states which it verified and how — not a bare self-declaration
  of completion. (Motivated by an observed failure mode: agents skipping a subtask and declaring
  the parent task done anyway.) Completed steps compact to one line each in `session.md` (e.g.
  "Step 2: wired up X — done") — full detail moves to `history.md`.
- **Parking lot** — side-notes/tangents jotted down mid-step without derailing current work. The
  navigator (agent) may propose when/how to fold them back in or resolve them; the human (driver)
  decides order and priority. Unresolved parking-lot items gate the *overall effort's* completion,
  not each individual step.

### `history.md` (append-only, read on demand)

Full change log: hypothesis pivots (with why), reflection results, anything pruned from
`session.md` when compacted. Not re-read into context every turn — the agent reads it only when
asked to reconstruct past reasoning ("what did we decide about X"). Mirrors the lean-index +
on-demand-topic-file pattern Claude Code's own auto memory (`MEMORY.md` + topic files) already
uses, for the same reason: keep the always-loaded context small.

### Context management, generally

- `session.md` must stay lean (rough budget similar to Claude's own `MEMORY.md` guidance: target
  well under its 200-line/25KB load ceiling, even though that ceiling technically only applies to
  `MEMORY.md` itself).
  - Doesn't automatically shrink; the skill must actively compact completed steps down to one
    line and move detail to `history.md` as part of normal step-completion handling.
- Large edits don't blow a turn's context budget because the watcher writes the full patch to
  disk and queues only a one-line summary (files, shortstat, patch path); the agent opens the
  patch only when the summary warrants it. (An earlier plan to size-cap diffs became unnecessary
  under this scheme.)
- Out of scope: the agent's own context window filling up over a long session from conversational
  back-and-forth (independent of the artifact). If that becomes a problem in practice, likely
  mitigations are periodic `/compact` or starting a fresh session per step/phase — not something
  to design preemptively.

## Intro conversation (new effort)

Modeled on XP's "five-minute-sign" planning conversation. Minimum content:

1. What you're learning and why; rough shape of "done."
2. Success/acceptance criteria.
3. Initial design hypothesis.
4. Break the hypothesis into sequential steps — explicit shared understanding that the hypothesis
   *and* the plan may change at any step, and that's expected, not a failure.

Detailed coaching style/guidelines (how much to explain, when to interject, what kind of questions
to ask) are deliberately left to the skill file itself, tunable per the user's preference at the
time — not fully specified in this design doc.

## Coaching directives (human-authored input)

Separate from the session artifact (agent-maintained *state*), the human can author standing
*directives* for how they want to be coached ("push me on async," "don't re-explain basics,"
"make me write the types by hand"). Two optional scopes, read at startup and treated as always-on
constraints second only to the never-write-code rule:

- **Global**: `~/.claude/navigator/coaching.md` — machine-wide, outside any repo (no gitignore
  needed).
- **Project-local**: `<repo-root>/.navigator/coaching.md` — per-repo; project-local
  augments/overrides global on conflict.

Project-local directives live *in* the repo (so they're editable right in the IDE) but are kept
out of git via the **global gitignore trick**: ignore `.navigator/` once in git's
`core.excludesFile` (`~/.config/git/ignore`), so it applies to every repo on the machine and never
requires a per-project `.gitignore` edit or risks being committed — which resolves the public-repo
friction that drove the artifact out of the repo in the first place. The agent only *reads* these
files (and may scaffold an empty template on request); it never writes coaching content into them.
Details/templates: `skills/navigator/references/coaching-directives.md`.

## Watch loop mechanics: background collect, never foreground polling

The watcher is a daemon that queues detections; the agent picks them up with `--collect`. The
collect must be launched as a **backgrounded** shell command with `--timeout 0` at the end of
each agent turn — the harness re-invokes the agent when it exits (i.e. when a change lands).

Rejected alternative (and the original design, corrected after real use): a *foreground*
`--collect --timeout 30` at end of turn, silently re-run when empty. In Claude Code a foreground
tool call holds the agent's turn open, so the human's prompt stays blocked while the agent loops
on empty collects, and every re-poll renders "Running shell command"/"thinking" chrome that no
amount of "emit no text" instruction can suppress — defeating both goals (interjectable human,
quiet screen) the loop was built around. The background collect yields the turn immediately and
produces zero output during quiet stretches. Consequence handled in the script: `--collect`
exits early if the watcher dies, so a forever-collect left pending at `--stop` doesn't hang.

Two rules in the skill fall out of this mechanism: the agent keeps exactly one collect
outstanding (a second concurrent collect would just race the first for the queue drain and
produce confusing extra wakeups), and a "watcher gone" return triggers a re-arm plus a one-line
notice to the human — relaunching collects against a dead watcher would leave the session
silently deaf, the exact failure the watching loop exists to prevent.

### Debounce (`--idle`)

A collect returns on the *first* queued detection — that was true of the foreground version too,
so the background switch changed nothing about coalescing. What it did change is the cost of a
detection: each one is now a full agent wakeup. Undebounced, an editor autosaving mid-sentence
produces a detection per poll, and each is a wakeup, a coaching opportunity spent on half-written
code, and a line of chrome — the screen-noise failure the loop exists to prevent, arriving by a
different route. So the daemon requires the state hash to hold steady for `--idle` seconds before
queueing: a typing burst becomes one detection when the human pauses. The cost is a few seconds
of reporting lag, which is the right trade for a coach that reacts to finished thoughts.

## Coaching restraint (deferred to skill prompt, not architecture)

Explicitly flagged during design: agent "soliloquies" need limiting so the human can interject.
This is a prompt-engineering concern for `skills/navigator/SKILL.md`, not an architectural one —
noted here so it isn't lost, but the mechanism is just careful instruction-writing (e.g. short
turns, checking in before elaborating, explicit stop points), not a technical control.

## Deferred decisions

- Tool-level hardening of the never-edit-code rule (permission config), deferred until/unless the
  soft instruction leaks in practice.
- Tuning knobs are the poll interval (`--interval`, default 3s) and the settle threshold
  (`--idle`, default 5s). A diff-size cap was considered and dropped — patch-on-disk (see Context
  management) removed the need for one.
- Detailed coaching-style content in `SKILL.md` (verbosity limits, question style, when to
  interject) is intentionally light and the user's to tune from experience.
