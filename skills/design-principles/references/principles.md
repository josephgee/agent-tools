# Design Principles — the *why* behind the smells

The values that name what a smell violates and what a good design preserves. Stated
**neutrally** as concepts; the consumer supplies the posture. Reach for this file when you
need to name *why* something is wrong or *which* option is better — not to run a checklist.

## SOLID

Five principles for where responsibilities and dependencies should sit.

- **Single Responsibility** — a module should have one reason to change. Two unrelated
  reasons to change living in one place is the root of *Divergent Change* and much
  *Rigidity*.
- **Open/Closed** — open for extension, closed for modification. You should be able to add
  behavior without editing code that already works. When a new case forces edits to a
  central conditional, this is what's being violated (*Switch Statements*).
- **Liskov Substitution** — a subtype must be usable anywhere its supertype is, without the
  caller knowing. *Refused Bequest* is a substitution failure made visible.
- **Interface Segregation** — clients shouldn't depend on methods they don't use. A fat
  interface forces consumers to know about things irrelevant to them; splitting it reduces
  *Immobility*.
- **Dependency Inversion** — depend on abstractions, not concretions; high-level policy
  shouldn't depend on low-level detail. Its absence is behind much *Rigidity* and
  *Fragility* — a change low in the stack ripples upward because the arrows point the wrong
  way.

## Beck's four rules of simple design

A design is simple, in priority order, when it:

1. **Passes its tests** — it works.
2. **Reveals intention** — a reader can see what it means without reconstructing it. This
   is the antidote to *Opacity*.
3. **Has no duplication** — one authoritative place for each piece of knowledge (see DRY).
4. **Has the fewest elements** — no class, method, or parameter that isn't earning its
   place. This rules out *Speculative Generality* and *Lazy Class*.

The order matters: never sacrifice clarity (2) to remove duplication (3), and never add
elements for symmetry or a hypothetical future. Consumers may apply this ordering as a
tie-breaker — e.g. when a refactor trades one rule against another, the higher rule wins.

## Pragmatic Programmer values

- **DRY (Don't Repeat Yourself)** — every piece of *knowledge* has a single, authoritative
  representation. DRY is about knowledge, not text: two functions that happen to look alike
  but encode different rules are not a DRY violation, and coupling them would be worse than
  the duplication. This is the principle behind *Duplicate Code* and *Needless Repetition*.
- **Orthogonality** — unrelated things should be independent, so a change to one doesn't
  disturb another. Its absence shows up as *Shotgun Surgery* and *Inappropriate Intimacy*.
- **Reversibility** — prefer decisions that are cheap to undo; avoid baking in an assumption
  that a later change would be expensive to reverse. Closely related to Martin's *Viscosity*
  — a design has poor reversibility when the wrong change is the easy one.
- **Tracer bullets / good-enough** — build the thinnest real end-to-end path and refine it,
  rather than perfecting one component in isolation before anything works together.
