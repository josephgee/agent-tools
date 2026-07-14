---
name: list-skills
description: "Produces a compact, at-a-glance inventory of every agent skill available in the current session, grouped by scope (global vs project) and location, with a one-line description each. Use when the user asks what skills you have, to list/audit skills, or where a skill is installed from — not for evaluating the quality of a specific skill (see skill-review) or for loading a skill to use it."
---

# List Skills

Inventory every skill visible to you right now and present it as one small table, grouped by scope. The goal is a reader scanning the result in five seconds — a directory listing with descriptions, not a summary of what each skill teaches.

Do not read any skill's full `SKILL.md` body for this — you only need the frontmatter (`name`, `description`) and its filesystem location. Reading full skill content wastes context and isn't needed to answer "what skills are available."

## Steps

1. **Identify the harness** you're running in (pi, Claude Code, other) from environment clues — which config directories exist (`~/.pi`, `~/.claude`), how the session was launched, etc. If unsure, check both sets of locations below rather than guessing wrong.

2. **Enumerate skill locations for that harness**, in this order, noting each scope with its icon:

   | Icon | Scope |
   |------|-------|
   | 🌐 | `global` |
   | 📁 | `project` |
   | 📦 | `package` |
   | ⌨️ | `cli` |
   | 🧩 | `plugin` |

   **pi:**
   - 🌐 `global`: `~/.pi/agent/skills/`, `~/.agents/skills/`
   - 📁 `project`: `.pi/skills/`, `.agents/skills/` — check the current directory and walk up through ancestors to the git repo root (or filesystem root if not in a repo)
   - Also note (without necessarily enumerating fully) any package-provided skills (`pi.skills` in `package.json`, 📦 `package`) or skills added via `settings.json`/`--skill` (⌨️ `cli`) if you have evidence of them — use those scopes rather than guessing global vs project

   **Claude Code:**
   - 🌐 `global`: `~/.claude/skills/`
   - 📁 `project`: `.claude/skills/` in the current directory and ancestors
   - 🧩 `plugin`: marketplace/plugin-provided skills — note their presence if visible, but it's fine to use this scope without fully resolving their origin

   If you're unsure which harness you're in, check both sets of paths.

3. **For each location, list the skill directories it contains** (or root-level `.md` files where the harness allows that — pi allows this in `~/.pi/agent/skills/` and `.pi/skills/`, but not in `.agents/skills/` variants). For each, read only the YAML frontmatter of `SKILL.md` — `name` and `description` — not the rest of the file.

4. **Note symlinks when relevant.** Shared skill collections (like this repo) are typically installed via symlink. Scope is determined by *where the link lives* (global vs project skills dir), not by the symlink's target — but if the target path is informative (e.g. points at a shared repo clone), you may mention it in the location column.

5. **Flag name collisions.** If the same skill `name` appears in more than one location (e.g. both global and project), list both rows and note the collision — don't silently pick one or guess which wins.

6. **Render one markdown table**, skills grouped by scope (global first, then project, then other), with the Scope column showing the icon plus the word (icon alone is ambiguous to a screen reader or a renderer that drops emoji):

   ```markdown
   | Skill | Scope | Location | Description |
   |-------|-------|----------|--------------|
   | tdd | 🌐 global | ~/.pi/agent/skills/tdd | Strict TDD via THINK-RED-GREEN-REFACTOR cycles |
   | skill-review | 🌐 global | ~/.pi/agent/skills/skill-review | Reviews skills for effectiveness and structure |
   | api-conventions | 📁 project | .pi/skills/api-conventions | House rules for this repo's REST API layer |
   ```

   Truncate each description to roughly 12 words — enough to know what it's for, not the full frontmatter text.

7. Respond with just the table — no preamble describing which locations you checked or what you found before it, no per-skill prose, no re-listing in another format afterward, no summary after it. If something notable needs flagging (a collision, a location you couldn't fully enumerate), add it as a single short line *after* the table, not before.
