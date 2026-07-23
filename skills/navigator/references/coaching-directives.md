# Coaching directives

Standing instructions the human authors to shape how the navigator coaches them. Distinct from
the session artifact: directives are *input* (how I want to be coached); the artifact is *state*
the agent maintains (where this effort stands). The agent reads directives; it does not write
coaching content into them.

## Two scopes

- **Global** — `~/.claude/navigator/coaching.md`. How you like to be coached across every effort
  on this machine. Lives outside any repo, so no gitignore concern.
- **Project-local** — `<repo-root>/.navigator/coaching.md`. Directives specific to this repo or
  stack. Project-local augments/overrides global on conflict.

Both are optional. With neither present, the agent coaches with its normal judgment.

## One-time gitignore setup (for project-local directives)

So `.navigator/` never needs a per-repo `.gitignore` edit (and can't be accidentally committed,
even in public repos), ignore it once globally via git's `core.excludesFile`:

```bash
# Point git at a global ignore file (skip if you already have one configured).
git config --global core.excludesFile ~/.config/git/ignore
mkdir -p ~/.config/git

# Ignore the navigator dir in every repo on this machine.
echo '.navigator/' >> ~/.config/git/ignore
```

After this, a `.navigator/coaching.md` in any project is invisible to git without touching that
project's tracked `.gitignore`.

## Template

Both files use the same freeform structure. Keep them short and concrete — they're read every
session, so they compete with working context.

```markdown
# Navigator coaching directives

## Coach me toward
- <e.g. "push me on async/await; I default to callbacks and want to break the habit">
- <e.g. "make me write type signatures by hand before running the type checker">

## Don't bother
- <e.g. "no need to re-explain language basics or syntax I already know">
- <e.g. "skip praise; get to the substance">

## Interaction style
- <e.g. "ask a leading question before giving the answer">
- <e.g. "keep spoken replies to two sentences unless I ask for more">

## Stack notes
- <e.g. "this project uses Effect-TS; hold me to its idioms, not vanilla Promises">
```

Nothing here is required — delete sections that don't apply. The agent folds whatever is present
into how it coaches, treating these as always-on constraints second only to the never-write-code
rule.
