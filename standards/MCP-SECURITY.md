---
title: MCP Security Standard
version: "2.2"
scope: Security rules for Model Context Protocol (MCP) servers
consult_when: "When selecting, configuring, or auditing MCP servers and tool definitions."
last_reviewed: 2026-09-29
---

# MCP Security Standard

Selecting, configuring, and auditing MCP servers — the external tools (databases, APIs, filesystems) an agent calls through the Model Context Protocol.

## Sections

- **Select servers you trust, and scope them** — approved list, least-privilege scope
- **Audit tool definitions** — on install and after every update
- **Treat tool results as untrusted input** — results are data, not instructions
- **Reference credentials by environment variable** — never by value
- **Keep secret-bearing MCP configs out of version control** — configs are credential-adjacent

## Select servers you trust, and scope them

Only connect to MCP servers you control or have reviewed. Pin server versions — the version pin (e.g. `@scope/pkg@1.2.3` in the `npx` args); hash-pin where the host supports it.

Maintain an approved list of MCP servers. A new server requires, before it connects:

1. Code review of the server's source or published manifest.
2. Security review of what data the server can access.
3. Least-privilege scope configuration.

Scale the review to the trust basis: first-party/official servers with signed releases — verify provenance + scope (steps 2–3). Third-party or novel servers — all three steps, source review included.

Scope each MCP server to the minimum directory or resource it needs. A filesystem server granted `~/` can read SSH keys, `.env` files, and credential stores.

## Audit tool definitions

Audit an MCP server's tool definitions on install and after every update — a compromised tool description can instruct an agent to re-emit secrets.

## Treat tool results as untrusted input

Why this holds: AGENTIC-SAFETY.md treats all tool-fetched content as data, not instructions; AGENTIC-DESIGN.md §5 — "Tool output is not automatically trusted simply because it came through a typed protocol." This file owns the MCP-specific practice; those files own the reasoning.

## Reference credentials by environment variable

In `mcp.json`, give the server the secret's environment variable — never the value:

```json
{
  "mcpServers": {
    "my-service": {
      "command": "npx",
      "args": ["-y", "@my-org/mcp-server@1.2.3"],
      "env": {
        "API_KEY": "${MY_SERVICE_API_KEY}"
      }
    }
  }
}
```

With `npx -y`, the pin is the version suffix — without it you have no update boundary to audit against.

Never — a hardcoded value, even redacted in docs:

```json
"API_KEY": "sk-live-abc123"
```

## Keep secret-bearing MCP configs out of version control

Gitignore `mcp.json` / `.mcp.json` when they carry secrets. Commit a `mcp.json.example` with `${ENV_VAR_NAME}` placeholders instead of real values.
