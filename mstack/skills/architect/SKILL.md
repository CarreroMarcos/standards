---
name: architect
description: Use when non-trivial work needs a shape before code — sketching types, signatures, and module boundaries, comparing structurally distinct candidates, and recording why one won.
---

## When to use

Code written before the shape is decided calcifies around the first idea
that compiled. Reach for `architect` when the design itself is the risky
part — new modules, changed boundaries, any work where a wrong structure
costs more than a wrong line.

## Procedure

1. **Ground before sketching.** Map every system the change touches by
   reading its code — a filename list is not a map. Where the territory
   is unfamiliar, run the `how` skill and produce its traced model; where
   the design moves ownership or layering, run the `why` skill so the
   existing rationale constrains the new shape instead of being guessed
   at. Only genuinely greenfield work with nothing to integrate against
   may skip this phase.
2. **Sketch competing shapes.** Produce at least two candidates with
   genuinely different structures — different boundaries, different
   ownership. Polishing one idea twice is not designing. Start each
   candidate from the caller's usage, then derive types, signatures, and
   module boundaries, leaving `not implemented` bodies where code comes
   later. Who produces the candidates is the harness's business
   (HARNESS.md); that there are two and they differ structurally is the
   protocol's. Screen each candidate against the eight tripwires before
   any synthesis:
   - **Shallow module.** A big interface with thin behavior behind it —
     callers stitching several calls to do one thing. Depth is capability
     per unit of surface, not call-chain length.
   - **Information leakage.** One decision living in two places — a
     format, a policy, a protocol detail. Parse external shapes into
     domain types at the boundary; nothing internal crosses it.
   - **Temporal decomposition.** Modules named after pipeline stages
     instead of owned knowledge. Guard the same decisions in one place,
     whenever they run.
   - **Pass-through method.** A layer that forwards without deciding.
     Either it adds policy or it goes.
   - **Split ownership.** Two writers on one state, or two copies drifting
     apart. One owner; everyone else reads or requests.
   - **Two ways to do one task.** Duplicate paths multiply callers. Keep
     one; migrate the rest and delete them together. The license covers the duplicate paths this pass migrates and deletes together; anything wider gets destructive-scope confirmation — state the exact scope and wait for the human.
   - **Importable internals.** Anything reachable gets imported and
     becomes interface. Unreachable-by-construction is the only guarantee
     that holds.
   - **Hand-synced list.** Parallel lists edited in lockstep. One source
     of truth; the rest derived, or the build fails when they disagree.
   Judge each candidate from the next contributor's chair: an agent that
   opens a few files, copies the nearest example, and ships the first
   thing that compiles. The winning shape is the one where that workflow
   still lands in the right place.
3. **Lock the synthesis.** Pick the candidate that buries the most
   complexity behind the narrowest public surface. Write the synthesis
   decision down — chosen, rejected, why — and say every assumption out
   loud (`state-assumptions`); nothing builds until the decision is on
   record (`recorded-decisions`). To stress-test the sketch before
   building, run the `interrogate` skill on it. Pushback after the fact
   is new evidence: return to step 1, then step 2, before writing more
   code.
4. **Build to the sketch.** Fill `not implemented` bodies with code and
   pseudocode with logic. The sketch binds both sides. When reality
   diverges — a function needs something the sketch never drew — stop and
   name it: wrong sketch, missed requirement, or overreaching
   implementation. Absorbing it quietly is not an option.
5. **Kill a bad sketch.** Friction the sketch cannot absorb, repeating
   across the implementation, means the design is wrong — not the code.
   Read the pattern across instances: recurring workaround shapes, edge
   cases multiplying special branches, types that only compile with
   escape hatches, callers forced to learn internals. Isolated rough
   edges do not count; data may be complex while the design stays simple.
   To restart: re-run `how` on what exists, treat the new constraints as
   day-one knowledge, shrink before growing — the replacement starts
   smaller than what it replaces — and sketch again from step 2. The replacement's license covers the implementation it restarts; anything wider gets destructive-scope confirmation.

## Output

The design package:

- The caller's usage sketch first, types derived from it
- The candidates with each one's tripwire screening
- The rationale — chosen, rejected, why — with the synthesis decision
- Assumptions stated out loud, decision on record before building
- Deleted paths named — the duplicate paths migrated and deleted together, and the implementation the restart replaced
