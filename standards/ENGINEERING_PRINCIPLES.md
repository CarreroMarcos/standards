---
title: Engineering Principles
version: "1.13"
scope: Core engineering principles and practices
last_reviewed: 2026-10-03
consult_when: "When making a judgment call no specific standard covers — 'the rules point both ways', 'this feels over-engineered but I can't say why', 'which principle wins here'."
---

# Engineering Principles

> This reference exists because these principles are counterintuitive enough that memory gets them wrong. When a router sends you here, read the named section and apply its reasoning.
>
> These are decision principles, not a checklist of fashionable patterns. **Core principle:** reason from requirements, critical flows, state and authority boundaries, failure modes, and evidence toward the simplest system that safely satisfies the need.
>
> Where a dedicated standard owns the mechanics, this file states the principle and points at it — one source of truth per topic, so nothing goes stale in two places.

---

## Sections

- **§0. When Principles Collide** — precedence for conflicting rules
- **§1. Design Principles** — DI without frameworks, functions by default, hoist I/O, fakes over mocks
- **§2. Code Readability & Documentation** — comment provenance, dead-code removal authority
- **§3. Refactoring & Modernization** — smallest change, 3-phase deprecation
- **§4. Testing Philosophy** — independent expected values, tracer bullets, property-based testing
- **§6. Change Safety & Decision Discipline** — blast radius, decision records
- **§7. Python Practice** — pointer to PYTHON.md
- **§8. Spec-First Workflow** — for significant work
- **Engineering Decision Flow** — the question sequence for applying all of the above

## §0. When Principles Collide

Several rules here pull in opposite directions by design. Each pair has a defined precedence, so use the relevant pair to resolve the tension. When two instructions appear to conflict, consult the guidance below before choosing a path.

**Pre-registered decisions narrow latitude.** When the project pre-registers decisions and gates (HLD decisions, eval gates with pinned thresholds), execute them as written — the "prefer proceeding to asking" and "keep process proportional" latitude applies only where the spec leaves room. A pinned gate is not a default to be scaled down.

**These are best practices, not laws.** Context decides which rules apply — some rules don't fit certain tasks, and that is expected, not a failure. The quality bar is explicitness: a rule that doesn't fit is set aside *explicitly* — named, with the reason recorded — never silently. A silent deviation is a silent default, and silent defaults are what these standards exist to prevent. "Project conventions win" (README) is the standing form of this: the local pattern overrides the general rule, openly.

**Ask vs. assume.** Ask when the decision cannot be safely resolved later; otherwise state the assumption and continue.

### How to read an exception clause

Most rules here are strong defaults with named exceptions rather than absolutes. Apply each rule according to its purpose and scope:

**Use defaults proportionally** — proportional to the change's significance (blast radius × irreversibility), not its line count. A Protocol wrapping a single class, `asyncio.to_thread` around a 200-byte file read, a rigid model for a payload with no fixed shape, a multi-region deployment for a recoverable internal tool, and a formal spec for a two-line change all add ceremony beyond the rule's purpose.

**Use named exceptions deliberately.** When invoking one, identify the listed exception and explain why it applies. The following categories are unconditional — they apply with full force regardless of proportionality: protecting security (hardcoded credentials, missing auth checks, unsafe model-controlled actions), safeguarding non-idempotent writes with deduplication, preserving authorization boundaries, and grounding claims in executed checks.

State the reason whenever you apply an exception. When the reason clearly does not apply, record that reasoning explicitly and choose the proportional alternative.

### Smallest change vs. fewest elements / reveals intention

**Precedence: scope decides.** "Smallest change" (§6) limits *unrelated* work. Beck's rules #2 and #4 (§1) guide the quality of the work the task requires.

Remove an abstraction your change made dead. Fix a comment your change falsified. Keep a messy function you merely happened to read outside the change. Use the causal test: "did my change create this?"

**For improvements your change didn't cause, blast radius decides.** The purpose of the smallest-change rule is a reviewable diff, so the question is whether the improvement widens the diff beyond the lines you were already touching.

Rename a misleading local variable inside a function you are already rewriting when the rename stays within the touched lines. Give a parameter, method, module-level name, or name with call sites its own task when the rename expands the diff beyond the requirement.

Use the lines in your diff as the boundary for *improvements* rather than your general judgment about quality; required completion — things your change broke or falsified — follows the causal test, not the diff boundary. A rename that stays within the diff is cleanup of your own work; a rename that expands the diff is a separate change.

**The common failures:** leaving behind a comment that now lies or a helper with no callers, and expanding a one-line fix across nine files through opportunistic renaming.

### Rule of Three vs. Contract-First Boundaries

**Precedence: the boundary decides.** The Rule of Three (§3) governs *internal* extraction — noticing similar code and pulling out a shared helper. Contract-First (ARCHITECTURE.md §8) governs *published* seams — a schema, envelope, event, or API that separate consumers depend on.

Use the third occurrence to shape an internal helper. Design a contract before its consumers exist, because a contract's purpose is agreement across consumers rather than discovery from duplicated code. A shared envelope with two known consumers and a third planned is contract design.

**The common failures:** allowing three incompatible ad-hoc formats to emerge while waiting for a third consumer, and promoting an internal helper to a published contract merely because it looks reusable.

### DRY vs. DAMP

**Precedence: the code's job decides.** Keep production logic single-sourced (§1, Beck #3). Keep test scenarios readable top-to-bottom with DAMP (§4), including purposeful duplication where it improves failure diagnosis.

### Define errors out of existence vs. surface failures

**Precedence: the explicit boundary in §1.** Let idempotent operations on valid requests absorb "already done." Surface invalid input, authorization failures, conflicts, destructive-operation failures, and uncertain outcomes. When intent satisfaction is uncertain, surface the uncertainty so the caller can respond accurately.

### Graceful degradation vs. honest failure

**Precedence: the caller's next decision decides.** Degrade only when the degraded result remains a safe and truthful basis for what the caller does next. (Full rule: ARCHITECTURE.md §14.)

An unavailable recommendation service may return "recommendation unavailable" while the core transaction continues. Missing authorization, unavailable authoritative state, a failed write, an unverified security decision, or a result whose correctness cannot be established must not become guessed data or apparent success.

**The common failure:** interpreting "fail softly" as "never return an error." A plausible fallback that causes the caller to proceed on false information is harder to diagnose than an explicit failure.

### Simplicity vs. resilience mechanisms

**Precedence: the failure model decides.** Retries, queues, caches, circuit breakers, replicas, and service decomposition are mechanisms, not architecture goals.

First identify the critical flow, dependency semantics, failure mode, business consequence, and recovery requirement (ARCHITECTURE.md §1). Add the smallest mechanism that addresses the observed or credible failure — credible means observed here, reported in comparable systems, or following from a concrete mechanism, not merely imaginable.

**The common failure:** mechanically adding every resilience pattern to every dependency and creating more failure states than the original dependency had.

### Deterministic software vs. model autonomy

**Precedence: determinism wins when it is sufficient** — full rule in AGENTIC-DESIGN.md §1 "Use Autonomy Only Where It Earns Its Cost."

### Verify everything vs. unavailable checks

**Precedence: report, then distinguish.** "Ground claims in verification" (§6) applies to every available check. When a suite cannot run, behavior is not observable, or the environment is missing, state "I couldn't verify X, because Y" plainly in the summary.

This is a complete and acceptable answer. Use available checks, report unavailable checks, and keep confidence aligned with evidence.

### A principle vs. what this codebase actually does

**Precedence: follow local convention inside the change; record the principle as a proposal.**

These principles describe the shape of a mature codebase. When the package you're editing already has a pattern — dependencies wired a particular way, validation in a particular layer, errors structured a particular way — follow the local pattern, record the improvement opportunity, and describe what fixing it would take.

Why this direction: a diff that introduces a second, better pattern into a package that has one leaves two patterns. The next reader must learn both and guess which applies. Consistency is itself a design property, so make a package-wide improvement through its own task.

Use the security path when the local pattern is actively unsafe — a hardcoded credential, a missing authorization check, an unsafe model-controlled action, a retry on a non-idempotent write, or a divergent implementation of idempotency/dedup-key derivation (two key functions that "must always agree" silently diverging is a correctness bug, and §3 requires one shared function — the §3 exception overrides the local-convention default here). Security rules have no local-convention exception (§6, AGENTIC-DESIGN.md §3); fix the risk or stop the unsafe path.

**The common failures:** silently importing an ideal architecture into one corner of a codebase, and following a bad local pattern without naming the gap. Follow the local pattern and name the gap — "I matched the existing composition root in this package; wiring it the way §1 describes would be a separate change touching N call sites."

### Writing tests vs. running tests

**Precedence: they are different obligations — fulfill both independently.**

*Running* existing checks is verification discipline (§6): run what exists and report what you could not run.

*Writing* new tests is scope (§6, smallest change). Add them where the task asks, where you fixed a bug and want it to stay fixed, or where new behavior is genuinely load-bearing. Keep a one-line change proportionate.

When behavior changed and an existing test does not cover it, state the gap and the reason for leaving it unpinned: "this path isn't covered by an existing test; I didn't add one because X — worth doing if you want it pinned." That satisfies Beck's rule #1 honestly (§1) while keeping the diff proportionate.

---

## §1. Design Principles

### Deep Modules

**Give modules a smaller interface than their implementation.** A shallow module forces every caller to learn the internals, because its interface adds a layer without hiding complexity.

**The test:** can the caller use the module correctly without understanding its internals? Deep modules hide significant complexity behind a small, minimal surface (Ousterhout). Favor meaningful responsibility over a module that does one trivial thing or exposes every internal knob.

**The common failure:** extracting a helper whose interface is as long as the code it replaced. The complexity moved while the caller's burden remained.

### Information Hiding

**Encapsulate design decisions likely to change** — data structures, external-service interactions, persistence mechanics, policy implementation, and format details (Parnas). Give each module ownership of one design decision so callers depend on the decision rather than its implementation.

Where a fact has one authoritative owner, make that ownership visible in the design. Other modules may consume or derive views of the fact without independently redefining its meaning.

**The common failure:** information leakage where two modules both depend on the same low-level detail — a shared magic number, response shape, persistence convention, policy rule, or file path. Every change then requires locating and updating both dependencies.

### Pull Complexity Downward

**Handle edge cases inside the module when the module has the context to resolve them.** Every edge case handled by N callers multiplies into N implementations with varying quality. Centralize the decision where its context is strongest.

Provide sensible defaults so the 90% case works with zero configuration. Expose behavior the caller legitimately needs to observe or control, including logging, error classification, cancellation, policy outcomes, and compatibility decisions. Hide mechanics while exposing decisions.

### Define Errors Out of Existence (bounded)

**Eliminate an error state through API semantics when valid intent remains clear.** An idempotent delete that succeeds whether or not the item exists removes a branch from every caller. A `getOrCreate` that handles the race internally removes a retry loop from every caller.

**The boundary:** surface invalid input, authorization failures, conflicts, potentially destructive operations, and uncertain outcomes. Let idempotent operations on valid requests absorb "already done." Preserve enough information for the caller to determine whether its intent was satisfied.

**The common failure:** returning success for a semantically failed operation. The caller builds on false success and the failure surfaces three layers later, untraceable.

### Dependency Injection over Singletons

**Instantiate shared resources at a composition root and inject them** — connection pools, clients, clocks — into the code that needs them. Global singletons couple every module to the same concrete implementation and make tests order-dependent and non-parallelizable.

**Scope: inject state, not functions.** Apply this to dependencies that are stateful, externally observable, or need substituting in tests — pools, HTTP and message clients, clocks, random sources, and feature-flag readers. Keep pure stateless helpers as module-level functions; wrapping one in a class solely for injection adds the ceremony this principle is meant to prevent.

**Inject the concrete type until substitutability earns an interface.** Introduce a Protocol or ABC when there is more than one real implementation, a test double the real type cannot provide, or a boundary you are deliberately hiding (§1). Let the interface reveal a meaningful seam rather than mirror one concrete class one-to-one.

**The common failure:** "it's just one logger, I'll make it a singleton." Then every test that touches logging depends on global state, and tests cannot run safely in parallel because they pollute each other's captures. The opposite failure is a Protocol per dependency and an abstract factory to assemble them, which is harder to follow than the globals it replaced.

**DI without frameworks.** A lightweight service registry — register factories at the composition root, acquire instances with automatic cleanup and health checks — gives inversion of control with no decorators, no global state, and no signature mangling. Decorators that rewrite signatures defeat type checkers and confuse readers; explicit parameters keep the dependency graph visible and swappable.

### Functions by Default; Classes Earn Their Keep with State

**Default to functions.** Reach for a class when there is meaningful internal state, behavior that depends on that evolving state, a clear domain model, or genuine polymorphism. A class with two methods where one is `__init__` is a function in costume — and classes accumulate hidden shared dependencies that every method silently uses, while functions take dependencies as explicit parameters.

Subclass only for code reuse, never for volatile taxonomies — stable closed taxonomies (AST nodes) may use inheritance. Modeling real-world categories (`Dog(Animal)`) breaks the day the requirements change; protocols and composition survive it.

**The common failure:** stateless classes as ceremony — harder to test, harder to compose — and deep hierarchies that hide behavior across ancestors.

### Beck's Design Rules (priority order)

**Evaluate every change against these four rules, in this order:**

1. **Passes the tests** — it works as intended. Without this, nothing else matters.
2. **Reveals intention** — the code communicates its purpose to a reader who's never seen it before. Naming, structure, and comments — the why, not the what — serve this rule.
3. **Single-source production logic** — state production logic once. Test code follows DAMP (§4). The Rule of Three (§3) governs when to act on duplication.
4. **Fewest useful elements** — keep classes, methods, services, configuration, and abstractions that serve the three rules above.

**Scope:** these rules judge the change you are making — the code you wrote or touched. Apply Rule #4 to elements your change made unnecessary; treat unrelated surrounding code as its own task. See §0.

**The common failure:** optimizing for #4 at the expense of #2. Over-abstraction hides intent behind indirection. An extra method that makes code self-documenting is better than a clever abstraction that requires three jumps to understand.

---

## §2. Code Readability & Documentation

### Optimize for Human Readability

**Code is how you tell another programmer what you want the computer to do.** The computer doesn't need readability — the next human does.

Optimize for the reader who arrives at 2 AM with a pager alert and five minutes to determine what the system intended, what actually happened, and where the relevant decision lives.

### Naming Conventions

**Use names that immediately clarify purpose and let readers understand intent at the call site.** Choose domain-accurate, consistent terms. Distinguish similar operations explicitly: `getOrderById` vs. `getOrderByReference`; give `fetch` and `retrieve` a precise qualifier when the key matters.

Use different terms for concepts with different authority or semantics. A recommendation is not a decision. A producer is not necessarily the durable writer. A request accepted for processing is not the same as an operation completed.

**The common failure:** choosing a name that's accurate-but-vague. `processData` is accurate for everything and communicates nothing. A longer name that disambiguates (`normalizeAndValidateOrderPayload`) is better than a short name that could mean anything. Developers over-abbreviate far more often than they over-lengthen — keep domain-meaning names ≥3 letters so the call site reads as a sentence; conventional shorts (`i`, `x`/`y`, `e`, `id`, `db`) are fine. The rule targets cryptic abbreviations, not established shorthand — judge by whether a new reader can expand the name.

### Contextual Comments

**Let code express the obvious behavior.** Use comments for the **why**: context, design decisions, constraints, invariants, and non-obvious trade-offs.

When you write a comment, ask: "What would a reader learn from this line?" Keep comments that add context and remove comments that add none.

When you change the code, update any affected comment. A current comment gives the reader accurate context; a falsified comment actively misleads. This is part of the edit, and fixing it follows the smallest-change rule (§0).

**The common failure:** adding a comment to explain mechanics the code should express. Improve the code with a well-named method, and reserve comments for decisions the code cannot express.

### Provenance of Rationale

**A comment explaining *why* is only as trustworthy as the source of the explanation.**

Do not invent rationale the evidence does not support — plausible-sounding optimization claims, speculative architectural history, or authoritative explanations with no traceable basis. AI-assisted authorship amplifies this failure mode: the explanation reads confidently and cites nothing checkable.

When the reason is not traceable to observable behavior, a documented constraint, an explicit decision record, or direct project guidance, omit the comment rather than inventing one. Absence of rationale is preferable to speculative rationale.

**Scope: this governs rationale presented as established fact.** Model-generated inference is allowed when it is labeled as inference and paired with cited evidence — "the build failed because the migration lock timed out (evidence: check-run X, log lines 40–52)" — never as an authoritative explanation. What is forbidden is unlabeled speculation masquerading as a verified reason (AGENTIC-DESIGN.md §5: model output is evidence, not authority).

**The common failure:** `// Legacy compatibility` with no linked ticket, no observable constraint, and no decision record — or `// Parallelized for performance` when the actual reason was an upstream timeout. Both read as established fact; neither can be verified.

### Documentation Is a Maintained Interface

**Treat documentation that people or tools depend on as part of the interface:** repository entry points, setup and verification commands, public contracts, compatibility notes, and consequential design decisions must remain aligned with the system they describe.

Keep one owner for each documented fact. A README routes readers to an authoritative contract or standard rather than restating it and creating a second version that can drift.

An append-only decision log (`DECISIONS.md`) is binding authority, not notes: rulings recorded with date and scope constrain later work the way a pinned spec does — execute them, don't re-derive them.

**The common failure:** updating behavior while leaving a plausible but stale command or contract in the documentation. The next maintainer follows it, and the documentation turns a known change into a delayed failure.

---

## §3. Refactoring & Modernization

### The Rule of Three

Use the third occurrence to shape a reusable abstraction. Duplication is often cheaper than the wrong abstraction (Sandi Metz).

**Why three:** the first occurrence is just code. The second suggests a pattern but could be coincidence. The third confirms the pattern and reveals the shape of the right abstraction — because by the third instance, you've seen enough variation to know which parts are stable and which change.

**The common failure:** extracting after the second occurrence because "I can see the pattern now." Two instances suggest a pattern; the third reveals whether the abstraction fits or needs to bend in an unexpected direction.

Use three concrete instances as the default evidence threshold. When you have two, ask: "Have I seen three concrete instances, or am I predicting the third?" If predicting, preserve the duplication until the third instance appears.

**Scope for this rule.** The Rule of Three trades a maintenance cost — duplication — against a design risk — the wrong shape. Use an earlier abstraction when duplication threatens correctness or security:

* **Published contracts** — a schema, message envelope, event shape, or API consumed by another team or service. Designed before consumers exist, by agreement rather than observation; Contract-First (ARCHITECTURE.md §8) governs instead. See §0.
* **Security-sensitive logic** — authentication, authorization checks, signing, secret redaction, input sanitization. A second copy is a second thing to get wrong and a second thing to forget when patching. One implementation, from the first duplication.
* **Logic that must stay behaviorally identical** — idempotency-key derivation, fingerprint and dedup hashing, serialization formats, anything where two implementations silently diverging is a correctness bug rather than an inconsistency. If "these must always agree" is a requirement, express it as one function.

Ordinary maintenance concerns remain subject to the three-instance threshold. The exceptions above apply when duplication threatens correctness or security.

**Applying the exceptions: ask whether the logic must stay the same.** Treat two authorization checks that merely resemble each other as ordinary duplication. Extract two checks that enforce the same rule when independent updates would create a vulnerability.

"Sort of similar" is the signal to answer that question explicitly. If a future change would have to touch both to stay correct, treat them as the same logic. If a future change could reasonably touch one independently, preserve separate implementations; merging them would create a branching helper and premature abstraction.

### Incremental Modernization (Strangler Fig)

Prefer the Strangler Fig pattern: build new functionality alongside the legacy system, route traffic incrementally, and decommission the old system when the new one is proven. Make each step independently deployable and revertible.

Recommend a full rewrite when incremental migration is demonstrably infeasible *or* demonstrably worse. Support either recommendation with a documented migration plan, rollback or forward-fix plan, data plan, and operational plan.

"Worse" requires evidence. Legitimate grounds include: the runtime or framework is end-of-life or unpatchable; the existing architecture cannot represent an invariant the system is now required to hold; or running both systems in parallel would cost more than the rewrite, with an estimate of both. Base the decision on operational and economic evidence rather than code aesthetics, test quality alone, fashion, or an unsupported claim that the rewrite will be quick.

Use a high bar because this decision is unusually prone to motivated reasoning. State the comparison explicitly and have someone independent check the arithmetic (§6).

**The common failure:** treating the old code's mess as sufficient rewrite evidence. Fresh starts inherit the constraints that produced the mess — deadlines, requirements, team knowledge — and lose accumulated bug fixes. Compare the proposed system with the old system's actual current state.

### Dead-Code Removal Is a Separate Authority

Identifying code that appears unused and removing it are different decisions with different evidence bars.

**Observe freely; remove only with proof.** Stating "this appears unused, and here is what I checked" is always safe. Deleting it requires deterministic proof that no execution path reaches it — or explicit human confirmation.

Lack of observed execution is not proof of non-use. Code that looks dead in local analysis may be a platform fallback, a CI-only branch behind an environment variable, a hook referenced by external config, a dynamically loaded extension point, or a compatibility shim that activates under conditions not yet reproduced.

When flagging suspected dead code, state what signals suggest it is dead, what references were checked, and what would need verification to be certain. The default posture for infrastructure, scripting, and governance code is observe-only.

---

## §4. Testing Philosophy

### Test Observable Behavior

**Test through stable public interfaces where practical.** Keep tests coupled to implementation details only when the coupling protects a deliberate invariant; private methods, internal state, and call-order assumptions otherwise lock in incidental structure.

For pure, complex, or security-sensitive internal logic, focused unit tests of internal components are acceptable when they improve confidence without locking in structure.

For critical flows (ARCHITECTURE.md §1), verify meaningful failure and recovery behavior as well as the happy path. A fallback, retry policy, recovery mechanism, or degraded path that has never been exercised is an assumption, not evidence.

Agentic behavior uses evaluations in addition to conventional tests (AGENTIC-DESIGN.md §7). Deterministic invariants around the agent still receive normal automated tests.

**The common failure:** testing private methods solely to achieve "coverage." That tests implementation rather than behavior, so safe refactoring breaks the test while behavior remains unchanged. Test behavior through the public seam whenever it provides equivalent confidence.

### Hoist Your I/O

**Push I/O to the top level; keep the decision-making core pure** — network, filesystem, console, clock. A pure function needs no mocks, no fixtures, no event loop — just inputs and expected outputs. This is the highest-leverage testability rule: it *removes* the need for most mocking rather than improving it.

For I/O-sequenced orchestration (fetch → decide → act, each step depending on the last), a single fake at the boundary is the 90% version of this rule: hoist what's cheap (pure builders, key computation, output validation) and test the orchestrator against one fake client. A full pure-core restructure that adds indirection without adding testability is ceremony, not compliance.

### Mock Only External Boundaries; Prefer Fakes

**Mock (or fake) only at the boundary** — network, database, clock, filesystem, third-party APIs. Never mock your own internal logic. Prefer in-memory fakes with real semantics and assert outcomes, not interactions. Mocking internals couples the test to the implementation: every refactor breaks tests without breaking behavior, which trains the team to stop refactoring.

**The common failure:** mocks that let generated code "pass" while asserting nothing about outcomes. AI-authored tests over-mock relative to human-authored ones — fakes with real semantics are the antidote.

### Property-Based Testing for Domains with Properties

**Where the domain has *properties*, use property-based testing** (Hypothesis) — round-trips (encode∘decode == identity), invariants (sorted output is ordered), equivalence (optimized implementation == reference implementation). Example tests check the cases you thought of; property tests check the ones you didn't: off-by-ones, empty inputs, unicode, boundary lengths. Keep concrete example tests alongside; don't use it where the assertion would re-implement the function.

### Clear, Complete, and Concise

**A test body contains everything needed to understand the test** — setup, action, assertion — without irrelevant distractions. A reader understands what behavior is being verified without opening any other file.

### Structure

**Make setup, action, and assertion unmistakably clear.** Use explicit Given-When-Then labels when they improve readability. Let a three-line test that reads top-to-bottom speak for itself.

**Prefer organizing by behavior over organizing by method.** A grouping named for a situation — `class TestWhenReleaseIsAwaitingApproval` — is usually more useful than one named for a function, because the situation is what a reader is looking for when a test fails. In pytest this is a preference about naming and grouping, and module-per-component with behavior-descriptive test names achieves the same thing. Let fixture scoping influence layout when appropriate.

The test that matters: does the test's name tell you what broke, without opening it?

### DAMP over DRY (with limits)

**In tests, favor Descriptive And Meaningful Phrases over aggressive deduplication.** Use purposeful duplication when it keeps a test readable top-to-bottom, because tests are read when they fail and the reader needs to understand the full scenario quickly.

Extract helpers when they express stable domain concepts (`createTestUser`, `seedOrderFixture`) or centralize risky setup — credentials, database connections, complex environment. Centralize opaque fixtures, credentials, and complex environment setup.

**The common failure:** extracting a test helper that six tests share, where one test needs a slightly different variant, and the helper grows conditional branches to accommodate it. At that point, the helper is harder to read than the duplicated version would have been — and changing it risks breaking five other tests. The DRY principle that serves production code works against test code.

### Independent Expected Values

**Compute a test's expected result from a source independent of the implementation under test.** Deriving the expected value from the same logic being tested proves only that the code agrees with itself.

A hand-computed value, a trusted reference implementation, or a pinned fixture from an independent source establishes correctness; restating the algorithm inside the test does not.

**The common failure:** testing a slug generator by re-implementing the slugify logic inline in the test. A genuinely wrong algorithm passes its own test every time.

This matters more when an agent writes the test. A tester that reads the builder's implementation inherits its bugs — the "misguidance effect" — so agent-authored tests are spec-sourced, never diff-sourced: expected values from the requirement, not from the code under test. When no independent spec exists, pin observed behavior explicitly as characterization — labeled as observed, not as verified-correct.

**Carve-out: model-generated prose has no independent expected value.** There is no hand-computable "correct diagnosis" for a model's output. Test the deterministic invariants around the model call instead — pinned inputs, structural output validation, the fencing and redaction that bound it — and cover the behavior itself with evaluations (AGENTIC-DESIGN.md §7), which exist precisely because conventional tests cannot judge it. Verify eval pins before scoring: a mutated capture feeding the driver produces wrong verdicts, not failed tests. Budget the eval run — checkpointed resume, the assumed parallelism stated beside any wall-clock claim, the minimal deciding subset — so a re-run is a decision, not an endurance test.

### Tests Are Evidence, Not the Target

**An agent that learns the test suite games the test suite.** The dominant failure mode is under-specification, not test editing: the fix passes the shown test and fails an unseen sibling — test-shaped compliance rather than correct behavior.

Countermeasures: red before green, with the failing test committed; lock test paths so the implementer cannot edit them; split writer and reviewer into separate sessions; keep hold-out checks the implementer never saw.

**The common failure:** the implementer "fixes" the test to match the code and calls it green.

Agent-workflow mechanics: `WORKFLOW.md` (Phase 4).

### Tracer Bullet

**For a multi-unit task, write and pass one test exercising the smallest meaningful path end to end** before implementing individual units in isolation.

Integration and wiring problems — imports, plumbing, environment, configuration — surface immediately instead of after N isolated units turn out not to connect.

---

## §6. Change Safety & Decision Discipline

### Smallest Change

Make the smallest change that meets the stated requirement. Keep rewrites, broad renames, reformatting, dependency upgrades, and public API changes as separately scoped work. When the requirement itself calls for the broader change, that scope is the task — not an exception to this rule.

Give meaningful cleanup its own task, review, and diff. Mixed-purpose diffs hide regressions and make review difficult; a reviewer seeing "fix bug + rename variables + upgrade dependency" cannot identify which change caused a failure.

**Scope this rule carefully.** It limits *unrelated* work while covering the full extent of the requested work. Include a comment your edit falsified, a helper your edit orphaned, a test required by changed behavior, and an error path introduced by a new branch. Give a function you merely read, disliked formatting, and an old dependency their own task.

Use the question "did my change create this?" to distinguish required completion from general improvement. A lying comment or uncalled function left by your change makes the change incomplete. See §0.

**The common failure:** treating messy surrounding code as part of the current fix. The cleanup can introduce a regression and couple its revert to the bug fix. Separate diffs support separate review, verification, and reversal.

### Prefer Reversible Change

Prefer frequent, incremental changes whose effect can be stopped, rolled back, disabled, or forward-fixed without reconstructing the old system under pressure.

Reversibility does not mean every change needs a feature flag or automatic rollback. It means the recovery path is understood before a consequential change is made.

For irreversible or difficult-to-reverse operations — destructive migrations, external side effects, data deletion, contract removals — raise the review bar and define the recovery or forward-fix strategy explicitly.

**The common failure:** treating deployment success as the point of no return and designing rollback only after production behavior diverges from expectations.

### State Assumptions Explicitly

State assumptions that affect the design.

Ask when the decision cannot be safely resolved later; otherwise state the assumption and continue. "I assumed X because Y — correct me if wrong" gives the decision-maker a chance to correct the path.

Do not manufacture certainty from incomplete evidence. Distinguish:

* verified fact;
* explicit requirement;
* architectural decision;
* reasonable working assumption;
* unresolved dependency.

This distinction matters particularly when an AI agent is doing the analysis (AGENTIC-DESIGN.md §5).

### Preserve Backward Compatibility

Preserve backward compatibility by default.

Version or deprecate published contracts deliberately, with a migration path and a defined compatibility policy. Treat a breaking change to a public API, schema, durable data representation, event, or other cross-team contract as an explicit decision.

Backward compatibility is not an excuse to accumulate accidental behavior forever. Remove obsolete behavior through an intentional migration rather than silently breaking consumers or preserving ambiguity indefinitely.

**Evolve in three phases: warn → document → remove.** (1) Warn — the deprecation message names the replacement and the removal version, and points at the *caller's* code. (2) Document — changelog entry in the same commit. (3) Remove in a major version, after a real warning window. Prefer additive change: new parameters arrive with defaults and keyword-only, so existing callers keep working. Never silently change what an existing argument *means* — changed semantics break downstream silently, which is worse than a loud rename.

**Changelog as contract.** Keep-a-Changelog sections (Added/Changed/Deprecated/Removed/Fixed/Security), one entry per user-visible change, updated in the same commit as the change, curated by hand. Users decide whether to upgrade by reading the changelog, not the diff; auto-generated commit lists are noise, curated entries are a migration guide.

### Validate Changes

Validate changes with the repository's formatter, static analysis, tests, build, and other applicable project checks.

For architecture changes, validation may additionally require contract tests, migration tests, failure injection, load tests, recovery exercises, or other evidence tied to the actual risk.

Report the checks you ran and the checks unavailable in the environment. Describe partial verification precisely.

### Ground Claims in Verification

Ground claims about passing tests, fixed vulnerabilities, correct behavior, compatibility, performance, and recovery in executed or directly observed evidence.

| Temptation                                        | Verification practice                                                                          |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| "I ran the tests last time, they should pass"     | Run them again. Uncommitted changes, environment drift, and flaky tests invalidate prior runs. |
| "The change is trivial, tests can't fail"         | Run the relevant checks; small changes can still break behavior.                               |
| "I'll verify after I finish the next part"        | Verify the current part now so later work builds on evidence.                                  |
| "The test suite is slow"                          | Run the relevant subset. Slow plus verified beats fast plus guessed.                           |
| "The architecture should handle this failure"     | Exercise the failure or state that the recovery path remains unverified.                       |
| "There is no test suite / it isn't runnable here" | State exactly what is unavailable and which available checks you ran.                          |

An agent's report is a claim, not proof. Verify against the real state — actual files, actual test output — never the implementer's summary. The verification names self-contained commands, shows raw output rather than narrating it, and ends in a clear pass/fail. "I already checked this" is not "here is how you can check this."

Do not mistake developer satisfaction for developer productivity. Measure AI assistance net of verification burden: experienced developers forecast speedups and report feeling faster while measuring slower (METR RCT, July 2025). Count review time, rework, and bug load in the ledger before claiming a speedup.

**When a check genuinely cannot run** — no suite exists, the environment is missing, or the behavior needs live infrastructure — report the limitation directly.

"I couldn't verify X because Y" in the summary satisfies this rule completely.

Run every available check and name unavailable ones: "unit tests pass; I could not exercise database recovery without a live Postgres" is useful. Describe the result as partial verification when only some checks ran. See §0.

### Parameterized Argv

When generating code that executes external commands, use parameterized argv arrays and validated arguments.

Avoid constructing shell commands from interpolated values. Treat environment-variable manipulation, command resolution, and shell built-ins as security-sensitive.

### Secrets

Access secrets through centralized, typed accessors or the project's approved secret mechanism — one controlled boundary rather than ad-hoc environment reads scattered through the code.

Keep secrets out of outputs and source control. Keep authentication and authorization checks enabled. Make security-sensitive telemetry explicitly reviewed.

Do not expose secrets to an AI model, agent context, tool result, log, or trace merely because that surface is internal.

Credential mechanics: `SECRETS.md`.

### Database Changes

For database changes, document:

* **Migration safety:** how the migration runs while old and new code may both be live.
* **Rollback or forward-fix strategy:** the recovery path for a partially applied migration.
* **Locking and performance impact:** the effect on high-traffic tables and the online execution strategy.
* **Data-backfill considerations:** how existing data is populated when the migration adds or changes state.
* **Compatibility window:** when applicable, how old and new readers/writers coexist.
* **Verification:** how the migrated data and application behavior are proven correct.

For consequential migrations, correctness takes precedence over making rollback artificially easy. Some data transformations move forward through a verified repair rather than reversing through a lossy migration.

---

## §7. Python Practice

Python-specific mechanics live in `PYTHON.md` — tooling, style, typing, async discipline, errors, packaging, and performance. This section states only the principle: the sections above state principles, not implementations — the examples are Python because that is the working language; translate the mechanics when the stack differs. The failure modes are easy to write, hard to see in review, and often invisible until load.

## §8. Spec-First Workflow (for significant work)

The development-workflow mechanics live in `WORKFLOW.md` (seven phases); the ticket-to-merge loop lives in `DEV-LOOP.md`. This section states the spec-first principles behind them.

For significant features or ambiguous work, reason in this order:

1. **Specify** — define intent, required outcomes, acceptance criteria, and explicit non-goals.
2. **Clarify** — identify assumptions, ambiguities, consequential decisions, and unresolved ownership.
3. **Map critical flows** — identify the important end-to-end paths and authoritative state they read or change.
4. **Identify boundaries and failure modes** — map ownership, trust, dependencies, failure consequences, and recovery needs.
5. **Choose the simplest sufficient architecture** — select components and isolation only after the preceding constraints are known.
6. **Define contracts** — schemas, behavior, compatibility, failure semantics, and observability at published seams.
7. **Decompose** — create atomic, testable tasks with clear acceptance criteria and ownership.
8. **Implement** — Red-Green-Refactor or the project's equivalent verified development loop.
9. **Validate** — verify acceptance criteria, contracts, important failure paths, migration/recovery behavior, and operational evidence appropriate to the risk.

**State semantics** (ARCHITECTURE.md §4 "State Has Semantics"): source of truth, ownership, durability, consistency, concurrency, ordering, retry and replay, identity and deduplication, retention, recovery.

This order is deliberate:

**requirements → critical flows → state and authority boundaries → failure modes → simplest architecture → contracts → implementation → production evidence**

Do not start from a preferred technology and reverse-engineer requirements that justify it.

Spend the reasoning budget where the leverage is: planning and review get the strongest model available; execution gets a cheaper one. Pin the model to the role, not to prestige.

Assign stable requirement IDs and link them to verification where the work is formal enough to benefit from traceability.

**Use whatever requirement format this project already uses.** If the repository's specs, tickets, or docs have a convention, follow it — an agent introducing a new notation nobody else writes creates ceremony the team did not ask for and will not maintain.

EARS syntax (`WHEN <event>, THE SYSTEM SHALL <response>`) is a default only when authoring formal requirements and no convention exists. If existing work tracks requirements by ticket ID, use ticket IDs.

Absent a convention and for anything short of a formal spec, a short statement of intent plus the assumptions behind it is the right artifact.

### Prefer the thin vertical slice

When the end state is large, make the first deliverable prove the riskiest mechanism end to end rather than completing one architectural layer in isolation.

Choose the risk being retired deliberately.

For a stateful system, that may be persistence and recovery: prove that authoritative state survives restart and resumes correctly.

For an integration-heavy system, it may be one contract-valid request through the real boundary.

For an agentic system, it may be one bounded workflow with real tool authorization, state verification, and evaluation rather than a large collection of disconnected prompts.

The principle is not "always build persistence first." It is **prove the hardest-to-retrofit assumption while the architecture is still cheap to change.**

### Identify which dependencies are real blockers

Use fixtures, fakes, or contract tests for work that can proceed independently.

Classify work requiring an unconfirmed authentication pattern, unresolved authority boundary, unowned schema field, unavailable production dependency, or unprovisioned datastore as blocked only when proceeding would require inventing a consequential decision.

Before building across a boundary, know:

* who owns the dependency;
* what contract is authoritative;
* which decision remains unresolved;
* which test or fixture proves the seam;
* whether useful work can proceed without guessing.

This keeps integrations grounded in reviewed behavior.

### What counts as "significant"

The full workflow is for work with at least one of these properties:

* It creates or changes a contract another team or independently deployed service consumes.
* It changes persisted state, a schema, consistency semantics, or a migration path.
* It changes a critical flow's reliability or failure behavior.
* It touches authentication, authorization, secrets, trust boundaries, or privileged operations.
* The agent takes actions beyond read-only analysis, or the change expands what an agent may do.
* It is irreversible or expensive to reverse.
* The requirement is genuinely ambiguous — reasonable engineers would build materially different systems from the description.

**For work outside these categories, proceed directly.** A medium-sized but well-understood change — a new endpoint over an existing model, a bounded refactor, a handler following an established pattern — needs a clear description of intent and appropriate tests, not architecture theater.

Scale requirement IDs, failure analysis, rollback planning, and documentation to the significance of the change.

**Scale the artifacts and prefer proceeding to asking.** Between "one-line fix" and "new cross-team contract," use a short statement of approach and assumptions, then implement.

Reserve stopping for consequential decisions involving product intent, security, state ownership, data migration, compatibility, infrastructure, or irreversible external effects. State an assumption and continue when it can be safely resolved later; stop rather than silently inventing a decision that changes the system's contract or authority model.

**For small, well-defined changes:** use the smallest-change rule (§6) and keep process proportional to the work.

### End the Spec with an Acceptance Contract

Acceptance criteria are checkable pass/fail criteria, not prose. Exit codes, golden hashes, schema validation — a verdict backed by a command someone else can re-run.

Fixture realism is a contract duty. A thousand passing tests against fake fixtures can mask a bug that only the real dependency exhibits; the contract names which checks run against the real thing.

**The common failure:** acceptance criteria written as prose nobody can execute, so "done" is whatever the implementer felt.

Plan-level mechanics for agent work: `WORKFLOW.md` (Phase 3).

### Independent Review for Significant Work

Self-review shares the author's blind spots. For significant work (per the criteria above), have the plan or spec checked by a reviewer with no authorship context — a separately dispatched agent, or a human reader — before implementation begins.

The reviewer verifies the plan against the spec and the actual current state of the system, using the project's review vocabulary. Blocking findings are fixed before proceeding; non-blocking findings are recorded in the plan, not silently dropped.

If the independent review cannot be completed, record that explicitly and get a decision before proceeding without it. "No review happened" must never be silently equivalent to "review passed."

**Scale the review to the work.** Small-but-significant changes (a ~200-line feature that trips a significance trigger — a trust boundary, a new model-directed step) get a lightweight independent check, not the full spec review: one reviewer, one pass, scoped to the significance delta (the trust/autonomy boundary), not the whole plan. Significance decides *whether* review happens; size decides *how much* review.

---

## Engineering Decision Flow

When the answer is not obvious, reason in this order:

1. **What outcome is actually required?**
2. **What is explicitly out of scope?**
3. **Which flows are critical?**
4. **What state is authoritative, and who owns each decision?**
5. **Where are the trust and compatibility boundaries?**
6. **What important failures can occur, and what is their blast radius?**
7. **What behavior is safe under those failures?**
8. **What is the simplest architecture that preserves those invariants?**
9. **Which published contracts must be defined before implementation?**
10. **Where does model autonomy genuinely add value, if anywhere?**
11. **What evidence will prove the implementation and recovery behavior work?**
12. **What remains assumption rather than verified fact?**

Do not optimize the diagram before answering those questions.

The goal is not the most sophisticated architecture.

The goal is the **simplest system whose correctness, authority boundaries, failure behavior, and operational evidence match the consequences of the problem it is solving.**
