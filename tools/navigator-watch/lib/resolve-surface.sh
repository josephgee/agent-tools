#!/usr/bin/env bash
# navigator-watch: auto-detect the cmux surface running Claude Code, so
# watch.sh/speak.sh don't need a hardcoded --surface (and Hammerspoon doesn't
# need per-pane editing).
#
# Strategy: find the workspace the cmux app currently has focused, then find
# a surface in it whose visible text (title/command/whatever field cmux uses)
# contains "claude". This is schema-agnostic on purpose — the exact JSON shape
# of `cmux current-workspace --json` / `cmux list-panels --json` isn't
# independently verified against a live cmux instance, only against its docs
# prose. If it can't find exactly one match, it fails loudly with the raw JSON
# instead of guessing, so you can tell what actually came back.
#
# IMPORTANT: "current workspace"/"current pane" resolution is scoped to the
# pane/window the `cmux` CLI is invoked FROM (confirmed: running `cmux
# list-panels --json` from inside a pane shows only that window's panels, not
# every open window) — i.e. it's ancestry-based, not "whichever workspace has
# UI focus." That means live resolution only works when called from inside a
# cmux pane. A process launched ancestry-free (e.g. by Hammerspoon) has
# nothing to scope to and can't reliably live-resolve.
#
# So: resolve live only where ancestry exists (watch.sh, run from inside the
# target cmux pane), and CACHE the result to a file. Anything ancestry-free
# (speak.sh via Hammerspoon) reads the cache instead of re-resolving.
#
# Usage:
#   resolve_surface            prints the id on stdout (live cmux query),
#                               or prints a diagnostic to stderr and returns
#                               non-zero. Only reliable from inside a cmux pane.
#   resolve_surface --cache    same, and also writes the result to
#                               $NAVIGATOR_STATE_DIR/surface on success.
#   read_cached_surface        prints the cached id on stdout, or returns
#                               non-zero (with a stderr message) if there is
#                               no cache yet.

# Primary signal: `resume_binding.kind` — a structured, exact field cmux sets
# on agent-launched surfaces (confirmed against a real cmux session: the
# Claude Code surface had `resume_binding: {"kind": "claude", "name": "Claude
# Code", ...}`; other surfaces had `resume_binding: null`). This is much more
# reliable than text matching — `initial_command` was null on a real session
# (not always populated), and `title` reflects the live task/status line
# (e.g. "✣ Clarify email list source in EmailSelectWithContactDetails"), not
# literally "claude".
#
# Fallback signal: `initial_command`/`title` containing "claude" (kept for
# surfaces without a resume_binding, e.g. a claude process started by hand
# rather than through cmux's agent-launch mechanism). Deliberately NOT a
# blanket recursive string search across all fields: fields like
# requested_working_directory could contain "claude" as a path component and
# false-positive.
#
# Identifiers are refs like "surface:7", under the key `ref` (confirmed
# against a real `cmux list-panels --json` response).
_navwatch_jq_find_claude_id() {
  jq -r '
    (if type=="array" then .
     else (.panels? // .surfaces? // .items? // .workspaces? // [] ) end)
    | .[]
    | select(
        ((.resume_binding.kind? // "") | test("claude"; "i"))
        or (((.initial_command // "") + " " + (.title // "")) | test("claude"; "i"))
      )
    | (.ref? // .id? // .surface_id? // .surfaceId? // .surface? // .panel_id? // empty)
  '
}

_navwatch_state_dir() { echo "${NAVIGATOR_STATE_DIR:-$HOME/.cache/navigator-watch}"; }
_navwatch_surface_cache_file() { echo "$(_navwatch_state_dir)/surface"; }

read_cached_surface() {
  local f; f="$(_navwatch_surface_cache_file)"
  if [[ -s "$f" ]]; then
    cat "$f"
    return 0
  fi
  echo "navigator-watch: no cached surface at $f yet. Run watch.sh (or refresh-surface.sh) from inside the target cmux pane first." >&2
  return 1
}

resolve_surface() {
  command -v jq >/dev/null || {
    echo "error: jq not found (brew install jq) — needed for live surface auto-detect (not for reading a cache)" >&2
    return 1
  }
  local want_cache=0
  [[ "${1:-}" == "--cache" ]] && want_cache=1
  local ws_json ws_id panels_json ids n

  ws_json="$("${CMUX:-cmux}" current-workspace --json 2>/dev/null)" || {
    echo "error: 'cmux current-workspace --json' failed" >&2; return 1; }

  ws_id="$(printf '%s' "$ws_json" | jq -r \
    '.ref? // .workspace_ref? // .id? // .workspace_id? // .workspaceId? // .workspace?.ref? // .workspace?.id? // empty' 2>/dev/null)"

  local panels_args=(list-panels --json)
  [[ -n "$ws_id" ]] && panels_args=(list-panels --workspace "$ws_id" --json)

  panels_json="$("${CMUX:-cmux}" "${panels_args[@]}" 2>/dev/null)" || {
    echo "error: 'cmux ${panels_args[*]}' failed" >&2; return 1; }

  ids="$(printf '%s' "$panels_json" | _navwatch_jq_find_claude_id 2>/dev/null || true)"
  n="$(printf '%s\n' "$ids" | grep -c . || true)"

  if [[ "$n" -eq 1 ]]; then
    printf '%s\n' "$ids"
    if [[ "$want_cache" -eq 1 ]]; then
      mkdir -p "$(_navwatch_state_dir)"
      printf '%s\n' "$ids" > "$(_navwatch_surface_cache_file)"
    fi
    return 0
  fi

  {
    if [[ "$n" -eq 0 ]]; then
      echo "navigator-watch: couldn't auto-detect a surface running claude."
    else
      echo "navigator-watch: found multiple candidate surfaces, can't pick automatically:"
      echo "$ids" | sed 's/^/  candidate id: /'
    fi
    echo "Pass --surface explicitly (find it with: cmux list-panels --json)."
    echo "Raw 'cmux current-workspace --json':"
    printf '%s\n' "$ws_json"
    echo "Raw 'cmux ${panels_args[*]}':"
    printf '%s\n' "$panels_json"
  } >&2
  return 1
}
