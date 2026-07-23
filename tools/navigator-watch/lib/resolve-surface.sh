#!/usr/bin/env bash
# navigator-watch: auto-detect the cmux surface running Claude Code, so
# watch.sh/speak.sh don't need a hardcoded --surface (and Hammerspoon doesn't
# need per-pane editing).
#
# Strategy: find the workspace the cmux app currently has focused, then try to
# spot the surface running Claude Code via metadata heuristics (see below).
# Metadata alone has proven unreliable in practice (see the correction note
# on `resume_binding` below), so when the heuristic doesn't confidently find
# exactly one match, it falls back to asking the human to pick from a
# numbered list of the real surfaces — never silently guesses wrong.
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

# Heuristic signals tried, in order, before giving up and asking a human:
# `resume_binding.kind` (a structured field cmux sets on agent-launched
# surfaces) and `initial_command`/`title` containing "claude".
#
# CORRECTION: `resume_binding` was initially thought to be a stable identity
# marker (seen as `{"kind": "claude", ...}` on the Claude Code surface), but
# a second real-world capture showed the *same* surface with `resume_binding:
# null` moments later — it's transient (populated only around some
# resume/auto-approval event, not a persistent property), so it can't be
# trusted alone. `initial_command` has also been observed `null` on a real
# session (not always populated), and `title` reflects the live task/status
# line (e.g. "✣ Clarify email list source in EmailSelectWithContactDetails"),
# not literally "claude". None of these are blanket recursive string
# searches across all fields (which risks false positives, e.g.
# requested_working_directory containing "claude" as a path component) — but
# given all of them are known to be unreliable individually, they're treated
# as a fast-path heuristic only, not the source of truth. See
# `_navwatch_prompt_pick` for the human-confirmed fallback.
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

  local chosen=""
  if [[ "$n" -eq 1 ]]; then
    chosen="$ids"
  else
    # Heuristic metadata (resume_binding.kind, title, initial_command) has
    # proven unreliable in practice — resume_binding in particular is
    # transient (seen populated, then null moments later on the same
    # surface). Rather than guess again, ask a human: list every surface in
    # the workspace and let them pick. Falls through to the raw-JSON dump
    # below only if no selection is made (e.g. non-interactive/no stdin).
    chosen="$(_navwatch_prompt_pick "$panels_json" "$n")" || chosen=""
  fi

  if [[ -n "$chosen" ]]; then
    printf '%s\n' "$chosen"
    if [[ "$want_cache" -eq 1 ]]; then
      mkdir -p "$(_navwatch_state_dir)"
      printf '%s\n' "$chosen" > "$(_navwatch_surface_cache_file)"
    fi
    return 0
  fi

  {
    echo "Pass --surface explicitly (find it with: cmux list-panels --json)."
    echo "Raw 'cmux current-workspace --json':"
    printf '%s\n' "$ws_json"
    echo "Raw 'cmux ${panels_args[*]}':"
    printf '%s\n' "$panels_json"
  } >&2
  return 1
}

# Ask the human to pick, when heuristic matching found zero or multiple
# candidates. Lists every surface in the workspace (not just heuristic
# matches), so a total heuristic miss is still recoverable without leaving
# the terminal. Prints the menu/prompt to stderr; prints only the chosen ref
# to stdout on success. Returns non-zero (no stdout) if no selection is made
# (blank input, invalid choice, or no stdin to read from).
_navwatch_prompt_pick() {
  local panels_json="$1" n="$2"

  if [[ "$n" -eq 0 ]]; then
    echo "navigator-watch: couldn't confidently auto-detect the Claude Code surface." >&2
  else
    echo "navigator-watch: found multiple candidates, can't pick automatically." >&2
  fi

  # NOTE: fields are joined with \x1f (unit separator), not a tab/@tsv. Tab is
  # "IFS whitespace" to bash's `read`, which always collapses runs of it
  # regardless of what IFS is set to — an empty field (e.g. no resume_binding)
  # next to a tab would silently vanish and shift every field after it.
  local rows
  rows="$(printf '%s' "$panels_json" | jq -r '
    (if type=="array" then .
     else (.panels? // .surfaces? // .items? // .workspaces? // []) end)
    | to_entries[]
    | [(.key+1|tostring), (.value.ref // .value.id // "?"), (.value.resume_binding.kind // ""), (.value.title // "")]
    | join("\u001f")
  ' 2>/dev/null)"

  if [[ -z "$rows" ]]; then
    echo "navigator-watch: no surfaces found to choose from either." >&2
    return 1
  fi

  echo "Pick the surface running Claude Code:" >&2
  local -a refs=()
  while IFS=$'\x1f' read -r idx ref kind title; do
    refs[idx]="$ref"
    if [[ -n "$kind" ]]; then
      printf '  %s) %s  [agent: %s]  %s\n' "$idx" "$ref" "$kind" "$title" >&2
    else
      printf '  %s) %s  %s\n' "$idx" "$ref" "$title" >&2
    fi
  done <<< "$rows"

  printf 'Enter number (blank to cancel): ' >&2
  local choice
  read -r choice

  if [[ -z "$choice" || -z "${refs[$choice]:-}" ]]; then
    echo "navigator-watch: no valid selection made." >&2
    return 1
  fi

  printf '%s\n' "${refs[$choice]}"
}
