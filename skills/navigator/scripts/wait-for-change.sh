#!/usr/bin/env bash
# navigator-watch: arm/collect file watcher for the `navigator` skill.
#
# Split into two operations so the agent can keep watching while it composes:
#
#   --arm                 start a background watcher for this project (idempotent,
#                         returns immediately). Detections are appended to a queue
#                         file rather than printed, so nothing is missed between
#                         collects.
#   --collect [--timeout] block until the queue is non-empty, print and drain it,
#                         exit 0. Exit 1 if --timeout elapses with an empty queue.
#   --stop                stop this project's watcher and clean up its state.
#   --status              report whether a watcher is running and how many
#                         detections are queued.
#
# Typical session: --arm once at startup, then --collect at the end of every turn.
#
# Crude polling by design (no fswatch/inotify dependency). Level-triggered: the
# watcher compares a hash of the current working-tree diff against the last one
# it queued, so an arm that starts late still sees changes made while it was down.
#
# Usage:
#   wait-for-change.sh --arm      [--dir PATH] [--interval SECS]
#   wait-for-change.sh --collect  [--dir PATH] [--timeout SECS]
#   wait-for-change.sh --stop     [--dir PATH]
#   wait-for-change.sh --status   [--dir PATH]
#
#   --dir       project to watch                         (default: cwd)
#   --interval  watcher poll interval                     (default: 3)
#   --timeout   collect give-up, 0 = wait forever         (default: 30)

set -euo pipefail

MODE=""
DIR="$PWD"
INTERVAL=3
TIMEOUT=30
STATE_ROOT="${NAVIGATOR_STATE_DIR:-$HOME/.cache/navigator-watch}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arm|--collect|--stop|--status) MODE="${1#--}"; shift;;
    --dir) DIR="$2"; shift 2;;
    --interval) INTERVAL="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;;
    --daemon) MODE="daemon"; shift;;   # internal: the forked watcher loop
    -h|--help) sed -n '2,30p' "$0"; exit 0;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -n "$MODE" ]] || { echo "error: need one of --arm / --collect / --stop / --status" >&2; exit 2; }

cd "$DIR"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: not a git work tree: $DIR" >&2; exit 2; }
REPO="$(git rev-parse --show-toplevel)"

# Per-project state dir, keyed by repo path so multiple projects don't collide.
KEY="$(printf '%s' "$REPO" | shasum | cut -c1-12)"
STATE="$STATE_ROOT/$KEY"
mkdir -p "$STATE"
PID_FILE="$STATE/watcher.pid"
QUEUE_FILE="$STATE/queue"
HASH_FILE="$STATE/last-hash"
DIFF_DIR="$STATE/diffs"
mkdir -p "$DIFF_DIR"
printf '%s\n' "$REPO" > "$STATE/repo"

watcher_alive() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid; pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# Working-tree changes vs HEAD plus untracked files (respecting .gitignore).
current_diff() {
  { git -C "$REPO" diff HEAD 2>/dev/null || git -C "$REPO" diff 2>/dev/null || true
    echo "---untracked---"
    git -C "$REPO" ls-files --others --exclude-standard 2>/dev/null || true
  }
}

case "$MODE" in

  arm)
    if watcher_alive; then
      echo "[navigator-watch] already armed (pid $(cat "$PID_FILE"), repo $REPO)"
      exit 0
    fi
    rm -f "$PID_FILE"
    # Self-daemonize so the watcher outlives the tool call that started it.
    setsid nohup "$0" --daemon --dir "$REPO" --interval "$INTERVAL" \
      >"$STATE/watcher.log" 2>&1 < /dev/null &
    disown 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      watcher_alive && break
      sleep 0.2
    done
    if watcher_alive; then
      echo "[navigator-watch] armed (pid $(cat "$PID_FILE"), repo $REPO, poll ${INTERVAL}s)"
    else
      echo "[navigator-watch] failed to arm; see $STATE/watcher.log" >&2
      exit 1
    fi
    ;;

  daemon)
    echo $$ > "$PID_FILE"
    trap 'rm -f "$PID_FILE"' EXIT
    # Baseline: if we have no persisted hash this is a first arm, so record the
    # current state without reporting it. If we do have one, it survived a
    # previous arm and anything that changed while we were down is real news.
    last_hash="$(cat "$HASH_FILE" 2>/dev/null || true)"
    if [[ -z "$last_hash" ]]; then
      last_hash="$(printf '%s' "$(current_diff)" | shasum | cut -d' ' -f1)"
      printf '%s' "$last_hash" > "$HASH_FILE"
    fi
    while true; do
      diff_now="$(current_diff)"
      now_hash="$(printf '%s' "$diff_now" | shasum | cut -d' ' -f1)"
      if [[ -n "$diff_now" && "$now_hash" != "$last_hash" ]]; then
        last_hash="$now_hash"
        printf '%s' "$now_hash" > "$HASH_FILE"
        stamp="$(date +%H:%M:%S)"
        patch="$DIFF_DIR/$now_hash.patch"
        printf '%s' "$diff_now" > "$patch"
        tracked="$(git -C "$REPO" diff --name-only HEAD 2>/dev/null || true)"
        untracked="$(git -C "$REPO" ls-files --others --exclude-standard 2>/dev/null \
                     | sed 's/$/ (new)/' || true)"
        names="$(printf '%s\n%s' "$tracked" "$untracked" | grep -v '^$' | tr '\n' ' ' || true)"
        stat="$(git -C "$REPO" diff --shortstat HEAD 2>/dev/null || true)"
        [[ -n "${names// }" ]] || names="(working tree clean — changes reverted)"
        [[ -n "${stat// }" ]] || stat="no tracked-line delta"
        # One detection per line; --collect drains whatever accumulated.
        printf '%s  %s | %s | patch: %s\n' \
          "$stamp" "${names% }" "${stat# }" "$patch" >> "$QUEUE_FILE"
      fi
      sleep "$INTERVAL"
    done
    ;;

  collect)
    watcher_alive || echo "[navigator-watch] warning: no watcher armed for $REPO" >&2
    elapsed=0
    while true; do
      if [[ -s "$QUEUE_FILE" ]]; then
        # Drain atomically so a detection during printing isn't lost.
        # mv is atomic and frees the path; the daemon recreates it on its next
        # append. Do NOT truncate afterwards — that races with an append landing
        # between the mv and the truncate, silently dropping a detection.
        tmp="$QUEUE_FILE.draining.$$"
        mv "$QUEUE_FILE" "$tmp"
        count="$(wc -l < "$tmp" | tr -d ' ')"
        echo "[navigator-watch] $count change(s):"
        cat "$tmp"
        rm -f "$tmp"
        exit 0
      fi
      if [[ "$TIMEOUT" -gt 0 && "$elapsed" -ge "$TIMEOUT" ]]; then
        echo "[navigator-watch] no changes in ${TIMEOUT}s"
        exit 1
      fi
      sleep 1
      elapsed=$((elapsed + 1))
    done
    ;;

  stop)
    if watcher_alive; then
      pid="$(cat "$PID_FILE")"
      kill "$pid" 2>/dev/null || true
      echo "[navigator-watch] stopped (pid $pid)"
    else
      echo "[navigator-watch] not running"
    fi
    rm -f "$PID_FILE" "$QUEUE_FILE"
    ;;

  status)
    if watcher_alive; then
      echo "[navigator-watch] armed (pid $(cat "$PID_FILE"), repo $REPO)"
    else
      echo "[navigator-watch] not armed (repo $REPO)"
    fi
    queued=0
    [[ -f "$QUEUE_FILE" ]] && queued="$(wc -l < "$QUEUE_FILE" | tr -d ' ')"
    echo "[navigator-watch] queued detections: $queued"
    ;;

esac
