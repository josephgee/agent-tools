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

## Law of Demeter

A unit should talk only to its immediate collaborators — its own fields, its parameters, and
objects it created — never to objects reached *through* another object. Violations read as
*train wrecks* (`a.getB().getC().getD()`), which is what *Message Chains* detects; the deeper
cost is that the caller now depends on a structure it doesn't own, so a change two objects
away breaks it. Also the principle behind *Inappropriate Intimacy*.

## Component principles

SOLID governs classes. These govern the next level up — which classes belong in a component,
and which way dependencies between components should point. Martin's rot symptoms are usually
the *effects* of violations here, not of class-level ones.

**Cohesion — what belongs together**

- **REP (Reuse/Release Equivalence)** — the granule of reuse is the granule of release. Things
  reused together must be releasable together, under a version someone can depend on.
- **CCP (Common Closure)** — classes that change for the same reasons, at the same times,
  belong in one component. This is *Single Responsibility* restated at component scale, and
  its violation is *Shotgun Surgery* at component scale.
- **CRP (Common Reuse)** — classes not reused together shouldn't be grouped together.
  Depending on a component means depending on *everything* in it: you inherit its transitive
  dependencies and get redeployed when parts you never used change. This is *Interface
  Segregation* restated at component scale.

These three pull against each other. REP and CCP are inclusive — they grow components. CRP is
exclusive — it shrinks them. Over-weighting REP and CCP forces users through releases they
don't need; over-weighting CRP scatters one reason-to-change across many components. The
balance also shifts with a project's age: early on, CCP (developability) dominates; later, CRP
and REP (reusability) matter more. There is no fixed right answer — naming which of the three
is being traded away is the useful move.

**Coupling — which way the arrows point**

- **ADP (Acyclic Dependencies)** — the component dependency graph must have no cycles. A cycle
  means neither component can be built, tested, or released without the other, and the pair is
  one component in practice whatever the directory layout says.
- **SDP (Stable Dependencies)** — depend in the direction of stability. A component with many
  dependents is hard to change; it must not depend on something volatile, or that volatility
  propagates upward into everything.
- **SAP (Stable Abstractions)** — a component should be as abstract as it is stable. Stable and
  concrete is the bad quadrant (Martin's *zone of pain*): everything depends on it and nothing
  can extend it without modifying it. Database schemas and shared utility packages land there
  most often.

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
