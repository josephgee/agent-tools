# navigator-watch

Infrastructure for the **navigator** learning workflow: you drive (write all the code, in your
editor of choice — e.g. WebStorm), and an agent running in Claude Code acts as a hands-off
navigator that coaches you by voice. This tool moves information between your work and the agent;
the agent's *behavior* is governed by the [`navigator` skill](../../skills/navigator/SKILL.md) —
see its [setup guide](../../skills/navigator/README.md) for starting a session and configuring
how you want to be coached (this doc only covers the file-watch/voice/TTS plumbing).

**Quick setup:** most of the mechanical setup below (gitignore, coaching-file scaffolds, merging
Claude Code hooks, PATH symlink, Hammerspoon config) can be done for you by running
[`setup.sh`](setup.sh) — or just ask your coding agent to run it. It's idempotent (safe to
re-run) and additive (merges into existing Claude Code hooks/settings rather than overwriting
them). A few things it can't do for you are listed at the end of its output (installing brew/npm
dependencies, granting Hammerspoon Accessibility permission, and switching cmux's socket access
mode, since that's only settable from within the cmux app itself). Everything below still applies
as the manual/detailed version, and as the reference for what `setup.sh` is actually doing.

```bash
~/workspace/agent-tools/tools/navigator-watch/setup.sh --project-dir ~/work/thing
```

It's built for **Claude Code running inside the [cmux](https://cmux.com) macOS app** (the
Ghostty-based terminal by manaflow — `cmux --version` ≈ 0.64+, *not* the npm `cmux-tui`). cmux
ships a `cmux` CLI / Unix socket that lets us inject text into the agent's surface without you
touching the terminal; Claude Code hooks let the agent talk back by voice.

> cmux's socket has access modes (Settings UI). Default is **"cmux processes only"** — anything
> launched from inside a cmux terminal (like `watch.sh`) can connect. Processes started *outside*
> cmux (like a Hammerspoon-launched `speak.sh`) need the access mode changed to **allowAll**,
> **persistently, for the cmux app itself**, via its Settings UI — this is not something a client
> can opt into per-invocation (e.g. setting `CMUX_SOCKET_MODE=allowAll` in your own shell/script
> before calling `cmux` has no effect; access mode is the server's decision). allowAll means any
> local process can reach the socket, not just ones cmux spawned — an intentional trade-off for
> this hands-free-from-IDE path.
>
> Also: cmux's "current workspace/pane" resolution is scoped to **whichever pane/window the CLI
> is invoked from** (confirmed: `cmux list-panels --json` run from inside a pane only shows that
> window's panels) — it is not "whichever workspace has UI focus." That means live auto-detection
> of the target surface only works from inside a cmux pane. See "Finding the surface" below for
> how `speak.sh` (launched ancestry-free by Hammerspoon) works around that.

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
- **jq** (`brew install jq`) — used to auto-detect the surface running Claude Code, so you don't
  hand-configure a surface id per pane/session (see below).
- **node** (any Node 18+) — used only by the Path C transcript extractor.
- **git** — Path A computes diffs with it.
- **fswatch** — `brew install fswatch` — Path A file watching.
- **A recorder** — `brew install sox` (gives `rec`) or `ffmpeg` — Path B.
- **A local transcriber** — one of: `whisper-cpp`/`whisper-cli` (with a model file),
  `mlx_whisper` (Apple Silicon), or OpenAI `whisper` — Path B.
- **Hammerspoon** (`brew install --cask hammerspoon`) — Path B global hotkey.
- **macOS `say`** (built in) — Path C TTS. Swappable, see below.

## Where you run this from

The scripts live in this `agent-tools` checkout, but you run them **against whatever project
you're learning in** — a different directory entirely. Two things follow from that:

- **`watch.sh`** defaults `--dir` to your current directory, so the natural pattern is: open a
  cmux pane, `cd` into the project you're working in, then invoke the script *by its path in
  this checkout* (or use the PATH symlink below) with no `--dir` needed:

  ```bash
  cd ~/work/thing                                  # your project, not agent-tools
  ~/workspace/agent-tools/tools/navigator-watch/watch.sh
  ```

  Running it from inside `tools/navigator-watch/` itself, or passing `--dir` pointed at the wrong
  place, would watch this repo instead of your project. (Surface is auto-detected — see "Finding
  the surface" below — so you don't normally need `--surface` either.)
- **`speak.sh`** doesn't care about your working directory at all, so it has no equivalent
  gotcha — run it from anywhere, or trigger it via the Hammerspoon hotkey binding, which already
  invokes it by absolute path.
- **Claude Code hooks** (`hooks/on-stop.sh`, `hooks/on-busy.sh`) are configured with absolute
  paths in your Claude Code settings (see Path C below) and run wherever Claude Code invokes
  them — nothing to think about here.

### Optional: put `watch.sh` on PATH

To avoid typing the full path every time, symlink it once:

```bash
ln -s ~/workspace/agent-tools/tools/navigator-watch/watch.sh /usr/local/bin/navigator-watch
```

Then the pattern above becomes just:

```bash
cd ~/work/thing
navigator-watch
```

## Finding the surface (auto-detect + cache)

`cmux`'s "current workspace/pane" resolution is scoped to whichever pane you invoke the CLI
*from* — confirmed by running `cmux list-panels --json` inside a pane and seeing only that
window's panels. So live auto-detection only works from inside a cmux pane, and `speak.sh`
(launched by Hammerspoon, with no ancestry link to any cmux pane) can't rely on it.

The split:

- **`watch.sh`** runs from inside the target cmux pane (see "Where you run this from"), so its
  auto-detection is legitimate. It resolves the surface running claude — asking `cmux
  current-workspace` for the pane's own window, then matching a surface in it whose
  `resume_binding.kind` is `"claude"` (the primary, reliable signal — confirmed against a real
  session; `title` reflects the live task/status line, not literally "claude", so it's only a
  fallback for surfaces without a `resume_binding`), using its `ref` (e.g. `surface:5`) — and
  **caches** the result to `$NAVIGATOR_STATE_DIR/surface` as a side effect of starting.
- **`speak.sh`** reads that cache instead of trying to live-resolve. If there's no cache yet
  (e.g. you want voice without running the file watcher), run
  [`refresh-surface.sh`](refresh-surface.sh) once from inside the target pane to prime it:

  ```bash
  ~/workspace/agent-tools/tools/navigator-watch/refresh-surface.sh
  ```

Either path also accepts an explicit `--surface <id>` (ids look like `surface:7`, not a bare
number; find one yourself with `cmux list-panels --json`) to skip auto-detection entirely.

The matching logic is verified against a real `cmux list-panels --json` sample but not run
end-to-end against a live cmux socket yet, and it fails loudly with the raw JSON rather than
guessing if it finds zero or multiple candidates.

## Path A — file watcher

Run it from *inside* a cmux pane (so the socket is reachable in the default access mode), with
your project directory as the working directory (see [Where you run this
from](#where-you-run-this-from) above):

```bash
cd ~/work/thing   # the project you're learning in — not this agent-tools checkout
~/workspace/agent-tools/tools/navigator-watch/watch.sh
# or, if symlinked onto PATH: navigator-watch
```

Surface is auto-detected (see above); pass `--surface <id>` to override. `--dir <path>` overrides
the working directory if you'd rather not `cd` first.

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

`speak.sh` records, transcribes, and sends. Surface is auto-detected (see above); pass
`--surface <id>` to override:

```bash
./speak.sh toggle    # tap once to start, again to stop + send
./speak.sh start     # or explicit start / stop for push-to-talk
./speak.sh stop
```

For whisper.cpp you must point at a model file, via `--model` or `$NAVIGATOR_WHISPER_MODEL`:

```bash
export NAVIGATOR_WHISPER_MODEL=~/models/ggml-base.en.bin
```

`mlx_whisper` and OpenAI `whisper` download/manage their own models and need no `--model`.

### Hotkey binding (Hammerspoon)

See [`hammerspoon/init.lua`](hammerspoon/init.lua). Copy the binding into `~/.hammerspoon/init.lua`
(no per-pane editing needed — surface comes from the cache, see above), then reload Hammerspoon.
It offers a toggle style (tap to start/stop) and a push-to-talk style (hold to record). Because
it's a global hotkey, it fires while you're focused in WebStorm.

**One-time setup:** since Hammerspoon launches `speak.sh` outside cmux, you must switch cmux's
socket access mode to **allowAll** yourself, persistently, in cmux's own Settings UI — see the
access-mode note near the top of this README for why a client-side env var doesn't achieve this.

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
