---
name: mstack-help
description: "Use when you're not sure which mstack skill fits the job — 'which skill for this?', 'what can these do?', or a mid-run question that matches a skill's trigger but names none. The router answers 'which skill' and hands over the prompt — it never starts the work."
---

# mstack-help

You are the router, not the worker. Answer "which skill for X", hand over the invocation prompt, and stop. Never start the skill's procedure yourself — the user asked how, not to do it.

## When to use

Use when the user asks which mstack skill to use, what the skills can do, or asks a question that matches a skill's trigger without naming the skill.

## Procedure

1. **Layer 1 — read the context first.** What the user is doing decides the answer:
   - **Mid-run question** → find the matching skill (Layer 2) and hand over its invocation prompt; quote the relevant step, never execute it.
   - **"What can you do"** → Layer 3: the full inventory.
   - **Choosing the next skill** → Layer 2 quick-pick.
   - **Stuck or blocked** → match the symptom: can't see the failure → `how`; hidden blind spots → `interrogate`; what broke → `blast-radius`.
   - **Handing off to another agent** → give the routed skill's name plus one invocation line the other agent can run.
2. **Layer 2 — quick-pick.** Match the question against the trigger phrases. One row per skill; on a match, read the skill file first, then hand over a one-line invocation prompt and the file path. Then stop.

   | The question sounds like | Skill |
   |---|---|
   | "prove this before it ships" — a prompt, a runbook step, a skill draft | `validate` |
   | "vet this number" — a speedup, a regression, a throughput claim | `measure` |
   | "says it's done, but show me" — a fix, a feature, a test | `prove-it` |
   | "tear this apart" — a change, design, or claim with blind spots | `interrogate` |
   | "I need a trail I can audit" — long or unattended work | `show-work` |
   | "this mistake happened again" — a repeated failure class | `correct` |
   | "prove the app really does it" — no scripted verification | `verify-app` |
   | "shape this before code" — types, boundaries, competing designs | `architect` |
   | "how does this work" — a code walkthrough before a change | `how` |
   | "why is it shaped this way" — rationale, regressions, postmortems | `why` |
   | "what could this break" — the damage beyond the diff | `blast-radius` |
   | "what did this session teach" — the lesson before the next run | `reflect` |
   | "write the test first" — a bug or behavior with a cheap local test path | `tdd` |
   | "how will we verify this" — a non-trivial change needing its evidence path designed before work starts | `verification-planning` |

3. **Layer 3 — full inventory.** Point at the directory: the fourteen routable skills in `mstack/skills/` (this router makes fifteen), each in its own `<name>/SKILL.md` directory. Never re-list the table — the directory is the inventory.
4. **No match → route to the runbook that owns the question.** An open-ended task that needs designing and driving to a finish condition → `figure-it-out`. A merge-readiness gate → `final-gate`. An unattended multi-hour run → `overnight-orchestrator`. Never invent a skill that doesn't exist.
5. **Anti-loop rule.** Never route the user back to `mstack-help` for a question this skill can answer. Answer here, in one turn.

## Output

The matched skill's name plus its one-line invocation prompt plus the skill file path — or the runbook routing for no-match questions. The work itself is never started.
