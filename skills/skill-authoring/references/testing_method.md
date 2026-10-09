# Testing Method

Detail for the Verify and Harden steps. Skill creation is TDD applied to process documentation. Adapted from superpowers' `writing-skills`.

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

New skills AND edits. Write the skill before testing? Delete it. Start over. Edit without testing? Same violation. Delete means delete.

| TDD concept | Skill equivalent |
|---|---|
| Test case | Scenario run on a subagent |
| RED (fails) | Agent violates the rule without the skill — document rationalizations verbatim |
| GREEN (passes) | Agent complies with the skill present |
| REFACTOR | New rationalization found → add explicit counter → re-verify |

*Core principle: "If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing."*
*Why the Iron Law: your draft reveals what YOU think needs preventing. The baseline reveals what ACTUALLY needs preventing. They're never the same on the first try.*

## Micro-test wording first

Full scenario runs are slow and expensive per iteration. Verify the wording itself first:

1. **One fresh-context sample per call** — system prompt = the realistic context the guidance will live in (the full skill, not the guidance in isolation); user message = a task that tempts the failure.
2. **Always include a no-guidance control.** If the control doesn't fail, there is nothing to fix — stop.
3. **5+ reps per variant.** Single samples lie.
4. **Read every flagged match manually.** Template echoes and quoted counter-examples masquerade as hits; automated counts overstate both failure and success.
5. **Variance is a metric.** Five different interpretations across five reps = the wording isn't binding. Tighten the form before adding words.

Micro-tests verify wording. They don't replace pressure scenarios for discipline skills.

## Trigger probes (test discovery)

The description is untested until an agent reaches for the skill on its own.

1. Collect 3–5 realistic task descriptions: some that SHOULD trigger this skill, some nearby ones that should NOT.
2. Present each to a fresh-context agent alongside 2–3 other skill descriptions (descriptions only, no body text).
3. Record which skill it reaches for — or none.

Pass: loads this skill on should-trigger tasks, doesn't on shouldn't-trigger ones. Fail → fix the description (keywords, triggers), not the body. → `discovery_guide.md`
*Why: the body gets tested constantly and the description never — yet discovery is the first gate. A skill nobody loads doesn't exist.*

## Pressure scenarios (discipline-enforcing skills)

Test skills agents have an incentive to bypass: discipline rules, compliance costs, anything contradicting speed. Skip for pure reference skills.

| Pressure | Example |
|---|---|
| Time | Deploy window closing in 5 minutes |
| Sunk cost | 4 hours in — "wasteful" to delete |
| Authority | Senior says skip it |
| Economic | Job or promotion on the line |
| Exhaustion | End of day, want to go home |
| Social | Looking dogmatic |
| Pragmatic | "Being pragmatic, not dogmatic" |

Combine 3+ pressures. Force a concrete choice (A/B/C), real constraints, real paths. Ask "what do you do?" — not "what should you do?" No easy outs ("I'd ask my human" without choosing).

Run WITHOUT the skill (RED — capture rationalizations verbatim), write the minimal skill addressing those exact failures (GREEN), re-run WITH it. Still fails? The skill is unclear or incomplete — revise, re-test.

## Neighbor regression check

Skills can degrade nearby tasks — SkillsBench measured negative effects on 16 of 84 tasks. After GREEN:

1. Pick 2–3 tasks from neighboring skills' domains (or general tasks adjacent to this skill's).
2. Run them WITH the new skill loaded; compare against the no-skill baseline.
3. Any degradation → the skill overreaches: too broad, trigger too loose, or wording leaking into other tasks. Narrow the scope or tighten the description.

*Why: passing your own evals while silently breaking adjacent work is the most expensive kind of "working."*

## Match the form to the failure

Classify the baseline failure before writing guidance. The wrong form measurably backfires.

| Baseline failure | Right form | Wrong form |
|---|---|---|
| Skips a rule under pressure (knows better, does it anyway) | Prohibition + rationalization table + red flags | Soft guidance ("prefer…", "consider…") |
| Output has the wrong shape | Positive recipe: state what the output IS, in order | Prohibition list |
| Omits a required element | Structural: REQUIRED slot in the template | Prose reminders near the template |
| Behavior depends on a condition | Conditional on an observable predicate | Unconditional rule + exemption clauses |

*Why: superpowers' head-to-head wording tests found the prohibition arm produced clearly more of the unwanted content than the recipe arm — and trended worse than even the no-guidance control. Never reach for the prohibition by default; micro-test your own case.*

Two rules for whichever form you pick:

- **No nuance clauses.** "Don't X unless it matters" reopens the negotiation — appending one nuance clause degraded a winning recipe from consistent to noisy in the same tests.
- **Exemption clauses don't scope.** "This limit doesn't apply to code blocks" still suppresses code blocks. Restructure so the rule can't reach the exempt part.

## Bulletproofing (discipline skills)

- **Close every loophole explicitly.** "Write skill before testing? Delete it. Start over." — plus each workaround forbidden by name: not kept as "reference", not "adapted" while testing, don't look at it.
- **Spirit-vs-letter:** "Violating the letter of the rules is violating the spirit of the rules." Cuts off a whole class of rationalization.
- **Rationalization table:** every excuse from testing goes in — verbatim excuse → reality.
- **Red flags:** a self-check list ("Code before test", "I'll test after", "Keep as reference"…). All of them mean: stop, start over.
- **Update the description** with violation symptoms — triggers for when you're *about* to break the rule.

*Beyond discipline skills: violation symptoms belong in the description as triggers (`discovery_guide.md`) — the skill should load when the failure tempts, not just when the task names it.*

## Verification log

Tally per round — rounds run, tokens spent, pass/fail — in the skill's PR or run notes. Verification costlier than expected lifetime use = overkill; drop a tier.
*Why: the cost check in the token budget needs data. Without the tally, "drop a tier" is a vibe.*

## Meta-testing

After the agent chooses wrong WITH the skill, ask how the skill could have made the right answer unmistakable:

1. "The skill was clear, I chose to ignore it" → not a docs problem. Strengthen the foundational principle.
2. "The skill should have said X" → docs problem. Add X verbatim.
3. "I didn't see section Y" → organization problem. Make key points prominent; principle goes early.

Bulletproof = correct choice under maximum pressure, agent cites the skill, meta-test returns "the skill was clear."
