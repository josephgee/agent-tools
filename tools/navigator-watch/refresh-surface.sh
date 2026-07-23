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

# Resolve our own real directory, following symlinks, so lib/resolve-surface.sh
# is found relative to the real script even if invoked via a symlink.
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  [[ "$_src" != /* ]] && _src="$_dir/$_src"
done
HERE="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
unset _src _dir
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
