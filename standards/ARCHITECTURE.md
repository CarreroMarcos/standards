---
title: Architecture
version: "1.6"
scope: "Architecture and resilience: critical flows, state semantics, isolation, contracts, degradation"
consult_when: "When designing a system or choosing architecture — 'we need microservices', 'just add a retry', 'which database' — or anytime the diagram is getting drawn before the failure modes."
last_reviewed: 2026-11-27
---

# Architecture

**Core principle:** reason from what the system must survive, not from a diagram of components — the simplest architecture whose failure behavior matches the consequences of the problem.

## Sections

- **1. Start With Critical Flows and Failure Modes** — reason from what must survive failure
- **2. Minimize Blast Radius** — contain failure domains
- **3. Simplest Sufficient Isolation** — no heavier isolation than the failure warrants
- **4. State Has Semantics** — ownership, consistency, and race-discipline boundaries
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
- **16. Design red flags** — checkable design anti-shapes and idempotent lifecycle operations

## 1. Start With Critical Flows and Failure Modes

**Design from what the system must preserve, not from a diagram of components.**

For significant systems, identify the business-critical flows first:

- what outcome the flow exists to produce;
- what authoritative state it reads or changes;
- which dependencies participate;
- what must remain available;
- what may degrade;
- what failure would be unacceptable.

Then identify important failure modes for those flows. For each meaningful failure, understand:

- **cause or dependency** — what can fail;
- **impact** — what outcome becomes incorrect or unavailable;
- **blast radius** — what else is affected;
- **detection** — how the failure becomes observable;
- **safe behavior** — fail, degrade, queue, reject, retry, or stop;
- **recovery** — how correct operation is restored.

Prioritize failure modes by business impact and credible likelihood — credible means observed here, reported in comparable systems, or following from a concrete mechanism, not merely imaginable. Do not engineer every hypothetical failure equally.

Where reliability is consequential, derive measurable objectives such as SLOs and, for durable state where appropriate, RTO and RPO from business consequences rather than inventing infrastructure targets.

**The common failure:** drawing services, queues, and databases first, then retrofitting the actual reliability requirement onto the topology. Architecture starts with the flow and its invariants; components are the implementation.

## 2. Minimize Blast Radius

**Design so failures stay contained and preserve unrelated capabilities.**

Keep one dependency's outage from taking down unrelated flows. Isolate one module's state from another module's bugs. Keep resource exhaustion, bad deployments, privileged credentials, and expensive workloads from automatically becoming system-wide failure domains.

Blast radius is a design property, not only an infrastructure property. A shared database, shared queue, shared credential, shared agent context, or shared retry policy can couple otherwise separate components.

## 3. Simplest Sufficient Isolation

**Start with the simplest architecture that provides the isolation the requirements actually need.**

Default toward a modular monolith when one deployment can satisfy ownership, scaling, security, reliability, and release needs. Within a process or deployment, use resource bulkheads where failure coupling is real — for example separate pools, bounded queues, concurrency limits, or worker groups for workloads that must not exhaust each other's capacity.

Feature flags and progressive rollout controls reduce change blast radius; they are rollout mechanisms, not resource-isolation bulkheads.

- **Check locality before auth on dangerous endpoints.** An endpoint that can spawn processes, install software, or run shell commands is classified loopback/local-only first, and that check runs unconditionally before any auth check — a leaked token must not be enough to reach it through a tunnel.
  - Why: auth answers "who are you"; locality answers "where are you standing." A token leaked through a tunnel passes auth from anywhere; a loopback-first gate fails it before auth is even consulted.
  - Bad: a process-spawning route guarded by JWT alone, reachable via a forwarded tunnel. Good: the route guard classifies loopback first; non-loopback requests are rejected regardless of token validity.
  - Boundary: fires where the endpoint executes code or mutates the host — ordinary data routes don't need a locality gate. (cheaper-inference/OmniRoute `AGENTS.md:393`, `:395`, Hard Rules 15/17)

Introduce separately deployable services when independent scaling, ownership, security boundaries, reliability requirements, technology constraints, or release cadence justify the operational cost of distribution.

**The common failure:** splitting a monolith into microservices for "scalability" before measuring the bottleneck. Distributed systems add network failure modes, partial failure, compatibility obligations, state consistency problems, deployment coordination, and operational overhead. Start modular and split when evidence identifies the need.

## 4. State Has Semantics

**Define what state *means* before choosing where to store it.**

For shared or durable state, explicitly identify:

- **source of truth** — which representation is authoritative;
- **ownership** — who may make the authoritative decision or write;
- **durability** — what must survive process, host, zone, or regional failure;
- **consistency** — when readers must observe a write and where eventual consistency is acceptable;
- **concurrency** — what happens when multiple actors act on the same state;
- **ordering** — whether event or mutation order is meaningful;
- **retry and replay** — what happens when work is repeated;
- **identity and deduplication** — how the same logical operation is recognized;
- **retention** — how long the state remains valid;
- **recovery** — how authoritative state is reconstructed after failure.

Choose a database, queue, cache, event stream, object store, or workflow engine only after the required semantics are understood.

Prefer one authoritative owner for a fact. Replicas, caches, indexes, read models, recommendations, and derived views must be distinguishable from the authoritative value when the difference affects a decision.

**The common failure:** selecting a datastore because it is already available, then discovering during implementation that the system needed ordering, deduplication, atomicity, stronger consistency, or a single writer that the chosen design does not naturally provide.

### 4.1. Race discipline for shared state

Concurrency is a named semantic above; these are the rules that make it concrete. Each one assumes two actors can interleave — where only one writer exists by construction, the machinery is overhead, and the proof is the exemption.

**Collapse check-then-act into one atomic decision.** A permission, balance, count, or existence check followed by a separate act is a race: both actors can pass the check before either acts. Make the decision where the write happens — a conditional write, a unique constraint, a row lock, a compare-and-swap — never read-decide-write in three steps.
- Why: the check's result is only true at check time; the act needs it true at act time, and nothing in between holds the world still.
- Bad: `if balance >= amount: balance -= amount` in two statements — two concurrent requests both pass the check. Good: `UPDATE accounts SET balance = balance - :amount WHERE id = :id AND balance >= :amount` — the check and the act are one statement, and the affected-row count says who won.
- Boundary: a single-writer path (one process owns the key, one thread drains the queue) needs no atomicity primitive — but the exemption is proven, not assumed: name the single writer. (cloudflare/security-audit-skill `ATTACK-CLASSES.md:67`)

**Act on the handle you verified, not a re-lookup by name.** Between check and use, never re-identify the resource by path, name, or key: verify identity on the handle itself (type, identity, bounds) and act through that handle. When identity can change between verification and use, re-verify at use and reject the mismatch.
- Why: a name can be rebound between the check and the use; the handle can't. Re-looking-up re-opens the race the check was supposed to close.
- Bad: `if os.path.exists(path): open(path)` — a symlink swap between the two calls redirects the open. Good: open with `O_NOFOLLOW | O_CREAT | O_EXCL`, then verify with `fstat` — regular file, link count exactly one, size within bounds — before reading from that descriptor; reject if type, identity, or size changed since the check.
- Boundary: where no untrusted writer can reach the namespace between check and use, a single lookup is fine — the handle discipline earns its cost at trust boundaries. (cloudflare/security-audit-skill `SKILL.md:71-77`)

**A lock or ownership rule is only as good as its worst path.** For shared state, enumerate every writer, then confirm the fast, error, shutdown, and compatibility paths all obey the same lock and ownership discipline. A single unlocked path — the background cleanup task, the shutdown hook, the lazily-initialized global — is the race.
- Why: races hide in the paths nobody reviews. The happy path takes the lock; the error path mutates without it.
- Bad: the write path holds the lock, but the teardown routine frees the object without it. Good: per shared structure, a writer × path matrix (fast / error / shutdown / compat) confirming one lock discipline — the lazily-initialized global treated as a concurrent writer until proven single-threaded.
- Boundary: a single-threaded runtime exempts itself by construction — but what you verify is the construction, not the assumption. (cloudflare/security-audit-skill `MEMORY-SAFETY-AND-BINARY.md:41-42`)

**Every decision used later carries a freshness contract.** An authorization, validation, or lifecycle decision made at t0 and acted on at t1 is stale unless re-verified at use — or the staleness is declared acceptable, with a stated bound. Revocation, ACL change, consent withdrawal, or secret rotation that doesn't invalidate sessions, caches, jobs, and materialized copies is a decision honored nowhere.
- Why: decisions age. The window between check and use is a race against every event that could invalidate the check.
- Bad: a token validated at login authorizes operations for a week with no recheck after a role downgrade. Good: short-lived decisions re-verified at each consequential use; long-lived ones carry an explicit TTL and revalidation points, and revocation propagates to sessions, caches, and queued work.
- Boundary: cheap local decisions (a loop bound read once) aren't freshness contracts — the rule fires where the decision gates a consequential action. (cloudflare/security-audit-skill `ATTACK-CLASSES.md:89`, `DATA-ISOLATION-AND-LIFECYCLE.md:63-64`)

## 5. Data-Access Discipline

**One session per request or task, closed at the boundary** — a session that outlives its scope is a stale read or a leak. Transaction boundaries sit at the request/task scope, not inside helpers; a helper that commits decides the caller's atomicity for it.

N+1 is the classic agent blind spot: a loop that touches a relationship fires one query per row. Load what you iterate — eager-load (`joinedload`/`selectinload` in SQLAlchemy, whatever the ORM calls it) for the relationships the loop actually touches. No lazy loading outside the session that opened it.

Write queries the index can answer: filter on indexed columns, and check the query plan before assuming the ORM generated a sane one. The ORM is a query builder, not a guarantee.

**The common failure:** an agent-written loop over a queryset that looks O(n) and runs O(n) queries — correct on ten rows in dev, a page-load killer in prod.

## 6. Dependency Contracts First

**Before adding retries, circuit breakers, fallbacks, queues, caches, or similar mechanisms, define the dependency contract:**

- **Timeout budget:** set the total time the caller is willing to wait, including retries, rather than the dependency's response time alone.
- **Retryability and idempotency:** classify which failures are retryable and whether repeating the operation can duplicate side effects.
- **Retry ownership:** avoid uncontrolled retries at multiple layers; identify which layer owns retry behavior.
- **Retry budget:** bound the total attempts or retry volume so a distressed dependency does not receive an expanding wave of retries.
- **Capacity and overload behavior:** define useful concurrency limits, queue bounds, admission control, backpressure, or load shedding where the dependency can be saturated.
- **Cancellation:** define whether abandoned work can be stopped, and whether it must be.
- **Fallback correctness:** define the fallback's return value and whether it gives the caller a safe basis to proceed.
- **Observability:** emit enough telemetry to show when retries fire, queues grow, admission rejects, circuits open, or fallbacks engage.
- **User-visible failure behavior:** define the user's experience when attempts fail and make the result actionable.

Require deduplication safeguards before automatically retrying non-idempotent writes.

Use randomized exponential backoff for distributed automatic retries where synchronized retries could amplify an outage. Do not retry permanent failures merely because retry infrastructure exists.

Retry what can self-heal; never *blind*-retry 4xx. Retry when the retry changes the condition: 429/5xx/timeouts, one refresh-then-retry on 401, bounded settle on 404-after-write. A 400/403 with no changed condition doesn't self-heal — don't hammer it; retrying auth failures without a changed condition is at best wasteful, at worst a lockout trigger. Honor `Retry-After`; jitter spreads retry timing so synchronized clients don't stampede the recovering service.

**The common failure:** adding a retry loop because "the call sometimes fails" while leaving idempotency, capacity, timeout budget, and failure behavior undefined. Contract-free retries amplify load during outages: the recovering service receives the original traffic plus retry traffic, turning a transient problem into a sustained one.

## 7. Worker and Queue Discipline

**One consumer, one queue** — route work deliberately (a queue per consumer, or task-level routing where the broker supports it), so a slow consumer never starves an unrelated workload. Know the worker's concurrency model — prefork, threads, or single-process — and set it deliberately; the default is rarely the right size.

Design every job for repeat delivery: workers retry, redeliver, and crash. Make the handler idempotent where the side effects allow it; where they don't (a charge, a sent email), put an idempotency key at the boundary so the repeat is detected, not re-executed. Visibility timeout (or its equivalent) exceeds the maximum task duration; a timeout shorter than the work produces phantom duplicates. Poison messages get bounded retries, then a dead-letter queue — never infinite requeue.

Close what the framework doesn't: one DB connection scope per worker task; transactions scoped to one request or one task. The worker process outlives the work — anything leaked per task compounds.

**The common failure:** a worker that borrows the request's database session and leaks it across tasks, or a visibility timeout shorter than the job — both produce corruption that only appears under load.

## 8. Contract-First Boundaries

**Define API schemas at stable service boundaries** — OpenAPI, gRPC proto, GraphQL schema, JSON Schema, or the project's equivalent — as the source of truth. Auto-generate client types and validators where the ecosystem supports it. Verify generated artifacts in CI with a clean-tree or drift check. Treat applied database migrations as the authoritative schema history and verify model/migration alignment in CI where applicable.

**Route every API call through the one generated, typed client; never call the raw HTTP primitive directly.**
- Why: the typed client is where the contract lives — a raw call bypasses the generated types, the error classification, and the request/response parsing in one stroke, so the call compiles while silently opting out of every guarantee the client enforces.
- Bad: `fetch('/v1/projects/abc/secrets')` in a component — untyped, unclassified errors, invisible to the client contract. Good: the same call through the generated client, where the path, params, and response are typed from the spec and failures route through the one error classifier.
- Boundary: the rule is one owned client per API, not one client for everything — a genuinely different transport (a third-party webhook receiver, a file download that needs a raw stream) gets its own named client, never a raw call in a component. (supabase/supabase `apps/studio/AGENTS.md:34`)

**Verify generated API types against the deployed production spec, not the local one — and treat a fetch failure as a fetch failure, never as drift.**
- Why: types generated from a local or staging spec describe an API nobody runs — merging them first means the client promises a shape production doesn't serve yet, and treating an unreadable spec as drift sends someone "fixing" types that were never wrong.
- Bad: regenerate types from a local dev API, merge, and ship a client that calls an endpoint production won't have until next week's deploy. Good: deploy first, regenerate from production, verify locally, merge — and when the verifier can't reach the spec endpoint, fix the endpoint and re-run instead of editing types to match a phantom.
- Boundary: the production gate applies to types generated from a *deployed* API's spec. A spec-first workflow inverts it deliberately — the spec is the gate there, and the rule to state is which side is authoritative, not that production always is. Verify in CI as a required merge check. (supabase/supabase `.agents/skills/api-types/SKILL.md:12, :25, :29`)

**Gate a request until every input it requires exists — fail fast at the call site rather than sending a request guaranteed to fail.**
- Why: a request fired without its required identifier doesn't test the API — it tests the API's 400 path, and every such call is a wasted round trip plus an error report for a failure the caller could have prevented.
- Bad: firing `GET /v1/projects/{ref}/x` with `ref` still `undefined` — the request was doomed before it left. Good: the fetcher throws on a missing required variable and the query stays disabled until the variable exists, so the only requests that fire are ones that can succeed.
- Boundary: a client-side rule — it governs the caller, not the server. The server still validates and rejects bad input; this rule is about not sending requests the caller already knows are incomplete. (supabase/supabase `.agents/skills/studio-queries/SKILL.md:38, :43`)

**A wire change ships the schema, its fixtures, and its producer in one review — with one stated boundary exception below.** When a wire format changes, the schema, the valid and invalid fixtures, and the code that produces the format all change together — never the schema alone, never the producer ahead of its fixtures. A schema without a matching producer is a promise nothing keeps; a producer without fixtures is a change nothing checks.
- Why: the three artifacts are one contract in three forms. A change that lands one without the others leaves the repo in a state where the schema describes a format nothing produces, or a producer emits a format nothing validates — and the drift is discovered by a consumer, not a test.
- Bad: the schema gains a field in one PR, the producer starts emitting it in the next, the invalid fixture still rejects it in the meantime. Good: one review carries the schema, both fixtures, and the producer — the suite validates the new format end to end before it merges.
- Boundary: a schema change with no producer change (a new optional field nothing emits yet) still ships its fixtures — the fixtures pin what the schema allows, not what the producer happens to do. (e2e-inc/e2e `AGENTS.md:21`)

**A change to a compatibility key re-records every entry keyed under it, in the same change.** When the key that versions a recorded artifact changes — a replay cache, a golden-file set, a snapshot store — every entry recorded under the old key is re-recorded under the new one and the old entries deleted in the same change. An entry recorded under a dead key that a reader silently misses is a check that quietly stopped checking.
- Why: the key is the entry's identity. A new key with old entries left behind means the new reader finds nothing and reports green — the suite passes because it ran nothing, not because anything held.
- Bad: a cache-key bump lands with the old recordings still on disk; a strict reader fails every step whose key misses, a lenient one silently completes an older entry — either way the recordings no longer match the key. Good: the key change, the re-recorded entries, and the deleted old ones ship together; the diff shows the new recordings, not an empty store.
- Boundary: when re-recording is impossible (no device, no key, no model), delete the stale entries and record the gap — a missing entry that fails loudly beats one that is silently missed. (e2e-inc/e2e `AGENTS.md:618-619`; translation: e2e's replay-cache key → any versioned recorded artifact)

Return errors in a consistent machine-readable format so clients can distinguish failure types from structured fields rather than parsing human messages.

**Classify every API error once, at the data layer, into a tagged error carrying a fault, a reason slug, and a retryable flag — the render layer looks the class up, never pattern-matches the message.**
- Why: a fault axis tells the handler who can fix it — the user retries, the platform pages, a third party waits — and a reason slug the compiler checks means a new error kind can't silently fall into a catch-all that shows the wrong remedy.
- Bad: `catch (e) { showToast(e.message) }` — the message is the classification, so a reworded message reclassifies the error. Good: the data layer throws a tagged error `{ fault: 'platform', reason: 'db_connection_timeout', retryable: true }`; the UI looks the class up and renders its troubleshooting, and a 5xx with no pattern still lands as a platform error, never as an unclassified blob.
- Boundary: the fault axis is about *who can fix it*, not who caused it — a user-triggered failure of a platform service is still `platform` fault. The default status mapping (5xx → platform, 4xx → unclassified) fires only when no pattern matches; a matched pattern always wins. The fault values are `user | platform | third_party | studio` (or the project's equivalent); the reason is a snake_case slug typed as a literal union, so a mistyped one fails typecheck. Pass the full error object to the renderer, never the message — the message alone loses the class. (supabase/supabase `.agents/skills/studio-error-handling/SKILL.md:15, :21, :77`, `apps/studio/components/interfaces/ErrorHandling/README.md:12, :18`)

**Every error response uses the one standard envelope — `{ message: string }` — so clients parse errors from the shape, never from a per-endpoint guess.**
- Why: a client that has to discover each endpoint's error shape by reading it is a client that will misread one of them — one envelope means the error path is written once and works everywhere.
- Boundary: the envelope is the *shape*, not the whole error contract — the fault/reason/retryable fields from the rule above ride inside it or alongside it; the rule is that the shape doesn't vary per endpoint. (supabase/supabase `.agents/skills/studio-mock-api-tests/SKILL.md:190-191`)

**Never fabricate a status or any other classification input — classify by what the response actually carried.**
- Why: a made-up 500 turns a local bug into a "platform outage" in every downstream decision — retry policy, alerting, the fault shown to the user — and the lie is invisible because the classifier's output looks exactly like a real classification.
- Bad: classifying a locally thrown `TypeError` with an invented status 500 — the dashboard now counts a platform error that never happened. Good: the local error goes through the non-API classifier and lands as an unexpected error; an unparseable body (an HTML error page, say) is classified by its status and nothing else.
- Boundary: the "classify by status alone" half applies when the body is unparseable — a body that *is* parseable still contributes its fields; the rule forbids inventing inputs, not using real ones. (supabase/supabase `apps/studio/components/interfaces/ErrorHandling/README.md:14, :16`, `.agents/skills/studio-error-handling/SKILL.md:21`)

**A successful GET that declares `Content-Type: application/json` but returns an empty body is a malformed response that rejects — never resolve it as `{}`.**
- Why: `{}` is a valid empty object — resolving an empty body as one tells every downstream consumer "the resource exists and has no fields," which is a lie the server never told; the truth is "the response was broken," and the caller deserves to know that instead of rendering an empty page that looks like an empty resource.
- Bad: `const { data } = await get(...)` resolving with `data = {}` on an empty body — the UI renders "no rows" for a request that never actually returned. Good: the fetch layer rejects with a tagged malformed-response error, so the error path — retry, then report — runs exactly as it would for a network failure.
- Boundary: one recovery attempt (a cache-bypassing refetch) comes first — a body that recovers isn't reported. And the rule fires only for JSON GETs: 204s, `HEAD`, non-GET requests, and empty non-JSON responses keep their empty-body normalization and don't throw. (supabase/supabase `apps/studio/components/interfaces/ErrorHandling/README.md:38`)

**Design the contract before the consumers exist.** This is the deliberate exception to the Rule of Three (ENGINEERING_PRINCIPLES.md §3): a shared envelope, event shape, or agent-call format is agreed up front with its known consumers, not discovered after three copies appear in the wild. Two known consumers and a planned third is sufficient reason to define a contract. See ENGINEERING_PRINCIPLES.md §0.

**Publishing a contract is a commitment.** Once another team or independently deployed component depends on it, changing it is a compatibility event (ENGINEERING_PRINCIPLES.md §6), not an internal refactor.

**When code moves to a new module, update every importer to point at the new location directly; never leave a re-export shim in the old file "for backward compatibility."**
- Why: a shim left behind for an internal move is a second source of truth for where a symbol lives — the next reader greps, finds the old location first, and edits the shim's target through a layer that exists only because nobody did a one-line import change.
- Bad: `export { Foo } from './new-location'` left in the old file after the move, so `Foo` now has two homes. Good: every importer changed to `./new-location` in the same diff; the old file has no trace of `Foo`.
- Boundary: this rule is for **internal** moves only. A **public** API surface follows the deprecation phases — shim plus warning window plus removal version (ENGINEERING_PRINCIPLES.md §6; languages/PYTHON.md §17 keeps shims for public names through the deprecation window) — not this rule. A deliberate compatibility shim with a documented removal date is the public-surface mechanism (see §16.4); do not read this rule as overriding it. (supabase/supabase `apps/studio/AGENTS.md:74`)

**Publish the smallest contract that satisfies known consumers.** Every optional field added "just in case" is a field someone may eventually depend on. Confirm required behavior with consumers before freezing rather than discovering omissions after implementation.

**Taste rules earn hard-error status; they don't start with it.** A validation rule that encodes taste ships first as evidence or a warning. Promote it to a hard error only after ruling out legitimate obstacles — shared ports, explicit routes, nested boundaries, existing examples — and naming the user harm the rule prevents. Before repairing a failed check, identify that harm and whether it is actually present; an unsuitable rule gets its scope, threshold, or severity revised, not its expected values overwritten — changing the expected value alone proves no benefit, and the original failure stays visible in the rationale (tt-a1i/archify `CONTRIBUTING.md:135`, `.agents/skills/archify-tuning/SKILL.md:22`).
- Why: hard errors are a contract; every hard error an agent can't tell apart from a bug gets worked around instead of respected. A warning that names its harm earns its error status on evidence.
- Bad: a new `no-detour` lint fails CI on day one against a diagram with an intentional routed detour. Good: the rule ships as a warning citing the harm (unreadable routes); it becomes an error after review of real failures, with the legitimate-obstacle list checked.
- Boundary: genuine correctness or safety violations can be errors from day one — this rule governs taste, not brokenness.

**Fixtures are a legitimate first deliverable.** When a contract is agreed but implementation is blocked, contract-valid static fixtures can unblock downstream consumers without pretending the service exists. Prefer this to building an integration against unconfirmed assumptions.

**The common failure:** hand-writing client types that drift from actual server behavior, with the missing field discovered in production. Keep one authoritative schema and automate alignment where practical.

## 9. Structured Exception Hierarchies

**Define one small hierarchy per domain** so callers can catch at the precision they need (`except TimeoutException` for retry logic, `except HTTPError` for total failure). Exceptions carry structured context — the relevant objects (request, response), not just text in the message — because structured attributes beat message-parsing.

**The common failure:** a flat `AppError` with everything in the message, forcing callers to string-match to distinguish conditions.

## 10. Match Resource Lifetime to Scope

**Create expensive-to-construct or pooled resources once per process at startup** and hand out references; create request-scoped handles (a DB session checked out of the pool) per request; keep pure values as plain functions. Creating a pooled client per request throws away connection pooling; closing a shared client in a per-request teardown breaks every concurrent request.

**The common failure:** a per-request dependency that constructs — or worse, closes — a process-scoped resource.

## 11. Typed Configuration, Validated at Startup

**One typed settings object, built once at startup and passed explicitly** — never scattered untyped environment reads. Untyped config fails at 3 AM with a key error deep in a code path; a settings object fails once, at startup, with a precise error naming the variable. Secrets ride as redacted types so they never surface in logs or tracebacks. Credential mechanics: `SECRETS.md`.

## 12. Trace Released Artifacts to Reviewed Source

**For software that is packaged or deployed, preserve evidence connecting each released artifact to the reviewed source revision**, declared build process, and verification that produced it. Prefer a consistent hosted build and provenance that identifies outputs by digest; strengthen signing and build isolation in proportion to the artifact's threat model. The [SLSA specification](https://slsa.dev/spec/v1.2/) provides a staged model for these guarantees.

A local scratch or documentation repository that produces no released artifact does not need release provenance. It still must not present a locally generated file as an attested or reproducible release.

**The common failure:** treating a successful build on one workstation as proof that the distributed artifact came from the reviewed revision or was produced without unrecorded inputs.

## 13. Design for Operability

**A system is not production-ready if its operators cannot determine:**

1. what it is doing;
2. whether it is healthy;
3. why an important flow failed;
4. what scope is affected;
5. what action to take next.

Critical flows expose the telemetry required to answer those questions. Depending on the system, that includes:

- meaningful health and readiness signals;
- structured logs;
- metrics tied to user or business outcomes as well as infrastructure;
- distributed traces where a request crosses meaningful boundaries;
- correlation or request identifiers that reconstruct one flow;
- queue depth, retry, rejection, saturation, and degraded-mode signals;
- actionable error classification;
- discoverable ownership and recovery guidance.

Observe outcomes, not only machinery. CPU at 40% does not prove releases are progressing, orders are completing, or an agent is producing valid decisions.

Do not log everything merely because observability matters. Telemetry has privacy, security, cost, and signal-to-noise consequences. Instrument the decisions and flows operators actually need to understand.

**Report a failed fetch once, after the last retry — not once per attempt.**
- Why: one failure retried three times is one failure — four reports make the error look four times as common, drown the real signal, and teach the team to ignore the alert that counts it.
- Bad: the retry loop reports on every attempt — the same outage shows up as four Sentry events. Good: the classifier runs per attempt and remembers the context; the report fires once from the error handler after the last retry, so retries produce one event, not one per attempt.
- Boundary: the "after the last retry" gate applies to retryable failures inside a retry loop. A caller outside any retry loop (plain function, event handler) reports immediately — waiting for retries that will never come is the opposite failure. (supabase/supabase `apps/studio/components/interfaces/ErrorHandling/README.md:40`)

**The common failure:** adding logs after the first production incident. If a load-bearing failure can occur without leaving enough evidence to reconstruct it, observability is part of the missing design.

### Telemetry naming, cardinality, and spans

Telemetry is a contract with consumers the diff doesn't show — dashboards and alerts query names the code emits, so a sloppy name or an unbounded label is a defect in the system, not in the style guide. (grafana/grafana `contribute/backend/instrumentation.md`, `public/app/core/journeys/AGENTS.md`)

**Label values come from a pre-defined set, declared where the metric is defined.** User-originated values are validated and sanitized first, and no label ever carries a secret.
- Why: one unbounded label — a user ID, a URL, an error string — turns a metric into a cardinality bomb that takes down the store it reports to.
- Bad: `http_requests_total{path="/users/48291/profile"}` — a new series per user. Good: `http_requests_total{route="/users/:id/profile"}` — a bounded set, declared up front.
- Boundary: the set is per metric, not a global allowlist (unmaintainable) and not an ad-hoc per-call set (no set at all). The never-secrets half is owned by `SECRETS.md`.

**One measurement, one name, everywhere.** Tell copies apart with a label, never by prefixing the name.
- Why: a name that varies by deployment is a name nobody can grep for — the dashboard queries three names, the code contains none of them, and a rename silently orphans every alert that queried the old one.
- Bad: `worker_a_queue_depth` vs `worker_b_queue_depth` as separate metric names. Good: `queue_depth{component="worker_a"}` — one name, one dashboard query.
- Boundary: renaming is allowed, but only as a change with consumers checked first — dashboards and alerts queried for the old name before it moves — not as a drive-by cleanup.

**Span only I/O-bound work or quantifiable CPU-bound work.** A thin wrapper that just calls the next layer gets no span of its own.
- Why: a span that adds no timing beyond what its child span already shows is pure volume — it costs storage and attention while teaching the reader nothing the child didn't already say.
- Bad: a `service.GetDashboard` span wrapping a `store.GetDashboard` span with identical start and end. Good: the span lives at the database call; the service passes context through and adds nothing.
- Boundary: "quantifiable" is the gate for CPU work — a CPU-bound function earns a span when it carries a count or size worth reading (an integer attribute like `permissions_count`), not merely because it burns cycles.

**A metric-name collision is a wiring bug — never catch it and carry on.** Do not resolve a duplicate registration by catching and ignoring the error, reusing another component's collector, passing a nil registerer, or otherwise skipping registration: every production component must report its metrics.
- Why: swallowing the collision silently deletes a component's telemetry — the dashboard looks healthy because the missing series never existed, and the outage that component would have caught goes unwitnessed.
- Bad: `try: register(m); except AlreadyRegistered: pass` — the component now reports nothing, quietly. Good: build the collectors once and pass them down to every contributor; or give each component a stable `component` label value under one shared name.
- Boundary: build-once-and-pass-down applies when callers intentionally share one measurement; when components measure different concepts, distinct names (the one-name rule above) is the fix instead — same-name-with-label is not a license to merge unrelated measurements.

**Span names are templates — the ID goes in an attribute, never in the name.** Name a span for the operation, not the instance: low-cardinality template names, with IDs and counts as attributes.
- Why: a span name with an ID baked in is a new series per entity — the same cardinality bomb as an unbounded label, in the trace store instead of the metric store — and it makes "show me all `get_account` spans" unqueryable.
- Bad: spans `get_account/42`, `get_account/43`, … — a thousand names for one operation. Good: span `get_account` with attribute `account_id=42`.
- Boundary: the template may carry the route shape (`get_account/{accountId}`) — the parameter's position, not its value. A name with no operation at all (`get`) is the opposite failure and equally unqueryable.

**The metric name encodes its type.** A counter takes a `_total` suffix (`http_requests_total`); a duration histogram takes a `_<unit>` suffix (`http_request_duration_seconds`); a gauge is named as a value that can rise and fall (`http_requests_in_flight`).
- Why: the suffix is the type, readable at the query site — a reader who sees `_total` knows to rate it, and one who sees `_seconds` knows the unit without opening the definition.
- Boundary: the suffix rule covers the three types; a metric that is none of these (an info- or enum-style series) falls outside it and gets its purpose in the name instead.

**Write the full metric name out in one piece, so a dashboard name greps to the code.** Never assemble it from parts or leave a gatherer to add a prefix.
- Why: the dashboard is where a metric is first seen; if its name doesn't appear verbatim in the code, the jump from "this graph is wrong" to "this is the code that emits it" is a guess, not a grep.
- Boundary: existing metrics written the other way keep working and do not need renaming — this rule governs new metrics and renames, not a retrofit sweep.

**Register collectors on the registry the service was wired with — never as package-level globals on a default registry.**
- Why: a global registry is shared mutable state with init-time side effects — tests leak collectors into each other, and a service wired with a scoped registry silently reports to the wrong one.
- Boundary: a nil or absent registerer is a legitimate "don't register" (what tests usually want) — the rule is about *where* registration lands when it happens, not about forcing registration in tests.

**Declare the series at startup so a query sees zero, not a gap.** Guarantee a metric exists before its first observation.
- Why: a missing series and a zero series mean different things to an alert — absence looks like "no data" and either pages nobody or pages everybody, while zero is a fact the alert can reason about.
- Boundary: applies to metrics an alert or dashboard queries; a purely ad-hoc debug counter nobody queries needs no pre-registration. It applies only when registration happens — in tests, a nil registerer that skips registration entirely is still legitimate (see the rule above).

**Every span you open, you close — in the same scope that opened it.** A span without an end is a leak, not telemetry.
- Why: an unterminated span never reports its duration, so the trace shows work that never finished — indistinguishable from work still running, which is exactly the wrong signal during an incident.
- Boundary: the close belongs to the scope that opened the span (defer-style, at the point of creation) — handing the end to a distant caller is how spans get forgotten.

**Track a multi-step user workflow as one journey with named steps and explicit end conditions — success, discarded, and timeout — so the outcome is a fact, not an inference from a timeout.**
- Why: a journey that only ends on success makes every abandonment look like a slow success — the timeout column absorbs the signal, and nobody learns the workflow was abandoned at step two.
- Bad: a journey that ends only on save; abandoned edits pile up as timeouts. Good: close-without-saving maps to an explicit `discarded` end, so the dashboard shows success vs discarded vs timed-out as three distinct outcomes.
- Boundary: the journey pattern is for multi-step user workflows (save flows, setup flows), not single actions — a one-click action is a point event, not a journey. Use measured steps for operations with a duration and point events for instants.

**Telemetry-only events stay silent in product analytics.** Mark events added purely for instrumentation so they don't pollute product analytics; events with independent product value stay visible.
- Why: an instrumentation event that lands in the analytics stream inflates the numbers product decisions are made on — the telemetry corrupts the signal it was meant to supplement.
- Boundary: "silent" is for events created *for* instrumentation; an existing event that already has analytics value keeps its visibility — silencing it would delete real product signal.

## 14. Graceful Degradation

**Preserve useful core behavior when an auxiliary capability fails** — but only when the degraded result remains a safe basis for the caller's next decision.

A search outage may leave checkout available. An analytics failure does not normally prevent login. A recommendation engine may return "recommendation unavailable" while the authoritative transaction continues.

Do **not** convert any of the following into stale, guessed, or apparently successful results merely to keep the flow moving:

- missing or failed authorization;
- unavailable authoritative state required for correctness;
- failed writes whose outcome is uncertain;
- schema or contract uncertainty;
- security or policy checks that could not be completed;
- safety-critical or otherwise consequential decisions whose basis is unavailable.

Make degraded mode observable and exercise it periodically when it is important enough to depend on. Rarely used fallback code is still production code.

**The common failure:** returning a plausible fallback that looks authoritative. The user or caller continues with an incorrect assumption, and the original failure becomes detached from the later consequence.

## 15. Overload Protection, Rate Limiting & Circuit Breakers

**Protect the system's ability to perform useful work under saturation.**

Depending on the actual failure mode, mechanisms may include:

- bounded concurrency;
- bounded queues;
- admission control;
- load shedding;
- rate limits and quotas;
- randomized exponential backoff;
- retry budgets;
- timeouts;
- circuit breakers;
- degraded responses.

Choose the mechanism from the dependency contract and capacity model rather than applying the entire catalog.

Prefer rejecting excess work early and cheaply over accepting an unbounded amount of work that cannot finish. A system that returns some explicit overload errors while preserving healthy throughput is usually safer than one that accepts everything until latency, memory, and retries collapse the service.

Circuit-breaker thresholds, rate limits, queue bounds, and concurrency settings must be based on the dependency's observed behavior or a documented initial assumption that can be measured and revised.

**The common failure:** allowing every layer to queue and retry independently. One user request fans out, queues accumulate, timeouts fire, each layer retries, and protection mechanisms amplify the outage they were intended to prevent.

## 16. Design red flags

**Screen every candidate design before synthesis.** A red flag is a reason to revise or reject the shape, not a style nit. Each flag below is a symptom tripwire: when you see the symptom, fix the shape.

### 16.1. Shallow module

**Symptom tripwire:** callers chain 3+ of your methods to complete one operation, or your option flags name internal stages (`skip_validation`, `phase="load"`).

**Why:** the interface taxes every caller with coordination work the module should own. A wide surface backed by thin behavior is a call chain, not a capability — learning the interface doesn't save the caller from learning the implementation.

**Bad:** `loader.load()`, `validator.validate(items)`, `saver.save(items)` called in that order by every caller — three modules, one operation, zero hidden complexity.

**Good:** one `ingest(source)` that owns load → validate → save internally. The caller names the outcome, not the steps.

**Boundary:** a thin wrapper that adapts a real boundary (foreign API shape, serialization mismatch) isn't shallow — it hides genuine complexity. Judge by hidden behavior: if removing the layer costs callers nothing, remove the layer.

### 16.2. Information leakage

**Symptom tripwire:** a change to a wire format, storage schema, or framework object forces edits in 2+ modules.

**Why:** every module that depends on a representation is coupled to it. One representation change becomes a coordinated edit across call sites you cannot enumerate.

**Bad:** a service returns `requests.Response` to callers who read `.json()["fields"]` — every caller's fate is tied to the transport library's object model.

**Good:** parse external data into domain types behind the interface — `parse_payload(raw) -> Order` — and everything past the boundary speaks `Order`. Transport, storage, and framework types stay private to the seam that owns them.

**Boundary:** your own published wire types (the §8 contract you agreed with consumers) are the contract, not leakage. This flag targets transport/framework internals leaking *past* the seam.

### 16.3. Temporal decomposition

**Symptom tripwire:** modules named after pipeline stages (Load / Validate / Transform / Save) that all manipulate the same representation and its invariants.

**Why:** execution order is not knowledge. Stages organized by time repeat one representation and its rules across N boundaries, so one invariant change touches every stage.

**Bad:** `Loader`, `Validator`, `Transformer`, `Saver` each holding their own copy of the `Order` field invariants.

**Good:** one `OrderIngestion` module owning `Order` and its rules; load/validate/transform are methods that run at different times inside it. Group code around domain knowledge owned, not the clock.

**Boundary:** genuine pipeline boundaries — different owners, deploys, or rate limits (per §3) — can stay separate. Group around knowledge; split only on a real isolation need.

### 16.4. Two ways to do one task

**Symptom tripwire:** grep finds 2+ live paths performing the same task (`send_via_queue()` and `send_direct()` both in use).

**Why:** agents and new code copy whichever way they find first, so every way keeps gaining callers and behavior drifts between the copies. One task with two implementations is a bug waiting for divergence.

**Bad:** keeping both paths because "migration is risky" — the migration never happens, the callers split, the behaviors drift.

**Good:** one live path per task. This flag is the detector — CODE-QUALITY §5 is the procedure (inventory callers, move them, delete the old API in the same change).

**Boundary:** a deliberate compatibility shim with a documented removal date (a §8 contract sunsetting) isn't two ways — it's one way with a deadline. The shim's expiry follows the CODE-QUALITY §5 adapter rule at the contract level.

### 16.5. Importable internals

**Symptom tripwire:** anything outside the module imports a `_private` name, a submodule-internal class, or a helper from under `internal/`.

**Why:** agents take the shortest path that compiles, so they import internals directly — and the imported internal becomes part of the interface. Every internal change turns into a compatibility event.

**Bad:** `from worker.pool import _pick_slot` — the pool's slot-picking algorithm is now public API.

**Good:** make internals unreachable from outside the module, so an import from outside fails the build — package exports, `__init__` boundaries, or lint that rejects private imports from outside the package.

**Boundary:** tests may reach internals to pin behavior (see TESTING.md) — that's a sanctioned exception, not an invitation for production code.

### 16.6. Hand-synced list

**Symptom tripwire:** adding one item means editing 2+ lists — event names in code plus docs, supported types in the handler plus the schema, flags in the CLI plus the config reference.

**Why:** whoever sees one list updates only that one. The lists disagree silently until a user hits the gap.

**Bad:** `SUPPORTED = [...]` in code and a matching list maintained by hand in the README — every addition is a two-edit ritual with no enforcement.

**Good:** keep one authoritative list and derive the others from it (codegen, doc build). If a list genuinely can't be derived, add a build/test check that fails when the lists disagree — the check *is* the derivation.

**Boundary:** intentionally redundant lists with a machine-checked consistency test satisfy this. The guarantee matters, not the mechanism.

### 16.7. Idempotent lifecycle operations

**Make startup, teardown, and scheduled loops converge to the same end state regardless of partial prior runs.**

**Why:** commands, lifecycle steps, and processing loops run where crashes, restarts, and retries are normal. If leftover state from a crashed run changes the next run's outcome, every restart becomes a debugging session. (§7 covers per-job idempotency at worker boundaries; this covers the process lifecycle around the jobs.)

**The recipe:**

- **Convergent startup:** on start, scan for existing state, clean stale artifacts, adopt or reclaim live sessions — never assume a clean boot.
- **Content-based cleanup:** recognize leftovers by content equivalence, not creation order, so a half-written artifact from a crashed run is identifiable as incomplete rather than valid.
- **Self-healing locks:** a lock file records the holder's PID; on lock contention, check whether that PID is still alive before treating the lock as held. A dead holder means a stale lock — release it, don't wait on it.
- **Idempotent scheduling:** failed work respawns cleanly; fresh input is regenerated after each cycle rather than accumulated from leftovers.

**The test — run before merge:**

1. What happens if this runs twice in a row?
2. What happens if the previous run crashed at every possible point?
3. Does re-execution converge to the same end state?

If any answer is "it depends on what state was left behind," the operation needs a reconciliation step.

**Boundary:** spend the reconciliation budget on operations that mutate shared state. Read-only and pure operations converge trivially — don't armor what can't break.

### 16.8. New mechanism beside an existing seam

**Symptom tripwire:** a new module, hook, or service call built beside an existing middleware, interceptor, provider — or the project's equivalent seam — that already serves that concern.

**Use the existing seam before building a new mechanism.** At plan time, list the extension points the codebase already offers for the concern; if one satisfies the use case, use it.

**Why:** every new mechanism is a second way to do one task (§16.4) — it gains callers, drifts, and doubles the surface the next change must touch. A seam that already exists was already reviewed, tested, and wired into the system's failure behavior; a new mechanism re-earns all of that from zero.

**Bad:** a new ad-hoc auth check in a handler beside the middleware that already enforces auth for that route family. **Good:** the handler registers on the existing middleware; the plan names the seam it checked and why it fits (NVIDIA/OpenShell `.agents/skills/build-from-issue/SKILL.md:21`).

**Boundary:** when no existing seam satisfies the use case — a genuinely new concern, or a seam that can't express it — building new is correct. Say which seams were checked and why they don't fit. And the need to run another service alone doesn't disqualify an extension — if the system already supports that service, the seam still counts.

### 16.9. Bypassed sanctioned layer

**Symptom tripwire:** call-site code implementing what a sanctioned layer exists to do — the layer is missing the operation, so the caller re-implements it inline.

**When the sanctioned layer lacks the operation you need, extend the layer — don't route around it.** Add the operation to the layer (and its backend or contract) instead of writing a direct implementation at the call site.

**Why:** a bypass is a second live path (§16.4) that no future change to the layer will reach — fixes, policy, and failure handling applied to the layer silently skip the bypass. The layer is the one place the behavior is reviewed; the bypass is the one place it isn't.

**Bad:** a handler that hand-rolls the operation because the shared layer "doesn't have that op yet" — the next fix to the layer never reaches it. **Good:** the operation lands in the layer with its tests; the handler calls it.

**Boundary:** documented, classified exceptions stay permitted — a protocol or parsing type, or an explicitly classified exception the layer's own docs allow, isn't a bypass. An undocumented bypass is. (Translated from crypto-specific: NVIDIA/OpenShell `AGENTS.md:240` — "Route first-party security-sensitive cryptographic operations through `openshell-crypto`. If an operation is missing, extend the facade and backend implementation instead of adding a direct cryptographic implementation in an application crate.")

---
