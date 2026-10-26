# Eval protocol

How a runbook or skill earns its place in mstack. **Nothing ships without
passing both stages.** A runbook that fails the gate is a draft, not a
runbook — the defect is in the artifact, never the agent.

## Stage 1 — playground

**Run the artifact before trusting it.** A fresh subagent executes the
runbook against a scratch target. For skills, trigger-probe execution:
fire the skill on 3–5 trigger-shaped prompts and check it does its job —
blinded per the `validate` skill whenever the run compares the draft against
a baseline or incumbent.
Then the artifact itself passes five audits:

1. **Bold-skeleton read.** Read only the bold lines top to bottom. The
   skeleton reads as coherent imperatives. A skeleton that doesn't make
   sense means the steps don't either.
2. **Hedge grep.** Run `rg -i '\b(should|generally|consider|try to|where possible|unless)\b'` — every hit is either inside a quoted rationalization, inside this step's own pattern line, or a bug. Fix the bugs.
3. **`check-values.sh` clean.** `bash scripts/check-values.sh values.md
   <file>` exits 0. Every magic number is a named entry in `values.md`;
   markdown references it by name, never inline.
4. **`check-refs.sh` clean.** `bash scripts/check-refs.sh <file>` exits 0.
   Nothing references outside `mstack/`.
5. **Contradiction pass.** List the artifact's normative statements: every
   bold imperative, every must / never / always, every exit predicate and
   done-check, every route (trigger-table row, skill-symptom mapping). Then
   check pairs, twice: (a) inside the artifact — for any two statements on
   the same subject, does one permit what the other forbids, define a term
   the other uses differently, or route a prompt shape to X where the other
   routes it to Y; (b) against the artifact's own description and the hub
   steering it inherits — a skill whose description promises one behavior
   cannot contain a rule permitting the opposite. A hit is a finding, not
   a judgment call: narrow the broader statement, scope the exception
   explicitly, or delete the weaker one — never keep both and let the
   agent pick. Re-run the pass after the fix.

All five green, or the artifact never leaves the playground.

## Stage 2 — pilot

**One real low-stakes run of the encoded loop.** Generic by design:
whatever loop the runbook encodes, run it once for real on something
low-stakes. Instances: a session-mining run, a recurring
research-and-publish cycle. Record what happened — the log is the evidence
this protocol trusts later.

## The bar

A runbook or skill ships when all three hold:

- **(a) Artifact parity.** The agent produces the same artifacts a manual
  run would, with nothing beyond the single intake round.
- **(b) Zero bypassed gates.** Every hold fires as a blocking step. A gate
  skipped is a failure, not a shortcut.
- **(c) Audit pass.** All five Stage 1 audits green on the final text.

**If it fails, the runbook is the defect, not the agent.** Fix the
artifact, re-run both stages. Never tune the agent's prompt to work
around a broken runbook.

## Pilot-before-fanout

**One unit through the whole path before parallel lanes.** Before a
runbook scales to fan-out, run one unit end to end to falsify the brief
template and the coordination steps. A template that survives one real
unit earns the swarm; a template that only worked in the playground does
not.

## Growth governor

**A new skill is admitted only when the same failure shows up twice.**
v0.0.1's thirteen are the seeded set; the selection bar — not enthusiasm
— admits the fourteenth. The `reflect` skill's Backlog is the occurrence
ledger: each candidate failure gets one entry per observed occurrence, and
two occurrences with the same shape is the admission threshold. Below
two, it stays in the Backlog.

- ❌ "This would be a nice skill to have" → stays in the Backlog.
- ✅ "The same missing check burned two runs — Backlog entries #12 and
  #19" → draft the skill, then run this protocol on it.
