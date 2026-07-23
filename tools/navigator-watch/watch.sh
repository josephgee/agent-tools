#!/usr/bin/env bash
# navigator-watch: Path A — file-change → batched update into a cmux surface.
#
# Watches a git project for changes, debounces them, waits until the agent is
# idle, then injects a one-line "here's what changed" message into the target
# cmux surface (the Claude Code pane). The full diff is written to a file the
# agent can read on demand — this keeps a single line going into the prompt
# (avoids multi-line submit issues) and keeps context small.
#
# Uses the cmux macOS app's CLI (`cmux send` / `cmux send-key`). The socket is
# reachable by default from processes started inside a cmux terminal ("cmux
# processes only" mode), so run this from a cmux pane. From outside cmux you'd
# need CMUX_SOCKET_MODE=allowAll.
#
# Requirements: bash, git, fswatch, and the `cmux` CLI on PATH.
#
# Config via flags:
#   --surface <id>     target cmux surface id. If omitted, auto-detected as the
#                      surface running claude in the currently focused cmux
#                      workspace (see lib/resolve-surface.sh).
#   --dir <path>       git project to watch                         (default: cwd)
#   --debounce <secs>  quiet period after last change before flush  (default: 3)
#   --idle <secs>      poll interval while waiting for idle          (default: 2)
#   --max-lines <n>    diff bigger than this note as large           (default: 50)
#
# Example:
#   ./watch.sh --surface 3 --dir ~/work/thing

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMUX="${CMUX_BIN:-cmux}"
# shellcheck source=lib/resolve-surface.sh
source "$HERE/lib/resolve-surface.sh"
STATE_DIR="${NAVIGATOR_STATE_DIR:-$HOME/.cache/navigator-watch}"
mkdir -p "$STATE_DIR"
DIFF_FILE="$STATE_DIR/last-diff.patch"

SURFACE=""
DIR="$PWD"
DEBOUNCE=3
IDLE=2
MAX_LINES=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --surface) SURFACE="$2"; shift 2;;
    --dir) DIR="$2"; shift 2;;
    --debounce) DEBOUNCE="$2"; shift 2;;
    --idle) IDLE="$2"; shift 2;;
    --max-lines) MAX_LINES="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ -z "$SURFACE" ]]; then
  SURFACE="$(resolve_surface)" || exit 2
  echo "navigator-watch: auto-detected surface $SURFACE" >&2
fi
command -v fswatch >/dev/null || { echo "error: fswatch not found (brew install fswatch)" >&2; exit 2; }
command -v git >/dev/null || { echo "error: git not found" >&2; exit 2; }
command -v "$CMUX" >/dev/null || { echo "error: cmux CLI not found on PATH" >&2; exit 2; }

cd "$DIR"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: --dir is not a git work tree: $DIR" >&2; exit 2; }

# Process lock keyed on the watched project, so two watchers can't race.
LOCK_DIR="${TMPDIR:-/tmp}/navigator-watch"
mkdir -p "$LOCK_DIR"
LOCK="$LOCK_DIR/$(git rev-parse --show-toplevel | shasum | cut -d' ' -f1).lock"
if [[ -f "$LOCK" ]] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
  echo "error: a navigator-watch is already running for this project (pid $(cat "$LOCK"))" >&2
  exit 1
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# Working-tree changes vs HEAD, non-mutating (never touches the index).
# .gitignore is respected for untracked files via --exclude-standard.
git_tracked_diff() { git diff HEAD 2>/dev/null || git diff 2>/dev/null || true; }
git_diffstat()     { git diff --stat=200 HEAD 2>/dev/null || git diff --stat=200 2>/dev/null || true; }
git_untracked()    { git ls-files --others --exclude-standard 2>/dev/null || true; }

# Idle is driven by the Claude Code hook flag files (hooks/on-stop.sh writes
# last-idle, hooks/on-busy.sh writes last-busy): idle == last-idle newer than
# last-busy. Without the hooks installed we can't tell, so we just proceed
# after the debounce (best effort) and warn once.
hooks_available() { [[ -f "$STATE_DIR/last-idle" || -f "$STATE_DIR/last-busy" ]]; }
hook_idle() {
  [[ -f "$STATE_DIR/last-busy" ]] || return 0
  [[ "$STATE_DIR/last-idle" -nt "$STATE_DIR/last-busy" ]]
}
warned_no_hooks=0
wait_until_idle() {
  if hooks_available; then
    while ! hook_idle; do sleep "$IDLE"; done
    return 0
  fi
  if [[ "$warned_no_hooks" -eq 0 ]]; then
    echo "navigator-watch: hook flags not found; install hooks/ for idle detection. Flushing without idle-wait." >&2
    warned_no_hooks=1
  fi
}

send_line() {
  "$CMUX" send --surface "$SURFACE" "$1"
  "$CMUX" send-key --surface "$SURFACE" enter
}

flush() {
  local tracked untracked names nfiles nlines msg
  tracked="$(git_tracked_diff)"
  untracked="$(git_untracked)"
  [[ -z "$tracked" && -z "$untracked" ]] && return 0  # nothing meaningful

  wait_until_idle

  # Write the full diff (+ untracked list) to a file the agent can read.
  { git_diffstat; echo; echo "$tracked"; \
    [[ -n "$untracked" ]] && { echo; echo "untracked (new) files:"; echo "$untracked"; }; } > "$DIFF_FILE"

  names="$(git diff --name-only HEAD 2>/dev/null | tr '\n' ' ')"
  [[ -n "$untracked" ]] && names="$names$(printf '%s' "$untracked" | tr '\n' ' ')"
  nfiles="$(printf '%s' "$names" | wc -w | tr -d ' ')"
  nlines="$(printf '%s\n' "$tracked" | wc -l | tr -d ' ')"

  # Single line into the prompt: summary + path to the full diff.
  msg="[navigator-watch] Changes since we last talked: ${nfiles} file(s) (${names%% }), ~${nlines} diff lines. Full diff: ${DIFF_FILE} — read it if relevant."
  send_line "$msg"
}

echo "navigator-watch: watching $DIR → cmux surface=$SURFACE (via cmux CLI)" >&2
echo "  debounce=${DEBOUNCE}s idle=${IDLE}s; full diffs written to $DIFF_FILE" >&2

# fswatch batch latency = debounce; --one-per-batch collapses a burst to one line.
# Excludes are efficiency only (git already ignores build artifacts).
fswatch --latency "$DEBOUNCE" --one-per-batch --recursive \
    --exclude '\.git/' \
    --exclude '/node_modules/' \
    --exclude '/\.next/' --exclude '/dist/' --exclude '/build/' \
    --exclude '/target/' --exclude '/\.venv/' \
    "$DIR" | while read -r _; do
  flush || echo "navigator-watch: flush failed" >&2
done
