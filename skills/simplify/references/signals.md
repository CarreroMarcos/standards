# Simplification signals

Concrete things to look for, each with the shape of the fix. Name which
signals you found in step 2 of the workflow — "clean up" without a named
signal is not a plan.

- **Deep nesting → guard clauses.** Invert the condition, return/raise
  early. Three nested levels is the smell; the fix reads top-to-bottom.
- **Long function, mixed responsibilities → extract.** One function does
  one thing; the extracted name documents the intent. Extract only what
  the task touched.
- **Repeated conditionals / duplicated logic → single source.** Two copies
  of a branch means two places to fix the next bug. (Production logic
  single-sourced; test code follows DAMP — don't import this rule into
  tests.)
- **Boolean flag arguments → split the function.** A flag that switches
  behavior is two functions wearing one name.
- **Wrapper that adds no behavior or no useful name → inline it.**
  Indirection must earn its keep.
- **Dead code, unreachable branches, obsolete comments → delete.**
  Flag during the pass; delete with proof (no callers, no references).
- **Generic or misleading names → rename.** The name should say what the
  thing is for, not what it is (`users_to_notify`, not `data`).
- **Compatibility shims with no remaining caller → delete.** Check
  callers first; a shim with one caller gets inlined.

Not signals: code you didn't touch, style preferences with no readability
gain, abstractions the team relies on, error handling you haven't proven
unreachable.
