---
title: Architecture
version: "1.0"
scope: Architecture and resilience: critical flows, state semantics, isolation, contracts, degradation
consult_when: "When designing a system or choosing architecture — boundaries, state ownership, failure handling, resilience."
last_reviewed: 2026-09-30
---

# Architecture

## Sections

- **1. Start With Critical Flows and Failure Modes** — reason from what must survive failure
- **2. Minimize Blast Radius** — contain failure domains
- **3. Simplest Sufficient Isolation** — no heavier isolation than the failure warrants
- **4. State Has Semantics** — ownership and consistency boundaries
- **5. Data-Access Discipline** — how data is read and written
- **6. Dependency Contracts First** — timeouts, retry, and dependency interaction
- **7. Worker and Queue Discipline** — background work rules
- **8. Contract-First Boundaries** — schemas before code at published seams
- **9. Structured Exception Hierarchies** — typed errors per domain
- **10. Match Resource Lifetime to Scope** — no leaks, no premature release
- **11. Typed Configuration, Validated at Startup** — fail fast on bad config
- **12. Trace Released Artifacts to Reviewed Source** — provenance for releases
- **13. Design for Operability** — observe and operate what you ship
- **14. Graceful Degradation** — defined fallback behavior
- **15. Overload Protection, Rate Limiting & Circuit Breakers** — shed load, don't amplify it


## 1. Start With Critical Flows and Failure Modes

Design from what the system must preserve, not from a diagram of components.

For significant systems, identify the business-critical flows first:

* what outcome the flow exists to produce;
* what authoritative state it reads or changes;
* which dependencies participate;
* what must remain available;
* what may degrade;
* what failure would be unacceptable.

Then identify important failure modes for those flows. For each meaningful failure, understand:

* **cause or dependency** — what can fail;
* **impact** — what outcome becomes incorrect or unavailable;
* **blast radius** — what else is affected;
* **detection** — how the failure becomes observable;
* **safe behavior** — fail, degrade, queue, reject, retry, or stop;
* **recovery** — how correct operation is restored.

Prioritize failure modes by business impact and credible likelihood — credible means observed here, reported in comparable systems, or following from a concrete mechanism, not merely imaginable. Do not engineer every hypothetical failure equally.

Where reliability is consequential, derive measurable objectives such as SLOs and, for durable state where appropriate, RTO and RPO from business consequences rather than inventing infrastructure targets.

**The common failure:** drawing services, queues, and databases first, then retrofitting the actual reliability requirement onto the topology. Architecture starts with the flow and its invariants; components are the implementation.

## 2. Minimize Blast Radius

Design so failures stay contained and preserve unrelated capabilities.

Keep one dependency's outage from taking down unrelated flows. Isolate one module's state from another module's bugs. Keep resource exhaustion, bad deployments, privileged credentials, and expensive workloads from automatically becoming system-wide failure domains.

Blast radius is a design property, not only an infrastructure property. A shared database, shared queue, shared credential, shared agent context, or shared retry policy can couple otherwise separate components.

## 3. Simplest Sufficient Isolation

Start with the simplest architecture that provides the isolation the requirements actually need.

Default toward a modular monolith when one deployment can satisfy ownership, scaling, security, reliability, and release needs. Within a process or deployment, use resource bulkheads where failure coupling is real — for example separate pools, bounded queues, concurrency limits, or worker groups for workloads that should not exhaust each other's capacity.

Feature flags and progressive rollout controls reduce change blast radius; they are rollout mechanisms, not resource-isolation bulkheads.

Introduce separately deployable services when independent scaling, ownership, security boundaries, reliability requirements, technology constraints, or release cadence justify the operational cost of distribution.

**The common failure:** splitting a monolith into microservices for "scalability" before measuring the bottleneck. Distributed systems add network failure modes, partial failure, compatibility obligations, state consistency problems, deployment coordination, and operational overhead. Start modular and split when evidence identifies the need.

## 4. State Has Semantics

Define what state *means* before choosing where to store it.

For shared or durable state, explicitly identify:

* **source of truth** — which representation is authoritative;
* **ownership** — who may make the authoritative decision or write;
* **durability** — what must survive process, host, zone, or regional failure;
* **consistency** — when readers must observe a write and where eventual consistency is acceptable;
* **concurrency** — what happens when multiple actors act on the same state;
* **ordering** — whether event or mutation order is meaningful;
* **retry and replay** — what happens when work is repeated;
* **identity and deduplication** — how the same logical operation is recognized;
* **retention** — how long the state remains valid;
* **recovery** — how authoritative state is reconstructed after failure.

Choose a database, queue, cache, event stream, object store, or workflow engine only after the required semantics are understood.

Prefer one authoritative owner for a fact. Replicas, caches, indexes, read models, recommendations, and derived views must be distinguishable from the authoritative value when the difference affects a decision.

**The common failure:** selecting a datastore because it is already available, then discovering during implementation that the system needed ordering, deduplication, atomicity, stronger consistency, or a single writer that the chosen design does not naturally provide.

## 5. Data-Access Discipline

One session per request or task, closed at the boundary — a session that outlives its scope is a stale read or a leak. Transaction boundaries sit at the request/task scope, not inside helpers; a helper that commits decides the caller's atomicity for it.

N+1 is the classic agent blind spot: a loop that touches a relationship fires one query per row. Load what you iterate — eager-load (`joinedload`/`selectinload` in SQLAlchemy, whatever the ORM calls it) for the relationships the loop actually touches. No lazy loading outside the session that opened it.

Write queries the index can answer: filter on indexed columns, and check the query plan before assuming the ORM generated a sane one. The ORM is a query builder, not a guarantee.

**The common failure:** an agent-written loop over a queryset that looks O(n) and runs O(n) queries — correct on ten rows in dev, a page-load killer in prod.

## 6. Dependency Contracts First

Before adding retries, circuit breakers, fallbacks, queues, caches, or similar mechanisms, define the dependency contract:

* **Timeout budget:** set the total time the caller is willing to wait, including retries, rather than the dependency's response time alone.
* **Retryability and idempotency:** classify which failures are retryable and whether repeating the operation can duplicate side effects.
* **Retry ownership:** avoid uncontrolled retries at multiple layers; identify which layer owns retry behavior.
* **Retry budget:** bound the total attempts or retry volume so a distressed dependency does not receive an expanding wave of retries.
* **Capacity and overload behavior:** define useful concurrency limits, queue bounds, admission control, backpressure, or load shedding where the dependency can be saturated.
* **Cancellation:** define whether abandoned work can and should be stopped.
* **Fallback correctness:** define the fallback's return value and whether it gives the caller a safe basis to proceed.
* **Observability:** emit enough telemetry to show when retries fire, queues grow, admission rejects, circuits open, or fallbacks engage.
* **User-visible failure behavior:** define the user's experience when attempts fail and make the result actionable.

Require deduplication safeguards before automatically retrying non-idempotent writes.

Use randomized exponential backoff for distributed automatic retries where synchronized retries could amplify an outage. Do not retry permanent failures merely because retry infrastructure exists.

Retry what can self-heal; never *blind*-retry 4xx. Retry when the retry changes the condition: 429/5xx/timeouts, one refresh-then-retry on 401, bounded settle on 404-after-write. A 400/403 with no changed condition doesn't self-heal — don't hammer it; retrying auth failures without a changed condition is at best wasteful, at worst a lockout trigger. Honor `Retry-After`; jitter spreads retry timing so synchronized clients don't stampede the recovering service.

**The common failure:** adding a retry loop because "the call sometimes fails" while leaving idempotency, capacity, timeout budget, and failure behavior undefined. Contract-free retries amplify load during outages: the recovering service receives the original traffic plus retry traffic, turning a transient problem into a sustained one.

## 7. Worker and Queue Discipline

One consumer, one queue — route work deliberately (a queue per consumer, or task-level routing where the broker supports it), so a slow consumer never starves an unrelated workload. Know the worker's concurrency model — prefork, threads, or single-process — and set it deliberately; the default is rarely the right size.

Design every job for repeat delivery: workers retry, redeliver, and crash. Make the handler idempotent where the side effects allow it; where they don't (a charge, a sent email), put an idempotency key at the boundary so the repeat is detected, not re-executed. Visibility timeout (or its equivalent) exceeds the maximum task duration; a timeout shorter than the work produces phantom duplicates. Poison messages get bounded retries, then a dead-letter queue — never infinite requeue.

Close what the framework doesn't: one DB connection scope per worker task; transactions scoped to one request or one task. The worker process outlives the work — anything leaked per task compounds.

**The common failure:** a worker that borrows the request's database session and leaks it across tasks, or a visibility timeout shorter than the job — both produce corruption that only appears under load.

## 8. Contract-First Boundaries

Define API schemas at stable service boundaries — OpenAPI, gRPC proto, GraphQL schema, JSON Schema, or the project's equivalent — as the source of truth. Auto-generate client types and validators where the ecosystem supports it. Verify generated artifacts in CI with a clean-tree or drift check. Treat applied database migrations as the authoritative schema history and verify model/migration alignment in CI where applicable.

Return errors in a consistent machine-readable format so clients can distinguish failure types from structured fields rather than parsing human messages.

## 9. Structured Exception Hierarchies

Define one small hierarchy per domain so callers can catch at the precision they need (`except TimeoutException` for retry logic, `except HTTPError` for total failure). Exceptions carry structured context — the relevant objects (request, response), not just text in the message — because structured attributes beat message-parsing.

**The common failure:** a flat `AppError` with everything in the message, forcing callers to string-match to distinguish conditions.

**Design the contract before the consumers exist.** This is the deliberate exception to the Rule of Three (§3): a shared envelope, event shape, or agent-call format is agreed up front with its known consumers, not discovered after three copies appear in the wild. Two known consumers and a planned third is sufficient reason to define a contract. See §0.

**Publishing a contract is a commitment.** Once another team or independently deployed component depends on it, changing it is a compatibility event (§6), not an internal refactor.

Publish the smallest contract that satisfies known consumers. Every optional field added "just in case" is a field someone may eventually depend on. Confirm required behavior with consumers before freezing rather than discovering omissions after implementation.

**Fixtures are a legitimate first deliverable.** When a contract is agreed but implementation is blocked, contract-valid static fixtures can unblock downstream consumers without pretending the service exists. Prefer this to building an integration against unconfirmed assumptions.

**The common failure:** hand-writing client types that drift from actual server behavior, with the missing field discovered in production. Keep one authoritative schema and automate alignment where practical.

## 10. Match Resource Lifetime to Scope

Create expensive-to-construct or pooled resources (connection pools, HTTP clients, models) once per process at startup and hand out references; create request-scoped handles (a DB session checked out of the pool) per request; keep pure values as plain functions. Creating a pooled client per request throws away connection pooling; closing a shared client in a per-request teardown breaks every concurrent request.

**The common failure:** a per-request dependency that constructs — or worse, closes — a process-scoped resource.

## 11. Typed Configuration, Validated at Startup

One typed settings object, built once at startup and passed explicitly — never scattered untyped environment reads. Untyped config fails at 3 AM with a key error deep in a code path; a settings object fails once, at startup, with a precise error naming the variable. Secrets ride as redacted types so they never surface in logs or tracebacks. Credential mechanics: `SECRETS.md`.

## 12. Trace Released Artifacts to Reviewed Source

For software that is packaged or deployed, preserve evidence connecting each released artifact to the reviewed source revision, declared build process, and verification that produced it. Prefer a consistent hosted build and provenance that identifies outputs by digest; strengthen signing and build isolation in proportion to the artifact's threat model. The [SLSA specification](https://slsa.dev/spec/v1.2/) provides a staged model for these guarantees.

A local scratch or documentation repository that produces no released artifact does not need release provenance. It still must not present a locally generated file as an attested or reproducible release.

**The common failure:** treating a successful build on one workstation as proof that the distributed artifact came from the reviewed revision or was produced without unrecorded inputs.

## 13. Design for Operability

A system is not production-ready if its operators cannot determine:

1. what it is doing;
2. whether it is healthy;
3. why an important flow failed;
4. what scope is affected;
5. what action should be taken next.

Critical flows should expose the telemetry required to answer those questions. Depending on the system, that includes:

* meaningful health and readiness signals;
* structured logs;
* metrics tied to user or business outcomes as well as infrastructure;
* distributed traces where a request crosses meaningful boundaries;
* correlation or request identifiers that reconstruct one flow;
* queue depth, retry, rejection, saturation, and degraded-mode signals;
* actionable error classification;
* discoverable ownership and recovery guidance.

Observe outcomes, not only machinery. CPU at 40% does not prove releases are progressing, orders are completing, or an agent is producing valid decisions.

Do not log everything merely because observability matters. Telemetry has privacy, security, cost, and signal-to-noise consequences. Instrument the decisions and flows operators actually need to understand.

**The common failure:** adding logs after the first production incident. If a load-bearing failure can occur without leaving enough evidence to reconstruct it, observability is part of the missing design.

## 14. Graceful Degradation

Preserve useful core behavior when an auxiliary capability fails, but only when the degraded result remains a safe basis for the caller's next decision.

A search outage may leave checkout available. An analytics failure should not normally prevent login. A recommendation engine may return "recommendation unavailable" while the authoritative transaction continues.

Do **not** convert any of the following into stale, guessed, or apparently successful results merely to keep the flow moving:

* missing or failed authorization;
* unavailable authoritative state required for correctness;
* failed writes whose outcome is uncertain;
* schema or contract uncertainty;
* security or policy checks that could not be completed;
* safety-critical or otherwise consequential decisions whose basis is unavailable.

Make degraded mode observable and exercise it periodically when it is important enough to depend on. Rarely used fallback code is still production code.

**The common failure:** returning a plausible fallback that looks authoritative. The user or caller continues with an incorrect assumption, and the original failure becomes detached from the later consequence.

## 15. Overload Protection, Rate Limiting & Circuit Breakers

Protect the system's ability to perform useful work under saturation.

Depending on the actual failure mode, mechanisms may include:

* bounded concurrency;
* bounded queues;
* admission control;
* load shedding;
* rate limits and quotas;
* randomized exponential backoff;
* retry budgets;
* timeouts;
* circuit breakers;
* degraded responses.

Choose the mechanism from the dependency contract and capacity model rather than applying the entire catalog.

Prefer rejecting excess work early and cheaply over accepting an unbounded amount of work that cannot finish. A system that returns some explicit overload errors while preserving healthy throughput is usually safer than one that accepts everything until latency, memory, and retries collapse the service.

Circuit-breaker thresholds, rate limits, queue bounds, and concurrency settings must be based on the dependency's observed behavior or a documented initial assumption that can be measured and revised.

**The common failure:** allowing every layer to queue and retry independently. One user request fans out, queues accumulate, timeouts fire, each layer retries, and protection mechanisms amplify the outage they were intended to prevent.

---

