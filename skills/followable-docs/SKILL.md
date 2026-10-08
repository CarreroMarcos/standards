---
name: followable-docs
description: "Use when writing or revising agent-facing docs — standards files, skills, rules docs, AGENTS.md — and agents keep ignoring them: rules get skimmed, hedged with 'should', or rationalized away mid-task. Rewrites the doc so its rules get followed under pressure, not just when freshly read."
---

# Followable Docs

**Core principle:** Agents follow instructions engineered to survive contact with their own rationalizations. Write every rule like the reader is already looking for the exit.

## Purpose

Rewrite or author agent-facing docs (standards files, skills, rules docs) so agents follow them under pressure — not just when freshly read. The 18 techniques in `references/techniques.md` are distilled from a forensic analysis of a production agent-skills library, ranked by evidence: Tier 1 = controlled wording A/B tests, Tier 2 = observed across the whole corpus, Tier 3 = strong but situational. **The tiers describe sourcing, not validation** — they rank how the techniques were evidenced in that corpus, and are not measurements from this repo. See the honesty notes in `references/techniques.md` before citing any count or tier claim.

## Workflow

### 1. Diagnose the doc's failure mode

Read the target doc end to end. For each rule that isn't working, name the failure type before touching the wording:

- **Discipline failure** (agent knows better, skips under pressure) → prohibition + rationalization table + red flags.
- **Shape failure** (output has the wrong form) → positive recipe: what the output IS, parts in order. Never open with "don't".
- **Omission failure** (agent drops a required element) → structural slot in a template.
- **Conditional behavior** → conditional keyed to an observable predicate, as its own rule — never an inline "unless".

**Never default to "don't".** Upstream's head-to-head tests: on shaping problems the prohibition arm produced *more* of the unwanted content than the recipe arm — worse than no guidance at all. **Reach for "don't" only on discipline failures** — where the reader knows the rule and will skip it under pressure. Shape, omission, and conditional failures get the positive recipe first.

### 2. Fix the triggers first

Rewrite every `consult_when` / description line as symptoms and temptations, never a content summary. Name the moment ("about to write code and tempted to skip tests"), quote the agent's own excuse phrases ("'it's just a quick fix'"), include error strings. A description that summarizes the doc teaches the agent to follow the summary *instead of* the doc — upstream measured this failure directly.

### 3. Rewrite rule by rule

Apply `references/techniques.md` as the checklist. The load-bearing moves, in order:

1. **Thesis first.** H1 → one-paragraph framing → one bolded core-principle line. No background essays.
2. **Bold is the rule-marker.** Every rule a bolded lead; skimming bold alone yields the full argument.
3. **Imperatives; ration MUST/NEVER; delete "should".** Hedges are exit ramps. Real uncertainty becomes a decision procedure, not "consider".
4. **No nuance clauses.** "Keep X short, unless…" → flat rule + the real exception as its own conditional on an observable predicate.
5. **Bad/good pair under every load-bearing rule.** ❌ shows the exact sin the agent commits, captioned; ✅ shows the fix. Real paths, real commands, real output — no foo/bar.
6. **One-line why after the rule.** Mechanistic or evidentiary ("a real session's dispatch hit 42k chars of which 99% was pasted history"). Never a lecture before the rule.
7. **Rationalization table for every rule agents break under pressure.** Quote the thought verbatim ("'Too small to need a test'"), rebut in one sentence. This turns unobservable rationalizing into pattern-matchable text.
8. **Quantified tripwires.** "If ≥ 3 fix attempts failed: STOP…" — numbers, not vibes.
9. **Named exception routes, named authority.** "Four things stop you, and only these" + who grants the exception. Never "use your judgment".
10. **Close with the next action.** Checklist with a failure clause, restated law, or killed excuses. Never a summary.

### 4. Verify the rewrite

- **Bold-skeleton test:** read only the bold text. If the argument doesn't survive, the markers are wrong.
- **Hedge grep:** a rule sentence is any bolded lead, imperative line, or template slot outside quotes and code blocks — hedges are permitted only inside quoted rationalizations and examples. Verify with `rg -i '\b(should|generally|consider|try to|where possible|unless)\b'`; every hit outside quotes and examples is a bug.
- **Trigger test:** does the description name a symptom or temptation? If it summarizes contents, rewrite it.
- **Close test:** the last line directs action. If it recaps, replace it.
- **Section-number check:** no renumbering of the target doc — its existing §N cross-references must stay valid.

## Output Contract

- The revised doc, edited in place (or the new doc, written to its home path — never a copy that drifts).
- A short report: per section, which techniques were applied and why (technique ID per change, e.g. "T6: hedges removed"). No silent judgment calls on contested ground.

## Operating Rules

- **The doc's voice wins.** Every rule keeps the target doc's existing voice — techniques change the *form*, never the *voice*.
- **One topic per file, single source of truth per file.** New content goes in the file whose scope already covers it; never create a near-duplicate file.
- **Don't invent evidence.** Techniques carry their Tier 1/2/3 marking in the reference. Tier 1 claims are the library authors' self-reported evals (harness not independently replicated) — say so if asked, don't oversell.
- **Don't copy workflow machinery into rule docs.** No announce-at-start lines, no phase gates between reference sections, no todo-per-item, no worked transcripts as closers — the full do-not-transfer list is in `references/techniques.md`. Exception: WORKFLOW.md genuinely is a procedure; gates belong there.
- **Verify, don't claim.** Technique counts and eval quotes in the reference come from analyst reports over the analyzed copy; re-grep the corpus before citing a number as fact.
- **Carve-out: keep warranted caution.** These techniques make rules harder to rationalize away — they don't remove caution where it's load-bearing. Never rewrite an explicit safety hedge on security, data-handling, or irreversible actions into a bare imperative.
