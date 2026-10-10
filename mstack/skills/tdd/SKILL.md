---
name: tdd
description: >
  Use when a bug or new behavior has a cheap, local test path — write the failing test first, confirm it fails for the intended reason, then fix.
---

## When to use

A bug has a clear, cheap test path and you are about to touch the
code. Reach for `tdd` when the failing behavior can be made executable
before the fix — a unit, a focused regression check, anything that runs
fast and locally. This skill is the red-first discipline behind a
fixer's work: the test exists before the fix, not after it.

Do not force it. When the test path is unclear, expensive,
integration-heavy, or needs production-only state, say so and use the
closest executable check instead — a targeted script, a repro command,
a log assertion. Skipping silently is the failure mode; skipping with a
stated reason is the contract.

## Procedure

1. **Name the intended behavior.** Write down what the code should do,
   in one sentence, before writing anything executable. A test written
   from a vague intention encodes the vagueness.
2. **Write the failing test first.** The smallest check that implicates
   the bug. Encode the intended behavior — never mirror the current
   implementation. A test that passes against the broken code is not a
   test; it is a description of the bug wearing a test's clothes.
3. **Run it before touching the fix — and read the failure.** Confirm
   the failure points at the code you are about to change — not a typo
   in the test, a bad fixture, or an unrelated setup error. A red test
   failing for the wrong reason proves nothing (`loop-before-theory`
   — the repro is the work).
4. **Make the smallest fix that turns it green.** Change production
   code, not the test. Never edit a test to match a wrong
   implementation; never weaken an assertion unless the expected
   behavior genuinely changed and you can say why.
5. **Rerun and bracket.** Failing-before and passing-after, each
   observed directly — the known-broken state, the single change, the
   check on both (`prove-completion`). Run the nearby tests too; a fix
   that breaks its neighbors is not a fix.

## Bad tests

**A bad test is worse than no test.** It burns CI time, trains
everyone to ignore red, and ossifies the wrong behavior. Kill or
rewrite on sight:

- **Cannot fail.** The assertion passes whatever the code does —
  tautologies, self-referential expectations, restated constants
  (`falsifiable-tests`).
- **Tests the mock.** Every interesting behavior is stubbed out, so
  the test verifies the test setup, not the code.
- **Encodes implementation.** Asserts on internal call order, private
  state, or incidental structure — breaks on every refactor that
  preserves behavior.
- **Flaky by construction.** Depends on timing, sleep durations, or
  unrelated global state. If the bug is timing-sensitive, make the
  test deterministic and write down which signal the test pins.
- **Expensive for a small fix.** Needs heavy infrastructure to check
  a one-line change — use the closest cheap check instead and say so.

Bad: a test asserting the function was called (it was — by the test).
Good: a test asserting the observable outcome changed.

The license covers bad tests by this section's criteria only. Deleting anything outside it — a test that merely fails, product code, config — requires destructive-scope confirmation first: state the exact scope and wait for the human.

## The skip contract

TDD is not universal. When it does not apply, **state why in one
sentence** — "no cheap local path: needs the staging cluster,"
"behavior is visual; using screenshot comparison instead." Then use
the closest executable check and name it. What you must never do is
skip silently and ship the fix untested — an unstated skip is
indistinguishable from laziness, including to your future self.

## Output

Per fix, report the evidence:

- **Failing-before** — which test (or closest check), and the
  failure it showed: what broke and where, read directly — not "it
  failed" but what failed.
- **Passing-after** — the same check green, plus nearby validation
  run.
- **Skipped-with-reason** — when no test was practical: the
  one-sentence reason and the closest check used instead.
- **Removed-on-criterion** — every test killed or rewritten, each with
  the criterion it met.
