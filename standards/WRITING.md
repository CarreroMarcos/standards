---
title: Writing
version: "1.0"
scope: "Prose the agent writes: docs, PR bodies, reports, comments"
consult_when: "When writing anything a human reads — documentation, PR descriptions, reports, commit messages — and the draft feels like it could have come from any project."
last_reviewed: 2026-10-23
---

# Writing

**Core principle:** every sentence earns its place by saying something only this project could say, in words the reader parses once.

## Sections

- **1. Pick the mode before writing** — one Diátaxis mode per document
- **2. Cut what could belong to any project** — the portability test
- **3. Say it plain** — concrete words, no metaphor nouns, no AI vocabulary
- **4. Give verbs the weight** — strong verbs, named actors, no adverb props
- **5. One thought per sentence, whole sentences** — 20/25 tripwires, no over-compression
- **6. PR bodies are under-a-minute briefings** — brief, then link the evidence
- **7. Rules have stable numbers** — a retired rule leaves a gap
- **8. Durable prose has a rot budget** — line numbers, generated docs, live facts, brief-vs-code authority

## 1. Pick the mode before writing

**Answer two questions before writing one word: does this inform action or understanding, and does it serve learning or work?**

One document, one mode:

- Action + learning: **tutorial.** "We" voice, every step produces a visible result early and often. Say what the learner will build, not what they will "learn."
- Action + work: **how-to.** Assume competence. Steps to a goal, no teaching, no background — link it instead. Name the guide by the task: "How to rotate the signing key."
- Understanding + work: **reference.** Describe, only describe. No instruction, no opinion, no hand-holding. Dry, complete, sure.
- Understanding + learning: **explanation.** One bounded topic, anchored on a real why question. Opinion is allowed here and nowhere else.

*Why: a doc that mixes modes makes the reader switch gears mid-read, and switching costs understanding. The tutorial that pauses to argue and the reference that hand-holds both fail for the same reason — no mode was chosen.*
*Bad:* a how-to that opens with three paragraphs of architecture background before the first step.
*Good:* "How to rotate the signing key" starts with step one and links the explanation instead of summarizing it.
Boundary: when a topic genuinely needs two modes, split it into two documents and link them. PR bodies and commit messages skip the compass — see §6.

| Thought | Reality |
|---|---|
| "Readers will figure out what kind of doc this is" | They won't. An unpicked mode reads as muddle no matter how correct the facts are. |

## 2. Cut what could belong to any project

**If the sentence could appear unchanged in another project's docs, it says nothing about this one. Cut it.**

Run every sentence through the test: ask what it tells the reader to do or know, then restate it as a concrete instruction, fact, or number. If you cannot restate it, cut it.
*Why: generic sentences survive every edit because nothing disagrees with them. The portability test is the fastest filter in the catalog — one question catches empty claims, vague praise, and feeling-words alike.*
*Bad:* "This robust, scalable solution ensures reliable performance in production environments." — any project could ship this sentence.
*Good:* "The worker runs 3 concurrent reviews inside the 900s Lambda timeout; production concurrency is capped at 3."
Boundary: the test targets claims about the system, not procedural glue. "Install the dependencies first" belongs to this procedure even if the sentence shape is generic.

| Thought | Reality |
|---|---|
| "This sentence applies to our project too" | If it applies to every project, it distinguishes none. |

## 3. Say it plain

**Use the concrete word. Drop the metaphor noun, the flourish, and the AI vocabulary word.**

Abstract metaphor nouns dress up plain ideas: substrate, vector, paradigm, harness, surface, bedrock, scaffolding, modality, nexus, north star, flywheel. Replace each with the concrete word — "base", "way", "a limit that only tightens". Mannered prose (aphorisms, rhetorical fragments, personified code, figurative verbs like "rides along") becomes the literal phrase. AI vocabulary (delve, crucial, pivotal, underscore, vibrant, intricate, tapestry, showcase, testament) becomes the plain word.
*Why: metaphor and flourish make the reader translate twice — once to the image, once back to the mechanism. The concrete word translates zero times.*
*Bad:* "The worker leverages a robust orchestration substrate to harness the full review pipeline."
*Good:* "The worker runs the three review stages in one Lambda invocation."
Boundary: a term the doc defines on first use is a definition, not a metaphor — define it once, then use it consistently.

## 4. Give verbs the weight

**Pick the verb that carries the meaning. Never prop a weak verb with an adverb.**

"Significantly improves" becomes the measured delta. "Runs quickly" becomes the number. An adverb propping up a weak verb means the verb is wrong. Name the actor: "the compiler validates queries", not "queries are validated" — passive is fine only when the actor is unknown or genuinely doesn't matter.
*Why: a sentence's payload lives in its verb. A strong verb with a number needs no adverb; a weak verb with three adverbs carries less.*
*Bad:* "The cache significantly improves response times for frequently accessed data."
*Good:* "The cache cuts p99 response time from 800ms to 90ms on repeat reads."
Boundary: do not invent precision — if the delta was not measured, the honest verb ("faster") beats a fabricated number. The rule demands the honest verb, not a made-up measurement.

## 5. One thought per sentence, whole sentences

**If the reader must backtrack to parse it, split it. If it drops its articles and verbs, expand it.**

Tripwires: split instructions longer than ~20 words and other sentences longer than ~25. One idea per sentence. Write whole sentences with their articles and verbs: "The parser rejects a bad date, exits with code 2, and writes nothing" instead of "Parser rejects bad date → exit 2, no write". Em dashes, stacked clauses, and symbol-speak are compression — decode work pushed onto the reader.
*Why: dense sentences feel efficient to write and expensive to read. The reader's parse is the cost; the split is cheap.*
*Bad:* "On timeout — which the 900s budget barely covers given ~240s per-call latency — the worker retries."
*Good:* "A review call takes ~240s, so three stages use ~720s of the 900s worker budget. On timeout the worker retries once, then escalates."
Boundary: keep the long sentence that carries one thought with its condition or consequence — split the sentence that carries two.

## 6. PR bodies are under-a-minute briefings

**A PR body is a briefing a reviewer can read in under a minute. Never paste swarm logs, SHA lists, or metric tables — link them.**

Cover three things: what changes, why, how to verify. The sycophancy and closers belong nowhere in durable prose: no "Great question!", no "Hope this helps!", no bot-comment applause. Commit messages are the same bar in miniature — the first line states what and why.
*Why: the reviewer decides in the first minute whether the change is safe. A buried verdict and a log dump push that decision onto a reader who never finishes the read.*
*Bad:* a PR body with 200 lines of pasted CI output ending in "Let me know if you need anything else!"
*Good:* three lines (what / why / verify) plus a link to the full logs.
Boundary: a complex PR earns more than a minute of reading, but never as pasted logs — the body briefs, links carry the evidence. Conversational response shape is AGENTIC-DESIGN.md §10; this section covers prose that persists.

**Never cite line numbers in durable prose.** They go stale as soon as the file changes. Reference the symbol, class, or subsystem by name instead of the location; include a file path only when the prose is about file layout, and even then prefer a link over a baked-in number. (langchain-ai/langchain `AGENTS.md:156-157`)
*Why: a line number is a pointer into a moving target. The next edit invalidates it and leaves a lie the reader trusts because prose looks authoritative.*
*Bad:* "the retry logic at `worker.py:412` handles the timeout" — after the next edit, 412 is a blank line.
*Good:* "the retry logic in `retry_with_backoff` handles the timeout."
Boundary: line numbers are fine in ephemeral text (a chat message, a review-thread reply) where staleness costs nothing — the rule binds prose that outlives the edit. Provenance citations are the other exemption: an attribution like `(langchain-ai/langchain AGENTS.md:156)` points into a source pinned at the commit the mine recorded — it is evidence about where a rule came from, not navigation into a living file.

**Every section earns its lines.** A "Test plan" section that says "CI passed" in every PR is a ritual, not information. Include a section only when its content is non-obvious, risky, or otherwise notable — mention tests then; otherwise the linked checks carry the verdict. (langchain-ai/langchain `AGENTS.md:160`)
*Why: ritual sections train reviewers to skim, and skimming trains them to miss the one section that actually mattered.*
*Bad:* "## Testing — Ran the full suite. All green."
*Good:* no Testing section at all; or one that says the flaky retry test failed twice before passing, with the run linked.
Boundary: a project whose CI never posts check results earns the section; a repo whose PR template mandates it follows the template.

**Write the why as a user story, for an outsider.** Who benefits, what problem they had, and how this solves it — written for a reader who has never seen this subsystem. Avoid insider shorthand; say what the thing is, not what the team calls it. (langchain-ai/langchain `AGENTS.md:154-155`)
*Why: the reviewer in six months is that outsider. A user story reconstructs the decision; a bare summary restates the diff the diff already shows.*
*Bad:* "Refactored the foobarifier to be less janky for the queue folks."
*Good:* "Worker teams hit duplicate reviews when the timeout fired mid-run; the new idempotency key makes a retried review collapse onto the original record."
Boundary: the user story is a shape, not a length — three tight sentences beat three loose paragraphs.

**Point the reviewer at the hard parts.** Call out the areas of the change that require careful review — the one or two places where the review actually matters: the locking order, the migration, the generated-code diff. (langchain-ai/langchain `AGENTS.md:161`)
*Why: reviewers have finite attention. An unmarked diff spreads it evenly across the safe and the risky alike.*
*Bad:* 400 changed lines with "PTAL."
*Good:* "Review carefully: the token-refresh ordering — a reorder there deadlocks the callback path."
Boundary: flag where the risk concentrates, not where you feel insecure — "not sure about any of this" is a review request, not a pointer.

## 7. Rules have stable numbers

**A retired rule leaves a gap. Never renumber — in files that use numbered rules.**

In a file with a numbered-rule catalog, rule numbers are stable IDs other rules cite. When a rule is removed, its number stays empty rather than shifting every rule after it. New rules take the next unused number.
*Why: renumbering silently breaks every citation. A gap is honest — it says something used to live here and was deliberately removed.*
*Bad:* deleting rule 12 and renumbering 13 to 12, orphaning every "see rule 13" pointer.
*Good:* rule 12 is removed and its entry reads "[retired]" until the next edit cycle; then the number simply stays empty.
Boundary: this file's own sections are prose sections (§§1–8), not a numbered-rule catalog — the rule binds when this file or any file grows one. New files start at 1 with no gaps — gaps appear only through retirement, never through authoring.

## 8. Durable prose has a rot budget

**Never hand-edit a generated document.** Fix the source it was generated from and regenerate; a generated page is a copy, not the source. (langchain-ai/langchain `AGENTS.md:388`)
*Why: a hand-edited generated page is guaranteed drift. The next regeneration either overwrites the edit or never comes, and then the edit is a lie nobody owns.*
*Bad:* patching the rendered API docs for a renamed parameter instead of fixing the docstring.
*Good:* fix the docstring, rebuild.
Boundary: when the generator is gone and the page is all that remains, say so in the commit — then it is the source, not the copy.

**Check live facts against their authority before writing them down.** Model IDs, versions, endpoints, pricing, API shapes — anything that changes without telling you — get verified at write time against the authoritative source, never reconstructed from memory. (langchain-ai/langchain `AGENTS.md:265`)
*Why: a memorized fact is a rumor with confidence. Writing it down locks the rumor in where the next reader trusts it as documentation.*
*Bad:* "as of v3 the endpoint is `/v3/reviews`" written from memory.
*Good:* open the provider's docs, quote the current endpoint, link the page.
Boundary: the bar scales with reach — an ephemeral message earns a glance; a reference doc or an example users copy earns the full check.

**When the source code and the brief disagree, the source code wins.** Treat source code and tests as authoritative. A generated brief's unknowns and open items are verification gaps to check, not requirements to implement. (langchain-ai/langchain `AGENTS.md:385`)
*Why: a brief describes a plan; the code describes what runs. Building to the brief after the code moved builds the wrong thing.*
*Bad:* implementing the brief's "verify rate limiting" TODO after the limiter was removed in the previous PR.
*Good:* "The brief lists rate-limit verification as an unknown; the limiter was removed in #57 — flagged, not implemented."
Boundary: the code is authoritative about what exists, not what was intended. An ADR's intended-but-unbuilt requirement still needs building — read the code to see whether it is. And items a human reviewer raises in a review thread are requirements to answer, not gaps to wave at — this rule governs briefs, not reviewers.
