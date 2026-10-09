---
title: Code Quality
version: "2.12"
scope: "Code quality rules: comments, dead code, testing, verification"
consult_when: "When about to write or change code and tempted to skip the small stuff — 'it's just a quick fix', 'the diff is obvious', 'tests would take longer than the change' — or when a review came back with nits to preempt."
last_reviewed: 2026-10-08
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

**When verification fails, suspect the observation method before suspecting
the system.** A failing check means the check *or* the system is wrong —
re-read the check first: stale fixture, wrong assertion, cached state, test
harness drift. Debugging the system from a broken instrument wastes the whole
session.
*Why: agents trust their own test code uncritically and chase system bugs that
don't exist. The instrument is written by the same fallible author as the
code.*

**A scripted check saved as an artifact beats a narrated one.** When the
verification matters enough to re-run — a migration, a perf claim, a subtle
bug — write the check as a deterministic script and keep its output as an
artifact a reviewer can re-run, not a one-time eyeball narrated in the
report.
*Why: "I ran it and it looked right" is a claim; a committed script plus its
output is evidence. The artifact re-runs on the next diff — the narration
doesn't.*
Boundary: commit the script for large or complex work where the trail must be
auditable later. For a routine unit test, the test suite itself is the
artifact — don't commit one-off scripts for checks the suite already covers.

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

→ languages/PYTHON.md §5 "Errors and exceptions" (structured exception hierarchies, `raise DomainError(...) from err`, one retry wrapper per boundary).

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

**Do not re-export wire/framework types through the public surface.** Validate
at the boundary, then translate into domain types — and expose only the
domain. A public signature that names a framework's request object, an ORM
model, or a transport envelope leaks the boundary's private representation
into every caller's code.
*Why: the boundary's types are the boundary's business. Re-exporting them
means every consumer couples to the framework, every framework upgrade
becomes a breaking change, and business logic can't be tested without the
framework.*
*Bad:* `def create_invoice(req: HttpRequest) -> DbInvoice:` in a service
module — callers must import the web framework and the ORM to use it.
*Good:* `def create_invoice(draft: InvoiceDraft) -> Invoice:` — pure domain
in, pure domain out; the HTTP layer translates at the edge.
Boundary: this is the mirror of §3's "trust the types inside" — the inside
types are domain types, and the translation happens exactly once, at the
boundary. Thin mechanical adapters at the edge that do the translation are
the sanctioned place for framework knowledge.

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

**A deliberate shortcut names its ceiling and its upgrade trigger.** A
shortcut with a known limit gets a `shortcut:` comment naming the limit
*and* the condition that forces the real fix — so "later" is a defined
condition, not a hope. The marker is always exactly `shortcut:` — one grep
pattern finds every marker, with or without a trigger. Markers with no
trigger are rot: greppable, and the debt scan's mechanical signal.

*Example:* `// shortcut: inlines the one live path; upgrade to strategy pattern if a second caller appears`

Boundary: for genuinely throwaway code, the trigger can be "delete with the
experiment."

**Encode the constraint, then delete the comment.** A constraint comment
("do not remove", "do not change wording", "talk to X before changing") is a
claim the code should enforce — so enforce it: as a type, a lint rule, or a
test that fails when the constraint is violated. Then delete the comment.
*Why: a comment asks the next reader for obedience; an encoding makes
violation impossible or loud. Comments rot — the reader who needs the warning
is the one who never read the comment.*
*Bad:* `# DO NOT REMOVE — the deploy pipeline depends on this column name`
sitting above a migration.
*Good:* a test asserting the pipeline's expected column name, and no comment.
Boundary: encode only what the code can actually check. A constraint about
something outside the code's reach (a human process, a vendor behavior) keeps
its comment — the encoding discipline governs claims the code *could*
enforce, not claims it can't.

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

**Be lazy about the solution, never about the change itself.** Finish every
part the task needs — the callers, tests, fixtures, and config your change
breaks. A minimized diff that leaves a broken caller is not minimal, it is
half-landed.
*Why: the corpus says "minimize" five ways but never states the completeness
corollary — and minimality without it is exactly how "lazy" produces
half-landed diffs.*
*Bad:* rename a function, update its definition, leave three callers on the
old name — "small diff."
*Good:* the rename lands with all callers, tests, and fixtures updated in the
same diff — or the rename doesn't ship.
Boundary: "every part the task needs," not every part of the repo — the
task's reach list bounds it.

**Prefer fixes that delete code.** Propose the smallest fix that works;
between a patch that adds and a fix that removes, take the removal. Never add
layers, frameworks, or config the problem does not need.
*Why: gives repair a directional bias — the codebase moves toward less code
with every fix, not merely "not more." A mechanical tie-breaker for
refactor-vs-patch decisions.*
*Bad:* fix a tangled helper by adding a wrapper that routes around it.
*Good:* fix it by deleting the helper and inlining the one live path.
Boundary: the deletion bias bows to the never-cut list — validation at trust
boundaries, error handling that prevents data loss, security. The bias
governs fix *shape*; it never authorizes expanding the task's scope to chase
deletions — every changed line still traces to the request.

**A one-liner that needs decoding is not short.** Gates brevity on
readability — the direct antidote to AI code-golf (nested comprehensions,
clever one-liners) that minimizes lines while maximizing bug surface. Short =
glanceable, not token-minimal.
Boundary: applies to cleverness, not density — a dense-but-idiomatic line is
fine.

**Delete wrappers that only pass calls through.** Interface with one
implementation, factory with one product, wrapper that only passes calls
through — if the layer adds no logic, it dies. Pass-through wrappers are AI's
favorite "clean architecture" cargo cult: a named layer with zero behavior,
doubling the edit surface of every future change.
Boundary: wrappers that exist for a real seam (test double injection, trust
boundary) stay — the tripwire is *no logic added*.

**Enumerate the change's reach before writing.** Read the task and the code it
touches; list every place the change must reach — callers, tests, fixtures,
config, exports — before writing. Blocks both failure modes: the lazy agent
that under-touches (breaks a caller) and the eager one that over-touches (adds
features).
Boundary: the enumeration is author-time, one pass — not a design doc.

**If answering a question requires tracing through more than 3 files or
layers, flatten it.** A rich interface that hides substantial work is not a
deep call chain — the tripwire is the *reader's* trace, not the depth of the
implementation behind an honest boundary.
*Why: every indirection is a file the next reader opens and a jump the next
debugger steps through. Depth that doesn't hide a decision is just distance
between the question and the answer.*
*Bad:* `handle_request` → `dispatch` → `route_event` → `apply_policy` →
`execute_action` where each layer forwards the same arguments unchanged.
*Good:* the honest boundaries stay (parse at the edge, execute the action);
the forwarding middles inline.
Boundary: flattening means removing layers that add no decision — never
merging distinct failure domains or trust boundaries into one function.

**Migrate callers, then delete the legacy API — adapters are exceptional and
time-boxed.** When a new internal API is the right design, inventory the
callers, migrate them, and delete the old API in the same wave — not behind a
compatibility layer. A temporary adapter gets an expiry (a dated TODO, a
ticket, a version ceiling), not permanent residence.
*Why: keeping both paths creates dual-path complexity and makes the codebase
feel append-only. An adapter with no expiry date is a second API, not a
bridge.*
*Bad:* `old_create_user()` kept alive "until everyone migrates," with the
migration never scheduled.
*Good:* callers migrated in the same diff; where a staged rollout truly needs
an adapter, it carries `# TODO(expires 2026-11-08): drop after rollout` — and
the date is a real commitment.
Boundary: applies when no external users depend on backward compatibility.
Published APIs with external consumers get the deprecation policy in
ARCHITECTURE.md, not this rule.

## 6. State Assumptions, Verify Goals

**State assumptions before coding.** Say what you assumed when it affects the
design, and push back when a simpler approach exists — in plain words: "A
simpler approach exists: `<one-sentence sketch>`. I'll proceed with it — say the
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

**Mark deliberate escape hatches explicitly** — a leading underscore signals "I chose this"; the full convention lives in languages/PYTHON.md §10.

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

**Split by job, never by line count.** A function doing several unrelated jobs
gets split along the job boundaries. Never split into helpers that exist only
to make a function shorter — `do_part1()` / `do_part2()` is line-count
theater, not structure.
*Why: mechanical splitting satisfies the line cap while adding indirection
without meaning; the bug surface doesn't shrink. This is AI's favorite way to
look disciplined while getting worse.*
*Bad:* 60-line function → `do_part1()`, `do_part2()`, `do_part3()` called in
sequence.
*Good:* 60-line function → `validate_input()`, `compute_result()`,
`format_output()` — each testable alone.
Boundary: the existing ~50-line / ~4-nesting guidance stands as a smell
signal; this rule governs what the split must *be*, not whether to split.

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

**Model the domain; don't scatter it across booleans and branches.** When the
code branches on state — lifecycle phases, feature flags, modes — encode the
domain in a structure instead of scattering conditionals. Scattered booleans,
repeated shape assumptions, and branching spread across files are accidental
complexity; a structure that matches the domain makes invalid states
unrepresentable and deletes branches.
*Why: §8's boolean-parameter rule covers booleans as arguments. This covers
booleans as state — the case where "just one more flag" compounds with every
feature. Choosing the structure at write time is cheap; recovering it later
reads as a refactor and gets deferred.*

Reach for the smallest structure that fits:
- **State machine** instead of scattered booleans, phases, or lifecycle checks.
- **Typed object/model** instead of loose parameters or repeated shape assumptions.
- **Registry/map/lookup table** instead of branching spread across files.
- **Reducer or event model** instead of ad hoc state mutations.

```python
# ❌ BAD - two booleans that must stay in sync, branches everywhere
def send(invoice, is_finalized, is_overdue):
    if is_finalized and is_overdue:
        ...
    elif is_finalized:
        ...
    # is_overdue=True with is_finalized=False is nonsense —
    # nothing in the code says so

# ✅ GOOD - the domain states are the only states
@dataclass(frozen=True)
class InvoiceState:
    status: Literal["draft", "finalized", "overdue"]   # overdue implies finalized

def send(invoice, state: InvoiceState):
    ...
```

**Do not force an abstraction.** If the current shape is already clear, local,
and unlikely to grow, boring code wins. Be skeptical of an abstraction that
adds indirection without removing branches, duplicated rules, invalid states,
or lifecycle risk.
*Bad:* wrap a two-branch conditional in a registry "for extensibility" with one
registered handler.
*Good:* leave the two branches alone — and notice the next feature that wants
to add a third branch, because that feature is the symptom you skipped this.
Boundary: the tripwire is the symptom — a new feature growing an existing
if/else chain by one more branch, or a second boolean that must stay in sync
with the first. No symptom, no structure; symptom, model it then.

**The 30-second reader test.** After shaping a change, ask: can a new reader
answer "where does X come from?" and "what can change X?" in under 30 seconds?
If not, cut layers or cut state.
*Why: line counts, cyclomatic complexity, and "clean architecture" are proxies.
Reader load — the layers to trace times the state to hold — is the thing that
matters. A flat file with 50 globals can be as hard to reason about as a
6-layer adapter stack; guard both.*
*Bad:* a call chain where answering "what changed this value?" means opening
five files and holding a flag through three of them.
*Good:* the value's origin and mutation points fit in one screen of search.
Boundary: applies to code a stranger will maintain — not to throwaway
experiments, which get deleted anyway.

**Adjacent layers must change the abstraction.** A layer that repeats the same
methods and arguments adds reader load without compression — collapse it.
*Why: every layer is a comprehension tax the next reader pays; a pass-through
layer taxes them and teaches nothing. A boundary that hides a meaningful
decision pays for itself; one that echoes the interface below it doesn't.*
*Bad:* `class OrderRepo` exposing `get(order_id)`, `save(order)` that do
nothing but forward to the ORM with identical signatures.
*Good:* the repository either encodes a real decision (tenant scoping,
caching, mapping) or doesn't exist.
Boundary: layers with one caller and zero behavioral delta die — this is §5's
pass-through rule applied to readers, not to call counts.

**Shrink state scope: derive instead of sync.** Prefer pure functions (returns
over mutations); then locals over fields, fields over module state, module
state over globals. When state can be derived, derive it — don't store a copy
and keep the two in sync.
*Why: every mutable holding is one more thing the reader must keep in their
head, and every sync point is a bug waiting for a missed update.*
*Bad:* `is_expired` stored on the object and refreshed by a caller that must
remember to call `refresh()`.
*Good:* `is_expired` is a property computed from `expires_at` — one truth, no
sync.
Boundary: caching is not sync — a derived value with a documented invalidation
rule is a performance decision, not a second source of truth.

## 9. Rules Bow to Context

A hot loop, a legacy boundary, or an explicit user instruction can override a
rule — when it does, say so in the change. An unexplained exception is
indistinguishable from a mistake.
