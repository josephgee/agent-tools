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
- Don't add a central manifest or index — skills are discovered by directory listing, and
  any cross-skill dependency info lives in the dependent skill's own `SKILL.md` frontmatter
  (`metadata.soft-deps`, a space-separated list of skill names), never in a shared file. An
  install helper that symlinks skills into a harness is fine, and the repo ships one:
  `install-claude.sh` for Claude Code, which links selected skills into `~/.claude/skills`
  and follows `soft-deps` so an interdependent skill isn't installed half-wired. Keep it a
  single self-contained script — don't grow a shared top-level code directory around it.
  The key's name notwithstanding, a listed dependency may be *hard*: a skill that requires
  another outright states that in its `compatibility` frontmatter and carries no fallback
  instructions for the dependency's absence (e.g. `tdd` and `design-review` both require
  `design-principles`). Don't re-add graceful-degradation branches to such a skill — the
  installer resolves the link, and a hand-copy that omits the dependency is broken by design.

## Writing or editing a skill

- Write the `description` field to be specific about *what* the skill does and *when* to use
  it — this is the only part of the skill always in an agent's context, and it's what decides
  whether the skill gets loaded at all. Vague descriptions ("Helps with X") are a defect.
  Frame it from the model's perspective: what task pattern should trigger loading this skill.
- Write instructions assuming the agent following them has no other context beyond what's in
  the skill. Don't assume knowledge of this repo's other skills or your conversation with the
  user.
- When a step branches into a preferred path and a fallback, make the *preferred* path the
  concrete, prescriptive one (spell out the exact action or command) and explicitly rule out the
  fallback when its condition doesn't hold. Agents under ambiguity reach for whichever branch
  names the most concrete, guarantee-satisfying action regardless of the gating condition — so a
  vague preferred path beside a sharp fallback gets the fallback taken even when it shouldn't be.
  (Seen for real: a "note the git sha, else copy the file" step got the copy done in a clean git
  repo, because copying was the concrete instruction.)
- **A skill that runs for a long session needs its rules somewhere other than its own body.**
  A `SKILL.md` body is read *into the conversation* when the skill triggers, so it lives in the
  compressible region of context — unlike a system prompt or `CLAUDE.md`, which are re-sent every
  turn. Over a long session it is diluted by *position* (attention is U-shaped; a body loaded
  forty turns ago sits in the worst place, and this starts well before the window fills) and then
  *lost* at compaction, replaced by a summary sentence. The symptom is an agent that follows the
  skill's shape while missing its specific steps — TDD-ish work that never proves the test failed
  first. If the skill already keeps a session artifact, that artifact carries *state*; give it a
  short **rules-in-force header** too — the non-negotiable steps only, ~15 lines, written verbatim
  at creation and never edited — and have the skill re-read the artifact at the top of each
  repeating unit (each cycle, pass, or checkpoint), at a fixed point rather than "if unsure".
  It works for two reasons worth keeping visible in the wording: the artifact is on disk, so it
  survives compaction, and re-reading relocates the rules to the *end* of context, the other
  privileged position. Two non-fixes: hoisting the rules into `CLAUDE.md` (durable, but then they
  load in every unrelated session, and that file is the one that can't afford noise), and telling
  the agent to re-invoke the skill (reloads the body, loses the position in the workflow — the
  artifact does both). Keep the header short; a long one re-read every cycle is more of the rot it
  exists to counter. `tdd`, `tdd-batch`, and `navigator` all do this.
- Don't run `skill-review` on your own initiative. It's a deliberate, token-expensive pass the
  user triggers when they judge it worth the cost. If a change looks like it warrants one, say
  so in a sentence and let them decide — then treat its output as a checklist, not just advice.
- Prefer editing existing skills over creating near-duplicate ones. Check `skills/` for existing
  coverage first.

## Non-goals

- Don't add CI, linting, or packaging infrastructure unless a specific need arises.
