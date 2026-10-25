# Authoring Guide

Detail for the Draft and Deploy steps. Adapted from the Hatch `skill-creator` skill.

## Naming

| Target runtime | Directory | Frontmatter `name` |
|---|---|---|
| Hatch workspace | `kebab-case` | `snake_case` |
| agentskills.io (Claude etc.) | `kebab-case` | hyphenated, letters/numbers/hyphens only |

Keep names short, concrete, capability-based, verb-first: `skill-authoring`, not `skill-stuff`. Namespace by provider or domain when it sharpens the trigger (`google-calendar`).
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
name: "my-skill"
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

## Wording

A skill's structure is not its compliance. These techniques decide whether the produced skill's rules get followed under pressure, not just when freshly read. Apply them to the draft's rule sentences in SKILL.md step 4.

### Thesis first

Open the skill — and each section — with the rule, not the background. An agent skimming for what to do finds the rule first; background after the rule is explanation, never a preamble the rule hides behind.

```markdown
# ❌ Background first, rule buried
Skills need good triggers. Trigger quality depends on many factors, and
authors often struggle. When writing a description, prefer triggers...

# ✅ Thesis first
**Description = triggers + capability-as-outcome. Never summarize the steps.**
Agents follow a summarizing description instead of reading the body.
```

### Imperatives, no hedges

Rule sentences are bare second-person imperatives. Ration MUST/NEVER for the non-negotiables. A hedge word in a rule sentence is a bug: `should`, `generally`, `consider`, `try to`, `where possible`, `unless`. Quoted examples and rationalizations don't count — only rule sentences.

```markdown
# ❌ Hedged — the agent decides whether to comply
You should generally try to keep descriptions trigger-focused where possible.

# ✅ Imperative — no exit offered
Write trigger-focused descriptions. No step summaries.
```

### Bold marks the rule

Bold the rule itself; plain text is explanation. The bold-skeleton test: read only the bold text. If the argument doesn't survive, the markers are wrong — the rule was written as prose, not as a rule.

### Bad/good pair on load-bearing rules

Every rule whose violation breaks the skill gets the wrong form and the right form, realistic, adjacent to the rule. A rule stated only positively leaves the agent guessing what the failure looks like; a rule stated only as a prohibition invites the opposite failure.

```markdown
# ❌ Rule alone — failure mode unstated
Keep SKILL.md short.

# ✅ Pair — the failure is visible
**Keep SKILL.md under 500 words; detail lives in `references/`.**
Bad: a 900-word SKILL.md the agent skims and half-follows.
Good: a 400-word core with the schema linked from `references/`.
```

### One-line why after each rule

A mechanistic why, one line, directly after the rule: what breaks, or what was measured — not an aspiration. A rule without a why is a preference; the agent drops preferences first under pressure.

```markdown
# ❌ Aspirational why
Write short skills, because brevity is a virtue.

# ✅ Mechanistic why
**Keep SKILL.md under 500 words.**
Why: this file loads on every trigger — every token competes with the conversation.
```

### No nuance clauses

No inline "unless", exemption, or condition clause inside a rule. A real exception becomes its own rule or a named route — never a tail on the rule it undermines. An inline exemption is the rationalization, pre-written.

```markdown
# ❌ Exemption tail — the rule rationalizes itself
Never summarize steps in the description, unless the steps are short.

# ✅ Exception as its own rule
**Never summarize steps in the description.**
Exception route: a one-step skill may name its single step in the description — the trigger and the step are the same sentence.
```

### Close with the next action

The last line of the skill directs action, never summarizes. A recap at the end is where the agent stops reading; a next action is where it starts doing.

### Match form to failure

- Shape failure (output has the wrong form) → positive recipe: what the output *is*, parts in order. Never open with "don't" — on shaping problems, prohibitions produce more of the unwanted content than recipes.
- Discipline failure (agent knows the rule, skips it under pressure) → prohibition + rationalization table + red flags.
- Omission failure (agent drops a required element) → structural slot in a template.

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
- Wording: hedge grep on the draft's rule sentences — `should|generally|consider|try to|where possible|unless` in a rule sentence is a bug (quoted examples excluded)?
- Wording: bold-skeleton test — read only the bold text; if the argument doesn't survive, the markers are wrong?
- Wording: close test — the last line directs action, not summary?
