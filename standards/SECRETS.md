---
title: SECRETS.md — Ephemeral by Default
version: "2.3"
scope: Secrets management: storage, rotation, agent exposure
consult_when: "When handling credentials, API keys, or tokens - storing, passing, logging, or reviewing code that touches them."
last_reviewed: 2026-09-29
---

# SECRETS.md — Ephemeral by Default

Secrets (API keys, tokens, passwords, certificates, connection strings) live in a secrets manager, rotate on short schedules, and never touch version control or an agent's environment.

**Why this file exists.** In March 2026, a backdoored `litellm` build (v1.82.7/1.82.8, CVE-2026-33634) auto-executed at Python startup and harvested environment variables, SSH keys, cloud credentials, and shell history from every host it touched. Long-lived credentials sitting in a developer's env or history were in the exfiltration set. This standard keeps yours out of that set.

## Sections

- **Agent-safe posture (read first)** — the five rules for running agents near credentials
- **Never commit a secret (hard boundary)** — what never touches git
- **Scan outputs, not just commits** — PR comments, traces, and logs leak too
- **Validation errors and typed secrets** — hide inputs at sensitive boundaries; secrets ride as redacted types
- **Storage and lifetime** — managers, short-lived issuance, default lifetimes
- **`.env`, when unavoidable** — scoping, rotation, and the verification grep
- **What never belongs near an agent** — root keys, SSH keys, long-lived db passwords
- **Treat agent memory as credential-adjacent storage** — authenticate, isolate, sanitize
- **MCP server configs** — env-var references, ephemeral parent env
- **Workflows** — dev-laptop and CI credential patterns
- **Incident: secret may have been exposed** — rotate, revoke, preserve, scan, post-mortem
- **References**

## Agent-safe posture (read first)

Treat every agent session as a potential read of your environment:

1. **Keep long-lived credentials out of the agent's shell.** The shell the agent runs in **must not** export long-lived credentials as environment variables. If the agent reads env, it can re-emit env. An agent that reads untrusted content (issues, logs, error trackers) must not simultaneously hold production credentials — the exfil channel is whatever data the agent is allowed to read.
2. **Inject short-lived tokens for the session only.** Secrets a session needs arrive as tokens that expire within the session window.
3. **Rotate after every session.** After any agent session that may have read credentials (even inadvertently via a tool call or log inspection), **rotate** them. Do not evaluate whether it was "actually read" — rotation is the default.
4. **Keep shell history and shell startup clean of credentials.** Never let credential-bearing commands land in `~/.bash_history`, `~/.zsh_history`, `~/.psql_history`, or equivalents. Prefix sensitive commands with a space (where the shell skips such lines) or `unset HISTFILE` for the session. Treat shell startup files (`.bashrc`, `BASH_ENV`) as untrusted-input territory for agent shells — poisoned hook variables (`PAGER`, `LD_PRELOAD`, `BASH_ENV`) turn the next benign command into payload execution; allowlist the hooks an agent shell may run.
5. **Broker credentials so the agent never holds the real secret.** Prefer a credential-brokering proxy that injects the real secret on the wire server-side — the agent's context holds only a placeholder. Env-var injection is weaker: the secret still lands in the child process env, where `printenv` re-exposes it to a compromised agent. Scope every issued credential to the intersection of the agent's grant and the user's grant, with ttl = task duration.

## Never commit a secret (hard boundary)

- No `.env`, `*.pem`, `*.key`, `id_rsa`, `credentials.json`, or cloud-provider credential files.
- `.gitignore` blocks `.env*`, `*.pem`, `*.key`, `id_*`, `credentials*`.
- Pre-commit hooks scan staged content for secret patterns (AWS access keys, Slack tokens, high-entropy strings).

## Scan outputs, not just commits

Pre-commit hooks catch secrets going into git. They miss everything else the agent writes.

- Scan agent-written PR comments, issue comments, summaries, and workflow logs for secret patterns before they publish.
- Scrub secrets from traces and audit logs: log that a credential was used, never the value. Restore `{{ENV_VAR}}` placeholders in displayed traces.
- Why: one 2026 incident's root cause was literally "no output filtering" — an agent posted environment contents to a PR comment.

## Validation errors and typed secrets

- **Hide inputs at sensitive boundaries.** Structured validation errors that echo the offending input are a secret-leak vector — passwords land in 422 responses, then in logs. At sensitive boundaries, suppress the input field (`errors(include_input=False)` / `hide_input_in_errors` in pydantic).
- **Secrets ride as redacted types.** Config values that hold secrets use a secret-string type so they redact in logs, tracebacks, and error payloads by default.
- **Redaction runs before rendering.** In the logging pipeline, the secret-scrubbing step sits before the formatter — the secret must never reach the string that gets emitted. Full policy: `LOGGING.md`.

## Storage and lifetime

- **Store secrets in a secrets manager** — never in committed files, wikis, chat, or long-lived environment variables. Credentials never belong in an agent's rules file.
- **Prefer short-lived issuance** wherever the provider supports it (STS, OIDC, workload identity, Vault dynamic secrets).
- **Dev-only fallback:** an OS keychain (`keyring`, Credential Manager, `libsecret`) combined with short-lived tokens, where no secrets manager is available.
- **Never store credentials in hidden context** — system prompts, tool schemas, agent memory configs, or policy text the model sees but the user doesn't. Assume hidden context will be discovered; it is never an authorization control.
- **Default lifetimes:** dev tokens ≤ 12 hours; CI tokens ≤ 1 hour; production service tokens ≤ 24 hours with automatic rotation. Any long-lived token needs a documented rotation SLA and an owner.

## `.env`, when unavoidable

- Scope it to the project folder — never `~/.env`.
- Populate it from the secrets manager at session start; never from a committed template with real values.
- Rotate its contents on session end or whenever the agent session completes.
- Exclude it from every read path exposed to an agent or tool.
- Verify after a task: `grep -rE "(API_KEY|SECRET|TOKEN|PASSWORD)\s*=" . --exclude=.env --exclude=.env.example --exclude-dir=.git` — review each match. A hardcoded value is a leak; a read from the environment is fine.

## What never belongs near an agent

- **Root-level API keys** (AWS root, broadly scoped GitHub PAT, `glpat-*` tokens in the remote URL) — even in a terminal the agent can't see, the agent can run `git remote -v`, so the leak vector exists.
- **Long-lived database passwords** in `~/.pgpass`, `~/.my.cnf`, etc. — if the agent can ask a tool to read a file, it can read these.
- **SSH keys** in `~/.ssh` — if the agent can ask a tool to read a file, it can read these.
- **Real secrets in agent config dirs at rest** (`.claude/`, `.vscode/`, shipped skill configs) — commodity malware now harvests these specifically; a config-stealing worm finds whatever you stored there.

When the agent must act on these systems, proxy its access through a short-lived credential issued by the secrets manager.

## Treat agent memory as credential-adjacent storage

- Authenticate memory-store APIs; isolate tenants; never persist provider API keys in plaintext in memory config.
- Sanitize what gets written — an injected one-line memory entry ("remember X") re-emits its payload in future sessions.
- Why: an unauthenticated memory API returned provider keys in plaintext (CVE-2026-59706); memory-poisoning campaigns now use trivial writes as persistence.

## MCP server configs

- Reference secrets by environment-variable name, never by value.
- Start a credentialed MCP server from the parent process's ephemeral env, not the user's long-lived env.
- Server-side hygiene (reviewing tool descriptions for secret-re-emission vectors): `MCP-SECURITY.md`.

## Workflows

**Dev laptop:** authenticate to the secrets manager (this issues a short-lived token); launch the agent session inside a shell spawned from that authenticated context; let the CLI vend short-lived service credentials on demand; the token expires at session end — nothing to clean up.

**CI:** the runner authenticates to the secrets manager via OIDC / workload identity — no long-lived keys stored in CI. Each job receives short-lived, task-scoped credentials; never echo credentials to build logs, and mask patterns at the runner level. Agents that touch untrusted input (issue triage, PR review) get only the model API key and a least-privilege `GITHUB_TOKEN` — never publish tokens, and never let agents post to publicly visible workflow summaries. Keep nightly/dev credentials separate from production; require OIDC provenance on publishing. Why: 2026 incidents stole CI tokens via `/proc/self/environ` reads and OIDC-token replay, and scraped masked secrets straight from runner process memory — masked ≠ safe on a compromised runner.

## Incident: secret may have been exposed

1. Rotate the affected credentials **immediately**, regardless of confidence level.
2. Revoke the token at the provider side — not just locally.
3. Preserve evidence (logs, commit diff, shell-history snapshot).
4. Scan agent config dirs (`.claude/`, `.vscode/tasks.json`, CI workflows) for injected hooks — supply-chain worms persist there, and uninstalling the package doesn't remove them.
5. File the incident; write the post-mortem.

## References

LiteLLM March 2026 supply-chain breach (CVE-2026-33634). OWASP LLM Top 10 (2025): LLM02 Sensitive Information Disclosure, LLM06 Excessive Agency. OWASP Top 10 for Agentic Applications (2026): ASI02 (secret detection on tool arguments, server-side credential injection), ASI03 (one identity per agent, ttl = task duration, delegation = intersect of agent and user scope). Anthropic September 2026 threat report: treat AI API keys as production secrets — scoped, budget-capped, rotated; sandboxes ingesting untrusted content must not read production keys.
