---
title: Code Review Standard
version: "2.8"
scope: How to run code reviews, including AI-assisted review
consult_when: "When reviewing a diff — yours, a bot's, or another agent's — especially when tempted to skim because 'the tests pass' or 'it's just a small diff'."
last_reviewed: 2026-10-08
---

# Code Review Standard

What a complete code review is and how findings are evidenced. Advisory — owning gates define pass/fail.

**Core principle:** a review is complete when every required domain is covered, every finding carries evidence, the opposition review answered its four questions, and a verdict is stated.

This standard does not mandate agent topology, model, or phase count.

Scale the ceremony to the diff (§10) — a rename doesn't earn an opposition review.

## Sections

- **1. Coverage** — the five required domains plus conditional ones
- **2. Finding schema** — Domain, Severity, Location, Evidence, Basis, Impact, Recommendation, Blocking
- **3. Basis classification** — VERIFIED / INFERRED / SPECULATIVE and what each requires
- **4. Blocking semantics** — what may block and what never does
- **5. Report sections** — assembly order for the finished report
- **6. Opposition review** — the four questions, answered explicitly
- **7. Evidence integrity** — a check that cannot fail does not count; mutation discipline
- **8. Failure criteria** — what fails the review itself
- **9. Remediation** — independent reviewers identify and recommend; self-review fixes its own findings
- **10. Scale the ceremony to the diff** — trivial / small / large tiers; blast radius, not line count

## 1. Coverage

**Cover every change for five domains:** Security, Correctness, Maintainability, Testing, and Architecture Drift — changes that contradict established patterns in the project or introduce abstractions not established elsewhere in the project. Security means the corpus's rules — lethal trifecta, Rule of Two (AGENTIC-SAFETY.md), secret inventory (SECRETS.md) — not just generic checks.

Activate conditional domains when the change triggers them:

- Performance — runtime-sensitive changes (tight loops, DB queries, I/O paths)
- Accessibility — UI file changes

Severity scale: `Critical → High → Medium → Low → Info`

## 2. Finding schema

**Give every finding eight fields:** Domain, Severity, Location, Evidence, Basis, Impact, Recommendation, Blocking. Impact is the concrete consequence if the finding is real; Severity is the risk rating. Cite the trust level in security findings (TRUST-CLASSIFICATION.md): `Issue: SQL injection via UNTRUSTED user input` — the level gates how the finding is handled.

Value scales: Severity is `Critical | High | Medium | Low | Info`. Blocking is `true | false`. Basis is `VERIFIED | INFERRED | SPECULATIVE`.

Compatibility note: `Basis` replaced the earlier `Confidence` field — any parser keyed on `Confidence` must update.

## 3. Basis classification

**The `Basis` field classifies how the reviewer arrived at the finding.**

| Basis | Meaning |
|---|---|
| `VERIFIED` | Agent directly observed the defect at the cited location |
| `INFERRED` | Agent reasoned from a code pattern; behavior not directly confirmed |
| `SPECULATIVE` | Suspected risk; consequence is uncertain |

Unmasked verify (DEV-LOOP.md, Verification terms): ground `VERIFIED` in the real file and real output — never in a diff hunk, a summary, or another agent's report.

Ground the evidence to the basis. `VERIFIED` requires `file:line` + code excerpt or precise behavioral description. `INFERRED` requires `file:line` + the reasoning chain. `SPECULATIVE` requires `file:line` + the observed trigger (the specific code pattern that raised the concern) + an explicit statement of why the consequence cannot be confirmed. The uncertainty is about the consequence, not the existence of the code. Prose alone ("this may cause...") is not evidence.

**State absence and attribution claims as scope + mechanism + output.** A claim that something does *not* exist — no reference, no test, unreachable — or that one thing cost or caused another is only `VERIFIED` when the finding states the scope actually searched as the mechanism that established it: shell command, driver invocation, or artifact path.

- Not `VERIFIED` — the conclusion alone: *"no test covers THING"*
- `VERIFIED` — the conclusion **plus** the command that established it and what it returned: *"no test covers THING — `grep -rl 'PATTERN' PATHS` returned OUTPUT"*

For attribution, show the decomposition summing to the measured whole — *"N net = A from the change itself, B from unrelated edits in the same commit, A + B = N against the measured whole"* — not *"this change cost N bytes"*.

**Match the command's reach to the assertion.** A filename filter cannot establish a claim about file *contents*; a single-directory search cannot establish a claim about the repository; a pattern written for the wrong syntax returns zero matches indistinguishable from a true absence. Where reach and assertion differ, the finding is **unsupported** — not necessarily wrong, but not established. Only a stated scope lets a second reader see the gap.

Run the command before writing its output. An unrun example is the same defect as an unrun test.

## 3.5 The evidence ladder

**Turn Basis from a classification into a procedure.** For each fact a finding depends on, climb as far down the ladder as is cheap — and state where you stopped.

| Rung | What it is | What it earns |
|---|---|---|
| 1 | You said so. Worthless on its own. | Prose — not evidence. |
| 2 | You pointed at the line. A real `file:line`, or the library's own source. | The citation every Basis requires. |
| 3 | You showed the bad case can't happen. You walked the failure step by step and it doesn't reach. | The reasoning chain that earns `INFERRED`. |
| 4 | You ran it. A script or test that calls the real code and fails loud if you're wrong. | `VERIFIED`, by observation. |
| 5 | You reproduced it in the running app. | `VERIFIED`, by reproduction. |

A `SPECULATIVE` finding is a ladder stopped at rung 2 — the trigger line is cited and the report states why the climb can't continue.

**Find the one fact it's safe because of.** Most findings rest on a single load-bearing fact — "this call only touches already-dead entries", "the input is validated upstream". Name that fact and climb the ladder on it. One climbed fact clears more maybes than ten listed risks.

**Point at what a symbol search misses.** Rung 2 is not only grep. The line that decides the finding may live in the library's own source, the pinned version, a wire format, a DB column, a feature flag, or code three hops downstream. A symbol search that misses these leaves the rung unreached.

- Bad — the claim without the climb: *"The retry can't loop forever — `MAX_ATTEMPTS` bounds it."* (Rung 1: said so.)
- Good — the fact climbed: *"The retry can't loop forever — the load-bearing fact is `MAX_ATTEMPTS=3` bounding the loop at `worker/poller.py:41`; walked the exit path and the bad case doesn't reach (rung 3). Callers of `poll()` checked — all three pass the bounded config."*

- Why: the Basis classification says what the finding is; the ladder records what you did to earn it — a second reader sees exactly how far the claim was pushed, and where it stopped.
- Boundary: stop where the next rung costs more than the finding's severity justifies, and state the stopping rung. The stopping point is part of the evidence, not a weakness. A cheap rung-4 script usually beats a long argument for rung 3.

## 4. Blocking semantics

**`Blocking: true` requires `Severity >= High` AND `Basis != SPECULATIVE`.**

- Critical/High + VERIFIED or INFERRED → may be `Blocking: true`
- Any severity + SPECULATIVE → `Blocking: false`
- Medium/Low/Info → `Blocking: false` by default

**Default every High finding to `Blocking: true`.** Downgrade only with specific evidence that the risk is contained — a cited test, a control that mitigates it, or a blast radius bounded in the diff — not a feeling.

## 5. Report sections

**Assemble the report after all findings are collected:** gather every finding first, then sort them into these sections in order: Scope, Files reviewed, Domain coverage, Supported Findings, Predicted Risks (omit if empty), Testing gaps, Opposition review, Verdict.

**Supported Findings** — VERIFIED and INFERRED findings; each row's Basis column carries the classification.

**Predicted Risks** — SPECULATIVE findings. Omit this section entirely when no SPECULATIVE findings exist.

**Verdict** — carries the Act On / Consider / Dismissed lists (§6.5).

## 6. Opposition review

**Answer all four explicitly — this is not a summary pass:**

1. Is any Critical/High finding overstated? Give counter-evidence.
2. What was not reviewed that could matter?
3. Which findings might be false positives in this codebase's context?
4. What cross-domain risk did no single domain catch?

A passing opposition review answers all four. A general statement that none apply is a failure.

## 6.5 Reviewer judgment

**Apply judgment to the findings list before writing the report.** Opposition review asks whether any finding is overstated; this section is the filter that decides what survives.

**Watch for nitpick gravity.** Reviewers, especially adversarial ones, fill their review — find nothing critical and the nits inflate to fill the space. If every finding is a nit or a style preference, the code is probably fine. Say so in the verdict, and shrink the report to match.

**Trace the call site before raising a hypothetical.** "What if someone passes null here?" is a finding only when a caller can actually pass null. Read the callers — a reviewer working from a diff can't always see the call chain; you can. Validated upstream or blocked by the type system means the finding dies there.

- Bad — the hypothetical without the trace: *"What if `user` is null?"* — no caller examined.
- Good — the trace that makes it real: *"What if `user` is null?"* — traced to `api/handlers.py:88`, which passes unvalidated input. Or the trace that kills it: `middleware/validate.py:12` rejects nulls — dismissed, reason stated.

**Dismiss the different-approach finding.** "I prefer a different approach" is not a bug, not a design flaw, and not actionable — unless the reviewer shows a concrete problem with the current approach. No concrete problem means dismissal, with the reason stated.

- Bad — a preference wearing a finding's clothes: *"Extract this into a helper for readability."*
- Good — dismissed with the reason: *"Extract this into a helper — no concrete problem shown with the inline version; 12 lines, one caller. Kept as is."*

**Keep findings that name a concrete execution path.** Three signals a finding survives the filter: independent reviewers flag the same issue, the finding walks a real call path instead of a hypothetical, or it exposes a gap in your own mental model of the code. Security and correctness findings get this scrutiny even when they come from a single reviewer — discomfort is not a filter.

**Cap the Act On list at five.** A verdict the reader can act on in one sitting is the goal. More than five "Act On" items means the filter isn't filtering — push the rest to Consider or Dismissed.

**Show the Dismissed section — it's the trust mechanism.** The verdict carries Act On, Consider, and Dismissed. Showing what you rejected and why lets the reader override your judgment where they disagree; hidden rejections force the reader to redo the review to check your work.

- Why: adversarial energy produces noise — judgment is what turns a findings dump into a review you can ship after.
- Boundary: this section filters the independent reviewer's report; self-review fixes its own findings (§9). Judgment never overrides evidence — a finding with a concrete path survives the filter, however uncomfortable.

---

## 7. Evidence integrity

**A check that cannot fail does not count as a check.** A test whose assertion holds whether the guarded code works, is broken, or is deleted provides no regression protection, however green it runs. Before offering a test as evidence for a guard, break the guard and confirm the test goes red.

Two traps, both hit while proving this rule:

- **A mutation that changes bytes has not necessarily changed behavior.** Replacing a command with a no-op that produces the same output looks applied and proves nothing. Confirm the mutated build behaves differently on a canary input before concluding a test "stayed green".
- **Redundant match paths mask mutations.** Where two independent code paths can produce the same verdict, mutating one leaves the other answering. Mutate all of them, or the result is a false negative.

**A self-attested completion counts as UNMET.** A completion claim supported only by the agent's own assertion is not evidence — it ranks *below* an openly declared gap, which at least is accurate about where the work stopped.

A Testing assessment that reports "suite passes" without having established that the relevant assertions discriminate has reported an execution, not a verification. State what was run, what it returned, and — for anything guarding a security or correctness boundary — what happens to it under mutation. A ticked checkbox whose evidence line still reads `pending` is worse than an empty box: proving a command ran and matched expected text is strictly weaker than proving the check discriminates.

**Rank checks by circularity.** "Can the agent pass this check with code that doesn't work?" Require at least one non-circular (external) check per gate.

- Why: a check the agent can satisfy with broken code is a self-attestation in disguise; external checks are the ones that can't be gamed from inside.
- Boundary: generalizes WORKFLOW.md's "acceptance tests are external truth" beyond acceptance tests — it doesn't replace it.
- Verdict: the Testing assessment names the external check — a gate whose evidence lists no external check fails §8.

## 8. Failure criteria

**The review fails on any of:**

- A required domain was skipped
- Any finding lacks a `file:line` reference or an Evidence field
- Evidence does not materially support the finding claim
- A `SPECULATIVE` finding is marked `Blocking: true`
- No Testing assessment, or a Testing assessment offering a non-discriminating test as evidence for a guard
- A completion claim presented as verified with no command and no output behind it
- An absence or attribution claim stated without the scope actually searched, as the command
- No Opposition review (where the tier requires one)
- Repo mutation during review without explicit user request

## 9. Remediation

**An *independent* reviewer identifies and recommends; it doesn't remediate unasked.** When you're reviewing your own diff, fixing your own findings is the job.

## 10. Scale the ceremony to the diff

**Not every diff earns all ten sections.** Match the review's weight to the change's blast radius — the trigger is what the change can break, not its line count.

Evidence-only tasks (re-captures, re-runs) get ceremony scaled to the decision they gate, not to a diff that doesn't exist.

- **Trivial (no behavior change — comments, renames, formatting, config value bumps):** one pass confirming the change is purely mechanical; a verdict and one line saying what you checked. No finding schema, no opposition review.
- **Small (one concern, typically 1–3 files):** cover only the domains the diff can affect — §1's conditional logic applies to the whole review, so skip domains the change can't touch. Findings still use the schema, but the report may be a short list. Opposition review is a paragraph answering the four questions briefly, not four essays.
- **Large or risky (multi-file, behavior change, or anything touching auth, money, data loss, or security boundaries):** the full standard, no shortcuts.

A 5-line auth change gets the full treatment; a 200-line rename gets the light one. When in doubt, go heavier and say why.

| Thought | Reality |
|---|---|
| "It's only N lines" | Blast radius, not line count, sets the ceremony — a 5-line auth change gets the full treatment. |
| "When in doubt, keep it light" | When in doubt, go heavier and say why. |
