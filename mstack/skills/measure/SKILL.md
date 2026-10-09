---
name: measure
description: Use when a headline number needs vetting before anyone trusts it — a speedup, a regression, a throughput claim — and the runs behind it might be lying.
---

## When to use

A number is about to be reported or acted on: a before-and-after PR run, a
regression claim, a config choice. Reach for `measure` when the claim is
"X is faster" and the evidence is a run someone did. This skill is the
validity gate that `runbooks/measurement-eval.md` runs before trusting any
number.

## Procedure

1. **Name the limiter.** Ask "why not double?" — what resource or code path
   bounds the result: a core, a lock, the disk, the network, the load
   generator itself. Get it from a profile or system counters taken during
   a sacrificial run you never report, then trace the hot spot back to
   source. **A guess from
   reading the code is not a limiter** (`name-the-limiter`). If one side's
   limiter is a setting — a debug build, a missing index, a commit per row —
   that side runs untuned: retune it and re-measure, or pick no winner from
   this run.
2. **Check parity.** Match production on every side: production binaries,
   live flags and environment, the batching and transaction knobs, the
   connection pools, caches warmed or cold exactly the way production hits
   them, identical versions and identical data. **Defaults on one side
   means you benchmarked settings, not code.**
3. **Count and interleave.** Run each side at least
   `values.md#eval.run-floor` times, alternating sides (A, B, A, B) so
   warmup, lazy init, caches, and drift hit both equally. **Never
   all-A-then-all-B.** Give the median with the range. **A gap under
   the run-to-run variation is no measurable difference.**
4. **Check relevance.** Pair every micro number with the full user-facing
   path it lives in, driven at realistic data sizes and concurrency. **A
   helper that takes a sliver of a request can speed up the request by at
   most that sliver, however fast the helper gets.** Express the micro
   number as a fraction of the whole path.
5. **Rule out the usual suspects.** Count errors — failures and non-success
   responses skew differently from successes (rejections run fast;
   timeouts and retries are slow). Prove the timed region did the work: the
   request landed on the server, the rows hit storage, the bytes came back,
   the code consumed the result. **Lazy work nobody awaited and
   timeouts both print numbers for work that did not happen.** A check that
   cannot fail does not count (`falsifiable-tests`).
6. **Report the uncertainty with the headline.** Every number ships with its
   run count, its range, and its limiter. **A number without a limiter is a
   rumor.**

**Inconclusive is a valid verdict.** Call it when the limiter stays
unnamed, when one side ran untuned, or when one of the questions above
cannot be checked — and name the blocking question. **A forced number is a
defect: it poisons every future comparison that trusts it.**

## Output

- Per-question verdict: pass / fail / unchecked, with the evidence
- The number with its unit, run count, range, and named limiter — or
  INCONCLUSIVE with the blocking question named
- The runs and limiter evidence kept with the number, so a later reader can
  check the claim
