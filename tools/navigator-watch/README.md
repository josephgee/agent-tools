# navigator-watch

Infrastructure for the **navigator** learning workflow: you drive (write all the code, in your
editor of choice — e.g. WebStorm), and an agent running in Claude Code acts as a hands-off
navigator that coaches you by voice. This tool moves information between your work and the agent;
the agent's *behavior* is governed by the [`navigator` skill](../../skills/navigator/SKILL.md).

It's built for **Claude Code running inside [cmux](https://github.com/manaflow-ai/cmux)** on
macOS. cmux exposes a JSON-lines control socket that lets us inject text into the agent's pane
without you touching the terminal; Claude Code hooks let the agent talk back by voice.

## The three paths

```
                 ┌─────────────────────────────────────────────┐
   you edit  ──▶ │ watch.sh   file changes → debounce → (idle?) │ ─▶ cmux `send` ─▶ agent pane
   in WebStorm   └─────────────────────────────────────────────┘        (Path A)

   you speak  ──▶ hotkey (Hammerspoon) ─▶ speak.sh: record → whisper → cmux `send` ─▶ agent pane
                                                                                       (Path B)

   agent replies ─▶ Claude Code `Stop` hook ─▶ on-stop.sh: extract last message → TTS (`say`)
                                                                                       (Path C)
```

- **Path A — file changes → agent.** `watch.sh` watches your git project, debounces bursts of
  saves, waits until the agent is idle, then injects a single size-capped `git diff` so the
  navigator can react. Never interrupts the agent mid-turn.
- **Path B — your voice → agent.** A global hotkey triggers `speak.sh`, which records a clip,
  transcribes it locally with Whisper, and sends the text straight into the agent's pane. Sent
  immediately (Claude Code queues it if the agent is mid-turn; hit Escape yourself to hard
  -interrupt).
- **Path C — agent → your ears.** A Claude Code `Stop` hook (`on-stop.sh`) reads the agent's last
  message and speaks it via TTS, so you never have to look at the terminal.

## Prerequisites

- **cmux** (`npm i -g cmux` or `npx cmux`), running your Claude Code session in a pane.
- **node** (ships with cmux's toolchain; any Node 18+ works) — used by `cmux.js` and the
  transcript extractor.
- **git** — Path A computes diffs with it.
- **fswatch** — `brew install fswatch` — Path A file watching.
- **A recorder** — `brew install sox` (gives `rec`) or `ffmpeg` — Path B.
- **A local transcriber** — one of: `whisper-cpp`/`whisper-cli` (with a model file),
  `mlx_whisper` (Apple Silicon), or OpenAI `whisper` — Path B.
- **Hammerspoon** (`brew install --cask hammerspoon`) — Path B global hotkey.
- **macOS `say`** (built in) — Path C TTS. Swappable, see below.

## Finding the surface (pane) id

Every command needs the cmux surface id of the pane running Claude Code:

```bash
node cmux.js --session main list
```

Look for the PTY surface running `claude` and note its numeric id. `identify` confirms the socket
and protocol version:

```bash
node cmux.js --session main identify
```

If your session isn't `main`, pass `--session <name>` (or `--socket <path>` for a non-default
socket location).

## Path A — file watcher

```bash
./watch.sh --surface 4 --dir ~/work/thing
```

Options: `--session`, `--socket`, `--debounce <secs>` (quiet period after last save, default 3),
`--idle <secs>` (idle poll interval, default 2), `--max-lines <n>` (diffs bigger than this are
summarized instead of sent in full, default 50). Only one watcher runs per project at a time
(enforced with a PID lock in `$TMPDIR/navigator-watch`).

Idle detection prefers the hook flag files (see Path C); if the hooks aren't installed it falls
back to diffing `read-screen` snapshots of the pane.

## Path B — voice hotkey

`speak.sh` records, transcribes, and sends:

```bash
./speak.sh --surface 4 toggle    # tap once to start, again to stop + send
./speak.sh --surface 4 start     # or explicit start / stop for push-to-talk
./speak.sh --surface 4 stop
```

For whisper.cpp you must point at a model file, via `--model` or `$NAVIGATOR_WHISPER_MODEL`:

```bash
export NAVIGATOR_WHISPER_MODEL=~/models/ggml-base.en.bin
```

`mlx_whisper` and OpenAI `whisper` download/manage their own models and need no `--model`.

### Hotkey binding (Hammerspoon)

See [`hammerspoon/init.lua`](hammerspoon/init.lua). Copy the binding into `~/.hammerspoon/init.lua`
(edit `SURFACE`/`SESSION`), then reload Hammerspoon. It offers a toggle style (tap to start/stop)
and a push-to-talk style (hold to record). Because it's a global hotkey, it fires while you're
focused in WebStorm.

## Path C — agent speaks back (Claude Code hooks)

Install the hooks so the agent's replies are spoken and idle state is tracked. Copy the `hooks`
block from [`claude-settings.example.json`](claude-settings.example.json) into your Claude Code
settings (`~/.claude/settings.json` for all projects, or `.claude/settings.json` in the learning
project), replacing `ABSOLUTE_PATH` with the absolute path to this directory. Hook commands must
be absolute paths.

- `Stop` → `on-stop.sh`: speaks the agent's last message and marks it idle.
- `UserPromptSubmit` + `PreToolUse` → `on-busy.sh`: marks the agent busy so Path A won't inject
  mid-turn.

Verify with `/hooks` inside a Claude Code session.

### Swapping the TTS engine

`on-stop.sh` uses macOS `say` by default. To use something else, set `$NAVIGATOR_TTS` to a command
that reads text on stdin, e.g.:

```bash
export NAVIGATOR_TTS='my-tts --voice nova'
```

## Shared state directory

The hooks and the watcher coordinate idle/busy state through flag files in
`$NAVIGATOR_STATE_DIR` (default `~/.cache/navigator-watch`). If you override it, set the same
value in the environment for both the watcher and Claude Code's hooks.

## Scope / limitations (v1)

- One active effort/watcher per project at a time.
- The agent never edits code — that's enforced softly by the `navigator` skill's instructions,
  not by this tool. Tool-level hardening (permission config) is a possible later step.
- Idle detection and diff caps use simple heuristics; tune the flags from real use.
- Tested against cmux control-socket protocol v9.
