---
title: Debugging Discipline
version: "1.2"
scope: "Systematic debugging for agents: feedback loops, repro minimization, hypothesis testing, instrumentation, seam judgment, premise attacks when fixes keep failing, cleanup"
consult_when: "When something is broken and you're tempted to theorize first — 'I think the bug is probably in…', 'let me just try changing…' — or when a debug session is spiraling and nothing is converging."
last_reviewed: 2026-10-09
---

# Debugging Discipline

**Core principle: the loop is the work.** A tight feedback loop — one command that reproduces the exact failure, fast and deterministically — is 90% of the fix. Bisection, hypothesis-testing, and instrumentation all merely consume the loop. Skip phases only when explicitly justified.

## Already covered elsewhere

This file owns the *phase discipline between* the gates. The gates themselves live where they belong — read them, don't re-derive them:

- **No red-capable repro, no hypothesis** → AGENTIC-DESIGN.md §4
- **Three strikes on "still broken" exits the code loop** → DEV-LOOP.md
- **Grep every caller, fix the root cause once in the shared code** → WORKFLOW.md
- **Prefer fixes that delete code** → CODE-QUALITY.md §5
- **Finish every part the change breaks** → CODE-QUALITY.md §5
- **A diagnostic that cannot run is "could not verify," never a pass** → languages/PYTHON.md (0/1/2 guard contract)
- **Redact before rendering; rotate on exposure** → SECRETS.md

## 1. Build the loop before the theory

**Spend disproportionate effort on the feedback loop.** Before theorizing, build one command that reproduces the exact failure. Bisection, hypothesis-testing, and instrumentation all merely consume the loop — the loop is the work.
*Why: agents under-invest in loop construction and over-invest in theorizing, because theorizing feels like progress and loop-building feels like overhead. It's reversed.*

**Tighten the loop as a product: faster, sharper, more deterministic.** A 30-second flaky loop is barely better than no loop; a 2-second deterministic one is a debugging superpower. Three levers, in order: make it faster, make it assert the specific symptom (not "it errored"), make it deterministic.
*Why: a slow or flaky loop caps how many hypotheses you can test per unit of time — every technique below is throttled by it.*

**Check the decision records in the blast area before diagnosing.** Past decisions explain present weirdness — read the ADRs and docs for the code you're touching before theorizing.
*Why: debugging without them re-litigates settled trade-offs; "weird" code is often weird on purpose.*

**Match the loop to the size of the problem.** A one-line fix in a small file gets a one-command check, not the nine-phase treatment. The full discipline earns its keep on bugs that resist the simple loop — when the first check doesn't converge, *then* build the loop properly.
*Why: the loop serves the fix, not the other way around. A disproportionate loop on a trivial bug is the debugging equivalent of over-engineering.*

| Thought | Reality |
|---|---|
| "I have a strong hunch where the bug is" | A hunch without a loop is a vibe. Build the loop, then test the hunch in one run. |
| "Building a repro takes longer than just fixing it" | The fix you can't verify is a guess with a commit message. |
| "It's flaky, I can't get a clean repro" | The goal isn't a clean repro — it's a higher reproduction rate (§2). |

## 2. Confirm the symptom; tame the flake

**Reproduce the user's exact failure, not a nearby one.** The loop must produce the failure mode the user described — the error message, the wrong output, the slow timing they reported. Capture it exactly; every later phase verifies against this capture.
*Why: nearby-but-different failures are the commonest wasted-debug cause. Wrong bug = wrong fix, and a fixed verification target beats a moving one.*

**For flaky bugs, raise the reproduction rate — don't chase a clean repro.** Loop the trigger 100×, parallelize, add stress, narrow timing windows, inject sleeps. A 50%-flake bug is debuggable; a 1% one is not. Keep raising the rate until it's debuggable.
*Why: "flaky" is a tunable parameter, not a verdict. Agents either declare flaky bugs unreproducible or inspect 1%-rate failures by reading code — both waste the session.*

**If you genuinely cannot build a loop, stop.** List what you tried. Ask the user for (a) access to an environment that reproduces it, (b) a redacted captured artifact (HAR file, log dump, core dump, screen recording with timestamps), or (c) permission to add temporary production instrumentation. Do not hypothesize without a loop.
*Why: the no-loop moment is when theory-first debugging is most tempting — which is exactly what this file exists to prevent. The "list what you tried" clause makes the stop auditable instead of a shrug.*

## 3. Minimize until every remaining element is load-bearing

**Shrink the repro to the smallest scenario that still goes red.** Cut inputs, callers, config, data, and steps one at a time, re-running the loop after each cut. Done when removing any single remaining element makes the loop go green.
*Why: a minimal repro shrinks the hypothesis space — fewer moving parts to suspect — and it becomes the regression test for free. One artifact, two jobs.*

```text
❌ 200-line repro with the full app booted, three config files, a seeded
   database — "it reproduces, ship the fix."

✅ 12-line script, one input, one flag — every line load-bearing.
   This file becomes test_regression_<bug>.py.
```

## 4. Hypotheses are predictions or they're vibes

**State every hypothesis as a falsifiable prediction.** "If X is the cause, then changing Y will make the loop go green." If you cannot state the prediction, the hypothesis is a vibe: discard it or sharpen it until it predicts.
*Why: prediction-less hypotheses can't be killed by experiment, so they survive every probe and steer the session indefinitely.*

**Show the ranked list before testing — but never block on it.** Rank 3–5 hypotheses and surface them; one domain fact ("we just deployed a change to #3") can outrank hours of instrumentation. In autonomous sessions, proceed with your ranking — don't wait for a reply.
*Why: cheap checkpoint, big time saver. The no-block clause keeps it from becoming a latency tax.*

## 5. Instrument with intent

**Every probe maps to a prediction; change one variable at a time.** No "log everything and grep" — unmapped logging is volume without discrimination. Prefer the debugger: one breakpoint beats ten logs.
*Why: a probe that isn't testing a prediction is noise you're generating to feel busy.*

**Tag every debug log with a unique prefix.** `[DEBUG-a4f2]` on every line you add — cleanup becomes a single grep. Untagged logs survive; tagged logs die.
*Why: debug logs that outlive the session become misleading permanent residents. The prefix makes removal mechanical, not a memory exercise.*

**Perf regressions: baseline first, then bisect.** Logs are usually wrong about perf. Establish a baseline measurement (timing harness, profiler, query plan), then bisect. Measure first, fix second.
*Why: without a baseline, "fixed" is unverifiable — the number before and after is the only verdict. Applies when the symptom is "too slow," not "wrong."*

## 6. Test at a correct seam — or name its absence

**Write the regression test before the fix, at a seam where the test exercises the real bug pattern as it occurs at the call site.** A shallow-seam test (single-caller test when the bug needs multiple callers, a unit test that can't replicate the chain that triggered the bug) gives false confidence — worse than no test, because it manufactures assurance.
*Why: "write a regression test" without the seam judgment produces tests that pass while the bug class stays live.*

**If no correct seam exists, that itself is the finding.** The architecture is preventing the bug from being locked down — note it and flag it. Untestable seams are a design defect, not a process failure.
*Why: converts "I can't write the test" from a shrug into a routed architectural finding.*

**Watch it fail; re-run the original.** If you forced the red by mutating code or a fixture, diff against a pristine copy to prove the mutation landed before you trust it. After the fix, re-run the *original un-minimized* loop — the minimized repro can pass while the original scenario still fails.
*Why: a test that never demonstrably failed proves nothing, and over-minimization is a real acceptance gap.*

## 7. Keep guards through code motion

**Code you move or merge keeps its error handling and validation.** Merge and refactor diffs are where guards get silently dropped — the diff's stated purpose ("just moving code") suppresses scrutiny. Invariant preservation is an explicit checklist item on any code-motion diff.
*Why: invariants get lost in the shuffle between helpers, and nobody re-checks what "just moved."*

**When reviewing a fix: a fix applied in one caller while the shared function stays broken is a Bug-class finding.** Caller-local workarounds pass their own test while leaving the bug live elsewhere — name it when you see it.
*Why: the author-side procedure (WORKFLOW.md: grep every caller, fix the root cause once) needs its review-side detector.*

## 8. Debug without leaking

**Redact first, quote only the signal.** Debug sessions are the highest-volume secret-display surface — commands, outputs, HARs, dumps. Write `<REDACTED>` before showing anything; build loops against env vars so the credential stays in the environment, not in what you show. Quote only the lines that carry the signal. If redacted output is insufficient, say so and ask — don't un-redact to be helpful.
*Why: a share-first reflex in a debug session is how credentials end up in transcripts and reports.*
→ SECRETS.md owns the why; this is the debug-session application.

**A diagnostic that cannot run is "could not verify" — never a pass.** A repro harness that errors on setup (bad fixture, unreachable env) and gets read as "bug not reproduced" converts ignorance into assurance.
*Why: the most dangerous verdict a debug gate can emit is assurance from ignorance.* (Companion to languages/PYTHON.md's 0/1/2 guard contract.)

## 9. Clean up and record

**Close every debug session with the checklist:**

- [ ] Original repro no longer reproduces (re-run the §1 loop)
- [ ] All `[DEBUG-...]` instrumentation removed (grep the prefix)
- [ ] Throwaway prototypes deleted or moved to a clearly-marked debug location
- [ ] The hypothesis that turned out correct is stated in the commit message — so the next debugger learns
- [ ] No secrets in anything shown or pasted during the session (§8)

## 10. Attack the premise when fixes keep failing

**Two or more fixes failed the same gate → suspect the shared premise, not the fixes.** Stop fixing. Write the premise down — the one sentence every failed fix assumed — and take a census before the next fix: count how the imbalance distributes across actors, not how large it is. Each failure under a shared premise is evidence about the premise.

Two stop rules: (1) stop fixing and re-examine the premise after the second failed fix — no third fix on the same assumption; (2) do not start the next fix before the premise is written down and the census exists.

*Why: fixing under a wrong premise converges on the wrong shape. The third fix assumes the same thing the first two already disproved.*

*Bad:* a third patch tuning the same retry knob after two identical failures. *Good:* "Premise: the load is evenly distributed. Census: one worker holds 90% of the backlog on every run — the premise is the bug; remove the assignment, don't compensate for it."

*Boundary: the census is the exit. If it comes back even across actors, the premise is not the cause — look elsewhere and keep the census as evidence. One failure is just debugging; two failures on the same assumption trigger the rule. When a correct seam for the census doesn't exist, the census itself is a rerunnable script (one artifact the reviewer reruns).*

---

## 11. When the cause is the environment, handle it and monitor it

**Exhausted investigation with an environmental cause is a verdict, not a failure.** When the loop is tight, the hypotheses are falsified, and what remains is timing, environment, or an external system — document what you investigated, implement the handling the cause calls for (retry, timeout, degraded path, clearer error), and add monitoring or logging so the next occurrence arrives with evidence.
*Why: "no root cause" usually means incomplete investigation — but the cases where the cause genuinely lives outside the code still need an engineering response, not a shrug. Handling without monitoring guarantees the next session starts from zero again.*

*Boundary: this section is reached only after the §1–§9 discipline, not instead of it. A cause declared "environmental" without the loop and the falsified hypotheses is incomplete investigation wearing a verdict's clothes.*

---
