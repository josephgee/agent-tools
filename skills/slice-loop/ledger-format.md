# Ledger Format

The ledger records how an agreed plan is being built: per PR, which strategy is running it, which
were tried and abandoned, its suite run, and what its executor reported; plus which criteria are
ticked and the backlog. What each PR *is* stays in the plan; the ledger keys on the plan's `NN`.

It is never committed — excluded at Setup — so the record of a failed attempt survives the rollback
that erases the attempt. SKILL.md's *Files* has the reasoning.

`<plans-dir>/loop-<feature-slug>.md`, in the plan's directory, under the plan's slug.

---

## The Rules in Force header

Everything inside the fence — the title and the `## Rules in Force` section, nothing after — is
copied verbatim into a new ledger and never edited. It is the **host's** rules only; no executor
reads it. Keep it short: it is re-read at every PR, boundary and abandon. **It is the only part of a
ledger ever replaced wholesale**, if a resumed one's header is missing or has drifted.

```markdown
# Slice Loop Ledger

## Rules in Force

Copied verbatim at creation. Re-read at the start of every PR, at every boundary, and before every
abandon. Never edited or summarized.

- Build only an `agreed` plan. Write to it only to re-slice — its PRs section: PRs not yet started,
  or narrowing the current one; drops, reorders and widening go to the user first — or to add a
  net entry a re-trace found.
- Lay a PR's net before its code: each spec proven red against a deliberate break. Re-trace at
  every boundary and on every change after one, review comments included. No executor edits a
  net spec.
- One PR = one branch off the previous PR's branch (base branch for PR 01); never two.
- Choose the strategy per PR, before its branch is cut; record it here before any code. State the
  executor's obligations at every handoff, in the form its shape takes.
- A guest has handed back only when its report exists with all six headings. Copy it here, then
  delete it. Check branch, tree and tests on disk — never take them from the report.
- No code on a PR until the previous PR's suite run reads `0`; only `slice-tdd` may start early, with
  the pause paragraph. The run uses this tree: change nothing outside the plans dir while it goes;
  stop it first.
- No boundary over a red test. Review, commit fixes, squash, start the suite run, then present; a
  change in review is amended in. Red after approval: reopen, fix, amend, rebase the next PR onto it.
- To abandon, **propose it and get the user's confirmation first**, then run the abandon recipe
  (`references/abandon.md`) as one uninterrupted step.
- An attempt's line is closed in place, never removed and never duplicated.
- **The plan, this ledger and reports are never committed** — all in `info/exclude`. Never `git add`
  or `clean -x` them.
- Branch names only, never a commit sha: the squash rewrites them.
- A PR the user has taken by hand is theirs — write no code in it; close its attempt line and
  confirm its work committed yourself.
```

## The rest of the file

A template, filled in as you go. Setup writes the Session block and the Criteria section complete,
in one write; a PR's entry appears when its strategy is chosen.

```markdown
## Session
- **Plan**: <plans-dir>/slices-<feature-slug>.md
- **Base branch**: <branch PR 01 is cut from and reviewed against>
- **Test runner**: `<command>`
- **Net runner**: `<command running every laid net spec>`, or `none yet`
- **Started**: YYYY-MM-DD
- **Last updated**: YYYY-MM-DD

## PRs

### 01 — shipped
- **Strategy**: internal
- **Suite**: green: /home/me/.cache/slice-suite/myrepo-<feature-slug>-01
- **Attempts**:
  - internal — shipped: reviewed
- **Review**: Dismissed: <finding — reason>; Open at cap: none
- **Discoveries**: <a later-PR discovery, and what was done about it>
- **Learned**: <decision context, folded into the squash commit>
- **Review changes**:
  - <comment, one line> → <what changed>; net: <new entries, or none>; suite: green

### 02 — in progress
- **Strategy**: hand
- **Attempts**:
  - internal — abandoned: <what entangled, one line>
  - hand — in progress

## Net

- R1 — PR 03: <spec path> — committed | untracked — red against: <the deliberate break>

## Criteria

- [x] AC1 — PR 01: <the test or proof that satisfies it>
- [ ] AC2

## Backlog

- [ ] <description> — noted in PR 02
- [x] <description> — resolved in PR 03: <how>
- [-] <description> — dismissed in PR 04: <why>
- [>] <description> — carried to <where the user named>
```

## When the host writes

Set **Last updated** at each:

- **Setup** — create the file.
- **Choosing a strategy** — the PR's entry with status `chosen`, its `Strategy` and its first
  `Attempts` line.
- **Cutting the branch** — the PR's status to `in progress`.
- **A guest's return** — the report copied in; the `Attempts` line closed with its Outcome.
- **The boundary** — `Suite` set to `running: <dir>` at step 3, then status `shipped`, the
  `Attempts` line closed, criteria ticked, backlog items.
- **A background run's result** — `Suite` set to `green: <dir>` or `red: …, <dir>`, and back to
  `running: <dir>` at every restart.
- **An abandon** — the abandoned `Attempts` line and the new strategy.
- **Laying the net** — each entry's Net line, and the Session's **Net runner**.
- **A review comment's fix** — its `Review changes` line.

The blocked path's fresh attempt lines are writes too.

## PR entry

| Field | Rule |
|---|---|
| Heading | `### NN — <status>`, `NN` from the plan. Status is `chosen` (strategy recorded, branch not cut), `in progress` (branch cut) or `shipped`; a PR with no entry has not started. |
| Strategy | What is running the PR *now*: `acceptance`, `internal`, `yolo`, `navigator`, `direct` or `hand`. |
| Suite | `running: <dir>`, then `green: <dir>`, `red: <failing tests>, <dir>`, or `green: fixed — <what>, <dir>` after a reopen — the directory always kept, since Cleanup deletes it. Absent until the boundary. |
| Attempts | One line per attempt, never removed, **closed in place** as its state changes: `<strategy> — <in progress \| handed back \| shipped \| blocked: <what stopped it> \| abandoned: <what entangled>>`, plus `<acceptance \| internal \| yolo> — paused: design done`, closed in place and followed by a fresh `in progress` line on resume. A `chosen` PR's first line
already reads `in progress`: the PR's status, not the line, says whether its branch exists. `handed back` and `shipped` may carry `: <note>`, and the whole token `reviewed`, comma-separated after any note, when the guest reported its own review. |
| Review changes | One line per hosted review comment fixed after `shipped`, per `references/review-comments.md`. |
| Review, Discoveries, Learned | Copied from the guest's report, or written by the host for `direct`, `hand` and `navigator`. Omitted when empty. |

The Attempts list is the reversibility record. Everything else about a PR is recoverable from git;
the fact that a strategy was tried and why it was abandoned is not.
