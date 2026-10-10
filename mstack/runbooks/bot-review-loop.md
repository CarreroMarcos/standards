---
name: bot-review-loop
description: >
  Use when a PR needs a babysitter through bot review: canonical review comments arriving, findings to disposition, recheck-until-flat loops to run, freeze-rule calls to make, or a bot that went quiet mid-loop.
---

## Exit predicate

The run ends when one of these holds, checkable per finding:

- The merge authority merged the PR, or
- every finding in the canonical comment carries exactly one disposition — `fixed`, `dismissed-with-reason`, or `frozen` — and the bot loop is green, or
- a confident-stop is flagged with its evidence attached.

A finding with no disposition keeps the loop open. A confident-stop without evidence is not a stop.

## Requires

- A review bot posting canonical comments carrying a versioned marker, with the marker prefix named in the run's inputs (`marker-prefix`).
- Merge authority named in the run's inputs (`merge-authority`) — the babysitter never merges, whatever the authority is.
- CI that reports per-commit status on the PR.
- Push authorization per the `push-authorization` input — the babysitter never pushes without it.

## Inputs

- `repo`: the repository under review.
- `pr`: the PR number.
- `marker-prefix`: the bot's canonical-comment marker prefix for this run — match the prefix, never the literal; a version bump in the marker must not silently break step 1.
- `merge-authority`: who may merge (human click, gate approval, …). The loop stops at the gate; the babysitter never performs the merge.
- `push-authorization`: whether the babysitter may push fix commits to the PR branch — `standing` (push without asking) or `per-push` (each push waits for the operator). When absent: no pushes — findings are dispositioned and reported, fixes stay local. A PR authored outside the operator's account takes `per-push` regardless of the input. In `background` mode the standing grant is what makes the unattended loop coherent. The grant is fixed at run start, like `mode`; under `per-push` the operator is asked at each push, which is where a mid-run change of mind takes effect.
- `mode`: one of `drive`, `background`, `threads-only`, `check` (see Babysit modes).

## Babysit modes

- `drive`: run the full loop now, reporting at each disposition round.
- `background`: run the loop unattended; emit the Reply report on every exit-predicate state change.
- `threads-only`: watch the PR thread for new canonical comments; take no other action.
- `check`: single pass — poll once, triage once, report. Skip step 5: `skip: single-pass mode runs no recheck loop`.

## Steps

1. Poll the PR thread for the latest comment carrying the run's `marker-prefix` — any version counts; the newest one is canonical and older ones are history. (Match the prefix, never the literal: a version bump in the marker must not silently break this step.) When the bot errors repeatedly, emits stale reviews, or stops posting canonical comments, go to step 13.
2. Triage every finding against the shared dismissal rubric — skeptical by default. Read the cited code before judging the finding (`loop-before-theory`); match triage depth to finding severity (`scale-ceremony`).

   **Shared dismissal rubric.** Dismiss a finding only with evidence attached:
   - False positive: quote the code that proves the finding wrong.
   - Out of scope: name the scope boundary the finding crosses.
   - Duplicate: point at the earlier disposition it repeats.

   Never dismiss: security findings, correctness findings touching the merge frontier, findings the rubric cannot classify — escalate those instead. Low-severity findings get fixed or dismissed; they never get debated.

   **Disposition ledger.** Every disposition lands in `.mstack/dispositions/<repo>-<pr>.md` — append-only, written at disposition time (steps 2, 6, 7), never at Reply time. `<repo>` is slugified: lowercase, `/` → `-`, other non-alphanumeric → `-`. A repo name that doesn't survive slugifying, or two repos colliding on one slug, parks the run with the ledger path named in the `parked:` note. On first write, create the parent directory and the header row if absent (`| finding-id | verdict | evidence | patch-id | supersedes |`); if creation fails, park with the ledger path named in the note — never proceed without the ledger. `finding-id` is minted at first triage: `F` + short hash of the finding's canonical anchor (file path + check/rule name + finding title as posted in the canonical comment), immutable once assigned — the ledger is the source of truth. A resumed session matches each canonical-comment finding against ledger anchors and reuses the existing id; only genuinely new findings get new ids. Re-triaged findings (after frozen lapse) keep their original id under a new superseding entry. One entry per disposition: finding-id, verdict (`fixed` / `dismissed-with-reason` / `frozen`), evidence pointer, patch-id at verdict time, `supersedes` pointer (empty unless this entry voids an earlier one). Every verdict row's patch-id names the exact pushed head the verdict was verified against, so the push trail is reconstructable from the ledger; a superseding entry names the new head. A voided verdict (step 7) gets a new entry with a `supersedes:` pointer to the old one — supersede, never rewrite. The exit predicate reads "exactly one *unsuperseded* entry per finding." `frozen` entries record the patch-id at freeze time for provenance, but step 7's staleness check does not apply to them — a frozen entry survives rebase by citing the ledger. A `frozen` entry lapses when its cited code no longer exists at the evidence pointer: the entry stays as history, but a finding about refactored or rewritten code is re-triaged as new. Freeze means "not actionable on this code," not permanent immunity. Every verdict mutation, for any reason, is a new entry with a `supersedes:` pointer; entries are never edited. The `parked:` note names this file's path when the run parks.
3. Address every non-low finding that survives triage: implement the fix, push the commit to the PR branch when the run's `push-authorization` grants it — when the input is absent, fixes stay local and are reported, never pushed — then hand verification to a different agent — never verify your own fix.
4. **verifier≠author.** The agent verifying a fix is never the agent that wrote it, and it runs on a different model family. **CI green is not a verdict** — green CI plus an unverified fix is an open finding (`orchestrator-verifies`: check the real state, never the summary).
5. Run the Mars-law recheck: sleep `values.md#mars-law.interval`, re-fetch the canonical comment, and stop when the review count is unchanged for `values.md#mars-law.flatten-rounds` consecutive rounds. A flat count means the bot said its piece — move to dispositions, not to more polling.
6. Apply the freeze rule: a dispositioned finding is never re-litigated. When a finding recurs — same code, same complaint — cite the original disposition from the ledger and move on.
7. **Patch-id staleness.** A rebase or new push voids the current verdict. The verdict survives only when the patch-id is unchanged; otherwise re-verify from step 1 and record the new verdict as a superseding ledger entry.
8. **CI-flake classification ladder.** On a CI failure, trigger exactly one fresh build per `values.md#flake-retry.count`. Never retry a single failed job blind. When the identical failure repeats on the fresh build, reclassify: it is a real failure, not a flake — route it back to step 3.
9. **Merge-frontier discipline.** The babysitter never merges. Merge authority is named per-run via the `merge-authority` input — human click, gate approval, some other bar. The loop's job ends at the gate; whatever the authority is, the babysitter does not perform it.
10. **Off-thread coordination.** Only the bot and the human post in PR threads. Dismissals, debates, and coordination live in the Reply disposition report or off-thread — never as thread replies.
11. **Stale-review SHA check.** The review's commit SHA matches the PR head SHA, or the review is stale. On mismatch: freeze or dismiss the review with the SHA evidence — never re-litigate its findings against new code.
12. **One babysitter per PR.** When another babysitter is active on the same PR, stand down and report the collision.
13. **Confident-stop on bot infra failure.** Stop the loop, attach the failure evidence, and report. Never fake a trigger commit to force the bot awake.

## Worked example — one operator's setup

His review bot posts canonical comments marked `<!-- pr-reviewer:canonical:v1 -->`, `v2`, … — so `marker-prefix` is `pr-reviewer:canonical:v` for runs against that bot. His merge policy: standards-repo PRs merge on his click only; pr-reviewer code PRs merge after his adversarial Oracle gate's APPROVE plus green CI; `tf-*` deploy tags are never pushed without his explicit approval.

## Reply:

```
## Reply: bot-review-loop disposition report

- PR: <repo>#<pr> @ <head SHA>
- Mode: <drive | background | threads-only | check>
- Outcome: merged | all-dispositioned | confident-stop
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
