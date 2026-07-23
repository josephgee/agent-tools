#!/usr/bin/env bash
# navigator-watch (stage 0): crude polling watch-and-diff, called by the AGENT
# itself (not an external process) — this is the "pull, not push" version.
#
# Run this from inside a Claude Code session loaded with the `navigator`
# skill, as a normal bash tool call at the end of a coaching turn. It blocks
# (polling every --interval) until the git working tree differs from the
# last change it reported, then prints a compact summary and exits 0 so the
# agent can react. If --timeout elapses with nothing new, exits 1 so the
# skill loop knows to just call again.
#
# No fswatch, no debounce, no cmux, no surface resolution — on purpose. This
# is meant to validate the core coaching loop first; add sophistication only
# once that's proven out.
#
# Usage:
#   wait-for-change.sh [--dir PATH] [--interval SECS] [--timeout SECS]
#
#   --dir       project to watch                          (default: cwd)
#   --interval  poll interval while waiting                (default: 5)
#   --timeout   give up and exit 1 after this many secs     (default: 0 = never)

set -euo pipefail

DIR="$PWD"
INTERVAL=5
TIMEOUT=0
STATE_DIR="${NAVIGATOR_STATE_DIR:-$HOME/.cache/navigator-watch}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DIR="$2"; shift 2;;
    --interval) INTERVAL="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

mkdir -p "$STATE_DIR"
HASH_FILE="$STATE_DIR/last-hash"
DIFF_FILE="$STATE_DIR/last-diff.patch"

cd "$DIR"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: --dir is not a git work tree: $DIR" >&2; exit 2; }

# Working-tree changes vs HEAD, plus untracked files (respecting .gitignore).
current_diff() {
  { git diff HEAD 2>/dev/null || git diff 2>/dev/null || true
    echo "---untracked---"
    git ls-files --others --exclude-standard 2>/dev/null || true
  }
}

last_hash="$(cat "$HASH_FILE" 2>/dev/null || true)"
elapsed=0

while true; do
  diff_now="$(current_diff)"
  now_hash="$(printf '%s' "$diff_now" | shasum | cut -d' ' -f1)"

  if [[ -n "$diff_now" && "$now_hash" != "$last_hash" ]]; then
    printf '%s' "$now_hash" > "$HASH_FILE"
    printf '%s' "$diff_now" > "$DIFF_FILE"
    stat="$(git diff --stat=200 HEAD 2>/dev/null || git diff --stat=200 2>/dev/null || true)"
    names="$(git diff --name-only HEAD 2>/dev/null | tr '\n' ' ')"
    echo "[navigator-watch] change detected: ${names% }"
    echo "$stat"
    echo "(full diff: $DIFF_FILE)"
    exit 0
  fi

  if [[ "$TIMEOUT" -gt 0 && "$elapsed" -ge "$TIMEOUT" ]]; then
    echo "[navigator-watch] no changes in ${TIMEOUT}s"
    exit 1
  fi

  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done
