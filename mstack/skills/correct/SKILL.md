---
name: correct
description: Use when a mistake repeats — the second occurrence of a failure class, a correction you've already given once — and the fix must be structural instead of another paragraph.
---

## When to use

A mistake has repeated, or is about to. Reach for `correct` when the same correction is needed a second time, when a failure class hits its second occurrence, or when a fix is about to ship as prose that agents will skim past. This skill climbs the fix ladder — highest rung first — and mines the lesson into structure instead of text.

## Procedure

1. **State the fix contract first** (`loop-contract-first`). Before touching anything: name the failure class, cite the occurrences (commits, reverts, corrections), name the rung you are attempting and why the higher rungs don't apply, and name what the proof will look like. A fix with no contract is a guess.
2. **Climb the ladder — highest rung first.** Attempt each rung in order and take the first one that holds:
   - **Make it impossible.** Restructure so the bad state cannot be written: one owner per piece of state, one supported way per task, internals hidden so the wrong import fails. **Structure beats discipline** — a state that cannot be represented needs no one's cooperation.
   - **Enforce it with types or a lint.** Where the bad code still compiles, add a check whose failure message names the right file, type, or function. Where the pattern is already widespread, fail only on changes that add more of it.
   - **Test the behavior.** Rewrite or delete any test whose assertions survive every callee returning nothing. This license covers only tests that meet this criterion.
   - **Write it down — last, and only for judgment calls.** Docs and agent rules are the weakest rung: nothing fails when an agent skips them. **Skip a rung only with a reason** — record why the higher rung didn't work in the Output.
3. **Count the class — never at one.** A failure class counts at `values.md#correct-mining.class-threshold` occurrences. **One occurrence is an anecdote, not a rule** — and not a basis for a new check. Group the evidence before you mine: commits, reverts, review comments, corrections.
4. **Prove the check on a real past mistake.** Every new check must fail on a real past mistake before it ships: run it against the old code and watch it fire. **A check that never failed proves nothing.** The check must fire identically locally and in CI.
5. **Pair every rule with its enforcer.** Keep the rule↔enforcer table: each rule names what enforces it — lint, type gate, test, or human. **A rule with no enforcer is a wish.** When a correction arrives for a rule that's already there with no enforcer, that's a repeat — climb to the highest rung in the same change. Retire a rule once its mistake is unrepresentable. Park exceptions on the offending line itself — reason, expiry date, and whose approval — never in a side document.

## Output

- **The fix** — the class, the rung taken, why the higher rungs didn't work, and the check itself.
- **The mined lesson** (only when the class counted) — class, occurrences with evidence pointers, the proof (the past mistake the check fails on), and the rule↔enforcer row.
- **Skipped rungs** — each with its reason.
- **Removed tests** — each with the criterion it met.
