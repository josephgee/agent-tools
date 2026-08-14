#!/usr/bin/env bash
#
# install-claude.sh — link skills from this repo into Claude Code's skills dir.
#
# Skills are plain directories; installing one means symlinking it to where the
# harness looks. This helper does that for Claude Code (~/.claude/skills by
# default). It links one skill at a time — so the target can already hold skills
# from elsewhere — and it pulls along each skill's soft dependencies, declared in
# that skill's own SKILL.md frontmatter (metadata.soft-deps), so an interdependent
# skill (e.g. design-review, which consults design-principles) isn't installed
# half-wired.
#
# It never clobbers: an existing real directory, or a symlink pointing somewhere
# else, is reported and skipped. Re-running is safe (idempotent).
#
# Usage:
#   ./install-claude.sh                        # link all skills
#   ./install-claude.sh tdd design-review      # link those (+ their soft-deps)
#   ./install-claude.sh --list                 # list available skills, then exit
#   ./install-claude.sh --dry-run tdd          # show what would happen, change nothing
#   ./install-claude.sh --no-deps design-review   # link only what's named, skip soft-deps
#   ./install-claude.sh --target DIR ...       # link into DIR instead of ~/.claude/skills
#
# The target can also be set with CLAUDE_SKILLS_DIR. A relative --target/env value
# is resolved against the current directory (handy for project-scoped .claude/skills).

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills_dir="$repo_root/skills"
target="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
dry_run=0
with_deps=1
requested=()

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# Print the leading comment block (minus the shebang), stripping the "# " prefix, so
# --help tracks the header automatically instead of hard-coded line numbers.
usage() { awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "${BASH_SOURCE[0]}"; }

# Space-separated soft-deps declared in a skill's SKILL.md frontmatter, or nothing.
soft_deps() {
  local f="$skills_dir/$1/SKILL.md"
  [ -f "$f" ] || return 0
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { exit }
    infm && /^[[:space:]]*soft-deps:[[:space:]]*/ {
      sub(/^[[:space:]]*soft-deps:[[:space:]]*/, ""); print; exit
    }
  ' "$f"
}

list_skills() {
  local d
  for d in "$skills_dir"/*/; do
    [ -f "$d/SKILL.md" ] && basename "$d"
  done
}

# --- parse args ---
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)    usage; exit 0 ;;
    --list)       list_skills; exit 0 ;;
    --dry-run)    dry_run=1 ;;
    --no-deps)    with_deps=0 ;;
    --target)     shift; [ $# -gt 0 ] || die "--target needs a directory"; target="$1" ;;
    --target=*)   target="${1#--target=}" ;;
    -*)           die "unknown option: $1" ;;
    *)            requested+=("$1") ;;
  esac
  shift
done

[ -d "$skills_dir" ] || die "no skills/ directory at $skills_dir"

# No skills named → all of them.
if [ "${#requested[@]}" -eq 0 ]; then
  while IFS= read -r s; do requested+=("$s"); done < <(list_skills)
fi
[ "${#requested[@]}" -gt 0 ] || die "no skills found under $skills_dir"

# Resolve the full set (requested + transitive soft-deps), preserving discovery order.
# Dedup via a space-delimited string set rather than an associative array, so this runs on
# bash 3.2 (macOS's system bash) as well as 4+.
seen=" "
resolved=()
queue=("${requested[@]}")
while [ "${#queue[@]}" -gt 0 ]; do
  name="${queue[0]}"; queue=("${queue[@]:1}")
  case "$seen" in *" $name "*) continue ;; esac
  [ -d "$skills_dir/$name" ] || die "no such skill: $name (try --list)"
  seen="$seen$name "
  resolved+=("$name")
  if [ "$with_deps" -eq 1 ]; then
    for dep in $(soft_deps "$name"); do queue+=("$dep"); done
  fi
done

# --- link ---
if [ "$dry_run" -eq 0 ]; then
  mkdir -p "$target"
fi
# Absolute target so the summary and env/relative --target read cleanly.
target="$(cd "$target" 2>/dev/null && pwd || printf '%s' "$target")"

linked=0 already=0 conflict=0
for name in "${resolved[@]}"; do
  src="$skills_dir/$name"
  dest="$target/$name"
  added=""
  # Mark deps that weren't explicitly requested, so the summary is honest.
  case " ${requested[*]} " in *" $name "*) : ;; *) added=" (soft-dep)";; esac

  # Canonicalize both sides so an already-correct link is recognized regardless of how
  # either path is spelled (symlinked repo path, relative --target, ./ vs realpath). This
  # is what keeps re-runs idempotent rather than flagging a spurious conflict.
  src_real="$(cd "$src" && pwd -P)"
  if [ -L "$dest" ]; then
    dest_real="$(cd "$dest" 2>/dev/null && pwd -P || true)"
    if [ "$dest_real" = "$src_real" ]; then
      printf '  ok    %s%s — already linked\n' "$name" "$added"; already=$((already+1)); continue
    fi
    printf '  skip  %s%s — symlink points elsewhere (%s)\n' "$name" "$added" "$(readlink "$dest")"
    conflict=$((conflict+1)); continue
  elif [ -e "$dest" ]; then
    printf '  skip  %s%s — a real path already exists there\n' "$name" "$added"
    conflict=$((conflict+1)); continue
  fi

  if [ "$dry_run" -eq 1 ]; then
    printf '  would %s%s -> %s\n' "$name" "$added" "$src"
  else
    ln -s "$src" "$dest"
    printf '  link  %s%s -> %s\n' "$name" "$added" "$src"
  fi
  linked=$((linked+1))
done

printf '\n%s into %s\n' \
  "$([ "$dry_run" -eq 1 ] && echo 'Dry run' || echo 'Done')" "$target"
printf 'linked: %d   already: %d   skipped(conflict): %d\n' "$linked" "$already" "$conflict"
[ "$conflict" -gt 0 ] && printf 'Resolve conflicts by hand — nothing existing was overwritten.\n'
exit 0
