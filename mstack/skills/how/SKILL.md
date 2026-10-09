---
name: how
description: Use when a "how does X work" question needs a real answer — code walkthroughs before changing something, placement and ownership questions, subsystem architecture, runtime flow. Grounds the explainer in the code before any theory.
---

## When to use

Theories about code are cheap; reading it is the work. Reach for `how`
when you need a working mental model of a subsystem — before changing
it, before moving it, before arguing about where it belongs. A
question with a one-line answer does not need this skill; a subsystem
does.

## Procedure

1. **Route by size, not by hope.** A narrow question — one function, one
   module, one "what calls this" — gets a direct answer: read the code,
   explain it, done. Never spin up the full machinery for a question one
   careful read answers. Ambiguity in scope gets stated up front: say how
   you read it, then let the caller redirect — then start. In doubt, take the
   small path. The code comes first and the theory after
   (`loop-before-theory`): no explanation may rest on code nobody
   opened.
2. **Split complex groundings into distinct angles.** A subsystem
   question gets 2 to 4 parallel explorers, each handed one distinct
   slice — runtime flow, data shapes, call graph, configuration surface.
   Never two explorers asking the same question: overlapping angles
   produce overlapping answers and teach nothing twice. Explorers are
   read-only — they map, they never change. Who spawns them is the
   harness's business (HARNESS.md); that they run parallel, stay
   read-only, and stay angle-distinct is the protocol's.
3. **One explainer synthesizes.** A single explainer takes every
   explorer's findings and writes one explanation — never a stapled
   bundle of explorer outputs. When explorers disagree, the explainer
   re-reads the code; contradictions are settled by the source, never by
   vote.
4. **Write to the fixed sections — and only them.** Overview, Key
   Concepts, How It Works, Where Things Live, Gotchas. Drop any section
   that does not apply; never invent a sixth. Every claim carries its
   location — the file and line that proves it. A section with no cited
   locations is a theory: rewrite it or cut it.

## Output

The five fixed sections, each grounded in cited locations:

- **Overview** — what the subsystem is for, in one paragraph
- **Key Concepts** — the vocabulary the code actually uses
- **How It Works** — the runtime flow, end to end
- **Where Things Live** — the map: files, modules, ownership
- **Gotchas** — the traps a newcomer hits, each with its location
