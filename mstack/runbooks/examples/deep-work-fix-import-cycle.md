---
name: deep-work-fix-import-cycle
description: >
  WORKED EXAMPLE — portable pattern, invented codebase. One instantiation of the
  deep-work runbook: three lanes splitting an import cycle, with the Grill, a
  lane brief, a phase-gate prompt, an adversary verdict, and a tombstone.
---

# Worked example — deep-work on an import cycle

One instantiation of `runbooks/deep-work.md`. The codebase is invented; the pattern is the point. Every section below maps to a runbook section — read them side by side the first time.

## The run

- **Goal:** split `config.py`'s import cycle. Done means `python -c 'import config'` exits 0 and `pytest tests/test_config.py` passes.
- **State dir:** `.mstack/runs/config-cycle/` (operator-named).
- **Lanes:**
  - **L1** — extract the `Settings` dataclass to `models/config.py`.
  - **L2** — rewrite the importers (`app.py`, `cli.py`) against the new location.
  - **L3** — regression pass: full test suite, no behavior change.

## The Grill (L1)

All seven questions, answered before dispatch:

1. **Goal restated:** `config.py` imports cleanly with zero cycles.
2. **Scope:** `config.py`, `models/config.py` (new), `app.py`, `cli.py`. Nothing else.
3. **Done-check:** `python -c 'import config'` exits 0; `pytest tests/test_config.py` green.
4. **Success type:** test — the suite is the verdict.
5. **Verify role:** verifier — checks the import graph, not just the tests.
6. **Max attempts:** 3, then the lane tombstones and the run re-plans.
7. **Context:** `config.py`, `app.py`, current import graph.

## Lane brief (L1, excerpt)

> Goal: extract `Settings` from `config.py` into `models/config.py`; `config.py` re-exports it. Acceptance: `python -c 'import config'` exits 0. Forbidden: don't touch `tests/`, don't change `Settings` fields. Report shape: `<summary> / <changes> / <verification>`.

## Phase-gate prompt (Gate 1, excerpt)

> Phase goal: lanes L1+L2 merged. Changed: `models/config.py`, `config.py`, `app.py`, `cli.py`. Evidence: pytest 41/41 green. Risk under review: L2 dropped a lazy import in `cli.py`. Attempt 1 of 3.

## Adversary verdict (excerpt)

> Attacked the lazy-import removal and the `Settings` mutation surface. Finding: `cli.py` now imports `Settings` at module load, breaking the env-var override ordering — `cli.py:14`. Coverage: import order, mutation surface; did not cover perf.

The finding routes back to a fixer lane with the evidence. The gate does not pass until the lane re-verifies.

## Tombstone (L3, when done)

> status: complete. conclusion: cycle split, 41/41 green, no behavior change. pointers: `.mstack/runs/config-cycle/progress.md`, `models/config.py`. date: 2026-10-09.

Six lines. The next run starts here, not from zero.
