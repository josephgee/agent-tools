# agent-tools

A shared collection of reusable agent tooling, meant to be portable across machines (home and
work) and jobs. It holds two kinds of thing:

- **`skills/`** — [Agent Skills](https://agentskills.io/specification): self-contained,
  markdown-only capability packages. Each skill lives in its own directory and follows the
  standard `SKILL.md` format, so the same directory can be used as-is by multiple harnesses
  (e.g. [pi](https://github.com/badlogic/pi-coding-agent) and
  [Claude Code](https://docs.anthropic.com/en/docs/claude-code)) without modification.
- **`tools/`** — actual scripts/programs for agent-adjacent workflows that can't live inside a
  `SKILL.md` (file watchers, hotkey/voice glue, IPC into a running session, etc.). Each tool has
  its own directory and `README.md`, and may have real dependencies and setup. Tools are not
  required to be harness-agnostic the way skills are.

Design notes for larger efforts live in `docs/designs/`.

## Skills

- **[tdd](skills/tdd/SKILL.md)** — Guides strict Test-Driven Development (TDD) as a learning
  loop, via THINK-RED-GREEN-REFACTOR cycles with a persistent state file for tracking design
  evolution and backlog.
- **[skill-review](skills/skill-review/SKILL.md)** — Reviews agent skills for effectiveness,
  structure, and context management.
- **[list-tools](skills/list-tools/SKILL.md)** — Lists the tools currently available to the
  agent as a compact table grouped by source (builtin, extension, MCP, custom).
- **[list-skills](skills/list-skills/SKILL.md)** — Lists the skills currently available to the
  agent as a compact table grouped by scope (global vs project) and location.
- **[navigator](skills/navigator/SKILL.md)** ([setup guide](skills/navigator/README.md)) —
  Reversed-role pairing for learning an unfamiliar stack: the human drives (writes all the code),
  the agent is a hands-off voice navigator that coaches, questions direction, catches skipped
  steps, and maintains a lean session artifact. Never edits code. Pairs with the
  `navigator-watch` tool.
- **[grill-me](skills/grill-me/SKILL.md)** — Interviews the user relentlessly about a plan or
  idea, branch by branch, until reaching shared understanding, then summarizes it.

## Tools

- **[navigator-watch](tools/navigator-watch/README.md)** — Infrastructure for the `navigator`
  skill: watches your project for file changes and feeds them to the agent, sends your
  hotkey-triggered voice input into a cmux-hosted Claude Code session, and speaks the agent's
  replies aloud via a Claude Code hook — so you can pair by voice while editing in an IDE.
  macOS + cmux + Claude Code. See its README for setup.

## Installing skills

Skills are plain directories — there's no build step or registry. Install a skill by
symlinking it into wherever your harness looks for skills. Symlinks keep the skill in sync
with this repo; pull updates here and every linked location gets them automatically.

Clone this repo somewhere stable first, then link from there:

```bash
git clone <this-repo> ~/workspace/agent-tools
```

### Link everything (personal use)

If you want all skills available everywhere, symlink the whole `skills/` directory:

```bash
# pi, global
ln -s ~/workspace/agent-tools/skills ~/.pi/agent/skills

# Claude Code, global (if your version supports a personal skills directory)
ln -s ~/workspace/agent-tools/skills ~/.claude/skills
```

### Link one skill at a time (shared/work environments)

If you only want specific skills available, or don't want to hand over the whole directory
wholesale, symlink individual skill directories instead. Replace `tdd` with the skill you want.

```bash
# pi, global
ln -s ~/workspace/agent-tools/skills/tdd ~/.pi/agent/skills/tdd

# Claude Code, global (if your version supports a personal skills directory)
ln -s ~/workspace/agent-tools/skills/tdd ~/.claude/skills/tdd
```

### Project-scoped installs

To make a skill available only within a specific project (not globally), link into the
project's local skills directory instead of your home directory:

```bash
# pi, project-scoped
mkdir -p .pi/skills
ln -s ~/workspace/agent-tools/skills/tdd .pi/skills/tdd

# pi, project-scoped (harness-agnostic convention)
mkdir -p .agents/skills
ln -s ~/workspace/agent-tools/skills/tdd .agents/skills/tdd
```

### Note on Claude Code

Depending on your Claude Code version, a personal `~/.claude/skills/` directory may or may not
be picked up — some versions only discover skills bundled inside plugins/marketplaces. If a
plain skills directory isn't recognized, packaging these skills as a minimal Claude Code plugin
is a possible future option, but isn't set up in this repo today.

## Adding a new skill

Create a new directory under `skills/` with a `SKILL.md`:

```
skills/
└── my-skill/
    └── SKILL.md
```

`SKILL.md` needs YAML frontmatter with at least:

```yaml
---
name: my-skill
description: What this skill does and when to use it. Be specific.
---
```

`name` should match the directory name. Everything else — `scripts/`, `references/`,
`assets/` — is optional and freeform; see the existing skills for examples. There's no
manifest or index to update — skills are discovered by directory listing.
