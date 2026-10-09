# values.md — magic-number SSOT

Every magic number mstack uses lives here as a named entry. Runbooks,
skills, and the hub reference values **by name** (`per
values.md#mars-law.interval`) and never inline a literal. The only
literals allowed are structural ones listed under `## Allowlist`.

Enforcement: `scripts/check-values.sh` fails any file that uses a
magic-looking number not declared here. Values not yet pinned are marked
`TBD (set when the runbook that owns it is written)` — the lint tolerates
explicit TBD markers.

### mars-law.interval
Value: 120
Unit: seconds
Why: Sleep between bot-review re-fetches. Long enough for the reviewer to post, short enough to keep the loop tight.
Used-in: bot-review-loop.md

### mars-law.flatten-rounds
Value: 2
Unit: rounds
Why: Stop the recheck loop when the review count is unchanged for 2 consecutive rounds — the "Mars law" stop condition that ends the loop instead of polling forever.
Used-in: bot-review-loop.md

### heartbeat.interval
Value: TBD (set when the runbook that owns it is written)
Unit: minutes
Why: Fallback wake interval for the overnight orchestrator when no event watcher exists. Sized to when the result is worth re-checking, not to a fixed cadence.
Used-in: overnight-orchestrator.md

### flake-retry.count
Value: 1
Unit: fresh builds
Why: One fresh build on a suspected CI flake, never a blind job retry. An identical second failure reclassifies the failure as real instead of burning more retries.
Used-in: bot-review-loop.md

### eval.run-floor
Value: 5
Unit: interleaved runs
Why: Minimum runs for a trustworthy measurement (median + range). Fewer runs cannot separate signal from run-to-run noise.
Used-in: measurement-eval.md, validate.md

### correct-mining.class-threshold
Value: 2
Unit: occurrences
Why: A mistake class counts when seen twice. One occurrence is an anecdote, not a rule — and not a basis for a new check.
Used-in: correct.md

### audit-tick.interval
Value: TBD (set when the runbook that owns it is written)
Unit: minutes
Why: Supervisor tick that re-reads the runbook and audits the overnight operation for drift. Judges progress by side effects only.
Used-in: overnight-orchestrator.md

### intake-gate.max-question-rounds
Value: 1
Unit: rounds
Why: The hub asks at most one batched round of questions before proceeding. More rounds turn the gate into an interrogation.
Used-in: hub.md

### interrogate.min-reviewers
Value: 2
Unit: independent reviewers
Why: Adversarial review needs at least two independent perspectives (different model families when available). One reviewer is an opinion, not a red team.
Used-in: interrogate.md

### growth-governor.occurrences
Value: 2
Unit: occurrences
Why: A new skill is admitted only when the same failure shows up twice. Guards the skill list against accretion by enthusiasm.
Used-in: references/eval-protocol.md, reflect.md

## Allowlist

Structural literals that are not magic numbers. The lint ignores these;
each carries its reason so the list stays honest.

- "7 runbooks" — the v0.0.1 file count; structural, not a tuned threshold.
- "step 1" (and other step numbers) — document numbering, not a quantity.
- "v0.0.1" — the version string, not a measurement.
- "3 times" — small fixed procedural counts in prose, not tuned thresholds.
