#!/usr/bin/env bash
# navigator-watch: prime the cached surface for speak.sh, without starting the
# file watcher (watch.sh does this automatically as a side effect of starting;
# use this instead when you only want the voice path).
#
# Must be run from INSIDE the cmux pane running Claude Code — "current
# workspace"/"current pane" resolution is scoped to the caller's own pane, so
# this can't work launched ancestry-free (e.g. from Hammerspoon).
#
# Usage:
#   ./refresh-surface.sh              # auto-detect and cache
#   ./refresh-surface.sh surface:7    # cache an explicit surface instead

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/resolve-surface.sh
source "$HERE/lib/resolve-surface.sh"

if [[ $# -ge 1 ]]; then
  STATE_DIR="${NAVIGATOR_STATE_DIR:-$HOME/.cache/navigator-watch}"
  mkdir -p "$STATE_DIR"
  printf '%s\n' "$1" > "$STATE_DIR/surface"
  echo "navigator-watch: cached surface $1" >&2
else
  SURFACE="$(resolve_surface --cache)" || exit 1
  echo "navigator-watch: cached surface $SURFACE" >&2
fi
