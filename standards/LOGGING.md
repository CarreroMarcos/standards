---
title: Logging Standard
version: "2.8"
scope: "Logging: what to log, levels, structure, retention"
consult_when: "When adding or changing log/telemetry statements — or deciding whether a field is safe to log ('is this secret-adjacent?')."
last_reviewed: 2026-10-16
---

# Logging Standard

**Core principle:** emit structured, queryable logs that never expose secrets.

## Sections

- **Rules** — structured format, honest levels, exception logging, request-scoped context, redaction before rendering, libraries emit records, entrypoint-owned termination, fixed log templates
- **Example** — the canonical logging setup
- **What Never to Log** — secrets and everything adjacent

## Rules

1. **Structured format** — use key-value pairs or JSON, not f-string concatenation.
2. **Use log levels honestly** — `DEBUG` for dev-only detail (gate it behind an env var in production); `INFO` for significant events; `WARN` for unexpected-but-handled cases and degraded behavior; `ERROR` for failures that need attention.
3. **Never log secrets** — no credentials, API keys, tokens, or passwords in logs, ever. Secret inventory: SECRETS.md.
   - **CI/build-log excerpts are secret-adjacent.** Test output routinely leaks tokens, and contributor-controlled logs are untrusted input. Never log raw excerpts: redact before logging (rule 6), and treat any untrusted external content the way you'd treat a password — it doesn't belong in logs raw. Identifiers from external systems are logged as identifiers; free-text external content is scrubbed first, then logged.
   - **Observability and telemetry sinks are UNTRUSTED** (TRUST-CLASSIFICATION.md, "Source Classification"): trusted infrastructure carrying attacker-writable content — classify fields, not just sources.
4. **Log the event, not the string** — log what happened and relevant IDs, not a sentence.
5. **Request-scoped context, bound at ingress, cleared per request** — bind request/user IDs at the request boundary and clear at the start of each request. Stale context leaking across requests (request A's user ID in request B's logs) is the classic production log bug. The event name is a stable, grep-able identifier; details are key=value.
   - **Queue workers: the unit is one message, not one invocation.** A Lambda invocation may process a batch; bind `message_id` (and entity IDs like `pr_number`) at message receipt and clear before the next message. Binding at invocation scope leaks message A's IDs into message B's lines — the exact bug this rule warns about, caused by following it literally.
6. **Log identifiers, not objects** — a lazy repr can trigger queries inside the log call. Redaction runs *before* rendering: the secret-scrubbing step sits ahead of the formatter, so a secret never reaches the string that gets emitted.
7. **Libraries emit records; applications own policy** — a library attaches a NullHandler and nothing else: never configure handlers, levels, or formatting in library code. Hierarchical logger names (`getLogger(__name__)`); lazy arguments so disabled levels cost nothing.
8. **Inside an `except` block, log with `logger.exception()`, never `logger.error()`.** `exception()` attaches the traceback; `error()` inside a handler discards the one artifact that would diagnose the failure. The message names the event; the traceback names the cause. (`exception()` always logs at ERROR — for an expected-but-noteworthy failure at another level, e.g. the warning-level skips CODE-QUALITY.md §3 prescribes, pass `exc_info=True` to `warning()` instead.)
9. **Termination is an entrypoint decision, not a logging side effect.** A logging call that also kills the process (`log.Fatal`, `os.Exit`, `sys.exit`, a panic used as control flow) inside request, worker, library, or cleanup paths steals the caller's recovery, context-logging, and cleanup — return the error and let the top-level entrypoint decide whether the process lives. The message gets emitted either way; only the entrypoint gets to decide if the process ends.
```go
// ❌ a library deciding the process's fate
if err != nil {
    log.Fatalf("db unreachable: %v", err) // caller can't recover, retry, or clean up
}
// ✅ return it; the entrypoint owns termination
if err != nil {
    return fmt.Errorf("db unreachable: %w", err)
}
```
   - Boundary: an impossible internal invariant or a documented programmer contract may still crash — deliberately, at the boundary, never as a library default.
10. **The log template is fixed; untrusted content is always a value.** Never pass a runtime-derived or user-controlled string in the template/format position of a log call — pass it as a parameter to a literal template, or as a structured field. Content containing format specifiers (`%s`, `{}`, `%@`) corrupts the message or crashes the formatter, and a template that changes per call breaks the stable event names rule 5 depends on for greppability.
```python
# ❌ user input promoted to the template position
logger.info(user_supplied_status)
# ✅ literal template, untrusted content as data
logger.info("status_received", extra={"status": user_supplied_status})
```
   - Boundary: also covers templates assembled at runtime from data — the template must be a literal in the source, not a string built on the fly.
11. **Log and error strings are read by operators — spell them right.** Misspelled words in log messages, exception messages, and panic messages degrade readability and break the greppability rules 4–5 depend on. Check spelling in emitted strings at write time, the same way identifiers get checked.
   - Boundary: flag actual misspellings that hurt readability, not style preferences.

**Format by environment:** structured JSON in production (queryable in CloudWatch/Loki); human-readable console rendering in dev. Serverless: structured JSON to stdout.

## Example

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
)
logger = logging.getLogger(__name__)

# Good: structured, queryable
logger.info("user_authenticated", extra={"user_id": user_id, "method": "oauth"})

# Bad: f-string, unqueryable, secrets exposed
logger.info(f"User {username} logged in with password {password}")  # Never
```

## What Never to Log

- Passwords, API keys, tokens, secrets of any kind
- Full request/response bodies from external APIs (may contain embedded secrets)
- Verbose per-row database output in production loops

| Thought | Reality |
|---|---|
| "It's just DEBUG, nobody reads prod DEBUG" | Bodies of model calls are never DEBUG-logged in production, gated or not. |
| "I'll redact it later" | Redaction runs before rendering — later never comes. Scrub first, then log. |

**Debugging a model call without logging the body:** log a bounded, redacted excerpt (explicit redaction step first — never raw), or log a content hash plus the byte range / source IDs needed to recover the exact input from the authoritative API later. Bodies of model calls are never DEBUG-logged in production, gated or not — in non-prod, gated DEBUG is the escape hatch, and the explicit redaction step stays mandatory. Prefer structured INFO fields (ids, counts, durations, content hashes) over DEBUG bodies for LLM pipelines.

**Eval-reproducibility record.** An eval run's record = corpus version + pin sha256 + driver version + model ID + effort/config + wall time, recorded in the tracked manifest. The next eval ticket re-derives nothing from scratch; the record names the exact evidence the gate scored.
