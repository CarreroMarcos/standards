---
name: blast-radius
description: Use when "blast radius of X" or "what could this break" needs a real answer — hunt what a change breaks beyond the diff, then prove the single fact it is safe because of by running code, not by writing it up.
---

## When to use

A change is about to ship and you need to know what it breaks
somewhere else. Reach for `blast-radius` for "blast radius of X",
"what could this break", or a diff that looks small but doesn't smell
right. It works alongside `how` and `why`: `how` reads the behavior,
`why` digs up the reasoning, blast radius hunts the breakage elsewhere
when the code moves. Listing callers is not the job — grep handles
that. The job is the damage grep can't see.

## Procedure

1. **Read the change.** What the diff added, altered, and removed,
   and the behavior that differs now — including the part the diff
   never states.
2. **Find the ONE fact it's safe because of.** Risky-looking changes
   are usually safe because of one invariant: if it holds, the risky
   cases clear together. Put the hours into that fact, not into a pile
   of hypotheticals. **If no such fact exists, say so — that IS the
   finding.**
3. **Push the fact down the certainty ladder.** A writeup that reads
   convincing proves nothing — it sounds true whether it is or not. So
   drive the one fact down this list as far as it's cheap to go,
   and name the level it stopped at:
   1. Said-so. Worth nothing by itself.
   2. Pointed-at-line. A real `file:line`, or a pointer into the
      dependency's source tree.
   3. Walked-the-failure. You traced the bad case step by step and it
      can't get there.
   4. Ran-it. A script or test that executes the real code and fails
      loudly when you're wrong.
   5. Reproduced-in-app. The failure — or its absence — shown in the
      live application.
4. **Scale the ceremony to the radius** (`scale-ceremony`). A comment
   tweak doesn't earn the full ladder; a migration or an auth change
   does. Match the effort to the blast radius, never to the line count.
5. **Trace past what grep finds.** Open the dependency's actual source,
   verify its pinned version plus any local patch. Follow the paths a
   symbol search can't take: the shape of a downstream API's JSON, a
   database column a report reads, a wire format another service
   consumes, a feature flag, behavior three hops downstream. An empty
   search result is still evidence — record it. Never invent a caller.
6. **Be honest about what's left.** Split the residual into three
   lists: **Confirmed** — a genuine way it breaks, with the `file:line`
   and the cost if it hits. **Cleared** — checked and fine, with what
   checked it. **Unproven** — couldn't be nailed down; say so plainly
   and name the cheapest check that would.

## Output

The hand-back:

- **The one fact** — stated in one sentence.
- **Its ladder level** — where the fact stopped on the 5-level ladder,
  with the proof. If it couldn't be proven: **unproven**.
- **Scoped verification** — the cheapest test or script that matches
  the radius: what it ran and what came out.
- **Residual** — the confirmed / cleared / unproven lists, each risk
  with its breakage path, `file:line`, and how to check it.
