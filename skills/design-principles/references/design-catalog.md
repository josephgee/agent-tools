# Design Catalog — Smells, Heuristics, and Rot Symptoms

A vocabulary for naming design pressure, drawn from Fowler's catalog of code smells, Martin's
*Clean Code* heuristics, the component principles, and Martin's symptoms of design rot. Each
entry states the concept **neutrally** — what the thing *is* — not what to do about it. The
posture (are you detecting these in existing code, or weighing them against design options?)
is supplied by whoever loaded this file.

Naming a smell is the point of consulting this catalog. A name is not a mandate to fix
anything — it is a precise handle for a real force, so a decision about it can be made on
its own merits rather than on a vague sense of unease.

A few entries carry a `designing note:` — a hint for the *generative* reader, where the
forward application ("what would tripping this look like in a design I haven't built yet?")
isn't obvious from the detection-flavored description. Most entries don't need one.

**Altitudes.** The sections sit at different structural levels — names and statements,
functions, classes, components, whole system. A problem is usually best named at the level it
actually lives at, and a symptom at one level often has its cause a level up.

The file is **not** ordered by that ladder. Fowler's smells come first because they are the
most-reached-for section and because later sections build on their entries. In altitude order
the sections are:

| Altitude | Section |
| --- | --- |
| names, comments, statements | Martin's Clean Code heuristics |
| functions | When a unit feels too big |
| classes and methods | Fowler's Design Smells |
| components | Component-level smells |
| whole system | Martin's Symptoms of Design Rot |

The ladder is not complete: nothing here yet names the architecture/boundary level (ports and
adapters, the dependency rule). That is a known gap, not an omission to work around.

## Fowler's Design Smells

**Bloaters** — something has grown past the point where it's still easy to work with.
- *Long Method* — a method doing enough that you can't summarize it in one sentence.
- *Large Class* — a class accumulating fields and methods that don't all relate to the same responsibility.
- *Primitive Obsession* — using raw strings/ints/booleans for concepts that deserve their own type (money, an email address, a status). *designing note:* an option that threads bare primitives through many signatures is choosing this smell up front; a small value type is the alternative being weighed against it.
- *Long Parameter List* — enough parameters that callers can't easily get the order or meaning right.
- *Data Clumps* — the same group of values (e.g. `start`, `end`, `timezone`) always traveling together as separate parameters instead of one type.

**Object-Orientation Abusers** — OO mechanisms used in ways that fight the paradigm.
- *Switch Statements* (or long if/elif chains) — the same conditional on type/kind repeated in multiple places; usually resolved with polymorphism.
- *Temporary Field* — a field only meaningful in some circumstances, null or unused otherwise.
- *Refused Bequest* — a subclass that overrides most of what it inherits, signaling the hierarchy is wrong.
- *Alternative Classes with Different Interfaces* — two classes doing the same job with differently named methods, blocking substitution.

**Change Preventers** — one change ripples further than it should.
- *Divergent Change* — one class changes for many unrelated reasons (a form of low cohesion).
- *Shotgun Surgery* — one change requires small edits scattered across many classes (the inverse of Divergent Change — logic that should be together is spread out).
- *Parallel Inheritance Hierarchies* — every time you add a subclass in one hierarchy, you must add a matching subclass in another.

**Dispensables** — something that shouldn't exist at all.
- *Duplicate Code* — same logic in more than one place.
- *Lazy Class* — a class that no longer does enough to justify its own existence.
- *Data Class* — a class with only fields and getters/setters, no behavior — logic that should live with the data lives elsewhere instead.
- *Dead Code* — unreachable or unused code.
- *Speculative Generality* — abstraction built for a future that hasn't arrived (hooks, parameters, or layers with no current caller). *designing note:* the most common way a design option over-reaches — prefer the option that solves the problem actually in front of you, and add the generality when a second caller makes it real.

**Couplers** — excessive coupling between classes or modules.
- *Feature Envy* — a method more interested in another object's data than its own; it probably belongs on that other object.
- *Inappropriate Intimacy* — two classes reaching into each other's internals rather than communicating through a clean interface.
- *Message Chains* — `a.getB().getC().getD()` — a client navigating deep into an object graph it shouldn't need to know about.
- *Middle Man* — a class whose methods mostly just delegate to another class, adding no value of its own.

## When a unit feels too big

*Long Method*, *Large Class*, and dense branching are **entry points, not verdicts**. Size is
what makes you look; it is never itself the finding. What you are looking *for* is a nameable
cause — and if none of the lenses below fires, the unit is fine as it stands. Leaving it alone
is a real outcome, not a skipped step.

The lenses, in no fixed order:

- **Comprehension cost** — how hard must a reader work to reconstruct what this does? This is
  what *Long Method* already encodes ("can't summarize it in one sentence"), and what
  *Opacity* names at system scale.
- **Mixed abstraction levels** — does one unit interleave high-level policy with low-level
  detail (a business rule sitting beside byte-shuffling)? A function should descend only one
  level of abstraction below its own name; where it doesn't, the lower level usually wants
  extracting. (Martin's *Stepdown Rule*.)
- **Missing abstraction** — is a concept the code clearly *has* never given a name of its own,
  so it gets re-derived inline everywhere it's needed? *Primitive Obsession* and *Data Clumps*
  are its two most common concrete forms; the general case is broader than either.
- **Single responsibility** — does the unit have more than one reason to change? See
  [principles.md](principles.md).
- **Branching density** — this one is a *measurement*, not a smell: high cyclomatic complexity
  is a reason to look harder, never a finding on its own. The finding, when there is one, is
  one of the other lenses — most often a missing abstraction, or a type/kind conditional that
  wants polymorphism (*Switch Statements*).

**This list is not exhaustive.** It is the set written down so far. A unit that troubles an
experienced reader while none of these lenses names why is a gap in this catalog, not a clean
bill of health — say so plainly in that case, rather than forcing a match to the nearest smell
that half-fits or declaring the code fine.

*Editing note:* this lens list is mirrored by consumers that must degrade without this skill —
`design-review` carries a copy in its fallback path. Change it here first, then update the
mirrors.

## Martin's Clean Code heuristics

A lower altitude than Fowler's smells: where those are class- and method-shaped, these sit at
the level of individual **functions, names, and comments**. Selected from *Clean Code* ch. 17;
the full list there is considerably longer and much of it restates Fowler.

The function-size rules from that chapter are deliberately **not** reproduced here. See "When a
unit feels too big" above, which carries what they were proxying for.

**Comments** — the governing idea is that a comment is compensation for code that failed to say
it itself. That makes a comment a place to look, not automatically a defect.
- *Redundant comment* — restates what the code already says; a name or an extracted function would have carried it. The real finding is usually the unclear code beneath it.
- *Commented-out code* — dead code that version control already remembers.
- *Journal comment* — a change log accumulating at the top of a file, duplicating history.
- *Misleading comment* — no longer matches the code it describes. Worse than no comment.
- Comments that do earn their place: intent behind a non-obvious decision, a warning of consequences, a legal notice, an amplification of something a reader would otherwise dismiss as trivial.

**Names**
- *Obscured Intent* — a name or expression that hides its meaning rather than revealing it.
- *Name at the wrong abstraction level* — exposes implementation where the caller only cares about the concept.
- *Magic number* — an unexplained literal where a named constant would state the rule.
- *Negative conditional* — `if (!isNotReady)`; harder to read than the positive form, for no gain.

**Functions**
- *Flag argument* — a boolean parameter selecting between two behaviors; the function is doing two things, and the call site reads as a puzzle.
- *Output argument* — a parameter mutated as a way of returning a result; the return value is the natural channel.
- *Side effect in a query* — a function that answers a question and also changes state, so callers can reason about neither (Meyer's command-query separation, which Martin cites here).

**Structure**
- *Vertical Separation* — a variable or helper declared far from its use, forcing the reader to hunt.
- *Artificial Coupling* — two things bound together for no real reason, usually convenience at the moment of writing.
- *Base Classes Depending on Derivatives* — a base class that knows about its subclasses, defeating the hierarchy.
- *Too Much Information* — a wide public surface where a narrow one would do; leaky encapsulation. *designing note:* between two otherwise equal options, the one with the smaller surface is the better bet.
- *Inconsistency* — the same idea done two different ways in one codebase, so a reader can't trust a pattern once learned.

**Error handling**
- *Returning or passing null* — pushes a null check onto every caller (or callee); an empty collection, an option type, or a raised error usually says it better.
- *Error codes where exceptions belong* — forces callers to branch on returns and remember to check.

## Component-level smells

Higher than Fowler's smells, lower than the rot symptoms — and frequently invisible in any
single file, since the evidence is the shape of the dependency graph rather than the contents
of a unit. See [principles.md](principles.md) for the principles these violate.

- *Dependency cycle* — two or more components that depend on each other, directly or transitively. Neither can be released, tested, or reasoned about alone (ADP).
- *Unstable dependency* — a widely-depended-on component reaching down into something that changes often; the volatility propagates to every dependent (SDP).
- *Zone of pain* — a component both heavily depended upon and entirely concrete, so it can't be extended without editing it (SAP).
- *Grab-bag component* — a `utils`/`common`/`shared` package with no single reason to change, accumulating whatever had nowhere else to go (CCP). **Descriptive name, not canonical** — Martin describes the condition without a settled label for it.
- *Over-broad dependency* — depending on a whole component to use one class in it, inheriting its transitive dependencies and its release cadence (CRP). **Descriptive name, not canonical.**

## Martin's Symptoms of Design Rot

Where Fowler's smells are concrete and local, these are higher-level symptoms — useful for
framing *why* a smell matters, especially a recurring one. *designing note:* read these as
the qualities a good design option preserves and a poor one erodes.

- **Rigidity** — every change forces a cascade of other changes elsewhere in the system.
- **Fragility** — changes break things in places conceptually unrelated to the change.
- **Immobility** — code that could be reused is too entangled with its current context to extract.
- **Viscosity** — the easy-but-wrong way to make a change is less effort than the proper way, so hacks accumulate.
- **Needless Complexity** — machinery in place for problems the system doesn't actually have.
- **Needless Repetition** — copy-paste standing in for a shared abstraction that was never made.
- **Opacity** — the code doesn't communicate its own intent; a reader has to reconstruct it.

## Relationship to principles

Martin's rot symptoms are the observable *effects* of violating design principles —
Rigidity and Fragility often trace back to a Single Responsibility or Dependency Inversion
violation, Immobility to Interface Segregation, Viscosity to any of them ignored under time
pressure. When you have a smell and want to name the principle behind it — to decide what
the fix (or the better design option) should actually be, rather than reaching for the first
abstraction that comes to mind — see [principles.md](principles.md).

**Check the altitude before settling on a cause.** A rot symptom at system scale often has its
cause a level above the class: in a mature codebase, Rigidity and Immobility trace to a
dependency cycle, a grab-bag component, or a stable-and-concrete component at least as often
as to a class-level SOLID violation. Naming the class-level cause when the real one is
component-level produces a fix that doesn't move the symptom. The component principles are in
[principles.md](principles.md) alongside SOLID.
