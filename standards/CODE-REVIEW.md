---
title: Code Review Standard
version: "2.4"
scope: How to run code reviews, including AI-assisted review
consult_when: "When reviewing a diff - yours, a bot's, or another agent's."
last_reviewed: 2026-09-29
---

# Code Review Standard

What a complete code review is and how findings are evidenced. Advisory — owning gates define pass/fail.

A review is complete when every required domain is covered, every finding carries evidence, the opposition review answered its four questions, and a verdict is stated. This standard does not mandate agent topology, model, or phase count.

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
- **9. Remediation** — review identifies; remediation needs explicit request
- **10. Scale the ceremony to the diff** — trivial / small / large tiers; blast radius, not line count

## 1. Coverage

Cover every change for: Security, Correctness, Maintainability, Testing, and Architecture Drift — changes that contradict established patterns in the project or introduce abstractions not established elsewhere in the project.

Activate conditional domains when the change triggers them:
- Performance — runtime-sensitive changes (tight loops, DB queries, I/O paths)
- Accessibility — UI file changes

Severity scale: `Critical → High → Medium → Low → Info`

## 2. Finding schema

Give every finding: Domain, Severity, Location, Evidence, Basis, Impact, Recommendation, Blocking.

Value scales: Severity is `Critical | High | Medium | Low | Info`. Blocking is `true | false`. Basis is `VERIFIED | INFERRED | SPECULATIVE`.

Compatibility note: `Basis` replaced the earlier `Confidence` field — any parser keyed on `Confidence` must update.

## 3. Basis classification

The `Basis` field classifies how the reviewer arrived at the finding.

| Basis | Meaning |
|---|---|
| `VERIFIED` | Agent directly observed the defect at the cited location |
| `INFERRED` | Agent reasoned from a code pattern; behavior not directly confirmed |
| `SPECULATIVE` | Suspected risk; consequence is uncertain |

Ground the evidence to the basis. `VERIFIED` requires `file:line` + code excerpt or precise behavioral description. `INFERRED` requires `file:line` + the reasoning chain. `SPECULATIVE` requires `file:line` + the observed trigger (the specific code pattern that raised the concern) + an explicit statement of why the consequence cannot be confirmed. The uncertainty is about the consequence, not the existence of the code. Prose alone ("this may cause...") is not evidence.

**State absence and attribution claims as scope + mechanism + output.** A claim that something does *not* exist — no reference, no test, unreachable — or that one thing cost or caused another is only `VERIFIED` when the finding states the scope actually searched as the mechanism that established it: shell command, driver invocation, or artifact path.

- Not `VERIFIED` — the conclusion alone: *"no test covers THING"*
- `VERIFIED` — the conclusion **plus** the command that established it and what it returned: *"no test covers THING — `grep -rl 'PATTERN' PATHS` returned OUTPUT"*

For attribution, show the decomposition summing to the measured whole — *"N net = A from the change itself, B from unrelated edits in the same commit, A + B = N against the measured whole"* — not *"this change cost N bytes"*.

**Match the command's reach to the assertion.** A filename filter cannot establish a claim about file *contents*; a single-directory search cannot establish a claim about the repository; a pattern written for the wrong syntax returns zero matches indistinguishable from a true absence. Where reach and assertion differ, the finding is **unsupported** — not necessarily wrong, but not established. Only a stated scope lets a second reader see the gap.

Run the command before writing its output. An unrun example is the same defect as an unrun test.

## 4. Blocking semantics

`Blocking: true` requires `Severity >= High AND Basis != SPECULATIVE`.

- Critical/High + VERIFIED or INFERRED → may be `Blocking: true`
- Any severity + SPECULATIVE → `Blocking: false`
- Medium/Low/Info → `Blocking: false` by default

Default every High finding to `Blocking: true` unless you have specific evidence that the risk is contained.

## 5. Report sections

Assemble the report after all findings are collected: gather every finding first, then sort them into these sections in order: Scope, Files reviewed, Domain coverage, Supported Findings, Predicted Risks (omit if empty), Testing gaps, Opposition review, Verdict.

**Supported Findings** — VERIFIED and INFERRED findings, each row prefixed `[VERIFIED]` or `[INFERRED]` in the Basis column.

**Predicted Risks** — SPECULATIVE findings. Omit this section entirely when no SPECULATIVE findings exist.

## 6. Opposition review

Answer all four explicitly — this is not a summary pass:
1. Is any Critical/High finding overstated? Give counter-evidence.
2. What was not reviewed that could matter?
3. Which findings might be false positives in this codebase's context?
4. What cross-domain risk did no single domain catch?

A passing opposition review answers all four. A general statement that none apply is a failure.

## 7. Evidence integrity

**A check that cannot fail does not count as a check.** A test whose assertion holds whether the guarded code works, is broken, or is deleted provides no regression protection, however green it runs. Before offering a test as evidence for a guard, break the guard and confirm the test goes red.

Two traps, both hit while proving this rule:
- **A mutation that changes bytes has not necessarily changed behavior.** Replacing a command with a no-op that produces the same output looks applied and proves nothing. Confirm the mutated build behaves differently on a canary input before concluding a test "stayed green".
- **Redundant match paths mask mutations.** Where two independent code paths can produce the same verdict, mutating one leaves the other answering. Mutate all of them, or the result is a false negative.

**A self-attested completion counts as UNMET.** A completion claim supported only by the agent's own assertion is not evidence — it ranks *below* an openly declared gap, which at least is accurate about where the work stopped.

A Testing assessment that reports "suite passes" without having established that the relevant assertions discriminate has reported an execution, not a verification. State what was run, what it returned, and — for anything guarding a security or correctness boundary — what happens to it under mutation. A ticked checkbox whose evidence line still reads `pending` is worse than an empty box: proving a command ran and matched expected text is strictly weaker than proving the check discriminates.

## 8. Failure criteria

The review fails on any of:
- A required domain was skipped
- Any finding lacks a `file:line` reference or an Evidence field
- Evidence does not materially support the finding claim
- A `SPECULATIVE` finding is marked `Blocking: true`
- No Testing assessment, or a Testing assessment offering a non-discriminating test as evidence for a guard
- A completion claim presented as verified with no command and no output behind it
- An absence or attribution claim stated without the scope actually searched, as the command
- No Opposition review
- Repo mutation during review without explicit user request

## 9. Remediation

Review identifies and recommends by default. Remediation (editing files, generating tests, applying fixes) requires explicit user request after findings are presented.

## 10. Scale the ceremony to the diff

Not every diff earns all ten sections. Match the review's weight to the change's blast radius — the trigger is what the change can break, not its line count.

Evidence-only tasks (re-captures, re-runs) get ceremony scaled to the decision they gate, not to a diff that doesn't exist.

- **Trivial (no behavior change — comments, renames, formatting, config value bumps):** one pass confirming the change is purely mechanical; a verdict and one line saying what you checked. No finding schema, no opposition review.
- **Small (one concern, one file or a focused set):** cover only the domains the diff can affect — §1's conditional logic applies to the whole review, so skip domains the change can't touch. Findings still use the schema, but the report may be a short list. Opposition review is a paragraph answering the four questions briefly, not four essays.
- **Large or risky (multi-file, behavior change, or anything touching auth, money, data loss, or security boundaries):** the full standard, no shortcuts.

A 5-line auth change gets the full treatment; a 200-line rename gets the light one. When in doubt, go heavier and say why.
