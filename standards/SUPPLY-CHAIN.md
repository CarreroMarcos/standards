---
title: Supply Chain Security
version: "2.4"
scope: Supply chain security: dependencies, provenance, SBOM
consult_when: "When adding, upgrading, or reviewing a dependency, package, skill, or any third-party code."
last_reviewed: 2026-09-29
---

# Supply Chain Security

Applies to: adding, upgrading, or regenerating dependencies in AI-assisted development.

## Sections

- **The attack: slopsquatting** — hallucinated package names as the delivery mechanism
- **The second attack: poisoning the real package** — the 2026 worm wave through legitimate packages
- **Verify every suggested package at the registry — before installing** — resolve first, install second; release-age gating for new versions too
- **Treat the model as a supply-chain artifact** — pin model IDs; model change = dependency update
- **Make dependency additions explicit and pinned** — manifests and lockfiles, reviewed diffs
- **The agent never adds a dependency on its own** — propose; human approves
- **Deny install-time execution by default** — scripts off, sandboxed installs
- **Treat agent config and skill supply chain as executable** — MCP servers and skills are supply-chain artifacts
- **Scan what you pull in** — what to scan and when
- **References**

## The attack: slopsquatting

AI assistants hallucinate package names. Research across 17 LLMs (2025) found that ~20% of AI-generated code samples referenced packages that do not exist. Of those, 43% recurred across multiple queries — meaning attackers can predict which names to register.

An attacker registers a hallucinated name on PyPI/npm, and `pip install <hallucinated-name>` installs their code. The hallucination is the delivery mechanism.

## The second attack: poisoning the real package

Slopsquatting is the 2025 threat. The 2026 threat is the real package going bad: maintainer-account compromise, CI/OIDC abuse, and trusted publishing minting malware with valid Sigstore provenance — provenance attests build identity, not source honesty.

The 2026 worm wave proved it: ChainDrop (Oct 2025), Mini Shai-Hulud (Aug 2026), and the axios compromise via TanStack (Sep 2026) all shipped hostile code through legitimate packages with valid provenance. Every check in the old playbook passed; the artifact was hostile anyway.

Treat every dependency update with the same suspicion as a new dependency. A familiar name is not evidence of a clean artifact.

## Verify every suggested package at the registry — before installing

Resolve the name against the official registry first:

```bash
pip index versions <package-name>  # Python
npm view <package-name> version    # Node
```

If the package does not exist on the official registry, do not install it. Resolve first, install second — no exceptions for "it looks legitimate" or a plausible repo URL.

Check age and download history before first use — and gate new *versions* of familiar packages the same way. A fresh release of a trusted name is a new artifact; the version you approved last month says nothing about this one. A package registered yesterday with no dependents is not the same risk as an established one.

**Default gate: 14 days since release with established download history** (a sharp, sustained uptick in downloads on a fresh release is itself a signal — the 2026 worm wave rode exactly that shape). Newer than the default needs explicit human approval with a stated reason (security fix, blocked feature), recorded in the dependency-change commit. The number is a default, not a law — the human overrides it, never the agent alone.

## Treat the model as a supply-chain artifact

The plan's highest-blast-radius third party is often not a package — it is the model. A model can change server-side with no manifest diff, no registry to resolve against, no release age to gate, and no SCA scanner that sees it. It is the exact "familiar name, new artifact" attack this file warns about.

Pin and track model IDs in config (model name, version/date, endpoint). A model change gets the same treatment as a dependency update: reviewed diff, human approval, same suspicion as a new dependency. Silent model drift is a supply-chain incident.

## Make dependency additions explicit and pinned

Route every new dependency through the manifest — `requirements*.txt`, `package.json`, lockfiles — so it arrives as a reviewed diff, never as a transcript of an `install` command. Pin versions; the lockfile records what actually resolved.

## The agent never adds a dependency on its own

- New dependencies require explicit human approval. The agent proposes; the human approves. "Do not install new dependencies without approval" belongs in the agent's guardrails.
- Dependency changes land as separate commits with a human-readable justification — what the package is, alternatives considered, what the lockfile diff shows. The agent prepares this evidence; it never approves its own addition.
- Put manifests and lockfiles under CODEOWNERS so the right eyes see every change.

## Deny install-time execution by default

Most 2026 supply-chain payloads fire at install time (preinstall/postinstall scripts). Shut that door:

- Install with scripts off by default (npm v12+ behavior; `--ignore-scripts` where the manager supports it). Note: `--ignore-scripts` alone is bypassable — prefer a manager version that defaults scripts off, or block git/remote/file deps explicitly.
- Run installs sandboxed and credential-free: no secrets in the install step's environment, no network beyond the registry.
- Some payloads fire at tool launch, not install — no install-time defense catches those. That is what the approval gate and config vetting below are for.

## Treat agent config and skill supply chain as executable

2026 payloads persist in agent config dirs and arrive as skills and MCP servers:

- `.claude/`, `.vscode/`, `SKILL.md`, MCP server configs, and hook definitions are executable surfaces — vet them like code. Supply-chain worms persist via SessionStart hooks and folderOpen tasks; uninstalling the package doesn't remove them.
- Vet every MCP server before connecting (audit tools exist; pin hashes in a lockfile; keep a hash-pinned allowlist). The first malicious MCP server shipped in September 2025.
- Skills and MCP servers are supply-chain artifacts — pin them like dependencies and vet them like code. The vetting rules live in AGENTIC-SAFETY.md and MCP-SECURITY.md; don't duplicate them here.

## Scan what you pull in

Run Software Composition Analysis on dependencies, especially after AI-assisted sessions:

```bash
pip-audit  # Python
npm audit  # Node
```

**Minimum CI requirement:** SCA scan (`pip-audit` or `npm audit`) on every merge request that modifies `requirements*.txt`, `package*.json`, or `*.lock` files.

Run SCA from a pinned, trusted scanner version — scanners sit in the blast radius too, and a compromised scanner passed malware through in 2026.

**Enterprise environments:** route installs through an approved internal mirror (Artifactory, Nexus) — packages not in the mirror require explicit security review.

## References

Shai-Hulud npm worm lineage (2025–2026, incl. the axios-via-TanStack wave of Sep 2026 — valid Sigstore provenance on malicious packages: provenance proves build identity, not source honesty). @bitwarden/cli compromise (Apr 2026 — first payload explicitly hunting AI coding-tool credentials). postmark-mcp backdoor (Sep 2025 — first malicious MCP server in the wild). Clinejection (Feb 2026 — prompt injection drove an agent to run a malicious `npm install` in CI). ChainDrop worm (Oct 2025). Mini Shai-Hulud worm (Aug 2026).
