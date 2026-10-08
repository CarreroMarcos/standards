---
title: Agentic Design
version: "1.3"
scope: Designing agentic systems: autonomy justification, architecture simplicity, human control, evaluation
consult_when: "When about to give a system model-directed autonomy — 'let's make it an agent', 'the model can decide this', 'how many agents do we need' — or when setting autonomy boundaries and evaluation."
last_reviewed: 2026-10-07
---

# Agentic Design

**Core principle:** a model may propose, but it never authorizes. Keep authority, truth, and state outside the model — and verify ground truth between actions.

## Sections

- **1. Use Autonomy Only Where It Earns Its Cost** — determinism beats autonomy when sufficient
- **2. Use the Least Complex Agent Architecture That Works** — simplest sufficient agency
- **3. Bound Autonomy; Keep Authority Outside the Model** — authority boundaries
- **4. Observe Ground Truth Between Meaningful Actions** — verify real state, not summaries
- **5. Treat Model and Tool Outputs as Evidence, Not Authority** — outputs are data
- **6. Context Is a Budget and a Trust Boundary** — spend context deliberately
- **7. Evaluate Agent Behavior, Not Just Agent Code** — behavioral evals
- **8. Preserve Human Control at Consequential Boundaries** — human gates for consequential actions
- **9. Orchestrating Multiple Agents** — multi-agent discipline
- **10. Shape Responses So the Reader Can Act** — answer-first, scannable agent output


Agentic systems inherit every principle above. They do not get weaker architecture, testing, state, security, or operational requirements because a model is involved.

The model adds a probabilistic reasoning component inside the system. It does not become the system's source of truth, authorization service, durable state owner, or proof that an external action succeeded.

Detailed protocol-specific tool, authorization, prompt-injection, and MCP security controls belong in the project's dedicated security standards. The rules here define the enduring architecture boundaries.

Agent-security mechanics have their own sources of truth — `AGENTIC-SAFETY.md` (skill vetting, Rule of Two, exfiltration channels), `TRUST-CLASSIFICATION.md` (what counts as trusted input), `SECRETS.md` (credential handling). This section states the architecture principles and points at them; it does not restate them.

## 1. Use Autonomy Only Where It Earns Its Cost

**Prefer deterministic code for deterministic decisions** and predefined workflows for well-defined sequences.

Use model-directed autonomy when the work genuinely requires one or more of:

- judgment under uncertainty;
- interpretation of unstructured information;
- dynamic planning;
- choosing among tools based on context;
- adapting a path that cannot reasonably be enumerated ahead of time.

Do not convert ordinary application logic into an agent merely because a model can perform it.

Autonomy adds nondeterminism, latency, cost, evaluation burden, security exposure, and the possibility of errors compounding across multiple steps.

**The test:** if the correct next step can be reliably determined from typed state and explicit business rules, keep that decision in code.

**The common failure:** asking a model whether a state transition is allowed when the actual rule is a deterministic comparison already available to the application.

## 2. Use the Least Complex Agent Architecture That Works

**Start with the smallest useful agentic unit.**

A single agent with clear tools and bounded responsibility is easier to evaluate, authorize, observe, and debug than a network of agents.

Introduce routing, planner/executor separation, evaluator loops, or multiple collaborating agents when measured behavior shows the simpler architecture is insufficient.

Architecture complexity must buy a demonstrated capability, quality, isolation, or scaling benefit.

Multi-agent systems have measured failure modes: system design, inter-agent misalignment, and task verification dominate real traces (MAST, NeurIPS 2025); uncoordinated agents amplify errors an order of magnitude (DeepMind, Dec 2025), and added agents stop paying around three or four. The remedies are typed handoff payloads and orchestrator-run verification gates — coordination machinery, not more agents.

**The common failure:** introducing multiple agents because the conceptual diagram maps neatly onto organizational roles, then paying for coordination, context handoff, duplicated reasoning, and ambiguous ownership without improving the outcome.

**Compose before minting.** A new skill or agent ships only when the behavior can't be composed from existing ones — every skill is permanent maintenance surface (docs, router, manifests).
- Why: skill sprawl taxes every future edit; the catalog stays the size the maintainer actually uses daily.
- Boundary: "can't be composed" is judged on behavior, not convenience — mild awkwardness in composition doesn't earn a new skill.

## 3. Bound Autonomy; Keep Authority Outside the Model

```text
NEVER LET THE MODEL AUTHORIZE
```

A model may propose. Deterministic policy decides what is allowed to happen.

Keep outside the model:

- authentication and authorization;
- tenant and environment boundaries;
- irreversible invariants;
- state ownership;
- permission checks;
- financial and quota limits;
- data-classification rules;
- approval requirements;
- tool availability;
- destructive-operation safeguards.

Every autonomous loop needs explicit stopping conditions appropriate to the workflow, such as:

- task completed;
- bounded attempts;
- bounded tool calls;
- deadline reached;
- cost or resource budget reached;
- repeated failure;
- required information unavailable;
- escalation or human approval required;
- cancellation.

Do not depend on the model eventually deciding to stop.

| Thought | Reality |
|---|---|
| "It'll stop when it's done" | A loop with no declared stopping condition isn't "almost done" — it's unbounded. Declare the conditions up front. |

For destructive, irreversible, privilege-expanding, externally visible, financial, security-sensitive, or otherwise high-impact actions, enforce authorization outside the model and require human approval where policy or risk calls for it.

Scope the sandbox to the tool call, not the agent. One sandbox shared across tools grants the union of every tool's permissions — confine each invocation to its declared capabilities so the isolation is real, not nominal.

Break the lethal trifecta (AGENTIC-SAFETY.md, "Break the lethal trifecta"): never combine private-data access, untrusted content, and external communication in one unattended session.

**The common failure:** encoding a hard business or security rule only in a system prompt and treating model compliance as enforcement.

**The law, restated:** the model proposes; it never authorizes.

## 4. Observe Ground Truth Between Meaningful Actions

An agent works in a changing environment. **Do not let it plan indefinitely from stale assumptions.**

**Before consequential actions, validate current authoritative state** and applicable policy.

**After an action, verify the effect that matters** — observe the environment or authoritative system — before treating the step as complete.

A tool returning `"success": true` proves only what the tool contract says it proves. It does not automatically prove that the user's intended external outcome occurred.

Keep proposals, observations, authoritative state, and committed effects conceptually separate.

For consequential loops, each stage writes a signed receipt — who acted, what was checked, an evidence hash, a timestamp — with secrets masked. Credentials are per-run and ephemeral; the broker hands out a handle, not the secret. A stage that left no receipt did not happen.

**The common failure:** an agent issues a deployment, receives a successful API response, and reasons from "deployment succeeded" without verifying rollout state, health, or the actual target revision.

**No red-capable repro, no hypothesis.** Before theorizing about a bug, build one command that goes red on the exact symptom — red-capable, deterministic, fast. Hypotheses come next as 3–5 ranked, falsifiable predictions.
- Why: agents anchor on the first plausible theory; the repro gate converts debugging from opinion into experiment.
- Boundary: the rule-sized core only — the full multi-phase discipline is a parked future-research idea (future-ideas.md), not an existing skill; this rule is the complete prescription.

## 5. Treat Model and Tool Outputs as Evidence, Not Authority

**Model confidence is not proof.** Retrieved text is not policy. Tool output is not automatically trusted simply because it came through a typed protocol.

Audit tool definitions on install and after every update (MCP-SECURITY.md, "Audit tool definitions"): a compromised tool description can instruct the agent to re-emit secrets — runtime delimiting doesn't cover the description.

Where a decision depends on authoritative facts, resolve those facts from their authoritative source or through a contract that explicitly guarantees them.

Separate untrusted data from instructions, especially when retrieved text, repository content, issue comments, webpages, model-generated text, or tool results can influence privileged actions.

**Worked shape — a model summarizes untrusted logs for publication:** (1) delimit the untrusted region in the prompt (`<untrusted-logs>…</untrusted-logs>`) and instruct the model to treat delimited regions as data only — never as instructions; (2) strip or neutralize instruction-like lines before they reach the model where the format allows it; (3) banner the published output as model-generated and cite the evidence it rests on. The separation is a pipeline step, not a hope about model behavior.

**Worked shape — a model renders verdicts:** require a stated failure mechanism plus the cited evidence *before* the verdict; escalate when the claim can't be verified. A verdict that is labeled and evidence-cited can still be wrong — the guard is not the label, it is the mechanism. *Bad:* "killed — the candidate lacks evidence," citing a file:line that doesn't show the lack. *Good:* "killed — the claimed failure is impossible under the runtime's guarantees, exact lines cited," or "escalated — the mechanism is plausible but unverifiable from here."

Do not allow one untrusted tool result to grant authority to another tool call.

**The common failure:** a retrieved document states that an action is approved, and the agent treats the statement itself as authorization rather than checking the actual approval system.

## 6. Context Is a Budget and a Trust Boundary

**More context is not automatically better context.**

Provide the model with the information needed for the current decision while preserving enough provenance to distinguish:

- instructions;
- authoritative state;
- retrieved evidence;
- prior model output;
- tool results;
- assumptions.

Long-running agents curate or compact context deliberately rather than accumulating every historical token indefinitely. Preserve load-bearing decisions and evidence; discard irrelevant mechanics.

Do not solve an information-architecture problem by dumping an entire repository, ticket history, database record, or conversation into the model context.

**The common failure:** increasing context until the needed fact is technically present but buried among stale, duplicated, conflicting, or untrusted information.

**Engineer the pointer's wording, not just its target.** Treat every context pointer as a trigger surface: front-load the leading word, one trigger per branch — sharpen the wording before inlining material.
- Why: a must-have target behind a weakly worded pointer is a variance bug — the agent never reaches the material. Retrieval precision is the unmeasured risk.
- Bad: README row "For agent coordination concerns, see AGENTIC-DESIGN.md" — trigger buried three words in. Good: the row leads with the situation vocabulary the reader actually has when they need it.
- Boundary: sharpen first; inline the material only if sharpening fails.

## 7. Evaluate Agent Behavior, Not Just Agent Code

Conventional unit and integration tests verify deterministic machinery around the model. They do not prove the agent behaves reliably across realistic inputs.

**For load-bearing agent behavior, maintain evaluations** that exercise representative tasks, important edge cases, and known failure modes.

**Define what success means before comparing models or prompts.**

Where relevant, evaluate:

- task completion;
- factual or contract faithfulness;
- correct tool selection;
- correct tool arguments;
- policy compliance;
- unnecessary actions;
- state-handling correctness;
- recovery from tool failure;
- escalation behavior;
- cost and latency;
- regression against previously solved cases.

Use evaluation results to choose the simplest model and architecture that satisfy the requirement. Do not choose complexity first and construct an evaluation that merely confirms it.

When an agent or model changes, rerun the relevant evaluation set. Model behavior is a dependency and can change independently of application code.

Record every eval run per LOGGING.md ("Eval-reproducibility record") — corpus version, pin sha256, driver, model ID, config, wall time — so the next ticket re-runs, not re-derives.

**The common failure:** shipping because the deterministic test suite passes while the actual model behavior was assessed through a handful of successful manual examples.

## 8. Preserve Human Control at Consequential Boundaries

**Make human involvement purposeful, not ceremonial.**

Do not require approval for every harmless read simply to claim a "human in the loop." Place approval where it changes risk: before a consequential action whose target, scope, or effect the human can meaningfully review.

Escalate when:

- failure or retry thresholds are exceeded;
- the agent lacks required information;
- user intent remains materially ambiguous;
- policy requires approval;
- an action crosses a defined risk threshold;
- the system cannot establish a safe basis to continue.

**Approval describes the actual operation being authorized.** If the target, scope, environment, cost, or impact materially changes afterward, re-evaluate the approval rather than treating the earlier consent as universal.

| Thought | Reality |
|---|---|
| "We have human-in-the-loop" | Approval on every harmless read is ceremony, not control. Approval belongs where it changes risk: the consequential action a human can actually review. |

**The common failure:** asking for broad approval at workflow start and then allowing the agent to choose a materially different destructive action several steps later.

## 9. Orchestrating Multiple Agents

When one agent dispatches others, **the orchestrator owns verification.** A subagent's report is a claim, not a fact.

**Verify independently, in-band.** After a worker completes, check the resulting state directly — the files changed, the tests run, the artifacts produced — rather than trusting the worker's summary. A worker that reports success from the wrong directory, or self-certifies its own review, is caught only by checking ground truth.

**Make handoffs file-backed.** Do not rely on transcript inheritance between stages: each stage writes its output to a named file, and the next stage is pointed at that file. A verifier that cannot see the evidence must refuse to fabricate findings from hints.

**Pin context; do not describe it.** Give a worker the literal absolute paths it will touch, not a "work from this directory" instruction it must translate. Where location matters, require the worker's first action to confirm its actual location before touching anything.

**Keep role separation real.** A reviewer that also implemented the change is not an independent reviewer. Adversarial review works only when the reviewer has no stake in the outcome — separate the roles, and treat self-approval as a process failure even when the underlying work is correct.

**Keep the verifier blind.** The verifier receives the task, the rubric, and the evidence. Blindness applies to verdict passes; diagnostic passes may inspect the maker's reasoning. A verifier that reads the maker's reasoning nods along with it; separation of reasoning is what makes the review independent. Loop mechanics: `DEV-LOOP.md`.

**Watch spawn volume.** ≤6 spawns per rolling 2 hours (AGENTIC-SAFETY.md, "Agent Spawn-Volume Advisory") — each agent is a new poisonable context, and volume makes verifying their reports harder.

**Bound worker authority.** Delegation is intersection (TRUST-CLASSIFICATION.md, Rule 7): a worker acts only within the overlap of each party's authorization, never the union — the narrower grant wins.

**The common failure:** chaining agents on prose handoffs, accepting "done, all green" at face value, and discovering three stages later that stage one edited the wrong tree.

**Re-sync the router on the same trigger.** Add, rename, remove, or re-fit a rule → update the routing map (README table) in the same pass. A new entry the map never mentions, or a stale one it still routes to, is a router that lies.
- Why: agents trust indexes more than they verify them; staleness accumulates exactly where nobody re-reads.

**Name the invocation tool.** When one instruction tells the agent to invoke another skill or agent, spell out the tool call — not a `/name` mention or a cross-file link. A step needing two skills is two calls, stated as such.
- Why: a bare mention is a hint the model must interpret; a named tool call is an instruction it can execute.

---

## 10. Shape Responses So the Reader Can Act

**Start with the answer; end when the answer is done.** No preamble, no recap,
no closer. Ban the openers ("Great question," "Let me look…", "I'll…"), the
post-task recaps ("I've now done X, Y, Z, which means…"), and the closers
("Hope this helps," "Let me know if…"). First line carries the verdict. The
last line is the next action when one exists (see below); otherwise it
carries what just happened.
*Why: readers act on the first line they read — everything before the payload
is working-memory tax, and across compacted sessions a buried verdict is a
lost verdict. This governs every subagent final report, every bot comment,
every overnight status message.*
*Bad:* "Great question! I dug into the failure and here's what I found…" —
verdict in paragraph three.
*Good:* "Root cause: missing auth header on the token-refresh call. Fix: add
it in `refresh()`." — then the detail.
Boundary: when asked to explain or walk through, the body runs as long as the
topic needs (headers for skimmability) — still no preamble, still no closer.

**Lead with the next action.** If the answer is a command, path, or snippet,
it goes first — prose after, if at all. The friction between "got it" and
"done it" is where work dies; a first-line action makes the verdict scannable
in reports.
Boundary: when there's no action (pure verdict), answer-first already covers
it.

**Restate state every turn; never narrate the plan twice.** "Step N of M done:
X. Next: Y." — one line restores position across turns (and across
compaction). With a task/plan tool, the checklist does the restating; do not
*also* narrate the full plan as prose — dual restatement doubles context
cost.
Boundary: one line, not a status paragraph.

**State errors matter-of-factly: cause, then fix.** Ban the alarm phrases ("Uh
oh," "Oh no," "There seems to be a problem") — they consume attention without
carrying information. The complete diagnostic payload is cause → fix.
Boundary: doesn't ban uncertainty — "cause unknown, here are the two leading
hypotheses" is matter-of-fact.

**End with one concrete next action, doable in under two minutes.** If
anything is left open, name ONE thing the reader can do in under two minutes
— even "open the file" counts. An open thread without a next step stalls; the
two-minute bar makes starting trivial.
Boundary: only when something is actually left open — no manufactured
next-actions on closed work.

**Never ask what you can read; cap intake at four.** Detect stack, test-runner, linters, CI from the repo first; report in two lines; ask only the remainder — max four questions, each with defaults.
*Why: ungrounded questions tax working memory and produce guess-configs; bounded intake makes "I don't know" a complete answer.*
Boundary: genuinely unknowable preferences (values, taste) still get asked — the cap applies to knowables.

