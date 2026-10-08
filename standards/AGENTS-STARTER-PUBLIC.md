---
title: AGENTS Starter (Public)
version: "1.0"
scope: "Portable, stack-agnostic, self-contained agent-instruction foundation - no external references"
consult_when: "When starting a new repo or refreshing agent instructions and you want a drop-in AGENTS.md with zero dependencies."
last_reviewed: 2026-10-08
---

# AGENTS.md — Portable Starter

This is the portable foundation. It holds the rules that survive any stack, language, or team shape: how to work, how to verify, how to keep code lean. It does not know your architecture, your commands, or your conventions — those live in **Repo-specific** at the bottom, which is yours alone. Copy this file into a repo as `AGENTS.md`, fill in the bottom section, change nothing above the line.

**Core principle: The first solution is a draft; the simplest working solution wins.**

## The rules

### 1. Ship the smallest solution that actually works

**Solve the stated problem at its stated scale.** No speculative generality, no framework for a script, no plugin system for two callers. Generalize for the second caller that exists, not the one you imagine. Over-engineering is a defect: 1000 lines where 300 would do is not thoroughness, it is bug surface.
*Why: every part you add is a part you maintain, debug, and explain — and AI-generated code arrives faster than anyone can review it, so the cost compounds.*

```python
# ❌ Speculative machinery for one caller
class ReportStrategy(ABC): ...
class PdfReportStrategy(ReportStrategy): ...   # the only strategy that will ever exist

# ✅ The direct solution
def render_pdf_report(data): ...
```

**Every changed line traces to the request.** Don't improve adjacent code, don't refactor what isn't broken, match existing style. When code your diff already touches could be much smaller, shrink it as part of the change — but don't go rewriting modules your diff doesn't need. Shrinking is fewer lines in code your diff already changes; expanding is touching code your diff doesn't need. The first is part of the task, the second is a separate task.

| Thought | Reality |
|---|---|
| "This might need to scale later" | Generalize for the second caller that exists, not the one you imagine. |
| "I'll clean up the neighboring code while I'm here" | That's a separate task with its own diff. |
| "The adjacent code has the same failure mode" | Same failure mode nearby is not a second caller — it's a second task. Note it in your report; don't expand this diff. |

### 2. Wire it in or delete it

**No orphan code.** Every function, module, and test you write is either called by what you built or deleted before you report. "I'll wire it in later" is how dead code is born — later never comes. Unwired code is dead code with extra steps.
*Why: unwired code rots invisibly. It still gets read, still gets "maintained," still confuses the next reader about what's real.*

```python
# ❌ Written, never called
def retry_with_backoff(fn): ...   # nothing imports this

# ✅ Wired or gone
from utils import retry_with_backoff   # used by worker_handler.py
```

Flag suspected dead code freely; deleting it needs deterministic proof or a human yes.

### 3. Prove completion — never claim it

```text
NO COMPLETION CLAIM WITHOUT FRESH EVIDENCE
```

**No verification run in this session, no "done."** Every completion report carries executed results: tests passing, lint clean, the behavior actually exercised. Re-run checks on the final diff — a green run only proves the tree it ran on. When a check can't run, say so: "I couldn't verify X because Y."
*Why: "done" without evidence is a rumor. The check is the proof.*

**Evidence must discriminate.** A check that cannot fail does not count — a green suite that can't go red proves nothing. A test that mocks away the thing under test, or an assertion that passes on any input, is theater, not verification. Test real behavior.

| Thought | Reality |
|---|---|
| "Tests passed earlier this session" | A green run only proves the tree it ran on. Re-run on the final diff. |
| "The change is too small to break anything" | Size doesn't predict breakage. The check is the proof. |
| "Tests after achieve the same thing" | A test written after the code verifies the code you happened to write. Write the check that would catch the bug, then make it pass. |

### 4. Name the alternatives before you commit to one

**The first solution is a draft.** Before building, state at least two approaches and their trade-offs in plain words — then pick one and say why. When a simpler approach exists, say so up front: "A simpler approach exists: `<one-sentence sketch>`. I'll proceed with it — say the word if you want the original plan."
*Why: the first idea is the most available, not the best. Forcing the comparison is the cheapest design review that exists.*

| Thought | Reality |
|---|---|
| "The first approach obviously works" | Obviously-working is how you miss the simpler one. Name two before you commit. |
| "The tech lead / the ticket asked for the bigger approach" | An ask is not a design review. Name the trade-offs and the simpler option anyway — authority doesn't make the complex option correct. If you follow the ask regardless, say which rule you're setting aside and why. |

### 5. Handle errors where they're credible — nowhere else

**Swallow nothing silently; armor nothing needlessly.** Every failure path gets an explicit decision: log, recover, or raise. But handling belongs at the boundary — user input, I/O, network, IPC — where failure is credible. A `try/except` around code that cannot fail is not robustness, it is noise that hides the handling that matters.
*Why: defensive code against impossible failures hides real bugs and teaches readers that every line is suspect.*

```python
# ❌ Safety theater
try:
    total = sum(items)      # items: list[int], already validated
except Exception:
    total = 0               # hides real bugs, "handles" nothing

# ✅ Handling at the boundary, clean inside
raw = request.json()
try:
    items = [int(x) for x in raw["items"]]
except (KeyError, ValueError) as e:
    raise BadRequest(f"invalid items payload: {e}") from e
total = sum(items)
```

A failure worth handling is a *credible* one: observed here, reported in comparable systems, or following from a concrete mechanism — not merely imaginable.

| Thought | Reality |
|---|---|
| "Better safe than sorry" | A try/except around code that cannot fail hides real bugs — safety theater, not safety. |

## Equally binding, shorter stated

**State assumptions before coding.** Say what you assumed when it affects the design. Define success criteria up front; loop until verified, with a verify step for each action.
*Why: unstated assumptions are where the wrong solution comes from.*

**Check the docs, not your memory.** Unsure about an API, a behavior, or a convention? Read the official documentation or a real open-source repo that does it — never reconstruct from memory. Memory is a rumor; docs are the source.
*Why: confident recollection of APIs is one of the most reliable sources of subtle bugs.*

**Scope-test before you write: 2–4 bullets.** Before writing a function or module, list what it accomplishes in 2–4 bullets. More than four means split it. Roughly: one thing per function, ~50 lines max; files ~800 max; guard clauses beat nesting (cap ~4 deep).
*Why: line counts catch size after the fact. The bullet test forces the scope decision up front, where splitting is cheap.*

**Duplicate twice, abstract on the third.** Write it three times before extracting — premature abstraction locks in the wrong shape.
*Why: the wrong abstraction is worse than duplication. Duplication is at least honest about what it is.*

**Prefer editing over creating.** Search before creating a file so you don't duplicate. No empty placeholders, no new module for one small helper.
*Why: every new file is a new place a reader must look.*

**Start with the answer; end when the answer is done.** No preamble ("Great question!"), no recap, no closer ("Hope this helps"). The first line carries the verdict.
*Why: everything before the payload is working-memory tax; across compacted sessions a buried verdict is a lost verdict.*

**State errors matter-of-factly: cause, then fix.** Never "Uh oh," "Oh no," or "There seems to be a problem." Uncertainty is allowed — "cause unknown, two leading hypotheses:" is matter-of-fact.
*Why: alarm phrases consume attention without carrying information.*

**Something broken? Loop before theory.** One command that goes red on the exact failure — fast, deterministic — before any theorizing. Match the loop to the problem's size.
*Why: theorizing without a loop feels like progress and isn't.*

**Writing a test? Make it falsifiable.** One test that fails when the logic breaks beats any coverage number. One behavior per test, named for WHAT; trivial changes exempt.
*Why: a check that cannot fail does not count.*

## When the rules conflict

**Rules bow to context.** These are defaults with strong priors, not laws of physics. When a rule genuinely doesn't fit, say which one and why — set it aside explicitly, never silently.

**Your limits are not arguments.** "I can't verify the simpler option from here" is a statement about you, not a strike against the option. State limits as limits — convenience never counts as a design reason.

---

## Repo-specific

*Everything below this line belongs to this repo. Fill in the slots when you adopt this file.*

- **Stack:**
- **Architecture map (where things live):**
- **Commands (install, test, lint, build):**
- **Local conventions:**
- **What "done" means here:**

---

**Adopting this file:** copy it into your repo as `AGENTS.md` (or merge it into the existing one), fill in Repo-specific, change nothing above the line. If you adopt a newer version of this starter later, re-copy everything above the line — your section below survives untouched.
