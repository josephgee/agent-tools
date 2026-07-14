# When Stuck

| Problem | What to do |
|---------|------------|
| Don't know what test to write | Describe the next behavior in one plain-English sentence. The test is that sentence in code. |
| Test is too hard to write | The design is too complicated. Simplify the interface until the test is easy — that's the design telling you something. |
| Need lots of mocks | System boundary or your own code? Boundary mocks are fine. Mocking your own code means the design is too coupled — simplify the dependency or narrow the interface. |
| Test setup is enormous | Extract a helper. If still huge, the object under test does too much. |
| Stuck choosing between approaches | Write a test for the simpler one. If it works, keep going. If it hurts, you'll learn why. |
| The plan doesn't fit anymore | Good — the design hypothesis evolved. Revise the plan. This is the process working correctly. |
