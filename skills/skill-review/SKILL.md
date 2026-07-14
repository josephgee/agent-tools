---
name: skill-review
description: Reviews pi agent skills for effectiveness, structure, and context management. Use when evaluating whether a skill will work as intended, is well-organized, and uses context windows effectively.
---

# Skill Review

You review a pi agent skill and produce a structured assessment across three dimensions: **effectiveness**, **structure**, and **context management**.

## Startup

1. Ask the user which skill to review if not specified.
2. List all files in the skill directory with sizes.
3. Read the skill's `SKILL.md` in full.
4. Read all other files in the skill directory. For files over ~200 lines, read the first 50 lines and assess whether the remaining content is instructions the agent follows (read in full) or reference data, boilerplate, or generated content (skim or skip).
5. Read the [skills documentation](skills-reference.md) for specification compliance context.

Only after reading everything, begin the review.

## Review Dimensions

Work through each dimension in order. For each, produce findings and a rating: **good**, **needs work**, or **problematic**. Every finding must reference a specific line, section, or file — no ungrounded claims.

---

### 1. Effectiveness — "Will it work?"

If an agent loads this skill and follows it, will it actually accomplish the task the skill promises? This is not about spec compliance — it's about whether the skill delivers results.

**Evaluate:**

Read every instruction as if you must follow it with no other context. Where would you have to guess? Where could two agents reasonably interpret the same line differently? As you close-read, look for:

- **Decision points.** Where the skill says "if X, do Y" or "choose between A and B", are the criteria for deciding clear and complete? Could an agent confidently pick a path, or would it stall or pick arbitrarily?
- **Unsupported assumptions.** Does the skill assume the agent knows something it wasn't told? Domain knowledge, tool behavior, environment details, conventions from other files?
- **Over-specification.** Does the skill spell out things an agent can reasonably figure out on its own? Explaining what ambiguity means, how to read a file, or what good structure looks like wastes tokens and adds noise. Instructions should supply what the agent *can't* infer — domain context, project conventions, non-obvious constraints — not tutor it on things it already understands.
- **Accuracy of commands and paths.** Do referenced scripts and files exist? Are relative paths correct? Would commands actually run? Don't trust — check.
- **Failure modes.** When the agent hits something unexpected (bad input, missing tool, ambiguous situation), does the skill guide it toward recovery or does it silently derail?
- **Prompt quality.** If the skill includes prompts (for subagent spawning, etc.), are they clear, complete, and likely to produce the intended behavior? Would a subagent receiving this prompt actually do the right thing?
- **Frontmatter.** Is the description specific enough that the agent will load this skill for the right tasks and skip it for the wrong ones? Does the name match the directory?

---

### 2. Structure — "Is it well-built?"

The skill should be organized for clarity, maintainability, and appropriate use of agent capabilities.

**Evaluate:**

- **Document flow.** Does SKILL.md read in a logical order? Can an agent follow it top-to-bottom without needing to jump back to earlier sections? Do later sections build on earlier ones, or do they introduce concepts that should have appeared sooner?
- **Section purpose.** Does each section earn its place? Is it clear what the agent should *do* with each section — follow it as a procedure, use it as a reference, internalize it as a constraint?
- **Emphasis and reinforcement.** Are the most important behaviors and constraints given appropriate weight? Critical instructions buried in a long list get skimmed. Are key points reinforced at the moments the agent will need them (e.g., at decision points, at phase transitions), or only stated once at the top and hoped-for later?
- **File organization.** Is the split between SKILL.md and supporting files sensible? Is anything crammed into one file that should be separated, or split across files unnecessarily?
- **Role separation.** If there are multiple roles (lead/executor, orchestrator/worker), are responsibilities clearly divided? Could one agent accidentally drift into another's scope?
- **Duplication.** Is the same concept explained in multiple places with risk of divergence? DRY applies to skill instructions too.
- **Consistency.** Are terms, formatting, and conventions uniform throughout? Do different sections contradict each other?
- **Orchestration design.** If the skill uses subagents:
  - Is there a clear reason for the orchestration boundary?
  - Are handoff points well-defined (what the subagent receives, what it reports back)?
  - Is the split between orchestrator and worker knowledge appropriate?
  - Could it work without orchestration, and if so, should it?
- **Progressive disclosure.** Does the skill front-load what's needed and defer details to reference files, or does it dump everything into SKILL.md?

---

### 3. Context Management — "Is it context-aware?"

Skills run inside finite context windows. A skill that's correct and well-structured can still fail if it burns context carelessly or creates execution flows where agents lose track.

**Evaluate:**

- **Skill size.** How large is SKILL.md? How large are supporting files? Will loading the skill leave enough room for the actual work? A skill that consumes half the context window before work begins is a problem.
- **On-demand loading.** Does the skill use references/external files that agents load only when needed, or does it force everything into memory at once?
- **Execution flow and context accumulation.** Walk through a realistic execution. How much context accumulates over the course of following the skill? Are there points where the window will be saturated?
- **Subagent context budgets.** If using subagents, does each subagent get a focused, minimal prompt? Or does it inherit bloat from the parent? Is accumulated state passed efficiently (artifact files vs. inline context)?
- **Artifact discipline.** If the skill uses persistent artifacts (state files, logs), does it read/write them at appropriate points? Writing too rarely loses state on context overflow; writing too often wastes cycles.
- **Information density.** Is the instruction text concise, or is it padded with unnecessary explanation, examples, or caveats that consume tokens without adding value? Every token in a skill competes with the user's actual work.
- **Cost implications.** For longer workflows, will the execution pattern result in reasonable token usage? Unnecessary subagent spawns, repeated full-file reads, or bloated prompts all multiply cost.

---

## Output Format

Present the review as:

```
## Skill Review: [skill-name]

### 1. Effectiveness — [rating]

[Findings with specific references]

### 2. Structure — [rating]

[Findings with specific references]

### 3. Context Management — [rating]

[Findings with specific references]

### Summary

[2-3 sentence overall assessment]

### Recommendations

[Ordered list, most impactful first. Each recommendation should be concrete and actionable — not "consider improving X" but "move the API reference from SKILL.md lines 45-120 into a separate reference file loaded on-demand".]
```

## Guidelines

- **Be specific.** Quote lines, name files, reference sections. Vague feedback is useless.
- **Calibrate to purpose.** A simple single-file skill doesn't need orchestration. A complex multi-phase workflow probably does. Judge fitness for purpose, not adherence to a template.
- **Distinguish nitpicks from real issues.** Formatting preferences are not structure problems. An ambiguous decision point is an effectiveness problem.
