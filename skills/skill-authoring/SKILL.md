---
name: "skill-authoring"
description: "Use when creating or editing a workspace skill — to produce one that is easy to trigger, cheap to load, and verified to work."
---

# Skill Authoring

## Purpose

Write skills that are easy to trigger, cheap to load, and proven to work — verified against agent behavior, not just inspected.
*Why: an untested skill is a rumor. The check is the proof.*

## Workflow

### 1. Scope: one skill, one job

One skill = one coherent job — split unrelated jobs. Name it verb-first, capability-based: `skill-authoring`, not `skill-stuff`.
*Why: the description is the trigger surface — a vague name never gets loaded.* → `references/discovery_guide.md`

### 2. Draft: the smallest core that teaches

Use your kind's body template — `references/authoring_guide.md`. Use only its sections.

**Description = triggers + capability-as-outcome. Never summarize the steps** — agents follow the description instead of reading the body.

```yaml
# ❌ The agent follows this instead of the body
description: "Use when executing plans - dispatches subagent per task with code review between tasks"
# ✅ Triggers only
description: "Use when executing implementation plans with independent tasks in the current session"
```

*Why: measured failure — the ❌ version made an agent run one review where the skill required two.*

Operational core only in `SKILL.md`. Bulky docs → `references/`, output assets → `assets/`, helpers → `bin/`.

Per paragraph, ask: would the agent get this wrong without this instruction? If no, cut it.

### 3. Verify: RED-GREEN-REFACTOR

**Iron Law: no skill ships without a failing test first — no edit either.** Untested edit? Delete it. Tested edit? Normal cycle.

Micro-test wording first: fresh-context sample, no-guidance control, 5+ reps, read every match. Control doesn't fail? Nothing to fix — stop.
*Why: full scenario runs are slow and expensive; wording tests are the cheap gate.*

Discipline-enforcing skills get pressure scenarios (3+ combined pressures). Probe discovery — 3–5 trigger probes (task in, right skill loaded?) — and neighbors for interference. → `references/testing_method.md`

### 4. Harden the wording

Match the form to the failure. Wrong-shaped output → positive recipe: state what the output *is*, in order. Rule broken under pressure → prohibition + rationalization table + red flags.
*Why: measured — prohibitions produced more unwanted content than recipes, and trended worse than no guidance.*

### 5. Deploy

Deploy checklist (`references/authoring_guide.md`); commit on a branch — never ship untested edits to main.

## Token budget

≤ 500 words — verify with `wc -w`. Detail lives in `references/`, loaded on demand.
*Why: this file loads on every trigger — every token competes with the conversation.*

Never force-load a reference — link it by name.

Log verification tokens per skill (`references/testing_method.md`). Verification costlier than lifetime use = overkill — drop a tier.

## Target runtime

Targets workspace skills — naming table in `references/authoring_guide.md`.

## Operating rules

1. Preserve working commands, paths, auth flows — never invent binaries or endpoints.
2. Connector skills: generate Tooling/Auth from your runtime's skill scaffold — don't hand-write what the helper owns.
3. A 401/403 is a question about the request before the key — check the credential was attached at all.
4. Python helpers in `bin/`: `python3 -m py_compile` them before reporting success.
