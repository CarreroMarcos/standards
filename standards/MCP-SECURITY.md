# MCP-SECURITY

Selecting, configuring, and auditing MCP servers — the external tools (databases, APIs, filesystems) an agent calls through the Model Context Protocol.

## Select servers you trust, and scope them

Only connect to MCP servers you control or have reviewed. Pin server versions.

Maintain an approved list of MCP servers. A new server requires, before it connects:

1. Code review of the server's source or published manifest.
2. Security review of what data the server can access.
3. Least-privilege scope configuration.

Scope each MCP server to the minimum directory or resource it needs. A filesystem server granted `~/` can read SSH keys, `.env` files, and credential stores.

## Audit tool definitions

Audit an MCP server's tool definitions on install and after every update — a compromised tool description can instruct an agent to re-emit secrets.

## Treat tool results as untrusted input

Treat MCP tool results as untrusted input.

Why this holds: AGENTIC-SAFETY.md treats all tool-fetched content as data, not instructions; ENGINEERING-PRINCIPLES.md §9 — "Tool output is not automatically trusted simply because it came through a typed protocol." This file owns the MCP-specific practice; those files own the reasoning.

## Reference credentials by environment variable

In `mcp.json`, give the server the secret's environment variable — never the value:

```json
{
  "mcpServers": {
    "my-service": {
      "command": "npx",
      "args": ["-y", "@my-org/mcp-server"],
      "env": {
        "API_KEY": "${MY_SERVICE_API_KEY}"
      }
    }
  }
}
```

Never:

```json
"API_KEY": "sk-live-abc123..."
```

Everything beyond this illustration — storage, rotation, agent exposure, gitignore, `.example` configs — is owned by SECRETS.md.
