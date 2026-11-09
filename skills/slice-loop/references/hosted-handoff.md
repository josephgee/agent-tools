# Handing a PR to a skill

A hosted skill builds **one PR**; the loop keeps the rest, and the block is how it learns that.

## The block

The block below is the **guest-facing rendering of the executor contract** in
[executor-contract.md](executor-contract.md), that contract's single source. It renders the five obligations **in the contract's order, one
numbered paragraph each**, in the guest's voice. It is the only form of the contract a guest ever
reads — and, with the plan read-only, everything a guest needs to run — so it stays self-contained
and pasteable and never becomes a pointer back to SKILL.md.

**Change an obligation there and change its numbered paragraph here in the same edit.** A block
carrying fewer than five numbered paragraphs has lost one — except `navigator`'s, numbered 1, 2, 3
and 5 by design (below). The unnumbered paragraphs are
framing, not obligations.

Give it verbatim with the placeholders filled. Copy the PR's fields from the plan and the Session
values from the ledger; give the report path absolute.

### Adapting it for a guest that reviews

A guest whose own flow reviews its diff before hand-back (`slice-tdd` today) gets **paragraph 5
replaced, whole, by this** — a guest's own per-PR gates, such as `slice-tdd`'s design gate, are not
the alignment gate the block skips and survive:

> **5. Hand back before the squash, with your report.** Do not squash, do not present a PR, and do
> not write a PR description. Do run your own review as your rules describe, before you hand back,
> and report it under `## Review` with the word `reviewed` and lists headed `Dismissed` (each finding
> with its reason), `Backlogged`, `Open at cap` (including any change made after your last review,
> marked unreviewed) and `Out of scope`. Never fix a finding that asks to tighten an earlier PR's or
> the steel thread's test, or that asks for behavior this PR does not have: those are `Backlogged`,
> however cheap. The host skips its own review and shows the user your dismissals, so keep them
> honest, one line each. Otherwise write your report as the block's *Your report* says; then, on
> `handed back`, make a last commit removing any file of your own you committed, such as a state
> file: nothing of yours ships.

### The mode paragraph, for `slice-tdd`

Add after paragraph 5, always, with `<strategy>` filled in:

> **Mode.** You run in **`<strategy>`** mode. Your report's Outcome names it.

For `yolo`, append: *"In `yolo`, obligation 2's passing test for this PR's behavior is replaced by
your acceptance proofs passing; the targeted tests still stay green. Report each criterion's agent
proof under Criteria proof, marked `read-only` or `mutating`."*

### The pause paragraph, for `slice-tdd`

While the previous PR's suite run is still going, add this after the mode paragraph. Leave it out
once the run reads `0`, and when invoking a paused `slice-tdd` again.

> **Pause before code.** Until you are invoked again, change no file outside your state file and
> run no tests: the host's full-suite run is using this tree. After your design commit, before any
> pinning or test, write your report with Outcome `<strategy> — paused: design done` and `none`
> under every other heading, and hand back. The host invokes you again when you may go on.

### Adapting it for `navigator`

`navigator` never edits files and the user writes every line, so hosted it coaches rather than
builds, and writes no report — the host records the PR's outcome itself (SKILL.md, *Hand off*). Its
block keeps paragraphs **1, 2, 3 and 5**, numbered as such:

- **Append to paragraph 2**: *"Coach the user through this PR. Write no code. Stop when they say
  the PR is done and the tests nearest their change are green, then hand back."*
- **In paragraph 3, drop its last sentence** (the state file): navigator keeps its own file outside
  the repo, at its own path.
- **Drop paragraph 4 entirely**, leaving the gap in the numbering — navigator commits nothing; the
  host confirms the user's work is committed.
- **Replace paragraph 5, whole**, with *"**5. Hand back before the squash.** Do not squash,
  review or present a PR. Say what happened and stop."* — and drop *Your report*.
- **In the `blocked` paragraph**, drop "commit any complete work" and the report: say what stopped
  it and stop.

---

> You are building **one PR** of an agreed plan, on behalf of a host that reviews, squashes and
> records it. Everything you need is here.
>
> - **Behavior**: *`<behavior sentence>`*
> - **Kind**: `<behavioral | thread | refactor: reason | scaffolding: reason>`
> - **Criteria it advances**: `<each criterion, ID and full text, with its examples>`
> - **Constraints**: `<the plan's Constraints, verbatim — they bind this PR>`
> - **Test runner**: `<command>`
> - **Base branch**: `<previous PR's branch — what this PR is reviewed against>`
> - **Plans directory**: `<plans-dir>`; **feature slug**: `<feature-slug>`; **PR number**: `<NN>`
> - **Design**: `<path, or none>` — context, not a decision you are bound by
> - **Plan**: `<plan path>` — read-only context: its later PRs show what is *not* this PR's work.
> - **Report path**: `<absolute path>`
>
> **Do not run your own planning or setup** — except creating your state file, if your flow keeps
> one. The feature, criteria and sequence are agreed; the tree is clean, the baseline green, the
> branch cut. Skip your preflight and your alignment gate. Make no "begin" commit.
>
> **1. Stay on the branch the host cut, and create no others.** It is already checked out:
> **`<branch>`**. Do not create, rename or switch branches.
>
> **2. Leave your targeted tests green when you hand back, with a passing test for this PR's
> behavior.** Your *targeted tests* are this PR's own tests plus the existing tests nearest the code
> you changed, picked with the runner's own file or directory filter. **Do not run the full suite**,
> even where your own rules say to: the host runs it after you hand back. On a `refactor` or
> `scaffolding` PR, the whole obligation is that the existing tests over the restructured code stay
> green — no new behavior, so no new test. Never hand back with a test red.
>
> **An earlier PR's test this PR breaks is yours to update, whatever your own rules say about
> changing tests.** Change its fixture or call site wherever that absorbs it: an expectation edited
> to agree with the new behavior stops pinning its own PR's rule. Otherwise narrow the expectation
> to that PR's rule, never weaker. If this PR replaces the rule, delete the test, and if it
> satisfied a criterion, make sure your test still does. Commit the update alone, before the work
> that needs it, and report it under Carry-forward.
>
> **3. Build only this PR, and write neither the plan nor any host file.** Work the plan's later PRs
> own is not yours, however much your own refactoring step wants it — report it under Later-PR
> discoveries and move on. Preserve existing behavior unless the behavior sentence changes it; the
> structure behind it, earlier PRs' included, evolves as this PR needs. If your flow keeps a state
> file, put it in the plans directory under your own naming, using the slug and PR number above,
> and copy the fields above into it rather than re-deriving them.
>
> **4. Commit your work on this branch as you go, and leave it committed when you hand back.** The
> host squashes committed history, not worktree state: an uncommitted PR fails the squash, and a
> resumed host reads zero commits as a PR you never built.
>
> **5. Hand back before the squash, with your report.** Do not squash, present a PR, write a PR
> description, or run your own design review of the diff — the host reviews this PR at its
> boundary. When you hand back `handed back`, write your report first, then make a last commit
> removing any file of your own you committed, such as a state file: nothing of yours ships.
>
> **Your report.** Write it to the report path, with exactly these six headings, each followed by
> its content or `none` — a missing heading means you have not handed back:
>
> ```markdown
> ## Outcome
> <your name> — handed back | <your name> — blocked: <what stopped you>
> ## Review
> none
> ## Criteria proof
> <each criterion ID: the test or proof that satisfies it>
> ## Carry-forward
> <backlog items; out-of-scope gaps; any earlier PR's test you updated, and how>
> ## Later-PR discoveries
> <anything you learned that changes a later PR>
> ## Learned
> <decision context a PR description would carry; or none>
> ```
>
> **If you cannot finish the PR, hand back `blocked`.** That is the one sanctioned way not to finish
> one — it needs splitting, or your own rules leave you no move on it. Get your tests back to green,
> commit any complete work (or nothing), keep your state file, and report `blocked: <what stopped
> you>`. Do not re-slice: that is the host's.

---

## Delegated or in-session

In-session is the default (SKILL.md, *Hand off*). Delegating buys context: the guest's body,
references and dependencies load in a subagent, once per PR, and an abandoned guest's body does not
linger. It costs the mid-PR exit — a delegated guest is invisible until it hands back, so you
cannot stop it — and the view of how it worked. Delegate only a guest that needs neither the user
live nor the abandon.

## Reading the result

**Judge a guest by what it left on disk**, not by its report. At the boundary, before the review:

- the targeted tests are green and no PR was presented;
- the commits are on the branch you cut, and `git branch --list` shows no branch the ledger does
  not name, other than one left behind by a dropped PR;
- `git -C "$top" diff --stat <previous-pr-branch> HEAD -- <plans-dir>/` adds no file of the
  guest's;
- `git -C "$top" status --short` is clean.
