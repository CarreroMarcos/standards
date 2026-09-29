---
title: Workflow Standard
version: "2.6"
scope: The seven-phase development workflow
consult_when: "When starting or planning a unit of work, from idea through clean commit."
last_reviewed: 2026-09-29
---

# Workflow Standard

Portable feature-development discipline — seven phases: brainstorm → spec → plan → implement (TDD) → simplify → security review → commit.

Prevents the most common AI coding failure mode: writing code before understanding what to build.

## Sections

- **Phase 1 — Brainstorm** — approaches and trade-offs before code; when to skip
- **Phase 2 — Spec** — the validated design doc
- **Phase 3 — Plan** — the implementation plan
- **Phase 3.5 — Independent Plan Review** — adversarial plan check (advisory)
- **Recorded decisions** — decisions on framed questions; executed, not re-litigated
- **Phase 4 — Implement (TDD)** — test-first implementation
- **Phase 5 — Simplify** — the simplification pass
- **Phase 6 — Security Review** — the security gate
- **Phase 7 — Commit** — changelog, deprecation, commit discipline
- **Handoff** — passing work between agents

## Phase 1 — Brainstorm

For any non-trivial feature, bug fix with unclear root cause, or architectural change.

- Explore the codebase to understand existing patterns first
- Ask clarifying questions one at a time: purpose, constraints, success criteria
- Propose 2–3 approaches with trade-offs
- Get design approved before writing any code

**Output:** agreed approach.

**Skip when:** Single-file fix, typo, config value change, renaming, or the change is obvious and < 20 lines — or the spec/HLD already pins the verification design, so there is nothing to design.

## Phase 2 — Spec

Write the validated design to `docs/specs/YYYY-MM-DD-<topic>.md`: context (why), architecture, components, data flow, error handling, verification steps.

- Self-review: no TBDs, no contradictions, no ambiguity
- Get user approval before proceeding
- For batch/async sources, define poison-message behavior (fail loudly — route to the dead-letter queue, never swallow) and partial-failure semantics (per-item results so only failed items retry, never the whole batch)

**Output:** the spec, committed to git.

**Skip when:** The change is too small to warrant a spec (single function, obvious fix).

## Phase 3 — Plan

Write the implementation plan to `docs/plans/YYYY-MM-DD-slug.md` and get user approval before proceeding.

The plan file is the durable record of implementation detail. Track only the active next steps separately at each session start — do not reload the full plan into context every time.

Spend the reasoning budget on planning, not execution — plan in the strongest mode available; implement in a cheaper one.

End the plan with an acceptance contract: checkable pass/fail criteria, not prose.

**Skip when:** No spec was needed.

## Recorded decisions

A recorded decision is a decision on a framed question — the options considered, the recommendation, who decided — written to the decision log with date and scope. It constrains later work but does not replace phase gates: later phases verify compliance with it rather than re-deriving it.

**A pinned decision is executed, not re-litigated.** Reopening one is itself a decision — it needs a new framed question and a new log entry, not a quiet reinterpretation mid-task.

## Phase 3.5 — Independent Plan Review (advisory — not one of the seven counted phases)

Between Plan and Implement: an advisory review, not a gate. Self-review shares the author's blind spots; an independent check finds what it can't.

- Dispatch a fresh agent with no authorship context, on a capable model
- It verifies the plan against its spec and the actual current repo state
- Findings use the project's review vocabulary — `CODE-REVIEW.md` (`VERIFIED` / `INFERRED` / `SPECULATIVE`, `Severity`, `Blocking`)
- Any `Blocking: true` finding should be fixed before proceeding; disclose non-blocking findings in the plan's Design Note — never drop them silently
- If the review agent fails to complete, retry once; still blocked → disclose to the user and get an explicit decision before proceeding without one
- The reviewer also grills the acceptance contract. Two modes: when the contract is open, it negotiates the definition of done with the author before code starts — what the acceptance checks are, and who runs them. When the contract is pre-registered and decision-constrained (a recorded decision already fixed the bounds), there is nothing to negotiate — the review verifies the plan *against the decision* instead: does it stay inside the ruled bounds, or does it quietly reopen them?

**Recommended for:** any plan with real consequence. Lighter for small or low-risk plans — use judgment.

Principle: `ENGINEERING_PRINCIPLES.md` §8 "Independent Review for Significant Work".

## Phase 4 — Implement (TDD)

**Verification-First:** Before asking the agent to start implementing, state upfront:
- Test cases or expected outputs (even informal: "function should return X given Y")
- The success criteria (what does "done" look like?)
- Any constraints (must not change the API, must stay under N ms, etc.)

This is the single highest-leverage prompt engineering habit — it cuts correction cycles significantly.

Example:

    Implementing `parseRetryPolicy`:
    - Tests: `parse("attempts=0")` fails with "attempts must be ≥ 1"
    - Success: backoff bounds covered; worker integration green
    - Constraints: the `RetryPolicy` public API stays unchanged

For each task in the plan:

    1. Write the failing test
    2. Run it — verify it fails with the expected error
    3. Write the minimal code to make it pass
    4. Run it — verify it passes
    5. Commit

Never write implementation before the failing test exists.

**Eval-shaped work (prompt changes, corpus re-runs) uses a different cycle.** The gate already failed — that is the failing test. Change the prompt, re-run the corpus, compare gate verdicts before/after, commit as one unit. One prompt iteration + one corpus re-run = one logical unit; per-test commits only make sense when the test cycle is seconds, not tens of minutes. Name the train/hold-out split the reported numbers came from — iterate against one split, confirm on the hold-out (e.g. frozen traps), and record which split each number belongs to.

**Acceptance tests are external truth.** Agent-written tests are unreliable judges — they test what the code does, not what it should do, and agents dodge their own acceptance criteria. Acceptance tests are authored or grilled by someone other than the implementer (you, or an independent agent), committed as checkpoints, and protected from the implementer — the implementer never edits them. Full re-verification runs before accept.
- **Minimum compliant path when no independent author exists** (solo session): the plan's acceptance contract serves as the checkpoint. The implementer may write the tests, then performs a documented adversarial re-read of them — checking each assertion against the contract, not the implementation — recorded in the plan's Design Note before the gate. Who authored what is stated in the Note; the gate still runs full re-verification.

**If a test looks wrong, stop and fix the test.** Never contort the code to satisfy a flawed test — strict "stop if the tests look flawed" discipline is what separates testing from specification gaming.

**"Tests pass" is not "mergeable."** Roughly half of test-passing benchmark PRs would not survive a real merge review (METR, Mar 2026) — green tests are necessary, not sufficient. The security review and simplify phases still apply.

**Commit frequency:** After each passing test or logical unit. Never accumulate more than one unit of work in a commit.

**Test design:**

- **One test per observable behavior — write, implement, verify, commit — before starting the next.** Do not write a batch of tests up front and implement them as a batch. *Why:* batching hides which test is driving which code.
- The remaining design rules live in `ENGINEERING_PRINCIPLES.md` §4: "Test Observable Behavior" (test the seam), "Independent Expected Values" (expected values from a source independent of the code), "Tracer Bullet" (one end-to-end test first).
- **Property-based tests for domains with properties.** Round-trips, invariants, equivalence (Hypothesis). Example tests check the cases you thought of; property tests check the ones you didn't — off-by-ones, empty inputs, unicode, boundary lengths. Keep concrete example tests alongside; don't use it where the assertion would re-implement the function.

## Phase 5 — Simplify

After implementation is complete:

- Review all changed files for clarity, consistency, and maintainability
- Remove dead code — observe freely, remove only with proof (principle: `ENGINEERING_PRINCIPLES.md` §3 "Dead-Code Removal Is a Separate Authority")
- Rename for clarity where needed
- Do NOT change behavior — only improve readability

**Output:** clean, committed code.

## Phase 6 — Security Review

Scan the diff against these patterns:

| Severity | Patterns |
|----------|----------|
| `[CRITICAL]` | Hardcoded secrets, command injection, SQL injection |
| `[HIGH]` | Unvalidated external input, missing auth checks, insecure deserialization |
| `[HIGH]` | Untrusted external content fed to an LLM (CI logs, issue bodies, tool output, PR diffs / code under review) — prompt-injection surface |
| `[HIGH]` | Model output or external content published to a public surface without redaction (CI logs routinely contain leaked secrets) |
| `[MEDIUM]` | XSS, exposed error details, unsafe eval/exec |
| `[LOW]` | Patterns safe now but risky under future changes |

The two `[HIGH]` LLM rows are the injection vocabulary from `AGENTIC-SAFETY.md` — use its defenses (delimit untrusted regions as data-only, banner model output, redact before publish), not just this table's scan.

Fix all `[CRITICAL]` and `[HIGH]` findings before proceeding to Phase 7. Disclose `[MEDIUM]` and `[LOW]` — never drop them silently.

Agent-generated code gets two extra checks: hallucinated dependencies (verify every suggested package at the registry — `SUPPLY-CHAIN.md`) and over-permissioned tool use (does the code grant the agent more authority than the task needs?).

When a recurring bug class surfaces, **propose** the rule addition to the human or orchestrator (what the class is, where it bit, the exact wording) — do not write it into the agent's rules file (`AGENTS.md` / `CLAUDE.md`) yourself. Editing your own governing instructions mid-task is out of scope and a bad write corrupts the file that governs you.

Full review vocabulary and procedure: `CODE-REVIEW.md`.

## Phase 7 — Commit

    git add <specific files — never git add -A blindly>
    git commit -m "feat: <what was built and why in one line>"

Never commit `.env`, credentials, or unrelated changes. (Credential rules: `SECRETS.md`.)

Update the changelog in the same commit — Keep-a-Changelog sections (Added/Changed/Deprecated/Removed/Fixed/Security), one entry per user-visible change, curated prose. Users decide whether to upgrade by reading the changelog, not the diff.

Deprecating a published contract: three phases — warn (name the replacement and the removal version) → document (changelog entry in the same commit) → remove in a major version after a real warning window. Principle: `ENGINEERING_PRINCIPLES.md` §6 "Preserve Backward Compatibility".

This standard ends at a clean commit. What happens between push and merge — review rounds, gates, merge discipline — is the dev loop (`DEV-LOOP.md`).

## Handoff

Trigger a handoff when context reaches ~40% or the user types "Handoff":

1. Stop all work immediately
2. Write `handoff.md` to the project root — accomplishments, files changed, service state, commands to resume, pending tasks
3. Respond only: "Handoff ready at `handoff.md`. Start a new conversation."
4. Do not continue

Next session: read `handoff.md` first, then continue.

Prefer a fresh session over a compacted one between interactive coding phases — context reset with a structured handoff beats compaction. For unattended long-running eval captures, the handoff unit is the evidence artifacts + resume command, and session persistence is expected. After any compaction, re-read the plan before writing code: plan drift sets in as context decays, and the plan is the anchor.

Principle: `ENGINEERING_PRINCIPLES.md` §9 "Make handoffs file-backed".
