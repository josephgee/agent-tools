# Failure modes

Read this as a checklist against a finished draft. Each entry is a named pattern, how to spot
it, and what it costs. Most drafts have three or four.

---

### The Flat Dump

**Tell:** every finding sits at the same level, in the order it was discovered, with no claim
above any of them.

**Cost:** the reader does the analysis. This is the default output of an eager agent and the
single most common reason a report is unusable.

**Fix:** synthesize. Two hundred items are evidence for three or four claims — find them.
See `synthesis.md`.

---

### The Folder Label

**Tell:** headings that name buckets — "Security Findings", "Performance", "Other Issues".

**Cost:** the heading carries no information, so the reader must read the section to learn
whether it matters. Every heading is a wasted opportunity to have already told them.

**Fix:** headings that assert. The test is whether the heading could be *wrong*.

> ✗ **Database Findings**
> ✓ **The connection pool is sized for a single worker**

**Not this:** the rows of a reference layer, where the heading is the item's name and the reader
is scanning for it. The claim belongs above that layer, not on each of its entries.

---

### Effort Narration

**Tell:** sentences describing the search rather than its result. "I examined 14 files", "after
checking the config", "my first hypothesis was", "I then searched for".

**Cost:** spends the reader's attention on work they did not commission, and signals that the
brief is organized around the agent's experience instead of the reader's decision.

**Fix:** delete it. Keep only method that *bounds* the conclusion ("`vendor/` was not
searched"), stated as a limit, in one line, near the end.

---

### Buried Lede

**Tell:** the actual answer appears in the fourth paragraph, or after a table, or in a closing
"so in summary" line.

**Cost:** a reader who stops early — most readers — leaves without the answer, and a reader who
doesn't has to hold four paragraphs of context to recognize the answer when it arrives.

**Fix:** move the last paragraph to the top and delete whatever it made redundant.

---

### Throat-Clearing

**Tell:** the brief opens with "Great question", "Let me walk through what I found", "There are
several things to consider here", or a restatement of the scope.

**Cost:** pure delay, at the position with the most reader attention in the entire document.

**Fix:** open on the claim. The first sentence should be losable only by losing information.

---

### The Echo

**Tell:** the question restated as the opening, or a closing summary that repeats the top.

**Cost:** the same content twice, plus the implication the reader wouldn't have followed it
once. A recap is only useful when the reader has traveled a long way from the opening — a brief
that leads with its answer never has.

**Fix:** delete both. If the closing summary is *better* than the opening, that is the answer —
promote it and delete the original.

---

### Triple Serve

**Tell:** the same fact appears in a paragraph, then in a table, then in a bullet list of
takeaways — all at the same layer, serving the same reader-moment.

**Not this:** a lead that sizes what the reference layer below it enumerates. Those serve
different reader-moments, and the recurrence is the layering doing its job.

**Cost:** the reader spends effort checking whether the second mention says something new. It
usually does not, and the checking is the cost. Well-intentioned reinforcement is still
redundancy.

**Fix:** pick the form that fits the content (see `rendering.md`) and delete the other two.

---

### Bullet Shred

**Tell:** bullets that are full sentences, bullets that only make sense after the one above,
lists nested three deep.

**Cost:** an argument's connective tissue — *therefore*, *but only if*, *which means* — lives in
the joins. Fragmenting it leaves true statements and no conclusion.

**Fix:** if the items depend on each other, write the paragraph. Keep lists for genuinely
parallel, short, independent items.

---

### Hedge Fog

**Tell:** "may", "could potentially", "it appears that", "in some cases" on nearly every claim.

**Cost:** worse than overconfidence. Uniform hedging erases the distinction between the claim
you are sure of and the one you are guessing at, so the reader discounts everything equally.

**Fix:** state the certain things flat; for the uncertain ones say what would settle it. See
`selection.md`.

---

### The Headline Count

**Tell:** the brief leads with a number — "Found 47 usages", "Reviewed 200 lines", "12 issues
identified".

**Cost:** a count measures the search, not the finding, and it frequently misleads: 47 usages
sounds like a big migration right up until you learn 44 are test fixtures.

**Fix:** lead with what the count *means*. Put the number in as support if it still matters.

---

### The Costume Table

**Tell:** a table where one column carries all the content, or two columns are "N/A", or every
cell in a column is identical.

**Cost:** table syntax implies comparison across fields. When there is nothing to compare, the
structure adds visual weight and (in a terminal) wrapping damage for nothing.

**Fix:** a list, or prose. State constant columns once above the table and drop them.

---

### Symmetry Padding

**Tell:** every section is about the same length, and the thin ones are visibly stretched with
restatement or generic advice.

**Cost:** length is a signal of importance. Flattening it hides the ranking that synthesis just
established, and the padding itself is inert text.

**Fix:** let a section be one sentence. If a claim only supports one sentence, that is what it
gets.

---

### Silent Truncation

**Tell:** 190 of 200 findings are gone and the brief does not say so — or says only "additional
findings omitted for brevity".

**Cost:** the reader cannot calibrate. Not knowing what was dropped or why, their only safe move
is to distrust the brief and go read the source, which wastes the whole exercise. **This binds a
reference layer hardest**: one that quietly covers 30 of 47 items has broken the completeness
contract that is its entire reason to exist, and looks complete while doing it.

**Fix:** one line with amount, class, and location. "The other 190 are the same three call
patterns; full list in `survey.md`."

---

### The Relocated Pile

**Tell:** a section labelled as reference material that is the raw source with a heading on top
— fields varying item to item, discovery order preserved, nothing chosen.

**Cost:** it looks like the work was done. A reference layer earns its place by being
*designed*: same fields for every item, picked on the resume-cold test. Relocating the pile
gives the reader the original problem with an extra hop.

**Fix:** choose the schema. See *Choosing the fields for a reference layer* in `rendering.md`.
If you can't say what each field is for, the material belongs in the archive instead.

---

### All Reference, No Lead

**Tell:** a complete, well-organized, genuinely useful document with no top layer — a reader
arriving cold must read the whole thing to learn what it concluded. Design notes, runbooks, and
survey write-ups fail this way constantly.

**Cost:** the completeness is real and the document is not wrong, so nothing signals the defect.
It just costs every reader the same extraction, forever.

**Fix:** add the lead; do not compress what is already there. A reference-shaped document is not
out of scope — it is a deliverable whose top layers were never written.

---

### Arranged Irrelevance

**Tell:** the brief is clean, scannable, well-synthesized — and does not bear on the question
that was asked. Usually happens when the source researched something adjacent.

**Cost:** the most dangerous failure here, because every surface signal says the work is good.
A sprawling document at least lets the reader notice the gap themselves.

**Fix:** say it as the top line — "This doesn't answer whether X; it covers Y" — then brief what
is actually there. Never arrange your way past the gap.

---

### The Ceremony

**Tell:** a framing line, a synthesis pass, a layer split, and an archive pointer, applied to a
source with four findings in it.

**Cost:** this skill exists to respect attention. Spending eight lines of scaffolding on a
four-line answer is the same disrespect in a tidier costume.

**Fix:** when the input is already small and already leads with its answer, say so and stop.
