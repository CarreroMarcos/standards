---
name: hunt-bugs
description: Use when you want latent bugs found in working code or a diff under review — a systematic hunt that reports only bugs it can prove with a concrete trigger.
---

# Hunt Bugs

## Purpose
Find real bugs hiding in working code — every finding proven, none speculative.

## Workflow
1. **Charter.** State the scope (files or diff) and the bug classes under hunt. Time-box the hunt.
2. **Hunt with lenses.** Read the code once per bug class (`references/bug-classes.md`): boundaries, error paths, state, concurrency, resources, security, logic. One lens at a time — a lens you skip is a class you declare clean.
3. **Prove each candidate.** A finding needs a concrete trigger: an input, a trace, or a failing test that demonstrates the bug. "Might fail if…" without the trigger is not a finding — file it as a hypothesis or drop it.
4. **Report.** File:line, bug class, the trigger that proves it, severity.

## Output Contract
- Findings: file:line + bug class + concrete trigger + severity (wrong behavior, crash, security, data loss).
- Non-findings: bug classes examined and declared clean, one line each.
- No fix code unless asked — findings first; fixes are a separate task.

## Operating Rules
1. No speculative findings. If you cannot name the input or trace that triggers it, it is not a bug report.
2. Do not fix while hunting — a hunt that edits code is a refactor wearing a hunt's clothes.
3. Rank by proof strength, not scariness. A proven crash beats a hypothetical exploit.
4. If the code is clean, say so — an empty findings list is a valid result.

Bug-class catalog → `references/bug-classes.md`.
