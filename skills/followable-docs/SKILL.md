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

Rewrite triggers per T4 (`references/techniques.md`) — symptoms, temptations, error strings; never a content summary. Upstream measured the failure directly: a summarizing description gets followed *instead of* the doc.

### 3. Rewrite rule by rule

Apply `references/techniques.md` as the checklist, in this order: T5 thesis first · T9 bold rule-markers · T6 imperatives, MUST/NEVER rationed, no "should" · T2 no nuance clauses · T7 bad/good pair per load-bearing rule · T8 one-line why after the rule · T3 rationalization tables · T12 quantified tripwires · T13 named exception routes and authority · T10 close with the next action. `references/appendix.md` carries a worked before→after per technique plus adjudicated edge cases.

### 4. Verify the rewrite

- **Bold-skeleton test:** read only the bold text. If the argument doesn't survive, the markers are wrong.
- **Hedge grep** (on the target doc): two passes. (1) Extract the rule sentences — bolded leads and imperative line-starts, skipping fenced code blocks. (2) Run `rg -i '\b(should|generally|consider|try to|where possible|unless)\b'` on those lines only; every hit is a bug. Quoted rationalizations and examples never survive pass (1), so there's nothing left to triage.
- **Trigger test:** does the description name a symptom or temptation? If it summarizes contents, rewrite it.
- **Close test:** the last line directs action. If it recaps, replace it.
- **Section-number check:** no renumbering of the target doc — its existing §N cross-references must stay valid. Skip when the target doc has no numbered sections.

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
