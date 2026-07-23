# Design: Navigator (voice-driven learning pair, reversed roles)

Status: v1 built. Captures the design conversation and the resulting implementation. The skill
lives at `skills/navigator/`; the infrastructure at `tools/navigator-watch/`. Update this doc if
reality diverges further.

## Problem / intent

When learning an unfamiliar tech stack at work, the usual `tdd` skill pairing model (agent
drives, human navigates) is inverted: the human wants to drive — write all the code themselves,
hands-on — while an agent acts as **navigator**: coaching, questioning direction, catching
missed steps, and keeping a running plan, without ever writing code itself.

The interaction is voice-first and asynchronous from typing: the human works in **WebStorm**
(a JetBrains IDE — not the terminal), occasionally speaks to the agent via a global hotkey, and
the agent occasionally speaks up on its own when it notices relevant file changes. Because the
human is heads-down in the IDE and not watching the terminal, the agent's replies must come back
as **audio**, not on-screen text. Target environment: cmux + Claude Code, on macOS, at work.
Generalizing beyond that is a nice-to-have, not a requirement — don't compromise the primary
experience for portability.

## Scope note: this expands what `agent-tools` covers

This repo was previously "Agent Skills only" (per `AGENTS.md`/`README.md`): plain markdown,
no application code, no build step. Navigator requires real running infrastructure (file
watcher, hotkey listener, voice transcription, IPC into a terminal session), which can't live
in a `SKILL.md`. Repo scope is expanding to cover this:

- `skills/` — Agent Skills, spec-conformant, markdown only, as before.
- `tools/` — actual scripts/code for reusable agent-adjacent tooling. Own README per tool, not
  required to be harness-agnostic or dependency-free the way skills are.

**TODO before/alongside v1 build:** update `README.md` and `AGENTS.md` to describe both
categories and the different rules each follows.

## Architecture overview

Two independent halves:

1. **`tools/navigator-watch`** — infrastructure. Watches files, decides when to interrupt,
   captures voice input on a hotkey, and injects text into the running Claude Code session.
   Never talks to a model itself; it only moves bytes into/observes the terminal.
2. **`skills/navigator`** — an Agent Skill. Instructions for how the agent behaves once it's
   receiving that input: the intro conversation, artifact discipline, coaching restraint,
   the never-edit-code rule. This is where "how much the agent talks," "how it verifies a step
   is really done," etc. get governed.

### Why this split

Claude Code (and cmux) don't give an agent a native background-loop primitive — the agent only
responds turn-by-turn to input arriving in its session. So anything resembling "watch files
in the background and decide when to speak" has to be an external process that turns raw events
into a turn-worthy chat message, with the skill governing judgment about *what to do with it*.

## Correction: which "cmux"

This was initially designed against the npm `cmux-tui` package (JSON-lines control socket,
protocol v9). The user's actual tool is the **cmux macOS app** (cmux.com, `cmux --version` ~0.64),
a Ghostty-based terminal by the same authors but a different program. It exposes a `cmux` CLI and
a Unix socket (`/tmp/cmux.sock`, JSON-RPC `{method,params}`), with access modes (default "cmux
processes only"). The implementation was switched to drive the **`cmux` CLI directly** (`cmux
send` / `cmux send-key` / `cmux list-panels`), and the custom socket client (`cmux.js`) was
deleted. The sections below describing the cmux-tui JSON socket are retained only as historical
context; the CLI is the real transport.

## The delivery mechanism (historical: cmux-tui control socket)

cmux (`npx cmux`, a tmux-like multiplexer backed by libghostty-vt) exposes a JSON-lines control
socket per session at `$TMPDIR/cmux-tui-<uid>/<session>.sock` (protocol v9). Relevant commands,
confirmed from `cmux-tui/docs/protocol.md` and `cmux-tui/spec/commands.md`:

- `send {surface, text, bytes?, paste?}` — writes bytes to a PTY surface, same as typing.
- `send-key {surface, keys:[...]}` — named key chords (`enter`, `ctrl+c`, etc.) without hand
  -encoding escape sequences.
- `read-screen {surface}` — plain-text snapshot of the current viewport (VT state), for
  detecting idle vs. busy.
- `subscribe` / `attach-surface` — event stream (`surface-output`, `title-changed`, etc.) for
  detecting activity without polling.
- `list-workspaces`, `identify` — enumerate surfaces / confirm protocol version at startup.

This gives us everything needed: inject text (agent-initiated batched updates, user voice
input), and observe state (idle detection for batching).

`cmux-tui <verb>` on the CLI wraps the same socket commands with `--json` output, so shelling
out to `cmux-tui send --session ... --surface ... --text "..."` is a viable v1 implementation
without hand-rolling the JSON-lines client, if the CLI verb coverage is sufficient. Otherwise a
small Node script speaks the socket protocol directly (Node, since `cmux` itself ships as a
Node-wrapped native binary — keeps the dependency footprint aligned).

## Three delivery paths

The human edits in WebStorm and listens for the agent by voice, so there are three flows: file
changes in (A), the human's voice in (B), and the agent's voice out (C). cmux is the transport
for getting text *into* the running session (A and B); Claude Code hooks drive audio *out* (C).

### Path A — agent-initiated (file-change driven)

- An external watcher (`fswatch` or similar) observes the project's files, debounced.
- Changes accumulate in a **pending buffer**, mechanically filtered only (`.gitignore`-aware,
  ignore lockfiles/build dirs/no-diff no-ops) — no semantic filtering. Semantic judgment about
  whether a change is worth commenting on belongs to the agent/skill, not the watcher.
- The watcher only **flushes** (delivers the buffered diff as a chat message via `send`) when the
  agent is idle. Idle is detected primarily via Claude Code hook flag files (see Path C): the
  agent is idle when a `Stop` fired more recently than the last busy signal. When hooks aren't
  installed, it falls back to diffing `read-screen` snapshots of the pane. Never interrupts an
  in-progress agent turn.
- Large diffs are capped: above a size threshold (~50 lines), send a summary ("N lines changed
  across file X, Y — read on demand") instead of the raw diff, to protect context budget.

### Path B — user-initiated (voice/hotkey)

- Hotkey (Hammerspoon/Karabiner) triggers press-and-hold (or toggle) audio capture.
- On release, local transcription (whisper.cpp / mlx-whisper — local for latency and to avoid
  sending work audio to a cloud API).
- Transcribed text is sent **immediately** via `send`, regardless of whether the agent is
  mid-turn. Rationale: since `send` writes raw bytes indistinguishable from typing, Claude
  Code's own native input-queueing/interrupt handling (type-ahead queues until the current turn
  finishes; Escape hard-interrupts) covers this for free — no busy-detection logic needed on
  this path. If the human wants a hard interrupt, that's a manual Escape press, not something the
  tool decides.
- The global hotkey (Hammerspoon) fires while focused in WebStorm, so no terminal focus needed —
  this is the entire reason this path exists.
- **On Claude Code's built-in `/voice`:** considered as a possible replacement, but rejected —
  `/voice` requires focusing the Claude Code pane, which defeats the actual requirement (talk to
  the navigator without changing contexts away from the IDE). `/voice` remains a simpler fallback
  for moments the human doesn't mind switching focus, but `speak.sh`/Hammerspoon stays the primary
  mechanism. Because Hammerspoon launches outside cmux, `speak.sh` needs
  `CMUX_SOCKET_MODE=allowAll` to reach the socket.
- **Multi-line/paste caveat:** the cmux app CLI has no documented bracketed-paste flag, so Path A
  no longer injects multi-line diffs. It writes the full diff to a file
  (`$NAVIGATOR_STATE_DIR/last-diff.patch`) and sends a single-line message naming the files and
  that path; the agent reads the file on demand. This dodges premature-submit issues and also
  keeps context small. Path B sends single-line transcripts only.

### Path C — agent-initiated output (agent → voice)

Since the human isn't watching the terminal, the agent's replies are spoken aloud via a Claude
Code **`Stop` hook** (fires when the agent finishes a turn). The hook reads the last assistant
message from the session transcript (`transcript_path` in the hook payload) and pipes its text to
a TTS engine — macOS `say` for v1, swappable via a `$NAVIGATOR_TTS` env var (chosen because
re-recording the voice is a cheap later iteration if `say` grates). Reading the transcript, not
scraping the pane, gives clean prose free of terminal UI chrome.

The same hooks double as the **idle signal** for Path A: `Stop` stamps a `last-idle` flag;
`UserPromptSubmit`/`PreToolUse` hooks stamp `last-busy`. The watcher compares the two. This is
more reliable than `read-screen` diffing and is the primary idle mechanism when hooks are
installed.

No length cap on the spoken message in v1 — a mid-sentence cutoff is worse than a slightly long
readout; the skill's "keep turns short" instruction is what actually keeps it bearable.

## Guardrail: the agent never writes code

v1 mechanism: **explicit, strong instruction in the skill** — "you are an observer/coach only,
the human drives, never edit files even if it would be faster or if asked to fix something
small; coach the human to make the change." Tool-level hardening (e.g., Claude Code permission
config denying `Edit`/`Write` for this session) is a deferred hardening step, added only if the
soft instruction proves to leak in practice.

## The working artifact

### Location

`~/.claude/projects/<project>/memory/navigator/<slug>/` — riding on Claude Code's existing
per-project auto-memory directory (keyed off the git repo, shared across worktrees, already
outside version control). Rejected alternative: storing in-repo, which raises gitignore
friction in public/shared repos for no benefit, since Claude Code already provides a
machine-local, non-tracked, project-scoped location for exactly this purpose.

`<slug>` is a **per-effort identifier** chosen during the intro conversation (e.g.
`learning-graphql`), not one fixed file per project — so multiple learning efforts in the same
repo over time don't overwrite each other, and old efforts stay resumable by name.

### Concurrency / confusion safeguards

- **Two-process collision** (e.g., accidentally starting two watchers against the same slug):
  watcher takes a PID lock file, `navigator/<slug>/.watcher.lock`, refuses to start a second
  instance against a live lock.
- **Cross-worktree / cross-session confusion**: since worktrees of the same repo already share
  one `memory/` directory (Claude Code's own design), the risk isn't data loss, it's the intro
  flow silently picking the wrong effort or creating an unwanted duplicate. Mitigation: the
  intro flow **always enumerates existing `navigator/<slug>/` folders first** and explicitly
  asks "resume one of these, or start new?" — never assumes.

### Structure (`session.md`, kept lean)

- **Goal & acceptance criteria** — set at intro, rarely edited after.
- **Current design hypothesis** — mutable; expected to change step by step. Pivots get logged,
  not silently overwritten.
- **Step plan** — sequential checklist. Each step carries a few concrete, verifiable bullets
  (defined when the step starts). A step only flips to done after an explicit **reflection
  pass** against those bullets — the agent states which it verified and how — not a bare
  self-declaration of completion. (Motivated by an observed failure mode: agents skipping a
  subtask and declaring the parent task done anyway.) Completed steps compact to one line each
  in `session.md` (e.g., "Step 2: wired up X — done") — full detail moves to `history.md`.
- **Parking lot** — side-notes/tangents jotted down mid-step without derailing current work.
  The navigator (agent) may propose when/how to fold them back in or resolve them; the human
  (driver) decides order and priority. Unresolved parking-lot items gate the *overall effort's*
  completion, not each individual step.

### `history.md` (append-only, read on demand)

Full change log: hypothesis pivots (with why), reflection results, anything pruned from
`session.md` when compacted. Not re-read into context every turn — the agent reads it only when
asked to reconstruct past reasoning ("what did we decide about X"). Mirrors the lean-index +
on-demand-topic-file pattern Claude Code's own auto memory (`MEMORY.md` + topic files) already
uses, for the same reason: keep the always-loaded context small.

### Context management, generally

- `session.md` must stay lean (rough budget similar to Claude's own `MEMORY.md` guidance:
  target well under its 200-line/25KB load ceiling, even though that ceiling technically only
  applies to `MEMORY.md` itself).
  - Doesn't automatically shrink; the skill must actively compact completed steps down to one
    line and move detail to `history.md` as part of normal step-completion handling.
- Watcher diffs are size-capped (see Path A above) so one large hand-made edit doesn't blow a
  turn's context budget.
- Out of scope for v1: the agent's own Claude Code context window filling up over a long
  session from conversational back-and-forth (independent of the artifact). If that becomes a
  problem in practice, likely mitigations are periodic `/compact` or starting a fresh session
  per step/phase — not something to design preemptively.

## Intro conversation (new effort)

Modeled on XP's "five-minute-sign" planning conversation. Minimum content:

1. What you're learning and why; rough shape of "done."
2. Success/acceptance criteria.
3. Initial design hypothesis.
4. Break the hypothesis into sequential steps — explicit shared understanding that the
   hypothesis *and* the plan may change at any step, and that's expected, not a failure.

Detailed coaching style/guidelines (how much to explain, when to interject, what kind of
questions to ask) are deliberately left to the skill file itself, tunable per the user's
preference at the time — not fully specified in this design doc.

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
`core.excludesFile` (`~/.config/git/ignore`), so it applies to every repo on the machine and
never requires a per-project `.gitignore` edit or risks being committed — which resolves the
public-repo friction that drove the artifact out of the repo in the first place. The agent only
*reads* these files (and may scaffold an empty template on request); it never writes coaching
content into them. Details/templates: `skills/navigator/references/coaching-directives.md`.

## Coaching restraint (deferred to skill prompt, not architecture)

Explicitly flagged during design: agent "soliloquies" need limiting so the human can interject.
This is a prompt-engineering concern for `skills/navigator/SKILL.md`, not an architectural one —
noted here so it isn't lost, but the mechanism is just careful instruction-writing (e.g., short
turns, checking in before elaborating, explicit stop points), not a technical control.

## Repo layout

```
skills/
  navigator/
    SKILL.md                       # agent-behavior half
    references/artifact-format.md  # session.md + history.md structure, on-demand
tools/
  navigator-watch/
    README.md                      # setup for all three paths
    cmux.js                        # minimal cmux control-socket client (send/read-screen/list)
    watch.sh                       # fswatch + debounce + hook-driven idle + cmux send (Path A)
    speak.sh                       # hotkey record + local whisper + cmux send (Path B)
    hammerspoon/init.lua           # example global hotkey binding (Path B)
    hooks/
      on-stop.sh                   # Claude Code Stop hook: TTS the reply + mark idle (Path C)
      on-busy.sh                   # UserPromptSubmit/PreToolUse hook: mark busy
      extract-last-assistant.js    # pull last assistant text from the transcript
    claude-settings.example.json   # hooks block to merge into Claude Code settings
```

Stack: shell for orchestration; a small Node helper for the cmux JSON-lines socket (aligns with
cmux's own Node-wrapped distribution) if `cmux-tui <verb>` CLI coverage proves insufficient;
`fswatch` for file events; local Whisper (whisper.cpp or mlx-whisper) for STT; Hammerspoon for
the global hotkey. No new build system — installed via existing brew/npm.

## Open items / deferred decisions

- Tool-level hardening of the never-edit-code rule (permission config), deferred until/unless
  the soft instruction leaks in practice.
- Exact debounce/idle thresholds and the diff-size cap (~50 lines) are flag-configurable
  defaults — tune from real use.
- Chose a **direct Node socket client** (`cmux.js`) over shelling out to `cmux-tui <verb>`, to
  avoid depending on CLI verb coverage and to control response parsing. Revisit only if it
  proves fragile.
- Detailed coaching-style content in `SKILL.md` (verbosity limits, question style, when to
  interject) is intentionally light and the user's to tune from experience.
- **Not yet validated against a live cmux + Claude Code session on macOS.** All scripts pass
  syntax checks and the hook/extractor/idle logic is unit-tested on Linux with stubs, but the
  real `send`/`read-screen`/hook round-trip, the whisper path, `say`, and the Hammerspoon
  binding need a first run on the target machine. Surface ids, the exact transcript JSONL shape,
  and default thresholds are the most likely things to need adjustment.

## Build order (as built)

1. `skills/navigator/` — SKILL.md + references/artifact-format.md. Reviewed with `skill-review`;
   fixed the memory-path resolution gap it surfaced.
2. `tools/navigator-watch` — `cmux.js` client, Path A (`watch.sh`), Path B (`speak.sh` +
   Hammerspoon), Path C (`hooks/` + settings example), README.
3. `README.md` / `AGENTS.md` updates for the `skills/` + `tools/` repo-scope expansion.
