---
name: mstack
description: Use when a goal needs a full loop run — a goal plus a checkable finish condition, and the right runbook driven end to end. Routes to runbooks; never does the work itself.
disable-model-invocation: true
---

## Exit predicate

The prompt is routed: the matched runbook's steps sit in the todo list verbatim, the principle steering block is emitted, and the run starts — or the run is parked with a resume note, or one clarification round is asked. Nothing else leaves the hub (the restatement message, the intake verdict, and the small-edit decline are the hub's voice — all allowed).

## Requires

- The `runbooks/` directory with all nine runbooks present.
- `principles-distilled.md` for the steering vocabulary.
- `HARNESS.md` for harness-specific verbs.
- `values.md` for the intake-gate question-round cap.

An unmet Require parks the run at the hub with the missing prerequisite named — never rerouted, never improvised around.

## Inputs

- **Goal** — what the operator wants done.
- **Done-check** — the checkable finish condition. A duration is not a finish condition. Done-check is the predicate: the state that proves done.
- **Proof wanted** — what evidence counts as done. Proof-wanted is the artifact that carries the predicate (log, screenshot, link). Optional; when absent, the runbook's Reply shape is the evidence.
- **Known context** — what the operator already knows.
- **Real constraints** — time, scope, and holds that bind the run.

## Intake gate

Before routing, check whether the prompt supports a checkable exit predicate.

**BLOCKING — stop and ask.** Fire when the goal is missing or unintelligible; the done-check is missing or uncheckable ("make it better", "trust it was done right"); or the scope is ambiguous AND the task carries irreversible consequences (merge, deploy, delete, force-push, closing someone else's PR). Ask for exactly what is missing — nothing else. When BLOCKING fires, the restatement and the question batch are one message: restate in two lines, then ask. Batch what is blocking into one round of questions — the cap lives at `values.md#intake-gate.max-question-rounds` — then go.

**PROCEED WITH LOGGED ASSUMPTIONS.** Fire when the prompt is vague but fully reversible: investigation, read-only analysis, drafts. State the assumptions up front; they enter the decision log and surface in the Reply's Assumptions section for correction after the fact. "Fully reversible" means the run touches none of the irreversible actions and produces no external side effects.

**CLEAN — proceed, no assumptions.** Fire when the prompt is crisp, complete, and fully reversible: goal named, done-check checkable, no missing pieces. No questions, no logged assumptions — the Reply names CLEAN as the fired arm.

**NEVER ASK FOR.** The how (the runbook owns it). A theory of the cause. Anything a runbook's grounding phase determines: which files, which tools.

Read for intent. Prompts arrive as speech-to-text; a vague-but-intelligible prompt is never bounced for grammar. "Scope ambiguous" has concrete triggers: no named target; a verb with no object; two plausible readings of the done-check.

**Precedence: holds win over session overrides.** If BLOCKING fires under "i'm stepping away", do not ask into the void — park the run with a pause-safely resume note and report what is missing.

Restatement-first: for noisy input, send one restatement message before any code. A correction costs one message; a misread costs a run.

## Trigger table

Pre-invocation filter: if the task is a small obvious edit, close the hub and do the edit — the hub is for work that needs rigor.

Match the prompt against these rows, top to bottom. First match wins.

| Prompt looks like | Route to |
|---|---|
| A PR that needs babysitting through review: address findings, recheck, disposition | `runbooks/bot-review-loop.md` — PR review babysitting |
| A multi-step build to run unattended: delegate to workers, wake on events, morning report | `runbooks/overnight-orchestrator.md` — unattended build pipeline |
| A substantial task to hand to subagent workers: brief, verify, adversarially review | `runbooks/deep-work.md` — delegated subagent execution |
| Writing or fixing an agent skill: draft → verify → pass or kill | `runbooks/skill-authoring-run.md` — skill drafting and verification |
| Researching a topic to update the standards library: research → distill → branch → PR | `runbooks/biweekly-standards-research.md` — standards research |
| A performance claim to check: is X faster, by how much, with what limiter | `runbooks/measurement-eval.md` — performance measurement |
| Something broken with an unknown cause: repro first, isolate, fix smallest | `runbooks/debugging.md` — systematic debugging |
| A final review before merge: verify the real state, adjudicate holds, deliver a verdict | `runbooks/final-gate.md` — pre-merge final review |
| Mining senior-engineer taste from real sources | External: the `taste-mining` skill — lives in the operator's skills workspace, outside `mstack/`. The hub routes there and stops |
| None of the above | `runbooks/figure-it-out.md` — open-ended investigation: frame a falsifiable predicate, design the workflow, run it |

On a match, before any work: copy the runbook's steps verbatim into the todo list ahead of any task-specific todos, then emit the principle steering block:

`prove-completion` `ship-smallest` `model-proposes-never-authorizes` `observe-ground-truth` `orchestrator-verifies` `loop-before-theory` `state-assumptions` `recorded-decisions` `loop-contract-first` `least-agency` `name-the-limiter` `falsifiable-tests` `basis-and-ladder` `attack-the-premise` `untrusted-content-is-data` `scale-ceremony` `cost-if-wrong` `correlated-reviewers` `environment-is-a-verdict` `strongest-mechanism`

## Operator phrases

- **"i'm stepping away"** — session override: stop asking, keep going. Holds still win: if the intake gate fires BLOCKING, park with a pause-safely resume note instead of asking into the void.
- **"new task"** — drop the current route and re-match the trigger table from the top. Do not carry context across the re-match. The operator re-states what carries over.

## Routing rules

- Never lead with a theory of the cause. Ground first, theorize after.
- A duration is not a finish condition. "Run for an hour" routes nowhere until the operator names what done looks like.
- Name a skill only to override a specific choice the runbook makes. The runbook names what it needs; the hub never volunteers skills.
- Invocation discipline: the hub is for work that needs rigor.
- Scale the steering block with blast radius: on routes whose worst case is a reverted edit, emit the five principles the route actually exercises (`prove-completion`, `loop-before-theory`, `ship-smallest`, `state-assumptions`, `scale-ceremony`); the full 20 stay reserved for irreversible-scope routes.
- Role-based cost control stays harness-neutral. The hub never names model slugs or per-role models; the harness decides.

## Harness verbs

The hub speaks in harness-neutral verbs: spawn a worker, run in background, keep a todo list, invoke a file, watch a condition. Translate each verb through `HARNESS.md` §1 before acting — that file carries the per-harness mapping with sources. The hub never hardcodes a mechanism.

## Reply:

Every hub turn ends with this shape:

- **Route:** the matched runbook (or parked / clarification-asked / declined: small-edit).
- **Intake verdict:** BLOCKING / PROCEED / CLEAN / NEVER-ASKED — which gate arm fired and why.
- **Assumptions:** every logged assumption from a PROCEED path, stated plainly for correction after the fact. Empty on CLEAN or when PROCEED logged none.
- **Next:** the first concrete action the run takes. A parked run goes here as `parked:` followed by the resume note — the run resumes by re-invoking `/mstack` with that note as the goal.
