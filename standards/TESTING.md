---
title: Testing Discipline
version: "1.0"
scope: "Test creation for agents: what to measure, seam agreement, when tests are required, anti-cheating, cost placement, suppression guards, mocking design, test shape"
consult_when: "When writing tests and tempted to test everything or nothing — 'do I need a test for this?', 'what should I mock?', 'is this test actually proving anything?' — or when a suite is slow, flaky, or green-but-meaningless."
last_reviewed: 2026-10-08
---

# Testing Discipline

**Core principle: a test is a falsifiable claim about behavior.** If it cannot fail when the behavior breaks, it is not a test — it is a green badge. Every rule here serves that claim: measure what you can move, agree what you're covering, require tests where risk lives, and never let the suite become theater.

## Already covered elsewhere

This file owns test *creation discipline*. The philosophy, procedures, and gates live where they belong — read them, don't re-derive them:

- **Testing philosophy** (observable behavior, I/O hoisting, fakes over mocks, property-based testing, DAMP, independent expected values) → ENGINEERING_PRINCIPLES.md §4
- **The TDD loop** (one test per observable behavior — write, implement, verify, commit) → WORKFLOW.md Phase 4
- **Evidence integrity at review gates** (break the guard, rank checks by circularity) → CODE-REVIEW.md §7
- **Python test mechanics** (mock-at-boundaries list, DI, 0/1/2 guard contract) → PYTHON.md §16
- **Prove completion — never claim it; wire it in or delete it** → AGENTS-STARTER.md rules 2–3

## 1. Measure what you can move

**Cover the changed lines, not the project.** Gate on the coverage of the lines the change touched — computed by intersecting the suite's existing coverage output with `git diff`. Never run the suite a second time just to produce the metric.
*Why: project coverage is an inherited number the agent cannot move — gating on it produces a permanently red build (then a team that learns to ignore red builds) or drive-by tests on untouched code. Changed-lines coverage is actionable per diff, and single-run mechanics keep the check cheap enough to survive.*
*Boundary: the intersection mechanics are stack-specific (lcov + git diff, coverage.py + diff-cover) — this rule defines the metric and the single-run constraint; each repo's CI defines the gate. Until a gate exists, the check is manual at task end. Adopting repos record their gate (tool + threshold) or "manual" in their own conventions — an unrecorded gate is an unenforced one.*

**Ratchet, don't aspirate.** When the codebase fails the target number today, record today's value with a "must not fall" direction and gate on *that*. Never set a bar the codebase fails on day one.
*Why: an unreachable bar trains everyone to ignore red builds — the gate decays into decoration while still looking enforced, which is worse than no gate.*

| Thought | Reality |
|---|---|
| "Let's require 80% coverage everywhere" | Set 80% on a codebase at 62% and you get a red build forever, then a team that ignores red. Record 62%, refuse to fall. |
| "Coverage dipped 2% on this diff, but the diff is fine" | Then the ratchet caught exactly what it's for — either the tests are missing or the number needs a recorded reason. |

## 2. Agree the seams before writing

**Write down the seams under test and confirm them before writing any test.** No test at an unconfirmed seam. Each seam gets a one-line note: what it catches, what it misses.
*Why: test effort is finite — the catches/misses note makes the coverage gap explicit and auditable instead of silently assumed. "We have tests" becomes "we tested X and knowingly skipped Y."*

## 3. When new logic needs a test

**New non-trivial logic leaves one small test.** Any new branch, loop, parser, money or security logic, data write, bug fix, or whole new script/app gets one small test — or an assert-based self-check for throwaway code. Trivial changes are explicitly exempt: no test theater.
*Why: the parenthesized trigger list is mechanically checkable — "did I write a branch?" needs no risk judgment — and the explicit exemption is what stops the rule from generating test theater.*
*Boundary: code explicitly marked throwaway gets no test suite at all — tests are polish the prototype's purpose (learning fast) doesn't need. It must still run; it need not be verified.*
*Scope limit: that exemption covers* writing *tests only.*
*Separately: a diagnostic that cannot run is still "could not verify," never a pass (→ DEBUGGING.md §8).*

## 4. One good test beats coverage

**For risky logic, one test that demonstrably fails when the logic breaks beats any coverage percentage.** A review flags risky logic whose only evidence is "covered."
*Why: coverage rewards executing code; this rewards discrimination. It is the review-side enforcement of "a check that cannot fail does not count," aimed at exactly what coverage hides.*

```text
❌ Risky branch "covered" by a test that passes whatever the branch does.

✅ One test with the branch forced both ways — green on the right path,
   red on the wrong one. Watched it fail before trusting it.
```

## 5. Place checks by cost

**Sub-second checks live in the edit loop; ~90s checks at task end; minutes-long checks in CI.** Anything expensive — mutation testing, whole-repo scans — gets diff-scoped or moved out of the fast loop. Never leave an expensive check to be switched off.
*Why: a check that stalls the loop gets switched off, and a gate people switched off is worse than no gate — the bar still looks like it exists. Diff-scoping converts "too expensive to run" into "cheap enough to keep."*

## 6. Guard the suppressions

**Treat test-suppression patterns as red flags.** Coverage-ignore pragmas, mutation-disabler comments, `.skip` added to a failing test, assertions pulled out of tests that stayed — the cheapest road to green is editing the test, not the code, and that's where agents go when a check binds.
*Why: agents don't craft clever loopholes; they hit a red check and take the cheapest road. Review the road, not just the green.*

## 7. Design boundaries for mockability

**Pass external dependencies in; prefer one purpose-built function per external operation.** A generic fetcher forces the mock to re-implement routing logic — the test then tests the mock's conditionals, not the code. SDK-style boundaries make each mock return one specific shape, with no conditional logic in test setup.
*Why: a mock with branches is a second implementation you're now responsible for. One function per operation keeps the mock dumb and the test honest.*
*Boundary: PYTHON.md §16 owns the DI mechanics and the mock-at-boundaries list; this is the interface-design half.*

## 8. Shape tests to diagnose

**One logical assertion per test.** When it fails, the failure points at the broken behavior — not at a test that bundles five.
*Why: multi-assertion tests hide which behavior regressed, and they invite "fix the test to match the code" edits that bury the real break.*

**Name tests for WHAT, not HOW.** `user can checkout with valid cart` survives a refactor; `calls CartService.process with mocked repo` doesn't. A good test reads like a specification.
*Why: HOW-names couple the test to the implementation — the name breaks on every refactor even when behavior holds. The mechanical test: if the name survives a refactor unchanged, it was named right.*

## Before you commit the test

- [ ] It fails when the guarded logic breaks (watched it fail — §4)
- [ ] One behavior per test; named for WHAT (§8)
- [ ] Expected values from a source independent of the implementation (→ ENGINEERING_PRINCIPLES.md §4)
- [ ] No suppression without a recorded reason (§6)
- [ ] Changed-lines coverage didn't fall (§1)
