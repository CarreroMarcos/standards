# Code Quality

Operational quality rules for AI-generated code. Design principles live in
`ENGINEERING_PRINCIPLES.md` (cited below as §N); this file holds only what an
agent must do or report on each task.

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
→ §6 "Ground Claims in Verification".

## 2. Be Conservative with Files

Prefer editing over creating files. Don't create empty placeholder files. Search
before creating so you don't produce duplicates. Group related code — avoid
single-function files. Never generate binary or hash content.

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
Absence of rationale beats speculative rationale.

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

→ §2 "Provenance of Rationale" and "Contextual Comments".

## 5. Keep Changes Surgical and Small

**Every changed line should trace directly to the user's request.** Don't improve
adjacent code, don't refactor what isn't broken, match existing style.
→ §6 "Smallest Change".

If 200 lines could be 50, rewrite it. Minimum code that solves the problem,
nothing speculative.
→ §1 "Beck's Design Rules".

Work in small incremental changes — easier to review and debug.
→ §6.

## 6. State Assumptions, Verify Goals

State assumptions that affect the design before coding, and push back when a
simpler approach exists.
→ §6 "State Assumptions Explicitly".

Define success criteria up front and loop until verified, with a verify step for
each action. Vague tasks become testable goals.
→ §6 "Ground Claims in Verification".

## 7. Dead Code

→ `ENGINEERING_PRINCIPLES.md` §3 "Dead-Code Removal Is a Separate Authority": flag freely, remove only with deterministic proof or explicit human confirmation.
