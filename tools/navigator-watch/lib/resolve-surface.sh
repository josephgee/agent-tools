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
# Usage: source this file, then call `resolve_surface` (prints the id on
# stdout, or prints a diagnostic to stderr and returns non-zero).

command -v jq >/dev/null || { echo "error: jq not found (brew install jq) — needed for surface auto-detect" >&2; return 1 2>/dev/null || exit 1; }

# Match on `initial_command` (set once at pane creation, e.g. a
# cmux-agent-resume/claude-<uuid>.zsh resume script — stable) and `title`
# (whatever's currently in the foreground — catches a live `claude` process,
# but drifts once you run something else in that pane). Deliberately NOT a
# blanket recursive string search: fields like requested_working_directory
# could contain "claude" as a path component and false-positive.
# Identifiers are refs like "surface:7", under the key `ref` (confirmed
# against a real `cmux list-panels --json` response).
_navwatch_jq_find_claude_id() {
  jq -r '
    (if type=="array" then .
     else (.panels? // .surfaces? // .items? // .workspaces? // [] ) end)
    | .[]
    | select( ((.initial_command // "") + " " + (.title // "")) | test("claude"; "i") )
    | (.ref? // .id? // .surface_id? // .surfaceId? // .surface? // .panel_id? // empty)
  '
}

resolve_surface() {
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
