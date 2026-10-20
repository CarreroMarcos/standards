---
name: rebuild-from-contract
description: >
  Use when a module, file, or component is gone or being replaced outright and its tests, callers, or spec survive: rebuild the artifact from the contract that remains, against a recorded baseline.
---

## Exit predicate

The run ends with one of three verdicts — never a pass:

- REBUILT: the gate's failure set on the rebuilt artifact is a subset of the recorded baseline (zero new failures), every contract test for the rebuilt unit is green, and the missing-behavior audit accounts for every public name.
- PARTIAL: the gate is green but the audit names behavior the contract could not pin and the rebuild does not provide — named, with the evidence.
- BLOCKED: the surviving contract cannot decide correctness (too thin, contradictory, or its baseline cannot be recorded) — the run states what extra evidence would decide.

A REBUILT claim from a recount instead of a failure-set diff against the baseline is not a verdict — it is a summary.

## Requires

- A surviving contract: tests that exercise the artifact, callers that consume it, a spec or doc that describes it — at least one, and the more independent the better.
- A recordable baseline: the gate command's result (pass/fail set) captured before the rebuild starts — against the original if it still runs anywhere, against the contract alone if it does not.
- One artifact in scope. A rebuild that sprawls into its callers is a different task.

## Inputs

- `lost`: what is gone or being replaced, in the operator's words.
- `contract`: where the surviving tests, callers, and spec live.
- `gate`: the exact verification command. When the operator doesn't name one, the run proposes it and states it in the Reply.

## Steps

1. **Record the baseline before touching anything.** Run the gate on the untouched tree and save its failure set verbatim — that set is the bar. The rebuild must add zero new failures to it; failures already in the baseline are classified as baseline, never silently absorbed or "fixed" as a side effect.
2. **Inventory the contract surface before writing code.** Read the unit's tests, its callers, and its spec as one specification: extract the public API (names, signatures, construction shapes) and the behavioral pins (exact strings, event shapes, error classes, timing and ordering pins). The contract is the spec — read it like one. Never reconstruct the artifact from memory of having seen it; memory is a rumor, the contract is the source.
3. **State the done-condition up front** (`state-assumptions`): the gate, the baseline, and what will count as missing behavior. Ambiguities the contract leaves open are judgment calls — decide them during implementation and name every one in the Reply.
4. **Implement leaf-first.** Pure helpers, data shapes, and validation before orchestration and side effects; the artifact's own dependency order, not the test file's order. One artifact — helpers the original split across files stay internal unless the contract's import surface demands otherwise (`ship-smallest`).
5. **Iterate against the gate; the failure count is the progress signal.** Reproduce each remaining failure in isolation before hypothesizing about it (`loop-before-theory`). Every failure gets a class: mine (the rebuild is wrong), baseline (it was already failing), or contract gap (the contract contradicts itself — stop and surface it, never pick a side silently).
6. **Check the consumers the gate doesn't name.** Harnesses, eval suites, scripts, and importers outside the gate command: a rebuild that passes the gate but breaks an unlisted consumer is not done. Run them, or state why each is out of scope.
7. **Missing-behavior audit.** Enumerate the artifact's public surface from the contract (callers' imports, tests' references, the spec's names) — every name is implemented, or named in the Reply as absent with the evidence that nothing consumes it. Untested behavior the contract hints at but cannot pin goes to the Reply as a contract gap, not a silent drop.
8. **Unmasked verify before any REBUILT claim** (`prove-completion`). A fresh gate run on the final tree; the Reply reports the failure-set *diff* against the step-1 baseline, not a recount of the final run.

## Reply:

```text
- Lost: <what was rebuilt>
- Gate: <the exact command>
- Baseline: <pass/fail counts + where the failure set is recorded>
- Final: <pass/fail counts + the failure-set diff against baseline>
- API audit: <public names: implemented n/n, or the absent names + evidence>
- Contract gaps: <what the contract could not pin, and the judgment call made>
- Decisions: <the design choices the contract left open, and why>
```

Every Contract gaps entry traces to a step-3 assumption or a step-5 classification. A REBUILT verdict with unexamined consumers (step 6) or an incomplete API audit (step 7) is a claim, not a verdict.
