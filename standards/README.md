---
title: Standards
version: "1.0"
scope: Index and routing table for the standards library
last_reviewed: 2026-09-27
---

# Standards

Routing table for this library. Each file is the single source of truth for its topic — don't duplicate content across files.

| File | Topic |
|------|-------|
| ENGINEERING_PRINCIPLES.md | Core engineering decision principles: design, testing, change safety, agentic systems |
| AGENTIC-SAFETY.md | Indirect prompt injection defense; subagent scope and trust violations |
| CODE-QUALITY.md | Code quality rules for AI-generated code (verification, comments, structure, error handling) |
| CODE-REVIEW.md | What constitutes a complete review: vocabulary, evidence integrity |
| LOGGING.md | Structured logging conventions |
| MCP-SECURITY.md | MCP server trust and tool-result handling |
| RULES-FILE-INTEGRITY.md | Hygiene rules for AI assistant rules files |
| SECRETS.md | Ephemeral-by-default secrets management; agent-safe posture |
| SUPPLY-CHAIN.md | Dependency verification and SCA scans |
| TRUST-CLASSIFICATION.md | Trust levels for content sources in agentic workflows |
| WORKFLOW.md | Portable feature-development discipline through a clean commit; the operated loop is DEV-LOOP.md |
| DEV-LOOP.md | Agentic build-loop runbook: ticket → implement → verify → bot rounds → Oracle gate → merge |

## Conventions

- One topic per file. Files stay tool-agnostic and portable to any repo.
- To add a standard: drop in a scannable one-topic file and add one row to the table above.

