---
title: Logging Standard
version: "2.5"
scope: Logging: what to log, levels, structure, retention
consult_when: "When adding or changing log/telemetry statements."
last_reviewed: 2026-09-29
---

# Logging Standard

Emit structured, queryable logs that never expose secrets.

## Sections

- **Rules** — structured format, honest levels, request-scoped context, redaction before rendering, libraries emit records
- **Example** — the canonical logging setup
- **What Never to Log** — secrets and everything adjacent

## Rules

1. **Structured format** — use key-value pairs or JSON, not f-string concatenation.
2. **Use log levels honestly** — `DEBUG` for dev-only detail (gate it behind an env var in production); `INFO` for significant events; `WARN` for unexpected-but-handled cases and degraded behavior; `ERROR` for failures that need attention.
3. **Never log secrets** — no credentials, API keys, tokens, or passwords in logs, ever. Secret inventory: SECRETS.md.
   - **CI/build-log excerpts are secret-adjacent.** Test output routinely leaks tokens, and contributor-controlled logs are untrusted input. Never log raw excerpts: redact before logging (rule 6), and treat any untrusted external content the way you'd treat a password — it doesn't belong in logs unless scrubbed. Identifiers from external systems are logged as identifiers; free-text external content is scrubbed first.
   - **Observability and telemetry sinks are UNTRUSTED** (TRUST-CLASSIFICATION.md, "Source Classification"): trusted infrastructure carrying attacker-writable content — classify fields, not just sources.
4. **Log the event, not the string** — log what happened and relevant IDs, not a sentence.
5. **Request-scoped context, bound at ingress, cleared per request** — bind request/user IDs at the request boundary and clear at the start of each request. Stale context leaking across requests (request A's user ID in request B's logs) is the classic production log bug. The event name is a stable, grep-able identifier; details are key=value.
   - **Queue workers: the unit is one message, not one invocation.** A Lambda invocation may process a batch; bind `message_id` (and entity IDs like `pr_number`) at message receipt and clear before the next message. Binding at invocation scope leaks message A's IDs into message B's lines — the exact bug this rule warns about, caused by following it literally.
6. **Log identifiers, not objects** — a lazy repr can trigger queries inside the log call. Redaction runs *before* rendering: the secret-scrubbing step sits ahead of the formatter, so a secret never reaches the string that gets emitted.
7. **Libraries emit records; applications own policy** — a library attaches a NullHandler and nothing else: never configure handlers, levels, or formatting in library code. Hierarchical logger names (`getLogger(__name__)`); lazy arguments so disabled levels cost nothing.

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

**Debugging a model call without logging the body:** log a bounded, redacted excerpt (explicit redaction step first — never raw), or log a content hash plus the byte range / source IDs needed to recover the exact input from the authoritative API later. Bodies of model calls are never DEBUG-logged in production, gated or not — in non-prod, gated DEBUG is the escape hatch, and the explicit redaction step stays mandatory. Prefer structured INFO fields (ids, counts, durations, content hashes) over DEBUG bodies for LLM pipelines.

**Eval-reproducibility record.** An eval run's record = corpus version + pin sha256 + driver version + model ID + effort/config + wall time, recorded in the tracked manifest. The next eval ticket re-derives nothing from scratch; the record names the exact evidence the gate scored.
