---
name: interrogate
description: "Use when a change, design, or claim needs adversarial review — 'tear this apart', 'find the blind spots', 'stress-test this before it ships'. Multiple independent reviewers attack the artifact from separate angles; the skill reports, never applies."
---

# interrogate

## When to use

Use when an artifact is about to be trusted — a diff, a design, a runbook, a skill, a measurement claim — and friendly review would miss what an adversary would find.

## Procedure

1. **State the intent under attack first.** Write one paragraph: what the artifact is supposed to achieve. Attack the premise before the implementation (`attack-the-premise`) — a flawless execution of the wrong intent is still a failure. If the intent is unclear, ask before convening anyone.
2. **Convene ≥ `values.md#interrogate.min-reviewers` independent reviewers.** Independent means no shared context beyond the artifact and the intent — separate reviewers, separate passes. Prefer different model families where the harness offers them; one reviewer is an opinion, not a red team. Every reviewer gets the same brief — the intent, the artifact, the rubric below — identical inputs, so divergence means disagreement, not different information. The harness decides how reviewers are spawned (HARNESS.md); the protocol decides they stay independent.
3. **Each reviewer attacks separately.** The brief: find real problems — bugs, design flaws, security issues, maintainability concerns. Each finding names a severity (`critical` | `warning` | `nit`), the concrete location, the evidence (why it matters — never an assertion without reasoning), and a suggestion only when one is concrete. A reviewer who finds nothing says "no findings" and stops — an empty review is a valid outcome, not a failure.
4. **Synthesize.** Merge the findings: dedupe descriptions of the same issue, noting which reviewers raised it; mark consensus — raised independently by 2+ reviewers — as the highest signal; weight lone-reviewer findings lower but read them; note explicit disagreements (one reviewer flags what another explicitly clears) as context for the verdict.
5. **Lead judgment.** You are the lead: filter, don't just aggregate. Bucket every finding:
   - **Act on.** Real issues against correctness, security, or maintainability given the actual goals. More than 5 Act Ons means the filter is too loose — cut harder.
   - **Consider.** Legitimate, but the cost of addressing it now may outweigh the gain. Worth attention, not a blocker.
   - **Noted.** Technically valid but not actionable — premature, context-dependent, low impact at this stage.
   - **Dismissed.** Wrong, nitpicky, or missing context — with a one-line reason. Dismissals are a trust mechanism: show what was rejected and why, so the reader can override.

   Filtering rules: trace hypotheticals to a real path ("what if null?" counts only if null can arrive); dismiss "I would have done it differently" when it names no concrete problem with the current approach; dismiss findings that reveal missing context (flagging untouched code, fighting known constraints). Never dismiss a security or correctness finding for being uncomfortable — discomfort is the point.
6. **Build the Agreement Map.** Where reviewers agreed, where they diverged, and what the pattern means. Agreement across independent reviewers is the verdict's load-bearing evidence; a lone critical finding with a named evidence chain outranks a consensus of nits.
7. **Report — never auto-apply.** The skill hands over the verdict. The human or the gate decides what changes. Applying findings is a separate act with its own authorization.

## Output

- **Intent** — the stated paragraph from step 1.
- **Reviewers** — one line each: reviewer, model family, finding count.
- **Act on / Consider / Noted / Dismissed** — every finding bucketed, each with which reviewers raised it and the lead's one-line rationale.
- **Agreement Map** — consensus points, divergences, and what the pattern means for trust in the artifact.
