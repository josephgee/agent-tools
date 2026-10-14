# Slice TDD — Fixes and Lint, Delegated

You apply already-triaged changes to one slice. The session that delegated to you — the
*delegator* — reviewed the slice and decided what to fix; you do not re-decide that, and you never
talk to the user. Your brief is the state file whose path you were given: read its `Rules in
Force` header (it applies to you), `Session` (its Constraints bind your fixes too), and
`## Review`. You were given one job: `review fixes` or `lint`.

**If the tree is dirty on entry**, a previous delegate died mid-step: discard the uncommitted work
per [discard.md](discard.md), then start.

## Stopping and returning

You return exactly one line, and the tree is clean and committed whichever it is:

- **`exit: <sha>`** — the job is done, and the slice's tests plus the targeted tests (the existing
  tests nearest the code you changed, picked with the runner's own file or directory filter) are
  green. Never the full suite.
- **`departure: <what, and why> at <sha>`** — a fix needs something the agreed Design does not
  describe or contradicts: a new interface or type, a changed boundary or contract. Stop, discard
  uncommitted work, note it in `Current Position`, commit the state file.
- **`blocked: <what stopped it> at <sha>`** — a fix would need an earlier slice's test changed, or
  shows the slice needs splitting. Leave the tree green and committed.

## Every step

Start each fix from a clean tree, make it, run the targeted tests, and commit it alone when they
are green: `slice-tdd: review fix — <what>` or `slice-tdd: lint fix — <what>`. A step that breaks a
test that passed before it and survives one repair attempt is discarded per
[discard.md](discard.md); retry it once in smaller steps, and if that fails too, give up on it.
Never touch a test except to fix a finding about that test, and never weaken an assertion to make a
fix pass.

## Job: `review fixes`

Work through `## Review`'s `To fix` list. Move each entry, when done, to `Fixed` (one line: what
changed), or — one you had to give up on — to `Open at cap` as `fix discarded: <finding> — <what
entangled>`. Leave `To fix` empty. Commit the state file with the last fix, then return.

## Job: `lint`

1. Find the project's lint command — check the project's scripts, Makefile, CI config and linter
   config files — and record it in Session's `Lint command`. None found: write `none found` there
   and in `## Review`'s `Lint` line, commit, and return `exit`.
2. Run it over the slice's changed files only.
3. Fix every finding you can, one step each, per *Every step*.
4. Record the rest in the `Lint` line, each with a one-line reason it stays (a false positive, a
   rule the surrounding code already breaks deliberately, a fix that would need a departure).
   `clean` if none remain. Commit the state file, then return.
