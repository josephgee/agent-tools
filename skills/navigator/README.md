# navigator (setup, for humans)

`SKILL.md` in this directory is instructions for the *agent* — how it behaves as a hands-off
navigator while you drive. This file is the human-facing setup guide: what to do before and
during a session.

## What this is

Reversed-role pairing. You write every line of code; the agent coaches, questions direction,
catches skipped steps, and keeps a running plan. It never edits your project files.

It's designed to run in a terminal window you keep visible while you work — an IDE terminal pane
alongside your editor. You don't summon it and wait for it; it watches your working tree and
reacts on its own, and you glance over when you feel like it.

## Starting a session

1. `cd` into the project you're working in (not this repo).
2. Launch Claude Code there.
3. Say: *use the navigator skill*.

It will arm the file watcher, ask whether you're resuming a past effort or starting a new one,
and if new, run a short intro conversation (goal, acceptance criteria, initial design hypothesis,
step plan) before you start driving. Then just code — it picks up your changes on its own.

## The watcher

`scripts/wait-for-change.sh` is bundled with the skill and the agent drives it for you. It polls
your git working tree in the background and queues changes; you shouldn't need to touch it.
Prerequisites are `git`, `bash`, and `shasum` (present on stock macOS and virtually every
Linux) — no `fswatch`, no daemons to install. It ships
executable; if your install method strips the exec bit (some archive downloads do), restore it
with `chmod +x scripts/wait-for-change.sh`.

Detections are debounced: the watcher waits for your working tree to hold still (`--idle`,
default 5s) before reporting, so a burst of typing becomes one detection when you pause rather
than one every poll. In practice the agent reacts about 5–10 seconds after your last keystroke.
If that feels sluggish, re-arm with a smaller `--idle` (and `--interval`); if the agent is
reacting to half-written code, raise it.

**If the watcher feels sluggish or pegs a core**, the usual cause is a large file that isn't
gitignored — a dataset, a build artifact, a log. Every poll re-reads untracked files to notice
edits to code you haven't `git add`ed yet, so anything big and untracked gets re-hashed every few
seconds. Gitignoring it fixes it.

If something seems off (the agent has gone quiet, or you want to stop it watching), you can run
it yourself from your project directory:

```bash
<path-to-skill>/scripts/wait-for-change.sh --status   # is a watcher running? anything queued?
<path-to-skill>/scripts/wait-for-change.sh --stop     # shut the watcher down
<path-to-skill>/scripts/wait-for-change.sh --arm      # start it again
```

State lives under `~/.cache/navigator-watch/<hash-of-repo-path>/` (override with
`NAVIGATOR_STATE_DIR`), keyed per repo so several projects can be watched independently. The
agent stops the watcher when an effort completes, which also deletes that repo's saved patch
files; if a session dies unexpectedly, `--stop` cleans up the leftover process. A session killed
without `--stop` can leave patches behind, but any later `--arm` (in any repo) sweeps patches
older than a week — and the whole directory is safe to `rm -rf` whenever nothing is being
watched.

Nothing is lost if the watcher is down for a while — it compares against the last change it
reported, so anything you did while it wasn't running shows up when it's armed again.

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

## Why there is no voice mode

An earlier version of this delivered coaching as hands-free speech (TTS + dictation) into a cmux
pane via Hammerspoon. It is gone — see git history if you want it back. The bet replacing it is
that a terminal pane already in your field of vision does the same job as a spoken notification,
with none of the machinery: no accessibility permissions, no pane resolution, no audio stack. If
voice returns, it should return as an additive layer over a loop that already works silently, not
as a prerequisite for one.
