---
name: show-work
description: "Use when a run needs a reviewable trail — long-running or unattended work, anything a human reviews after stepping away — and 'trust me' is not evidence."
---

# show-work

One log per run, and it is the record. If the work can't be reconstructed from the log, the log failed.

## When to use

Any run whose result a human (or a gate) must trust without watching it happen: overnight runs, multi-phase builds, work reviewed after stepping away. Runbooks name this skill at their checkpoint and handoff steps — invoke it there, not as an afterthought.

## Procedure

1. **Open the log before the first decision.** One TSV file per run: `.mstack/runs/<slug>/decisions.tsv` — `<slug>` from the invoking runbook's run (the runbook's Inputs may name another path). One file per run: concurrent runs never interleave rows. The first row is the header:
   `ts	decision	alternatives	evidence	result`
2. **Log the decisions, not the keystrokes.** One row per: a fork chosen, a unit completed with its verification result, a pivot or revert with its trigger, a blocker surfaced, a gate fixed. One row per loop iteration. Skip the trivial and self-evident.
3. **Write each row so a reviewer reads it at a glance.** Single-line cells, plain words, concrete actions. Columns:
   - **ts** — ISO8601 timestamp of the decision.
   - **decision** — what was chosen or done, one line.
   - **alternatives** — what else was considered and why it lost (`recorded-decisions`).
   - **evidence** — a pointer that proves it: commit SHA, PR number, `file:line`, artifact path. **Evidence points; it never narrates.**
   - **result** — the outcome: `tests green`, `reverted`, `INCONCLUSIVE`, `open`.
4. **Append-only, always.** Supersede, never rewrite: a wrong call gets a new row that supersedes it; history is never edited or deleted. Corrections are new rows, never edits.
5. **Audit the log against the run's artifacts at end of run.** `HARNESS.md` defines no transcript verb (§1's verbs are spawn, background, todo, invoke, watch, isolate): read this run's evidence targets instead — resolve every row's pointers (commits, PRs, files, artifact paths) and re-derive the run's actions from its git history, run directory, and files on disk — this run only, never another run's rows or another project's. A row whose action left no on-disk residue gets an explicit `unresolvable` verdict, never a silent pass. Walk the rows against what actually happened:
   - Every row maps to a real decision or action; every row's evidence resolves and shows what the row claims.
   - A fork, pivot, or abandoned approach that shaped the work but isn't logged is a gap — add it as a row.
   - **Fix the record, not the narrative.** The audit never edits or removes a row, even an invented one. A row that records nothing real gets a superseding row with what actually happened and a pointer that resolves.
6. **Cross-model Attention review before handoff.** A reviewer on a different model family than the one that did the work reads the trail and its evidence targets — not a redo, a scan for what the author can't see: decisions logged with weak or absent evidence; verification steps skipped or claimed without proof; choices that look risky in hindsight; gaps a casual skim would miss. Where only one model family is available, same-model review runs with an explicit caveat flag. **Close every trailed run's reply with an Attention section** — "No flags found" is a complete answer.

## Output

The log's location, plus the audit findings: unlogged decisions found and added, and the Attention section (flags, or "No flags found").
