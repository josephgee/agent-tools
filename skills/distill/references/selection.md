# Selection: what survives the cut

Selection runs **after** synthesis, on the handful of claims and their supporting evidence —
never on the raw pile. Cutting before collapsing is how you get a shorter deluge.
See `synthesis.md`.

## The test

For every claim, and every piece of evidence under it:

> **Would knowing this change what the reader does next?**

That is the whole criterion, and it is why the frame is mandatory. "Would this change what they
do" is unanswerable until you have written down what they are deciding.

**The test applies to the layers the reader reads now — the lead and the actions.** In a
reference layer it inverts: that layer is complete over its set, so an omission is the defect
and this test would gut it. What the test governs there is not *which items* appear but *which
fields* each one carries; see the resume-cold test in `rendering.md`.

And "cut" throughout this file means **demote**, not delete: down to the reference layer if the
reader will want it later, to the archive if they will not.

Three things follow from taking it literally:

- **Interesting is not relevant.** A genuinely fascinating fact about the codebase that bears
  on no decision is cut. It can go in the archive pointer.
- **True is not relevant.** Accuracy is a floor, not a reason to include.
- **Expensive is not relevant.** This is the one that actually bites — see below.

## The sunk-cost trap

The strongest pull toward verbosity is not sloppiness. It is that the material **cost
something to produce**. Forty tool calls went into that survey; dropping 95% of it feels like
throwing away the work.

It is not. The work produced the *conclusion*; the conclusion is what gets delivered. The
intermediate material has already done its job, and it still exists in the archive. Effort
spent finding something is not evidence that the reader needs it.

The tell that sunk cost is leaking into the output is **process narration** — any sentence
describing the search rather than its result. "I looked at 14 files", "after checking the
config I then examined", "my initial hypothesis was". Cut all of it. The reader did not
commission a report on the investigation; they commissioned its findings.

The one exception: **method matters when it bounds the conclusion**. "This covers `src/` only;
the vendored code was not searched" is not narration, it is a limit on what the brief claims.
Keep those, stated as limits, in one line, near the end.

## More material raises confidence without raising accuracy

Heuer's finding on intelligence analysts: past a fairly early point, giving an analyst more
information does not make their judgments more accurate — it makes them **more confident** in
the judgments they already had. The extra material feels like it is helping and is not.

This is the argument that a deluge is *actively harmful* rather than merely long. A brief that
buries three decision-relevant findings in ninety inert ones does not just waste time; it makes
the reader feel better informed than they are. Cutting is not a concession to impatience. It is
part of being correct.

## Always cut, regardless of frame

| Cut | Why |
| --- | --- |
| Process narration | Reports on the search, not its result. See above. |
| Restating the question | The reader wrote it; echoing it back spends their attention on what they already know. |
| Preamble and throat-clearing | "Great question", "Let me walk through what I found", "There are several things to consider here" — pure delay before the answer. |
| The closing summary that repeats the top | If the brief leads with the answer, a recap is the same fact a second time. The redundancy costs load and adds nothing. |
| Hedging on things you are not unsure about | See calibration, below. |
| Generic recommendations | "Consider adding tests", "you may want to monitor this" — true of everything, therefore informative about nothing. |
| Definitions of terms the reader used | If they asked about their own auth middleware, they know what it is. |
| Counts as headline facts | "200 usages found" is a measure of the search, not a finding. Lead with what the 200 mean. |

## Keep, even when it looks minor

Some things pass the test despite being small or unglamorous, and are the most common wrongful
cuts:

- **Exceptions to a claim.** "All of them convert mechanically — except three" is a different
  brief from "all of them convert mechanically". The exception is usually the decision.
- **Anything that blocks the decision**, however cheap the fix. A one-line config change that
  gates the whole thing outranks an elegant architectural observation.
- **Cheap wins**, if the frame is about effort. High value over cost is decision-relevant.
- **Irreversibility and data loss.** If proceeding destroys something, that survives at any
  length budget.
- **A limit on what was examined**, when it bounds the conclusion.
- **Disconfirming evidence.** Anything cutting against your own leading claim stays. Dropping
  it is how a brief becomes advocacy.

## Calibration

Hedge in proportion to actual uncertainty, and nowhere else. Uniform hedging destroys the
signal: if every claim is "may potentially", the reader cannot tell which one you actually
doubt, so they discount all of them equally — including the one you were certain about.

- **Certain:** state it flat. "The token check runs after the handler."
- **Inferred but unverified:** say what would settle it. "This looks like the cause; running
  the suite against `main` would confirm."
- **Genuinely unknown:** say so and stop. "Nothing in the source indicates why."

Never manufacture symmetry by hedging a solid claim to match a shaky one.

## Stating the remainder

Every cut of any size gets one line, and the line carries three things: **roughly how much**,
**of what class**, and **where it is**.

> The other 190 hits are the same three call patterns; full list in `survey.md`.

Not "some other findings were omitted for brevity" — that tells the reader nothing about
whether they should go look. Naming the *class* is what lets them decide, and it is also what
proves you actually classified them rather than truncating.

If a cut item turns out to be its own class of one, that is a signal it should not have been
cut.
