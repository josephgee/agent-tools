# Refactoring Standard

The rules production code is held to, not suggestions to weigh. Shared by the `refactor`,
`tdd`, and `slice-tdd` skills, so it speaks in two terms the file that sent you here defines:
**the scope** (the code under change) and **the log** (where findings are recorded).

When priorities conflict, apply Simple Design in this order: tests pass > intention clear > no
duplication > fewest elements. Never trade clarity for less duplication.

- **Naming**: name the *meaning*, not the type (`remaining_attempts` not `retryInt`). Name the
  *behavior*, not the mechanism (`publish_validated` not `process_data`). Name the *condition*
  for booleans (`has_exceeded_limit`, not `flag`). If you must read the body to understand the
  name, rename it. An extracted function is named for what it achieves at its caller's level,
  never for the lines it happens to contain (`apply_member_discount`, not `loop_over_items`).
  If the work taught you something about a concept, check whether existing names still
  reflect that understanding.
- **One level of abstraction per function.** A function reads as a sequence of steps one level
  below its own name. Where policy sits beside low-level detail, extract the detail and name it.
  Extract to name a concept, not to shorten: a one-line helper that only restates its body is
  worse than the line.
- **Ordering**: within the scope, a caller comes before the functions it calls, so the code
  reads top-down from the entry point — public surface first, each helper below its first caller,
  in the order the caller uses them. A variable is declared next to its first use. Where the
  language or the project's lint config dictates order (definition before use), follow it. Don't
  reorder code outside the scope to comply.
- **Comments**: delete every comment on lines the scope adds or rewrites. Where does the code need to be more
  expressive to make up for it? Do that. Decision context (why this change, what was rejected)
  goes in the log, not back into the code. If a hazard can only be flagged at the edit site
  and no name, type, or failing test can carry it, do not keep a comment — list it (file:line,
  why) in the log for the user to decide. Not comments: tool and build directives (`//go:build`,
  `# noqa`, `eslint-disable`, `# type: ignore`, pragmas), doctests, and API docs a generator
  publishes — they are behavior, and stay.
- **Delete first.** Candidates are everything the scope adds or changes, and anything it may have
  made redundant — a branch, parameter, type, concept, helper. An argument that something earns its
  place is not evidence; one can always be made. Act by what is known about each candidate:
  - **Nothing references it** (no caller found by the compiler or a search, and nothing dynamic
    could reach it) — delete it.
  - **Referenced and pinned** by tests you trust — delete it and run the targeted tests. Green
    means it stays deleted, unless you can name a consumer the tests miss (a caller outside them,
    behavior a user sees); then restore it and log the missing pin.
  - **Referenced but unpinned** — neither delete it nor argue for it: log it as
    `deletion candidate (unpinned): <what, why it looks redundant>`.
- **Duplication**: same logic in more than one place in the scope? Consolidate it. Check the
  surrounding code too: a helper that already exists there is duplication.
- **Structure**: responsibilities in the right places? A unit doing the work of several, or a
  method more interested in another object's data than its own, is the cause to fix — not its
  length.
