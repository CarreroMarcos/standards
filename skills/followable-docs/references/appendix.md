# Appendix: Applying the Techniques

Worked before→after examples for each technique, adjudicated edge cases where the evidence seemed to conflict, and the machinery that does **not** transfer to rule docs. Companion to `techniques.md` — read the checklist first; come here when a technique's application is ambiguous.

## Reconciled disagreements

Three cases where the underlying analysis appeared to contradict itself. Each adjudication is load-bearing: applying the technique wrong here is worse than not applying it.

### Why before the rule vs. why after — both, at different altitudes

Separate two altitudes. **Strategic why** — the cost model for choosing a whole approach ("inline execution costs one context plus one reviewer; what it gives up is a fresh context per task") — goes **before**, and only in docs where the reader genuinely chooses between strategies. **Per-rule why** — mechanistic or evidentiary, one line — goes **after**, always. The observed "why before" cases all came from docs presenting a real strategic choice; docs with no such choice go straight to thesis + rules.

For a standards doc: the file's opening thesis or core-principle line *is* the strategic why. Every individual rule gets its one-line why after. Never a philosophy paragraph before a rule.

### Examples interleaved vs. examples at the end — the corpus splits by doc type

**Procedures** close with worked transcripts (showing the shape of a correct session over time). **Rule collections** interleave bad/good pairs under each rule (21 interleaved pairs in a single file of the analyzed library; the pairs are what disambiguate the rules). For a standards doc — a rule collection, not a procedure — **interleave the pairs**. A closing transcript is the wrong shape for reference prose.

### Heavy prohibition use vs. "prohibitions backfire" — no conflict once failure-typed

The wording tests show the prohibition arm producing *more* of the unwanted content than the recipe arm on shaping problems — worse than no guidance. Separately, the analyzed library uses prohibitions heavily (dozens per file). Both true: every observed prohibition targets a **discipline failure** (skipping reviews, dispatching conflicting agents, piling fixes) — exactly the failure type the doctrine prescribes prohibitions for. The eval bans *defaulting* to prohibition for **shaping** problems (output form, verbosity, structure), where all shaping is done with positive recipes.

The rule for doc authors: **never open with "don't" — first ask whether the failure is discipline or shape.** Discipline → prohibition + rationalization table + red flags. Shape → positive recipe.

## Application map

One concrete before→after per technique, on the kind of rule that lives in a standards doc.

**T1 — Match the form to the failure.**
- Before: "Don't write overly long functions."
- After: "**One thing per function, one level of abstraction.** Roughly under 50 lines; the top function reads as an outline, details live one call down. **Why critical:** long functions mix abstraction levels, which makes the bug surface the entire function." *(Shaping problem → positive recipe with a number, not a prohibition.)*

**T2 — No nuance clauses.**
- Before: "Keep changes small and focused, unless the task genuinely requires touching more code."
- After: "**Every changed line traces to the request.** Don't improve adjacent code, don't refactor what isn't broken. A change that must touch more than the request gets its own task — that's a separate conditional, not an exception to this rule." *(The carve-out becomes its own rule.)*

**T3 — Quote the rationalization, rebut in one sentence.**
- Before: "Don't skip writing tests for 'simple' changes."
- After: "| Thought | Reality |
| 'Too small to need a test' | Size doesn't predict breakage; the test is the only proof the change does what you claim. |
| 'I'll add tests after' | After never comes. Write the failing test first or don't claim the change works. |"

**T4 — Triggers are symptoms, not summaries.**
- Before (trigger): "When writing or refactoring code and you want the per-task quality rules."
- After (trigger): "Use when about to write or change code and tempted to skip the small stuff — 'it's just a quick fix', 'the diff is obvious', 'tests would take longer than the change' — or when a review came back with nits you want to preempt." *(Fires on temptation, in the agent's own words.)*

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

## What NOT to copy

Machinery from the analyzed library that is specific to skills-as-executable-workflows and does not transfer to a standards or rules doc. Each with why, so borderline cases get judged correctly.

1. **Announce-at-start speech acts.** Makes *invoking a procedure* observable in the transcript. A standards doc is consulted mid-task, not invoked — announcing the consultation is noise. The transferable residue: make *decisions* observable (T11 coined terms cited in review threads), not the consultation itself.
2. **Phase gates with hard sequencing.** Workflows execute; rule libraries are consulted non-linearly — an agent jumps to the error-handling section on an error-handling question. Imposed order fights actual use. Exception: a doc that genuinely *is* a procedure keeps its gates.
3. **Ledger formats and exact artifact schemas.** Enforce one execution loop's bookkeeping. A standards library shouldn't mandate a single loop's schema — but the principle transfers narrowly: where a standard requires an artifact (completion report, decision log), template its exact fields (T18).
4. **Todo-per-checklist-item.** An execution-harness trick so a long procedure survives context compaction. For a reference doc the checklist itself is the artifact; mandating todo-creation per consultation is pure overhead.
5. **Skill-graph load callouts.** Dependency injection between skills. The standards analog already exists and is better: cross-file `→ FILE.md §N` pointers at the point of use. Don't invent a load-order mechanism on top of it.
6. **STOP gates between sections.** Gates separate *execution stages*. In a reference doc they're speed bumps between sections the reader may legitimately read in any order.
7. **Full worked transcripts as closers.** Transcripts show the shape of a correct *session over time* — the right closer for a procedure. For a rule library the right closers are the checklist, the restated law, or the killed excuse (T10).
8. **Flowcharts for everything.** Flowcharts are for non-obvious *decisions* only. A rule with a linear statement doesn't need a diamond. In standards docs, reserve diagrams for genuine branching (e.g., exception routing in T13).
9. **Router-injection mechanics** (e.g., person/voice rules for skill descriptions). About how skill routers consume descriptions — different machinery from doc retrieval. The transferable part is T4 (triggers = symptoms, never summaries), not the person rule.
10. **The description-trap prohibition applied naively.** "Never summarize the workflow" targets *router trigger sentences*. A standards file still needs its one-line thesis (T5) — the trap is specifically the trigger sentence doubling as a content summary that lets the agent skip reading. Keep the thesis; keep the trigger symptom-only; don't confuse the two jobs.

## Testing a rewrite

"Micro-test your own case rather than assuming." A rewrite claim without a test is theater. The bar, distilled from the analyzed library's eval protocol:

- **Control arm mandatory.** Compare against no-guidance, not against the old wording alone — the old wording may itself be worse than nothing (the prohibition-backfire result).
- **Multiple reps.** Single samples lie; run 5+ reps per wording arm. Variance is a metric.
- **Manual review of every flagged match.** Automated grep for compliance markers produces false positives; read the outputs.
- **Measure the right thing.** Compliance on a fixed task battery, or whether the agent can reproduce the rule's rationale when challenged — not whether the doc "reads well."
