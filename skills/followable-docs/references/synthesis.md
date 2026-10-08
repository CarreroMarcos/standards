# Synthesis: What Makes Superpowers Skills Followable — and How to Steal It

**Purpose:** Distill the writing techniques of the obra/superpowers skill library (v6.4.2, 14 skills analyzed across three forensic reports) into an actionable inventory for rewriting agent-facing standards docs (CODE-QUALITY.md / WORKFLOW.md / ENGINEERING_PRINCIPLES.md class). Direct input to the workspace skill for writing high-impact agent docs.

**Sources:**
- Report A — process skills: brainstorming, systematic-debugging, writing-plans, executing-plans, subagent-driven-development, dispatching-parallel-agents
- Report B — quality gates: test-driven-development, requesting/receiving-code-review, verification-before-completion, using-git-worktrees, finishing-a-development-branch
- Report C — meta: writing-skills, diagnosing-superpowers, upstream's stated philosophy + evaluation claims

**Evidence tiers used for ranking:**
- **Tier 1** — upstream cites actual evaluation data (wording A/B tests, the drill eval harness, cited persuasion research).
- **Tier 2** — observed consistently across all or nearly all 14 skills (counts, structural invariants).
- **Tier 3** — observed in a subset; strong, but situational.

---

## 1. Unified technique inventory

Each item is phrased as something a doc author can **do**. For each: what it is, the evidence, a corpus example, the anti-pattern it replaces.

### T1. Match the form to the failure — never default to "don't"

**Do:** Diagnose the baseline failure first, then pick the form. If the agent *skips or violates under pressure* (knows better, does it anyway) → prohibition + rationalization table + red flags. If the *output has the wrong shape* (bloated, buried verdict) → positive recipe/contract: state what the output IS — parts, in order. If the agent *omits a required element* → structural slot in a template. If behavior *depends on a condition* → conditional keyed to an observable predicate.

**Evidence (Tier 1):** "In head-to-head wording tests on dispatch-prompt guidance, the prohibition arm produced clearly more of the unwanted content than the recipe arm (fully separated distributions), and trended worse than even the no-guidance control — micro-test your own case rather than assuming, but never reach for the prohibition by default." (writing-skills, "Match the Form to the Failure")

**Corpus example:** To stop bloated dispatch prompts they don't write "don't paste history" — they write the recipe: what goes in the prompt, in what order. To stop skipping test-first, they use prohibition + rationalization table ("Thinking 'skip TDD just this once'? Stop. That's rationalization.").

**Anti-pattern it replaces:** The default advice-writing reflex of listing prohibitions ("don't be verbose", "avoid X") regardless of failure type.

### T2. No nuance clauses. No exemption clauses. Ever.

**Do:** Write the rule flat. Express every real exception as its own separate conditional on an observable predicate — never as "unless…", "generally…", or "this doesn't apply to…".

**Evidence (Tier 1):** "'No nuance clauses.' 'Don't X unless it matters' reopens the negotiation — appending a single nuance clause to a winning recipe degraded it from consistent to noisy in the same wording tests. Express a real exception as its own conditional on an observable predicate." And: "'Exemption clauses don't scope.' 'This limit doesn't apply to code blocks' still suppresses code blocks. If part of the output must be exempt, restructure so the rule can't reach it." (writing-skills)

**Corpus example:** diagnosing-superpowers: "Steps 5–7 run only on their stated condition" — conditions are separate, observable, and outside the rule sentence.

**Anti-pattern it replaces:** "Keep functions short, unless the logic genuinely requires length" / "This rule doesn't apply to generated code" (the carve-out that silently swallows the rule).

### T3. Quote the reader's rationalization verbatim, then rebut it in one sentence

**Do:** For every load-bearing rule, write down the exact sentence the agent will think when tempted to break it — in the agent's own voice, in quotes — and pair it with a one-sentence reality check. Format as an Excuse|Reality or Thought|Reality table, or a Red Flags list.

**Evidence (Tier 1 method, Tier 2 penetration):** The red-flags list "Make[s] it easy for agents to self-check when rationalizing" — it converts an unobservable internal state (rationalizing) into a **pattern-matchable string**. An agent can grep its own chain-of-thought against quoted strings. Library-wide: 10 of 15 skills carry rationalization tables, 8 carry Red Flags sections (15 = installed copy including the `using-superpowers` router; the analyzed corpus is otherwise described as 14 skills). The objections are harvested from real baseline tests (watch the agent fail without the guidance, log what it says).

**Corpus example:** "| 'Too tedious to test' | Testing is less tedious than debugging bad skill in production. |" (writing-skills). "Thinking 'skip TDD just this once'? Stop. That's rationalization." (test-driven-development)

**Anti-pattern it replaces:** Generic warnings ("don't cut corners") that the agent never recognizes as describing its own behavior.

### T4. Trigger sentences describe symptoms and temptations, never summarize content

**Do:** Write every "when to use" line as: who/what symptoms, quoted error strings or user complaints, and the temporal moment ("before proposing fixes"). Include the *temptation* state: "when tempted to test after, or when manually testing seems faster." Never summarize what the doc contains.

**Evidence (Tier 1):** The description trap, from testing: "Testing revealed that when a description summarizes the skill's workflow, an agent may follow the description instead of reading the full skill content. A description saying 'code review between tasks' caused an agent to do ONE review, even though the skill's flowchart clearly showed TWO reviews." Rule: "NEVER summarize the skill's process or workflow."

**Corpus example:** diagnosing-superpowers description: "Use when a superpowers session went wrong and your human partner wants to know why — repeated work, ignored plans, stumbles, poor results, a skill that didn't fire, 'it took too long', 'why is it so expensive', 'what is it doing'…" — literal quoted complaints as trigger phrases.

**Anti-pattern it replaces:** "This document covers our error-handling standards, including boundaries, retries, and logging." (a summary the agent will follow *instead of* the doc).

### T5. Open with the thesis, not the background

**Do:** First ~10 lines: H1 → one-paragraph framing → a single bolded core-principle line → when-to-use. The reader knows the whole document's point before any rule. Never open with definitions, motivation essays, or "this document describes…".

**Evidence (Tier 2):** All 14 skills follow this skeleton. TDD: "**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing." Worktrees: "**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness."

**Corpus example:** systematic-debugging: `# Systematic Debugging` → `## Overview` (`**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.`) → `## The Iron Law` → `## When to Use` → phases.

**Anti-pattern it replaces:** Opening with scope statements, history, or definitions the agent must wade through to find the point.

### T6. Write rules as bare second-person imperatives; ration MUST/NEVER; delete "should"

**Do:** Default mood is imperative, subjectless where it reads as law ("Run the check again before reporting"). Reserve MUST for genuine gates and NEVER for identity-level violations — their force comes from scarcity (5 MUSTs in 3,765 words of writing-skills). Never write "should" in a rule; "should" survives only inside quoted rationalizations you're about to kill. Keep hedge words (consider/might/generally/probably) at or near zero; where uncertainty is real, replace the hedge with a decision procedure.

**Evidence (Tier 2):** Measured across 12 files: 0–3 hedges per file; subagent-driven-development has **0**. "should" appears 6× in 3,765 words. Prohibition ladder observed: Iron Law > NEVER > Don't > (never "avoid" — "avoid"/"resist" appear 0×).

**Corpus example:** "Write code before the test? Delete it. Start over." (TDD). "Don't skim - read every line." (conversational `don't` for peer-tone corrections vs. mid-sentence absolute `never` for process violations: "Another plan's directory is never yours to read or write.")

**Anti-pattern it replaces:** "You should generally try to keep functions focused where possible." (every hedge word is an exit ramp).

### T7. Teach every rule as a bad-vs-good pair, realistic, adjacent to the rule

**Do:** Put the ❌/✅ pair directly under the rule it teaches — not in an appendix. The BAD example must show the specific failure the agent will actually produce, with a one-line caption. No foo/bar: real paths, real commands, real machine output (FAIL/PASS).

**Evidence (Tier 2):** TDD is ~40% example code; 21 code-block pairs in writing-skills alone. B: "several rules would be ambiguous without them (e.g., what counts as 'testing real behavior' is only defined by the Good/Bad pair under RED)."

**Corpus example:** dispatching-parallel-agents Common Mistakes: "**❌ Too broad:** 'Fix all the tests' — agent gets lost / **✅ Specific:** 'Fix agent-tool-abort.test.ts' — focused scope." TDD shows actual shell output: `$ npm test` → `FAIL: expected 'Email required', got undefined`.

**Anti-pattern it replaces:** Abstract rules with no example ("Write meaningful tests"), or toy examples that don't transfer.

### T8. WHY goes after the rule, one line, mechanistic or evidentiary

**Do:** Rule first. Then one line of why, tagged (`**Why critical:**`, `**Why bad:**`) or fused: mechanistic ("consuming 200k+ context") or evidentiary ("Testing revealed…", measured real-session failures with numbers). Never a paragraph of philosophy before the rule.

**Evidence (Tier 2, with Tier 1 flavor):** B and C agree: "The why almost never precedes the rule. It follows as a single line." A's per-rule cases match: "Do not paste accumulated prior-task summaries… — **a real session's dispatch hit 42k chars of which 99% was pasted history**." "A failure worth handling" rules cite observed sessions, not principles.

**Corpus example:** "**Why critical:** Prevents accidentally committing worktree contents to repository." (using-git-worktrees). "**WHY:** Items may be related. Partial understanding = wrong implementation." (receiving-code-review)

**Anti-pattern it replaces:** The upfront lecture ("Error handling is important because in distributed systems…") that the agent skims past before reaching the rule. (See §2 for the adjudicated exception: whole-strategy cost models.)

### T9. Bold is the rule-marker; plain text is explanation

**Do:** Make every rule a bolded lead label or bolded imperative line-start. An agent skimming only the bold text must get the complete argument skeleton. Code spans mark exact strings to reproduce; never use bold for emphasis inside explanations.

**Evidence (Tier 2):** 69 bold-imperative line-starts in writing-skills; the universal paragraph unit across all 14: `**Core principle:**`, `**Why inline:**`, `**Don't skip when:**`, `**Use this ESPECIALLY when:**`. "An agent skimming bold text alone gets the complete argument skeleton."

**Corpus example:** `**Rulings, not stalls.** … Record every decision in the ledger as \`Ruling: <what> — <why> — <what it costs if wrong>\`, and keep going.`

**Anti-pattern it replaces:** Bold used decoratively, or rules buried as plain sentences inside paragraphs.

### T10. Close with the reader's next action — never a summary

**Do:** End the document (or section) with a checklist, a gate, a red-flags table, or the law restated. The last line should constrain or direct what the reader does next. No "in conclusion", no recap.

**Evidence (Tier 2):** No skill ends with a summary. writing-skills ends with "Discovery Workflow" (the future agent's journey: "**Optimize for this flow**"). diagnosing-superpowers ends with the Red Flags table. TDD ends with "Final Rule" restating the Iron Law. Worktrees/finishing end on the Rationalizations table — "the last thing the agent reads is its excuses preemptively destroyed."

**Anti-pattern it replaces:** The recap paragraph, which teaches the agent that the ending is skippable.

### T11. Coin 2–4 terms per document and reuse them as enforcement handles

**Do:** Mint short names for your key concepts ("silent discard", "decision made in secret", "load-bearing", "parked") and then *cite them in other rules* as enforcement handles. A named violation ("a silent discard is forbidden") is enforceable in a way "don't forget" isn't.

**Evidence (Tier 2):** ~2–4 coined terms per file, consistently reused: "The Iron Law", "Rulings, not stalls", "the breaker", "RED→GREEN", "load-bearing".

**Corpus example:** "Deviating from the plan without a ledgered ruling is a decision made in secret." — the coined phrase does the prohibiting.

**Anti-pattern it replaces:** Re-describing the concept fresh each time ("failing to record a decision somewhere") so no shared vocabulary ever forms.

### T12. Replace judgment words with quantified tripwires and observable predicates

**Do:** Wherever you'd write "if it gets bad" / "when appropriate" / "use your best judgment", substitute a number or a checkable fact: "If ≥ 3 fixes failed: STOP and question the architecture", "Five rounds maximum per task, then the breaker trips", "R≤3 resume the implementer; R≥4 fresh implementer, stronger model".

**Evidence (Tier 2):** Quantified tripwires recur across skills; "Numbers, not vibes." Conditional rules are "keyed to an observable predicate" per the Tier 1 doctrine in T2.

**Corpus example:** systematic-debugging Phase 4: "**If ≥ 3: STOP and question the architecture (step 5 below)**" — the exception has its own numbered step with its own procedure.

**Anti-pattern it replaces:** "If you've tried several times without success, consider stepping back." (several? consider? — unenforceable).

### T13. Give exceptions their own named routes and name the authority

**Do:** Exceptions are first-class named paths with their own mini-procedures ("two routes leave the loop immediately:", "the breaker"), never footnotes or inline carve-outs. Name who may grant the exception ("Exceptions (ask your human partner)") — never "use your judgment".

**Evidence (Tier 2):** executing-plans: "**Four things stop you, and only these:** an irreversible or destructive operation; a security-sensitive action; a side effect outside this worktree; a plan so broken that every path forward is a guess." (Repeated verbatim in subagent-driven-development — deliberate cross-doc repetition.)

**Corpus example:** brainstorming's one-way ratchet: "hidden complexity discovered mid-task upgrades the path — stop, say so, and step up. **Nothing downgrades mid-task.**"

**Anti-pattern it replaces:** "…except in special circumstances" / "use your best judgment" (the agent is always the judge, and always acquits itself).

### T14. Replace judgment calls with ordered decision procedures

**Do:** Where generic advice says "use your best judgment", give an ordered procedure: re-grade steps, tiebreakers, a testable definition of done. "A step is done when the implementer can write **exactly one reasonable thing** from it. That is the whole requirement: unambiguous, not complete."

**Evidence (Tier 2):** executing-plans Final Review: "**Sort the findings before you act on any of them… Re-grade first, by effect**." Model selection as a 3-bullet complexity ladder plus the tiebreaker "Turn count beats token price."

**Corpus example:** receiving-code-review's response algorithm: 1. READ 2. UNDERSTAND 3. VERIFY 4. EVALUATE 5. RESPOND 6. IMPLEMENT.

**Anti-pattern it replaces:** "Review the findings carefully and prioritize appropriately."

### T15. Bless the anxious case explicitly: "X is fine."

**Do:** State permissions as flat grants for the thing a conscientious agent would hesitate over or ask about: "Read-only project exploration is allowed while those prerequisites remain incomplete." "A task that spans several commits is fine." "No need to re-review — just fix and move on."

**Evidence (Tier 2):** Observed across process skills. "The word 'fine' does real work — it explicitly blesses the thing an anxious agent would ask about."

**Corpus example:** "Fine. Throw away exploration, start with TDD." (test-driven-development)

**Anti-pattern it replaces:** Silence on the permitted case, which the agent reads as prohibition (or burns a question on).

### T16. Frame the human relationally and the violation as integrity, not sloppiness

**Do:** Call the human "your human partner" in rules (accountability framing: a partner is owed something). Frame non-compliance as dishonesty where it's load-bearing: "Skip any step = lying, not verifying." Agents optimize harder for not-lying than for not-being-sloppy.

**Evidence (Tier 2):** "your human partner" is the invariant relational term across all 14 (21× "user" in brainstorming refers to generic persons in examples; the relational term is always "human partner"). B §8b: "violating the rule is not 'suboptimal', it is **integrity fraud**."

**Corpus example:** "a red test you watched scroll past and didn't mention is a report falsified by omission." (TDD) / "proceeding past failures is your human partner's call."

**Anti-pattern it replaces:** "the user" (transactional framing) and "this would be suboptimal" (no sting).

### T17. Give the single non-negotiable an Iron Law block

**Do:** For the one rule the document exists to enforce, render it as an ALL-CAPS fenced block plus one brutal gloss line. Repeat it verbatim at the close.

**Evidence (Tier 3):** 3 of 6 quality-gate skills + writing-skills use it; the form is distinctive and the gloss lines are the most quoted sentences in the corpus.

**Corpus example:**
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```
"Write code before the test? Delete it. Start over."

**Anti-pattern it replaces:** Burying the load-bearing rule at the same visual weight as everything else.

### T18. Script exact words for handoffs, reports, and announcements

**Do:** Where the agent must communicate (handoff message, completion report, review reply), provide the verbatim script in a code block or blockquote — including what to say when stuck. Blockquotes are reserved for exact speech, never asides.

**Evidence (Tier 3):** writing-plans' handoff script; receiving-code-review's `"I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."`; announce-at-start lines making compliance observable.

**Corpus example:** "**'Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Please review the plan. Which execution approach would you prefer?'**"

**Anti-pattern it replaces:** "Communicate the plan status to the user." (every agent invents a different, worse version).

---

## 2. Reconciled disagreements

The three reports disagree on four points. Adjudications below, each with the evidence that settles it.

### D1. Why BEFORE the rule vs. why AFTER the rule — both, at different altitudes

- **Report A** claims "The WHY comes BEFORE the rule" (named `**Why inline:**` blocks above the procedure) *and* why fused to rules as measured failures.
- **Reports B and C** claim why comes *after* the rule, one line; B: "the justification arrives as a refutation of your excuse, not as an upfront lecture"; C lists "explaining the WHY at length before the rule" as an anti-pattern.

**Adjudication:** The disagreement dissolves once you separate two altitudes. **Strategic why** (the cost model for choosing a whole approach — "Inline execution pays for one context plus one reviewer; what it gives up is a fresh context per task") goes **before**, and only in docs where the reader chooses between strategies. **Per-rule why** (mechanistic or evidentiary, one line) goes **after**, always. Report A's "before" cases are all in the two execution skills, the only ones presenting a genuine strategic choice; B's six quality-gate skills have no such choice and go straight to thesis + rules. For a standards library: the file's opening thesis/principle line *is* the strategic why; every individual rule gets its one-line why after.

### D2. Examples interleaved vs. examples at the end — the corpus splits by doc type

- **Report A:** "Examples always come AFTER the full rule set, never interleaved as teaching" (citing the two closing `## Example Workflow` transcripts).
- **Report B:** "Examples sit adjacent to rules, never in an appendix" (TDD interleaves `<Good>`/`<Bad>` pairs under each phase; ~40% of the file).

**Adjudication:** Report A overclaimed from two data points. The actual pattern: **procedures close with worked transcripts** (showing session shape over time); **rule collections interleave bad/good pairs under each rule**. Report C's evidence breaks the tie: writing-skills alone has 21 interleaved example pairs, and the doc mandates "One excellent example beats many mediocre ones" as inline teaching. For a standards library (a rule collection, not a procedure): **interleave the pairs**. Transcripts are the wrong shape for reference docs.

### D3. Heavy prohibition use vs. "prohibitions backfire" — no conflict once failure-typed

- **Report A** documents a rich prohibition ladder (23 `never`s in one file, 9 uppercase DON'Ts in another) as standard practice.
- **Report C** quotes the eval finding that the prohibition arm "produced clearly more of the unwanted content than the recipe arm… and trended worse than even the no-guidance control."

**Adjudication:** Consistent. Every one of Report A's prohibitions targets a **discipline failure** (skipping reviews, dispatching conflicting agents, piling fixes) — exactly the failure type for which C's "Match the Form to the Failure" doctrine *prescribes* prohibitions. The eval result bans *defaulting* to prohibition for **shaping** problems (output form, verbosity, structure), where C shows all of A's shaping is done with positive recipes. Report A itself states the same boundary: "Pure prohibitions appear only where the agent's default impulse is the problem." The rule for doc authors: **never open with "don't" — first ask whether the failure is discipline or shape.**

### D4. "Never 'the user'" vs. 21× "user" in brainstorming — terminology, not contradiction

- **Report B:** "the human is never 'the user' — it is always 'your human partner'."
- **Report A:** notes "the user" appears 21× in brainstorming.

**Adjudication:** Report A already resolves it: those 21 occurrences refer to the person generically inside *examples*; the **relational term in rules is always "human partner"**. No substantive disagreement. Transferable lesson stands (T16).

---

## 3. Application map: rewriting standards rules with the techniques

For each technique, one concrete before→after on the kind of rule that lives in CODE-QUALITY.md / WORKFLOW.md / ENGINEERING_PRINCIPLES.md.

**T1 — Match the form to the failure.**
- Before: "Don't write overly long functions."
- After: "**One thing per function, one level of abstraction.** Roughly under 50 lines; the top function reads as an outline, details live one call down. **Why critical:** long functions mix abstraction levels, which makes the bug surface the entire function." *(Shaping problem → positive recipe with a number, not a prohibition.)*

**T2 — No nuance clauses.**
- Before: "Keep changes small and focused, unless the task genuinely requires touching more code."
- After: "**Every changed line traces to the request.** Don't improve adjacent code, don't refactor what isn't broken. A change that must touch more than the request gets its own task — that's a separate conditional, not an exception to this rule." *(The carve-out becomes its own rule.)*

**T3 — Quote the rationalization, rebut in one sentence.**
- Before: "Don't skip writing tests for 'simple' changes."
- After: "| Thought | Reality |\n| 'Too small to need a test' | Size doesn't predict breakage; the test is the only proof the change does what you claim. |\n| 'I'll add tests after' | After never comes. Write the failing test first or don't claim the change works. |"

**T4 — Triggers are symptoms, not summaries.**
- Before (consult_when): "When writing or refactoring code and you want the per-task quality rules."
- After (consult_when): "Use when about to write or change code and tempted to skip the small stuff — 'it's just a quick fix', 'the diff is obvious', 'tests would take longer than the change' — or when a review came back with nits you want to preempt." *(Fires on temptation, in the agent's own words.)*

**T5 — Thesis first.**
- Before: "# Code Quality\n\nThis document defines the code quality standards for AI-generated code, covering comments, dead code, testing, and verification. It is intended to be consulted…"
- After: "# Code Quality\n\n**Core principle:** Code a stranger — human or agent — can read and safely change. Refactorability is the bar; the rules below are how you reach it." *(Whole point absorbed in two sentences.)*

**T6 — Imperatives, rationed authority, no "should".**
- Before: "You should generally verify your changes by running the relevant tests where possible."
- After: "**Run the checks again before reporting** — a prior green run does not cover new changes. When a check cannot run, report it: 'I couldn't verify X because Y.'" *(Zero hedges; the uncovered case gets its own instruction.)*

**T7 — Bad/good pairs adjacent to the rule.**
- Before: "Handle errors explicitly and don't swallow exceptions silently."
- After: rule + pair:
```python
# ❌ BAD - Silent swallow
try:
    result = api_call()
except:
    pass

# ✅ GOOD - Explicit decision per failure path
try:
    result = api_call()
except ConnectionError as e:
    logger.warning("API unavailable, using cached data", error=str(e))
    result = get_cached_result()
```
*(The BAD shows the exact sin the agent commits; the caption names it.)*

**T8 — One-line why after the rule.**
- Before: "Comprehensive error handling matters because in production systems unhandled exceptions can cascade into outages, corrupt state, and pages at 3am. Therefore, you should…"
- After: "**Swallow nothing silently.** Give every failure path an explicit decision: log, recover, or raise. **Why critical:** a swallowed exception is a lie in the logs — the next reader debugs a symptom three layers away." *(Rule first, mechanism second, one line.)*

**T9 — Bold as the rule-marker.**
- Before: "It's a good idea to prefer editing existing files over creating new ones, since creating files unasked tends to clutter the repo and duplicate existing utilities…"
- After: "**Prefer editing over creating files.** Don't create empty placeholder files. **Search before creating** so you don't produce duplicates." *(Skimming the bold yields the whole rule.)*

**T10 — Close with the next action.**
- Before (end of section): "In summary, the key takeaways are: keep changes small, verify your work, and document decisions."
- After (end of section): "**Before you commit:** every changed line traces to the request; checks re-run on the final diff; each assumption stated once. Can't check all three? You skipped the workflow. Go back." *(Checklist with a failure clause, not a recap.)*

**T11 — Coined terms as enforcement handles.**
- Before: "Don't re-argue a finding that was already discussed and decided."
- After: "**The freeze rule:** a dispositioned finding that recurs is not re-litigated — cite the original disposition and move on. Reopening it is itself a decision, and needs a new framed question." *(The name becomes citable in review threads.)*

**T12 — Quantified tripwires.**
- Before: "If debugging is taking too long without progress, step back and reconsider the approach."
- After: "**If ≥ 3 fix attempts failed: STOP and question the architecture.** Write the failing test that reproduces it, then follow the debug procedure — no Fix #4 on the same theory." *(Number, stop word, prescribed next step.)*

**T13 — Named exception routes + named authority.**
- Before: "Follow the workflow phases, unless the change is trivial enough to skip steps."
- After: "**Skip when:** single-file fix, typo, config value change, renaming, or the change is obvious and < 20 lines. Anything else runs the full workflow — **your human partner** approves skipped phases, not you." *(Bounded list + who decides.)*

**T14 — Decision procedure over judgment.**
- Before: "Prioritize review findings appropriately before acting on them."
- After: "**Sort the findings before you act on any of them.** Re-grade first, by effect: what does a reasonable person get if this ships — not whether the spec names the input that triggers it. Fix in severity order; ledger anything you defer." *(Ordered steps with a re-grading rule.)*

**T15 — Bless the anxious case.**
- Before: *(silence — the agent asks whether it may proceed)*
- After: "**Flagging suspected dead code is always safe;** deleting it needs proof or explicit human confirmation. When in doubt, flag — flagging is never wrong." *("Fine" doing its work: the hesitant action is explicitly blessed.)*

**T16 — Relational framing + integrity stakes.**
- Before: "Make sure your completion report is accurate for the user."
- After: "**Never claim 'done' without evidence.** Every completion report carries executed results — tests, lint, build. A green suite you didn't run is a report falsified by omission, and your human partner is the one who pays for it." *(Partner framing; violation = dishonesty.)*

**T17 — Iron Law block for the load-bearing rule.**
- Before: "It's important to always run verification before declaring work complete."
- After:
```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```
"If you haven't run the verification command in this session, you cannot claim it passes." *(Rendered immutable; restated verbatim at the close.)*

**T18 — Scripted exact words.**
- Before: "Ask the user to review the plan before implementing."
- After: "> 'Plan complete and saved to `docs/plans/<date>-<slug>.md`. Does the plan capture what you want, and should I proceed to implementation?'" *(Blockquote = exact speech; the agent doesn't invent a worse version.)*

---

## 4. What NOT to copy

Techniques that are specific to skills-as-executable-workflows and do not transfer to a standards/rules library. Copying these would add ceremony without leverage.

1. **Announce-at-start speech acts** ("I'm using the X skill…"). This makes *invoking a procedure* observable in the transcript. A standards doc is consulted mid-task, not invoked; announcing "I'm consulting CODE-QUALITY.md" is noise. The transferable residue is already covered: make *decisions* observable (T11 coined terms cited in review threads), not the consultation itself.

2. **Phase gates with hard sequencing** ("You MUST complete Phase 1 before Phase 2"). Workflows execute; rule libraries are consulted non-linearly. Imposing execution order on reference docs fights how they're actually used (an agent jumps to §3 on an error-handling question). Exception: WORKFLOW.md genuinely *is* a procedure — phase gates belong there, and only there.

3. **Ledger formats and exact artifact schemas** (`` `Ruling: <what> — <why> — <cost if wrong>` ``). These enforce a specific execution loop's bookkeeping. A standards library shouldn't mandate one loop's schema — but the *principle* transfers narrowly: where a standard requires an artifact (completion report, decision log), template its exact fields (T18).

4. **Todo-per-checklist-item** ("Create a todo for EACH checklist item"). An execution-harness trick so a long procedure survives context compaction. For a reference doc, the checklist itself is the artifact; mandating todo-creation on every consultation would be pure overhead.

5. **REQUIRED SUB-SKILL callouts** ("load superpowers:tdd now"). Skill-graph dependency injection. The standards analog already exists and is better: cross-file `→ FILE.md §N` pointers at the point of use. Don't invent a load-order mechanism on top of it.

6. **STOP gates between sections** ("## STOP: Before Moving to Next Skill"). Gates separate *execution stages*. In a reference doc they'd just be speed bumps between sections the reader may legitimately read in any order.

7. **Full worked transcripts as closings.** Transcripts show the shape of a *correct session over time* — the right closer for a procedure. For a rule library, the right closers are the checklist, the restated law, or the killed excuse (T10).

8. **Flowcharts for everything.** Upstream is explicit: flowcharts are for non-obvious *decisions* only ("Use ONLY for: … Never for: …"). A rule with a linear statement doesn't need a diamond. In standards docs, reserve diagrams for genuine branching (e.g., the exception-routing in T13).

9. **Third-person frontmatter doctrine** ("Write in third person — injected into system prompt"). That's about skill-router injection mechanics. Standards files aren't injected as skill descriptions; their `consult_when` is a retrieval trigger with different machinery. The transferable part is T4 (triggers = symptoms, never summaries), not the person rule.

10. **The description-trap prohibition applied naively.** "NEVER summarize the workflow" is about *router descriptions*. A standards file's opening still needs its one-line thesis (T5) — the trap is specifically about the *trigger sentence* doubling as a content summary that lets the agent skip reading. Keep the thesis; keep the trigger symptom-only; don't confuse the two jobs.

---

## 5. Open questions — where the evidence is thin

Upstream's own advice is "micro-test your own case rather than assuming." These are the cases we'd need to micro-test before treating the techniques as settled for *standards docs* (their evals were on skill wording, dispatch prompts, and descriptions — not on rule-library prose):

1. **Does the prohibition-backfire result generalize to rule libraries?** The head-to-head test was on *dispatch-prompt guidance* (shaping an output). A standards corpus is mostly discipline-type content ("don't swallow exceptions") where prohibitions are already the prescribed form. The risky transfer is the reverse: are there shaping-type standards rules currently written as prohibitions that would do better as recipes? Candidate micro-test: rewrite 5 shaping rules as recipes, 5 as prohibitions, measure compliance in a fixed task battery.

2. **Why-after vs. why-before for reference docs.** Their wording tests didn't isolate why-placement. The corpus pattern (strategic why before, per-rule why after) is observational. Micro-test: same rule, why-before vs. why-after vs. excuse-table-only; measure whether the agent can *reproduce the rationale* when challenged.

3. **Bad/good pairs vs. excuse/reality tables — which carries more weight per token?** Both are Tier 2 observational. For a token-budgeted standards file, we need the exchange rate: does one excuse-table row buy more compliance than one bad/good pair? Unknown; test with the no-guidance control they insist on.

4. **Optimal density / file length.** Their word-count discipline (<150 / <200 / <500 words by load frequency) is a *policy*, not an eval result — and writing-skills itself is 3,765 words. At what file size does a consulted-per-task standards doc stop being read? Nobody measured it. Micro-test: same rule set at 3 densities, measure citation/usage in downstream tasks.

5. **Does "human partner" framing change anything in a rules doc?** Purely observational; no A/B. It may matter less in reference prose (read once, consulted often) than in execution skills. Cheap to test, low prior either way.

6. **Quantified tripwire calibration.** "≥3 failures → stop" and "5 rounds → adjudicate" are specific numbers from specific workflows. Do agents respect *any* number, or do the numbers need to be credible per domain? Untested: "2 rounds then escalate" vs. "5 rounds" in a standards context.

7. **The persuasion-research transfer.** Meincke et al. (2025) measured *human* compliance in AI conversations (33% → 72%) — upstream applies Cialdini-style authority language to *agents* on the theory that "LLMs are parahuman: trained on human text containing these patterns." That transfer assumption is untested. The authority voice may work via a different mechanism (training-data prior on imperative instructional text) — worth knowing because it changes which markers to ration.

8. **Variance as a metric for doc edits.** "Single samples lie. Variance is a metric." Their protocol demands 5+ reps per wording arm plus a no-guidance control, with manual review of every flagged match. Any internal micro-test that skips the control arm or runs n=1 is theater — this is the methodological bar to clear before claiming a rewrite "worked."

9. **Interaction effects.** All their claims are about single techniques. Real rewrites stack 5+ techniques per rule (imperative + pair + why + tripwire). Do they compose linearly, or do some cancel (e.g., does an Iron Law block plus an excuse table create reactance)? Untested.

10. **The "reading ≠ using" gap for standards specifically.** Their whole methodology exists because "documentation that was merely read and approved still fails." A standards library is *only ever read* — never executed as a procedure. Whether rule-library compliance can ever reach procedure-level compliance, or whether the ceiling is structurally lower, is the foundational unknown this whole project should test first.
