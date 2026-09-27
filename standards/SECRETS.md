# SECRETS.md — Ephemeral by Default

Secrets (API keys, tokens, passwords, certificates, connection strings) live in a secrets manager, rotate on short schedules, and never touch version control or an agent's environment.

**Why this file exists.** In March 2026, a backdoored `litellm` build (v1.82.7/1.82.8, CVE-2026-33634) auto-executed at Python startup and harvested environment variables, SSH keys, cloud credentials, and shell history from every host it touched. Long-lived credentials sitting in a developer's env or history were in the exfiltration set. This standard keeps yours out of that set.

## Agent-safe posture (read first)

Treat every agent session as a potential read of your environment:

1. **Keep long-lived credentials out of the agent's shell.** The shell the agent runs in **must not** export long-lived credentials as environment variables. If the agent reads env, it can re-emit env.
2. **Inject short-lived tokens for the session only.** Secrets a session needs arrive as tokens that expire within the session window.
3. **Rotate after every session.** After any agent session that may have read credentials (even inadvertently via a tool call or log inspection), **rotate** them. Do not evaluate whether it was "actually read" — rotation is the default.
4. **Keep shell history clean of credentials.** Never let credential-bearing commands land in `~/.bash_history`, `~/.zsh_history`, `~/.psql_history`, or equivalents. Prefix sensitive commands with a space (where the shell skips such lines) or `unset HISTFILE` for the session.

## Never commit a secret (hard boundary)

- No `.env`, `*.pem`, `*.key`, `id_rsa`, `credentials.json`, or cloud-provider credential files.
- `.gitignore` blocks `.env*`, `*.pem`, `*.key`, `id_*`, `credentials*`.
- Pre-commit hooks scan staged content for secret patterns (AWS access keys, Slack tokens, high-entropy strings).

## Storage and lifetime

- **Store secrets in a secrets manager** — never in committed files, wikis, chat, or long-lived environment variables. Credentials never belong in an agent's rules file.
- **Prefer short-lived issuance** wherever the provider supports it (STS, OIDC, workload identity, Vault dynamic secrets).
- **Dev-only fallback:** an OS keychain (`keyring`, Credential Manager, `libsecret`) combined with short-lived tokens, where no secrets manager is available.
- **Default lifetimes:** dev tokens ≤ 12 hours; CI tokens ≤ 1 hour; production service tokens ≤ 24 hours with automatic rotation. Any long-lived token needs a documented rotation SLA and an owner.

## `.env`, when unavoidable

- Scope it to the project folder — never `~/.env`.
- Populate it from the secrets manager at session start; never from a committed template with real values.
- Rotate its contents on session end or whenever the agent session completes.
- Exclude it from every read path exposed to an agent or tool.
- Verify after a task: `grep -rE "(API_KEY|SECRET|TOKEN|PASSWORD)\s*=" . --exclude=.env --exclude=.env.example --exclude-dir=.git` returns zero matches. `.env` holds real secrets and `.env.example` holds placeholder names, so both are excluded from the scan; everything else must be clean.

## What never belongs near an agent

- **Root-level API keys** (AWS root, broadly scoped GitHub PAT, `glpat-*` tokens in the remote URL) — even in a terminal the agent can't see, the agent can run `git remote -v`, so the leak vector exists.
- **Long-lived database passwords** in `~/.pgpass`, `~/.my.cnf`, etc. — if the agent can ask a tool to read a file, it can read these.
- **SSH keys** in `~/.ssh` — if the agent can ask a tool to read a file, it can read these.

When the agent must act on these systems, proxy its access through a short-lived credential issued by the secrets manager.

## MCP server configs

- Reference secrets by environment-variable name, never by value.
- Start a credentialed MCP server from the parent process's ephemeral env, not the user's long-lived env.
- Server-side hygiene (reviewing tool descriptions for secret-re-emission vectors): `MCP-SECURITY.md`.

## Workflows

**Dev laptop:** authenticate to the secrets manager (this issues a short-lived token); launch the agent session inside a shell spawned from that authenticated context; let the CLI vend short-lived service credentials on demand; the token expires at session end — nothing to clean up.

**CI:** the runner authenticates to the secrets manager via OIDC / workload identity — no long-lived keys stored in CI. Each job receives short-lived, task-scoped credentials; never echo credentials to build logs, and mask patterns at the runner level.

## Incident: secret may have been exposed

1. Rotate the affected credentials **immediately**, regardless of confidence level.
2. Revoke the token at the provider side — not just locally.
3. Preserve evidence (logs, commit diff, shell-history snapshot).
4. File the incident; write the post-mortem.

## References

LiteLLM March 2026 supply-chain breach (CVE-2026-33634). OWASP LLM Top 10 (2025): LLM02 Sensitive Information Disclosure, LLM06 Excessive Agency.
