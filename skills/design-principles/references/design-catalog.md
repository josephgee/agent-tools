# Design Catalog — Smells and Rot Symptoms

A vocabulary for naming design pressure, drawn from Fowler's catalog of code smells and
Martin's symptoms of design rot. Each entry states the concept **neutrally** — what the
thing *is* — not what to do about it. The posture (are you detecting these in existing code,
or weighing them against design options?) is supplied by whoever loaded this file.

Naming a smell is the point of consulting this catalog. A name is not a mandate to fix
anything — it is a precise handle for a real force, so a decision about it can be made on
its own merits rather than on a vague sense of unease.

A few entries carry a `designing note:` — a hint for the *generative* reader, where the
forward application ("what would tripping this look like in a design I haven't built yet?")
isn't obvious from the detection-flavored description. Most entries don't need one.

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
