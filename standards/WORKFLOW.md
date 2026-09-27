# Workflow Standard

Portable feature-development discipline — seven phases: brainstorm → spec → plan → implement (TDD) → simplify → security review → commit.

Prevents the most common AI coding failure mode: writing code before understanding what to build.

## Phase 1 — Brainstorm

For any non-trivial feature, bug fix with unclear root cause, or architectural change.

- Explore the codebase to understand existing patterns first
- Ask clarifying questions one at a time: purpose, constraints, success criteria
- Propose 2–3 approaches with trade-offs
- Get design approved before writing any code

**Output:** agreed approach.

**Skip when:** Single-file fix, typo, config value change, renaming, or the change is obvious and < 20 lines.

## Phase 2 — Spec

Write the validated design to `docs/specs/YYYY-MM-DD-<topic>.md`: context (why), architecture, components, data flow, error handling, verification steps.

- Self-review: no TBDs, no contradictions, no ambiguity
- Get user approval before proceeding

**Output:** the spec, committed to git.

**Skip when:** The change is too small to warrant a spec (single function, obvious fix).

## Phase 3 — Plan

Write the implementation plan to `docs/plans/YYYY-MM-DD-slug.md` and get user approval before proceeding.

The plan file is the durable record of implementation detail. Track only the active next steps separately at each session start — do not reload the full plan into context every time.

**Skip when:** No spec was needed.

## Phase 3.5 — Independent Plan Review (advisory — not one of the seven counted phases)

Between Plan and Implement: an advisory review, not a gate. Self-review shares the author's blind spots; an independent check finds what it can't.

- Dispatch a fresh agent with no authorship context, on a capable model
- It verifies the plan against its spec and the actual current repo state
- Findings use the project's review vocabulary — `CODE-REVIEW.md` (`VERIFIED` / `INFERRED` / `SPECULATIVE`, `Severity`, `Blocking`)
- Any `Blocking: true` finding should be fixed before proceeding; disclose non-blocking findings in the plan's Design Note — never drop them silently
- If the review agent fails to complete, retry once; still blocked → disclose to the user and get an explicit decision before proceeding without one

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

**Commit frequency:** After each passing test or logical unit. Never accumulate more than one unit of work in a commit.

**Test design:**

- **One test per observable behavior — write, implement, verify, commit — before starting the next.** Do not write a batch of tests up front and implement them as a batch. *Why:* batching hides which test is driving which code.
- The remaining design rules live in `ENGINEERING_PRINCIPLES.md` §4: "Test Observable Behavior" (test the seam), "Independent Expected Values" (expected values from a source independent of the code), "Tracer Bullet" (one end-to-end test first).

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
| `[MEDIUM]` | XSS, exposed error details, unsafe eval/exec |
| `[LOW]` | Patterns safe now but risky under future changes |

Fix all `[CRITICAL]` and `[HIGH]` findings before proceeding to Phase 7. Disclose `[MEDIUM]` and `[LOW]` — never drop them silently.

Full review vocabulary and procedure: `CODE-REVIEW.md`.

## Phase 7 — Commit

    git add <specific files — never git add -A blindly>
    git commit -m "feat: <what was built and why in one line>"

Never commit `.env`, credentials, or unrelated changes. (Credential rules: `SECRETS.md`.)

This standard ends at a clean commit. What happens between push and merge — review rounds, gates, merge discipline — is the dev loop (`DEV-LOOP.md`).

## Handoff

Trigger a handoff when context reaches ~40% or the user types "Handoff":

1. Stop all work immediately
2. Write `handoff.md` to the project root — accomplishments, files changed, service state, commands to resume, pending tasks
3. Respond only: "Handoff ready at `handoff.md`. Start a new conversation."
4. Do not continue

Next session: read `handoff.md` first, then continue.

Principle: `ENGINEERING_PRINCIPLES.md` §9 "Make handoffs file-backed".
