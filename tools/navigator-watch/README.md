# navigator-watch

Infrastructure for the **navigator** learning workflow: you drive (write all the code, in your
editor of choice — e.g. WebStorm), and an agent running in Claude Code acts as a hands-off
navigator that coaches you by voice. This tool moves information between your work and the agent;
the agent's *behavior* is governed by the [`navigator` skill](../../skills/navigator/SKILL.md).

It's built for **Claude Code running inside the [cmux](https://cmux.com) macOS app** (the
Ghostty-based terminal by manaflow — `cmux --version` ≈ 0.64+, *not* the npm `cmux-tui`). cmux
ships a `cmux` CLI / Unix socket that lets us inject text into the agent's surface without you
touching the terminal; Claude Code hooks let the agent talk back by voice.

> cmux's socket has access modes (Settings UI). Default is **"cmux processes only"** — anything
> launched from inside a cmux terminal (like `watch.sh`) can connect. Processes started *outside*
> cmux (like a Hammerspoon-launched `speak.sh`) need `CMUX_SOCKET_MODE=allowAll`.

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
- **Path B — your voice → agent, without leaving your IDE.** This is the core reason this path
  exists: Claude Code's built-in `/voice` needs its pane focused, which defeats the point. A
  global hotkey (works while focused in WebStorm) triggers `speak.sh`, which records a clip,
  transcribes locally with Whisper, and sends the text into the agent's surface immediately
  (Claude Code queues it if mid-turn; hit Escape to hard-interrupt).
- **Path C — agent → your ears.** A Claude Code `Stop` hook (`on-stop.sh`) reads the agent's last
  message and speaks it via TTS, so you never have to look at the terminal.

## Prerequisites

- **cmux** macOS app (`brew install --cask cmux`), running your Claude Code session in a surface,
  with its `cmux` CLI on PATH (automatic inside cmux terminals; otherwise symlink per cmux docs).
- **node** (any Node 18+) — used only by the Path C transcript extractor.
- **git** — Path A computes diffs with it.
- **fswatch** — `brew install fswatch` — Path A file watching.
- **A recorder** — `brew install sox` (gives `rec`) or `ffmpeg` — Path B.
- **A local transcriber** — one of: `whisper-cpp`/`whisper-cli` (with a model file),
  `mlx_whisper` (Apple Silicon), or OpenAI `whisper` — Path B.
- **Hammerspoon** (`brew install --cask hammerspoon`) — Path B global hotkey.
- **macOS `say`** (built in) — Path C TTS. Swappable, see below.

## Finding the surface id

Every command needs the cmux surface id of the pane running Claude Code:

```bash
cmux list-panels --json
```

Note the id of the surface running `claude`. (`cmux current-workspace` and `cmux list-panels`
help orient you.)

## Path A — file watcher

Run it from *inside* a cmux pane (so the socket is reachable in the default access mode):

```bash
./watch.sh --surface 3 --dir ~/work/thing
```

Options: `--debounce <secs>` (quiet period after last save, default 3), `--idle <secs>` (idle
poll interval, default 2), `--max-lines <n>` (threshold for calling a diff "large" in the
message, default 50). Only one watcher runs per project at a time (PID lock in
`$TMPDIR/navigator-watch`).

Instead of pasting a multi-line diff into the prompt, the watcher writes the full diff to
`$NAVIGATOR_STATE_DIR/last-diff.patch` and sends a **one-line** message naming the changed files
and that path — the agent reads the file on demand. This avoids multi-line submit issues and
keeps the prompt/context small.

Idle detection uses the Claude Code hook flag files (see Path C). Without the hooks installed the
watcher can't detect idle and flushes after the debounce (with a warning) — installing the hooks
is recommended.

## Path B — voice hotkey

The point of this path is talking to the navigator **without switching focus away from your
IDE** — Claude Code's built-in `/voice` needs its pane focused, so it doesn't cover this case.
(If you're ever fine focusing the Claude Code pane, `/voice` is simpler and needs none of this.)

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
(edit `SURFACE`), then reload Hammerspoon. It offers a toggle style (tap to start/stop) and a
push-to-talk style (hold to record). Because it's a global hotkey, it fires while you're focused
in WebStorm. Since Hammerspoon runs outside cmux, the binding sets `CMUX_SOCKET_MODE=allowAll` so
`speak.sh` can reach the socket.

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
- Idle detection relies on the Path C hooks; heuristics/thresholds want tuning from real use.
- Built for the cmux macOS app's `cmux` CLI (`cmux send` / `send-key` / `list-panels`). Not the
  npm `cmux-tui`. Not yet run end-to-end on the target Mac.
