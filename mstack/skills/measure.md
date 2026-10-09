---
name: measure
description: Use when a headline number needs vetting before anyone trusts it — a speedup, a regression, a throughput claim — and the runs behind it might be lying.
---

## When to use

A number is about to be reported or acted on: a PR's before-and-after, a
regression claim, a config choice. Reach for `measure` when the claim is
"X is faster" and the evidence is a run someone did. This skill is the
validity gate that `runbooks/measurement-eval.md` runs before trusting any
number.

## Procedure

1. **Name the limiter.** Ask "why not double?" — what resource or code path
   bounds the result: a core, a lock, the disk, the network, the load
   generator itself. Get it from a profile or system counters taken during
   a run you do not report, then map the hot spot to source. **A guess from
   reading the code is not a limiter** (`name-the-limiter`). If one side's
   limiter is a setting — a debug build, a missing index, a commit per row —
   that side is untuned: tune it and measure again, or pick no winner from
   this run.
2. **Check parity.** Run every side the way production runs it: release
   builds, production flags and env, batching and transaction settings,
   connection pools, caches as warm or cold as production sees them, same
   versions and data. **If one side runs on defaults, you compared
   configurations, not implementations.**
3. **Count and interleave.** Run each side at least
   `values.md#eval.run-floor` times, alternating sides (A, B, A, B) so
   warmup, lazy init, caches, and drift hit both equally. **Never
   all-A-then-all-B.** Report the median and the range. **A gap smaller
   than the run-to-run variation is no measurable difference.**
4. **Check relevance.** Next to any micro result, measure the end-to-end
   path a user waits on, with realistic data sizes and concurrency. **A
   helper that takes a sliver of a request can speed up the request by at
   most that sliver, however fast the helper gets.** Report the micro
   result as a share of the whole.
5. **Rule out the usual suspects.** Count errors — failures and non-success
   responses behave differently from successes (rejections are fast;
   timeouts and retries are slow). Confirm the work ran inside the timed
   region: the request reached the server, the rows were written, the bytes
   were read, the code used the result. **Lazy work nobody awaited and
   timeouts both print numbers for work that never happened.** A check that
   cannot fail does not count (`falsifiable-tests`).
6. **Report the uncertainty with the headline.** Every number ships with its
   run count, its range, and its limiter. **A number without a limiter is a
   rumor.**

**Inconclusive is a valid verdict.** Call it when you cannot name the
limiter, when a side ran untuned, or when a question above cannot be
checked — and name the blocking question. **A forced number is a defect: it
poisons every future comparison that trusts it.**

## Output

- Per-question verdict: pass / fail / unchecked, with the evidence
- The number with its unit, run count, range, and named limiter — or
  INCONCLUSIVE with the blocking question named
- The runs and limiter evidence kept with the number, so a later reader can
  check the claim
