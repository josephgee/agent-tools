# When Stuck

| Problem | What to do |
|---------|------------|
| Don't know what behaviors go in the batch | Describe the PR's one sentence, then list what a consumer must be able to observe for it to be true. Each observation is one behavior, one test. |
| A batch test is too hard to write | The design is too complicated. Simplify the interface until the test is easy — that is the design telling you something, and at RED it costs nothing to change. |
| The batch keeps growing while you write it | It is more than one PR. Stop, split the PR plan, and write the batch for the first slice only. Never grow the fence to fit the work. |
| Need lots of mocks | System boundary or your own code? Boundary mocks are fine. Mocking your own code means the design is too coupled — simplify the dependency or narrow the interface. |
| Setup is enormous across the batch | Extract a helper. If it is still huge, the object under test does too much — and five tests sharing that setup is a verdict, not a whisper. |
| Tests fail on imports, not assertions | The skeleton is missing or incomplete. Add raising stubs for the whole sketched interface before verifying. |
| A test passes against the raising skeleton | The test is broken — it is not exercising what it claims. Fix it or delete it; do not proceed. |
| Implementation thrashing, failing count flat | Three flat full-suite runs is the tripwire: drop to the ladder — one failing test at a time — until the entanglement breaks, then resume holistically. |
| A batch test turns out to be wrong mid-GREEN | Use the amendment protocol: halt, state the defect, amend in its own commit, re-verify it fails for the right reason. Never weaken it inside an implementation commit. |
| Discovered a behavior the PR needs but the batch lacks | In scope for the PR's sentence: add it via the amendment protocol. Outside it: backlog, and it becomes a later PR. |
| The review keeps finding structural problems | You are converging or you are not: the three-round cap decides. What is still open at the cap goes to the backlog and is surfaced at the boundary — it does not get silently absorbed. |
| Nothing to write in the pressure log | Wrong question. "Ugliest thing you wrote" always has an answer; the judgment may still be "and it's fine, because Y". |
| The plan doesn't fit anymore | Good — the design hypothesis evolved. Revise the plan. This is the process working correctly. |
