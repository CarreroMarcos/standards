---
name: verify-app
description: Use when an app has no scripted way to prove its real behavior — or when the scripted way it has may have rotted. This skill generates project-local verification skills and keeps them honest.
---

## When to use

The project needs a repeatable way to operate the actual app and confirm behavior — start it, walk a user path, keep the evidence — and either has nothing or hasn't re-checked what it has since the app changed. Phase A generates the skill; Phase B maintains it.

## Procedure

### Phase A — Generate the `verify-<app>` skill

1. **Interview the repo, not the operator.** Answer from the codebase; ask only what you cannot observe:
   - **Surface:** which part of the app does a human actually use? Web UI, CLI, API, desktop, mobile, library — name the primary surface and note the rest.
   - **Run:** how is the app launched for local work? Use the repo's documented entry point; record the ports, environment, seed data, and auth it needs.
   - **Drive:** through what channel can an agent operate it? Prefer whatever the repo already has (specs, PTY helpers, HTTP endpoints) — reach for a generic recipe only when nothing exists.
   - **Observe:** what proof can the run leave behind? Screenshots, terminal output, response payloads, logs, exit codes, database state.
   - **Isolate:** can two copies run concurrently without sharing ports, data, or profiles? If not, the generated skill says so — never let a run corrupt the operator's live session by double-driving it.
2. **Fix a broken base first.** When the checkout won't build or boot as-is, repair it (or report exactly what's wrong) before generating — instructions written against a broken starting point teach the wrong moves.
3. **Write the skill to the five-section template**, grounding every section in interview findings — no placeholders:
   - **Launch:** the precise command that starts the app, plus the signal that it's ready (a log line, an answering port, a shell prompt) — and how to tear it down.
   - **Doctor:** one read-only check answering "is this instance worth driving?" — run it first whenever anything looks off.
   - **Drive:** the interaction recipe using this repo's actual selectors and commands — prefer durable handles (labels, data attributes, route paths) over screen coordinates and tab order.
   - **Evidence:** what to capture and where it lands. Drive the genuine user journey — never internal setters or test-only backdoors; record both the action taken and the state it produced; check the side effects too (files, rows, messages sent), not just what's on screen; use mocks only where a real production boundary already walls off the external system.
   - **Cleanup:** tear down what the run created. Kill what you started — never by process name. Proof artifacts survive teardown at the location the skill names.
4. **Prove it end to end before handoff.** Execute its own instructions a single time — launch, doctor, drive one genuine user path, gather evidence, tear down — then verify the evidence is still present where the skill says it lives. A generated skill earns the name only after it has executed end to end — until then it is a draft, not a handoff (`prove-completion`).
5. **Ship it to the target repo, never to mstack/.** The generated skill is project-local by design — it lives where the app lives.

### Phase B — Maintain the generated skills

6. **Audit on a schedule.** For each project-local verification skill: read its own docs, check the app still does what they describe, drive the paths live.
7. **Pick one outcome per skill and say which:**
   - **clean** — everything still checks out; nothing to ship. No branch, no PR.
   - **changed** — the app moved; ship proven corrections to the skill.
   - **blocked** — coverage could not finish. Say exactly what blocked it — never fake it.
8. **Never touch product code during an audit.** When the app no longer does what the docs describe, that's either drift in the docs (fix them) or a regression in the product (report it — never hide it by editing docs).

## Output

- **Phase A:** the generated skill's path in the target repo, plus the end-to-end proof — which user path was driven, what evidence was captured, where it lives.
- **Phase B:** per skill, one verdict — clean / changed / blocked — each with the evidence behind it.
