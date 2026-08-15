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
#                         exit 0. Exit 1 if --timeout elapses with an empty queue
#                         (0 = wait forever), or early if the watcher dies — so a
#                         forever-collect ends cleanly after --stop.
#   --stop                stop this project's watcher and clean up its state.
#   --status              report whether a watcher is running and how many
#                         detections are queued.
#
# Typical session: --arm once at startup, then a *backgrounded*
# `--collect --timeout 0` launched at the end of each agent turn — it exits when
# a change lands and the harness wakes the agent with its output. Run --collect
# in the foreground only for a quick manual check with a short --timeout; a
# foreground forever-collect holds the agent's turn open and blocks user input.
#
# Crude polling by design (no fswatch/inotify dependency). Level-triggered: the
# watcher compares a hash of the current working-tree state (tracked diff vs
# HEAD + per-file content hashes of untracked files) against the last one it
# queued, so an arm that starts late still sees changes made while it was down,
# and edits to files not yet `git add`ed are detected too.
#
# Detections are debounced: a change must hold steady for --idle seconds before
# it is queued, so one detection is a settled edit rather than a mid-keystroke
# snapshot, and a burst of typing (or editor autosave) collapses into a single
# detection instead of one per poll.
#
# Usage:
#   wait-for-change.sh --arm      [--dir PATH] [--interval SECS] [--idle SECS]
#   wait-for-change.sh --collect  [--dir PATH] [--timeout SECS]
#   wait-for-change.sh --stop     [--dir PATH]
#   wait-for-change.sh --status   [--dir PATH]
#
#   --dir       project to watch                         (default: cwd)
#   --interval  watcher poll interval                     (default: 3)
#   --idle      settle time before queueing a detection   (default: 5)
#   --timeout   collect give-up, 0 = wait forever         (default: 30)

set -euo pipefail

MODE=""
DIR="$PWD"
INTERVAL=3
IDLE=5
TIMEOUT=30
STATE_ROOT="${NAVIGATOR_STATE_DIR:-$HOME/.cache/navigator-watch}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arm|--collect|--stop|--status) MODE="${1#--}"; shift;;
    --dir) DIR="$2"; shift 2;;
    --interval) INTERVAL="$2"; shift 2;;
    --idle) IDLE="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;;
    --daemon) MODE="daemon"; shift;;   # internal: the forked watcher loop
    -h|--help) sed -n '2,/^[^#]/p' "$0" | sed '$d'; exit 0;;   # whole leading comment block
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

untracked_files() {
  git -C "$REPO" ls-files --others --exclude-standard 2>/dev/null || true
}

# Change-detection fingerprint: tracked diff vs HEAD, plus a per-file content
# hash of each untracked file (respecting .gitignore). Hashing content — not
# just listing names — is what makes edits to a not-yet-added file register;
# a name listing only changes when files appear or disappear.
# Known tradeoff: every poll re-reads and re-hashes ALL untracked content.
# Fine for the small source files a learning session produces; a large
# un-gitignored artifact (dataset, build output, log) makes every poll re-hash
# it. The remedy is to gitignore such files, not to tune this script.
current_state() {
  { git -C "$REPO" diff HEAD 2>/dev/null || git -C "$REPO" diff 2>/dev/null || true
    echo "---untracked---"
    untracked_files | while IFS= read -r f; do
      shasum "$REPO/$f" 2>/dev/null || printf 'unreadable %s\n' "$f"
    done
  }
}

# Human/agent-readable patch for a detection: tracked diff plus a real diff
# body for each untracked file (diffed against /dev/null, so new-file content
# is visible in the patch too).
current_patch() {
  { git -C "$REPO" diff HEAD 2>/dev/null || git -C "$REPO" diff 2>/dev/null || true
    untracked_files | while IFS= read -r f; do
      # -C makes the relative path resolve (and render in the patch header)
      # repo-root-relative, matching the tracked hunks above.
      git -C "$REPO" diff --no-index -- /dev/null "$f" 2>/dev/null || true
    done
  }
}

state_hash() {
  current_state | shasum | cut -d' ' -f1
}

# Size signal for a detection, derived from the patch itself so new/untracked
# files are counted. `git diff --shortstat` sees tracked changes only, which
# rendered every new-file detection as an indistinguishable "no delta" — and
# new files are the common case for someone learning an unfamiliar stack.
patch_stat() {
  git -C "$REPO" apply --numstat - < "$1" 2>/dev/null \
    | awk '{ a += ($1 == "-" ? 0 : $1); d += ($2 == "-" ? 0 : $2) }
           END { if (NR) printf "+%d/-%d lines over %d file(s)", a, d, NR }'
}

case "$MODE" in

  arm)
    if watcher_alive; then
      echo "[navigator-watch] already armed (pid $(cat "$PID_FILE"), repo $REPO)"
      exit 0
    fi
    rm -f "$PID_FILE"
    # Janitor: a session killed without --stop leaves its patch files behind,
    # and nothing else would ever delete them. Sweeping week-old patches
    # across ALL repo state dirs on every fresh arm bounds that leak without
    # touching anything a live queue could still reference.
    find "$STATE_ROOT" -name '*.patch' -mtime +7 -delete 2>/dev/null || true
    # Self-daemonize so the watcher outlives the tool call that started it.
    # setsid (util-linux) fully detaches the session but doesn't exist on
    # stock macOS; there, nohup + background + disown detaches well enough.
    if command -v setsid >/dev/null 2>&1; then
      setsid nohup "$0" --daemon --dir "$REPO" --interval "$INTERVAL" --idle "$IDLE" \
        >"$STATE/watcher.log" 2>&1 < /dev/null &
    else
      nohup "$0" --daemon --dir "$REPO" --interval "$INTERVAL" --idle "$IDLE" \
        >"$STATE/watcher.log" 2>&1 < /dev/null &
    fi
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
      last_hash="$(state_hash)"
      printf '%s' "$last_hash" > "$HASH_FILE"
    fi
    # Debounce state: a hash differing from what we last queued has to hold
    # steady for IDLE seconds before it counts as a settled edit worth waking
    # the agent for. Without this, every autosave mid-sentence is its own
    # detection, its own agent wakeup, and its own line of chrome.
    pending_hash=""
    pending_since=0
    while true; do
      now_hash="$(state_hash)"
      if [[ "$now_hash" == "$last_hash" ]]; then
        pending_hash=""                    # reverted to what we already queued
      elif [[ "$now_hash" != "$pending_hash" ]]; then
        pending_hash="$now_hash"           # still moving — restart the timer
        pending_since="$(date +%s)"
      elif (( $(date +%s) - pending_since >= IDLE )); then
        last_hash="$now_hash"
        pending_hash=""
        printf '%s' "$now_hash" > "$HASH_FILE"
        stamp="$(date +%H:%M:%S)"
        patch="$DIFF_DIR/$now_hash.patch"
        current_patch > "$patch"
        tracked="$(git -C "$REPO" diff --name-only HEAD 2>/dev/null || true)"
        untracked="$(untracked_files | sed 's/$/ (new)/' || true)"
        names="$(printf '%s\n%s' "$tracked" "$untracked" | grep -v '^$' | tr '\n' ' ' || true)"
        stat="$(patch_stat "$patch" || true)"
        [[ -n "${names// }" ]] || names="(working tree clean — changes reverted)"
        [[ -n "${stat// }" ]] || stat="no line delta"
        # One detection per line; --collect drains whatever accumulated.
        printf '%s  %s | %s | patch: %s\n' \
          "$stamp" "${names% }" "${stat# }" "$patch" >> "$QUEUE_FILE"
      fi
      sleep "$INTERVAL"
    done
    ;;

  collect)
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
      # Queue drained above, so nothing pending is lost: a dead watcher means no
      # new detections can arrive, and waiting on it would hang forever.
      if ! watcher_alive; then
        echo "[navigator-watch] watcher gone; ending collect" >&2
        exit 1
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
    # Drain first: a last edit made just before "stop watching" would otherwise
    # be destroyed unseen, at exactly the moment the agent is doing its
    # completion reflection. Patch files go with the stop, so print the summary
    # lines — filenames and stat are what a final reflection needs.
    if [[ -s "$QUEUE_FILE" ]]; then
      echo "[navigator-watch] uncollected detection(s) at stop (patches discarded):"
      cat "$QUEUE_FILE"
    fi
    if watcher_alive; then
      pid="$(cat "$PID_FILE")"
      kill "$pid" 2>/dev/null || true
      echo "[navigator-watch] stopped (pid $pid)"
    else
      echo "[navigator-watch] not running"
    fi
    rm -f "$PID_FILE" "$QUEUE_FILE"
    rm -rf "$DIFF_DIR"   # queue is gone with it, so nothing references the patches
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
