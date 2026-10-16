---
name: simplify
description: Use when implementation is complete and working — run a simplification pass that removes complexity without changing behavior.
---

# Simplify

## Purpose
Make working code simpler to read and review — same behavior, less machinery.

## Workflow
1. **Scope.** Only code changed or touched by the current task. A broader refactor is a separate task, not a drive-by.
2. **Name the targets.** List the concrete simplifications before touching code — what will become easier to understand. No vague "clean up."
3. **One change at a time.** Make the smallest behavior-preserving change, run the narrowest relevant check, keep it only if behavior is preserved. Never batch simplifications.
4. **Verify.** All tests pass unmodified; the diff touches only the task's files; read the result cold — if still confusing, revert and try smaller.

## Output Contract
- The simplified code.
- Per change: what was simplified, and the check that proved behavior preserved.

## Operating Rules
1. Never change behavior to simplify — if a simplification needs a behavior change, stop and re-scope.
2. If tests had to be modified to pass, you changed behavior, not shape. Revert.
3. Never remove error handling, validation, or guards because they "look redundant" — credibility is decided by the code's contract, not its appearance.
4. Never simplify code you cannot fully explain — read more context first.
5. Over-simplification is a defect: no clever one-liners, no abstractions removed that carry a useful name, no concerns merged that were separate.

Signals catalog → `references/signals.md`. Verification checklist → `references/checklist.md`.
