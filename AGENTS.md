# agent-tools — Agent Instructions

This repo is a shared collection of reusable [Agent Skills](https://agentskills.io/specification)
under `skills/`: markdown-only, spec-conformant, harness-agnostic. No repo-wide code, no build
step — the content *is* the product.

A skill may bundle its own supporting scripts under its directory when a `SKILL.md` genuinely
can't do the job alone (e.g. `navigator`'s file watcher). Keep such scripts self-contained in
that skill, dependency-light, and documented in the skill's own `README.md` — don't grow them
into a shared top-level code directory.

See `README.md` for what this repo is and how things get installed. This file covers how to work
within it. Design notes for larger efforts live in `docs/designs/`.

## Rules

- Every skill must conform to the [Agent Skills specification](https://agentskills.io/specification)
  — check it directly if unsure about required frontmatter, file layout, or other spec
  details, rather than relying on any paraphrase of it here or elsewhere in this repo.
- One directory per skill under `skills/<skill-name>/`. `SKILL.md` frontmatter's `name` must
  equal the directory name. This is stricter than the spec requires and stricter than any
  harness enforces — it's a policy of this repo, needed because skills are consumed by multiple
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
- Don't run `skill-review` on your own initiative. It's a deliberate, token-expensive pass the
  user triggers when they judge it worth the cost. If a change looks like it warrants one, say
  so in a sentence and let them decide — then treat its output as a checklist, not just advice.
- Prefer editing existing skills over creating near-duplicate ones. Check `skills/` for existing
  coverage first.

## Non-goals

- Don't add CI, linting, or packaging infrastructure unless a specific need arises.
