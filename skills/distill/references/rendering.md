# Rendering: ordering and form

Synthesis decides what the brief says. Rendering decides whether the reader can get it without
reading every word.

## Order

**The deliverable opens on the answer.** Always. Not the method, not the scope, not the caveats.
A reader who stops two sentences in should have the conclusion. Everything after it is support
for a point already made, and a layer further down does not restate it.

**Within the lead, order by decision impact** — what the reader must act on soonest, or what most
changes their answer. This is the default and it is right most of the time. The actions layer
orders by dependency instead — what unblocks what — and a reference layer by whatever it is
scanned by, usually name or location.

**Discovery order is the enemy.** It is what the source already used, it requires no thought, and
it is almost never the reader's priority. If your ordering happens to match the order you
encountered things, check whether that is a coincidence.

Other schemes, and when one beats impact ordering:

| Scheme | Use when |
| --- | --- |
| **Impact** *(default)* | The reader is deciding and some findings weigh more than others. |
| **Sequence / time** | The brief describes a process, a chronology, or steps that must happen in order. Ordering these by impact is actively confusing. |
| **Location** | The reader will act file-by-file or service-by-service, so grouping by place saves them the regrouping. |
| **Category** | Items are genuinely parallel and equally weighted, and the reader will look up one of them rather than read all. |
| **Magnitude** | The quantity *is* the finding — slowest, largest, most frequent. |
| **Alphabetical** | A reference layer the reader scans for a known name. Almost never right for a lead or an action list. |

Pick one deliberately and apply it consistently within a level. Mixing schemes inside one list
is why some lists feel unordered even when every item is fine.

## The left-edge test

Readers scan the first two or three words of each line and stop when the scent runs out. So the
**meaning must be at the front** of every heading, bullet, and cell.

| Weak left edge | Strong left edge |
| --- | --- |
| There is a risk that the migration will need a product decision | **Guest checkout needs a product decision** before migrating |
| In `checkout.ts`, the null case is common | **`checkout.ts` — null is the common path**, not an edge case |
| It should be noted that tests are unaffected | **Tests are unaffected** |

Cover the right two-thirds of your draft. If the visible left column still tells the story, the
brief is scannable. If it reads "There is / In the / It should", it is not.

Headings follow the same rule and go further: in any layer the reader reads through they must
be **claims**, not categories — see `synthesis.md`. In a reference layer they are the item's
**name** instead, because that is what the reader is scanning for; the claim moves up to sit
above the layer.

## Choosing a form

| Form | Use when | Fails when |
| --- | --- | --- |
| **Prose** | There is an argument to follow — this, therefore that. | Used for parallel data, where it hides structure. |
| **Table** | Items share the same fields, and the reader compares across them. | Cells hold sentences of differing length, or one column is mostly empty. |
| **List** | Items are genuinely parallel, short, and unordered relative to each other. | Used to shred reasoning — see below. |
| **Code block** | Exact text matters: a command, a path, output to match. | Used for prose the author wanted to look precise. |
| **Single sentence** | The finding is one thing. | Padded into a section to look substantial. |

The most common error is a **table with one useful column**. If two of four columns are "N/A"
or repeat the same value, the table is a list wearing a costume.

The second most common is **prose carrying tabular data** — three paragraphs each describing the
same four attributes of a different item. That is a table.

## Bullets don't hold arguments

A list is a good container for parallel facts and a bad container for reasoning. Shredding an
argument into fragments strips exactly the connective tissue — *therefore*, *but*, *only if* —
that made it an argument. The reader gets true statements and no conclusion.

Symptoms: bullets that are full sentences, bullets that depend on the one above, bullets nested
three deep, a "list" whose items each need their own sub-list.

If the items relate to each other logically, write the paragraph.

## Table discipline

- **Header row says what the column *means*,** not what type it holds.
- **One idea per cell.** A cell containing a semicolon usually wants to be two columns or a
  paragraph.
- **Keep cells short and roughly even.** Tables degrade badly when one cell is a paragraph.
- **Put the column the reader scans first on the left** — usually the name or location.
- **Drop columns that are constant.** State the constant once above the table.

## Choosing the fields for a reference layer

A reference layer is complete over its set of items, which makes **which fields each item
carries** the main design decision — and the one place where adding is as wrong as omitting.

**The resume-cold test.** Pick fields by what someone needs to pick this item up and act on it
with no memory of the survey and no memory of the brief above. That is the whole criterion.

For a set of code surfaces awaiting change, it usually resolves to:

| Field | Why it survives the test |
| --- | --- |
| Where it is | Cannot act without it. |
| What it does | Orients someone who has never opened the file. |
| Why it is in scope | Lets them tell whether it still applies when the plan shifts. |
| What changes | The actual work. |
| What it blocks or depends on | Lets them sequence, and spot the one that has to go first. |

And it usually excludes: how you found it, line counts and other size metrics, the code itself,
timestamps, and confidence scores.

**Same fields for every item.** An empty cell is information — "nothing depends on this" — only
if the column exists everywhere. Ad-hoc per-item notes turn a reference back into prose that
cannot be scanned or compared.

**If some items need fields the others don't, they are different classes.** Split them into two
tables, each under its own claim, rather than one table with half its cells empty.

**Completeness is over items, not over what you know about each item.** Those pull in opposite
directions, and that tension is the design. A reference layer listing all 47 surfaces with five
fields each is right; listing 12 of them with everything you learned is not.

## Emphasis

Bold marks the few words that carry the claim, so a scanner reading only bold gets the spine of
the brief. It stops working the moment it is common: a paragraph with six bold phrases has
none. Italics for a genuine aside. Do not use both at once, and do not bold whole sentences.

## Output medium

Check where the brief is going and render for it.

- **Terminal (the usual case).** Assume a narrow, variable width and no guarantee of color.
  Wide tables wrap into unreadable rubble — keep to about three or four short columns, and use
  a list of short paragraphs when the data needs more. Assume no images.
- **A file the user will open.** More width is available; tables can be richer. Still no
  guarantee anything renders — plain markdown only.
- **A rendered/rich surface.** Follow whatever that surface's own guidance is. Charts,
  dashboards, and visual layout are out of scope for this skill; hand off to a skill that
  covers them.

**References to locations** should be precise enough to act on — file and line where you know
it. If the harness makes such references clickable, use its expected form; otherwise plain
`path:line` is understood everywhere.

## Length

There is no target length, and imposing one produces padding or truncation. The top layers run
as long as the claims that survived selection, and no longer.

A check worth running **when the source is large**: if the lead and actions together come to
more than about a fifth of it, you probably filtered rather than collapsed — go back to
`synthesis.md`. A short source has no such ratio; a four-finding pile legitimately distills to
most of itself.

**The ratio does not apply to a reference layer.** That layer is sized by its item count, and
may legitimately be longer than everything above it. If it is, put it in a sibling file so it
does not bury the lead.
