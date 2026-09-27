---
title: Logging Standard
version: "2.0"
scope: Logging: what to log, levels, structure, retention
last_reviewed: 2026-09-27
---

# Logging Standard

Emit structured, queryable logs that never expose secrets.

## Rules

1. **Structured format** — use key-value pairs or JSON, not f-string concatenation.
2. **Use log levels honestly** — `DEBUG` for dev-only detail (gate it behind an env var in production); `INFO` for significant events; `WARN` for unexpected-but-handled cases and degraded behavior; `ERROR` for failures that need attention.
3. **Never log secrets** — no credentials, API keys, tokens, or passwords in logs, ever. Secret inventory: SECRETS.md.
4. **Log the event, not the string** — log what happened and relevant IDs, not a sentence.

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
