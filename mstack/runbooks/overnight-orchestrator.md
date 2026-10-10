---
name: overnight-orchestrator
description: >
  Use when a goal needs to run unattended over hours: wake-on-event loops to
  arm, work to dispatch, drift audits to run, and a morning handoff to produce.
  A thin wrapper — the execution machinery (briefs, lanes, gates, state) lives
  in the deep-work runbook.
---

## Exit predicate

The run ends on one of these — never a relaxed version of them:

- the run's declared acceptance state(s), or
- a dead-end write-up documenting what was tried, what failed, and why the run stops.

A predicate bent to fit the run is not an exit. When the run cannot reach either state, it parks with a pause-safely resume note and says so in the Reply (`loop-contract-first`: the contract is fixed before the loop runs).

## Requires

- The deep-work runbook — this file is a thin wrapper. Briefs, lanes, the Grill intake, phase gates, and the run state directory are deep-work's machinery; none of it is re-specified here.
- A persistent execution environment — the run must survive the operator disconnecting.
- `values.md` for every tunable below — no inline numbers.
- `principles-distilled.md` for the steering vocabulary.

## Inputs

- `goal`: the objective plus its checkable done-condition.
- `timebox`: how long the run may continue before it must report.
- `holds`: what stops the run — merge authority, destructive scope, anything the operator must decide.

## Steps

1. **Decide unattended vs attended before anything else.**
   - **Unattended** when the goal decomposes into verifiable lanes, the gates are checkable without judgment, the timebox spans hours, and the operator will be away. The exit predicate and holds must be airtight — no one is there to adjudicate.
   - **Attended** when checkpoints need judgment, holds are ambiguous, or the run is short enough that supervision is cheap. The machinery is identical; only the escalation latency changes.
2. State the exit predicate from `goal` before any work starts. Write it down; never relax it.
3. Dispatch per the deep-work runbook: decompose into lanes, run the Grill intake per lane, pilot-before-fanout, phase gates. Brief each lane's forbidden actions from the run's holds. This step delegates the whole delegation machinery; the orchestrator here adds only the unattended concerns below.
4. Arm the wake design for every wait on an external condition (`HARNESS.md` §2): the event-watcher arm where the harness exposes one, and the heartbeat arm — re-checking the condition every `values.md#heartbeat.interval`, each tick logged, so a stalled loop is distinguishable from a quiet one. The heartbeat is the portable baseline; the watcher is an optimization.
5. Run the audit tick every `values.md#audit-tick.interval`: re-read this runbook, then audit the run for drift — predicate still intact, holds still held, decision log current. A drifted run pauses until the drift is corrected.
6. Hold per-iteration decision-log checkpoints: after each unit, append what was decided, what was tried, and what the evidence showed, using the `show-work` skill's log format. The log is the run's memory; a new session resumes from the log, never from recollection (`recorded-decisions`).
7. Retry by mode, never by hope:

   | Failure mode | Retry rule |
   |---|---|
   | Worker stall | Probe once; on continued silence, kill and respawn with narrowed scope. |
   | External-service failure | Confident-stop per that loop's contract — stop and report; never fake a trigger to keep the loop alive. |
   | Build flake | Exactly one fresh build per `values.md#flake-retry.count`; an identical second failure is a real failure, routed back to the lane. |
   | Merge conflict on rebase | Pause-safely and report in the handoff. |
   | Gate HOLD | Address the cited evidence and re-enter the gate; never re-litigate a frozen finding. |

8. Split every escalation by who it reaches. **Reaches the human:** merge decisions, destructive scope, external-gate verdicts, confident-stops, dead-end write-ups, operator stops. **Never reaches the human:** routine retries inside the table above, re-polling, checkpoint logging, audit ticks, worker respawns — all logged in the decision log and surfaced in the morning handoff.
9. **Freeze rule.** A dispositioned finding is never re-litigated — cite the original disposition and move on.
10. **Unmasked verify.** Verify against the real state — actual files, actual test output — never an agent's summary (`orchestrator-verifies`, `prove-completion`: no completion claim without fresh, discriminating evidence).
11. **Destructive-scope confirmation.** State the deletion scope explicitly and wait for the human before any deletion.
12. **Operator-stop path.** On operator stop: issue the zero-writes order (no new commits, no new pushes), pause-safely, cut a work-in-progress commit, and report the resume state. The run resumes from the decision log.

## Pause-safely

Pause-safely produces the resume note — the contract a new session needs to pick up the run without recollection. It answers, in this order:

- **Where:** the working state — repo, branch, and head when the run works a repo; the run directory slug always.
- **Contract:** the exit predicate, quoted verbatim — the next session re-commits to the same predicate.
- **Lanes:** one line each — complete / open / dead-ended.
- **Next:** the single most useful next action, concrete.
- **Blocked on:** the holds waiting for the human.

A resume note missing any of these is incomplete — the next session reconstructs nothing from memory.

## Reply:

```
## Reply: morning handoff

- Goal: <goal> — exit predicate: <met | dead-end | parked>
- Working state: <repo, branch, head — when the run works a repo> + run directory slug
- Lanes: <n> complete / <n> open / <n> dead-ended
- Gate: <pass | findings-routed | pass-with-caveat — caveat named | residual-risk recorded>
- Deliverables: <paths, each re-read from disk>
- Holds: <each blocking hold — pass/fail + the evidence that decided it>
- Discoveries: <mid-run surprises + their disposition>
- Residual risks: <accepted risks + who accepted them>
- Escalations: <what reached the human overnight and why>
- Resume: <pause-safely resume note | nothing to resume>
- Assumptions: <none | listed>
```

Every claim carries its evidence or is flagged red. A handoff without evidence is a rumor, not a report.
