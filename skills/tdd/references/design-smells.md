# Design Smells Reference

A vocabulary for naming design pressure, drawn from Fowler's catalog of code smells and
Martin's symptoms of design rot. This is a reference to consult, not a checklist to run
every cycle.

**When to use it:**
- **Per-cycle Design Pressure Check** (in the main cycle): only if you sense pressure but
  can't name it, or want the precise term for a backlog entry. The three fast triggers
  already in that check (repeated branching, a class with two reasons to change, test
  setup friction) cover the smells that show up most often within a single cycle's diff —
  they're deliberately narrow so the check stays a minute, not an audit. Don't scan this
  whole file mid-cycle.
- **Final "Code is clean" review** (Progress, end of feature): this is the deeper,
  whole-codebase pass where scanning the full list below is appropriate. Log genuine
  matches to the backlog before declaring the feature complete.
- **Design Evolution**: if the same smell keeps recurring across cycles rather than
  resolving with a local refactor, that recurrence — not any single instance — is the
  signal to consider a hypothesis revision rather than another patch.

Naming a smell is the point of consulting this file — not a mandate to fix it immediately.
A named smell still goes through the same judgment as anything else here: fix now if it's
cheap and the test suite is green, or log it to the backlog with the name and a one-line
reason if it isn't.

## Fowler's Design Smells

**Bloaters** — something has grown past the point where it's still easy to work with.
- *Long Method* — a method doing enough that you can't summarize it in one sentence.
- *Large Class* — a class accumulating fields and methods that don't all relate to the same responsibility.
- *Primitive Obsession* — using raw strings/ints/booleans for concepts that deserve their own type (money, an email address, a status).
- *Long Parameter List* — enough parameters that callers can't easily get the order or meaning right.
- *Data Clumps* — the same group of values (e.g. `start`, `end`, `timezone`) always traveling together as separate parameters instead of one type.

**Object-Orientation Abusers** — OO mechanisms used in ways that fight the paradigm.
- *Switch Statements* (or long if/elif chains) — the same conditional on type/kind repeated in multiple places; usually resolved with polymorphism.
- *Temporary Field* — a field only meaningful in some circumstances, null or unused otherwise.
- *Refused Bequest* — a subclass that overrides most of what it inherits, signaling the hierarchy is wrong.
- *Alternative Classes with Different Interfaces* — two classes doing the same job with differently named methods, blocking substitution.

**Change Preventers** — one change ripples further than it should.
- *Divergent Change* — one class changes for many unrelated reasons (a form of low cohesion; overlaps with "two reasons to change" in the per-cycle check).
- *Shotgun Surgery* — one change requires small edits scattered across many classes (the inverse of Divergent Change — logic that should be together is spread out).
- *Parallel Inheritance Hierarchies* — every time you add a subclass in one hierarchy, you must add a matching subclass in another.

**Dispensables** — something that shouldn't exist at all.
- *Duplicate Code* — same logic in more than one place (already covered directly in the refactor checklist).
- *Lazy Class* — a class that no longer does enough to justify its own existence.
- *Data Class* — a class with only fields and getters/setters, no behavior — logic that should live with the data lives elsewhere instead.
- *Dead Code* — unreachable or unused code (see "Deletion-driving tests" in the refactor checklist for the test-side version of this).
- *Speculative Generality* — abstraction built for a future that hasn't arrived (hooks, parameters, or layers with no current caller).

**Couplers** — excessive coupling between classes or modules.
- *Feature Envy* — a method more interested in another object's data than its own; it probably belongs on that other object.
- *Inappropriate Intimacy* — two classes reaching into each other's internals rather than communicating through a clean interface.
- *Message Chains* — `a.getB().getC().getD()` — a client navigating deep into an object graph it shouldn't need to know about.
- *Middle Man* — a class whose methods mostly just delegate to another class, adding no value of its own.

## Martin's Symptoms of Design Rot

Where Fowler's smells are concrete and local, these are higher-level symptoms — useful
for framing *why* a recurring smell matters, especially when deciding whether to escalate
to a hypothesis revision.

- **Rigidity** — every change forces a cascade of other changes elsewhere in the system.
- **Fragility** — changes break things in places conceptually unrelated to the change.
- **Immobility** — code that could be reused is too entangled with its current context to extract.
- **Viscosity** — the easy-but-wrong way to make a change is less effort than the proper way, so hacks accumulate.
- **Needless Complexity** — machinery in place for problems the system doesn't actually have.
- **Needless Repetition** — copy-paste standing in for a shared abstraction that was never made.
- **Opacity** — the code doesn't communicate its own intent; a reader has to reconstruct it.

## Relationship to SOLID

Martin's rot symptoms are the observable *effects* of violating SOLID principles — Rigidity
and Fragility often trace back to a Single Responsibility or Dependency Inversion violation,
Immobility to Interface Segregation, Viscosity to any of them being ignored under time
pressure. If a final review turns up a rot symptom, naming the SOLID principle behind it
can help decide what the fix should actually look like, rather than reaching for the first
abstraction that comes to mind.
