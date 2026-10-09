---
name: prove-it
description: Use when someone claims work is done — a fix landed, a feature works, a test passes — and the evidence so far is their word for it.
---

## When to use

A claim of "done" is on the table and you are the one who has to trust
it. Reach for `prove-it` whenever the evidence offered is a summary, a
green badge, or "it compiles" — anything short of the thing itself,
observed directly. This skill is the unmasked-verify step behind
`final-gate.md`, `skill-authoring-run.md`, and `figure-it-out.md`.

## Procedure

1. **Name the artifact and the claim.** Write down exactly what exists
   (the file, the endpoint, the behavior) and exactly what is claimed
   about it ("returns 200 for …", "deletes the row", "passes on …"). A
   claim you cannot point at is not verifiable — restate it until it is.
2. **Open the real state.** Read the actual file, not the diff summary.
   Re-run the actual test and read its actual output, not the CI badge.
   Drive the actual behavior and observe it — process liveness checked
   directly, the value read from the source, not from a cached or derived
   representation. **Never accept an agent's summary as evidence**
   (`orchestrator-verifies`).
3. **Razor the check.** Before trusting any test or check, ask: could
   this check pass if the thing it verifies were broken? **A check that
   cannot fail does not count** (`falsifiable-tests`). A test that would
   still pass if every function it imports returned nothing observes no
   behavior — rewrite the assertion or delete the test. A self-referential
   expectation (the expected value computed from the code under test) or
   a restated constant is not a check.
4. **Bracket the change.** For any claim that something changed, show the
   before and after as one verifiable unit: the known-broken (or
   known-prior) state, the single change, the check run on both.
   Failing-before and passing-after, each observed directly — a "before"
   reconstructed from memory is not a bracket.
5. **Suspect the observation before the system.** When verification
   fails, check your method first: stale cache, wrong file, derived state
   mistaken for source. Only after the observation is sound does the
   failure belong to the system.
6. **Close the loop.** **No completion claim without this evidence**
   (`prove-completion`). If the evidence is missing, the claim is
   unverified — say so, and say exactly what observation would verify it.

## Output

Per claim, one of:

- **Verified** — the claim, plus a pointer to the evidence (file:line,
  test output, observed behavior).
- **Unverified** — the claim, plus exactly what is missing and what
  observation would close it.
