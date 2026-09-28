# The background suite run

The full suite runs once per slice, on the slice's final code, in a detached checkout of the
slice's branch, while the user reviews the slice. The squash changes no code — `reset --soft`
plus `commit` rebuilds the same tree under a new sha — so a run on the pre-squash commit proves
the squashed one too. No executor runs the full suite, and **no executor ever sees this run**:
you start it, you watch it, and you decide when the next slice's code may start (SKILL.md, *Hand
off*).

## Starting it

One recipe starts the run, and the same recipe restarts it — after a dead run, a setup fix, or a
red run's fix. Each start first stops whatever run is recorded there and deletes its old status,
so a stale result or an orphaned run can never be read as the new one.

**The run's directory** is chosen once, at the first start:
`${XDG_CACHE_HOME:-$HOME/.cache}/slice-suite/<repo-dir-name>-<feature-slug>-<NN>`, expanded to an
absolute path. Record it in the slice's **Suite** field, and from then on copy it from there.
Shell variables do not survive between tool calls, so every start writes the path literally.

At the boundary's step 3 (SKILL.md), from a clean tree — `status --short` shows nothing outside
the plans directory — so the checkout holds exactly what ships:

```bash
dir="<the run's directory, absolute>"
top=$(git rev-parse --show-toplevel)
[ -f "$dir/pid" ] && kill "$(cat "$dir/pid")" 2>/dev/null
git -C "$top" worktree remove --force "$dir/tree" 2>/dev/null; rm -rf "$dir"; git -C "$top" worktree prune
mkdir -p "$dir" && git -C "$top" worktree add --detach "$dir/tree" <slice-branch>
cat > "$dir/run.sh" <<'EOF'
cd "$1/tree" || { echo setup-failed > "$1/status"; exit 1; }
if ! ( <suite setup> ); then s=setup-failed; else ( <test runner> ); s=$?; fi
echo "$s" > "$1/status.tmp" && mv "$1/status.tmp" "$1/status"
EOF
nohup bash "$dir/run.sh" "$dir" > "$dir/log" 2>&1 & echo $! > "$dir/pid"
```

Substitute the Session's `<test runner>` and `<suite setup>` literally — the quoted heredoc
passes them through untouched, quotes included — using `true` for a setup of `none`. Both run in
`bash`, each in its own subshell, so the runner's exit status is the one recorded; where the
runner is a pipeline, put `set -o pipefail;` in front. `<slice-branch>` is the slice's branch by
name: before the squash it is the reviewed code, after it the same tree, after a reopen's fix the
fixed one. A plan with no `Suite setup` field predates it: ask the user what a fresh checkout
needs and record the answer in the Session first. The checkout lives outside the repo, so it
never shows in the worktree's `status`; `nohup` keeps the run alive past this session. After
every start, set **Suite** to `running: <dir>`.

**The result is `<dir>/status`**, kept until Cleanup: absent means running (or dead — see below),
`0` means green, `setup-failed` means the checkout never got as far as the tests, anything else
means red, with the reason in `<dir>/log`.

## Waiting on it

Read it at every plan write, and **before any of the next slice's code can start**: before
*Running a slice* step 2's earlier-test update, before handing off a slice that waits for it, and
when a paused `atdd` hands back. Slice 01 has no previous run — the planning session's baseline
stands in for it — so nothing waits there.

While the status is absent, check the run is alive and is this run:
`p=$(cat "<dir>/pid"); kill -0 "$p" && ps -p "$p" -o args= | grep -q run.sh`. If so, tell the
user you are waiting and check again every few minutes — with a scheduled wake-up or background
wait where your harness blocks a foreground `sleep`. If it runs well past what the user expects
the suite to take, show them the tail of `log` and ask: keep waiting, stop it and treat it as red,
or start it again. On a resume, do all of this before anything else in the slice.

- **`0`** — set **Suite** to `green: <dir>` and remove the checkout alone, keeping `status` and
  `log`: `git -C "$(git rev-parse --show-toplevel)" worktree remove --force "<dir>/tree"`.
- **Absent and not alive** — the run died (a reaped background job, a restarted machine). Start
  it again.
- **`setup-failed`** — the checkout, not the slice. Set **Suite** to `setup-failed: <dir>`, read
  `log`, fix the Session's `Suite setup` with the user, and start it again. Not a reopen.
- **Anything else** — red. Which branch below depends on whether the squash has run.

## Red before the squash

The boundary's step 4 reads the status before squashing, so this is the user still at step 3.
Fix it on this branch, as step 2's review fixes are, commit, start the run again, and tell the
user what changed, since no reviewer saw it. Squash once they approve; the new run is waited on
like any other.

## Red after the squash

This reopens a shipped slice — the one exception to *Feature complete*'s rule against amending
one. The review is spent, but a slice that breaks the suite never met the bar it was approved
against. The next slice's code has not started (you held it), so the reopen is cheap. Every step
below can be re-entered after an interruption; SKILL.md's *Startup* sends a resume here whenever a
shipped slice's **Suite** reads `red:`. Set `top=$(git rev-parse --show-toplevel)` in the same
call as each command below.

1. Set the shipped slice's **Suite** to `red: <failing tests>, <dir>`. If the next slice's
   branch is cut, confirm it holds no code:
   `git -C "$top" diff --stat <shipped-branch> <next-slice-branch> -- . ':(exclude)<plans-dir>/'`
   prints nothing. If it prints anything, stop and show the user — this recipe assumes none.
2. Show the user the failure and the fix you propose. On approval, with the repo clean, switch
   to the shipped branch, make the fix **uncommitted**, and run the full suite in the foreground
   until it is green. Then fold it into the shipped commit:
   `git -C "$top" add -A && git -C "$top" commit --amend --no-edit`. On a resume, a dirty tree on
   the shipped branch means this step is unfinished; a clean one means it is done.
3. If the next slice's branch is cut and `git -C "$top" merge-base --is-ancestor <shipped-branch>
   <next-slice-branch>` fails, carry it over:

   ```bash
   git -C "$top" rebase --fork-point --onto <shipped-branch> <shipped-branch> <next-slice-branch>
   ```

   `--fork-point` finds where the next slice left the shipped branch from the reflog, however many
   amends came since, so no sha is carried between calls. The rebase moves the next slice's
   non-code commits — a guest's state-file commits — onto the fixed slice and leaves you on the
   next slice's branch.
4. The foreground run proved the fix, so record it as the result rather than running it twice:
   `echo 0 > "<dir>/status"` and remove the checkout as for any `0`. Set **Suite** to
   `green: fixed — <what>, <dir>` and carry on with the next slice where its hold left it.
