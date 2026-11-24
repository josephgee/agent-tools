# Review comments on a shipped PR

Read when the user brings review comments on a PR the ledger shows `shipped`, usually from the
hosted PR after they pushed the stack. A comment's fix is a change after the boundary, which is
exactly where a regression slips through. In the incident behind this file, a reviewer's comment
moved a check into a shared hook, nothing re-checked it, and a page outside the hook's provider
broke in production. So every step below runs for every comment, however small the fix looks.

Set `top=$(git rev-parse --show-toplevel)` in the same call as each command.

1. **Re-read the ledger's Rules in Force header, its PRs and Net sections, and the plan's PRs and
   Regression Net sections.**
2. **Free the tree.** `git -C "$top" status --short` must show nothing. If a background run is
   going, stop it (`background-suite.md`, *To stop a run without restarting*). If a later PR is
   `in progress` with uncommitted work, ask the user before touching it: commit it on its branch
   or leave the comments for later.
3. **Mark the old tip, then switch:** `git -C "$top" branch <NN-branch>-pre-review <NN-branch>`,
   then `git -C "$top" switch <NN-branch>`. The marker is what the restack in step 7 rebases from.
4. **Make the change as new commits on the branch, not amended into the squash commit.** The PR is
   pushed and under review: reviewers read new commits, and amending forces a push the user did
   not choose. Commit tests and code together.
5. **Re-trace, unconditionally**, over the PR's whole diff,
   `git -C "$top" diff <previous-pr-branch>...HEAD`, following
   `../slice-plan/references/regression-net.md`. Don't stop at the files the fix touched: a
   dependency added inside a unit that was already touched is the case this exists for. Lay each
   new entry as SKILL.md's *Laying the net* does, owned by this PR. If its spec is red on the
   fixed code with no deliberate break, the fix broke that consumer: rework the fix.
6. **Run the targeted tests and the whole net.** Any red here means the fix isn't done. If the
   change is structural (a signature, a moved responsibility, a new type or module), send the PR's
   diff through one design-review round, as the boundary's step 2 does.
7. **Restack the later branches** in one command, from the last shipped or in-progress PR's
   branch: `git -C "$top" rebase --update-refs --onto <NN-branch> <NN-branch>-pre-review <last-branch>`.
   On a conflict, stop and show the user. Once it succeeds, delete the marker branch.
8. **Start the background suite run** on `<NN-branch>`, per `background-suite.md`, reusing the
   directory in this PR's **Suite** field. If later branches exist, start a second run on the last
   branch once the first reads `0`: it is the only check that the later PRs still hold.
9. **Record it in the ledger**, under the PR's entry: a `Review changes` line per comment, with
   the comment in one line, what changed, the new net entries or `none`, and the run's result.
   Say what to push: `<NN-branch>` as new commits, and every restacked later branch, which needs
   a force push. Pushing is the user's call.
