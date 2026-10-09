---
title: Typed Languages
version: "1.0"
scope: "Shared type-system discipline for typed languages (TypeScript, Java, ...)"
consult_when: "When designing a type, reviewing a function signature, or reaching for a boolean flag, an `any`/`Object` escape hatch, or a 'should never happen' throw — or when the review question 'can this combination actually happen?' comes up."
last_reviewed: 2026-10-08
---

# Typed Languages

Shared type-system discipline for the statically typed languages in the stack — TypeScript, Java, and anything else with a checker that runs in CI. Language-specific mechanics live in their own files (`languages/TYPESCRIPT.md`); this file owns the discipline those mechanics serve.

**Core principle:** make illegal states unrepresentable — the type checker is a proof assistant, and every case the types let you ignore becomes a runtime failure the compiler could have stopped.

Every rule carries its why — read it, don't skim past it. The point is that you understand the decision well enough to own it, not that you check a box.

## Sections

- **1. Sum types over boolean bags** — variants, not flag combinations
- **2. Constructive modeling** — build up from the values you want
- **3. Simplest total type** — strengthen only where partiality appears
- **4. Branded types** — semantic primitives that can't be mixed up
- **5. Exhaustive matching** — the compiler finds the unhandled variant
- **6. Parse at the boundary** — validate once at the edge, trust inside
- **7. Don't lie to the compiler** — no casts that bypass the checker

## 1. Sum types over boolean bags

**Model variants as sum types.** Never model state as a bag of optional fields where contradictory combinations compile. The comment test: "Can I write a comment explaining when this combination of fields is valid?" If yes, the type is too loose — split it into a sum type. Discriminated unions in TypeScript, sealed classes in Java, enums with payloads in Kotlin/Rust/Swift.

```typescript
// Bad: admits { completed: true, completedAt: undefined } — meaningless
interface Task { completed: boolean; completedAt?: Date }

// Good: the impossible state can't be constructed
type Task = { kind: "open" } | { kind: "done"; at: Date };
```

The subtle anti-pattern: a boolean derived from data should be *derived*, not stored — `completedAt != null` is the source of truth, not a second field that can disagree with it. If a bug ever forces the question "wait, can this combination actually happen?", the type is too loose.

- Why: a contradictory combination that compiles is a runtime branch someone has to defend with comments and runtime checks — the checker was supposed to kill it for free.
- Boundary: one field, local to a single function — a literal union there is fine without a named sum type. The rule targets states that travel across functions and files.

## 2. Constructive modeling

**Build the type up from the values you want instead of carving them out of a looser type with checks.** Types are constructions, not restrictions. The invariant that seems to need a refinement type is usually a construction away: a non-empty list is a head plus a rest, not a list with a length check; a valid time range is a start plus a duration, not two timestamps you must keep ordered; an even-length list of pairs is `[T, T][]`, not a list you assert has even length. No representation is privileged — choose the shape that cannot build the illegal value, then expose the interface callers need on top.

```typescript
// Bad: carves "non-empty" out of a plain array with a runtime wish
function first(items: string[]): string {
  if (items.length === 0) throw new Error("should never happen");
  return items[0];
}

// Good: the shape cannot build the illegal value — no guard, no throw
type NonEmpty<T> = [T, ...T[]];
function first<T>([head]: NonEmpty<T>): T {
  return head;
}
```

- Why: a runtime guard against an unconstructable value is a "should never happen" throw wearing a seatbelt — it can fire, so it's a failure mode you own; a constructive type moves the failure to compile time, where it's free.
- Boundary: expose the interface callers need on top of the construction — the internal shape is your business, but callers shouldn't have to destructure tuples by hand to ask a natural question.

## 3. Simplest total type

**Keep the plain type while every operation on it stays total. Strengthen to a narrower type only where the loose type forces a `!`, a cast, or a "should never happen" throw.** `sum` of an empty list is 0, so it takes the plain list. `head` of an empty list has no answer, so it demands the non-empty one. A runtime assertion, null check, or impossible-case throw marks the place a type is too weak — push that check up into the type, then stop.

The distinguishing test: "Am I strengthening this type to keep an operation total, or just to be more precise?" If nothing would otherwise panic or cast, keep the plain type.

```typescript
// Bad: precision for its own sake — narrowing a signature nothing forces
function total(items: NonEmpty<number>): number {
  return items.reduce((a, b) => a + b, 0);
}
// The plain list is already total for sum: the narrower type buys nothing
// and rejects valid input — total([]) should be 0.

// Good: the strength is earned — `!` was the symptom
function firstOrDefault<T>([head]: T[], fallback: T): T {
  return head ?? fallback;  // total on the plain type: no narrowing needed
}
function firstStrict<T>([head]: [T, ...T[]]): T { ... }         // head has no answer on [] → narrow here
```

- Why: the type system's job is to track the cases each use site must handle, not to describe the data as precisely as possible — maximal precision without a totality reason is annotation theater that every reader pays to parse.
- Boundary: the `!`/cast/throw is the tripwire, not the aesthetics. Never strengthen a type because the narrower version "feels more correct."

## 4. Branded types

**Brand semantic primitives so they can't be mixed up.** `UserId` and `OrderId` are strings underneath but must not be interchangeable. Validate once at creation, trust the type downstream.

```typescript
// Bad: two stringly-typed IDs — one swapped argument compiles fine
function transfer(from: string, to: string, amount: number) { ... }

// Good: the brand makes the swap a compile error
type UserId = string & { readonly __brand: "UserId" };
type OrderId = string & { readonly __brand: "OrderId" };
function transfer(from: UserId, to: UserId, amount: number) { ... }
```

In Java the same rule renders as a thin wrapper (`record UserId(String value) {}`) — one constructor, one validation site, zero mix-ups downstream.

The branding test: "Do two of my function arguments share a primitive type but mean different things?" Brand them.

- Why: swapped-argument bugs compile, pass type checks, and surface as wrong data in production — the brand converts a silent corruption into a compile error at the call site.
- Boundary: brand at creation and trust downstream — re-validating a branded value inside the system is the same "validate at the boundary, trust inside" rule (§6) restated. Don't brand throwaway locals that never cross a function boundary.

## 5. Exhaustive matching

**When you match on a sum type, the compiler must fail compilation if a new variant is added without handling.** Use the idiom your language provides: a `never`-typed binding in the default arm in TypeScript, sealed-class pattern-match exhaustiveness in Java. The goal is that adding a variant next month tells the *next* agent exactly where to add a case.

```typescript
// Good: adding a variant breaks the build at every unhandled site
function render(shape: Circle | Square): string {
  switch (shape.kind) {
    case "circle": return "circle";
    case "square": return "square";
    default: {
      const _exhaustive: never = shape;  // compile error when Triangle lands
      throw new Error(`unhandled shape: ${_exhaustive}`);
    }
  }
}
```

The exhaustiveness test: "If a new variant is added next month, will the compiler tell the next agent where to add a case?" If no, the match isn't exhaustive — it's a runtime `default` that silently absorbs the new case.

- Why: an unhandled variant that falls into a `default` arm is a behavior decision made by whoever wrote the default, not by whoever added the variant — the wrong person decides, silently.
- Boundary: the never-binding goes in genuinely dispatching matches on sum types. Don't sprinkle it on switches over booleans or open string sets where "new variant" isn't a meaningful event.

## 6. Parse at the boundary

**External data is untyped until parsed.** RPC payloads, JSON, CLI args, config files, environment variables, database rows. Put one parse function at every boundary that turns unstructured input into the named domain type — and let the untyped shape stop there. Past that line, pass typed objects and trust them. This is `ENGINEERING_PRINCIPLES.md` §1's information hiding made concrete: parsing and validation rules live in one place instead of every consumer re-checking `if "field" in payload`.

```typescript
// Bad: the untyped shape travels three layers deep, every consumer re-checks
function handle(req: Record<string, unknown>) {
  const items = (req.body as any).items;  // re-proving the shape, again
  ...
}

// Good: one parse at the edge; consumers take the type
const order = OrderRequest.parse(req.body);  // throws here, once, with the why
process(order);                              // typed from here down
```

- Why: validation scattered across consumers means N places that can disagree about the contract and N places to update when it changes — one parse site is one source of truth.
- Boundary: the exception is content that is genuinely open by design — a passthrough body owned by another team, arbitrary metadata. Carry those as an explicit opaque type and keep them opaque rather than reaching inside; the rule targets shapes you actually know, not shapes you're inventing.

## 7. Don't lie to the compiler

**Casts, unsafe coercions, and assertion functions that bypass the checker are latent runtime crashes.** If the compiler can't prove a fact, prove it — validate, narrow, or refine the model — or accept that the cast is a hazard you're carrying. A lying type guard is worse than a cast, because the bug hides behind a name that says it's safe.

The trace test: "Where did this `as`, this `!`, this assert-not-null come from?" Trace it to the boundary and validate there instead of asserting here.

```typescript
// Bad: the cast asserts what validation should have proven
const config = JSON.parse(raw) as Config;

// Good: the parse proves it; the type follows the proof
const config: Config = ConfigSchema.parse(JSON.parse(raw));
```

- Why: every bypass teaches the checker to stop checking at exactly the line where the data is least trustworthy — the lies compound, and the first runtime crash lands far from the cast that caused it.
- Boundary: a cast *after* validation is not a lie — it's the checker catching up to a fact you proved. The rule targets casts that substitute for proof, not casts that follow it.
