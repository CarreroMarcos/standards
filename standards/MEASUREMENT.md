---
title: Measurement
version: "1.2"
scope: "Trusting numbers: benchmarks, performance measurements, eval results"
consult_when: "Before trusting, reporting, or acting on a number you measured — a speedup, a regression, a throughput, a latency, or an eval result."
last_reviewed: 2026-11-23
---

# Measurement

**Core principle: a measured number is a claim about the system. Prove the claim before you report it or act on it.** A run that went wrong still prints a plausible number. Failed requests, a cache that skipped the work, code that never ran, a side left on defaults, and run-to-run noise all produce results that look fine. If you cannot say why the number is not twice as good, you do not know what you measured.

## Sections

1. [Name the limiter](#1-name-the-limiter)
2. [Tune every side before picking a winner](#2-tune-every-side-before-picking-a-winner)
3. [Check the number against the limits](#3-check-the-number-against-the-limits)
4. [Count errors and verify outputs](#4-count-errors-and-verify-outputs)
5. [Reproduce with 5 alternating runs](#5-reproduce-with-5-alternating-runs)
6. [Weigh it against what the user waits on](#6-weigh-it-against-what-the-user-waits-on)
7. [Confirm the work ran inside the timed region](#7-confirm-the-work-ran-inside-the-timed-region)
8. [Rule out what else the number could be](#8-rule-out-what-else-the-number-could-be)
9. [Report the evidence with the number](#9-report-the-evidence-with-the-number)
10. [A number needs a budget to be a verdict](#10-a-number-needs-a-budget-to-be-a-verdict)
11. [Compare the same work; never add inclusive timings](#11-compare-the-same-work-never-add-inclusive-timings)

## 1. Name the limiter

**Answer "why not double?" with a named resource or code path, taken from a profile or system counters during a run — never from reading the code.** A guess from reading the code is not a limiter. If a change did not move the number, the limiter explains why — find it before calling the change useless. Watch the load generator too: if it saturates first, you measured the load generator.
*Why: "why isn't it twice as fast" forces the claim to name what holds it back — a core, a lock, the disk, the network, the generator. A limiter you can point at is a number you understand; a limiter you inferred is a story you told yourself.*
*Boundary: profiling happens on a throwaway run, not the run you report — profilers and tracers slow the work they observe. Where profiling is impractical (short-lived processes, distributed paths), log counters structurally — or call the verdict inconclusive per §9. Never substitute a guess from reading the code.*

```text
❌ "export is faster because the new code is more efficient."

✅ "p50 41 ms → 33 ms, median of 7 runs per side, bound by JSON parsing on one core."
```

## 2. Tune every side before picking a winner

**Run every side the way production runs it: release builds, production flags and env, batching and transaction settings, connection pools, caches as warm or cold as production sees them, same versions, same data.** If one side runs on defaults, you compared configurations, not implementations. If a side is untuned and you cannot tune it, do not pick a winner from that run.
*Why: a limiter that is a setting — a commit per row, a debug build, a missing index — decides the race before the code does. An untuned run answers "which default is better," not "which option is better," and the user adopts the option, not today's settings.*

| Thought | Reality |
|---|---|
| "It's faster as-is; tuning won't change the order" | A default commit-per-row on side B is not a code difference — it's a configuration gap. Tune both, then re-run. |
| "I'll narrow the claim to the code as it ships today" | The user is choosing what to adopt. They adopt the option, not today's settings. |

## 3. Check the number against the limits

**Do the arithmetic before celebrating.** Compare operations per second times cost per operation against your cores; compare bytes per second against disk and network bandwidth; compare time saved against the time the changed piece took. Removing a piece that takes 10% of the run can make the run at most about 11% faster — a result past a limit means the run measured something other than the work: a cache, a no-op, or a bug.
*Why: physics is the cheapest reviewer. Arithmetic on the back of the run catches the cache, the skipped loop, and the broken harness before they become a decision.*

```text
❌ "Removed a 10% component, got 40% faster — ship it."

✅ "40% faster from removing 10% of the work is past the ~11% limit —
   something else changed. Re-checking what the timed region measured."
```

## 4. Count errors and verify outputs

**Count failures and non-success responses, and check that outputs are correct — not just present.** Rejections are often fast; timeouts and retries are slow; errors behave differently from successes. If the harness does not count errors, add the count before reporting.
*Why: a fast error is still a number. A run with 20% timeouts prints a latency distribution that looks like a performance improvement — it is a failure report wearing a benchmark's clothes.*

## 5. Reproduce with 5 alternating runs

**Run each side at least 5 times, alternating the sides (A, B, A, B, …) so warmup, lazy initialization, caches, and drift cannot favor one side.** Report the median and the range. A gap smaller than the run-to-run variation is no measurable difference.
*Why: one run is a weather report. Alternation distributes the machine's mood — thermal drift, cache warmth, a noisy neighbor — evenly across both sides, so the median compares implementations instead of luck. When the call is close, use the harness's own statistics.*

*Boundary: for a quick ballpark the user asked for, one run is enough — but it still checks §4 (errors) and §7 (the work ran), and the report says it is one run. A choice between options is never a ballpark.*

```text
❌ "A is 5% faster (one run each)."

✅ "A and B differ by 3%; run-to-run variation is ±5%. No measurable difference."
```

## 6. Weigh it against what the user waits on

**Next to any micro result, measure the end-to-end path a user waits on — realistic data sizes and concurrency — and report the micro result as a share of the whole.** A helper that takes 1% of a request can make the request at most 1% faster, however fast the helper gets.
*Why: a 10× faster helper inside a 1% slice is a 1% win wearing a 10× costume. The end-to-end number is the one the user feels; the micro number without its share is a decision trap.*

## 7. Confirm the work ran inside the timed region

**Verify the work happened where the timer was running.** The request reached the server, the rows were written, the bytes were read, the code used the result. Lazy code — generators nobody iterates, promises nobody awaits, results the JIT can discard — and timeouts all produce numbers for work that never happened.
*Why: the timer measures the region, not the intent. A "fast" run where the work silently never executed is the most common impossible number — and it always looks like a win.*

## 8. Rule out what else the number could be

**List what else the number could be measuring, and rule out each one with evidence.** The usual suspects: errors, skipped or cached work, an untuned side, noise, and a piece too small to matter end to end.
*Why: a number that survives this list is a claim you can defend. Each suspect ruled out is a failure mode the report no longer has to carry as doubt.*

*Boundary: for an eval result, ask the same of the trials — did every run actually do the task, does the gap hold across trials and models, and does the scenario matter.*

## 9. Report the evidence with the number

**Keep the run count, the spread, and the limiter with the number — in the notes, a linked artifact, or the PR body.** Lead with the verdict: faster, slower, no measurable difference, or inconclusive.
*Why: the number alone is not checkable. Run count, spread, and limiter are what let a second reader reproduce or falsify the claim — the measurement half of "verify, don't claim."*

**Call the verdict inconclusive when you claim a difference but cannot name the limiter, when a side ran untuned, or when you could not check §4 and §7.** Name the gap — an inconclusive number is honest; a confident number without evidence is not.
*Why: "inconclusive, limiter unknown" stops the number from being quoted as a result later. Doubt written down stays doubt; doubt omitted becomes fact.*

## 10. A number needs a budget to be a verdict

**Pre-register the threshold before you measure.** A metric without a budget is a number, not a verdict: "LCP 2.1s" means nothing until the budget says whether 2.1s passes. Set the budget first; measure second.
*Why: a threshold chosen after the measurement is a rationalization, not a standard. The budget is what turns §9's evidence into a pass/fail the next reader can trust.*

**Budget three layers — what the user feels, what causes it, what you don't control.** For web pages: user-facing metrics (LCP ≤ 2.5s, INP ≤ 200ms, CLS < 0.1 — Google's Core Web Vitals "good" thresholds at the 75th percentile of real visits), resource sizes (JavaScript, page weight, images, fonts), and third-party scripts. Each layer catches failures the others miss: a page can pass LCP while a third-party script doubles its weight.
*Why: a single-layer budget is a single point of failure — the metric you didn't budget is the one that regresses silently.*

**Set resource budgets from your own baseline, then tighten — never copy generic numbers as limits.** Measure the key templates, record today's values, set the budget at today's value where the template already passes, then tighten in steps. If the baseline already exceeds the budget, set an improvement budget (reduce 10%, then 20%) instead of enforcing an unreachable target on day one.
*Why: a budget copied from another project's numbers is either unreachable (and ignored) or slack (and useless). Your baseline is the only honest starting point.*

**Enforce the budget in CI on every pull request — and give every budget an owner and an over-budget rule.** A bundle-size check or Lighthouse CI assertion fails the build when a page or bundle goes over. A breach that nobody owns and nothing blocks is a suggestion, not a budget.
*Why: the budget's job is to make the cost visible at the moment someone adds it, when it is cheap to change — not months later when the page fails Core Web Vitals and nobody remembers why.*
*Boundary: budgets are thresholds on numbers, not a new file — this section is the library's performance-budget discipline, folded here because MEASUREMENT owns trusting numbers. Metric thresholds (the Core Web Vitals values) are Google's published targets; resource limits are always local to the project.*

## 11. Compare the same work; never add inclusive timings

**Compare benchmarks only when they invoke the same boundary and produce the same tables.** Do not compare benchmark names alone — two runs with the same name can measure different work.

**Inclusive timings must not be added together.** Request and query timings include their children; summing them double-counts nested work.
*Why: both errors manufacture fake wins — a same-named benchmark measuring different work, or a total inflated by double-counted nesting.*
*Bad:* "p50 12 ms → 8 ms" from two benchmarks with the same name but different workloads, or a total built by summing request + query timings.
*Good:* confirm same boundary and same tables before comparing; report inclusive timings as a tree, never as a sum. Benchmark workloads separately — cold vs warm lookup, dependency edit, deep import chain — so each number has one meaning. (biomejs/biome `crates/biome_module_graph/CONTRIBUTING.md:660-661, :605, :649-658`)

## Before you report a number

- [ ] I can name the limiter from a profile or counters, not from reading the code (§1)
- [ ] Every side ran production-tuned, or no winner is claimed (§2)
- [ ] The number survives the limits arithmetic (§3)
- [ ] Errors counted, outputs verified correct (§4)
- [ ] ≥5 runs per side, alternating, median and range reported (§5)
- [ ] The end-to-end share is stated next to any micro result (§6)
- [ ] The work ran inside the timed region (§7)
- [ ] Each alternative explanation ruled out with evidence (§8)
- [ ] The evidence travels with the number — run count, spread, limiter stated; verdict called inconclusive where §9's tripwires fire (§9)
- [ ] The threshold was set before the measurement, and the budget has an owner and an over-budget rule (§10)
- [ ] Compared benchmarks invoke the same boundary and produce the same tables (§11)
- [ ] Inclusive timings never summed (§11)
