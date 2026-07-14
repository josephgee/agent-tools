# Skills Specification Reference

Quick reference for reviewing skills against the pi/Agent Skills standard.

## Required Structure

- Directory containing `SKILL.md`
- Directory name must match the `name` frontmatter field

## Frontmatter

| Field | Required | Rules |
|-------|----------|-------|
| `name` | Yes | 1-64 chars, lowercase a-z, 0-9, hyphens. No leading/trailing/consecutive hyphens. Must match parent directory. |
| `description` | Yes | Max 1024 chars. Specific enough for the agent to decide when to load the skill. |
| `license` | No | License name or reference. |
| `compatibility` | No | Max 500 chars. Environment requirements. |
| `metadata` | No | Arbitrary key-value mapping. |
| `allowed-tools` | No | Space-delimited tool list (experimental). |
| `disable-model-invocation` | No | When `true`, skill hidden from system prompt. |

## How Skills Are Loaded

1. Agent sees skill name + description in system prompt (always present)
2. Agent uses `read` to load full SKILL.md when task matches (on-demand)
3. Agent follows instructions, loading additional files as referenced

This means:
- **Description** is the only thing always in context — it must be good
- **SKILL.md** is loaded into the working context window — size matters
- **Referenced files** are loaded on-demand — use for detailed/situational content

## Common Issues

- Description too vague → agent doesn't know when to use the skill
- Description too long → wastes system prompt space for all conversations
- SKILL.md too large → consumes working context needed for the task
- Relative paths wrong → agent can't find referenced files
- Name doesn't match directory → validation warning
- Missing description → skill won't load at all
