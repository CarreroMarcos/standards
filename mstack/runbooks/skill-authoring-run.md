---
name: skill-authoring-run
description: >
  Use when a skill draft needs to earn its place: a technique that might be a reference section in disguise, a draft needing the RED-GREEN-REFACTOR verification loop, trigger probes to run, or a pass-or-kill verdict to deliver.
---

## Exit predicate

The run ends when one of these holds — no third outcome:

- The skill passes both stages of `references/eval-protocol.md` and ships, or
- the skill is killed with written reasons.

A skill that "mostly works" is not a pass. A kill without written reasons is not a kill.

## Requires

- A skill draft: a named technique or reference under test.
- A playground target: a scratch repo or prompt set where the skill fires without side effects.
- The eval protocol at `references/eval-protocol.md`.

## Inputs

- `skill`: the draft skill's name (kebab-case).
- `source`: the material the draft was mined from (session notes, failure log, Backlog entries).
- `triggers`: the 3–5 trigger-shaped prompts the skill must fire on.

## Steps

1. State the skill's type claim up front: technique (changes behavior under pressure) or reference (informs lookup). Write it down. Step 6 tests this claim.
2. RED: write the failing check first. A trigger probe the draft must fail today — a prompt shaped like a trigger where the desired behavior is missing, or a verification the draft cannot yet perform. No draft text changes until the RED probe exists and fails.
3. GREEN: make the smallest draft change that turns the RED probe green. One behavior per change. When the probe passes for the wrong reason, the probe is the defect — fix the probe, not the draft.
4. REFACTOR with the per-paragraph razor: every paragraph earns its place or is cut. A paragraph stays only when removing it changes what an agent does under pressure. Cut the rest.
5. Run the trigger probes: fire the skill on 3–5 trigger-shaped prompts and check it does its job each time. Then run the neighbor regression check: prompts shaped like neighboring skills' triggers still fire the right skill. A probe that passes on the draft but fails on a clean prompt is a prompt-tuned probe — rewrite it.
6. **Technique-vs-reference kill decision.** When the draft claims technique but the content is lookup material — traps, gotchas, tables, things to know — the technique dies. Kill it with the written reason, rebuild as a reference skill, and restart this run at step 1 on the rebuild. A technique that wants to be a reference section is not a technique with extra steps.
7. Measure the token cost: load the skill and record its token cost. The core stays cheap — record the number in the Reply so the cost is visible, and cut when the cost buys nothing.
8. Run the blinded eval per the `validate` skill before promoting: the evaluator does not know which draft it judges. An unblinded pass is theater, not evidence.
9. **Verify against the real artifact per the `prove-it` skill.** Exercise the skill on the real target — a real repo, a real prompt — never a proxy, a mock, or the author's own summary. Evidence must discriminate: a check that cannot fail does not count.
10. Run the eval protocol's two stages: Stage 1 (trigger-probe execution at no fewer than `values.md#eval.run-floor` interleaved runs, plus the four audits — bold-skeleton, hedge grep, check-values.sh, check-refs.sh); Stage 2 (one real low-stakes run of the skill). Both stages green, or the skill never ships.
11. **Unmasked verify before any pass claim.** The pass verdict rests on the real state — actual probe outputs, actual audit results — never the author's summary of them.
12. **Byte-identical copies for portable skills.** The workspace source and the repo copy stay byte-identical. Drift between the two is a defect in the run, not in the skill.
13. **Never edit a skill mid-task.** When the skill is broken, stop this run and give it its own fix PR. Editing the skill to make the run pass falsifies the run.

## Reply:

```
## Reply: skill-authoring-run verdict

- Skill: <name> (technique | reference)
- Verdict: PASS | KILL
- Type claim: <as stated in step 1> → upheld | overturned
- RED probe: <the failing check and its failure>
- Trigger probes: <each prompt, pass/fail>
- Neighbor regression: <pass | fail — details>
- Token cost: <tokens to load the core>
- Blinded eval: <per `validate` — pass | fail>
- Real-artifact check: <per `prove-it` — pass | fail>
- Eval protocol: <Stage 1 pass | Stage 2 pass>
- Kill reasons: <none | the written reasons>
- Assumptions: <none | listed>
```

A KILL names the step that killed it and the reason, one sentence each. A PASS with any audit red is not a pass.
