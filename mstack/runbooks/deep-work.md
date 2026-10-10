---
name: deep-work
description: >
  Use when substantial work needs doing through delegated subagents: brief fixers,
  verify their output against real state, adversarially review it — pinned to a
  different model family when the harness supports per-subagent pinning — and
  reconcile the results. Harness-neutral — any codebase, any harness with subagents.
---

## Exit predicate

The run ends when every lane's artifact is verified against real state, the
adversarial gate has passed or its residual risk is recorded and accepted, and
the state directory is tombstoned. A lane no one verified is not done — it is
open, no matter what its worker reported.

## Requires

- A harness that can spawn subagents (`HARNESS.md` §1 translates the verbs below). When the harness cannot, the no-subagent degradation rule applies — the run still works, with roles played as separate passes.
- `values.md` for every tunable below — no inline numbers.
- `principles-distilled.md` for the steering vocabulary.

## Inputs

- **Goal** — the objective plus its checkable done-condition. A duration is not a finish condition.
- **Lanes** — the units of work, or nothing: the orchestrator decomposes the goal into lanes when none are given.
- **Model constraints** — which model families the harness offers. Stated as constraints ("adversary differs from fixer"), never as slugs.
- **Holds** — what stops the run: merge authority, destructive scope, anything the operator must decide.

## The contract

**The orchestrator is a scheduler, not a worker.** It plans, dispatches, and reconciles — it never implements. When the orchestrator catches itself writing the fix, it stops and briefs a fixer instead (`least-agency`: deterministic dispatch decides deterministic things; the orchestrator's judgment is spent on routing, not doing).

Bad: the orchestrator notices a typo in the fixer's diff and corrects it inline.
Good: the orchestrator re-briefs the fixer with the typo location and the acceptance check, and the verifier confirms the correction.

## Roles

Every delegated role is a triple: what it does, what it may do, and when to use it. Permissions are explicit — who may spawn and who may not is a rule, not a convention. A role that never spawns keeps delegation trees bounded.

### fixer

**Job:** takes a brief, produces a diff plus a rerunnable check. Headless mechanical implementation.

**Hard constraints:** never verifies its own work. Never spawns subagents. Runs only the validation the orchestrator assigns — never broadens it. Reports validation results and skips accurately, with reasons for every skip. Does not act as a reviewer.

**Permissions:** write to the lane's working files. May-not-spawn.

**Delegate when:** the work is mechanical implementation against a clear brief.

**Don't delegate when:** explaining the task to the fixer costs more than doing it directly, or the work is tightly integrated with the orchestrator's current context.

**Rule of thumb:** can the brief stand alone, read cold? → fixer.

### verifier

**Job:** runs the fixer's check against real state and reports what the state showed.

**Hard constraints:** never trusts the fixer's summary. States the check's falsification condition — "what observable outcome would make this check fail?" — *before* running it. A verifier that cannot state the condition does not run the check (`falsifiable-tests`: a check that cannot fail does not count). Every must-not-flag probe carries a paired must-flag twin — one must-flag case per must-not-flag case; silence proves cleanliness only when the twin proves the instrument still fires. A verification whose negative probes lack twins is an unstated falsification condition: the verifier does not run it — it goes back for a fix to the brief.

**Permissions:** read and execute checks. Never modifies the artifact under review. May-not-spawn.

**Delegate when:** a fixer's output needs independent confirmation against real state.

**Don't delegate when:** the check is trivially observable by the orchestrator in one read.

**Rule of thumb:** the fixer says "done" — the verifier asks "prove it," against the files, never the report (`orchestrator-verifies`, `prove-completion`).

Bad: verifier runs the fixer's test script, sees green, reports "verified."
Good: verifier states "this check fails if the migration leaves orphans — I will count orphans before and after," then runs it and reports the counts.

### adversary

**Job:** attacks the fix's reasoning, not its output. Finds what friendly review would miss.

**Hard constraints:** read-only — advises, never implements (`model-proposes-never-authorizes`). Acknowledges uncertainty when present. Prefers simpler designs unless complexity clearly earns its keep. Model family: when the harness supports pinning a model per subagent, pin the adversary to a model family different from the fixer's. When it does not, spawn the adversary as one of the harness's general subagents and log `caveat: single-family-adversary` on the gate verdict — never silent. A "no findings" report is valid only with stated coverage.

**Permissions:** read-only. May-not-spawn.

**Delegate when:** the change carries judgment calls, a fix survived two failed attempts, or the blast radius is wide.

**Don't delegate when:** the change is mechanical with no judgment calls — the verifier suffices.

**Rule of thumb:** would a smart skeptic change this decision? → adversary.

### researcher

**Job:** answers one bounded question with evidence, grounding the lane before implementation.

**Hard constraints:** reports findings with sources — never recommendations disguised as findings. Timeboxed by the lane's brief; a researcher that keeps digging past the question is re-briefed or recalled.

**Permissions:** read-only. May-not-spawn.

**Delegate when:** the lane needs grounding — unknown APIs, unfamiliar code, unclear constraints.

**Don't delegate when:** the orchestrator already holds the facts.

**Rule of thumb:** "I need to know X before deciding" → researcher.

### synthesizer

**Job:** merges competing outputs for one brief — chooses the best approach, grafts what ports, and improves on it. Reports consensus level, agreed points, disagreements with their resolution, and remaining uncertainty. Notes failed or timed-out lanes instead of omitting them.

**Hard constraints:** never pastes mechanically. "Don't just average responses — choose the best approach and improve upon it."

**Permissions:** write to the synthesis output. May-not-spawn.

**Delegate when:** two or more fixers produced competing outputs for the same brief.

**Don't delegate when:** a single lane produced the output — the orchestrator reconciles directly.

**Rule of thumb:** multiple candidates, one brief → synthesizer picks, grafts, and improves.

## State

All run state lives in a run-scoped directory the operator names — never a fixed dot-path. When the operator names no directory, use `.mstack/runs/<slug>/` derived from the goal, log it as an assumption, and surface it in the Reply. Three tiers, each with one address:

- **Pinned head** (≤ `values.md#deep-work.head-lines` lines): `status:`, `task:`, `slug:`, `phase:`, `next:`, `blockers:` — one line each. `files:` — one-line index of the run directory's artifacts (progress, ledger, gate records). `token:` — a fresh `resume-token`, unique per park, written here and into the `parked:` note whenever the run parks; a resume note without the matching token is unverified. The orchestrator keeps this current; it is the first thing read on resume.
- **Progress file** (≤ `values.md#deep-work.progress-lines` lines, rewritten in place, never appended): status, open items, one-line verdicts per lane, pointers to topic files. Mid-run, on any conflict between state shapes, the progress file wins. At resume, the gate record wins for dispositions — a disposition is what the gate that made it recorded, and a re-review appends a new entry to the same gate-record file, never by rewriting the old entry; for lane and status state, the progress file still wins.
- **Topic files:** full lane outputs, verbatim. Full analyses live here — never in the progress file, never in chat.

**Instrumentation ledger.** One TSV in the run directory, one row per dispatch, lane completion, gate, and recovery — written by the orchestrator, never by workers. Dispatch rows carry t_start; the row that closes an interval carries t_end (lane completion, gate close, kill or respawn, contention events with an opening row, tombstone/report); tokens and cost land on completion rows when the harness exposes usage, else literally n/a — named as unobserved, never blank. Timebox evidence is t_end − t_start against the brief's timebox; a lane that cannot show its wall-clock cannot claim it stayed in budget.

A restored or superseded state file carries its correction in place — one line at the top: NOTE: superseded, see <incident record> — and the named record must exist in the run's evidence; a NOTE that names nothing is itself a finding. The correction lives in the incident record; the pointer just makes it findable from the scene.

**Resume chain:** on resume or after compaction, read one chain, one file per hop — the pinned head, then the progress file its `slug:` points to, then the run's gate record, then the topic files its pointers reference. Nothing else. Bounded recovery by construction. The pinned head is a cache of the progress file: if they disagree, the progress file is current — no mtime forensics, and a torn update heals on the next orchestrator write.

## The Grill — per-lane intake

Before dispatching any lane, answer all seven. A lane dispatched without a Grill is an unbriefed worker — recall it and grill it.

1. **Goal:** what is this lane trying to accomplish?
2. **Success criteria:** how do we know the lane succeeded — stated as observable state, not effort?
3. **Success type:** one of `test`, `build`, `lint`, `command`, `file-exists`, `review`, `manual`. Named up front, never inferred after the fact.
4. **Execute role:** usually `fixer`.
5. **Verify role:** named separately from the execute role — usually `verifier`, `adversary` for judgment-heavy lanes.
6. **Max attempts:** `values.md#deep-work.lane-max-attempts`.
7. **Context files:** what the lane must read before starting.

**Escalation:** every lane names its escalation path before iteration one — what reaches the human, and on what trigger. Manual gates never auto-resolve: a gate waiting on a human stays waiting until the human answers (`loop-contract-first`: the contract is fixed before the loop runs).

## Dispatch

1. Brief one lane per worker with the lane brief template — goal, scope, context, acceptance, the exact verification, timebox, forbidden actions, report shape, standing rules. A brief with a blank field goes back for a rewrite.
2. **Pilot before fan-out.** Run one lane through the whole path first when the brief shape is novel. When the pilot stalls on an unclear field, fix the brief — never the worker.
3. Probe worker liveness on a cadence tighter than the lane's timebox. A worker with no output and no state change across a full probe window is dead: kill it and respawn fresh with the same brief — never inherit a dead session's confusion. On continued silence after respawn, narrow the scope before the next attempt. Record every probe verdict as a per-lane status line in the progress file — one slot per lane, current verdict only, overwritten in place (running / silent / dead), never a log. On resume, a lane with a dispatch record and no completion record is dead — the resumer does not consult anyone's narrative about it.
4. Retry by mode, never by hope: stall → probe, respawn with the same brief, then narrow on continued silence; flake → exactly one fresh attempt, then the failure is real; conflict → pause and report, never force through. A finding already dispositioned is never re-litigated.
5. When a lane surfaces a mid-run discovery, the discovering lane owns it: scope the surprise, report it at the next checkpoint, hold scope steady until the orchestrator re-briefs. Discoveries never silently expand the run.

## Lane completion

A lane is complete only when the orchestrator re-reads the artifact from disk and finds its first line — and that first line IS the lane's one-line conclusion. Reading the worker's report is not completion; reading the artifact is (`prove-completion`: no completion claim without fresh evidence). A dead lane's output is completed by nobody: on resume the resumer records only what the checks showed, on the run's verification and gate artifacts, marked resumed-by <context> — the resumer verifies, never authors the lane's output.

**Fixer output contract** — every fixer report carries all three, in order:

- `<summary>` — what was done, in two sentences or fewer.
- `<changes>` — file: description, one per changed file.
- `<verification>` — what was run, what resulted, and every skip named with its reason. A skip without a reason is an open item, not a pass.

When a dead lane's checks are scripted and cheap — re-runnable in one command by the resumer — the resumer runs them, falsification condition stated first, instead of re-dispatching a worker to roll the mortality dice again; this is the scheduler verifying, not implementing. When the same context both runs the checks and reviews the gate, the verdict carries caveat: resume-verifier-equals-reviewer — never silent. The twin requirement applies to resumed verification too: a re-run whose negative probes lack twins does not count until the resumer supplies the twin or records its absence as a caveat on the verdict.

## Phase gates

A gate is mandatory after each phase. The gate prompt carries: the phase goal, the changed paths, the validation evidence, the specific decision or risk under review, and the attempt counter (`Gate 2 — review attempt 2 of 3`). Each gate's decision lands in the run's gate record — a file in the run directory, one entry appended at gate close: verdict, evidence, caveats.

- The grounding gate's record pins the run's expected end-state as a literal falsifiable expectation — exit 0, or exit 1 with exactly these findings, or the done-check's literal equivalent — and every later gate and the final verdict check against that pin. A pin that narrows or contradicts the operator's done-check goes back to the operator — a gate decision re-scopes the run only within the done-check's frame. Changing the pin is a new gate decision, never a quiet edit.
- At most `values.md#deep-work.gate-rereview-budget` re-reviews per gate. Re-review only when remediation materially changes the reviewed decision — never to reopen accepted, unchanged, or resolved concerns.
- Budget exhausted → record the remaining risk in the progress file and ask the operator: accept the risk, change the scope, or authorize one exceptional additional review. The gate never auto-passes on an empty budget. The operator's call is pinned in the progress file and executed, never re-litigated (`recorded-decisions`).

## The adversarial gate

This gate is one adversary with independent context; it is not the interrogate protocol. If a lane invokes the interrogate skill, interrogate's `min-reviewers = 2` bar governs that review.

After the fixer lanes verify clean, the adversary reviews the work — not the workers. The gate verdict carries one of: pass, findings (routed back to a fixer lane with the evidence), or pass-with-caveat (caveat named on the verdict, e.g. `single-family-adversary`).

- **Same-model collapse.** When the harness supports per-subagent model pinning, the adversary is pinned to a model family different from the fixer's. When it does not, the adversary runs as a general subagent — independent context, possibly the same family — and the verdict carries `caveat: single-family-adversary`. A silent single-family gate is a failed gate.
- **Brief drift.** Covered by pilot-before-fanout above: novel brief shapes prove themselves on one lane before the rest.
- **Verifier theater.** Covered by the falsification-condition rule above: no stated condition, no check run.
- **Adversary sycophancy.** An adversary's "no findings" is valid only with stated coverage — "I attacked X, Y, and Z; found nothing." A coverageless "looks good" is treated as a failed gate, not a pass, and the lane goes back with a coverage demand.
- **No-subagent degradation.** On a harness without subagents, the operator — or a single agent — plays each role as a separate pass: brief, implement, verify, attack, reconcile. Role separation is enforced by the passes, not by agents. State the degradation in the progress file; never assume subagents exist.

Bad: adversary reports "Reviewed the diff. Looks good." → gate passes.
Good: adversary reports "Attacked the error paths and the migration ordering; the retry logic has no jitter — finding, with file:line. Coverage: error paths, ordering, concurrency; did not cover perf." → finding routed to a fixer lane.

## Tombstone

On completion, rewrite the progress file into ≤ `values.md#deep-work.tombstone-lines` lines: `status: completed`, the final conclusion, deliverable pointers, surviving constraints, the date. A finished run directory is read by nothing and is kept by default — retention is the lifecycle, not deletion. A finished directory is pruned only with destructive-scope confirmation: state the exact scope — the run directory's actual path (`.mstack/runs/<slug>/` only when the operator named no directory, per ## State) — and its completion date from the tombstone, and wait for the human. No run deletes its own or a prior run's directory during normal execution. The license covers only the stated directory — nothing outside its path. A scope stated after the deletion is a confession, not a confirmation.

## Reply:

```
## Reply: deep-work handoff

- Goal: <goal> — exit predicate: <met | parked>
- Lanes: <n> complete / <n> open / <n> dead-ended
- Gate: <pass | findings-routed | pass-with-caveat — caveat named | residual-risk recorded>
- Deliverables: <paths, each re-read from disk>
- Holds: <each blocking hold — pass/fail + the evidence that decided it>
- Discoveries: <mid-run surprises + their disposition>
- Residual risks: <accepted risks + who accepted them>
- Assumptions: <none | listed>
```

Every claim carries its evidence or is flagged red. A handoff without evidence is a rumor, not a report.
