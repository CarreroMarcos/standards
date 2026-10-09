---
name: bot-review-loop
description: Use when a PR needs a babysitter through bot review: canonical review comments arriving, findings to disposition, recheck-until-flat loops to run, freeze-rule calls to make, or a bot that went quiet mid-loop.
---

## Exit predicate

The run ends when one of these holds, checkable per finding:

- The human merged the PR, or
- every finding in the canonical comment carries exactly one disposition — `fixed`, `dismissed-with-reason`, or `frozen` — and the bot loop is green, or
- a confident-stop is flagged with its evidence attached.

A finding with no disposition keeps the loop open. A confident-stop without evidence is not a stop.

## Requires

- A review bot posting canonical comments carrying the marker `<!-- pr-reviewer:canonical:v1 -->`.
- A human merge gate: only the human merges standards-repo PRs.
- CI that reports per-commit status on the PR.

## Inputs

- `repo`: the repository under review.
- `pr`: the PR number.
- `mode`: one of `drive`, `background`, `threads-only`, `check` (see Babysit modes).

## Babysit modes

- `drive`: run the full loop now, reporting at each disposition round.
- `background`: run the loop unattended; emit the Reply report on every exit-predicate state change.
- `threads-only`: watch the PR thread for new canonical comments; take no other action.
- `check`: single pass — poll once, triage once, report. Skip step 5: `skip: single-pass mode runs no recheck loop`.

## Steps

1. Poll the PR thread for the latest comment carrying `<!-- pr-reviewer:canonical:v1 -->`. When several exist, the newest one is canonical; older ones are history. When the bot errors repeatedly, emits stale reviews, or stops posting canonical comments, go to step 13.
2. Triage every finding against the shared dismissal rubric — skeptical by default. Read the cited code before judging the finding (`loop-before-theory`); match triage depth to finding severity (`scale-ceremony`).

   **Shared dismissal rubric.** Dismiss a finding only with evidence attached:
   - False positive: quote the code that proves the finding wrong.
   - Out of scope: name the scope boundary the finding crosses.
   - Duplicate: point at the earlier disposition it repeats.

   Never dismiss: security findings, correctness findings touching the merge frontier, findings the rubric cannot classify — escalate those instead. Low-severity findings get fixed or dismissed; they never get debated.
3. Address every non-low finding that survives triage: implement the fix, then hand verification to a different agent — never verify your own fix.
4. **verifier≠author.** The agent verifying a fix is never the agent that wrote it, and it runs on a different model family. **CI green is not a verdict** — green CI plus an unverified fix is an open finding (`orchestrator-verifies`: check the real state, never the summary).
5. Run the Mars-law recheck: sleep `values.md#mars-law.interval`, re-fetch the canonical comment, and stop when the review count is unchanged for `values.md#mars-law.flatten-rounds` consecutive rounds. A flat count means the bot said its piece — move to dispositions, not to more polling.
6. Apply the freeze rule: a dispositioned finding is never re-litigated. When a finding recurs — same code, same complaint — cite the original disposition and move on.
7. **Patch-id staleness.** A rebase or new push voids the current verdict. The verdict survives only when the patch-id is unchanged; otherwise re-verify from step 1.
8. **CI-flake classification ladder.** On a CI failure, trigger exactly one fresh build per `values.md#flake-retry.count`. Never retry a single failed job blind. When the identical failure repeats on the fresh build, reclassify: it is a real failure, not a flake — route it back to step 3.
9. **Merge-frontier discipline.** Standards-repo PRs merge on the human's click only — the babysitter never merges one. pr-reviewer code PRs merge after Oracle APPROVE + green CI. `tf-*` tags are never pushed without explicit approval.
10. **Off-thread coordination.** Only the bot and the human post in PR threads. Dismissals, debates, and coordination live in the Reply disposition report or off-thread — never as thread replies.
11. **Stale-review SHA check.** The review's commit SHA matches the PR head SHA, or the review is stale. On mismatch: freeze or dismiss the review with the SHA evidence — never re-litigate its findings against new code.
12. **One babysitter per PR.** When another babysitter is active on the same PR, stand down and report the collision.
13. **Confident-stop on bot infra failure.** Stop the loop, attach the failure evidence, and report. Never fake a trigger commit to force the bot awake.

## Reply:

```
## Reply: bot-review-loop disposition report

- PR: <repo>#<pr> @ <head SHA>
- Mode: <drive | background | threads-only | check>
- Outcome: merged-by-human | all-dispositioned | confident-stop
- Findings:
  - <finding-id>: fixed — <what changed, commit>
  - <finding-id>: dismissed-with-reason — <rubric class + evidence>
  - <finding-id>: frozen — <original disposition cited>
- Verifier: <agent / model family, different from author>
- CI: <status at verdict time>
- Assumptions: <none | listed>
- Open questions: <none | listed>
```

Every finding id appears exactly once. A confident-stop attaches the bot-failure evidence.
