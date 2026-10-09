---
title: Python Standard
version: "1.10"
scope: "Python-specific coding rules for agents: tooling, style, readability, typing, async, errors, architecture, packaging, testing, runtimes, performance"
consult_when: "When writing Python and reaching for the old habits — bare `except`, mutable defaults, sync calls in async code, 'just pip install it' — or when the code runs but a Python review would flag it."
last_reviewed: 2026-10-09
---

# Python Standard

Operational Python rules for agents. Language-neutral principles live in `ENGINEERING_PRINCIPLES.md`; per-task quality rules in `CODE-QUALITY.md`. This file owns the Python-specific how: the tooling contract, style, typing, async, errors, packaging, and performance.

**Core principle:** explicit, typed, boring Python — the kind the type checker, the linter, and the runtime all agree with.

Every rule carries its why — read it, don't skim past it. The point is that you understand the decision well enough to own it, not that you check a box.

## Sections

- **1. The tooling contract** — deliberate ruff rule selection; lint is the gate, judgment is the override
- **2. Style: what the linter can't catch** — imports, naming-adjacent style rules
- **3. Typing** — strictness as team posture; typed module boundaries
- **4. Async discipline** — task ownership, cancellation, no fire-and-forget
- **5. Errors and exceptions** — structured hierarchies; retry in one wrapper per boundary
- **6. Correctness traps agents repeat** — lru_cache on methods, naive datetimes, un-awaited coroutines
- **7. Subprocess, environment, and dependencies** — evaluate every new dependency as a decision
- **8. Performance** — measure first; the standard optimization rules
- **9. Readability** — naming, one-thing functions, guard clauses, docstrings as contract
- **10. Functions, classes, and data flow** — functions by default, sentinel values, no taxonomies
- **11. Control flow** — EAFP-when-exceptional / LBYL-when-routine, comprehension ceiling, match
- **12. Module and package design** — lazy heavy imports, src layout, feature-organized modules
- **13. API design** — keyword-only args, progressive disclosure
- **14. Configuration** — typed settings object, hide inputs at sensitive boundaries
- **15. Runtimes: Lambda and long-lived servers** — thin handlers, cold-start discipline, batchItemFailures
- **16. Testing** — hoist I/O, fakes over mocks, Hypothesis, contract tests
- **17. Evolving code** — 3-phase deprecation, additive compatibility, changelog as contract

## 1. The tooling contract

**The project names its tools once, in `AGENTS.md`, and every agent uses them.** A conflicting project instruction overrides the default; the linter's opinion never does.

- **uv runs everything.** `uv run` for execution, `uv.lock` committed for deployables, CI installs with `--locked`. The lockfile is what makes "tests pass" mean something — without it the dependency set drifts between runs and a green suite proves nothing about the next install. PEP 735 dependency groups replace ad-hoc `requirements-dev.txt`.
- **Ruff is the linter and the formatter.** One tool replaces black/isort/flake8/pylint — say so explicitly in `AGENTS.md` ("do not call Black, flake8, isort, or pylint") so agents stop reaching for the old stack.
- **Deliberate rule selection, never `select = ["ALL"]`.** Enable what the project means: `E,F,W` (errors), `I` (imports), `N` (naming), `UP` (pyupgrade), `B` (bugbear — catches the classic agent traps below), `C4` (comprehensions), `SIM` (simplify), `S` (bandit security), `ASYNC` (async correctness), `PT` (pytest style), `RET` (return discipline), `PERF`, `DTZ` (datetime correctness), `RUF`. ALL drowns the signal in style noise and teaches agents to ignore the linter — the opposite of lint-is-law.
- **One type checker, named with its exact command.** mypy and pyright both work; the project names one as the CI gate. A fast checker in the editor is a complement, not the gate.
- **pytest conventions:** fixtures in `conftest.py`, `@pytest.mark.parametrize` over copy-pasted test functions, `tmp_path` over hand-rolled tempdirs, `asyncio_mode = auto` so async tests just work, `pytest-xdist` plus `pytest-randomly` for speed and order-independence.
- **pre-commit gates the commit:** ruff hooks, the type checker via `uv run`, and the uv lock hooks. The gate runs before the commit exists, not after.

Why this section comes first: every rule below is cheaper when a tool enforces it. The contract turns style from advice into a gate.

**Version posture.** 3.15 is the horizon — PEP 661 (`sentinel()`) and PEP 810 (`lazy import`) are Final, first release scheduled 2026-10-01; 3.16 is now the watch. Use version-gated idioms (§10, §12) until the floor moves.

## 2. Style: what the linter can't catch

- **Import modules, not bare colliding names.** Default to `import os.path` over `from os.path import join` — the call site says where the name came from, so the reader never hunts the import block, and two modules exporting the same name stop colliding silently. `from` imports are fine for names that can't collide or confuse (`from dataclasses import dataclass`); the rule bites on generic names (`join`, `get`, `load`) whose origin the reader can't place.

```python
# Bad: where did `join` come from — os.path or shlex?
from os.path import join
p = join(a, b)

# Good: the module is the namespace
import os.path
p = os.path.join(a, b)
```

- **Prefer absolute imports in new code; match the file's existing convention; never mix the two in one module.** `from .models import User` breaks the moment the file moves or the package runs as a script — but churning a working package's convention for the rule's sake is worse.
- **No mutable global state.** Module-level *constants* and shared *clients* (a boto3 client, a connection pool) are fine — even good on Lambda, where module scope survives warm invocations. Mutable request-scoped state at module level is the trap: concurrent requests share it, and the bug only appears under load.

```python
# Bad: every request mutates the same dict
_cache = {}

# Good: constant, or a client built once and never mutated
_CLIENT = boto3.client("s3")  # built once, read-only use
```

- **Keep try blocks tiny.** Wrap only the line that can raise. Why: a broad try block catches exceptions from code you didn't mean to guard, and the handler then "handles" a failure it doesn't understand.

```python
# Bad: a KeyError from process() gets swallowed as a fetch failure
try:
    raw = fetch(url)
    data = parse(raw)
    result = process(data)
except FetchError:
    result = fallback()

# Good: only fetch() is guarded; parse/process failures surface honestly
try:
    raw = fetch(url)
except FetchError:
    result = fallback()
else:
    result = process(parse(raw))
```

- **Never `assert` for validation.** `assert` is a debugging aid the interpreter can strip with `-O`. Validation that protects a boundary must survive optimization — raise a real exception.

```python
# Bad: disappears under python -O
assert user_id, "user_id is required"

# Good: always enforced
if not user_id:
    raise ValueError("user_id is required")
```

| Thought | Reality |
|---|---|
| "It's only a sanity check" | Under `python -O` the check doesn't exist. Validation that protects a boundary must survive optimization. |

- **Don't shadow builtins.** `list`, `dict`, `id`, `type`, `input` as variable names break the reader's mental model and any later code in the scope that needs the real builtin. Name it `items`, `payload`, `user_id` — don't wait for the linter to flag it.

## 3. Typing

**Validate at the boundary, then trust inside it.** Parse untrusted input — HTTP bodies, message payloads, tool results, external API responses — into typed models at the entry point. Past that line, pass typed objects. This is `ENGINEERING_PRINCIPLES.md` §1's information hiding made concrete: parsing and validation rules live in one place instead of every consumer re-checking `if "field" in payload`.

**Pass typed values across module boundaries when the shape is known.** A `dict[str, Any]` in a signature moves the contract out of the type system and into the reader's memory. It is the Python form of the shallow module — the caller must know the internals to use it.

**The exception is content that is genuinely open.** Some payloads have no fixed shape by design: a passthrough body owned by another team, arbitrary metadata, a JSON column. Modelling those with a rigid type is worse than not modelling them, because the type claims a guarantee the data doesn't honor. Carry them as an explicit opaque type — a `JsonValue` alias — and keep it opaque rather than reaching inside. The rule targets dictionaries standing in for a shape you actually know; it doesn't require inventing shapes you don't.

**Prefer generated models where a schema exists.** When you own or consume a real schema, generate models from it where tooling makes that reliable and verify drift in CI. Where no usable schema exists, use a hand-written narrow adapter: validate at the boundary, convert to your own types, and let contract tests pin the behavior you depend on.

**Annotate public functions.** Where there is no external schema, the annotation is part of the contract. The type checker runs in CI so the contract gets automated verification.

**Typing strictness is a team posture; state it once.** The checker, its strictness level, and what `Any` is allowed to mean are named in the repo's typing config — not renegotiated per file. Strict where the contract matters (boundaries, money, auth); pragmatic where the shape is genuinely open.

### Choose the model type by cost and job

- `TypedDict` — boundary dictionaries with a known shape. Zero runtime cost; the type exists only for the checker.
- **Frozen dataclass** (`@dataclass(frozen=True, slots=True)`) — internal domain objects. Cheap, immutable by default, hashable.
- **Pydantic `BaseModel`** — the untrusted edge only. It validates, which is exactly what you want at the boundary — but instantiation costs roughly 7× a dataclass, so don't pay it for internal objects that are already validated.
- **`msgspec.Struct`** — hot-path serialization. Decode-plus-validate beats even orjson's decode alone on structured payloads; reach for it when JSON throughput is the bottleneck, not by default.

```python
# Bad: paying validation cost on every internal hop
class Order(BaseModel): ...  # validates again on every construction

# Good: validate once at the edge, carry cheap types inside
order = OrderRequest.model_validate(raw_body)  # edge: Pydantic earns its cost
process(order.to_internal())                    # inside: frozen dataclass
```

### Use the typing the checker understands

- Builtin generics: `list[str]`, not `List[str]`. `X | None`, not `Optional[X]`. PEP 695: `type Alias = ...`, `class Box[T]`.
- **`assert_never` closes every dispatch.** When you branch on a union or match on an enum, end the "impossible" branch with `assert_never(x)` — the checker then proves exhaustiveness, and adding a variant without handling it becomes a type error instead of a silent fallthrough.

```python
from typing import assert_never

def render(shape: Circle | Square) -> str:
    if isinstance(shape, Circle):
        return "circle"
    elif isinstance(shape, Square):
        return "square"
    assert_never(shape)  # adding Triangle later fails the type check here
```

- `TypeIs` (3.13+) over `TypeGuard` for narrowing functions — it informs the checker on the negative branch too.
- **Narrow types with `isinstance()`, not `hasattr()`.** For type narrowing, `hasattr()` tests capability, not type — for `str | None` it answers the wrong question, and the checker can't narrow on it. `isinstance()` tells both the reader and the checker what the value is. (`hasattr()` keeps its one legitimate job: genuine capability/feature detection on objects you don't control, where no type exists to narrow to.)

```python
# Bad: duck-typing a union
x: str | None = maybe_name()
if hasattr(x, "replace"):
    x = x.replace("e", "a")

# Good: the checker narrows, the reader knows
if isinstance(x, str):
    x = x.replace("e", "a")
```

- `ParamSpec`/`TypeVar` for decorators (`def deco[**P, R](f: Callable[P, R]) -> Callable[P, R]`), `Unpack[TypedDict]` for `**kwargs`, `@override` (PEP 698) when overriding — the checker verifies the signature actually matches the parent.
- `Never`/`NoReturn` for functions that never return (raise-only helpers, `sys.exit` wrappers).

### Enum discipline

- `Literal["a", "b"]` — one field, local to a function. No runtime existence; don't use it for values that cross a boundary.
- `StrEnum` (3.11+) — wire values. It serializes as the string it is, so the API contract and the code agree.
- Plain `Enum` — internal-only symbolic values.

### Any accountability

`Any` is a hole in the contract — account for every one. Use `object` when you truly know nothing (it forces the consumer to narrow before use). Every `# type: ignore` carries its code (`# type: ignore[attr-defined]`), and `warn_unused_ignores` is on — so a fixed problem surfaces as a stale suppression instead of a silent lie.

## 4. Async discipline

These failure modes are easy to write, hard to see in review, and often invisible until load.

**Keep the event loop responsive during blocking or unbounded work.** Inside `async def`, make network, database, process, and large-disk waits awaitable. A synchronous DB driver, a `requests` call, or `time.sleep` stops every concurrent task in the process. The symptom is throughput that collapses under concurrency while each individual request looks fine in isolation.

**The proportionality rule:** size the execution strategy to the work and its bound. Run network and unbounded blocking I/O through awaitable paths. Run small, bounded, local work — a startup config read, a few-kilobyte file read outside the hot path, an in-memory transform — inline when the cost of offloading exceeds the blocking risk. Treat unknown-size files and suspected network mounts as unbounded.

Use `asyncio.to_thread` for unavoidable synchronous **I/O-bound** work, such as a blocking library with no async API.

For CPU-bound Python work — CPU-bound enough to hold the GIL and starve concurrent tasks at your expected concurrency — see §8 "Performance" for the threads-vs-processes rule. In async code, `to_thread` is only appropriate for CPU-heavy extension code that releases the GIL (or a runtime with equivalent parallelism).

**The common failures:** using a sync DB driver inside an async handler because it worked in a single-request test; moving heavy Python CPU work to a thread and assuming the GIL disappeared; and adding `to_thread` around a 200-byte config read. The first blocks concurrency, the second may only move the blockage, and the third adds overhead without meaningful benefit.

**Own every task you create.** The real hazard with `asyncio.create_task(...)` is losing ownership: nothing awaits the task, so its exception may surface only as a late "Task exception was never retrieved" log, shutdown does not wait for it, and cancellation cannot reliably be coordinated with the parent work. The event loop also keeps only weak references to tasks, so an otherwise unreferenced task may disappear before completion.

Keep ownership. Await the task, hold it in a collection that outlives it, or use `asyncio.TaskGroup` for structured concurrency and automatic exception propagation.

In a system that dispatches work, a silently lost task is indistinguishable from work that never arrived.

**Propagate cancellation as control flow.** `asyncio.CancelledError` is cancellation, not an ordinary application failure — and since 3.8 it inherits from `BaseException`, so `except Exception` doesn't catch it. That's by design: keep cancellation propagating through broad catches and explicit cancellation handling. Use `try/finally` for cleanup, or catch and re-raise when cleanup needs the exception. Don't "fix" propagation by catching `BaseException`.

**Bound every external wait with one timeout strategy.** Every network, database, and subprocess call needs a bound. Place that bound deliberately, because multiple nested timeout layers obscure the effective deadline.

Use this layering:

1. **Set one deadline per inbound request or job** at the entry point from the timeout budget. This is the authoritative budget.
2. **Configure per-call bounds through the client's own timeout configuration** — HTTP client, DB pool, driver — where the client is constructed.
3. **Wrap an individual `await` in `asyncio.timeout` when that operation needs a stricter bound than the client default**, and state the reason. Use this as the exception rather than the pattern.

A call inheriting the request deadline and its client's configured timeout is already bounded; keep one effective strategy.

When a call is genuinely unbounded, fix it at layer 1 or 2 before reaching for layer 3.

**When layer 1 is not available yet** — no request context or deadline object — configure the bound on the client (layer 2) and note the budget needs end-to-end wiring; a locally guessed five seconds buried three frames deep is harder to find and fix later than an unwired budget you explicitly identified. Establish the deadline convention as its own task, separate from unrelated changes. When the change itself is the budget-tuning work the plan calls for, that's the task — not an exception.

**The common failure:** wrapping every `await` in `asyncio.timeout` with a locally invented number. Nested deadlines disagree, the innermost one wins by accident, the budget becomes fiction, and a slow dependency trips a two-second inner timeout while the caller was willing to wait thirty.

| Thought | Reality |
|---|---|
| "This call needs a timeout" | It already has two — the request deadline and the client default. A third invented number makes the budget fiction. |

## 5. Errors and exceptions

**Define a domain exception hierarchy where callers need to distinguish failure classes.** Raise meaningful types rather than bare `Exception`. Let callers distinguish failures through types and structured data rather than message strings.

Do not invent an elaborate hierarchy when the application has no callers that need the distinction.

**Handle exceptions explicitly and preserve outcome accuracy.** Use narrow catches with defined recovery. A broad, silent catch such as `except Exception: pass`, or a catch that logs and continues as though the operation succeeded, hides the outcome.

Catching a specific expected exception and handling it is correct code. Legitimate examples:

- `FileNotFoundError` during idempotent cleanup of something that may already be gone;
- `KeyError` when probing genuinely optional data — though `.get()` may express the intent more clearly;
- a known client exception triggering a defined fallback whose correctness is stated;
- `TimeoutError` entering an explicitly designed degraded path.

The distinguishing test is whether the caller receives an accurate picture.

Handle a narrow, named exception with a defined recovery. Surface a broad failure when the operation's outcome remains uncertain.

**The overcorrection:** propagating every exception for safety, so an optional cache read or best-effort notification takes down a request that only needed its core operation to succeed. Exception discipline preserves honesty about what failed while allowing defined recovery.

**Preserve the exception chain.** Use `raise DomainError(...) from err` so the original traceback remains available to the person debugging at 2 AM.

**Exceptions carry structured data, not just text.** Follow the httpx pattern: a small hierarchy per domain (`HTTPError → RequestError → TimeoutException → ConnectTimeout`), with the relevant objects attached (`.request`, `.response`) — not just a message string. Callers catch at the precision they need (`except TimeoutException` for retry logic, `except HTTPError` for total failure), and structured attributes beat message-parsing. Put the object on the exception, not just text in the message.

**Retry lives in one wrapper per boundary.** All hand-rolled retry logic in a single `_request_with_retry` — never scattered at call sites. If the SDK already retries correctly (boto3's standard mode), configure it instead of wrapping it. Exponential backoff `min(base * 2**attempt, cap)` plus jitter; honor `Retry-After`; cap attempts. Retry policy: ARCHITECTURE.md §6 — retry what can self-heal, never blind-retry 4xx. Jitter prevents thundering-herd synchronized retries. Note that httpx timeouts are per-socket-operation, not a wall-clock total — don't confuse "timed out" with "deadline exceeded" in retry policy.

**Budget retries against the deadline — retries multiply the timeout.** Every retry re-spends the per-call timeout, so the worst-case wall clock is `timeout × (max_retries + 1)`. Size attempts so that product fits inside the request deadline, not just the per-call bound.
- Why: a 30s timeout with 4 retries is a 150s commitment wearing a 30s costume. The deadline holder never sees the per-attempt number — only the product can blow their budget.
- Bad: `timeout=30, max_retries=5` under a 60s worker deadline. Good: `timeout=10, max_retries=2` — 30s worst case, budget left for the rest of the pipeline.
- Boundary: when the SDK owns the retry loop, configure its budget knobs instead of doing this math yourself (same rule as the wrapper above).

## 6. Correctness traps agents repeat

Each of these is a known AI-generated-code failure. The linter catches most (`B`, `ASYNC`, `DTZ` rules) — this section is the why behind the flag, so the fix is understood and not just applied.

**Mutable default arguments.** The default is created once at `def` time and shared across every call.

```python
# Bad: items accumulates across calls
def add(item, items=[]):
    items.append(item)
    return items

# Good
def add(item, items=None):
    items = [] if items is None else items
    items.append(item)
    return items
```

**Late-binding closures.** Loop variables are looked up when the closure *runs*, not when it's created.

```python
# Bad: every lambda returns 2
fns = [lambda: i for i in range(3)]

# Good: bind at creation time
fns = [lambda i=i: i for i in range(3)]
```

**Bare `except:` and `except Exception: pass`.** The first also swallows `KeyboardInterrupt` and `SystemExit` — the process can no longer be stopped cleanly. The second hides the outcome (§5). Name what you expect or let it propagate.

**String-built SQL.** `f"SELECT ... WHERE id = {user_id}"` is injection by construction. Parameterize — the driver quotes, you don't.

```python
# Bad
cursor.execute(f"SELECT * FROM orders WHERE id = {user_id}")

# Good
cursor.execute("SELECT * FROM orders WHERE id = %s", (user_id,))
```

**Un-awaited coroutines.** Calling `fetch()` without `await` returns a coroutine that never runs — no error, no work done. If the call isn't awaited, gathered, or wrapped in a task, it's dead code wearing a function's clothes.

**`lru_cache` on methods.** `self` becomes part of the cache key, so instances are never garbage-collected — the canonical slow leak. Cache the underlying function, or use a module-level cache keyed on the real arguments. Always set `maxsize`; an unbounded cache is a memory leak with a decorator.

**Naive datetimes.** `datetime.now()` without a timezone is a bug waiting for a second timezone. Use `datetime.now(UTC)` — `utcnow()` is deprecated since 3.12. Compare aware with aware, always; mixing aware and naive raises, which is the *good* outcome — the bad one is silent wrong arithmetic.

**`open()` without `encoding`.** The default encoding is platform-dependent. `open(path, encoding="utf-8")`, or the file reads differently on different machines.

**`sys.path` hacks.** `sys.path.insert(0, ...)` to import a sibling directory is packaging done wrong — fix the package layout or the install instead of mutating the import system at runtime.

**Circular imports.** If two modules need each other, the dependency is pointing the wrong way — move the shared piece down a layer, or import under `TYPE_CHECKING` for annotations only.

## 7. Subprocess, environment, and dependencies

**Use argv lists and explicit environments.** `subprocess.run([cmd, arg], shell=False)` keeps arguments structured. Keep interpolated values out of shell execution, and pass an explicit `env` dict rather than mutating process-global `os.environ`.

**Log only the environment values needed for diagnosis.** The environment contains secrets by construction (`ENGINEERING_PRINCIPLES.md` §6). Environment values are secret-adjacent (SECRETS.md; LOGGING.md rule 3): log only what diagnosis needs, never the value.

**Pin and commit the lockfile for deployable applications and services.** A service, job, or container image installs from a committed, reproducible dependency definition — `uv.lock`, installed with `--locked` in CI. Reproducible installs support the verification discipline: "tests pass" means little if the dependency set drifts between runs.

**Let reusable libraries declare compatible ranges.** A package others depend on keeps its resolution flexible for consumers. It may still commit a lockfile for its own CI — that lock constrains the library's development environment, not its consumers' installs.

Classify the project by checking whether other projects import it as a dependency or whether it gets deployed.

**Evaluate every new dependency as a decision.** Account for supply-chain, licensing, operational, security, and maintenance cost. Prefer the standard library for small needs; add a library when its value justifies the cost and scope. The agent never adds one on its own — propose, human approves (`SUPPLY-CHAIN.md`).

**Use APIs you have confirmed exist.** Plausible-looking library functions that do not exist are a recurring AI failure mode. Check an uncertain signature against the installed package or authoritative documentation before using it, and state the verification gap when checking is unavailable.

## 8. Performance

- **Threads are for I/O, processes are for CPU.** The GIL means threads don't parallelize Python bytecode — `to_thread` around CPU-bound Python work just moves the blockage. CPU-bound work goes to `ProcessPoolExecutor` or off-process. Free-threaded builds (3.13t+) are opt-in with real trade-offs: single-threaded slowdowns, extensions that silently re-enable the GIL, and now-real races on operations like `x += 1`. Track it; don't adopt it as the default.
- **asyncio is not obsolete next to threads** — different niche. Async for many concurrent I/O waits in one process; threads for blocking libraries with no async API; processes for CPU.
- **Comprehensions read better than loops, to a point.** Two levels of nesting max — beyond that it's a puzzle, not code. Generators for pipelines: don't materialize a list you're only going to iterate once.
- **Lazy logging.** A filtered-out log call is nearly free, but the *formatting* isn't — never f-string at the call site.

```python
# Bad: pays for the string on every call, even when debug is off
logger.debug(f"user {user} did {action}")

# Good: formatting deferred until a handler actually emits
logger.debug("user %s did %s", user, action)
```

- **Serialization fast paths.** stdlib `json` is the default. `orjson` is several times faster when JSON is the bottleneck; `msgspec` decode-plus-validate beats orjson's decode alone on structured payloads; Pydantic's `model_validate_json`/`model_dump_json` skip the intermediate dict. Don't optimize serialization until the profiler says it's the bottleneck.
- **Profile first.** `py-spy`, `tracemalloc`, `memray` before any performance change. A performance fix without a measurement is a guess wearing a lab coat.
- **Startup is performance too.** Profile import time with `python -X importtime` — import cost is paid on every CLI run, every Lambda cold start, every test collection. The lazy-import discipline is §12.

## 9. Readability

The readability rules are Python's rendering of CODE-QUALITY.md §8 (canonical) — the examples here are Python-specific.

**Name for meaning, not mechanics.** Nouns for variables, verbs for functions. A good name removes the need for a comment — `pending_refunds` beats `data2`, `dedupe_preserve_order` beats `proc`. Developers over-abbreviate far more often than they over-lengthen; keep domain-meaning names ≥3 letters, conventional shorts (`i`, `x`/`y`, `e`, `id`, `db`) are fine. The rule targets cryptic abbreviations (`procData`, `tmpUsr`), not established shorthand — judge by whether a new reader can expand the name.

**Unpack to name, not to index.** `x, y = point` beats `point[0], point[1]` — the names document what each position *means* at the use site, so the reader never holds the layout in their head. Unpacking is naming; indexing is a memory test.

**One thing per function, one level of abstraction.** A function small enough that its whole idea fits in your head at once — roughly under 50 lines, files under ~800. Long functions mix abstraction levels (policy next to byte-twiddling), which makes the bug surface the entire function. The top function reads as an outline; details live one call down.

**Guard clauses beat nesting.** Validate inputs and handle edge cases first; keep the happy path at the left margin. Each nesting level doubles the reader's mental stack. Cap nesting at ~4 — past that, extract.

```python
# Bad: arrow code
def charge(user, amount):
    if user:
        if user.is_active:
            if amount > 0:
                ...
            else: raise ValueError("amount")
        ...

# Good: guards, then one linear path
def charge(user, amount):
    if user is None: raise ValueError("no user")
    if not user.is_active: raise ValueError("inactive")
    if amount <= 0: raise ValueError("amount")
    ...
```

**Boolean parameters are a design smell.** One boolean = caution; two or more = refactor into named functions, a mode enum, or a parameter object. Each flag multiplies the function's code paths and test cases. `download(url, True)` is unreadable at the call site — a boolean usually hides two functions with different reasons to change. Any surviving flag is keyword-only.

**Comments explain why, never what.** Default to no comment. A comment earns its place only when removing it would leave a future reader confused about a hidden constraint, a surprising decision, or a gotcha:

```python
# Foo (not Bar): Bar's validation rejects legacy IDs still in prod
client = Foo(...)
```

"What" comments rot — code changes, comments don't, and a stale comment is worse than none because readers trust prose over code. "Why" comments capture what the code *cannot* contain: business rationale, external constraints, performance trade-offs. Acceptable uses: non-obvious invariants, workarounds with an issue reference (`# Workaround for GH-123 — remove when fixed`), why this algorithm over the obvious one, hidden coupling to external systems. Canonical rule: CODE-QUALITY.md §4.

**Docstrings state the contract the signature can't show.** Public module/class/function gets a Google-style docstring covering units, invariants, side effects, raised exceptions — what the annotations can't express. Never duplicate the signature (`timeout (float): The timeout` adds nothing). Skip docstrings on trivial private helpers. A docstring that drifts from the signature is worse than absent.

```python
# Bad: duplicates annotations, adds nothing
def fetch(url: str, timeout: float) -> Response:
    """Fetch a URL.

    Args:
        url (str): The URL.
        timeout (float): The timeout.
    """

# Good: adds what the signature can't show
def fetch(url: str, timeout: float) -> Response:
    """GET url with a per-operation timeout.

    Args:
        url: Absolute https:// URL; http:// is rejected.
        timeout: Seconds per socket operation (not a total deadline).

    Raises:
        ConnectTimeout: If the TCP handshake exceeds timeout.
    """
```

## 10. Functions, classes, and data flow

**Default to functions; earn a class with state.** If a class has two methods and one of them is `__init__`, it's a function in costume — write the function. Reach for a class when there is meaningful internal state, behavior that depends on that evolving state, a clear domain model, or genuine polymorphism. Classes accumulate hidden shared dependencies (`self.db`, `self.cache`) that every method silently uses; functions take dependencies as explicit parameters, so coupling is visible in the signature. Stateless classes are ceremony — harder to test, harder to compose.

```python
# Bad: ceremony — no state, just a namespace
class Greeter:
    def __init__(self, greeting): self.greeting = greeting
    def greet(self, name): return f"{self.greeting}, {name}!"

# Good: a function; specialize with functools.partial
def greet(name, greeting): return f"{greeting}, {name}!"
```

**Lambda means "throwaway", not "clever".** `lambda` is for tiny anonymous functions passed as arguments — `key=` sorts, one-expression callbacks. A function whose name the reader will ever need to find gets a `def` and a real name. Multi-line logic, default-arg binding tricks, and nested lambdas are always a `def`.

**Don't build taxonomies; subclass only for code reuse.** Never model real-world categories (`Dog(Animal)`) — the day you need `RobotDog`, the tree breaks. Python is protocol-oriented: duck typing and dunders outlive nominal hierarchies. Composition survives requirement changes; deep hierarchies hide behavior across ancestors. Never subclass builtins to change their behavior — `dict.update` won't call your overridden `__setitem__` (C-level methods bypass it silently). Compose or wrap instead.

**Keep the public surface minimal; underscore the rest.** Everything public is something someone will depend on and you can never refactor. Mark implementation details with a leading underscore — helpers, caches, internal constants. The `_` convention is Python's entire access control; the ecosystem honors it.

**Return values; don't mutate arguments.** Functions speak data in, data out. Mutating a caller's dict or list makes behavior depend on call history — the #1 source of "works in isolation, fails in production." Build and return new values; frozen dataclasses (§3) make this cheap.

**Use a sentinel when `None` is a legitimate value.** `def update(name=None)` can't distinguish "don't touch" from "clear it." A private `_MISSING = object()` gives three states with zero ambiguity. On 3.15+, `sentinel()` is a builtin — a named, repr-able sentinel built for exactly this; below 3.15, keep the `_MISSING = object()` idiom. When `None` genuinely means "no value," plain `None` is correct.

```python
_MISSING = object()

def update(name=_MISSING):
    if name is _MISSING: return   # untouched
    record.name = name            # may be None → clear
```

**Prefer immutable value objects inside the system.** After the boundary, carry data in frozen dataclasses; transitions return new values (`dataclasses.replace`). Frozen values are safely shareable across async tasks and threads.

## 11. Control flow

**EAFP when failure is exceptional; LBYL when failure is routine.** `try: handler = dispatch[t] except KeyError` does one lookup and avoids a check-then-act race; `if t in dispatch: handler = dispatch[t]` does two, and the world can change between them. But when failure is the common path (user-input validation) or the check is cheap and clear (`if not items: return []`), explicit checks win — exceptions shouldn't steer normal flow. Note: mainstream Python culture is EAFP-by-default; some 2026 agent shops mandate LBYL-by-default for predictability in generated code. Pick per codebase and stay consistent.

**`match` for the structure of one value; `if/elif` for independent conditions.** Match on shape — constants, destructured tuples/dicts/dataclasses — so the dispatch table is visible at once; keep it exhaustive with a `case _` arm (and `assert_never` for truly unreachable arms, §3). Independent conditions get `if/elif` — they aren't alternatives, so don't present them as one.

```python
# Structure of one value → match
match event:
    case {"type": "click", "x": x, "y": y}: handle_click(x, y)
    case {"type": "key", "key": k}: handle_key(k)
    case _: raise UnknownEvent(event)

# Independent conditions → if/elif
if retries_exhausted(job): dead_letter(job)
elif job.priority > 5: fast_lane(job)
```

**`for…else` kills flag variables in search loops.** The `else` runs only if the loop completed without `break` — "not found" handling stays attached to the loop that determines it. If the team finds it unreadable, an early-return helper is the consistent alternative.

```python
for user in users:
    if user.id == target: break
else:
    raise UserNotFound(target)
```

**Resources live in `with` blocks — by default.** Files, sockets, locks, DB sessions: acquired in `with`, never manual `close()`. When a resource must outlive its creator, document the ownership transfer at the handoff. Manual cleanup has exactly one failure mode — the exception path that skips it — and it's the path you test least. For a *dynamic number* of context managers, `ExitStack` (LIFO unwind cleans up partial setup; `AsyncExitStack` for async). For expected-and-ignorable exceptions, `contextlib.suppress` beats `try/except: pass`. In `@contextmanager` generators, code after `yield` belongs in `finally`.

**Comprehensions: one filter, one transform, one line-ish.** A comprehension is a for-loop in expression form — it inherits the loop's complexity budget. One `for` with one `if` and one expression is the ceiling; past that, write the loop or a generator function. A nested comprehension costs nothing at runtime and everything in review time.

```python
# Bad: two loops and a filter in one expression
flat = [y for row in rows if row for y in row if y]

# Good: the loop says what it does
def flatten(rows):
    for row in rows:
        yield from row
```

## 12. Module and package design

**`def main() -> int` + `sys.exit(main())`.** Scripts are structured as a `main()` returning an exit code, guarded by `if __name__ == "__main__": sys.exit(main())`. Top level holds definitions and constants only — no work. Importable modules are testable modules; top-level side effects make `import` run your program. `main(argv) -> int` is directly unit-testable without subprocesses. Map exit codes deliberately (0 ok, non-zero failure, 130 on KeyboardInterrupt); handle `BrokenPipeError` for piped output. One real console entrypoint owns arg parsing, logging setup, and the top-level error boundary.

**Guards get the 0/1/2 contract.** Exit 0 = clean, 1 = violation, 2 = the guard couldn't run — and a 2 must never read as a 0.

- Why: a checker that silently passes on unavailable inputs converts ignorance into assurance, the most dangerous verdict a gate can emit.
- Boundary: the couldn't-run path needs its own alerting, or it becomes a quiet bypass.

**Do no work at import time; make heavy imports lazy.** Import must be safe and fast: no network, no filesystem mutations, no expensive work, no heavy third-party imports at module top level. Move slow imports (pandas, cloud SDKs, ML libs) into the functions that need them. Import cost is paid on *every* invocation — every CLI run, every Lambda cold start, every test collection — and the wins are measured in the high double digits of percent. Profile with `python -X importtime` before guessing. Manage the trade-off deliberately: ruff PLC0415 gets per-file ignores in CLI modules, not blanket disables; `TYPE_CHECKING` for type-only imports; a regression test asserting heavy modules are absent from `sys.modules` after importing the CLI. On 3.15+, the `lazy import` statement makes deferral declarative instead of hiding imports inside functions — prefer it where the version allows; keep function-level imports with `noqa: PLC0415` on older versions.

```python
# Bad: every `tool --help` pays for pandas + boto3
import pandas as pd, boto3

# Good: pay only on the code path that needs it
def cmd_stats(...):
    import pandas as pd  # noqa: PLC0415 — lazy for startup
    ...
```

**src layout so tests hit the installed package.** `src/<package>/`, not flat. Flat layout lets pytest import `./package` from the repo root — silently testing files that were never packaged. `src/` makes the installed artifact the thing under test and kills "works here because CWD shadows site-packages."

**`__init__.py` re-exports the stable public API — but keep it light.** Users `import package` and find the API — they shouldn't memorize your module tree. If re-exports create cycles or drag in heavy imports, expose submodules instead. Moved names get a deprecation shim (§17), not a silent break.

**Organize by feature, not by technical layer.** `billing/refunds.py` over `models.py` + `utils.py` + `managers.py`. Many small focused modules, each importable without dragging in the world; dependency direction one-way (no import cycles — cycles are the #1 cause of "restructure the package" refactors). Layer-organized code scatters one feature across N files; feature-organized code is independently testable and deletable.

## 13. API design

**Keyword-only arguments for flags and future growth.** `def get(url, *, timeout=..., follow_redirects=...)`. Positional booleans are unreadable at call sites (§9), and keyword-only lets the signature grow for years without breaking positional callers. New parameters are added keyword-only with defaults — backward-compatible by construction. This is how httpx-style clients keep stable APIs.

**Sensible defaults, explicit overrides.** Defaults cover the common case; overrides are explicit keywords. (And never mutable defaults — §6.)

**Minimal surface, progressive disclosure.** `rich.print()` works with zero config; the `Console` object gives full control. The zero-config path gets adoption; the object path gets power. New users never face a constructor with 12 parameters; power users aren't blocked.

## 14. Configuration

**One typed settings object, built once at startup, passed explicitly.** `pydantic-settings` `BaseSettings`: typed, validated, env-sourced. Scattered `os.environ[...]` reads fail at 3 AM with `KeyError` deep in a code path; a settings object fails once, at startup, with a precise validation error naming the variable. Typing documents every knob in one place. Secrets ride as `SecretStr` so they redact in logs and tracebacks.

**Hide inputs at sensitive boundaries.** pydantic's `ValidationError.errors()` returns structured `{type, loc, msg, input}` — machine-readable, which is good — but at sensitive boundaries use `errors(include_input=False)` so secrets and PII never echo back in error payloads and logs. (Also noted for `SECRETS.md`.)

**Don't re-supply what the framework guarantees.** If a registry requires a default at registration time, passing your own default at the call site doesn't add safety — it adds a second source of truth that can drift from the real one. The "missing default" case you're guarding against cannot happen; the duplicate is the only new failure mode.

```python
# Bad: two sources of truth for one knob
batch_size = options.get("deletions.batch-size", 1000)

# Good: the registered default is the default
batch_size: int = options.get("deletions.batch-size")
```

The contract: registration requires a default, so the call returns the registered default (raising if none was registered) — never `None` out of thin air. Don't annotate the result `Optional` out of habit.

## 15. Runtimes: Lambda and long-lived servers

**Thin handler: parse → delegate → return.** Zero business logic in the handler body. The handler parses the event, calls domain functions, returns a response. Handlers are untestable without the Lambda runtime harness; plain functions are unit-testable. Expensive clients (boto3, httpx) are constructed at module level — reused across warm invocations, keeping connection pools warm. Same lifetime logic as below: process-scoped things once, invocation-scoped things cheap.

```python
_client = boto3.client("dynamodb")  # module level: warm reuse

def handler(event, context):
    cmd = parse_event(event)      # may raise → DLQ/retry
    result = process(cmd)         # pure, unit-tested
    return {"statusCode": 200, "body": json.dumps(result)}
```

**Cold start is import time + init time.** Apply §12 inside the handler module: heavy imports deferred or module-level only if always needed; prune the dependency tree (each transitive package is cold-start milliseconds). Structured JSON to stdout for CloudWatch. Measure cold and warm separately; optimize the p99 that matters.

**Fail loudly on poison; partial-failure semantics for batches.** Malformed input → raise, so the event lands in the DLQ or gets retried by the source. For SQS batches, return `batchItemFailures` so only failed records retry. Bind log context per message, not per invocation (LOGGING.md, Rules §5) — one invocation processes a batch; invocation-scoped IDs leak across messages. Swallowing a poison message drops data silently; re-raising the whole batch reprocesses (and re-bills) successes. Timeouts on every outbound call; degrade gracefully on non-critical dependency failure with an explicit degraded signal.

**Long-lived servers: match resource lifetime to scope.** FastAPI `lifespan` owns process-lifetime resources (httpx.AsyncClient, DB engine/pool, ML model) → `app.state`; dependencies *read* from `app.state` — they don't own the resource. `yield` dependencies are for per-request setup/teardown (a DB session checked out of the pool). Creating an `httpx.AsyncClient` per request throws away connection pooling; closing a shared client in a per-request dependency breaks every concurrent request. `Depends`' cache is per-request, not across requests — a frequent misconception. Rule of thumb: expensive-to-construct or pooled → lifespan; request-scoped → dependency; pure value → plain function.

## 16. Testing

**Hoist your I/O: pure core, thin shell.** Push I/O (network, filesystem, console, clock) to the top level; keep the decision-making core pure. A pure function needs no mocks, no fixtures, no event loop — just inputs and expected outputs. This is the highest-leverage testability rule: it *removes* the need for most mocking rather than improving it.

**Explicit dependencies in, not hidden globals.** Pass dependencies as parameters; don't reach for module globals. Hidden globals make tests order-dependent and parallel-unsafe; explicit parameters make the dependency graph visible and swappable.

**Mock only external boundaries; prefer fakes.** Mock (or fake) only at the boundary — network, database, clock, filesystem, third-party APIs. Don't mock internals to test behavior a fake could cover — but mocking is legitimate when the unit under test *is* the interaction: retry wrappers, decorators, middleware. Assert the outcome, not the call choreography. Prefer in-memory fakes with real semantics and assert outcomes, not interactions. Mocking internals couples the test to the implementation: every refactor breaks tests without breaking behavior, which trains the team to stop refactoring. Mocks also let generated code "pass" while asserting nothing about outcomes. A check that cannot fail does not count as a check (CODE-REVIEW.md §7): break the guard and confirm the test goes red before offering it as evidence.

```python
# Bad: asserts implementation; breaks on any refactor
repo = Mock(); svc = BillingService(repo); svc.charge(u, 10)
repo.save.assert_called_once_with(...)

# Good: fake with real semantics; asserts outcome
svc = BillingService(FakeRepo()); svc.charge(u, 10)
assert svc.balance(u) == 90
```

**Contract-test the boundaries.** Test boundary models hard (pydantic validation, Hypothesis round-trips on serializers); test internals against typed values. For HTTP clients, contract-test against a fake transport (httpx's mock transports), not the live API. Live-API tests are flaky, slow, and couple CI to someone else's uptime; transport-level fakes keep the real request-building code under test.

**Tests mirror src; run against the installed package.** `tests/` mirrors `src/<pkg>/`; fast unit tests separated from slow integration tests by markers. A test that passes against CWD files but fails against the wheel is a release-day surprise (§12).

**Async tests force interleaving.** Every coroutine under test is awaited; use `asyncio.gather` to force task interleaving and expose missing locks; keep shared fixtures read-only or copy-per-test; put timeouts on tests that can deadlock. Timeouts turn "CI hangs for 6 hours" into a failing test with a name.

**Property-based testing for parsers, serializers, protocols.** Hypothesis where the domain has *properties*: round-trips (`decode(encode(s)) == s`), invariants (sorted output is ordered), equivalence (optimized impl == reference impl). Hypothesis where available — under a stdlib-only constraint, a small deterministic property loop (seeded PRNG over the input space) is the same rule. Example tests check the cases you thought of; property tests check the ones you didn't — off-by-ones, empty inputs, unicode, boundary lengths. Keep concrete example tests alongside; don't use it where the assertion would re-implement the function.

**CLI tests: test handlers, not argv strings.** Subcommands map to `_cmd_*` handlers taking parsed args; test handlers directly, the entrypoint thinly (exit codes). Parsing is the framework's job; your logic is the handler.

## 17. Evolving code

**Deprecate in three phases: warn → document → remove.** (1) Warn with `warnings.warn(msg, DeprecationWarning, stacklevel=2)` — `stacklevel=2` points at the *caller's* code, and the message names the replacement and the removal version. (2) Document: changelog entry in the same commit. (3) Remove in a major version, after ≥2 minor versions of warning. `FutureWarning` (visible by default) for user-facing *behavior* changes; `DeprecationWarning` (hidden by default) for developer-facing API removals. Silent removals break downstream with no migration path; warnings without a named replacement leave users stuck; the default `stacklevel=1` blames your library instead of the call site.

```python
warnings.warn(
    "fetch_all() is deprecated; use iter_records() — removed in 4.0",
    DeprecationWarning, stacklevel=2,
)
```

**Backward compatibility is additive.** New functions, new parameters with defaults, new keyword-only parameters (backward-compatible by construction). Moving a name? Re-export a shim from the old location for the whole deprecation window. Never silently change what an existing argument *means* — changed semantics break downstream silently, which is worse than a loud rename.

**Changelog as contract.** Keep-a-Changelog sections (Added/Changed/Deprecated/Removed/Fixed/Security), one entry per user-visible change, updated in the same commit. Users decide whether to upgrade by reading the changelog, not your diff; auto-generated commit lists are noise, curated entries are a migration guide.
