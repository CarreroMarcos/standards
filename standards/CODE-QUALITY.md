---
title: Code Quality
version: "2.6"
scope: Code quality rules: comments, dead code, testing, verification
consult_when: "When writing or refactoring code and you want the per-task quality rules."
last_reviewed: 2026-09-29
---

# Code Quality

Operational quality rules for AI-generated code. Design principles live in
`ENGINEERING_PRINCIPLES.md` (cited below as §N); this file holds only what an
agent must do or report on each task. Every rule below serves one goal: code a
stranger — human or agent — can read and safely change. Refactorability is the
bar; the rules are how you reach it. Deliberately not carried over: per-language
`extensions/<language>.md` files, metrics tables, and CI/pre-commit enforcement
boilerplate — nothing in this repo reads them.

## Sections

- **1. Prove Completion, Don't Claim It** — every "done" carries executed evidence, not assertion
- **2. Be Conservative with Files** — don't create files unasked
- **3. Handle Errors Explicitly** — no silent swallowing; errors surface with context
- **4. Comment the WHY, Keep Provenance Honest** — why-not-what; no comments on absent code
- **5. Keep Changes Surgical and Small** — the smallest diff that does the job
- **6. State Assumptions, Verify Goals** — say what you assumed, check what you achieved
- **7. Dead Code** — flagging is always safe; deleting needs proof
- **8. Naming, Function Size, and Control-Flow Discipline** — naming, guard clauses, rule of three
- **9. Rules Bow to Context** — when to break a rule and how to say so

## 1. Prove Completion, Don't Claim It

**Never claim "done" without evidence.** Every completion report carries executed results:

```
❌ "Done! I've implemented the feature."

✅ "Done! I've implemented the feature.
    - Tests passing: 47/47
    - Lint: No errors
    - Build: Successful
    - Tested: Created user, verified in database"
```

Run the checks again before reporting — a prior green run does not cover new
changes. When a check cannot run, report it: "I couldn't verify X because Y."
For long-running capture/eval checks, the checkpointed artifact plus
deterministic re-scoring IS the re-run — do not re-capture to verify a capture.
→ ENGINEERING_PRINCIPLES.md §6 "Change Safety & Decision Discipline" (ground claims in verification).

## 2. Be Conservative with Files

Prefer editing over creating files. Don't create empty placeholder files. Search
before creating so you don't produce duplicates. Group related code — don't create a *new* module for a single small helper. A focused module with one public function is fine. Don't generate binary blobs. Generate hashes only as tamper-evidence a tracked consumer verifies — nothing opaque enters unread.

## 3. Handle Errors Explicitly

Swallow nothing silently. Give every failure path an explicit decision: log,
recover, or raise.

```python
# ❌ BAD - Silent swallow
try:
    result = api_call()
except:
    pass

# ✅ GOOD - Explicit handling
try:
    result = api_call()
except ConnectionError as e:
    logger.warning("API unavailable, using cached data", error=str(e))
    result = get_cached_result()
except ValueError as e:
    logger.error("Invalid API response", error=str(e))
    raise
```

## 4. Comment the WHY, Keep Provenance Honest

**Comment the WHY, not the WHAT.** A comment must trace to observable behavior,
a documented constraint, or explicit project guidance — otherwise omit it.
Absence of rationale beats speculative rationale. No comments about code that
isn't there — don't narrate dead code; flag or remove it (→ §7).

```python
# ❌ BAD - Obvious comment
# Loop through users
for user in users:
    process(user)

# ✅ GOOD - Explains WHY (traceable constraint)
# Process sequentially to avoid rate limiting on external API
for user in users:
    process(user)
```

→ ENGINEERING_PRINCIPLES.md §2 "Code Readability & Documentation" (provenance of rationale).

## 5. Keep Changes Surgical and Small

**Every changed line should trace directly to the user's request.** Don't improve
adjacent code, don't refactor what isn't broken, match existing style.
→ ENGINEERING_PRINCIPLES.md §6 "Change Safety & Decision Discipline" (smallest change).

If 200 lines could be 50, rewrite it — when the code your task already touches could be much smaller, shrink it as part of the change. Don't go rewriting modules your diff doesn't otherwise need. Minimum code that solves the problem,
nothing speculative.
→ ENGINEERING_PRINCIPLES.md §1 "Design Principles" (Beck's design rules).

Work in small incremental changes — easier to review and debug.
→ ENGINEERING_PRINCIPLES.md §6 (smallest change).

## 6. State Assumptions, Verify Goals

State assumptions that affect the design before coding, and push back when a
simpler approach exists.
→ §6 "State Assumptions Explicitly".

Define success criteria up front and loop until verified, with a verify step for
each action. Vague tasks become testable goals.
→ §6 "Ground Claims in Verification".

## 7. Dead Code

Observe freely, remove only with proof: flagging suspected dead code is always safe, deleting it requires deterministic proof or explicit human confirmation. Full policy: `ENGINEERING_PRINCIPLES.md` §3 "Dead-Code Removal Is a Separate Authority".

## 8. Naming, Function Size, and Control-Flow Discipline

**Name for meaning, not mechanics.** Nouns for variables, verbs for functions. `pending_refunds` beats `data2`; `dedupe_preserve_order` beats `proc`. Developers over-abbreviate far more often than they over-lengthen — keep domain-meaning names ≥3 letters so the call site reads as a sentence; conventional shorts (`i`, `x`/`y`, `e`, `id`, `db`) are fine. The rule targets cryptic abbreviations (`procData`, `tmpUsr`), not established shorthand — judge by whether a new reader can expand the name.

**Mark deliberate escape hatches explicitly** — a leading underscore signals "I chose this"; the full convention lives in PYTHON.md §10.

**One thing per function, one level of abstraction.** Roughly under 50 lines; files under ~800. The top function reads as an outline; details live one call down. Long functions mix abstraction levels, which makes the bug surface the entire function.

**Flat structure first; guard clauses beat nesting.** Validate inputs and
handle edge cases first; keep the happy path at the left margin. Nesting is
for genuine branching, not formatting — no `if:` inside `if:` that could be a
guard clause. Cap nesting at ~4 — past that, extract.

```python
# ❌ BAD - Nesting as formatting
if order:
    if order.items:
        process(order)

# ✅ GOOD - Edge cases first, happy path flat
if not order: raise ValueError("no order")
if not order.items: raise ValueError("empty order")
process(order)
```

**Boolean parameters are a design smell.** One boolean = caution; two or more = refactor into named functions, a mode enum, or a parameter object. Each flag multiplies the code paths and test cases. `download(url, True)` is unreadable at the call site — a boolean usually hides two functions with different reasons to change. Any surviving flag is keyword-only.

**Duplicate twice, abstract on the third.** Write it three times before
extracting — premature abstraction locks in the wrong shape. The deliberate
exception: a shared contract at a published boundary is designed up front,
→ `ARCHITECTURE.md` §8.

## 9. Rules Bow to Context

A hot loop, a legacy boundary, or an explicit user instruction can override a
rule — when it does, say so in the change. An unexplained exception is
indistinguishable from a mistake.
