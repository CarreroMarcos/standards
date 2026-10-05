---
title: Code Quality
version: "2.10"
scope: Code quality rules: comments, dead code, testing, verification
consult_when: "When about to write or change code and tempted to skip the small stuff — 'it's just a quick fix', 'the diff is obvious', 'tests would take longer than the change' — or when a review came back with nits to preempt."
last_reviewed: 2026-10-04
---

# Code Quality

Operational quality rules for AI-generated code. Design principles live in
`ENGINEERING_PRINCIPLES.md` (cited below as §N); this file holds only what an
agent must do or report on each task.

**Core principle:** code a stranger — human or agent — can read and safely
change. Refactorability is the bar; the rules below are how you reach it.

Deliberately not carried over: per-language
`extensions/<language>.md` files, metrics tables, and CI/pre-commit enforcement
boilerplate — nothing in this repo reads them.

## Sections

- **1. Prove Completion, Don't Claim It** — every "done" carries executed evidence, not assertion
- **2. Be Conservative with Files** — don't create files unasked
- **3. Handle Errors Explicitly** — no silent swallowing; errors surface with context; handle at the boundary, not everywhere
- **4. Comment the WHY, Keep Provenance Honest** — why-not-what; no comments on absent code
- **5. Keep Changes Surgical and Small** — the smallest diff that does the job; simplest solution at stated scale; stdlib before packages
- **6. State Assumptions, Verify Goals** — say what you assumed, check what you achieved
- **7. Dead Code** — flagging is always safe; deleting needs proof
- **8. Naming, Function Size, and Control-Flow Discipline** — naming, guard clauses, rule of three
- **9. Rules Bow to Context** — when to break a rule and how to say so

## 1. Prove Completion, Don't Claim It

```text
NO COMPLETION CLAIM WITHOUT FRESH EVIDENCE
```

No verification run in this session? You cannot claim it passes.

**Never claim "done" without evidence.** Every completion report carries executed results:

```text
❌ "Done! I've implemented the feature."

✅ "Done! I've implemented the feature.
    - Tests passing: 47/47
    - Lint: No errors
    - Build: Successful
    - Tested: Created user, verified in database"
```

**Completion evidence must discriminate** (CODE-REVIEW.md §7 "Evidence integrity"): a check that cannot fail does not count — a green suite that can't go red proves nothing.

Run the checks again before reporting — a prior green run does not cover new
changes. When a check cannot run, report it: "I couldn't verify X because Y."
For long-running capture/eval checks, the checkpointed artifact plus
deterministic re-scoring IS the re-run — do not re-capture to verify a capture.

| Thought | Reality |
|---|---|
| "Tests passed earlier this session" | A green run only proves the tree it ran on. Re-run on the final diff. |
| "The change is too small to break anything" | Size doesn't predict breakage. The check is the proof. |
| "I'll verify after I report" | After never comes. No evidence, no "done". |

→ ENGINEERING_PRINCIPLES.md §6 "Change Safety & Decision Discipline" (ground claims in verification).

**The law, restated:** no fresh evidence, no "done".

## 2. Be Conservative with Files

**Prefer editing over creating files.** Don't create empty placeholder files.
**Search before creating** so you don't produce duplicates. Group related code
— don't create a *new* module for a single small helper. A focused module with
one public function is fine. Don't generate binary blobs. Generate hashes only
as tamper-evidence a tracked consumer verifies — nothing opaque enters unread.

## 3. Handle Errors Explicitly

**Swallow nothing silently.** Give every failure path an explicit decision: log,
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

→ PYTHON.md §5 "Errors and exceptions" (structured exception hierarchies, `raise DomainError(...) from err`, one retry wrapper per boundary).

**Handle errors at the boundary, not everywhere.** Error handling belongs where
the program meets the untrusted or unreliable: user input, file I/O, network
calls, IPC, subprocesses. Internal deterministic paths — pure functions,
in-memory transforms on already-validated data — stay clean and direct. Do not
armor against impossible failures: a `try/except` around code that cannot fail
is not robustness, it is noise that hides the handling that matters.

```python
# ❌ BAD - Armoring the deterministic path
try:
    total = sum(items)          # items: list[int], already validated
except Exception:
    total = 0                   # hides real bugs, "handles" nothing

# ✅ GOOD - Handling at the boundary, clean inside
raw = request.json()            # external boundary: validate and handle
try:
    items = [int(x) for x in raw["items"]]
except (KeyError, ValueError) as e:
    raise BadRequest(f"invalid items payload: {e}") from e
total = sum(items)              # deterministic from here: no armor needed
```

A failure worth handling is a *credible* one: observed here, reported in
comparable systems, or following from a concrete mechanism — not merely
imaginable.

| Thought | Reality |
|---|---|
| "Better safe than sorry" | A `try/except` around code that cannot fail hides real bugs — safety theater, not safety. |
| "What if something unexpected comes in" | Handle it at the boundary where it's credible, not three layers deep where it isn't. |

**In per-item paths, a permanently bad item gets logged and skipped — never raised through the loop.** When a handler processes a stream of items (webhook events, queue messages, digest loops) and one item is malformed beyond recovery, log it at warning with the item's identity and continue. A raise in a per-item hot path multiplies by volume: one bad payload shape in a continuously-firing handler becomes hundreds of thousands of errors. Raise when something downstream owns the failure (a queue's dead-letter, a retry budget); skip when the loop itself is the last owner.

```python
# ❌ BAD - one poison item aborts the batch, then fires again on retry
installations = lookup_installations(slug)
if installations.count() != 1:
    raise ValueError(f"Expected 1 installation for {slug}")

# ✅ GOOD - the bad item is logged and skipped; the stream continues
installation = lookup_installations(slug).first()
if installation is None:
    logger.warning("app.installation_not_found", extra={"slug": slug})
    return None
```

If the skip rate itself goes anomalous — every item suddenly "bad" — that's a systemic failure, not per-item noise. Alert on skip volume and let the overload path own it (→ ARCHITECTURE.md §15), rather than warning-logging your way through an outage.

→ ENGINEERING_PRINCIPLES.md §1 "Simplicity vs. resilience mechanisms" (credible failures).

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

**Write for the reader who never saw your session.** No comments that narrate
the conversation: `# changed per review feedback`, `# v2 — simpler after
iteration`, `# as discussed`. Maintainer-facing prose — code comments, commit
messages, PR descriptions — must read clean for someone with no access to the
session that produced it. Issue references are still fine (`# Workaround for
GH-123`): they name a traceable artifact, not a conversation.

```python
# ❌ BAD - Leaks session history
# Refactored per user's request to be simpler

# ✅ GOOD - States behavior and rationale
# Single pass: input fits in memory and ordering is stable, so no
# chunking needed
```

**Explain the constraint, not the compatibility.** Past-facing wording like
"preserve the existing behavior" is a why-shaped hole — it names no
constraint a reader can check. Write the actual backwards-compatibility
constraint the code honors, in the present tense. Genuinely historical notes
("removed in v3 because X") are fine when a future reader needs the history;
the target is lazy compatibility hand-waving.

```python
# ❌ BAD - Past-facing, names no checkable constraint
# Preserve existing behavior for backwards compatibility
accept_missing_version = True

# ✅ GOOD - Names the constraint
# Pre-2.0 clients omit the version header; treat missing as v1
# or their sync breaks
accept_missing_version = True

# ✅ GOOD - Historical note a future reader needs
# Removed in v3: every supported client sends the version header since 2.4
```

**Every suppressed guard carries its safety case.** A lint or type-check
suppression (`# noqa`, `# type: ignore`, `eslint-disable-next-line`,
clippy `#[expect]`) is a claim that the guarded-against case cannot bite —
write the claim down, inline, or the suppression is a lie waiting to rot.
File-level directives (e.g. a `# ruff: noqa` header) and project-wide disables
carry their rationale in the same place they live — the directive comment or
the linter config — not scattered as bare per-line suppressions.

```python
# ❌ BAD - Bare suppression
result = legacy_parse(data)  # type: ignore

# ✅ GOOD - Safety case on its own line, stays attached through reflows
# legacy_parse is untyped by design; input schema is validated above
result = legacy_parse(data)  # type: ignore[no-untyped-call]
```

→ ENGINEERING_PRINCIPLES.md §2 "Code Readability & Documentation" (provenance of rationale).

## 5. Keep Changes Surgical and Small

**Every changed line traces directly to the user's request.** Don't improve
adjacent code, don't refactor what isn't broken, match existing style.
→ ENGINEERING_PRINCIPLES.md §6 "Change Safety & Decision Discipline" (smallest change).

If 200 lines could be 50, rewrite it — when the code your task already touches could be much smaller, shrink it as part of the change. Don't go rewriting modules your diff doesn't otherwise need. Minimum code that solves the problem,
nothing speculative.
→ ENGINEERING_PRINCIPLES.md §1 "Design Principles" (Beck's design rules).

**Solve the stated problem at its stated scale.** Choose the simplest, most
readable solution that fulfills the immediate requirement — no speculative
generality, no framework for a script, no plugin system for two callers.
Generalize for the second caller that exists, not the one you imagine.
Over-engineering is a defect: 1000 lines where 300 would do is not thoroughness,
it is bug surface.

```python
# ❌ BAD - Speculative machinery for one caller
class ReportStrategy(ABC): ...
class PdfReportStrategy(ReportStrategy): ...   # the only strategy that will ever exist

# ✅ GOOD - The direct solution
def render_pdf_report(data): ...
```

| Thought | Reality |
|---|---|
| "I'll clean up the neighboring code while I'm here" | That's a separate task with its own diff. Every changed line traces to the request. |
| "This might need to scale later" | Generalize for the second caller that exists, not the one you imagine. |

**Standard library before packages.** Reach for the standard library — and
native platform APIs (`fetch`, DOM methods) — before adding an external
package. A new dependency is a supply-chain, upgrade, and audit cost: it must
earn its place. Use one when the stdlib genuinely cannot do the job, or the
package removes real, non-trivial complexity. `pip install` is not step one.
→ SUPPLY-CHAIN.md (vetting a new dependency before adding it).

Work in small incremental changes — easier to review and debug.
→ ENGINEERING_PRINCIPLES.md §6 (smallest change).

## 6. State Assumptions, Verify Goals

**State assumptions before coding.** Say what you assumed when it affects the
design, and push back when a simpler approach exists — in plain words: "A
simpler approach exists: <one-sentence sketch>. I'll proceed with it — say the
word if you want the original plan."
→ §6 "State Assumptions Explicitly".

**Define success criteria up front.** Loop until verified, with a verify step for
each action. Vague tasks become testable goals.
→ §6 "Ground Claims in Verification".

## 7. Dead Code

**Flag freely; delete only with proof.** Flagging suspected dead code is always
safe — when in doubt, flag. Deleting it requires deterministic proof or explicit
human confirmation. Full policy: `ENGINEERING_PRINCIPLES.md` §3 "Dead-Code Removal Is a Separate Authority".

## 8. Naming, Function Size, and Control-Flow Discipline

**Name for meaning, not mechanics.** Nouns for variables, verbs for functions. `pending_refunds` beats `data2`; `dedupe_preserve_order` beats `proc`. Developers over-abbreviate far more often than they over-lengthen — keep domain-meaning names ≥3 letters so the call site reads as a sentence; conventional shorts (`i`, `x`/`y`, `e`, `id`, `db`) are fine. The rule targets cryptic abbreviations (`procData`, `tmpUsr`), not established shorthand — judge by whether a new reader can expand the name.

**Mark deliberate escape hatches explicitly** — a leading underscore signals "I chose this"; the full convention lives in PYTHON.md §10.

**One thing per function, one level of abstraction.** Roughly under 50 lines; files under ~800. The top function reads as an outline; details live one call down. Long functions mix abstraction levels, which makes the bug surface the entire function.

**Scope-test before you write: 2–4 bullets.** Line counts are a lagging indicator — a 30-line function can still do six things. Before writing a function or module, list what it accomplishes in 2–4 bullets. More than four means split it. State the problem it solves without describing machinery; if the "what" needs the "how," the scope is wrong.
*Why: the 50-line cap catches size after the fact. The bullet test forces the scope decision up front, where splitting is cheap.*

```python
# ❌ BAD - scope discovered after writing
def handle_webhook(req):  # verifies, parses, routes, retries, notifies...

# ✅ GOOD - scope decided before writing
# handle_webhook: 1) verify signature, 2) parse event, 3) dispatch.
# Three bullets, one concept — now write it.
```

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
exception: a shared contract at a published boundary is designed up front; see
`ARCHITECTURE.md` §8.

## 9. Rules Bow to Context

A hot loop, a legacy boundary, or an explicit user instruction can override a
rule — when it does, say so in the change. An unexplained exception is
indistinguishable from a mistake.
