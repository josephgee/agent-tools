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

## Surface auto-detection (removing per-pane hand-tooling)

Originally both `watch.sh` and a hardcoded `SURFACE` in the Hammerspoon config required manually
looking up and entering the cmux surface id per project/pane — flagged as "gross" by the user
since it meant hand-configuring two places (Hammerspoon + the watcher invocation) every session.

Fixed with auto-detection (`lib/resolve-surface.sh`): resolve the currently focused cmux
workspace via `cmux current-workspace`, then find the surface in it whose `initial_command` or
`title` mentions "claude", using its `ref` as `--surface`. `--surface` becomes optional
everywhere; the Hammerspoon config no longer has a per-pane field to edit at all.

Confirmed against a real `cmux list-panels --json` sample (not a live socket call, but real
output the user captured) that:
- The root shape is `{"surfaces": [...], "workspace_ref": ..., "window_ref": ...}`.
- Identifiers are refs like `"surface:7"` / `"workspace:4"` under the key `ref`, not a bare
  numeric `id` (initial design guessed several candidate key names defensively; `ref` wasn't
  among the first guesses and was added once confirmed).
- `title` reflects whatever's currently running in the pane's foreground and drifts (e.g. a
  Claude Code pane's title read `"vim README.md"` after the user ran `vim` in it) — unreliable
  alone. `initial_command` is stable (sourced from the `cmux-agent-resume/claude-<uuid>.zsh`
  resume script cmux launches an agent pane with), so matching prioritizes it, with `title` as a
  secondary signal. Deliberately not a blanket recursive string search across all fields, since
  paths like `requested_working_directory` could contain "claude" as an unrelated path segment
  and false-positive.

Still not run against a live cmux socket end-to-end — the resolver fails loudly with raw JSON on
zero/multiple matches rather than guessing, specifically so a mismatch is diagnosable on first
real use rather than silently wrong.

### Correction: "current workspace" is ancestry-scoped, not UI-focus-scoped

User observation: the `cmux` CLI is available from inside any pane, and running `cmux
list-panels --json` from inside a pane shows only that window's panels, not every open window.
This means "current workspace/pane" resolution is scoped to **whichever pane/window the caller
was invoked from** (ancestry-based) — not "whichever workspace currently has UI focus in the
app," which is what the original design assumed. That assumption was necessary for `speak.sh`
(launched by Hammerspoon, with no ancestry link to any cmux pane) to auto-detect anything, and
it's very likely wrong.

Fix: don't attempt ancestry-free resolution at all. Resolve live only where ancestry genuinely
exists (`watch.sh`, run from inside the target cmux pane) and **cache** the result to
`$NAVIGATOR_STATE_DIR/surface`. `speak.sh` reads that cache instead of re-resolving. A standalone
`refresh-surface.sh` primes the cache for voice-only use when the watcher isn't running. This
keeps the "no per-pane hand-tooling" property for the common case (starting `watch.sh` for a
project also primes voice) while not depending on an unverified (and now doubted) assumption
about cmux's UI-focus semantics.

### Correction: the access-mode env var doesn't do what it looked like

The original Hammerspoon binding set `CMUX_SOCKET_MODE=allowAll` in the small subprocess it
launches `speak.sh` in, on the theory that this would let that ancestry-free process bypass the
default "cmux processes only" access check. Re-reading cmux's access-mode doc more carefully:
allowAll is listed as an *environment override* alongside "Settings UI" as ways to configure the
mode — i.e. a setting of the cmux app (the server) itself, not something a connecting client
opts into per-invocation. A client setting this in its own environment almost certainly has no
effect on the server's access decision. Fixed by removing that from the Hammerspoon script and
documenting the real requirement: switch cmux's access mode to allowAll persistently via its own
Settings UI (or via whatever mechanism sets environment for the cmux app process itself, e.g.
`launchctl setenv`, since GUI apps don't inherit shell exports).

## Usage model clarification

`watch.sh` is invoked from the *project being learned*, not from this `agent-tools` checkout —
it's not obvious from the script alone since `--dir` silently defaults to the caller's cwd. Fixed
by adding an explicit "Where you run this from" section to the README (cd into the project, then
invoke by path or via an optional PATH symlink), rather than relying on the `--dir` flag being
discovered. `speak.sh` has no such gotcha (cwd-independent, only needs `--surface`).

## Setup automation (setup.sh)

User question: could an agent do most of the setup instead of the human hand-typing every step
from the READMEs? Considered a repo-local `CLAUDE.md` for this and rejected it — the setup work
mostly needs to happen in the *target* learning project's directory tree (a different repo),
and CLAUDE.md loading is scoped to the agent's current working directory tree, so a CLAUDE.md
living only in `agent-tools` wouldn't load there.

Instead: `tools/navigator-watch/setup.sh`, an idempotent script any agent can be told to run
(from anywhere — it doesn't depend on being "loaded"). It handles: the global gitignore trick,
scaffolding empty coaching.md templates (global + project-local, never inventing actual coaching
content), merging this tool's Claude Code hooks into a settings.json, a PATH symlink for
`watch.sh`, and Hammerspoon config (symlinked only if none exists; otherwise reports what to add
rather than overwrite). Explicitly does not touch cmux's socket access mode (only settable from
within the cmux app itself) or install brew/npm dependencies.

The hooks merge is the part with real correctness risk (clobbering a user's existing Claude Code
hooks would be bad), so it was tested directly: a fake `settings.json` pre-populated with an
unrelated `PostToolUse` hook and an existing `Stop` hook for a different tool, run through
`setup.sh` twice. Confirmed: unrelated settings/hooks untouched, the pre-existing `Stop` hook
preserved alongside the new one (not replaced), a timestamped backup written before any change,
and the second run made no further changes (no duplicate entries). Tested with a real `jq`
binary against fabricated JSON, not against the actual Claude Code app reading the result.

### Safety review (prompted: "review that work carefully, so we don't hose a local env")

Targeted edge-case testing found and fixed real bugs before this ever touched a real machine:

- **Backup-failure bug (the serious one):** the original code did
  `cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak..." 2>/dev/null || true` followed unconditionally
  by overwriting the original — if the backup write failed (permissions, disk full), the script
  proceeded to overwrite anyway with no safety net. Confirmed with a read-only `.claude/`
  directory: fixed version now checks the `cp` succeeded and the backup file actually exists
  before writing, and refuses (with a clear message) rather than overwriting unprotected.
- **Invalid existing JSON:** confirmed jq fails closed (exit 5, no output, `set -e` aborts before
  any write) if `settings.json` is malformed — already safe, but improved with an explicit
  `jq empty` pre-check so the failure is a friendly warning that lets the rest of setup continue,
  instead of a raw jq parse error aborting the whole script.
- **Merge-output validation:** added a check that the merge result is itself valid, non-empty
  JSON before it's ever written — belt-and-suspenders against a future jq-logic bug silently
  corrupting the file.
- **Hammerspoon broken-symlink edge case:** a dangling symlink at `~/.hammerspoon/init.lua` that
  isn't ours would previously fail `-f` (so it looked like "nothing there") and then hit an
  unguarded `ln -s`, hard-aborting the script via `set -e`. Fixed to detect any existing path
  entry (including broken symlinks) and leave it alone with instructions, matching the pattern
  already used for the PATH symlink step.
- **Missing `git`:** added an explicit early check with a clear message, instead of an
  unguarded `git config` call failing opaquely partway through.

All fixes re-verified against the original happy-path test (still correct, still idempotent)
plus the specific failure scenarios above, using a real `jq` binary against fabricated
environments (fake `$HOME`, read-only directories, truncated JSON).

### Correction: `${BASH_SOURCE[0]}` breaks when invoked through the PATH symlink

User observation: `watch.sh` (and the same pattern in `speak.sh`, `refresh-surface.sh`,
`setup.sh`) computed its own directory as
`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd`, which resolves to wherever the script was
*invoked from* — for a direct call that's the real directory, but invoked through the PATH
symlink `setup.sh` itself creates (`/usr/local/bin/navigator-watch -> watch.sh`),
`${BASH_SOURCE[0]}` is the symlink's own path, so `HERE` resolved to `/usr/local/bin` and
`lib/resolve-surface.sh` couldn't be found. Confirmed with a minimal repro before touching the
real scripts.

Fixed in all four scripts with the standard symlink-chain-resolving loop (follows `readlink`
repeatedly, handling both absolute and relative symlink targets, until it reaches a real file).
Verified against direct invocation, a single symlink, a chained symlink (symlink to a symlink),
and a relative-target symlink — all four resolve to the real directory. Also verified end-to-end
by actually symlinking `watch.sh` the way `setup.sh` does and invoking it through that symlink.

(One earlier attempt to apply this fix via a shell/perl one-liner corrupted all four files by
letting the outer shell expand variables meant for the replacement text — caught immediately via
`git checkout` before it was ever tested or committed, redone properly with direct file edits.)

### Correction: the surface-matching heuristic missed the real Claude Code pane

First real-world run surfaced the predicted risk directly: workspace resolution worked correctly
(found `workspace:3`, queried it), but the surface matcher found zero candidates. Real data
showed why — on an actual session, the Claude Code surface had `initial_command: null` (not
always populated, contrary to the one earlier sample) and `title: "✣ Clarify email list source in
EmailSelectWithContactDetails"` (the live task/status line, not literally "claude"). Both
signals the matcher relied on were absent or misleading.

The real, reliable signal was sitting in the same payload: **`resume_binding.kind: "claude"`** —
a structured, exact field cmux sets on agent-launched surfaces (`null` on the other two surfaces
in the same window: a dev server and the pane running the diagnostic commands themselves).
Switched matching to prioritize `resume_binding.kind`, keeping the `initial_command`/`title`
substring check only as a fallback for surfaces without a `resume_binding` (e.g. a `claude`
process started by hand rather than through cmux's agent-launch mechanism). Verified against the
user's actual captured JSON, through the real `resolve_surface` function (not just the bare jq
filter) with a stubbed `cmux` — correctly resolves and caches `surface:5`, the surface the user
confirmed was actually running Claude Code.

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
