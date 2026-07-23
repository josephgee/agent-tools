# navigator (setup, for humans)

`SKILL.md` in this directory is instructions for the *agent* — how it behaves as a hands-off
navigator while you drive. This file is the human-facing setup guide: what to do before and
during a session.

See also: [`tools/navigator-watch`](../../tools/navigator-watch/README.md) for the voice/file
-watch infrastructure this skill is normally paired with (optional — the skill works fine in a
plain chat too, just without hands-free voice or automatic file-change updates). If you're using
that tool, its [`setup.sh`](../../tools/navigator-watch/setup.sh) can do most of the steps below
for you — including the coaching-file scaffolding — idempotently; ask your coding agent to run it.

## Starting a session

Load the `navigator` skill in Claude Code (or whatever harness you're using) and start talking.
It will ask whether you're resuming a past effort or starting a new one, and if new, run a short
intro conversation (goal, acceptance criteria, initial design hypothesis, step plan) before you
start driving.

## Setting up coaching directives (optional)

Coaching directives are standing instructions **you write** to shape how the navigator coaches —
e.g. "push me on async, I'm weak there," "don't re-explain language basics," "ask before giving
an answer." The agent reads these; it never writes into them. Full details and a template:
[`references/coaching-directives.md`](references/coaching-directives.md). Quickstart:

**1. (One-time, recommended) Make project-local directive files invisible to git everywhere**,
so you never have to touch a project's own `.gitignore`, even in public repos:

```bash
git config --global core.excludesFile ~/.config/git/ignore
mkdir -p ~/.config/git
echo '.navigator/' >> ~/.config/git/ignore
```

**2. Global directives** (apply to every navigator effort on this machine):

```bash
mkdir -p ~/.claude/navigator
$EDITOR ~/.claude/navigator/coaching.md
```

**3. Project-local directives** (specific to one repo/stack — run from that repo's root):

```bash
mkdir -p .navigator
$EDITOR .navigator/coaching.md
```

Both are optional; without either, the agent coaches with its own judgment. If both exist,
project-local augments/overrides global. See the template in
[`references/coaching-directives.md`](references/coaching-directives.md) for the sections to
fill in (coach me toward / don't bother / interaction style / stack notes).

## Where the session artifact lives

You generally don't need to touch this — the agent maintains it — but if you're curious or want
to inspect/edit it directly: `~/.claude/projects/<project>/memory/navigator/<slug>/session.md`
(plus a sibling `history.md`). See [`references/artifact-format.md`](references/artifact-format.md)
for the full structure. It's outside your project repo, so nothing to gitignore there.
