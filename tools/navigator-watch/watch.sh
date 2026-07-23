#!/usr/bin/env bash
# navigator-watch: Path A — file-change → batched update into a cmux pane.
#
# Watches a git project for changes, debounces them, waits until the target
# cmux pane looks idle, then injects a single "here's what changed" message
# (a git diff, size-capped) into that pane so the navigator agent can react.
#
# It never filters semantically — it relies on git (tracked files + .gitignore)
# for mechanical filtering and lets the agent judge significance.
#
# Requirements: bash, git, fswatch, node (for cmux.js in this dir).
#
# Config via env or flags:
#   --surface <id>        cmux surface (pane) id to send into        (required)
#   --session <name>      cmux session name                          (default: main)
#   --socket <path>       explicit cmux socket path                  (default: derived)
#   --dir <path>          git project to watch                       (default: cwd)
#   --debounce <secs>     quiet period after last change before flush(default: 3)
#   --idle <secs>         poll interval while waiting for idle        (default: 2)
#   --max-lines <n>       diff larger than this is summarized, not sent (default: 50)
#
# Idle detection prefers the Claude Code hook flag files written by hooks/on-stop.sh
# (last-idle) and hooks/on-busy.sh (last-busy): the agent is idle when last-idle is
# newer than last-busy. If those flags are absent (hooks not installed), it falls
# back to diffing read-screen snapshots of the pane.
#
# Example:
#   ./watch.sh --surface 4 --dir ~/work/thing

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMUX="node $HERE/cmux.js"

SURFACE=""
SESSION="main"
SOCKET=""
DIR="$PWD"
DEBOUNCE=3
IDLE=2
MAX_LINES=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --surface) SURFACE="$2"; shift 2;;
    --session) SESSION="$2"; shift 2;;
    --socket) SOCKET="$2"; shift 2;;
    --dir) DIR="$2"; shift 2;;
    --debounce) DEBOUNCE="$2"; shift 2;;
    --idle) IDLE="$2"; shift 2;;
    --max-lines) MAX_LINES="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -n "$SURFACE" ]] || { echo "error: --surface is required" >&2; exit 2; }
command -v fswatch >/dev/null || { echo "error: fswatch not found (brew install fswatch)" >&2; exit 2; }
command -v git >/dev/null || { echo "error: git not found" >&2; exit 2; }

cmux_args=(--session "$SESSION")
[[ -n "$SOCKET" ]] && cmux_args+=(--socket "$SOCKET")

STATE_DIR="${NAVIGATOR_STATE_DIR:-$HOME/.cache/navigator-watch}"
mkdir -p "$STATE_DIR"

cd "$DIR"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: --dir is not a git work tree: $DIR" >&2; exit 2; }

# Process lock keyed on the watched project, so two watchers can't race on the
# same effort. Stale locks (dead PID) are reclaimed.
LOCK_DIR="${TMPDIR:-/tmp}/navigator-watch"
mkdir -p "$LOCK_DIR"
LOCK="$LOCK_DIR/$(git rev-parse --show-toplevel | shasum | cut -d' ' -f1).lock"
if [[ -f "$LOCK" ]] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
  echo "error: a navigator-watch is already running for this project (pid $(cat "$LOCK"))" >&2
  exit 1
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# Working-tree changes vs HEAD, non-mutating (never touches the index, so it
# won't interfere with the human's own git workflow). .gitignore is respected
# for untracked files via --exclude-standard.
git_tracked_diff() { git diff HEAD 2>/dev/null || git diff 2>/dev/null || true; }
git_diffstat()     { git diff --stat=200 HEAD 2>/dev/null || git diff --stat=200 2>/dev/null || true; }
git_untracked()    { git ls-files --others --exclude-standard 2>/dev/null || true; }

read_screen() {
  $CMUX "${cmux_args[@]}" read-screen --surface "$SURFACE" 2>/dev/null || echo "{}"
}

hooks_available() { [[ -f "$STATE_DIR/last-idle" || -f "$STATE_DIR/last-busy" ]]; }

# Agent is idle when the most recent hook event was a Stop (last-idle newer than
# last-busy), or nothing is busy.
hook_idle() {
  [[ -f "$STATE_DIR/last-busy" ]] || return 0
  [[ "$STATE_DIR/last-idle" -nt "$STATE_DIR/last-busy" ]]
}

# Block until the agent looks idle. Prefer hook flags; fall back to read-screen
# diffing when hooks aren't installed.
wait_until_idle() {
  if hooks_available; then
    while ! hook_idle; do sleep "$IDLE"; done
    return 0
  fi
  local prev cur
  prev="$(read_screen)"
  while true; do
    sleep "$IDLE"
    cur="$(read_screen)"
    [[ "$cur" == "$prev" ]] && return 0
    prev="$cur"
  done
}

send_payload() {
  # Paste the body (multi-line safe), then submit with a separate Enter.
  $CMUX "${cmux_args[@]}" send --surface "$SURFACE" --paste --text "$1"
  $CMUX "${cmux_args[@]}" send-key --surface "$SURFACE" --keys enter
}

flush() {
  local tracked untracked stat nlines payload
  tracked="$(git_tracked_diff)"
  untracked="$(git_untracked)"
  [[ -z "$tracked" && -z "$untracked" ]] && return 0  # nothing meaningful to report

  wait_until_idle

  stat="$(git_diffstat)"
  [[ -n "$untracked" ]] && stat="${stat}"$'\n'"untracked (new) files:"$'\n'"${untracked}"
  nlines="$(printf '%s\n' "$tracked" | wc -l | tr -d ' ')"

  if [[ "$nlines" -gt "$MAX_LINES" ]]; then
    payload="[navigator-watch] Files changed since we last talked (large diff, ${nlines} lines — ask me to show specifics if relevant):
${stat}"
  else
    payload="[navigator-watch] Changes since we last talked:
${stat}
----
${tracked}"
  fi

  send_payload "$payload"
}

echo "navigator-watch: watching $DIR → cmux session=$SESSION surface=$SURFACE" >&2
echo "  debounce=${DEBOUNCE}s idle=${IDLE}s max-lines=${MAX_LINES}" >&2

# fswatch with a batch latency = debounce. Each emitted batch triggers a flush.
# --one-per-batch collapses a burst of events into a single line.
# Excludes are efficiency only (git already ignores build artifacts, so they'd
# never produce a diff) — they just keep fswatch from churning on large dirs.
fswatch --latency "$DEBOUNCE" --one-per-batch --recursive \
    --exclude '\.git/' \
    --exclude '/node_modules/' \
    --exclude '/\.next/' --exclude '/dist/' --exclude '/build/' \
    --exclude '/target/' --exclude '/\.venv/' \
    "$DIR" | while read -r _; do
  flush || echo "navigator-watch: flush failed" >&2
done
