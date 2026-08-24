# distill: turning a deluge into a brief

**What was decided.** `distill` is a standalone, explicitly-invoked skill that turns
already-gathered material into a **layered** deliverable. Four decisions carry the design:
synthesis rather than filtering is the core move; it runs at composition time on material that
already exists, never ambiently; the reader's pending decision is the loss function, inferred
and declared rather than elicited; and the output is layered — lead, actions, reference, archive
— each layer carrying its own inclusion rule. Everything below is why.

## Problem

An agent asked to research something behaves like an eager helper: it gathers hard, then reports
**everything it found**. The result is complete, expensive to produce, and unreadable — a flat
pile at one level of importance, ordered by discovery, with the answer somewhere in the middle.
The reader has to do the analysis the agent was asked to do.

Nothing in `skills/` addresses this. `list-skills` and `list-tools` each hand-roll the same
instinct — "a reader scanning the result in five seconds" — inline, for their own narrow output.
That instinct is worth generalizing.

## Synthesis is the core move, and it runs downstream

Two framings were tried and rejected.

**Selection is not the center of gravity.** Picking the best twelve of two hundred findings
yields a *shorter deluge* — still flat, still unranked, still leaving the analysis to the reader,
and now arbitrary-looking on top. The move that works is **abstraction**: collapse the two
hundred into the four things they are evidence for, state those as claims, demote the instances.
Two hundred to four is not a 94% cut, it is a change of altitude. Selection is real but
secondary, operating on the surviving claims rather than on the raw pile.

**Selection is downstream of gathering, not upstream.** "Don't gather what you won't use"
describes a research-scoping skill, which is a different problem. Here the pile already exists
and the tokens are already spent; `distill` fires at **composition time**.

That second point shapes everything: **the sprawling document is not the failure, it is the
archive**. Already materialized on disk, it is what makes an aggressive cut safe — nothing is
lost, because everything demoted still sits in a file the brief points at. It is the *bottom* of
a graded stack, not the other half of a brief/archive pair.

The argument is only as strong as that file. A **transcript-only source** has nothing durable to
point at, so the remainder line names a message instead of a path. The skill offers, once, to
write the source out first when the material is large — but this remains a real weak spot rather
than a solved case: the archive argument degrades to a promise about scrollback.

## Invocation: explicit, never ambient

Ambient firing — before the agent writes its report — was rejected for three reasons:

1. **The trigger fails in the wrong direction.** A description keyed on composing ("when writing
   a summary") does not fire, because an agent about to dump everything does not experience
   itself as about to write badly. Self-assessment is the worst possible trigger condition.
2. **It contradicts repo norms.** `design-review`, `skill-review`, and `code-review` are all
   deliberate passes; `AGENTS.md` states outright that `skill-review` must not self-trigger.
3. **Ambient mode loses the archive.** With no prior document, writing the detail layer out
   means producing a large file at the moment the agent most wants to be finished. It gets
   skipped, and the cut stops being safe.

Two entry points, mirroring `design-review`:

- **Human-invoked** — `/distill`, or a request to condense, restructure, or tighten a result.
- **Skill-invoked** — a caller passes **target, frame, and destination**. Target and frame alone
  leave the destination undefined.

The accepted cost is that the bad document gets generated and read back in. Ambient mode does
not avoid that cost — it holds the same pile in context instead of on disk, and pays a worse
trigger for the privilege.

### Never overwrite the source

The load-bearing rule. The source justifies the cut; overwriting it destroys what makes the
brief trustworthy. `distill` writes a new file or a response and links back. A *new* sibling
file is not a rewrite; editing the source in place is.

## The frame is the loss function

"Make this shorter" has no criterion, and an agent without one shortens *uniformly*, preserving
the shape of the deluge. The criterion is the reader's pending decision: **would knowing this
change what they do next?** It does two jobs — decides what leads, and decides **how many layers
the deliverable needs**, since naming what the reader does now versus later is the same act as
naming the layers.

Establishing a frame is mandatory. **Asking** for it is not: it is usually recoverable from the
request that started the research, and asking the user to restate what they already said is
friction the skill bans elsewhere. So: **infer it and declare it** — cost zero when right, one
message when wrong, against a round trip every time for always-asking. The declaration is a
**label above the brief, not its opening sentence**, since a brief that opens by announcing its
framing has not led with the answer; it is dropped entirely when the brief runs to a sentence or
two.

`distill` asks only where inference genuinely fails, not merely where it is uncertain: an
inherited source, a request with no decision attached, or material spanning decisions whose
briefs would actually diverge. It asks with **candidates drawn from the material** — it has read
the pile, so an open-ended "what are you trying to decide?" wastes its one advantage.

**The frame is also what makes mismatch detectable.** A restructuring pass fails
characteristically by producing *beautifully arranged irrelevance* — a crisp brief of material
that answers an adjacent question. Without a frame there is nothing for the material to fail to
match. When framing reveals the gap, saying so is the deliverable.

## One deliverable, several reader-moments

An earlier framing treated document **genre** as the dividing line — decision-support for
`distill`, reference material for some other skill. A concrete case broke it: "find every code
surface this project has to touch" produces one deliverable serving four reader-moments at once
— how big is this, what do I act on, what do I look up later, what stays in the pile.

So the layers sit **inside** one deliverable:

| Layer | Read when | Inclusion rule |
| ----- | --------- | -------------- |
| **Lead** | Now, deciding whether to engage | One claim, sized. |
| **Actions** | Now, to do the work | Everything requiring a human move, ordered by what unblocks what. |
| **Reference** | Later, item by item | **Complete** over the relevant set — omission is the defect. |
| **Archive** | Almost never | The untouched source. |

Each layer also orders differently: the lead by decision impact, the actions layer by dependency
— what unblocks what — and a reference layer by whatever it is scanned by, usually name or
location. Ordering is a per-layer choice for the same reason inclusion is.

**The archive is never counted** — it is the source, sitting where it already sits. The question
is how many layers you *write*, and two is the common answer. A reference layer is added when
the reader will work through the material item by item. Only one layer gets written when the
material is small, or when the frame is purely descriptive ("what does this currently do") and
nothing requires a human move — a lead with no actions layer beneath it, rather than an actions
layer padded to look non-empty.

Two consequences. **The bar's properties do not all share one scope** — some hold for the
deliverable, some turn on a given layer's contract, and those invert in a reference layer where
completeness rather than relevance is the point (see *Shape*). And **cutting means demoting** —
to the reference layer when the reader will want it later, to the archive when not.

This settles whether `distill` was over-fitted to research and needed a genre-general sibling
holding the neutral material in `rendering.md` and `failure-modes.md`. It did not. A document
that looks like reference material is a deliverable whose top layers were never written; the fix
is to add them, not to route it elsewhere. No second skill, no extraction.

### The reference layer is designed, not dumped

Complete over its **items**, which makes the real decision *which fields each item carries* — the
one place in the skill where adding is as wrong as omitting. The rule is the **resume-cold
test**: pick fields by what someone needs to pick the item up and act with no memory of the
survey and no memory of the brief above. For code surfaces that lands on where it is, what it
does, why it is in scope, what changes, and what it blocks; it excludes how it was found, size
metrics, and the code itself.

Completeness is over items, not over what you know about each item. Those pull against each
other, and that tension is the design.

## Shape: a bar, not a procedure

Same reshaping `backfill-tests` went through. A pipeline gets marched through mechanically on a
three-item result set, producing ceremony where none was needed. A bar states what the finished
output must be true of, and is trivially met when the input is already small.

The five: the answer arrives first; groups are claims where the reader reads through and lookup
labels where they scan; retained items pass decision-relevance where relevance is the layer's
contract; nothing disappears silently at any layer; and form matches content, with no fact twice
within a layer.

Their scopes differ, and an earlier two-value tag scheme — *(top layers)* against *(every
layer)* — got three of the five wrong. Two are deliverable-level (answer-first, silent-cuts),
two turn on the layer's contract (claim-vs-label, relevance-vs-completeness), and one is
universal; a notation with two values cannot express three distinctions. Its worst error was
scoping stated-cuts to the top layers, which **legalized silent truncation inside a reference
layer** — the exact failure that layer exists to prevent.

The replacement notation is deliberately uneven: the three items whose scope is fixed carry a
tag (*the deliverable*, *the deliverable*, *universal*), and the two whose scope turns on the
layer's contract carry **none**, saying how inside the item instead. A tag on those two would
have to name a condition rather than a place, which is what broke the old scheme. `SKILL.md`
holds the authoritative wording.

## Architecture

```
skills/distill/
  SKILL.md              — target + frame resolution, the layer-scoped bar, the moves
  references/
    synthesis.md        — grouping and abstraction; claim-vs-category; a worked collapse
    selection.md        — decision relevance, the always-cut list, calibration
    rendering.md        — form selection, ordering, scent, per-item schema, markdown constraints
    failure-modes.md    — named anti-patterns with tells and fixes
```

Thin-router `SKILL.md` over on-demand references, following `design-principles`. **Standalone**:
no `soft-deps`, no hard dependency. The lens/consumer split that justifies `design-principles`
requires two consumers sharing a catalog; there is one consumer here, and splitting would buy
nothing but installer wiring.

`failure-modes.md` carries the most practical weight — named anti-patterns with concrete tells
change behavior; abstract principles largely do not.

## Non-goals

- **Not a research skill.** It may open a file the source cites when synthesis needs a fact the
  source summarized away; it does not gather.
- **Not charts or visual design.** Those are separate concerns with their own skills in most
  harnesses. `distill` stays on prose, structure, and terminal markdown.
- **Not a general prose-style skill.** Sentence-level craft appears only where it serves
  scannability, not as an editing pass.
- **Not applicable to code output.** Source files are not briefs.

## Sources

Weighted toward the deluge scenario rather than general information design:

- **Minto, *The Pyramid Principle*** — grouping, abstraction, answer-first. Backbone of synthesis.
- **Heuer, *Psychology of Intelligence Analysis*** — more material raises confidence without
  raising accuracy. Why a deluge is actively harmful, not merely long.
- **Grice; Sperber & Wilson, *Relevance Theory*** — relevance as effect over effort, which the
  decision-relevance test operationalizes.
- **Pirolli & Card, information foraging; NN/g scanning** — information scent, hence front-loading.
- **Horn, *Information Mapping*** — labeled chunks by type; heading and table discipline.
- **Wurman's LATCH** — the menu of ordering schemes.
- **Tufte, "The Cognitive Style of PowerPoint"** — against shredding reasoning into fragments.
- **Sweller, cognitive load theory** — the redundancy effect.

Deliberately **not** cited: Miller's 7±2 (Cowan's ~4 supersedes it, and neither governs list
length), "users read only 20% of words" (a 1997 extrapolation, over-quoted), and Strunk & White
beyond "omit needless words".

## Status

Built: `skills/distill/` — `SKILL.md` plus the four references above.

Not built, noted for later:

- **A caller.** No skill currently invokes `distill`. The skill-invoked contract exists because a
  research or review skill is the natural second caller; until one exists, only the human path
  is exercised.
