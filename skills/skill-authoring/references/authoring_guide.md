# Authoring Guide

Detail for the Draft and Deploy steps. Adapted from the Hatch `skill-creator` skill.

## Naming

| Target runtime | Directory | Frontmatter `name` |
|---|---|---|
| Hatch workspace | `kebab-case` | `snake_case` |
| agentskills.io (Claude etc.) | `kebab-case` | hyphenated, letters/numbers/hyphens only |

Keep names short, concrete, capability-based, verb-first: `skill_authoring`, not `skill_stuff`. Namespace by provider or domain when it sharpens the trigger (`google-calendar`).
*Why: the name is half the trigger — a vague name never gets loaded.*

## Resource split

Use the smallest structure that carries the skill reliably:

- `SKILL.md` — instructions that are short, stable, and needed on every trigger.
- `references/` — useful but conditional: long examples, schemas, variant notes, extended workflows.
- `assets/` — only files that become part of the delivered output.
- `bin/` — helpers for repeated protocol, credential, or parsing work. Never leave in prompt text what a helper can own. Compile Python helpers before reporting success: `python3 -m py_compile <skill-dir>/bin/*.py`.

## Frontmatter

```yaml
---
name: "my_skill"
description: "Use when [trigger conditions + capability-as-outcome]."
---
```

`name` and `description` are the trigger surface. Keep frontmatter minimal — only metadata the skill actually needs.

## Body templates

Don't invent sections. Pick the template for your kind:

### Tool-backed skill

```markdown
# Skill Title

## Purpose
One line.

## Tooling
Exact commands, key flags, and the response fields to parse.

## Auth
Where auth lives, what setup to do first, and what never to print.

## Operating Rules
Short numbered constraints the tool itself doesn't enforce.
```

### Workflow-only skill

```markdown
# Skill Title

## Purpose
One line.

## Workflow
Ordered steps.

## Output Contract
What the final result must contain.

## Operating Rules
Short numbered constraints.
```

## Connector credentials

Collecting a provider credential is `credentials.request_api_access` — a sequenced flow with external dependencies, not a file you write. Once connected, scaffold — don't start from empty. Use your runtime's connector-skill generator (on Hatch: `/opt/hatch/skills/skill-creator/bin/scaffold-connector-skill --provider <provider>`).

It writes a `SKILL.md` whose Tooling and Auth sections already carry the credential mechanics: which helper to import, where the value goes, allowed hosts, how to replace a dead credential. Write the CLIs into the `bin/` it creates; leave those two sections as generated.
*Why: hand-written auth drifts from the real flow. The scaffold can't.*

A 401/403 from the provider is a question about the request before it is a question about the key — a request built without the helper carries nothing, which looks exactly like a wrong or under-scoped token. Check the credential was attached at all before blaming the key.

## What to move out of SKILL.md

Long endpoint catalogs, full schema dumps, repeated auth snippets, tutorials, background essays, variant-specific guidance that only applies sometimes. Move it to `references/` and link it from the relevant section.
*Why: SKILL.md loads on every trigger — detail that isn't needed every time is a tax on every use.*

## Review checklist (Deploy gate)

- Description states trigger conditions + capability-as-outcome, never the steps?
- One coherent job — unrelated jobs split?
- `SKILL.md` says what to do next, not the whole domain?
- Every paragraph passes the razor: would the agent get this wrong without this instruction?
- Commands, paths, and auth flows real for this runtime — nothing invented?
- Auth has its own section, not buried in operating rules?
- Helpers own their mechanics — no duplicated protocol in prose?
- Always-load flag (`includeInPrompt` in frontmatter `metadata`, or your runtime's equivalent) unset unless the skill must load into every conversation?
- `wc -w SKILL.md` within budget (≤ 500)?
