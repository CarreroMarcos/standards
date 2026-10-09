# mstack

A portable runbook system — the **procedures layer** a standards library doesn't have. Principles say what to do; runbooks say how to run the loop. One hub entry point takes "goal + done-check" and drives the right runbook, so an agent owns the whole loop (design, build, verify, report) while the human's holds stay encoded as blocking steps.

## Usage

```
/mstack <goal>. done means <checkable conditions>.
```

Give the goal and a checkable finish condition. Leave out the how and your theory of the cause. If the prompt can't form a checkable exit predicate, the hub asks — once, for exactly what's missing.

## Layout

| Path | What |
|---|---|
| `README.md` | This file — what mstack is, usage, install |
| `VERSION` | Current version (`0.0.1`) |
| `hub.md` | The router: matches your prompt to a runbook, copies its steps into the todo list. Thin — it never does the work itself |
| `values.md` | SSOT for magic numbers. Every number lives here as a named entry; runbooks reference it by name, never inline literals |
| `principles-distilled.md` | Distilled principle pointers — the named vocabulary the hub cites. Re-distilled on the biweekly sync; no-change is valid |
| `HARNESS.md` | Per-harness translation notes (Muse agents, Claude Code, OpenCode, Cursor, Codex). Runbooks stay harness-neutral |
| `runbooks/` | Seven loop procedures: bot-review-loop, overnight-orchestrator, skill-authoring-run, biweekly-standards-research, measurement-eval, final-gate, figure-it-out (fallback) |
| `skills/` | Thirteen situational tools invoked by runbook steps: validate, measure, prove-it, interrogate, show-work, correct, verify-app, architect, how, why, blast-radius, reflect, mstack-help |
| `scripts/` | `check-values.sh` (magic-number lint), `check-refs.sh` (self-containment lint) |
| `references/` | `eval-protocol.md` — how a runbook or skill earns its place |

## Install (v0.0.1)

Copy the `mstack/` folder into the target repo. Nothing references outside the folder — a copied folder works standalone. Automating distribution comes later.

## Versioning

`mstack/VERSION` holds the version. Patch = wording/fix-level changes. Minor = new runbook, new skill, or new `values.md` entry. Major = hub contract or Reply-contract change. A principles re-distillation alone does not bump.

## Design rationale

See `~/workspace/docs/superpowers/specs/2026-10-09-mstack-design.md` — decisions, the three-layer architecture, holds-as-blocking-steps, and the audit trail that shaped v0.0.1.
