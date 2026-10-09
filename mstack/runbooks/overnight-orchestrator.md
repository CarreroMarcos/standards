---
name: overnight-orchestrator
description: Use when a goal needs to run overnight on the headless host: spec-to-Oracle cycles to drive, workers to brief and liveness-probe, wake-on-event loops to arm, audit ticks to run, or a morning handoff report to produce.
---

## Exit predicate

The run ends when one of these holds — never a relaxed version of them:

- Oracle APPROVE plus green CI on the final diff, or
- a dead-end write-up documenting what was tried, what failed, and why the run stops.

A predicate bent to fit the run is not an exit. When the run cannot reach either state, it parks with a pause-safely resume note and says so in the Reply.

## Requires

- A headless host with tmux (the run survives disconnects).
- A spec → implement → bot-review → Oracle-gate pipeline.
- The push binding (`HARNESS.md` §5 — "push via the harness binding," never a literal command).
- A human merge gate: the orchestrator never merges.

## Inputs

- `goal`: the objective plus its checkable done-condition.
- `repo`: the repository under work.
- `branch`: the dated branch for the run.
- `timebox`: how long the run may continue before it must report.

## Steps

1. State the exit predicate from `goal` before any work starts. Write it down; never relax it (`loop-contract-first`: the contract is fixed before the loop runs).
2. Break the goal into units and brief one worker per unit with the worker brief template (all nine fields filled — a brief with a blank field goes back for a rewrite):

   **Worker brief template.**
   - GOAL: the objective and its checkable done-condition.
   - SCOPE: what is in bounds and what is out.
   - CONTEXT: repo, branch, and the prior state the worker inherits.
   - ACCEPTANCE: how the orchestrator verifies the work — against real state, never the worker's summary.
   - VERIFY: the exact commands or checks that prove done.
   - TIMEBOX: how long before the worker reports back regardless of progress.
   - FORBIDDEN: actions the worker never takes — merging, pushing `tf-*` tags, posting in PR threads, hand-editing Jira.
   - REPORT: the shape of the worker's report back.
   - STANDING: the standing rules that always apply — the holds below, the freeze rule, off-thread coordination.

3. Run one unit through the whole path before fanning out (pilot-before-fanout). The pilot falsifies the brief template: when the pilot worker stalls on an unclear field, fix the template, not the worker.
4. Drive the spec → implement → bot-review → Oracle-gate cycle per unit. Implement the smallest change that could falsify the current hypothesis; discard what didn't help instead of accumulating it.
5. Arm the wake design for every wait on an external condition (`HARNESS.md` §2): the event-watcher arm where the harness exposes one, and the heartbeat arm — re-checking the condition every `values.md#heartbeat.interval` with each tick logged, so a stalled loop is distinguishable from a quiet one. The heartbeat is the portable baseline; the watcher is an optimization.
6. Run the audit tick every `values.md#audit-tick.interval`: re-read this runbook, then audit the run for drift — predicate still intact, holds still held, decision log current. A drifted run pauses until the drift is corrected.
7. Hold per-iteration decision-log checkpoints: after each unit, append what was decided, what was tried, and what the evidence showed, using the `show-work` skill's log format. The log is the run's memory; a new session resumes from the log, never from recollection (`recorded-decisions`).
8. Probe worker liveness on a cadence tighter than the worker's TIMEBOX. A worker with no output and no state change across a full probe window is dead: kill it and respawn fresh with the same brief — never inherit a dead session's confusion.
9. Retry by mode, never by hope:

   | Failure mode | Retry rule |
   |---|---|
   | Worker stall | Probe once; on continued silence, kill and respawn with narrowed scope. |
   | Bot review infra failure | Confident-stop per the bot-review loop — stop and report; never fake a trigger commit. |
   | CI flake | Exactly one fresh build per `values.md#flake-retry.count`; an identical second failure is a real failure, routed back to the worker. |
   | Merge conflict on rebase | Pause-safely and report in the handoff — never force-push. |
   | Oracle HOLD | Address the cited evidence and re-enter the gate; never re-litigate a frozen finding. |

10. Split every escalation by who it reaches. **Reaches the human:** merge decisions, `tf-*` tag pushes, destructive scope, Oracle verdicts, confident-stops, dead-end write-ups, operator stops. **Never reaches the human:** routine retries inside the table above, re-polling, checkpoint logging, audit ticks, worker respawns — all logged in the decision log and surfaced in the morning handoff.
11. When a worker surfaces a mid-run discovery, the discovering worker owns it: scope the surprise, report it at the next decision-log checkpoint, and hold scope steady until the orchestrator re-briefs. Discoveries never silently expand the run.
12. **Oracle gate before merge.** No code merges without Oracle APPROVE plus green CI on the final diff.
13. **Freeze rule.** A dispositioned finding is never re-litigated — cite the original disposition and move on.
14. **Unmasked verify.** Verify against the real state — actual files, actual test output — never an agent's summary (`orchestrator-verifies`, `prove-completion`: no completion claim without fresh, discriminating evidence).
15. **Destructive-scope confirmation.** State the deletion scope explicitly and wait for the human before any deletion.
16. **`tf-*` tags.** Never pushed without the human's explicit approval — pushing one auto-applies.
17. **Dated branch + PR, never direct to main.** Standards-repo PRs merge on the human's click only.
18. Jira is a projection of the run's task list — the task list is the source of truth. Never hand-edit Jira; when they disagree, fix the projection, not the list.
19. **Operator-stop path.** On operator stop: attach to the tmux session, issue the zero-writes order (no new commits, no new pushes), pause-safely, cut a wip commit, and report the resume state. The run resumes from the decision log.

## Reply:

```
## Reply: overnight-orchestrator morning handoff

- Goal: <goal> — exit predicate: <met | dead-end | parked>
- Branch: <branch> @ <head SHA>
- Units: <n> complete / <n> open / <n> dead-ended
- Oracle: <APPROVE | HOLD — evidence cited | not reached>
- CI: <status at handoff time>
- Holds: <each blocking hold — pass/fail + the evidence that decided it>
- Discoveries: <mid-run surprises + their disposition>
- Escalations: <what reached the human and why>
- Resume: <pause-safely state | nothing to resume>
- Assumptions: <none | listed>
```

Every claim carries its evidence or is flagged red. A handoff without evidence is a rumor, not a report.
