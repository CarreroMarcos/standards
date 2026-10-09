---
title: TypeScript Standard
version: "1.0"
scope: "TypeScript-specific mechanics: strictness, narrowing, casts, guards, schemas, call style"
consult_when: "When writing TypeScript and reaching for `any`, `as`, a hand-written type guard, or a brand-new interface — or when the question is how the typed-languages discipline renders in TS syntax."
last_reviewed: 2026-10-08
---

# TypeScript Standard

TypeScript-specific mechanics. The discipline — sum types, constructive modeling, total types, branding, exhaustive matching, boundary parsing — lives in `languages/TYPED-LANGUAGES.md`. This file owns the TS syntax that serves it.

**Core principle:** the checker is only as honest as you are — never write a line that teaches it to stop checking.

Every rule carries its why — read it, don't skim past it. The point is that you understand the decision well enough to own it, not that you check a box.

## Sections

- **1. Strictness is a team posture** — name the flags once in tsconfig
- **2. `unknown` over `any`** — external data is `unknown`
- **3. Schemas before guards** — infer from the schema, don't hand-roll the parallel type
- **4. The narrowing hierarchy** — discriminant switch down to `as`, never below it
- **5. No `as` casts** — every `as` is a runtime crash waiting
- **6. Type guards must verify the claim** — a lying guard is worse than `as`
- **7. `satisfies` over `as`** — validate without widening
- **8. Derive types from what owns them** — `Pick`/`Omit`/`Parameters` before a new interface
- **9. Object args** — argument order self-documents, except on hot paths
- **10. Structured telemetry** — no `console.log` in shipped code

## 1. Strictness is a team posture

**Name the checker, its strictness, and what `any` is allowed to mean once — in `tsconfig.json`, not per file.** `strict: true` is the floor; name the extras the project means (`noUncheckedIndexedAccess`, `noImplicitOverride`) the same way. The strictness level is a team posture, not a per-file negotiation.

- Why: strictness negotiated per file drifts toward the loosest file — one `// @ts-nocheck` becomes the pattern, and the checker becomes advisory where the code is hardest.
- Boundary: generated files and vendored shims may carry their own settings; hand-written source never does.

## 2. `unknown` over `any`

**External data is `unknown`.** `any` disables the checker for that value and everything downstream of it; `unknown` forces narrowing before use — which is exactly the work §3's parse step does.

```typescript
// Bad: the checker is off from here down
const payload: any = JSON.parse(raw);
payload.items.forEach(...);  // any typo here compiles

// Good: use is gated on proof
const payload: unknown = JSON.parse(raw);
const order = OrderSchema.parse(payload);  // §3 does the proving
```

- Why: `any` is contagious — it flows through assignments and return types, silently un-checking every function it touches.
- Boundary: inside a parse function that is actively narrowing, a local `any` that never escapes the function is contained damage, not a lie. Contain it; never export it.

## 3. Schemas before guards

**Before hand-writing a property-by-property type guard, use the repo's runtime schema library and infer the type from the schema.** A hand-rolled guard is a parallel definition of a shape the schema already owns — the two drift, and the guard drifts toward the lying kind (§6).

```typescript
// Bad: parallel definition, maintained by hand, verified by hope
function isOrder(x: unknown): x is Order {
  return typeof x === "object" && x !== null && "id" in x /* ...and 12 more fields */;
}

// Good: the schema is the definition; the type is derived
const OrderSchema = z.object({ id: z.string(), items: z.array(ItemSchema) });
type Order = z.infer<typeof OrderSchema>;
```

- Why: one definition means the runtime validation and the compile-time type can't disagree — a hand-written guard lets them drift silently, which is worse than no guard at all.
- Boundary: where the repo has no schema library and adding one is out of scope, a hand-written guard earns its place by verifying its full claim (§6) — the rule prefers the schema, it doesn't mandate a dependency.

## 4. The narrowing hierarchy

**Narrow in this order, and stop as high as you can: discriminant switch > `in` operator > `typeof`/`instanceof` > user-defined type guard > `as`.** Each step down is a step away from compiler-verified truth. `as` is the floor — never below it, and rarely at it.

```typescript
// Best: the discriminant is compiler-verified
switch (shape.kind) {
  case "circle": return shape.radius;  // narrowed, no guard needed
  ...
}

// Lower: user-defined guard — only when the shape has no discriminant
function isCircle(s: Shape): s is Circle { return "radius" in s; }
```

- Why: the hierarchy is a cost ladder — higher rungs get the compiler to do the proving, lower rungs make you do it by hand, and hand-proving is where the lies creep in.
- Boundary: reaching for a lower rung is fine when the higher ones genuinely don't apply (no discriminant on the wire shape). Skipping a rung that does apply is the violation.

## 5. No `as` casts

**Every `as` is a runtime crash waiting. Cast only after validation.** The cast asserts what validation should have proven — and the compiler believes you, which is the problem.

```typescript
// Bad: asserts the shape instead of proving it
const config = JSON.parse(raw) as Config;

// Good: the parse proves it; the type follows the proof
const config = ConfigSchema.parse(JSON.parse(raw));  // Config, proven
```

The one legitimate `as`: after validation, where the checker can't follow the proof you just ran — and then the cast sits on the line directly after the validation, so the proof is visible.

- Why: a cast converts "the compiler can't prove this" into "the compiler trusts me" — at exactly the line where the data is least trustworthy. The crash lands far from the cast that caused it.
- Boundary: casts that *narrow* a proven value (e.g. `as const` for literal inference) aren't bypassing anything — the rule targets casts that widen trust, not ones that sharpen it.

## 6. Type guards must verify the claim

**A type guard must verify the claim it makes. A lying guard is worse than `as`, because the bug hides behind a name that says it's safe.** Name guards `isX` or `hasX`, and make the body prove the whole shape — not one field of it.

```typescript
// Bad: checks one field, claims the whole type — the lie wears a safe name
function isOrder(x: unknown): x is Order {
  return typeof x === "object" && x !== null && "id" in x;
}

// Good: verifies the discriminant the sum type actually dispatches on
function isOrder(x: unknown): x is Order {
  return typeof x === "object" && x !== null && (x as { kind?: unknown }).kind === "order";
}
```

Prefer the discriminant check over a field-by-field census — it's cheaper and it matches how the type is actually consumed (§4). And prefer a schema (§3) over any hand-written guard at all.

- Why: callers trust the `isX` name and stop checking — a guard that verifies half the shape moves the unchecked half into every call site that trusted it.
- Boundary: a guard on a genuinely open shape (no discriminant, no schema) may verify the fields the consumer actually needs — but then the name must say so (`hasOrderId`, not `isOrder`).

## 7. `satisfies` over `as`

**Use `satisfies` to validate a value against a type without widening its literal types.** It checks the value *and* keeps the narrow type — `as` checks nothing and widens everything.

```typescript
const config = {
  mode: "strict",
  retries: 3,
} satisfies Config;  // errors if it doesn't fit Config...

type Mode = typeof config.mode;  // ...but stays "strict", not string
```

- Why: literal types are information — `"strict"` vs `string` is the difference between an exhaustive check that works and one that doesn't. `as` throws that information away at the exact moment you needed it checked.
- Boundary: `satisfies` is for values whose literal types you want to keep. When you genuinely want the widened type, annotate it — don't launder the widening through `as`.

## 8. Derive types from what owns them

**Reach for `Pick`, `Omit`, `Parameters`, `ReturnType`, `Awaited`, and `typeof` before declaring a new interface.** When a schema, an API response, or another module owns a shape, derive from it instead of hand-rolling a parallel type.

```typescript
// Bad: a parallel shape that drifts from the source
interface CreateOrderInput { items: Item[]; customerId: string }
function createOrder(input: CreateOrderInput) { ... }

// Good: derived from what owns it — drift is impossible
function createOrder(input: Pick<Order, "items" | "customerId">) { ... }
type Handler = (req: Request) => Promise<Response>;
type Req = Parameters<Handler>[0];  // the handler's own signature is the source
```

The test: "Is this type duplicating a shape another file owns?" If yes, derive.

- Why: a parallel type is a second source of truth — the source changes, the copy doesn't, and the mismatch compiles until it doesn't.
- Boundary: derive from the *authoritative* owner — the schema, the function signature, the API definition. Deriving from another hand-rolled copy just chains the drift.

## 9. Object args

**Pass objects, not positionals, so argument order is self-documenting.** `download({ url, retries })` can't be mis-ordered; `download(url, 3)` can't be read.

```typescript
// Bad: unreadable at the call site, mis-orderable
createUser(name, email, true, false);

// Good: every argument names itself
createUser({ name, email, sendWelcome: true, dryRun: false });
```

Skip on hot paths — per-frame render, tokenizers, parsers — where allocation is measured, not imagined. The rule targets human-called APIs, not inner loops.

- Why: positional arguments past two are a memory test at every call site — and a swapped-argument bug that the types can't catch when two parameters share a type (see `TYPED-LANGUAGES.md` §4 for the type-level fix).
- Boundary: one or two obvious parameters (`map(fn)`, `get(id)`) don't earn the braces. The rule bites at three-plus, or whenever two parameters share a type.

## 10. Structured telemetry

**Prefer structured logger diagnostics with enough context to debug from an id. No `console.log` in shipped code.** A log line you can't query by request id is a line you wrote for nobody.

```typescript
// Bad: unsearchable, unstructured, ships to prod
console.log("order failed", orderId);

// Good: structured, correlated, queryable
logger.error("order.create failed", { orderId, userId, reason: err.code });
```

- Why: production debugging is a query problem — "show me everything for order X" — and `console.log` emits text that no query can filter.
- Boundary: `console.log` in a local scratch script or a failing-test debug session is fine; it dies with the session. The rule targets anything that ships.
