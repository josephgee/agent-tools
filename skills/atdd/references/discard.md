# Discarding an Experiment

Any of three things triggers this: GREEN's convergence tripwire (three flat runs), a GREEN refactor
step, or a REVIEW fix or lint fix. Uncommitted work is an experiment, and refactors most often
fail. The rule that makes throwing one away cheap: **start every refactor or fix step from a
clean tree** (clean apart from the state file), and commit each step that leaves every previously
passing test passing. The discard then removes exactly one step, never good work beside it.

**Discard when** the tripwire fires, or when any refactor or fix step breaks a test that passed
before it and one repair attempt does not put it right.

```bash
top=$(git rev-parse --show-toplevel)
git -C "$top" restore --source=HEAD --staged --worktree -- . ':(exclude)<state-file>'
git -C "$top" clean -fd -- <source dirs>
```

- `<state-file>` is the repo-root-relative path of the ATDD state file; it is left alone, so
  pressure-log entries and any uncommitted state write survive.
- `<source dirs>` are the repo-root-relative directories holding this slice's implementation and
  tests (for example `src/` and `tests/`). Never the plans directory, and never a directory holding
  a design doc or anything else you meant to keep — `clean -fd` deletes untracked files there
  without asking.
- Keep the `-C "$top"`: pathspecs follow the working directory, so from a subdirectory the discard
  is silently partial and the state-file exclusion stops matching.

Then append one line to the pressure log saying what entangled — it is the only trace the
experiment leaves — and resume. After the tripwire, drop to the ladder: pick one failing test,
make it pass, run, commit, repeat. After a failed refactor or fix, retry it in smaller steps once;
if that fails too, note it in the state file and move on.
