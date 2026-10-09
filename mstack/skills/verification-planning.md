---
name: verification-planning
description: >
  Use before implementing a non-trivial change — a feature, bug fix, refactor, or cross-system edit — to decide how it will be verified: the claims, the evidence path, the budget, and what each piece of evidence must show.
---

## When to use

The work hasn't started and the question is "how will we know it worked" —
not "did it work." Reach for `verification-planning` before implementing a
feature, bug fix, refactor, or cross-system change that needs a credible,
project-specific evidence path.

**Boundary — this skill plans; the others execute and judge:**
- `measure` runs the numbers and vets a headline claim. This skill decides
  *which* numbers would count, before anyone runs them.
- `prove-it` takes a "done" claim and checks it against real state. This
  skill designs the evidence `prove-it` will later demand.
- `verify-app` builds durable project-local verification machinery. When
  this skill decides an affordance should outlive the change, that handoff
  goes to `verify-app` — or to the project's own checks — deliberately,
  never by drift.
- Small mechanical changes skip this skill: ordinary project checks are
  already the evidence path. Use it when the verification itself needs
  designing.

## Procedure

1. **Frame the claim and its uncertainty.** State the behavior that must
   become true, and separately state the conditions that could make a
   confident conclusion wrong (`state-assumptions`). Name what must change,
   what must remain true, where the behavior crosses a boundary, and which
   failure would matter most. A claim without its uncertainty is a wish —
   restate until both are concrete enough to investigate.

   Bad: "The retry logic will work."
   Good: "Retries fire on 503 with backoff, never on 400. Uncertainty:
   the staging LB may not return real 503 responses, so a green test could be
   measuring the mock, not the path."

2. **Design the evidence path from the system itself.** Derive the path
   from what this system actually offers: controllable inputs, observable
   effects, state transitions, invariants, boundaries, artifacts,
   repeatability. Generate alternatives before choosing — the purpose is
   not to pick a familiar technique but to decide how *this system* can
   reveal the truth of *this change*. Prefer the path that yields a
   trustworthy conclusion at proportionate cost, and record each
   alternative's limits alongside the choice.

3. **Set the verification budget.** List the distinct claims, assign one
   owner to establish or refute each, and choose the minimum
   non-duplicative evidence covering the claims and the important
   boundaries. Reuse evidence only while its code, inputs, environment,
   and state remain valid — a green run from before the change is not
   evidence for the change. Required repo and release checks still apply;
   broaden or repeat verification only when a stated condition justifies it.

4. **Build an affordance only when the path is indirect.** When the system
   leaves the decisive truth too indirect or ambiguous, add the smallest
   capability that makes the relevant state controllable, observable, and
   repeatable for an agent. **Decide temporary vs durable before building:**
   a temporary affordance is removed once it has served its purpose; a
   durable one is a product or project decision, not a side effect.

   Bad: a debug endpoint left in the diff because it was useful once.
   Good: "temporary probe, removed in the same diff" — or a deliberate
   handoff: "this becomes the project's health check, tracked as such."

5. **Research the unfamiliar before committing.** When the path depends on
   an unfamiliar dependency, framework, or external service, research
   first: the official or project-specific facilities, constraints, and
   trade-offs that bear on this exact verification problem. A path built
   on assumption is a plan to be surprised.

6. **Close the path: established, limited, or refuted.** After the work,
   follow the planned path and report which verdict each claim earned —
   **established**, **limited**, or **refuted** — distinguishing known
   facts from remaining uncertainty (`prove-completion`). A check that
   could not have failed does not count (`falsifiable-tests`); say what
   would have made each check fail.

## Output

A verification plan, per claim:

- **Claim** — the behavior plus its stated uncertainty.
- **Evidence path** — the chosen route, its limits, and the rejected
  alternatives.
- **Owner** — who establishes or refutes it.
- **Affordances** — each with its temporary/durable lifecycle and owner.
- **Verdict** — established / limited / refuted, with known facts
  separated from remaining uncertainty.
