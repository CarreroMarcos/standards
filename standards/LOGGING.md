---
title: Logging Standard
version: "2.1"
scope: Logging: what to log, levels, structure, retention
consult_when: "When adding or changing log/telemetry statements."
last_reviewed: 2026-09-29
---

# Logging Standard

Emit structured, queryable logs that never expose secrets.

## Rules

1. **Structured format** — use key-value pairs or JSON, not f-string concatenation.
2. **Use log levels honestly** — `DEBUG` for dev-only detail (gate it behind an env var in production); `INFO` for significant events; `WARN` for unexpected-but-handled cases and degraded behavior; `ERROR` for failures that need attention.
3. **Never log secrets** — no credentials, API keys, tokens, or passwords in logs, ever. Secret inventory: SECRETS.md.
4. **Log the event, not the string** — log what happened and relevant IDs, not a sentence.
5. **Request-scoped context, bound at ingress, cleared per request** — bind request/user IDs at the request boundary and clear at the start of each request. Stale context leaking across requests (request A's user ID in request B's logs) is the classic production log bug. The event name is a stable, grep-able identifier; details are key=value.
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
