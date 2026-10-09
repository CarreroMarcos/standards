---
title: Testing Discipline
version: "1.1"
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
- **Python test mechanics** (mock-at-boundaries list, DI, 0/1/2 guard contract) → languages/PYTHON.md §16
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
*Boundary: languages/PYTHON.md §16 owns the DI mechanics and the mock-at-boundaries list; this is the interface-design half.*

## 8. Shape tests to diagnose

**One logical assertion per test.** When it fails, the failure points at the broken behavior — not at a test that bundles five.
*Why: multi-assertion tests hide which behavior regressed, and they invite "fix the test to match the code" edits that bury the real break.*

**Name tests for WHAT, not HOW.** `user can checkout with valid cart` survives a refactor; `calls CartService.process with mocked repo` doesn't. A good test reads like a specification.
*Why: HOW-names couple the test to the implementation — the name breaks on every refactor even when behavior holds. The mechanical test: if the name survives a refactor unchanged, it was named right.*

## 9. Earn the green: red-first

**Write the test first; run it and read the failure before touching the implementation.** Confirm it fails *for the intended reason* — the failure output must name the broken behavior, not an import error, a bad fixture, or a typo. A test that fails for the wrong reason proves nothing; a test written after the code only verifies the code you happened to write.
*Why: the red is what makes the test a witness. The test demonstrated it observes the broken behavior, so the green afterward means the behavior changed — not that the test was edited to match.*
*Boundary: red-first applies where a practical test path exists. When it doesn't (broad harness setup, brittle mocks, slow e2e, production-only state, vague reproduction), skip the test and use the closest executable check instead — a targeted script, a manual command, a log assertion — and record what you skipped and why in the report. Skipping with a stated reason is discipline; silently shipping nothing is drift.*

**Prefer no test over a bad test.** Symptoms of a test not worth keeping:

- It mostly tests the mocks — the assertion observes the harness, not the subject.
- It encodes current implementation details — a refactor of equal behavior breaks it.
- It depends on timing or unrelated global state — green on one machine, red on another.
- It needs expensive infrastructure for a small fix — the check costs more than the bug.
- It would be deleted immediately after proving the fix — a one-shot witness masquerading as a regression guard.

```text
❌ Test added to satisfy the workflow, mocking away the subject. Green
   before the fix, green after — it never saw the bug.

✅ Smallest test that would have caught the bug, red before, green
   after. Failure output read and confirmed to name the intended
   behavior before the implementation changed.
```

## 10. Kill dead tests

**A test is dead if it would pass when every function it imports returned nothing.** Call the subject inside the test body with one concrete input and assert the literal output or the observable effect. Five shapes that pass anyway:

1. **Weak or no assertion.** No expectation at all, or only "it exists / is truthy / didn't throw" — any behavior survives.
2. **Mock-or-absence only.** Asserts the mock was called, or that the result equals an empty/absence — never what came back.
3. **Self-referential.** The expected value comes from the code under test — the expectation compares the code to itself.
4. **Constant pin.** The assertion restates a hand-maintained constant, config default, table row, or prompt string — it locks the value in two places instead of testing anything.
5. **Fixture asserts fixture.** The assertion reads data the test built; the subject never runs inside the body.

*Why: a dead test costs CI time and review attention while catching nothing — and a constant pin actively fights the edit it guards against, failing when someone changes the value on purpose. This is the test-design implementation of §4's "a check that cannot fail does not count" and of AGENTS-STARTER.md rule 3's "evidence must discriminate."*
*Boundary: keep tests of a relation across data (a key present in two tables, a parent that exists) and compile-time checks (e.g. `*.test-d.ts`) — they assert structure, not behavior, and say so. When no honest assertion exists, delete the test instead of weakening it to green.*

```text
❌ expect(slugify("Hello, World!")).toBe(slugify("Hello, World!"))
   — passes if slugify returns anything at all.

✅ expect(slugify("Hello, World!")).toBe("hello-world")
   — one concrete input, one literal expected value.
```

## 11. Prove runs the way the user drives them

For scripted verification runs — the harness that launches the app and proves behavior end to end, where a unit test is the wrong vehicle:

**Drive the real user path.** Not internal setters, not test-only endpoints, not a harness seam the user never touches. The path the agent drives must be the path the user walks.
*Why: verification through a test-only endpoint proves the endpoint wiring, not the feature. The bug users hit lives on the user path.*

**Capture the action and the resulting state, not just the final screen.** Screenshot, transcript, response body — plus the side effects: files written, rows inserted, messages sent. An end state with no proof of the side effects is a rumor.
*Why: a check that only shows the last screen can't distinguish "it worked" from "the screen didn't update."*

**Verify what a dry-run actually skips by observing it, not by trusting its name.** Watch the files, the network, the git refs. Some dry-runs still touch the network or open a browser.
*Why: "dry-run" is a label, not a contract. A safe-mode flag that quietly writes to production is how drills become incidents.*
*Boundary: mocks belong only where a production boundary already isolates the external system — never as a convenience to skip driving the real path.*

**Cleanup removes instances and scratch — never the proof.** Kill what you started (never by process name); after teardown, confirm the evidence still exists at the named location. A cleanup that eats the proof fails the run.
*Why: proof that doesn't survive the run's own teardown can't be re-read by the next agent or the review — it existed for a minute and is gone.*

---

## Before you commit the test

- [ ] It fails when the guarded logic breaks (watched it fail — §4)
- [ ] One behavior per test; named for WHAT (§8)
- [ ] Expected values from a source independent of the implementation (→ ENGINEERING_PRINCIPLES.md §4)
- [ ] No suppression without a recorded reason (§6)
- [ ] Changed-lines coverage didn't fall (§1)
- [ ] New test: ran before the fix; failure read and confirmed for the intended reason (§9)
- [ ] No dead-test shape — it would fail if every import returned nothing (§10)
- [ ] Verification runs: drove the real user path; dry-run's skips observed, not assumed; proof survives cleanup (§11)
