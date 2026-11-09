# Abandoning an attempt

Abandon when the strategy itself is wrong for the PR: it keeps throwing its own work away, or
what the PR needs is plainly a different shape of work than the strategy delivers. One failed
attempt at something *inside* a strategy is that strategy's own business. Propose the abandon and
get the user's confirmation before running any of the below.

**First** note why the attempt failed: it belongs in the `abandoned: <what entangled>` text you
write last, so draft it now rather than carrying it in your head across the restore; anything
longer goes in the ledger's Backlog. **Then** restore the worktree to the previous PR's branch,
remove new files, and commit the reversion the restore stages. The restore also removes a guest's
committed state file — it does not exist on the previous branch — so the reversion commit carries
it away without your naming it. A state file the guest **never committed** — the usual
first-cycle case — is untracked, so neither the restore nor the clean below touches it: if
`git -C "$top" status --short` lists one in the plans directory, `rm` it by name. Never clean the
plans directory to get it. Commits on the current branch stay; the boundary's squash collapses them
all away.

**Derive `<source dirs>` rather than recalling them.** Run `git -C "$top" status --short` first
and take every untracked path outside the plans directory — a top-level directory a guest created
mid-PR is one you never noticed appear and will not think to name. `status --short` prints a mix of files and collapsed directories, so pass the **containing
directory** of each path it lists, not the paths themselves: a second stray file in a directory
`status` collapsed is otherwise left behind. **If the list comes out empty — the normal case when the executor committed its work — skip the
`clean` entirely.** `git clean -fd --` with nothing after the `--` has no pathspec to limit it and
cleans the whole repo, including untracked files in the plans directory that are nothing to do
with this feature. There is nothing to clean when nothing is untracked; run no command rather
than an unbounded one. **Except for a path at the repo root, where you pass
the path itself** — its containing directory is `.`, and `.` is never a member of `<source dirs>`,
nor is the plans directory: `git clean -fd -- .` deletes every untracked project document in the
plans directory, which is whichever one the repo already had and routinely holds documents nothing
to do with this feature. Then **show the derived list before it executes** — run
`git -C "$top" clean -fdn -- <source dirs>` and read what it would remove; the list is derived, not
recalled, and this is the last point at which a wrong entry is still harmless. Keep `-n` before the
`--`: after it, `-n` is a pathspec and the clean is real. Then:

```bash
top=$(git rev-parse --show-toplevel)
git -C "$top" restore --source=<previous-pr-branch> --staged --worktree -- .
git -C "$top" clean -fdn -- <source dirs>   # dry run: read this list before the next line
git -C "$top" clean -fd -- <source dirs>
git -C "$top" diff --cached --quiet || git -C "$top" commit -m "revert abandoned <strategy> attempt"
```

`<previous-pr-branch>` is the branch this PR was cut from — the base branch for PR 01.
The plan, the ledger and any report are untracked, so `restore` never touches them.

Give `<source dirs>` as repo-root-relative paths and keep the `-C`: pathspecs follow the working
directory, so from a subdirectory the restore either fails loudly — `error: pathspec '.' did not
match any file(s) known to git` — or is silently partial, and the partial case is the one you get
from `src/`.

`<source dirs>` is whatever that derivation produced — typically directories the strategy wrote
code into, plus any repo-root file named as itself. It is never recalled from memory, never `.`,
never the plans directory, and when it is empty the `clean` does not run at all. A directory the guest created and you did not
name survives the clean, which is how abandoned code reaches the replacement strategy's first
`git add -A`.

**`clean -fd` also spares ignored build output, by the same design.** The abandoned attempt's
compiled or generated artifacts — `__pycache__/`, `dist/`, `target/`, `.next/` — are still on disk
with their sources gone. Harmless where the toolchain invalidates by source hash, load-bearing
where it caches by path. Check for them after the clean and remove those by name; do not reach for
`-x`, which would take the plan and ledger with them.

If the guest never committed, nothing was staged and the block's last line commits nothing — the
expected result for a first-cycle abandon, not a failed restore.

Either way, re-check `git -C "$top" status --short` afterwards: it should print **nothing at all**
— no `??`, and nothing staged. A leftover `??` path is a directory the clean missed, not a failed
restore — clean it and re-check before going on.

**Only then**, on the restored tree, write the ledger — no commit, it is untracked:

1. **Close the strategy's open Attempts line** in place, setting it to
   `<strategy> — abandoned: <what entangled>`. Do not append a second line and leave the
   `in progress` one standing — a stale open line reads as an attempt still running, and the
   resume path reads the newest line to decide where to re-enter.
2. Set the PR's **Strategy** to the new one and append `<new-strategy> — in progress`. **This
   line is written last**: the resume path (`resume.md`) reads it as "the branch is ready for a
   new strategy, go to step 3".

Then start the new strategy.
