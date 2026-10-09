---
title: Standards
version: "2.1"
scope: Index and routing table for the standards library
consult_when: "When you need to find which standard covers your current task."
last_reviewed: 2026-10-08
---

# Standards

Route by what you are **doing**, not by what a title sounds like. Find the row whose "when" matches your current task, read that file, and skip the rest. Each file is the single source of truth for its topic — don't duplicate content across files.

## How to use these

These are best practices, not laws. Context matters — some rules don't fit certain tasks, and a rule applied where it doesn't fit is worse than no rule. When a rule doesn't fit, set it aside explicitly: name the rule, state the reason, record it where the decision lives. (Full statement: ENGINEERING_PRINCIPLES.md §0.)

| When you are… | Read | Skip when / precedence |
|---|---|---|
| Giving an agent tools, autonomy, or access to untrusted input (webpages, files, uploads, tool results, CI/build logs, PR diffs) — or adding/changing any model-directed step (prompts, LLM calls, agent loops) | AGENTIC-SAFETY.md | Skip when no model is acting. Read first whenever agents are involved — it owns the Rule of Two. |
| Handling credentials, API keys, or tokens — storing, passing, logging, reviewing code that touches them, or letting an agent near them | SECRETS.md | Skip when no secret material is involved. Wins over CODE-REVIEW on secret findings. |
| Deciding whether content can be acted on or only read — classifying a page, tool output, file, or message by trust tier, even when it looks first-party | TRUST-CLASSIFICATION.md | Skip when every input is first-party code you wrote. Classify before acting. |
| Adding, upgrading, or reviewing a dependency, package, skill, plugin, or any third-party code — including "just a patch bump" | SUPPLY-CHAIN.md | Skip when no new external code enters the repo. The agent never adds a dependency on its own — propose, human approves. |
| Selecting, configuring, or auditing MCP servers and their tool definitions | MCP-SECURITY.md | Skip when no MCP servers are involved. AGENTIC-SAFETY owns the general agent rules; this file owns MCP mechanics. |
| Writing or modifying agent instruction files (AGENTS.md, CLAUDE.md, rules, skills) — even "just a formatting tweak" or a bot's PR | RULES-FILE-INTEGRITY.md | Skip when not touching instruction files. Rules files are code — every diff gets human review. |
| Adding or changing log/telemetry statements, or deciding whether a field is safe to log | LOGGING.md | Skip when not emitting telemetry. Never log secrets — SECRETS.md owns why. |
| Reviewing a diff — yours, a bot's, or another agent's | CODE-REVIEW.md | Skip when not reviewing. Advisory — the owning gate defines pass/fail. |
| Writing anything a human reads — documentation, PR descriptions, reports, commit messages | WRITING.md | Skip when the output is code or a terse status. Response shape lives in AGENTIC-DESIGN §10. |
| Writing or changing code — especially when tempted to skip the small stuff ('just a quick fix', 'the diff is obvious') — or preempting review nits (proof of completion, file hygiene, error handling) | CODE-QUALITY.md | Skip when a specific standard already answers the question. Design principles live in ENGINEERING_PRINCIPLES. |
| Writing tests — unit, integration, edge cases, e2e — or deciding what to mock, what coverage to require, or whether a test is actually proving anything | TESTING.md | Skip when not writing tests. Philosophy lives in ENGINEERING_PRINCIPLES.md §4; the TDD loop in WORKFLOW.md Phase 4. |
| Trusting a number you measured — a speedup, a regression, a throughput, a latency, or an eval result — before reporting or acting on it | MEASUREMENT.md | Skip when no number is being trusted. A number without a named limiter is a rumor. |
| Debugging a failure — building the repro, minimizing it, testing hypotheses, instrumenting — or when a debug session is spiraling | DEBUGGING.md | Skip when nothing is broken. The gates (red-capable repro, three-strikes) live in AGENTIC-DESIGN.md §4 and DEV-LOOP.md. |
| Writing Python — style, typing, async, errors, tooling, or performance | languages/PYTHON.md | Skip when not writing Python. Language-neutral principles live in ENGINEERING_PRINCIPLES; per-task quality rules in CODE-QUALITY. |
| Writing TypeScript — strictness, narrowing, casts, guards, schemas | languages/TYPESCRIPT.md | Skip when not writing TypeScript. Shared type-system discipline lives in TYPED-LANGUAGES.md. |
| Designing with a type system — sum types, branding, exhaustive matching, parse-at-boundary | languages/TYPED-LANGUAGES.md | Skip when the language is untyped. Language mechanics live in the language files under languages/. |
| Starting or planning a unit of work, from idea through clean commit | WORKFLOW.md | Skip when the work is already ticketed inside the dev loop. Ends at commit — DEV-LOOP owns push to merge. |
| Operating the ticket → implement → verify → review → gate → merge loop | DEV-LOOP.md | Skip for one-off changes on the verbal go-ahead path. Documents the loop as operated. |
| Designing a system or choosing architecture — 'we need microservices', 'just add a retry', 'which database' — or when the diagram is getting drawn before the failure modes | ARCHITECTURE.md | Skip when not making architectural decisions. |
| Designing agent systems or multi-agent orchestration — autonomy boundaries, architecture choice, evaluation | AGENTIC-DESIGN.md | Skip when no model is acting. AGENTIC-SAFETY owns the safety controls; this file owns the design. |
| Making a judgment call no specific file covers — 'the rules point both ways', 'which principle wins here' | ENGINEERING_PRINCIPLES.md | A specific standard always wins over a general principle. Check §0 when two rules seem to conflict. |

## Conventions

- One topic per file. Files stay portable to any repo — language-specific files are welcome; coupling to a specific tool is not.
- Project conventions win: these standards are the default, not the law. When the repo you're in has an established local pattern that contradicts a rule here, follow the project and note the deviation.
- Each file's frontmatter `consult_when` is the source of truth for its table row — this table mirrors it. Update both together.
- To add a standard: drop in a scannable one-topic file and add one row to the table above.
- When you finish a non-trivial task, state which standards you consulted and why.
