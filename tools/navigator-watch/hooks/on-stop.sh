#!/usr/bin/env bash
# Claude Code `Stop` hook for navigator-watch (Path C: agent → voice).
#
# On each turn end: speak the agent's last message aloud, and mark the agent
# idle (a flag file the watcher uses to decide when it's safe to inject a
# batched file-change update).
#
# Wire it up in a Claude Code settings file (see README). Claude Code passes the
# hook payload as JSON on stdin; this script forwards it to the extractor.
#
# TTS engine is swappable via $NAVIGATOR_TTS (a command reading text on stdin).
# Default: macOS `say`.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${NAVIGATOR_STATE_DIR:-$HOME/.cache/navigator-watch}"
mkdir -p "$STATE_DIR"

payload="$(cat)"

# Mark idle: the watcher flushes only when last-idle is newer than last-busy.
touch "$STATE_DIR/last-idle"

# Speak the agent's last message.
text="$(printf '%s' "$payload" | node "$HERE/extract-last-assistant.js")"
[[ -z "${text// /}" ]] && exit 0

if [[ -n "${NAVIGATOR_TTS:-}" ]]; then
  printf '%s' "$text" | eval "$NAVIGATOR_TTS" >/dev/null 2>&1 || true
elif command -v say >/dev/null; then
  printf '%s' "$text" | say >/dev/null 2>&1 || true
fi

exit 0
