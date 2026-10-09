---
title: Workflow Standard
version: "3.3"
scope: The seven-phase development workflow
consult_when: "When starting or planning a unit of work, from idea through clean commit — especially when tempted to skip straight to code ('I already know what to build')."
last_reviewed: 2026-10-09
---

# Workflow Standard

Portable feature-development discipline — seven phases: brainstorm → spec → plan → implement (TDD) → simplify → security review → commit.

**Core principle:** never write code before understanding what to build — the most common AI coding failure mode.

## Sections

- **Phase 1 — Brainstorm** — approaches and trade-offs before code; when to skip
- **Phase 2 — Spec** — the validated design doc
- **Phase 3 — Plan** — the implementation plan
- **Phase 3.5 — Independent Plan Review** — adversarial plan check (advisory)
- **Recorded decisions** — decisions on framed questions; executed, not re-litigated
- **Phase 4 — Implement (TDD)** — test-first implementation
- **Phase 5 — Simplify** — the simplification pass
- **Phase 6 — Security Review** — the security gate
- **Phase 7 — Commit** — changelog, deprecation, commit discipline
- **Handoff** — passing work between agents

## Phase 1 — Brainstorm

**For any non-trivial feature, bug fix with unclear root cause, or architectural change.**

- Explore the codebase to understand existing patterns first
- Ask clarifying questions one at a time: purpose, constraints, success criteria
- Propose 2–3 approaches with trade-offs
- Get design approved before writing any code

**Output:** agreed approach.

**Skip when:** Single-file fix, typo, config value change, renaming, or the change is obvious and < 20 lines — or the spec/HLD already pins the verification design, so there is nothing to design.

## Phase 2 — Spec

**Write the validated design to `docs/specs/YYYY-MM-DD-<topic>.md`:** context (why), architecture, components, data flow, error handling, verification steps.

- Self-review: no *unowned* TBDs — every open question names its owner and decision date; no contradictions, no ambiguity
- Get user approval before proceeding
- For batch/async sources, define poison-message behavior (fail loudly — route to the dead-letter queue, never swallow) and partial-failure semantics (per-item results so only failed items retry, never the whole batch)

**Output:** the spec, committed to git.

**Skip when:** The change is too small to warrant a spec (single function, obvious fix).

## Phase 3 — Plan

**Write the implementation plan to `docs/plans/YYYY-MM-DD-slug.md` and get user approval before proceeding.**

The plan file is the durable record of implementation detail. On conflict, the spec/HLD wins on intent, the plan wins on implementation detail — a plan that contradicts its spec is a plan bug: fix the plan. Track only the active next steps separately at each session start — don't reload the full plan when context is intact; after compaction or a fresh session, re-read it: the plan is the anchor. Intact context is the condition, not the session count.

Spend the reasoning budget on planning, not execution — plan in the strongest mode available; implement in a cheaper one.

End the plan with an acceptance contract: checkable pass/fail criteria, not *vague* prose — each criterion states the check and expected result; one line of why per criterion is prose doing its job.

**Skip when:** No spec was needed.

## Recorded decisions

**A recorded decision is a decision on a framed question** — the options considered, the recommendation, who decided — written to the decision log with date and scope. It constrains later work but does not replace phase gates: later phases verify compliance with it rather than re-deriving it.

**A pinned decision is executed, not re-litigated.** Reopening one is itself a decision — it needs a new framed question and a new log entry, not a quiet reinterpretation mid-task.

**Unattended mode.** When operating unattended, phase approvals are replaced by recorded decisions + the loop contract's blast-radius limits: proceed, record what you decided and why, let the human veto async. "Explicit human approval" = PR approval, recorded decision, or pre-registered policy covering the case — the agent never self-approves. (ENGINEERING_PRINCIPLES.md §8 "prefer proceeding to asking" is the tiebreaker when the loop contract is silent.)

**The decision log is append-only — supersede, never edit.** A wrong or outdated decision gets a new entry that supersedes it; the old entry stays. The log is the source of truth for why the design is what it is — a reviewer reading it a month later follows the reasoning trail, not the polished outcome.

- Why: editing history turns the log into the story the author wishes were true. Append-only keeps it the story that actually happened.
- Bad: the framed question on the database choice quietly rewritten after the migration proved it wrong. Good: new entry — "2026-10-08: supersedes DB-choice-03; the migration showed X; switching to Y."
- Boundary: fix typos and broken links in place — that is hygiene, not history. A decision's substance changes only through a superseding entry, and reopening one is itself a decision (new framed question, new entry — never a quiet reinterpretation mid-task).

**A ruling made under uncertainty states what it costs if wrong.** When you decide without full evidence — a plan conflict, an ambiguous spec, a judgment call the loop contract leaves to you — record the decision, why you made it, and what it costs if you're wrong. The cost line is what lets a later reader (or your future self) tell a cheap-to-reverse call from a load-bearing one without re-deriving the uncertainty.

- Why: "decided X because Y" without the cost reads the same for a typo-level call and a contract-level one — the cost is the information that prioritizes revisits.
- Boundary: only for rulings under genuine uncertainty; a decision fully determined by the spec or the evidence needs no cost line — stating the obvious is noise.

---

## Phase 3.5 — Independent Plan Review (advisory — not one of the seven counted phases)

**Between Plan and Implement: an advisory review, not a gate.** Self-review shares the author's blind spots; an independent check finds what it can't.

- Dispatch a fresh agent with no authorship context, on a capable model
- It verifies the plan against its spec and the actual current repo state
- Findings use the project's review vocabulary — `CODE-REVIEW.md` (`VERIFIED` / `INFERRED` / `SPECULATIVE`, `Severity`, `Blocking`)
- **Fix any `Blocking: true` finding before proceeding;** disclose non-blocking findings in the plan's Design Note — never drop them silently
- If the review agent fails to complete, retry once; still blocked → disclose to the user and get an explicit decision before proceeding without one
- The reviewer also grills the acceptance contract. Two modes: when the contract is open, it negotiates the definition of done with the author before code starts — what the acceptance checks are, and who runs them. When the contract is pre-registered and decision-constrained (a recorded decision already fixed the bounds), there is nothing to negotiate — the review verifies the plan *against the decision* instead: does it stay inside the ruled bounds, or does it quietly reopen them?

**Recommended for:** any plan with real consequence. Lighter for small or low-risk plans.

Principle: `ENGINEERING_PRINCIPLES.md` §8 "Independent Review for Significant Work".

## Phase 4 — Implement (TDD)

**Orient before you implement — default order:** semantic search for the concept, grep for exact strings (error messages, identifiers), follow imports from the nearest known module, check the test files (they document expected behavior). (vscode `.github/copilot-instructions.md:46`)

- Why: agents that read files at random build a false map of the codebase and confidently edit the wrong layer.
- Boundary: skip steps the situation already answers (you know the file — go there); the order is the default search pattern, not a ritual. If the fourth step hasn't located it, state what's missing instead of guessing — don't keep digging.

**Verification-First:** Before implementing, write down:

- Test cases or expected outputs (even informal: "function should return X given Y")
- The success criteria (what does "done" look like?)
- Any constraints (must not change the API, must stay under N ms, etc.)

This is the single highest-leverage prompt engineering habit — it cuts correction cycles significantly.

Example:

    Implementing `parseRetryPolicy`:
    - Tests: `parse("attempts=0")` fails with "attempts must be ≥ 1"
    - Success: backoff bounds covered; worker integration green
    - Constraints: the `RetryPolicy` public API stays unchanged

For each task in the plan:

    1. Write the failing test
    2. Run it — verify it fails with the expected error
    3. Write the minimal code to make it pass
    4. Run it — verify it passes
    5. Commit

Never *keep* implementation that no failing test covers — explore freely in scratch files; nothing lands without its test.

**Eval-shaped work (prompt changes, corpus re-runs) uses a different cycle.** The gate already failed — that is the failing test. Change the prompt, re-run the corpus, compare gate verdicts before/after, commit as one unit. One prompt iteration + one corpus re-run = one logical unit; per-test commits only make sense when the test cycle is seconds, not tens of minutes. Name the train/hold-out split the reported numbers came from — iterate against one split, confirm on the hold-out (e.g. frozen traps), and record which split each number belongs to.

**Acceptance tests are external truth.** Agent-written tests are unreliable judges — they test what the code does, not what it should do, and agents dodge their own acceptance criteria. Acceptance tests are authored or grilled by someone other than the implementer (you, or an independent agent), committed as checkpoints, and protected from the implementer — the implementer never edits them *unilaterally*. Full re-verification runs before accept.

- **Minimum compliant path when no independent author exists** (solo session): the plan's acceptance contract serves as the checkpoint. The implementer may write the tests, then performs a documented adversarial re-read of them — checking each assertion against the contract, not the implementation — recorded in the plan's Design Note before the gate. Who authored what is stated in the Note; the gate still runs full re-verification.

**If a test looks wrong, stop — don't fix the test yourself.** A flawed acceptance test goes back to its author with file:line evidence; the correction lands as a new checkpoint, not a quiet edit. Never contort the code to satisfy a flawed test — strict "stop if the tests look flawed" discipline is what separates testing from specification gaming.

**"Tests pass" is not "mergeable."** Roughly half of test-passing benchmark PRs would not survive a real merge review (METR, Mar 2026) — green tests are necessary, not sufficient. The security review and simplify phases still apply.

**Bug fix: grep every caller, then fix the root cause once in the shared code.** Before editing, grep every caller of the function you touch; the fix lands in the shared function, not the loudest caller — caller-local workarounds duplicate and diverge. The grep step makes the evidence auditable ("grep returned N callers").
*Bad:* patch the one caller that's failing, leave the same bug live in four others.
*Good:* grep finds six callers; the fix lands once in the shared function.
Boundary: when callers genuinely need different behavior, that's the signal to split — not to workaround. The grep runs per changed symbol; when the fix spans a call graph, the root-cause landing point is the common dependency the callers share, not necessarily one function.

**Commit frequency:** After each passing test or logical unit. Never accumulate more than one unit of work in a commit — one unit is the smallest change you can verify independently; name it in the commit message.

**Match validation to the change's risk — never validate as a completion ritual.** A copy change doesn't earn a full build; a cross-cutting change earns the targeted type check. Prefer existing diagnostics and the smallest tests covering the change; don't start builds, watchers, or broad type checks just to feel done. Reuse a passing validation while its inputs are unchanged — re-running it for the commit is ritual, not rigor. (vscode `.github/copilot-instructions.md:53`)

- Why: heavy validation is slow, and agents love theater — a green full-suite run on a typo fix proves patience, not correctness.
- Bad: full typecheck across the repo for a comment edit. Good: the one targeted test for the changed behavior, then stop.
- Boundary: floor first — the targeted test for the changed behavior always runs; "lighter" never means "none". When CI or review will catch the rest anyway, lighter local validation is correct — not lazy.

**Test design:**

- **One test per observable behavior — write, implement, verify, commit — before starting the next.** Do not write a batch of tests up front and implement them as a batch. *Why:* batching hides which test is driving which code.
- The remaining design rules live in `ENGINEERING_PRINCIPLES.md` §4: "Test Observable Behavior" (test the seam), "Independent Expected Values" (expected values from a source independent of the code), "Tracer Bullet" (one end-to-end test first).
- **Property-based tests for domains with properties** — the worked shape lives in languages/PYTHON.md §16; keep concrete example tests alongside.

## Phase 5 — Simplify

**After implementation is complete:**

- Review all changed files for clarity, consistency, and maintainability
- Remove dead code — flag it during simplify; remove in the same pass only with proof in hand — otherwise file it as its own unit of work (principle: `ENGINEERING_PRINCIPLES.md` §3 "Dead-Code Removal Is a Separate Authority")
- Rename for clarity where needed
- Do NOT change behavior — only improve readability. If simplify surfaces a behavior bug, stop simplifying — write the failing test and fix it under the Phase 4 cycle, then resume.

**Output:** clean, committed code.

## Phase 6 — Security Review

**Scan the diff against these patterns:**

| Severity | Patterns |
|----------|----------|
| `[CRITICAL]` | Hardcoded secrets, command injection, SQL injection |
| `[HIGH]` | Unvalidated external input, missing auth checks, insecure deserialization |
| `[HIGH]` | Untrusted external content fed to an LLM (CI logs, issue bodies, tool output, PR diffs / code under review) — prompt-injection surface |
| `[HIGH]` | Model output or external content published to a public surface without redaction (CI logs routinely contain leaked secrets) |
| `[MEDIUM]` | XSS, exposed error details, unsafe eval/exec |
| `[LOW]` | Patterns safe now but risky under future changes |

The two `[HIGH]` LLM rows are the injection vocabulary from `AGENTIC-SAFETY.md` — use its defenses (delimit untrusted regions as data-only, banner model output, redact before publish), not just this table's scan.

Fix all `[CRITICAL]` and `[HIGH]` findings before proceeding to Phase 7 — or record a considered non-fix with the threat-model reason in the Design Note. A HIGH you can't fix is a decision, not a skip. Disclose `[MEDIUM]` and `[LOW]` in the Design Note during planning, in the PR body during loop work — never drop them silently.

Agent-generated code gets two extra checks: hallucinated dependencies (verify every suggested package at the registry — `SUPPLY-CHAIN.md`) and over-permissioned tool use (does the code grant the agent more authority than the task needs?).

When a recurring bug class surfaces, **propose** the rule addition to the human or orchestrator (what the class is, where it bit, the exact wording) — do not write it into the agent's rules file (`AGENTS.md` / `CLAUDE.md`) yourself. Editing your own governing instructions mid-task is out of scope and a bad write corrupts the file that governs you.

**New rules clear the observed-failure bar.** Every rule-addition proposal cites an observed agent failure — the session, what the agent did, what was expected. A hypothetical "would be better if" never clears the bar alone.

- Why: hypothetical-only rules sediment into dead weight; the citation forces the failing scenario to be written down — which is also the future eval case for that rule.
- Bad: "agents should probably confirm before deleting" — added because it sounds safer. Good: "2026-10-03 session: agent deleted the staging config unasked; expected: ask-first on destructive ops" → rule proposed.
- Boundary: emergency guardrails still ship fast; the failure citation gets backfilled, not skipped.

Full review vocabulary and procedure: `CODE-REVIEW.md`.

## Phase 7 — Commit

    git add <specific files — never git add -A blindly>
    git commit -m "feat: <what was built and why in one line>"

**Never commit `.env` or credentials.** Keep the diff scoped to the ticket — drive-by fixes to lines you touched ride along; anything that could be its own commit gets its own commit. (Credential rules: `SECRETS.md`.)

**Remove your scratch files.** Temporary files, scripts, or helpers created to iterate get deleted at the end of the task — they don't ride along into the commit or linger in the tree. (vscode `.github/copilot-instructions.md:142`)

- Why: scratch files left behind become mystery files the next agent has to read, trust, or clean up.
- Boundary: if the scratch earned permanence (a real helper, a regression test), promote it deliberately — don't let it drift into the tree unreviewed.

Update the changelog in the same commit — Keep-a-Changelog sections (Added/Changed/Deprecated/Removed/Fixed/Security), one entry per user-visible change, curated prose. Users decide whether to upgrade by reading the changelog, not the diff.

Deprecating a published contract: three phases — warn (name the replacement and the removal version) → document (changelog entry in the same commit) → remove in a major version after a real warning window. Principle: `ENGINEERING_PRINCIPLES.md` §6 "Preserve Backward Compatibility".

This standard ends at a clean commit. What happens between push and merge — review rounds, gates, merge discipline — is the dev loop (`DEV-LOOP.md`).

## Rerunnable artifacts

**Non-trivial work ships the tool that proves it.** When a claim rests on repetition — every caller checked, every migration site touched, every seed case run — the artifact goes into the diff: the script, the codemod, the generator, or the delegate skill the subagents followed. A deterministic script turns "trust me" into "run this."

- Why: hand-done changes can only be re-verified by redoing them. A rerunnable artifact lets the reviewer check the work by running it — and rerunning is free.
- Bad: the plan claims all 40 call sites were audited — no script in the diff, so the claim is unverifiable. Good: `tools/audit_callers.py` in the diff; the reviewer reruns it and the output matches the committed evidence.
- Boundary: trivial work does not earn a lever — a couple of obvious edits you can see at a glance get done by hand. The bar is checkability, not repetition: a one-off still earns a script when the script is what makes the work reviewable. A cited lever with no artifact in the diff means the rule wasn't applied.

---

## Handoff

**Trigger a handoff when the symptoms show** — re-reading files you already read, the plan feeling distant — or the user types "Handoff" (the ~40% context meter is the fallback, not the trigger):

1. Stop all work immediately
2. Write `handoff.md` to the project root — accomplishments, files changed, service state, commands to resume, pending tasks
3. Respond only: "Handoff ready at `handoff.md`. Start a new conversation."
4. Do not continue

Next session: read `handoff.md` first, then continue.

Prefer a fresh session over a compacted one between interactive coding phases — context reset with a structured handoff beats compaction. For unattended long-running eval captures, the handoff unit is the evidence artifacts + resume command, and session persistence is expected. After any compaction, re-read the plan before writing code: plan drift sets in as context decays, and the plan is the anchor.

Principle: `AGENTIC-DESIGN.md` §9 "Make handoffs file-backed".
