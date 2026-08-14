# agent-tools

A shared collection of reusable [Agent Skills](https://agentskills.io/specification), meant to be
portable across machines (home and work) and jobs. Each skill is a self-contained, markdown-only
capability package living in its own directory under `skills/`, following the standard `SKILL.md`
format — so the same directory can be used as-is by multiple harnesses
([Claude Code](https://docs.anthropic.com/en/docs/claude-code) and
[pi](https://github.com/badlogic/pi-coding-agent)) without modification.

A skill may bundle its own supporting scripts (see `navigator`), but the repo has no shared
application code, build step, or dependencies of its own.

Design notes for larger efforts live in `docs/designs/`.

## Skills

- **[tdd](skills/tdd/SKILL.md)** — Guides strict Test-Driven Development (TDD) as a learning
  loop, via THINK-RED-GREEN-REFACTOR cycles with a persistent state file for tracking design
  evolution and backlog.
- **[backfill-tests](skills/backfill-tests/SKILL.md)** — Backfills a regression-test net onto
  existing, poorly-tested code by gutting a function and earning each line back under test: comment
  out the whole body, then write one failing test at a time and un-comment the smallest slice of the
  original code that makes it pass. Surfaces bugs as skipped tests to fix at the end. The inverse of
  `tdd`, for code that already exists.
- **[skill-review](skills/skill-review/SKILL.md)** — Reviews agent skills for effectiveness,
  structure, and context management.
- **[list-tools](skills/list-tools/SKILL.md)** — Lists the tools currently available to the
  agent as a compact table grouped by source (builtin, extension, MCP, custom).
- **[list-skills](skills/list-skills/SKILL.md)** — Lists the skills currently available to the
  agent as a compact table grouped by scope (global vs project) and location.
- **[navigator](skills/navigator/SKILL.md)** ([setup guide](skills/navigator/README.md)) —
  Reversed-role pairing for learning an unfamiliar stack: the human drives (writes all the code),
  the agent is a hands-off voice navigator that coaches, questions direction, catches skipped
  steps, and maintains a lean session artifact. Never edits code. Bundles a git-polling file
  watcher (`scripts/wait-for-change.sh`) that the agent drives for you.
- **[grill-me](skills/grill-me/SKILL.md)** — Interviews the user relentlessly about a plan or
  idea, branch by branch, until reaching shared understanding, then summarizes it.

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
# Claude Code, global
ln -s ~/workspace/agent-tools/skills ~/.claude/skills

# pi, global
ln -s ~/workspace/agent-tools/skills ~/.pi/agent/skills
```

### Link one skill at a time (shared/work environments)

If you only want specific skills available, or don't want to hand over the whole directory
wholesale, symlink individual skill directories instead. Replace `tdd` with the skill you want.

```bash
# Claude Code, global
ln -s ~/workspace/agent-tools/skills/tdd ~/.claude/skills/tdd

# pi, global
ln -s ~/workspace/agent-tools/skills/tdd ~/.pi/agent/skills/tdd
```

### Project-scoped installs

To make a skill available only within a specific project (not globally), link into the
project's local skills directory instead of your home directory:

```bash
# Claude Code, project-scoped
mkdir -p .claude/skills
ln -s ~/workspace/agent-tools/skills/tdd .claude/skills/tdd

# pi, project-scoped
mkdir -p .pi/skills
ln -s ~/workspace/agent-tools/skills/tdd .pi/skills/tdd

# pi, project-scoped (harness-agnostic convention)
mkdir -p .agents/skills
ln -s ~/workspace/agent-tools/skills/tdd .agents/skills/tdd
```

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
