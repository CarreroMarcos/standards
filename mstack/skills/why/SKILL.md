---
name: why
description: Use when "why does X work this way" needs evidence, not a guess — design rationale, regressions, postmortems, data-backed thresholds. Investigates the forces behind a shape and converts them into constraints before anyone changes it.
---

## When to use

How the code works is a read; why it is shaped that way is an
investigation. Reach for `why` when the rationale behind a design is
what stands between you and a safe change — a regression that smells
like a violated tradeoff, a magic number that needs its origin story,
a postmortem that needs the real forcing function. Guesses about intent
do not answer this skill; sourced evidence does.

## Procedure

1. **Pin the target and the question.** Name the exact thing under
   investigation — a behavior, a design choice, a threshold, a
   regression — and the precise question about it. If the target is
   vague, state how you read it so the caller can redirect, then
   proceed. No evidence-gathering starts before the question is sharp.
2. **Build the coverage map.** List every evidence factor the question
   could touch: the change history behind the target, the review
   discussion on those changes, the design documents or specs, the
   incident and error record that motivated any defenses, the
   runtime/infra signals the code reacts to, the product or data reality
   it encodes. Search each one and record the result. **A searched-and-
   absent factor is a finding, not a gap** — evidence of absence goes on
   the map next to evidence of presence. An unchecked row is a hole; a
   checked-empty row is a result.
3. **Grade every factor into a confidence tier.** **Found** — direct
   evidence (a commit message, a review comment, a spec paragraph, a
   metric) says so; quote the source. **Infer** — the shape strongly
   suggests a cause but no source states it; mark it Infer and keep the
   reasoning visible. **Competing** — two or more sources point
   different ways; hold both, never pick the convenient one.
   **Unknown** — no evidence and no responsible inference; say so
   plainly. **Never present an Infer as a Found.** Promoting an Infer
   needs new evidence, not stronger wording. When the trail runs cold,
   resist the urge to fill it: an honest Unknown outranks a confident
   guess every time.
4. **Say the assumptions out loud** (`state-assumptions`). Before drawing
   conclusions, write down what you assumed — which sources you treat as
   complete, which are silent by design, where the record ends.
   Assumptions are load-bearing: unstated ones rot into facts.
5. **Convert the map into constraints.** When the why-question precedes
   a change, translate the graded map into the four constraint kinds:
   **Preserve** — what the rationale requires the change to keep;
   **Change** — what the rationale licenses or demands to move;
   **Avoid** — approaches the record shows already failed or were ruled
   out; **Risk** — where the record is silent or competing, so the
   change carries unpriced exposure. **Every constraint traces to its map
   entries** — a constraint without a trace is opinion. The map and the
   constraints go on the record together (`recorded-decisions`): they
   are the decision the change will be judged against.

## Output

The investigation's hand-back:

- **Coverage map** — every factor, each with its tier (Found / Infer /
  Competing / Unknown) and its evidence pointer, or its
  searched-and-absent mark
- **Constraints** — the Preserve / Change / Avoid / Risk list, each
  traceable to its map entries
- **Assumptions** — stated out loud, with where the record ends
