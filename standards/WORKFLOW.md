# Workflow Standard

Structured feature development from idea to committed code. Prevents the most common AI coding failure mode: writing code before understanding what to build.

## The Problem

AI assistants default to writing code immediately. This produces:
- Code that solves the wrong problem
- Designs that don't survive contact with the actual codebase
- Security issues discovered after implementation
- Sessions that burn context on rework

## The Solution

A 7-phase workflow that front-loads understanding and defers code until the design is locked.

## Phases

### Phase 1 — Brainstorm

**Trigger:** Any non-trivial feature, bug fix with unclear root cause, or architectural change.

**What happens:**
- Explore the codebase to understand existing patterns
- Ask clarifying questions one at a time to understand purpose, constraints, success criteria
- Propose 2–3 approaches with trade-offs
- Get design approved before writing any code

**Output:** Verbal agreement on approach.

**Skip when:** Single-file fix, typo, config value change, renaming, or the change is obvious and < 20 lines.

---

### Phase 2 — Spec

**What happens:**
- Write the validated design to `docs/specs/YYYY-MM-DD-<topic>.md`
- Include: context (why), architecture, components, data flow, error handling, verification steps
- Self-review: no TBDs, no contradictions, no ambiguity
- Get user approval before proceeding

**Output:** `docs/specs/YYYY-MM-DD-<topic>.md` committed to git.

**Skip when:** The change is too small to warrant a spec (single function, obvious fix).

---

### Phase 3 — Plan

Write the implementation plan to `docs/plans/YYYY-MM-DD-slug.md` and get user approval before proceeding.

Keep the plan file as the durable record of implementation detail. If the session's context is limited, track only the active next steps separately — do not reload the full plan at every session start.

**Skip when:** No spec was needed.

---

### Phase 3.5 — Independent Plan Review (advisory — not one of the 7 counted phases)

Not a gate. This step is deliberately scoped as a recommended practice inserted between Plan and Implement — an advisory review, not an 8th phase.

**Why:** self-review, however adversarial, shares the blind spots of whoever wrote the plan. A 14-task plan for a review-gate mechanism passed its author's self-review (which found 3 real gaps) — a separately-dispatched agent with no context from writing it then found 8 more real, file:line-verified defects, including a Blocking-severity bug the self-review missed.

**What happens:**
- Dispatch a fresh agent with no context from writing the plan, on a capable model
- It independently verifies the plan against its spec and the actual current repo state, including tracing shell-script error-handling behavior and templates/ mirror consistency
- Findings use this repo's `CODE-REVIEW.md` vocabulary (`VERIFIED`/`INFERRED`/`SPECULATIVE`, `Severity`, `Blocking`)
- Any `Blocking: true` finding should be fixed before proceeding; non-blocking findings are disclosed in the plan's Design Note, not silently dropped
- If the review agent itself fails to complete, retry once; if still blocked, disclose to the user and get an explicit decision before proceeding without one

**Output:** A plan verified by someone other than its own author, or an explicit, disclosed decision to proceed without one.

**Recommended for:** any plan with real consequence. Lighter-weight for small or low-risk plans — use judgment, since this step is advisory rather than a hard-and-fast gate.

---

### Phase 4 — Implement (TDD)

**Verification-First:** Before asking Claude to start implementing, state upfront:
- Test cases or expected outputs (even informal: "function should return X given Y")
- The success criteria (what does "done" look like?)
- Any constraints (must not change the API, must stay under N ms, etc.)

This is the single highest-leverage prompt engineering habit — it cuts correction cycles significantly.

For each task in the plan:

```
1. Write the failing test
2. Run it — verify it fails with the expected error
3. Write the minimal code to make it pass
4. Run it — verify it passes
5. Commit
```

Never write implementation before the failing test exists.

**Commit frequency:** After each passing test or logical unit. Never accumulate more than one unit of work in a commit.

**Test Design Principles:**

1. **Test the public interface (the seam), not internals.** A test exercises what a caller can observe — return values, visible side effects, errors — never private state or implementation-specific call sequences. *Why:* tests coupled to internals break on every refactor even when behavior is unchanged, training people to treat red tests as noise instead of signal.

2. **One test per observable behavior — write, implement, verify, commit — before starting the next.** Do not write a batch of tests up front and implement them as a batch. *Why:* batching hides which test is driving which code; a partially-passing batch conceals which minimal-code step actually worked versus which is untested guesswork.

3. **Compute the expected result from an independent source of truth.** Never derive a test's expected value from the same logic or algorithm being tested — that only proves the code agrees with itself, not that either is correct. *Why:* e.g. testing a slug generator by re-implementing the slugify logic inline in the test asserts self-consistency, not correctness; a genuinely wrong algorithm passes its own test every time. Use hand-computed values or a trusted reference, not restated logic.

4. **Start with a tracer bullet.** Before implementing a task's individual units, write and pass one test exercising the smallest meaningful path through the task end-to-end — not a unit in isolation. *Why:* this surfaces integration/wiring problems (imports, plumbing, environment) immediately, instead of after building N isolated units that turn out not to connect.

---

### Phase 5 — Simplify

After implementation is complete:
- Review all changed files for clarity, consistency, and maintainability
- Remove dead code, redundant logic, unnecessary abstraction
- Rename for clarity where needed
- Do NOT change behavior — only improve readability

**Output:** Clean, committed code.

---

### Phase 6 — Security Review

Scan the current diff against 9 patterns:

| Severity | Patterns |
|----------|---------|
| `[CRITICAL]` | Hardcoded secrets, command injection, SQL injection |
| `[HIGH]` | Unvalidated external input, missing auth checks, insecure deserialization |
| `[MEDIUM]` | XSS, exposed error details, unsafe eval/exec |
| `[LOW]` | Patterns safe now but risky under future changes |

**Resolution:** All `[CRITICAL]` and `[HIGH]` findings must be resolved before proceeding. `[MEDIUM]` and `[LOW]` are documented in the PR.

---

### Phase 7 — Commit

```bash
git add <specific files — never git add -A blindly>
git commit -m "feat: <what was built and why in one line>"
```

Never commit `.env`, credentials, or unrelated changes.

---

## Quick Reference

| Phase | Skip when | Output |
|-------|-----------|--------|
| 1. Brainstorm | Trivial change | Agreed approach |
| 2. Spec | No spec needed | docs/specs/*.md |
| 3. Plan | No spec needed | docs/plans/*.md |
| 3.5 Independent Plan Review (advisory) | Small/low-risk plan | Verified plan or documented decision to proceed without |
| 4. Implement | — | Committed, tested code |
| 5. Simplify | — | Clean committed code |
| 6. Security Review | — | Resolved findings |
| 7. Commit | — | Clean commit |

## Context Management

### When to Hand Off
Trigger a handoff when context reaches ~40% or the user types "Handoff":
1. Stop all work immediately
2. Write `handoff.md` to the project root (format: accomplishments, files changed, service state, commands to resume, pending tasks)
3. Respond only: "Handoff ready at `handoff.md`. Start a new conversation."
4. Do not continue

On next session: read `handoff.md` first, then continue.

### Token Budget
- Compact/summarize at task boundaries (not mid-task): after planning, after debugging, before switching context
- Stay ahead of mid-task interruption: compact manually before context runs low
