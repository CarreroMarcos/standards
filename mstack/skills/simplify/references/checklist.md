# Simplify verification checklist

Run after the pass, before reporting done:

- [ ] All tests pass **unmodified** — a test edited to pass means behavior changed.
- [ ] The diff touches only the task's files — no drive-by refactors.
- [ ] No error handling, validation, or guards weakened or removed.
- [ ] No `try/except` removed — restructuring error handling must preserve the contract (see SKILL.md rule 3).
- [ ] No generic name replacing a descriptive one — `data` / `tmp` / `result` are fine where no meaningful name existed.
- [ ] Read the result cold. Still confusing → the simplification didn't land; revert and try smaller.
- [ ] Each change was checked individually — no batched simplifications with one test run at the end.
