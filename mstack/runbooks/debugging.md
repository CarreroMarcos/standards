---
name: debugging
description: >
  Use when something is broken and the cause is unknown: build a red-capable repro before any theorizing, isolate by bisection, fix smallest, verify against real state — with a two-failures stop rule and an honest environmental verdict.
---

## Exit predicate

The run ends with one of these — never a softer version:

- **Fixed:** the repro goes green on the final diff, the adjacent tests pass, and the root cause is named with evidence; or
- **Environmental verdict:** the investigation log shows the discipline below was run, the handling the cause calls for is implemented, and monitoring is in place so the next occurrence arrives with evidence; or
- **Not reproduced:** the repro attempts are recorded, what was ruled out is stated, and the evidence that would reopen the case is named.

Never: "fixed" without the repro going green. Never an environmental verdict without the loop — a cause declared environmental before the hypotheses are falsified is incomplete investigation, not a verdict.

## Requires

- The broken thing, runnable on demand: a command, a test suite, a service you can start. Debugging what you cannot run is theorizing.
- A way to observe the symptom directly: exit codes, logs, output. Never a secondhand description of the failure.
- A way to run the code with and without the fix: version control, or a copy of the tree. Verification needs both sides.

## Inputs

- `symptom`: the exact failure — error text, wrong output, hang. Quoted, not paraphrased.
- `repro`: the command that triggers it. Built in step 1 if not given.
- `scope`: the code under suspicion. Narrows in step 3; never widens without evidence.

## Steps

1. **Repro first — one red-capable command before any theory.** Build the smallest command that exhibits the exact symptom, run it, and watch it fail (`loop-before-theory`). Match the loop's cost to the problem's size: a one-liner for a crash, a small script for a flake. No repro that goes red on demand, no hypothesis — theorizing without a loop feels like progress and isn't. Open `.mstack/debug-log.md` now — append-only, it carries every attempt from this step on.

   Bad: "The retry logic looks suspicious — let me read it."
   Good: `run.sh 2>&1 | tail -3` exits non-zero with the exact error from the report. Now theorizing may begin.

2. **State one hypothesis and its falsifier.** Before touching code, write down what you believe is wrong and what observation would prove you wrong (`falsifiable-tests` — the discipline applies to hypotheses, not just tests). One hypothesis at a time; a second hypothesis waits its turn. Each hypothesis gets a log entry: hypothesis, falsifier, result — plus the **premise** it rests on. Bisection outcomes append under the owning hypothesis's entry.

3. **Isolate by bisection.** Narrow the suspect surface: halve the input, the code path, or the config with each experiment. A hypothesis that survives narrowing gets stronger; one that doesn't dies cheap. When an experiment's result contradicts the hypothesis, the hypothesis changes — not the interpretation of the result.

4. **Fix smallest.** The minimal change that makes the repro go green (`ship-smallest`). Not the refactor noticed along the way, not the hardening that "might help." If the fix needs more than the repro demands, the repro was wrong — go back to step 1.

5. **Two failures, same assumption → stop.** Two failed fixes on the same assumption means the assumption is the bug (`attack-the-premise`). The premise is already in the log from step 2 — count failures per premise, not per hypothesis. Question it, and take a census before the next fix. The third fix on a disproven premise is the definition of spiraling — the runbook forbids it.

6. **Verify against real state.** The repro goes green on the final diff. The adjacent tests pass — the neighbors of the changed code, not just the repro. If a regression test was added, watch it fail without the fix, then restore the fix (`prove-completion`: evidence, not "fixed!"). A green run on a tree that isn't the final diff proves nothing — re-run on the diff that ships.

7. **Environmental verdict — only after the discipline.** When the loop is tight, the hypotheses are falsified, and what remains is timing, environment, or an external system: document what was investigated, implement the handling the cause calls for (retry, timeout, degraded path, clearer error), and add monitoring so the next occurrence arrives with evidence (`environment-is-a-verdict`). This step is reached, never jumped to.

8. **Not reproduced is a verdict, not a shrug.** When genuine effort cannot reproduce the symptom: record every attempt, state what was ruled out, and name the evidence that would reopen the case. Close it as not-reproduced — honestly labeled, with the log attached — never as fixed.

## Reply:

```text
- Symptom: <exact failure, quoted>
- Repro: <the command that goes red>
- Hypothesis: <final one, with its falsifier>
- Root cause: <named with evidence> | environmental | not reproduced
- Fix: <the minimal change>
- Evidence: <repro green on final diff; adjacent tests pass; regression test watched failing without fix>
- Handling/Monitoring: <if environmental: what was implemented>
- Reopen criteria: <if not reproduced: what evidence reopens the case>
```
