# agent-tools — Agent Instructions

This repo is a shared collection of reusable agent tooling in two forms:

- **`skills/`** — [Agent Skills](https://agentskills.io/specification): markdown-only, spec
  -conformant, harness-agnostic. No code, no build step — the content *is* the product.
- **`tools/`** — actual scripts/programs for things a `SKILL.md` can't do (file watchers,
  hotkey/voice glue, IPC into a running session). Each tool owns its directory and `README.md`,
  may have real dependencies, and is not required to be harness-agnostic.

See `README.md` for what this repo is and how things get installed. This file covers how to work
within it. Design notes for larger efforts live in `docs/designs/`.

The rules below are about **skills** unless stated otherwise. For **tools**: keep each one
self-contained in its directory with a `README.md` that covers setup and dependencies; don't add
repo-wide build/CI/packaging infrastructure for them (see Non-goals).

## Rules

- Every skill must conform to the [Agent Skills specification](https://agentskills.io/specification)
  — check it directly if unsure about required frontmatter, file layout, or other spec
  details, rather than relying on any paraphrase of it here or elsewhere in this repo.
- One directory per skill under `skills/<skill-name>/`. `SKILL.md` frontmatter's `name` must
  equal the directory name. This is stricter than the spec requires and stricter than pi
  enforces — it's a policy of this repo, needed because skills are consumed by multiple
  harnesses via symlinks of the bare directory name (see `README.md`).
- Keep `SKILL.md` lean. Move detailed reference material into `references/`, loaded on-demand
  — don't inline everything just because it's convenient while writing.
- Don't add a manifest, index, or install script (see `README.md` for why).

## Writing or editing a skill

- Write the `description` field to be specific about *what* the skill does and *when* to use
  it — this is the only part of the skill always in an agent's context, and it's what decides
  whether the skill gets loaded at all. Vague descriptions ("Helps with X") are a defect.
  Frame it from the model's perspective: what task pattern should trigger loading this skill.
- Write instructions assuming the agent following them has no other context beyond what's in
  the skill. Don't assume knowledge of this repo's other skills or your conversation with the
  user.
- After drafting or materially changing a skill, review it with the `skill-review` skill
  (`skills/skill-review/SKILL.md`) before considering the work done — it checks effectiveness,
  structure, and context management. Treat its output as a checklist, not just advice.
- Prefer editing existing skills over creating near-duplicate ones. Check `skills/` for existing
  coverage first.

## Non-goals

- Don't add CI, linting, or packaging infrastructure unless a specific need arises.
