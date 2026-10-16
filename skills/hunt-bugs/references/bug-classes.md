# Bug-class catalog

Read the scope once per class. A class you don't read is a class you
declare clean — say so in the report.

## Boundaries
Off-by-one in loops, slices, and ranges. Empty input, single element,
maximum size. Integer division and rounding at the edges. Fencepost in
retry/backoff counts.

## Error paths
Swallowed exceptions (`except: pass`, caught-and-logged-and-continued).
Error returns the caller never checks. Cleanup that doesn't run on the
failure path (no `finally` / context manager). Error messages that leak
internals or swallow the cause.

## State
Mutable default arguments. Shared mutable state across calls. Stale
caches — invalidation missing on the write path. Order-dependent
behavior: works if called in one order, breaks in another.

## Concurrency
Unprotected shared mutable state across threads/tasks. Check-then-act
races. Deadlock from lock ordering. Assumptions about scheduling order.

## Resources
Unclosed files, connections, or handles on any path. Unbounded growth:
lists, caches, or queues with no cap or eviction. Expensive work
repeated per call that should be hoisted or memoized.

## Security (AI-generated code repeats these)
Secrets or credentials in code. Unauthenticated access to a new
endpoint. Overly broad CORS or permissions. Debug logging left in.
Unparameterized queries / injection points. Missing audit of new
dependencies.

## Logic
Inverted conditions. Wrong operator (`and`/`or`, `<`/`<=`). Early
return that skips required work. Branch that can never execute — or a
branch missing for a case the code claims to handle.
