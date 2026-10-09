---
name: reflect
description: Use when a session, runbook run, or long loop ends — and its lesson must be captured before the next session pays for the same failure again.
---

## When to use

When the work is over and the lesson is still warm: a mistake repeated, a pattern that worked and deserves repeating on purpose, or a surprise that overturned an assumption. Skip it for trivial or off-topic work — one-offs are not learnings.

## Procedure

1. **Mine the session through three lenses.** Read the transcript; where the transcript is unreachable, work from a tight digest instead. One pass per lens — parallel where the harness supports subagents, sequential where it doesn't:
   - **What worked** — patterns worth repeating on purpose, not luck.
   - **What failed** — mistakes, rework, and wasted rounds, with the evidence attached.
   - **What surprised** — wrong predictions, and what the evidence actually said.
   **One-offs are not learnings**: a single anecdote with no recurring shape is noise, not a lesson.
2. **Triage every candidate — one bucket each.** Every candidate lands in exactly one list:
   - **Accepted** — a rule worth keeping, with its why. The why ships with the rule: no rule without the reason it exists (`recorded-decisions`).
   - **Rejected** — considered and declined, with the reason. **A rejected lesson is still `recorded-decisions`**: record the decline and its rationale so it is never relitigated.
   - **Backlog** — undecided. Every Backlog item carries an occurrence ledger: the count of observed occurrences, each with an evidence pointer (commit, revert, review comment, correction).
3. **Run the structural-enforcement check.** Before an Accepted lesson becomes a paragraph, ask whether a lint, script, type, or runtime check enforces it more reliably. **If the lesson can be enforced mechanically, the lesson is the enforcer, not the paragraph** — move the item to Backlog with the enforcer's design, and ship the check, not the prose. **Docs are the weakest rung**: nothing fails when an agent skips them.
4. **Apply the growth-governor rule.** A Backlog item is admitted as a new skill only at `values.md#growth-governor.occurrences` occurrences of the same failure. **Never at one**: one occurrence is an anecdote, not a curriculum. When the ledger hits the threshold, the item ships as a new skill through the skill-authoring runbook; below the threshold it stays in the ledger.
5. **Never auto-apply Accepted edits.** Edits land in shared skills, not in one session — present the full Accepted/Rejected/Backlog output and wait for explicit approval before touching anything. The operator picks the subset and may redirect a routing. File Backlog items to the tracker automatically; Rejected items stand as written.

## Output

- **Accepted** — each rule with its why, its routing, and where it landed.
- **Rejected** — each declined candidate with its reason (`recorded-decisions`).
- **Backlog** — each undecided item with its occurrence count and evidence pointers.
