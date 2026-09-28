---
title: Python Standard
version: "1.0"
scope: "Python-specific coding rules for agents: tooling, style, typing, async, errors, packaging, performance"
consult_when: "When writing Python - style, typing, async, errors, tooling, or performance."
last_reviewed: 2026-09-28
---

# Python Standard

Operational Python rules for agents. Language-neutral principles live in `ENGINEERING_PRINCIPLES.md`; per-task quality rules in `CODE-QUALITY.md`. This file owns the Python-specific how: the tooling contract, style, typing, async, errors, packaging, and performance.

Every rule carries its why. Read the why before the rule — the point is that you understand the decision well enough to own it, not that you skim a checklist.

## 1. The tooling contract

The project names its tools once, in `AGENTS.md`, and every agent uses them. No improvising.

- **uv runs everything.** `uv run` for execution, `uv.lock` committed for deployables, CI installs with `--locked`. The lockfile is what makes "tests pass" mean something — without it the dependency set drifts between runs and a green suite proves nothing about the next install. PEP 735 dependency groups replace ad-hoc `requirements-dev.txt`.
- **Ruff is the linter and the formatter.** One tool replaces black/isort/flake8/pylint — say so explicitly in `AGENTS.md` ("do not call Black, flake8, isort, or pylint") so agents stop reaching for the old stack.
- **Deliberate rule selection, never `select = ["ALL"]`.** Enable what the project means: `E,F,W` (errors), `I` (imports), `N` (naming), `UP` (pyupgrade), `B` (bugbear — catches the classic agent traps below), `C4` (comprehensions), `SIM` (simplify), `S` (bandit security), `ASYNC` (async correctness), `PT` (pytest style), `RET` (return discipline), `PERF`, `DTZ` (datetime correctness), `RUF`. ALL drowns the signal in style noise and teaches agents to ignore the linter — the opposite of lint-is-law.
- **One type checker, named with its exact command.** mypy and pyright both work; the project names one as the CI gate. A fast checker in the editor is a complement, not the gate.
- **pytest conventions:** fixtures in `conftest.py`, `@pytest.mark.parametrize` over copy-pasted test functions, `tmp_path` over hand-rolled tempdirs, `asyncio_mode = auto` so async tests just work, `pytest-xdist` plus `pytest-randomly` for speed and order-independence.
- **pre-commit gates the commit:** ruff hooks, the type checker via `uv run`, and the uv lock hooks. The gate runs before the commit exists, not after.

Why this section comes first: every rule below is cheaper when a tool enforces it. The contract turns style from advice into a gate.

## 2. Style: what the linter can't catch

- **Import modules, not names.** `import os.path`, not `from os.path import join`. Why: the call site says where the name came from, so the reader never hunts the import block to resolve a bare name — and two modules exporting the same name stop colliding silently.

```python
# Bad: where did `join` come from — os.path or shlex?
from os.path import join
p = join(a, b)

# Good: the module is the namespace
import os.path
p = os.path.join(a, b)
```

- **No relative imports.** `from .models import User` breaks the moment the file moves or the package runs as a script. Absolute imports survive reorganization.
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

- **Don't shadow builtins.** `list`, `dict`, `id`, `type`, `input` as variable names break the reader's mental model and any later code in the scope that needs the real builtin. Name it `items`, `payload`, `user_id` — don't wait for the linter to flag it.

## 3. Typing

**Validate at the boundary, then trust inside it.** Parse untrusted input — HTTP bodies, message payloads, tool results, external API responses — into typed models at the entry point. Past that line, pass typed objects. This is `ENGINEERING_PRINCIPLES.md` §1's information hiding made concrete: parsing and validation rules live in one place instead of every consumer re-checking `if "field" in payload`.

**Pass typed values across module boundaries when the shape is known.** A `dict[str, Any]` in a signature moves the contract out of the type system and into the reader's memory. It is the Python form of the shallow module — the caller must know the internals to use it.

**The exception is content that is genuinely open.** Some payloads have no fixed shape by design: a passthrough body owned by another team, arbitrary metadata, a JSON column. Modelling those with a rigid type is worse than not modelling them, because the type claims a guarantee the data doesn't honor. Carry them as an explicit opaque type — a `JsonValue` alias — and keep it opaque rather than reaching inside. The rule targets dictionaries standing in for a shape you actually know; it doesn't require inventing shapes you don't.

**Prefer generated models where a schema exists.** When you own or consume a real schema, generate models from it where tooling makes that reliable and verify drift in CI. Where no usable schema exists, use a hand-written narrow adapter: validate at the boundary, convert to your own types, and let contract tests pin the behavior you depend on.

**Annotate public functions.** Where there is no external schema, the annotation is part of the contract. The type checker runs in CI so the contract gets automated verification.

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

**The proportionality rule:** size the execution strategy to the work and its bound. Run network and unbounded blocking I/O through awaitable paths. Run small, bounded, local work — a startup config read, a few-kilobyte file read outside the hot path, an in-memory transform — inline when the cost of offloading exceeds the blocking risk. Treat unknown-size files and paths that might be network mounts as unbounded.

Use `asyncio.to_thread` for unavoidable synchronous **I/O-bound** work, such as a blocking library with no async API.

For materially CPU-bound Python work, use an appropriate process pool, worker process, or other off-process execution strategy rather than assuming a thread makes the work parallel. `to_thread` can be appropriate for CPU-heavy extension code only when the implementation releases the GIL or the runtime provides equivalent parallelism.

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

**When layer 1 is not available yet.** This layering assumes the codebase has somewhere to carry a request deadline. When request context or a deadline object is absent, configure the bound on the client — layer 2 — where it belongs, and note that the budget needs end-to-end wiring.

A locally guessed five seconds buried three frames deep is harder to find and fix later than an unwired budget you explicitly identified.

Establish the deadline convention as its own task. Keep it separate from unrelated changes.

**The common failure:** wrapping every `await` in `asyncio.timeout` with a locally invented number. Nested deadlines disagree, the innermost one wins by accident, the budget becomes fiction, and a slow dependency trips a two-second inner timeout while the caller was willing to wait thirty.

## 5. Errors and exceptions

**Define a domain exception hierarchy where callers need to distinguish failure classes.** Raise meaningful types rather than bare `Exception`. Let callers distinguish failures through types and structured data rather than message strings.

Do not invent an elaborate hierarchy when the application has no callers that need the distinction.

**Handle exceptions explicitly and preserve outcome accuracy.** Use narrow catches with defined recovery. A broad, silent catch such as `except Exception: pass`, or a catch that logs and continues as though the operation succeeded, hides the outcome.

Catching a specific expected exception and handling it is correct code. Legitimate examples:

* `FileNotFoundError` during idempotent cleanup of something that may already be gone;
* `KeyError` when probing genuinely optional data — though `.get()` may express the intent more clearly;
* a known client exception triggering a defined fallback whose correctness is stated;
* `TimeoutError` entering an explicitly designed degraded path.

The distinguishing test is whether the caller receives an accurate picture.

Handle a narrow, named exception with a defined recovery. Surface a broad failure when the operation's outcome remains uncertain.

**The overcorrection:** propagating every exception for safety, so an optional cache read or best-effort notification takes down a request that only needed its core operation to succeed. Exception discipline preserves honesty about what failed while allowing defined recovery.

**Preserve the exception chain.** Use `raise DomainError(...) from err` so the original traceback remains available to the person debugging at 2 AM.

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

**Log only the environment values needed for diagnosis.** The environment contains secrets by construction (`ENGINEERING_PRINCIPLES.md` §6).

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
