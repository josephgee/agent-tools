#!/usr/bin/env bash
# Claude Code hook for navigator-watch: marks the agent BUSY.
#
# Wire this to events that mean "the agent is now working and shouldn't be
# interrupted with an injected update" — recommended: UserPromptSubmit and
# PreToolUse. It just stamps a flag file the watcher compares against last-idle.

set -euo pipefail

STATE_DIR="${NAVIGATOR_STATE_DIR:-$HOME/.cache/navigator-watch}"
mkdir -p "$STATE_DIR"

# Drain stdin so Claude Code's pipe closes cleanly; we don't need the payload.
cat >/dev/null 2>&1 || true

touch "$STATE_DIR/last-busy"
exit 0
