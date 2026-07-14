---
name: list-tools
description: "Produces a compact, at-a-glance inventory of the tools currently available to the agent, grouped by source (builtin, extension/plugin, MCP server, custom/SDK) with a one-line purpose for each. Use when the user asks what tools you have, to list/audit your tools, or where a tool came from — not for explaining how to use one specific tool (read its own description instead)."
---

# List Tools

Inventory every tool currently available to you and present it as one small table, grouped by where each tool comes from. The goal is a reader scanning the result in five seconds, not a reproduction of each tool's full description.

## Steps

1. **Enumerate every tool you currently have**, including ones you have never called in this session. Use only tools actually available to you right now — do not include tools you merely know how to describe from training but that aren't present in your current tool list.
2. **Classify each tool's source.** Use naming conventions and known harness conventions; when genuinely unsure, label it `unknown` rather than guessing:
   - **builtin** — ships with the harness itself. For pi: `read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`. For Claude Code: `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Glob`, `WebFetch`, `WebSearch`, `Task`, `TodoWrite`, `NotebookEdit`, and similar core tools.
   - **mcp** — name is prefixed like `mcp__<server>__<tool>` (Claude Code) or otherwise clearly routed through an MCP server. The server name is part of the source, e.g. `mcp:github`.
   - **extension / plugin** — registered by a harness extension, plugin, or package rather than the harness core or an MCP server. If the extension/plugin name isn't derivable from the tool name or description, use `extension (unknown)`.
   - **sdk / custom** — passed in directly by the host application embedding the agent (e.g. pi's `customTools`), distinct from a discoverable extension.
3. **Determine scope only when it's actually inferable** — e.g. an MCP server defined in a project-local config file vs a global one. If you can't tell, write `n/a` rather than guessing global vs project.
4. **Summarize the purpose in your own words, ≤10 words.** Do not paste the tool's full description or parameter list.
5. **Render one markdown table**, tools grouped by source (sort or blank-line-separate groups so provenance is visually scannable):

   ```markdown
   | Tool | Source | Scope | Purpose |
   |------|--------|-------|---------|
   | read | builtin | n/a | Read file contents |
   | bash | builtin | n/a | Run shell commands |
   | mcp__github__create_issue | mcp:github | project (.mcp.json) | Create a GitHub issue |
   | deploy_preview | extension (unknown) | n/a | Deploy a preview environment |
   ```

6. **If a tool is disabled/excluded in the current session** (e.g. via `--tools`/`--exclude-tools` on pi) but you can tell it's configured, you may note it in a short "excluded" line below the table — don't fabricate this if you have no evidence either way.
7. Respond with just the table — no preamble describing what you checked or found before it, no per-tool prose, no repeating the table in a different format afterward. If something notable needs flagging (e.g. a tool you couldn't classify, an excluded tool), add it as a single short line *after* the table, not before.
