---
name: distill
description: "Turns a sprawling body of already-gathered material — a research write-up, a codebase survey, log analysis, a multi-file review, any result that reports everything it found — into a layered brief that leads with the answer and respects the reader's attention: a sized lead, the actions to take, and a complete reference layer for whatever gets looked up later. Synthesizes findings into claims instead of merely shortening the pile, demotes whatever cannot change the reader's next decision rather than deleting it, states plainly what moved and where the full detail still lives, and never overwrites the source. Use when the user runs /distill or asks to condense, tighten, restructure, summarize, or 'make this readable', and when a skill needs an existing result reported briefly. Not a research skill — it gathers nothing — and not for charts, dashboards, or visual design."
---

# Distill

A body of material already exists: a research document, a survey of a codebase, a pile of log
findings, or a long answer someone already wrote. It reports **everything that was found**
rather than answering anything. It is flat — every item at the same level of importance — and
ordered by the sequence of discovery. The reader has to do the analysis themselves.

Your job is to write the brief that should have been written, and to do it **without destroying
the material**. The sprawling source is not the failure — it is the archive, and it is what
makes an aggressive cut safe: nothing is deleted, only **demoted**. So what you produce is
rarely one block of prose. A deliverable has **layers** — what the reader reads now, what they
come back to later, and the untouched source underneath — and getting those layers right is most
of the work.

This is a **bar, not a procedure**. The five properties below are what the finished deliverable
must be true of. Meet them however the material makes sensible. A source with four findings in
it already meets most of them — don't manufacture ceremony to prove you ran the process.

## Startup

**1. Resolve the target.** If the user named a file or path, that is the target. Otherwise, if
something in this session wrote a document, that file is the target — name it explicitly in
your first reply so the user can correct you. Only if neither holds, take the most recent
substantial output in the transcript. If two candidates are equally plausible, ask which. If
none of these hold — nothing named, nothing written this session, nothing substantial in the
transcript — say there is nothing to distill yet and ask what to point at.

A transcript-only source has no file to point at, so the remainder line (bar 4) names the
earlier message rather than a path — "the full survey is in the message above" — and the cut is
only as safe as that message stays reachable. When the material is large or the user will want
it later, offer once to write the source out to a file first, then distill the file.

**2. Establish the frame.** The frame is the reader's pending decision, written as one sentence:
*"The reader is deciding whether to X."* Without it, "make this shorter" has no meaning and you
will shorten uniformly, which preserves the shape of the deluge instead of fixing it.

The frame does two jobs. It is the criterion for what leads — and it tells you **how many layers
the deliverable needs**, because it names what the reader does now and what they will come back
for later. See *Layer the deliverable*.

Infer the frame from the request that started the work — it is almost always in the transcript
— and **declare it above the brief**:

```
**Framed for:** whether the auth rewrite can ship this week.
```

That line is a label, not the opening — the answer is still the first sentence of the brief
itself, so bar 1 holds. Drop the label entirely when the brief runs to a sentence or two (see
*When the input is already small*): a framing line over a three-line answer is the ceremony
this skill exists to prevent.

A declared frame that is wrong gets corrected in one message. Do not ask the user to restate a
decision they already stated.

**Ask only when inference genuinely fails**, which means one of exactly three cases:

- The source is inherited — you were pointed at a file and there is no originating request in
  the transcript.
- The originating request had no decision attached to it ("research X", "look into Y").
- The material bears on several decisions whose briefs would actually *diverge* — different
  findings would lead, different ones would be cut.

When you ask, ask with **candidates you drew from the material**: "This covers migration cost,
adoption risk, and current-state accuracy — which are you deciding on?" You have read the pile
and know which frames exist. An open-ended "what are you trying to decide?" pushes the work back
onto the reader and wastes the one advantage you have.

**If a skill invoked you**, it owes you three things: the **target** — a path, or the material
inline; the **frame**, as one decision sentence; and **where the brief goes** — returned in your
response unless the caller named a file. An invocation that hands you a target plus a decision
sentence is this path, not the human one. If the frame is missing, proceed on a stated
inference rather than prompting — there may be no human on the channel.

## Never overwrite the source

The source document justifies the cut. Overwriting it destroys the thing that makes the brief
trustworthy, and there is no way to get it back.

Write the brief into your response by default. Write it as a **sibling file** — same directory,
a distinct name — when the brief is itself a deliverable the user asked for as a file. When a
reference layer is long enough that it would bury the lead, split *that layer* into its own
sibling file instead and keep the lead and actions in your response — the point is to keep what
the reader reads now out of a file they'd have to open. With a transcript-only source there is
nothing to sit beside, so put that file next to the work it describes, or ask where it goes. A
new sibling file is not a rewrite; what is forbidden is editing, truncating, or "cleaning up"
the source in place.

## The bar

A deliverable has **layers** (see *Layer the deliverable*). Items 1 and 4 are tagged for the
deliverable as a whole and 5 for every layer; 2 and 3 carry no tag, because their scope turns on
the layer's contract and the item itself says how.

1. **The answer arrives first.** *(the deliverable)* The reader's first contact is the
   conclusion — not the method, not the scope, not what was searched. A reader who stops after
   two sentences has it. This is about where the deliverable opens, so it is satisfied by the
   lead; an actions or reference layer further down does not restate it.
2. **Every group is a claim where the reader reads through; a lookup label where they scan.**
   In a lead or an actions layer a heading must assert — "Five auth issues" is a filing label,
   "auth fails open when the token is expired" is a finding. In a reference layer the label is
   the item's **name**, because that is what the reader is scanning for, and the claim sits above
   the layer instead. See `references/synthesis.md`.
3. **Every retained item passes decision-relevance — where relevance is the layer's contract.**
   In the lead and the actions layer it could change what the reader does next; interesting-but-
   inert is demoted, and so is expensive-to-find-but-inert. **In a reference layer this inverts**:
   the contract is completeness over the set, so relevance governs which *fields* each item
   carries, not which items appear. See `references/selection.md`.
4. **Nothing disappears silently, at any layer.** *(the deliverable)* Whatever was demoted gets
   one line saying roughly how much, of what class, and where it now lives. This binds a
   reference layer as hard as a lead — a reference layer that quietly covers 30 of 47 items has
   broken its own completeness contract, and the reader has no way to know.
5. **Form matches content, and no fact appears twice *within a layer*.** *(universal)* Table
   when items share fields, prose when there is an argument to follow, list only for genuinely
   parallel short items. Never the same fact in prose and then again in a table and then again
   in a closing summary. Across layers, recurrence is the design: a lead that sizes what the
   reference layer enumerates is the layering working, not duplication.

## The moves

These are the usual route to the bar, not a checklist to march — skip any the material has
already done for you.

**Read the whole source before writing anything.** If you start drafting while still reading,
you anchor on whatever appeared first, and discovery order leaks into the brief. If the source
is too large to hold, read it structurally — headings, section openings, the shape of each part
— and state in the brief which portion you read in full. A silently partial read is a silent
cut wearing a different hat.

**Synthesize — don't filter.** This is the move that does the work. Filtering a pile of two
hundred findings down to the best twelve produces a *shorter pile*: still flat, still unranked,
still leaving the analysis undone. Instead, collapse the two hundred into the three or four
things they are **evidence for**, state those as claims, and demote the instances to support.
If your brief has more than about seven top-level claims, you have not finished collapsing.
See `references/synthesis.md`.

**Don't gather.** If synthesis needs one fact the source summarized away, you may open a file
the source cites. That is not re-research: do not start gathering new material.

**Layer the deliverable.** Decide how many layers the reader needs before you cut anything,
because cutting *is* demotion to a lower layer and you cannot demote without somewhere to demote
to. Each layer gets its own inclusion rule:

| Layer | Read when | Inclusion rule |
| --- | --- | --- |
| **Lead** | Now, deciding whether to engage at all | One claim, sized. "12 surfaces, ~3 days, 4 need decisions first." |
| **Actions** | Now, to do the work | Everything requiring a human move, ordered by what unblocks what. |
| **Reference** | Later, item by item | **Complete** over the relevant set — omission is the defect here, not verbosity. |
| **Archive** | Almost never | The untouched source. |

**The archive is always there and is not counted** — it is the source, sitting where it already
sits. The question is how many layers you *write*. **Two is the common answer**: a lead and an
actions list. Add a reference layer when the reader will come back to work through the material
item by item; that is what turns "here is everything I found" into something they can act from
twice. **Drop the actions layer when nothing requires a human move** — a purely descriptive
frame ("what does this currently do") gives a lead over a reference layer, not an actions layer
padded to look non-empty. Write one layer, a lead alone, only when the material is small.

The reference layer is *designed*, not dumped. It is not the raw source moved to a file — it is
a curated, complete set with a chosen shape. Choosing that shape is the next move.

**Cut against the frame.** Apply decision-relevance to each claim and each piece of supporting
evidence, and demote what fails it rather than deleting it — into the reference layer if the
reader will need it later, into the archive if they will not. Some things are cut every time
regardless of frame, and go straight to the archive: narration of your own process, restatements
of the question, hedging on things you are not actually unsure about, and the closing summary
that repeats the top. See `references/selection.md`.

**Choose the per-item schema** for any reference layer: the same fields for every item, picked
on the **resume-cold test** — what does someone need to pick this item up and act on it with no
memory of the survey? See `references/rendering.md` for the fields that usually survive that
test and the ones that never do.

**Order deliberately, per layer.** The lead answers first, then orders by decision impact — what
the reader must act on soonest or most severely. The actions layer orders by dependency instead:
what unblocks what, so the reader can work straight down it. A reference layer often wants a
different scheme entirely, since it is scanned for a known item rather than read through.
Discovery order is the most common accidental ordering and is almost never right anywhere. See
`references/rendering.md` for the schemes and when each one wins.

**Render to fit the content**, using claim-shaped headings and front-loaded lines so a reader
scanning the left edge picks up the meaning. See `references/rendering.md`.

**Point at the archive.** Say in one line what is in it that isn't in any layer above. "The other
190 hits are the same three call patterns; full list in `<file>`." This is what makes demotion
safe rather than lossy.

## When the material doesn't answer the frame

If the source answered a question adjacent to the one that was asked, say so as the top line —
*"This doesn't answer whether X; it covers Y"* — and then brief what is actually there. The
mismatch is worth more to the reader than a well-arranged non-answer would be. See *Arranged
Irrelevance* in `references/failure-modes.md`.

## When the input is already small

If the source has a handful of findings and already leads with its conclusion, say so and stop.
Meeting the bar may take one reordering and a cut of two paragraphs. Producing a restructured
document, a framing line, and an archive pointer for four bullet points is exactly the disrespect
for attention this skill exists to prevent.

## What to load, and when

Keep this file in context. Load a reference when you hit the move it covers — not up front.

| Load | When |
| --- | --- |
| `references/synthesis.md` | Collapsing many items into claims; a group won't reduce to a claim; unsure how deep the hierarchy should go. |
| `references/selection.md` | Deciding what survives; unsure whether something is decision-relevant; calibrating how much to hedge. |
| `references/rendering.md` | Choosing table vs prose vs list; picking an ordering scheme; deciding which fields a reference layer's items carry; laying out for terminal markdown. |
| `references/failure-modes.md` | Before you finalize — read it as a checklist against the draft. Also when a brief feels wrong and you can't name why. |
