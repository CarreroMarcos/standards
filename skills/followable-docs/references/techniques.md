# The 18 Techniques

Distilled from a forensic analysis of a production agent-skills library (14 skills).

**Evidence tiers:** Tier 1 = controlled wording A/B tests (the library authors' self-reported evals — not independently replicated). Tier 2 = observed across the whole corpus. Tier 3 = strong but situational. Technique counts are analyst measurements — re-grep before citing as fact. Full honesty notes at the end of this file.

**Ordering coupling:** `SKILL.md` §3 applies these techniques in a fixed sequence (T5 → T9 → T6 → T2 → T7 → T8 → T3 → T12 → T13 → T10). If you renumber or reorder techniques here, update that list in the same change.

---

### T1. Match the form to the failure — never default to "don't" (Tier 1)

**Do:** Diagnose first. Discipline failure (knows better, skips under pressure) → prohibition + rationalization table + red flags. Shape failure (wrong output form) → positive recipe: what the output IS, parts in order. Omission → template slot. Conditional → its own rule on an observable predicate.

**Evidence:** Head-to-head wording tests: the prohibition arm produced *more* of the unwanted content than the recipe arm on shaping problems — worse than the no-guidance control.

**Example:** Bloated prompts fixed with a recipe (what goes in, in what order), not "don't paste history." Skipped test-first fixed with prohibition + table ("Thinking 'skip the test just this once'? Stop. That's rationalization.").

**Replaces:** Listing prohibitions regardless of failure type.

### T2. No nuance clauses. No exemption clauses. Ever. (Tier 1)

**Do:** Write the rule flat. Every real exception becomes its own conditional on an observable predicate — never "unless…", "generally…", "this doesn't apply to…".

**Evidence:** Appending one nuance clause to a winning recipe degraded it from consistent to noisy (Tier 1). "Exemption clauses don't scope" is a single observed case rather than a controlled test: "this limit doesn't apply to code blocks" still suppressed code blocks — treat as Tier 2.

**Example:** "Steps 5–7 run only on their stated condition" — conditions separate, observable, outside the rule sentence.

**Replaces:** "Keep functions short, unless the logic genuinely requires length."

### T3. Quote the reader's rationalization verbatim, then rebut in one sentence (Tier 1 method, Tier 2 penetration)

**Do:** For every load-bearing rule, write the exact sentence the agent thinks when tempted to break it — in quotes, in its own voice — plus a one-sentence reality check. Excuse|Reality tables or Red Flags lists. Harvest objections from watching agents fail without the guidance.

**Evidence:** Converts unobservable rationalizing into pattern-matchable text the agent can grep its own chain-of-thought against. 10 of 15 skills carry rationalization tables, 8 carry Red Flags sections (15 = installed copy including the router skill; analyzed corpus = 14 skills).

**Example:** | 'Too tedious to test' | Testing is less tedious than debugging bad skill in production. |

**Replaces:** Generic warnings ("don't cut corners") the agent never recognizes as describing itself.

### T4. Trigger sentences describe symptoms and temptations, never summarize content (Tier 1)

**Do:** "When to use" = symptoms, quoted error strings / user complaints, the temporal moment ("before proposing fixes"), plus the temptation state ("when tempted to test after"). Never summarize the doc's contents.

**Evidence:** The description trap: a description saying "code review between tasks" caused an agent to do ONE review though the flowchart showed TWO. "NEVER summarize the skill's process or workflow."

**Example:** "Use when a session went wrong and your human partner wants to know why — repeated work, ignored plans, 'it took too long', 'why is it so expensive'…"

**Replaces:** "This document covers our error-handling standards…" (followed *instead of* the doc).

### T5. Open with the thesis, not the background (Tier 2)

**Do:** First ~10 lines: H1 → one-paragraph framing → one bolded core-principle line → when-to-use. Never definitions, motivation essays, or "this document describes…".

**Example:** "**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing."

**Replaces:** Scope statements and history the reader wades through to find the point.

### T6. Bare second-person imperatives; ration MUST/NEVER; delete "should" (Tier 2)

**Do:** Default mood imperative, subjectless where it reads as law. MUST only for genuine gates, NEVER only for identity-level violations — force comes from scarcity (3 MUSTs in 3,765 words at time of writing). Never "should" in a rule; it survives only inside quoted rationalizations you're about to kill. Hedges at ~zero; replace uncertainty with a decision procedure.

**Evidence:** 0–3 hedges per file measured across 12 files. Ladder: Iron Law > NEVER > don't > (never "avoid" — 0×).

**Example:** "Write code before the test? Delete it. Start over." vs. conversational "Don't skim — read every line."

**Replaces:** "You should generally try to keep functions focused where possible." (every hedge is an exit ramp).

### T7. Bad-vs-good pairs adjacent to each rule, realistic, never toy (Tier 2)

**Do:** ❌/✅ pair directly under the rule — not in an appendix. BAD shows the specific failure the agent will actually produce, with a one-line caption. Real paths, real commands, real machine output.

**Evidence:** example-heavy skills run ~40% example code; 21 pairs in a single skill file. Several rules are ambiguous without their pair.

**Example:** `**❌ Too broad:** 'Fix all the tests' — agent gets lost` / `**✅ Specific:** 'Fix agent-tool-abort.test.ts' — focused scope.`

**Replaces:** Abstract rules with no example, or foo/bar toys.

### T8. WHY after the rule, one line, mechanistic or evidentiary (Tier 2)

**Do:** Rule first, then one tagged line (`**Why critical:**`, `**Why bad:**`) — mechanistic ("consuming 200k+ context") or evidentiary (measured real-session failures with numbers). Never a philosophy paragraph before the rule. Exception: whole-strategy cost models go before, and only where the reader chooses between strategies.

**Example:** "**Why critical:** Prevents accidentally committing worktree contents to repository."

**Replaces:** The upfront lecture the reader skims past before reaching the rule.

### T9. Bold is the rule-marker; plain text is explanation (Tier 2)

**Do:** Every rule a bolded lead label or bolded imperative line-start. Skimming bold alone must yield the complete argument skeleton. Code spans = exact strings to reproduce. Never bold for decoration.

**Evidence:** 69 bold-imperative line-starts in one skill file; the universal paragraph unit (`**Core principle:**`, `**Don't skip when:**`).

**Replaces:** Rules buried as plain sentences; decorative bold.

### T10. Close with the reader's next action — never a summary (Tier 2)

**Do:** End with a checklist, gate, red-flags table, or the law restated. The last line constrains or directs what the reader does next. "The last thing the agent reads is its excuses preemptively destroyed."

**Example:** one skill ends restating its Iron Law; another ends on its Red Flags table.

**Replaces:** The recap paragraph, which teaches the reader the ending is skippable.

### T11. Coin 2–4 terms per document as enforcement handles (Tier 2)

**Do:** Mint short names ("silent discard", "decision made in secret", "load-bearing", "parked") and cite them in other rules. A named violation is enforceable; "don't forget" isn't.

**Example:** "Deviating from the plan without a ledgered ruling is a decision made in secret." — the coined phrase does the prohibiting.

**Replaces:** Re-describing the concept fresh each time so no shared vocabulary forms.

### T12. Quantified tripwires and observable predicates over judgment words (Tier 2)

**Do:** Replace "if it gets bad" / "when appropriate" with numbers or checkable facts: "If ≥ 3 fixes failed: STOP and question the architecture." "Numbers, not vibes."

**Example:** "**If ≥ 3: STOP and question the architecture (step 5 below)**" — the exception gets its own numbered step with its own procedure.

**Replaces:** "If you've tried several times, consider stepping back." (unenforceable).

### T13. Exceptions as named routes; name the authority (Tier 2)

**Do:** First-class named paths with mini-procedures ("two routes leave the loop immediately:", "the breaker"), never footnotes. Name who grants the exception ("Exceptions (ask your human partner)") — never "use your judgment".

**Example:** "**Four things stop you, and only these:** an irreversible operation; a security-sensitive action; a side effect outside this worktree; a plan so broken every path forward is a guess."

**Replaces:** "…except in special circumstances" (the agent always acquits itself).

### T14. Ordered decision procedures instead of judgment calls (Tier 2)

**Do:** Replace "use your best judgment" with ordered steps, re-grading rules, tiebreakers, testable definitions of done.

**Example:** "A step is done when the implementer can write **exactly one reasonable thing** from it. That is the whole requirement: unambiguous, not complete."

**Replaces:** "Review the findings carefully and prioritize appropriately."

### T15. Bless the anxious case: "X is fine." (Tier 2)

**Do:** Flat grants for what a conscientious reader would hesitate over: "Read-only exploration is allowed while prerequisites remain incomplete." "A task spanning several commits is fine."

**Replaces:** Silence the reader reads as prohibition (or burns a question on).

### T16. Relational framing + integrity stakes (Tier 2)

**Do:** "Your human partner" in rules — a partner is owed something. Frame load-bearing non-compliance as dishonesty: "Skip any step = lying, not verifying." Agents optimize harder for not-lying than not-being-sloppy.

**Example:** "A red test you watched scroll past and didn't mention is a report falsified by omission."

**Replaces:** "The user" (transactional) and "this would be suboptimal" (no sting).

### T17. Iron Law block for the single non-negotiable (Tier 3)

**Do:** ALL-CAPS fenced block + one brutal gloss, restated verbatim at the close. For the ONE rule the document exists to enforce.

**Example:** `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST` / "Write code before the test? Delete it. Start over."

**Replaces:** Burying the load-bearing rule at the same visual weight as everything else.

### T18. Script exact words for handoffs and reports (Tier 3)

**Do:** Verbatim scripts in code blocks/blockquotes for anything the reader must say. Blockquotes reserved for exact speech, never asides.

**Example:** `"I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."`

**Replaces:** "Communicate the plan status to the user." (every agent invents a worse version).

---

## Do NOT transfer to rule docs

Workflow machinery that doesn't belong in a rules library: announce-at-start speech acts; hard phase sequencing between reference sections (WORKFLOW.md excepted — it genuinely is a procedure); ledger/artifact schemas for a specific execution loop; todo-per-checklist-item; REQUIRED SUB-SKILL callouts (the `→ FILE.md §N` pointer convention already covers this); STOP gates between sections; full worked transcripts as closers; flowcharts for non-decisions; third-person frontmatter doctrine (router-injection mechanics); and a naive "never summarize" — the *trigger sentence* stays symptom-only, but the file still needs its one-line thesis.

## Honesty notes

- Tier 1 claims are the library authors' self-reported eval results (harness not independently replicated). Strong priors, not settled science.
- Technique counts ("69 bold-imperative line-starts") are analyst measurements over the analyzed copy; re-grep before citing as fact.
- Open questions needing our own micro-tests (per the authors' "micro-test your own case"): prohibition-backfire generalization to rule libraries, why-placement isolation, bad/good vs. excuse-table exchange rate, optimal doc density, "human partner" A/B, tripwire calibration, persuasion-research transfer to agents, interaction effects of stacked techniques, and the foundational "reading ≠ using" gap for read-only standards.
