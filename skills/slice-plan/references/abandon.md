# Abandoning an attempt

Abandon when the strategy itself is wrong for the slice: it keeps throwing its own work away, or
what the slice needs is plainly a different shape of work than the strategy delivers. One failed
attempt at something *inside* a strategy is that strategy's own business. Propose the abandon and
get the user's confirmation before running any of the below.

**First** drain the guest's state file into the plan and remove it with the `git rm -f` in the
block below, so the reversion commit carries the deletion away (`hosted-handoff.md`, *The guest's
state file*, has what to drain and which guests keep theirs). Use a plain `rm` **only** where the
guest never committed at all: the file is then untracked and `git rm` fails with `pathspec … did
not match any files`. The destination for a short drain is the Attempts line you are about to
close — the reason the attempt failed belongs in its `abandoned: <what entangled>` text,
so write it there now rather than carrying it in your head across the restore; anything longer
goes in the Backlog or the Design Hypothesis. **Then** restore the worktree to the previous
slice's branch, remove new files, and commit the reversion the restore stages. Commits on the
current branch stay; the squash at ship collapses them all away.

**Derive `<source dirs>` rather than recalling them.** Run `git -C "$top" status --short` first
and take every untracked path outside the plans directory — a delegated guest is invisible while
it works, so a top-level directory it created is one you never saw appear and will not think to
name. `status --short` prints a mix of files and collapsed directories, so pass the **containing
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
git -C "$top" rm -f -- <plans-dir>/<guest's state file>   # if it kept one and committed it
git -C "$top" restore --source=<previous-slice-branch> --staged --worktree -- . ':(exclude)<plans-dir>/'
git -C "$top" clean -fdn -- <source dirs>   # dry run: read this list before the next line
git -C "$top" clean -fd -- <source dirs>
git -C "$top" diff --cached --quiet || git -C "$top" commit -m "revert abandoned <strategy> attempt"
```

`<previous-slice-branch>` is the branch this slice was cut from — the base branch for slice 01.
The plan is untracked, so `restore` would not touch it either way; the exclusion is there so that
a guest state file you have *not* yet drained is not silently deleted by the restore. Drain first
and the exclusion costs nothing.

Give `<plans-dir>` and `<source dirs>` as repo-root-relative paths and keep the `-C`: pathspecs
follow the working directory, so from a subdirectory the restore either fails loudly —
`error: pathspec '.' did not match any file(s) known to git`, from a subdirectory holding no
tracked files — or is silently partial, from one that does, with the exclusion no longer matching.
The silent case is the one that loses the record, and it is the one you get from `src/`.

`<source dirs>` is whatever that derivation produced — typically directories the strategy wrote
code into, plus any repo-root file named as itself. It is never recalled from memory, never `.`,
never the plans directory, and when it is empty the `clean` does not run at all. A directory the guest created and you did not
name survives the clean, which is how abandoned code reaches the replacement strategy's first
`git add -A`. The exclude means `clean -fd` would spare the plan anyway, but `clean -fdx` does not,
and nothing here needs to touch that directory.

**`clean -fd` also spares ignored build output, by the same design.** The abandoned attempt's
compiled or generated artifacts — `__pycache__/`, `dist/`, `target/`, `.next/` — are still on disk
with their sources gone. Harmless where the toolchain invalidates by source hash, load-bearing
where it caches by path. Check for them after the clean and remove those by name; do not reach for
`-x`, which would take the plan with them.

If the guest had committed at least once, the restore stages the reversion of its code and the
block's last line commits it, so **nothing is staged afterwards** — and the squash at ship
collapses that commit away like the guest's own. Do not leave the reversion sitting in the index
instead: it is the only thing undoing the abandoned attempt's *committed* code, the replacement
guest is told the tree is already clean and to skip the preflight that would notice, and a guest
that tidies what looks like a dirty start discards it — after which the abandoned code ships
inside the squash, never reviewed as part of the slice. If the guest never committed, nothing was
staged and the commit is skipped; that is the expected result, not a failed restore. First-cycle
abandons are the common case, so this is the one you will usually see.

Either way, re-check `git -C "$top" status --short` afterwards: it should print **nothing at all**
outside the plans directory — no `??`, and nothing staged. A leftover `??` path is a directory the
clean missed, not a failed restore — clean it and re-check before going on.

**Then redo the earlier-slice test update** that *Running a slice* step 2 (SKILL.md) made on this
branch. The restore goes back to the previous slice's branch, which is *before* the host committed
that update — so it is gone, and the handoff block promises the next guest it starts green. The
note on the Attempts line you are about to close is the surviving record of what it was. Re-apply
it, get to green, and commit it on this branch.

**Only then**, on the restored tree, write the plan — no commit, it is untracked:

1. **Close the strategy's open Attempts line** in place, setting it to
   `<strategy> — abandoned: <what entangled>`. Do not append a second line and leave the
   `in progress` one standing — a stale open line reads as an attempt still running, and the
   resume path reads the newest line to decide where to re-enter.
2. Set the slice's **Strategy** to the new one and append `<new-strategy> — in progress`. **This
   line is written last, after the redo above**, and that order is load-bearing: it is what the
   resume path (`resume.md`) reads as "the branch is ready for a new strategy, go to
   step 3". Written before the redo, it routes a session that ends in between straight into a
   handoff over the red suite the block promises the guest it will not meet.

Then start the new strategy. Its state file is created fresh.
