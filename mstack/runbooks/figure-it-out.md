---
name: figure-it-out
description: >
  Use when no runbook matches the goal and the path forward is unknown: an unfamiliar failure with no procedure, a vague "make it work" that needs a designed workflow first, a problem where the fix cannot be attempted until the mechanism is understood.
---

## Exit predicate

The run ends with one of three verdicts — never a pass:

- VERIFIED: the predicate held against the real artifact.
- NOT VERIFIED: the predicate failed against the real artifact.
- INCONCLUSIVE: the evidence cannot decide, and the audit trail shows the loop actually ran.

An INCONCLUSIVE verdict with an empty audit trail is not inconclusive — it is an unstarted run. A VERIFIED claim without unmasked verification is not verified.

## Requires

- A goal the hub could not match to any runbook.
- Permission to design a workflow — this runbook invents the procedure, then follows it.

## Inputs

- `goal`: what needs figuring out, in the operator's words.
- `context`: whatever is known — logs, symptoms, prior attempts.
- `constraints`: what must not break, what is off-limits.

## Steps

1. Frame a falsifiable predicate before any work (`falsifiable-tests`). State what would prove the goal achieved and what would disprove it. No predicate, no work — a goal you cannot falsify is a wish, not a task. Never lead with a theory of the cause (`loop-before-theory`).
2. State assumptions up front (`state-assumptions`). Write down what is taken as given; each assumption is a candidate for the first attack.
3. Design the smallest workflow that could test the predicate. One loop, one artifact, one check — add machinery only when the predicate demands it.
4. Ground the investigation in the system under test. When the workflow touches unfamiliar code or behavior, run the `how` skill's grounding pass first — parallel angles, fixed-section synthesis — so the hypothesis loop starts from observed structure, not guesses.
5. Run the hypothesis loop: predict → run → compare. Each iteration states its prediction before the run, executes against the real artifact, and compares the outcome to the prediction. Log every iteration with its evidence.
6. Attack the premise (`attack-the-premise`). When an iteration surprises, interrogate the predicate and the assumptions before the code — the most expensive bug is a well-tested wrong theory.
7. Keep the audit trail current: every attempt recorded with what was tried, what was observed, and what it ruled out. The trail is append-only; a dead end is a finding, not a failure.
8. **Unmasked verify before any VERIFIED claim.** Check the real artifact — the actual files, the actual behavior, the actual output — per the `prove-it` skill. Never accept the loop's own summary as evidence. `prove-completion` holds: no completion claim without fresh evidence.
9. **Destructive-scope confirmation before any deletion the designed workflow implies.** Destructive scope means deletion or modification of files, records, branches, or any non-fast-forward / history-rewriting operation (`git push --force`, rebase, `git reset --hard`) — named explicitly, never left to the enumeration. This step is the corpus-wide definition: every other "destructive-scope confirmation" in the corpus invokes this meaning. A skill's explicitly licensed deletion criterion is a standing grant exempting that exact scope; anything outside the license invokes this gate. State the exact scope and wait for the human. A scope stated after the deletion is a confession, not a confirmation.
10. Render the verdict. VERIFIED only when the predicate held under unmasked verification; NOT VERIFIED when it failed; INCONCLUSIVE when the evidence cannot decide — with the audit trail attached either way.

## Reply:

```text
- Goal: <the original goal>
- Predicate: <the falsifiable statement tested>
- Verdict: <VERIFIED | NOT VERIFIED | INCONCLUSIVE>
- Attempts:
  - <attempt 1: what was tried, what was observed, what it ruled out>
  - <attempt 2: ...>
- Evidence: <the real artifact checked, and where>
- Assumptions: <what was taken as given, and which ones broke>
```

Every attempt in the Attempts section traces to an audit-trail entry. An INCONCLUSIVE verdict without attempts is not a verdict — it is an admission the loop never ran.
