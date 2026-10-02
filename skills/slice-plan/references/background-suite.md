# The background suite run

The full suite runs once per slice, on the slice's final code, **in the working tree itself**,
while the user reviews the slice. The squash changes no code — `reset --soft` plus `commit`
rebuilds the same tree under a new sha — so a run on the pre-squash commit proves the squashed one
too. No executor runs the full suite, and **no executor ever sees this run**: you start it, you
watch it, and you decide when the next slice's code may start (SKILL.md, *Hand off*).

The tree is idle while it runs — the next slice's code is held until the run reads `0` — and that
idleness is what the result rests on:

**While the run is going, nothing outside the plans directory changes.** No code edit, no `git
switch` to a branch with a different tree, no `git restore` or `clean` — by you, an executor, or
the user. The squash, plan writes, the guest's state-file deletion, and cutting the next slice's
branch from the shipped one all leave the code untouched and are fine. Anything else — a fix for a
red run, a change the user asks for — **stops the run first**, and the recipe below restarts it
once the change is committed. Tell the user the tree is in use when you present the slice.

## Starting it

One recipe starts the run, and the same recipe restarts it — after a dead run or a red run's fix.
Each start first stops whatever run is recorded there and deletes its old status, so a stale
result or an orphaned run can never be read as the new one. **Kill only what the pid file proves is
this run** — the recorded pid, and only while its command line is still this directory's `run.sh`;
a dead run's pid can be reused by anything. `run.sh` starts the runner in a process group of its
own and takes that group down with it, so the one `kill` stops everything the run started and
nothing else.

**To stop a run without restarting** — the user asked to, or chose "treat it as red" — run the
recipe's first two lines, then `echo stopped > "<dir>/status"`, so the stop reads as red rather
than as a run that died and wants restarting.

**The run's directory** holds its pid, log and status. It is chosen once, at the
first start: `${XDG_CACHE_HOME:-$HOME/.cache}/slice-suite/<repo-dir-name>-<feature-slug>-<NN>`,
expanded to an absolute path. Record it in the slice's **Suite** field, and from then on copy it
from there. Shell variables do not survive between tool calls, so every start writes the path
literally.

At the boundary's step 3 (SKILL.md), on the slice's branch, from a clean tree — `status --short`
shows nothing outside the plans directory — so the run tests exactly what ships:

```bash
dir="<the run's directory, absolute>"
p=$(cat "$dir/pid" 2>/dev/null) && ps -p "$p" -o args= | grep -qF "$dir/run.sh" && kill "$p"
rm -rf "$dir"; mkdir -p "$dir"
cat > "$dir/run.sh" <<'EOF'
cd "$2" || exit 1
set -m
trap 'kill -- -"$c" 2>/dev/null; exit 143' TERM
( <test runner> ) & c=$!
wait "$c"; s=$?
echo "$s" > "$1/status.tmp" && mv "$1/status.tmp" "$1/status"
EOF
nohup bash "$dir/run.sh" "$dir" "$(git rev-parse --show-toplevel)" > "$dir/log" 2>&1 & echo $! > "$dir/pid"
```

Substitute the Session's `<test runner>` literally — the quoted heredoc passes it through
untouched, quotes included. It runs in `bash`, in its own subshell — `set -m` gives that subshell
its own process group, which the trap kills — so the runner's exit status is the one recorded; where the runner is a pipeline, put `set -o pipefail;` in front. `nohup` keeps
the run alive past this session. After every start, set **Suite** to `running: <dir>`.

**The result is `<dir>/status`**, kept until Cleanup: absent means running (or dead — see below),
`0` means green, anything else means red, with the reason in `<dir>/log`.

## Waiting on it

Read it at every plan write, and **before any of the next slice's code can start**: before
*Running a slice* step 2's earlier-test update, before handing off a slice that waits for it, and
when a paused `atdd` hands back. Slice 01 has no previous run — the planning session's baseline
stands in for it — so nothing waits there.

While the status is absent, check the run is alive and is this run:
`p=$(cat "<dir>/pid"); ps -p "$p" -o args= | grep -qF "<dir>/run.sh"`. If so, tell the
user you are waiting and check again every few minutes — with a scheduled wake-up or background
wait where your harness blocks a foreground `sleep`. If it runs well past what the user expects
the suite to take, show them the tail of `log` and ask: keep waiting, stop it and treat it as red,
or start it again. On a resume, do all of this before anything else in the slice.

- **`0`** — set **Suite** to `green: <dir>`. Then clear the run's leftovers below; the tree is
  free once they are gone.
- **Absent and not alive** — the run died (a reaped background job, a restarted machine). Start
  it again.
- **Anything else** — red. Clear the run's leftovers below first; which section after that
  depends on whether the squash has run.

**Clearing the run's leftovers.** The tree was clean when the run started and nothing else has
changed it since, so anything `git -C "$(git rev-parse --show-toplevel)" status --short` now shows
outside the plans directory is the runner's own output — coverage, reports, caches, rewritten
snapshots. Show it to the user. Output the runner will write every time goes into
`"$(git rev-parse --git-path info/exclude)"`, by pattern; a tracked file the runner rewrote is
restored with `git restore`, and the user should know a run changes tracked files; anything else
is deleted. Do this before any of the next slice's code starts: an executor's `git add -A` would
otherwise commit it. Until the run finishes, leave its output alone — it is still writing.

## Red before the squash

The boundary's step 4 reads the status before squashing, so this is the user still at step 3.
Fix it on this branch, as step 2's review fixes are, commit, start the run again, and tell the user
what changed, since no reviewer saw it. Squash once they approve; the new run is waited on like any
other.

## Red after the squash

This reopens a shipped slice — the one exception to *Feature complete*'s rule against amending
one. The review is spent, but a slice that breaks the suite never met the bar it was approved
against. The next slice's code has not started (you held it), so the reopen is cheap. Every step
below can be re-entered after an interruption; `resume.md` sends a resume here whenever a
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
   `echo 0 > "<dir>/status"`. Set **Suite** to
   `green: fixed — <what>, <dir>` and carry on with the next slice where its hold left it.
