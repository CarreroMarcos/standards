---
name: measurement-eval
description: Use when a performance claim needs a number you can trust: "is X faster than Y", a benchmark result to validate, a before/after comparison to run, or a headline number that still needs its limiter named.
---

## Exit predicate

The run ends with one of these — no third outcome:

- A named number with its limiter identified, or
- an explicit "not measured".

A number without provenance is not a result. A limiter you cannot name is a limiter you did not find.

## Requires

- Something runnable at least `values.md#eval.run-floor` interleaved times: the claim under test, executable on demand.
- A way to observe wall-clock or the metric of interest — the real thing, never a proxy.

## Inputs

- `claim`: the statement under test ("X is faster than Y", "the change cut p99 latency").
- `metric`: what gets measured (wall-clock, tokens, requests per second).
- `environment`: the machine, flags, and dataset the runs execute on — recorded, never assumed.

## Steps

1. State the claim and the metric before any run. Write down what would falsify the claim (`falsifiable-tests`). A claim you cannot falsify is not a claim — it is a wish.
2. **Run the `measure` skill's validity checklist before trusting any number.** Limiter: name what caps the result (`name-the-limiter` — answer "why not double?" from a profile or counters, never from reading the code). Parity: both sides run under identical conditions — same machine, same flags, same data, same warm-up. Count: no fewer than `values.md#eval.run-floor` interleaved runs per side. Relevance: the metric measures the end-to-end outcome, not a micro-benchmark that flatters the change.
3. **Alternate A and B — never all-A-then-all-B.** Interleave the runs (A B A B …). Machine drift (thermal throttling, noisy neighbors) corrupts a batched comparison and looks exactly like a result.
4. Report medians, not means. A mean lets one outlier write the headline; a median makes the outlier earn it.
5. Report run-to-run variation alongside the headline number: the range across the interleaved runs. A headline without its spread is a rumor with formatting.
6. **Unmasked verify: measure the real thing.** The number comes from the actual runs on the real workload — never a proxy metric, never the author's summary of the runs. `prove-completion` holds: no completion claim without fresh evidence, and the evidence must discriminate.
7. Record the results in a form future runs can compare against: the claim, the metric, the environment, the per-run values, the median, the range, the named limiter. A result nobody can reproduce is a story, not a measurement.
8. **Inconclusive is a valid verdict.** When the ranges overlap and no limiter separates the sides, report inconclusive with the evidence. A forced number is a defect — it poisons every future comparison that trusts it.

## Reply:

```text
- Claim: <the statement under test>
- Metric: <what was measured>
- Environment: <machine, flags, dataset>
- Runs: <per-run values, interleaved A/B>
- Median: <A median> vs <B median>
- Range: <run-to-run variation per side>
- Limiter: <named, from profile/counters> | not identified
- Verdict: <measured | not measured | inconclusive>
- Evidence: <where the raw run data lives>
```

A "not measured" verdict names what blocked the measurement. An inconclusive verdict shows the overlapping ranges. A forced number is never a verdict.
