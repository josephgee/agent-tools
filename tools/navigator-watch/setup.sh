#!/usr/bin/env bash
# navigator-watch: idempotent setup for the navigator skill + this tool.
#
# Meant to be run BY AN AGENT on your behalf (or by you directly) — "hey,
# run tools/navigator-watch/setup.sh for me" — rather than hand-typing every
# step from the READMEs. Safe to re-run: every step checks the current state
# first and only changes what's missing, reporting what it did or skipped.
#
# What it does, each independently skippable:
#   1. Global gitignore for .navigator/ (git config --global core.excludesFile)
#   2. Scaffold ~/.claude/navigator/coaching.md (global coaching directives)
#   3. Scaffold <project-dir>/.navigator/coaching.md (project-local directives)
#   4. Merge this tool's Claude Code hooks into a settings.json (additive,
#      never overwrites unrelated hooks/settings)
#   5. Symlink watch.sh onto PATH as `navigator-watch`
#   6. Report on Hammerspoon config (does NOT overwrite an existing config —
#      prints what to add if one exists; symlinks only if none exists)
#
# What it deliberately does NOT do:
#   - Write actual coaching content (that's the human's to author — it only
#     scaffolds an empty template if the file doesn't exist yet)
#   - Touch cmux's socket access-mode setting (that's a one-time manual step
#     in cmux's own Settings UI, not scriptable from outside the app)
#   - Install brew/npm dependencies (jq, fswatch, cmux, whisper, etc.) — see
#     README Prerequisites
#
# Usage:
#   ./setup.sh [--project-dir <path>] [--claude-settings <path>]
#              [--bin-dir <path>] [--skip-gitignore] [--skip-coaching]
#              [--skip-hooks] [--skip-path] [--skip-hammerspoon]
#
# Defaults: --project-dir is cwd, --claude-settings is ~/.claude/settings.json
# (use .claude/settings.json in a project dir instead if you want the hooks
# scoped to one project rather than global), --bin-dir is /usr/local/bin.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_DIR="$PWD"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
BIN_DIR="/usr/local/bin"
SKIP_GITIGNORE=0
SKIP_COACHING=0
SKIP_HOOKS=0
SKIP_PATH=0
SKIP_HAMMERSPOON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir) PROJECT_DIR="$2"; shift 2;;
    --claude-settings) CLAUDE_SETTINGS="$2"; shift 2;;
    --bin-dir) BIN_DIR="$2"; shift 2;;
    --skip-gitignore) SKIP_GITIGNORE=1; shift;;
    --skip-coaching) SKIP_COACHING=1; shift;;
    --skip-hooks) SKIP_HOOKS=1; shift;;
    --skip-path) SKIP_PATH=1; shift;;
    --skip-hammerspoon) SKIP_HAMMERSPOON=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

command -v git >/dev/null || { echo "error: git not found — required even with --skip-gitignore/--skip-coaching, since project-local scaffolding checks for a git repo" >&2; exit 2; }

note()  { echo "  - $*"; }
did()   { echo "  ✓ $*"; }
skip()  { echo "  · $* (already set up)"; }
warn()  { echo "  ! $*" >&2; }

COACHING_TEMPLATE='# Navigator coaching directives

## Coach me toward
-

## Don'"'"'t bother
-

## Interaction style
-

## Stack notes
-
'

echo "navigator-watch setup"
echo "======================"

# 1. Global gitignore for .navigator/
if [[ "$SKIP_GITIGNORE" -eq 0 ]]; then
  echo; echo "[1/6] Global gitignore for .navigator/"
  EXCLUDES_FILE="$(git config --global core.excludesFile 2>/dev/null || true)"
  if [[ -z "$EXCLUDES_FILE" ]]; then
    EXCLUDES_FILE="$HOME/.config/git/ignore"
    git config --global core.excludesFile "$EXCLUDES_FILE"
    did "set git config --global core.excludesFile to $EXCLUDES_FILE"
  else
    EXCLUDES_FILE="${EXCLUDES_FILE/#\~/$HOME}"
    note "using your existing core.excludesFile: $EXCLUDES_FILE"
  fi
  mkdir -p "$(dirname "$EXCLUDES_FILE")"
  touch "$EXCLUDES_FILE"
  if grep -qxF '.navigator/' "$EXCLUDES_FILE" 2>/dev/null; then
    skip ".navigator/ already in $EXCLUDES_FILE"
  else
    echo '.navigator/' >> "$EXCLUDES_FILE"
    did "added .navigator/ to $EXCLUDES_FILE"
  fi
else
  echo; echo "[1/6] Global gitignore — skipped (--skip-gitignore)"
fi

# 2 & 3. Coaching directive scaffolds
if [[ "$SKIP_COACHING" -eq 0 ]]; then
  echo; echo "[2/6] Global coaching directives (~/.claude/navigator/coaching.md)"
  GLOBAL_COACHING="$HOME/.claude/navigator/coaching.md"
  if [[ -f "$GLOBAL_COACHING" ]]; then
    skip "$GLOBAL_COACHING already exists, left untouched"
  else
    mkdir -p "$(dirname "$GLOBAL_COACHING")"
    printf '%s' "$COACHING_TEMPLATE" > "$GLOBAL_COACHING"
    did "scaffolded $GLOBAL_COACHING — edit it to add your preferences"
  fi

  echo; echo "[3/6] Project-local coaching directives ($PROJECT_DIR/.navigator/coaching.md)"
  if [[ -d "$PROJECT_DIR/.git" || -f "$PROJECT_DIR/.git" ]] || git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    PROJECT_COACHING="$PROJECT_DIR/.navigator/coaching.md"
    if [[ -f "$PROJECT_COACHING" ]]; then
      skip "$PROJECT_COACHING already exists, left untouched"
    else
      mkdir -p "$(dirname "$PROJECT_COACHING")"
      printf '%s' "$COACHING_TEMPLATE" > "$PROJECT_COACHING"
      did "scaffolded $PROJECT_COACHING — edit it to add project-specific preferences"
    fi
  else
    warn "$PROJECT_DIR doesn't look like a git repo — skipped project-local scaffold. Pass --project-dir to point at the project you're learning in."
  fi
else
  echo; echo "[2-3/6] Coaching directive scaffolds — skipped (--skip-coaching)"
fi

# 4. Merge Claude Code hooks (additive — never overwrites existing hooks/settings)
if [[ "$SKIP_HOOKS" -eq 0 ]]; then
  echo; echo "[4/6] Claude Code hooks ($CLAUDE_SETTINGS)"
  if ! command -v jq >/dev/null; then
    warn "jq not found (brew install jq) — can't safely merge JSON, skipping hooks setup"
  else
    NEW_HOOKS_TEMPLATE="$HERE/claude-settings.example.json"
    mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
    [[ -f "$CLAUDE_SETTINGS" ]] || echo '{}' > "$CLAUDE_SETTINGS"

    if ! jq empty "$CLAUDE_SETTINGS" 2>/dev/null; then
      warn "$CLAUDE_SETTINGS isn't valid JSON — not touching it. Fix it by hand or pass --skip-hooks, then re-run."
    else
      # Substitute ABSOLUTE_PATH with this tool's real directory, then merge
      # additively: for each hook event, concatenate existing + new hook groups
      # and de-dup by command, so re-running never duplicates entries and any
      # hooks you already had for other tools are preserved untouched.
      RESOLVED_HOOKS="$(sed "s#ABSOLUTE_PATH#$HERE#g" "$NEW_HOOKS_TEMPLATE")"
      MERGED="$(jq -s '
        .[0] as $old | .[1] as $new |
        $old * {hooks: (
          ($old.hooks // {}) as $oh |
          ($new.hooks // {}) as $nh |
          (($oh | keys) + ($nh | keys) | unique) as $allkeys |
          reduce $allkeys[] as $k ({}; . + { ($k): (($oh[$k] // []) + ($nh[$k] // []) | unique_by(.hooks[0].command? // .)) })
        )}
      ' "$CLAUDE_SETTINGS" <(echo "$RESOLVED_HOOKS"))"

      # Belt-and-suspenders: refuse to write anything that isn't itself valid,
      # non-empty JSON, in case of a merge-logic bug — never trust MERGED blind.
      if [[ -z "$MERGED" ]] || ! printf '%s' "$MERGED" | jq empty >/dev/null 2>&1; then
        warn "merge produced unexpected output — not writing anything. Please report this; $CLAUDE_SETTINGS is untouched."
      elif [[ "$MERGED" == "$(cat "$CLAUDE_SETTINGS")" ]]; then
        skip "hooks already present in $CLAUDE_SETTINGS"
      else
        BACKUP="$CLAUDE_SETTINGS.bak.$(date +%s)"
        if cp "$CLAUDE_SETTINGS" "$BACKUP" && [[ -f "$BACKUP" ]]; then
          printf '%s\n' "$MERGED" > "$CLAUDE_SETTINGS"
          did "merged Stop/UserPromptSubmit/PreToolUse hooks into $CLAUDE_SETTINGS (backup: $BACKUP)"
        else
          warn "couldn't write a backup at $BACKUP — refusing to modify $CLAUDE_SETTINGS without one. Check permissions/disk space and re-run."
        fi
      fi
    fi
  fi
else
  echo; echo "[4/6] Claude Code hooks — skipped (--skip-hooks)"
fi

# 5. PATH symlink for watch.sh
if [[ "$SKIP_PATH" -eq 0 ]]; then
  echo; echo "[5/6] navigator-watch on PATH ($BIN_DIR)"
  TARGET="$BIN_DIR/navigator-watch"
  if [[ -L "$TARGET" && "$(readlink "$TARGET")" == "$HERE/watch.sh" ]]; then
    skip "$TARGET already links here"
  elif [[ -e "$TARGET" ]]; then
    warn "$TARGET already exists and isn't our symlink — leaving it alone"
  else
    if ln -s "$HERE/watch.sh" "$TARGET" 2>/dev/null; then
      did "symlinked $TARGET -> $HERE/watch.sh"
    else
      warn "couldn't write to $BIN_DIR (try: sudo ln -s $HERE/watch.sh $TARGET)"
    fi
  fi
else
  echo; echo "[5/6] PATH symlink — skipped (--skip-path)"
fi

# 6. Hammerspoon (report only — never overwrite an existing personal config)
if [[ "$SKIP_HAMMERSPOON" -eq 0 ]]; then
  echo; echo "[6/6] Hammerspoon hotkey config"
  HS_CONFIG="$HOME/.hammerspoon/init.lua"
  if [[ -L "$HS_CONFIG" && "$(readlink "$HS_CONFIG")" == "$HERE/hammerspoon/init.lua" ]]; then
    skip "$HS_CONFIG already links to our config"
  elif [[ -f "$HS_CONFIG" ]]; then
    if grep -q "navigator-watch" "$HS_CONFIG" 2>/dev/null; then
      skip "$HS_CONFIG already references navigator-watch"
    else
      warn "$HS_CONFIG already exists — not overwriting. Add this line to it yourself:"
      note "require(\"$HERE/hammerspoon/init\")"
    fi
  elif [[ -e "$HS_CONFIG" || -L "$HS_CONFIG" ]]; then
    # Something's there but isn't a regular file or our symlink (e.g. a
    # broken/dangling symlink from elsewhere) — don't touch it.
    warn "$HS_CONFIG exists (possibly a broken symlink) and isn't ours — not touching it. Add this line to your own config:"
    note "require(\"$HERE/hammerspoon/init\")"
  else
    mkdir -p "$HOME/.hammerspoon"
    if ln -s "$HERE/hammerspoon/init.lua" "$HS_CONFIG" 2>/dev/null; then
      did "symlinked $HS_CONFIG -> $HERE/hammerspoon/init.lua (reload Hammerspoon to pick it up)"
    else
      warn "couldn't create $HS_CONFIG (permissions?). Add this line to your own config:"
      note "require(\"$HERE/hammerspoon/init\")"
    fi
  fi
else
  echo; echo "[6/6] Hammerspoon config — skipped (--skip-hammerspoon)"
fi

echo
echo "Done. Manual steps this script can't do for you:"
echo "  - Install prerequisites if missing: cmux, jq, fswatch, sox/ffmpeg, a whisper transcriber, Hammerspoon (see README)."
echo "  - Grant Hammerspoon Accessibility permission (System Settings > Privacy & Security > Accessibility)."
echo "  - Switch cmux's socket access mode to allowAll in cmux's own Settings UI (needed for speak.sh via Hammerspoon)."
echo "  - Edit the scaffolded coaching.md file(s) with your actual preferences."
echo "  - Verify hooks loaded: run '/hooks' inside a Claude Code session."
