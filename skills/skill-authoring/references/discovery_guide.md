# Discovery Guide

Detail for naming, descriptions, and token economy. Future agents must FIND the skill before they can follow it. Adapted from superpowers' Skill Discovery Optimization.

## Description discipline

The description answers one question: "Should I read this skill right now?" It states trigger conditions + capability-as-outcome. It NEVER summarizes the steps.

```yaml
# ❌ Workflow summary — the agent follows this instead of reading the body
description: "Use when executing plans - dispatches subagent per task with code review between tasks"
# ✅ Triggers only
description: "Use when executing implementation plans with independent tasks in the current session"
```

*Why: measured — the ❌ version made an agent run one review where the skill's flowchart required two. A description that summarizes the workflow becomes a shortcut the body can't compete with.*

Rules: start with "Use when…", third person, concrete symptoms over abstractions ("race conditions, inconsistent pass/fail" — not "async testing"), technology-agnostic unless the skill itself is technology-specific. Under ~500 characters.

## Keyword coverage

Use the words an agent would search for: error messages ("Hook timed out"), symptoms ("flaky", "hanging"), synonyms ("timeout/hang/freeze"), tool and file names. Spread them through the body, not just the description.
*Why: discovery runs on the agent's vocabulary at the moment of need, not yours at the moment of writing.*

## Naming

Verb-first, active voice: `condition-based-waiting`, not `async-test-helpers`. Gerunds work for processes: `creating-skills`, `debugging-with-logs`. Name by what you DO or the core insight — never by the mechanism alone.

## Token efficiency

Targets — verify with `wc -w`:

| Skill | Budget |
|---|---|
| Getting-started workflows | < 150 words each |
| Frequently-loaded skills | < 200 words total |
| Other skills | < 500 words |

Techniques: move flag-level detail to tool `--help`; cross-reference instead of repeating (never force-load a reference — link it by name); compress examples to the smallest runnable form; delete anything obvious from the command itself or covered by a referenced skill.
*Why: this SKILL.md loads on every trigger. Every token competes with the conversation.*

## Cross-referencing

Reference other skills by name with an explicit requirement marker: `**REQUIRED BACKGROUND:** you must understand <skill-name>`. Never a bare path (unclear whether it's required), never a force-load import (burns context before it's needed).
*Why: the reader decides what to load and when. Your links are suggestions with a priority label, not a preload list.*
