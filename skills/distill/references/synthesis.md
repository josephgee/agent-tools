# Synthesis: collapsing a pile into claims

Synthesis is the move that does the work. Everything else in `distill` arranges or trims what
synthesis produces.

## Cutting is not collapsing

Reducing two hundred findings to the best twelve produces a **shorter pile**. It has the same
defects as the original — flat, unranked, ordered by discovery, analysis left to the reader —
and it adds a new one: the twelve look arbitrary, because the reader cannot see why those
twelve. You have thrown away information and gained no clarity.

Collapsing two hundred findings to four **claims** is a change of altitude. The four are not a
subset of the two hundred; they are statements the two hundred are *evidence for*. Nothing is
discarded — the instances become support, and the bulk of them move down a layer: into the
reference layer if the reader will work through them later, into the archive if they will not.

If your output is a shorter version of the input's list, you filtered. Go back up an altitude.

## The claim-vs-category test

Every group you form must reduce to a sentence that **asserts something**. Apply the test to
every heading **in a layer the reader reads through** — the lead and the actions. (A reference
layer is the exception, and it is a real one: see *Headings in a reference layer* below.)

| Category (bad) | Claim (good) |
| --- | --- |
| Authentication issues | Auth fails open when the token is expired |
| Performance findings | Three N+1 queries account for most of the p99 latency |
| Files using the old API | The remaining old-API usage is almost entirely in test fixtures |
| Miscellaneous | *(delete it — see below)* |

A category names a folder the items were put in. A claim tells the reader something they did
not know and could act on. If you cannot write the claim, you have not found the group's
meaning yet — regroup rather than shipping the folder label.

The mechanical test: can the heading be **wrong**? "Authentication issues" cannot be wrong; it
is a bucket. "Auth fails open when the token is expired" can be wrong, which is what makes it
worth reading.

### Headings in a reference layer

A reference layer is arrived at, not read through. The reader already knows which item they
want and is scanning for its **name**, so there the heading *is* the name — a path, a service, a
surface. Replacing it with an assertion makes the layer unscannable, which defeats the thing the
layer is for.

The claim still has a place: it goes on the layer as a whole, above the items. "The remaining
old-API usage is almost entirely in test fixtures" is the claim; the 47 named rows beneath it
are the reference.

## Group by implication, not by provenance

The default grouping an agent reaches for is the one the material arrived in: by file, by
directory, by tool call, by which search turned it up, by severity label, by type. These are
all **provenance** groupings — they describe how the material was found, not what it means.

Group instead by **what the items jointly imply about the reader's decision**. Findings from
six unrelated files belong together if they are the same problem. Two findings in the same file
belong apart if one blocks the decision and the other is cosmetic.

Provenance groupings are not useless — they are often the right structure for the *archive*, and
sometimes for a reference layer the reader scans by location. They are just not the structure of
a lead.

## Writing the claim

- **Subject, verb, object.** A real assertion, not a noun phrase.
- **Say the thing, not that there is a thing.** "Three call sites pass a nullable id the new
  API rejects", not "there are issues with nullable ids".
- **Put the consequence in it where you know it.** "…which means migration is a rename, not a
  redesign" earns its length; "…which may have implications" does not.
- **No hedging you don't mean.** See `selection.md` on calibration.

## Keep climbing until the "so what" runs out

Write the claim, then ask *so what?* If the answer is another sentence the reader needs, that
sentence is the real claim and yours was support. Repeat until *so what* returns something the
reader already knows or does not care about.

> 47 files import `legacy_client`.
> *So what?* → The migration is broader than the ticket estimated.
> *So what?* → 44 of the 47 are test fixtures, so the estimate is roughly right for production.
> *So what?* → nothing further. **That is the claim.**

Notice the last step changed the answer, not just the wording. Climbing often reverses the
impression the raw count gives, which is precisely why the raw count was a bad thing to lead
with.

## Depth and breadth

- **Top level: aim for three to five claims, and treat more than about seven as unfinished
  collapsing.** This is not a memory limit, it is a synthesis check — a pile that still has
  twelve top-level points has groups that share a parent nobody has named yet.
- **Two levels is usually enough**: claim, then its evidence. A third level means the second
  level is doing categorization work and should be collapsed, or moved down into the reference
  layer or the archive.
- **Groups should not overlap.** If an item belongs under two claims, either the claims are
  facets of one larger claim, or the item is support for one and merely illustrative for the
  other — pick one and don't repeat it.

## How much evidence to keep under a claim

Enough to make the claim **checkable**, not enough to prove it exhaustively. Usually that is:

- The strongest instance, named concretely with a location.
- The count of the rest, with their class.
- Anything that is an exception to the claim — exceptions are load-bearing and must survive.

> **Three production call sites pass a nullable id the new API rejects.**
> The worst is [`checkout.ts:88`](src/checkout.ts:88), where the null path is the common case
> for guest users. The other two are in admin tooling. The remaining 44 usages are test
> fixtures and migrate mechanically.

Three lines carry what forty rows of a table did.

## A worked collapse

**Input** — 200 rows of a survey, one per usage site:

```
src/checkout.ts:88   getUser(id)        id may be null
src/admin/list.ts:14 getUser(id)        id may be null
tests/fixtures/a.ts:3  getUser("u1")
tests/fixtures/b.ts:9  getUser("u2")
... 196 more
```

**Filtering** would give you twenty of these rows and a sentence saying there are 180 more.
The reader still has to work out what it means.

**Collapsing** gives:

> **Framed for:** whether the `getUser` migration can be done mechanically.
>
> **It is mechanical everywhere except three call sites.** 197 of the 200 usages pass a
> non-null literal or a checked id and convert with a rename.
>
> **The three exceptions pass a nullable id, which the new API rejects.** These need a product
> decision about guest users, not a code change — [`checkout.ts:88`](src/checkout.ts:88) is the
> one that matters, since null is the *common* case there. The other two are admin tooling.
>
> The three are enumerated below — where each is, what it passes, what needs deciding. The
> other 197 are the mechanical rename; the per-site list stays in `survey.md`.

Two hundred rows to two claims and one decision, with the three that need work demoted to a
reference layer and the 197 that don't left in the archive. The reader now knows what to do.

## When items genuinely don't group

Sometimes a few findings really are unrelated one-offs. Do not invent a claim to house them,
and do not create a "Miscellaneous" or "Other findings" heading — that is a category admitting
it is a category.

Either they pass decision-relevance individually, in which case each gets one line at the
bottom stated as its own small claim, or they do not, in which case they belong in the reference
layer if the reader will look them up later and in the archive, with a one-line pointer, if not.
Usually it is the archive.
