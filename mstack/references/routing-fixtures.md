# Routing fixtures

The hub router's test data. One row per prompt: the prompt text, the
route it must take, and the intake verdict it must draw. **This file is
data, not prose**: update it deliberately, in the same change that alters
routing semantics — a routing edit that changes a row's correct answer
without updating the row is a silent break. Never edit a row to make a
failing simulation pass; that is tuning the test to the code.

- Source: the routing stress campaign's blind-router matrix (19 prompts,
  P1–P16 and F1–F3); F4–F5 added with the direct-answer boundary fix;
  P17 + F6 added with the rebuild-from-contract route (2026-10-20). The
  campaign's raw router walks are not part of mstack; this file is the
  durable fixture, reviewed as data.
- Expected routes encode the hub's intended semantics as written on
  disk: the question valve declines the locate / summary /
  what-does-X-do family; the skill-symptom check runs before the
  catch-all; the intake gate's reversibility escape routes
  unanchored-comparative asks to the skill whose contract supplies the
  done-check; CONFIRM stands down when the routed runbook owns the
  authorization itself.
- Verification corrections (2026-10-20, router-clause run for the
  rebuild-from-contract change): five blind sims routed every row
  correctly (115/115) but returned CLEAN unanimously on P12 and P17
  against this file's PROCEED. The rows were the anomaly: skill-contract
  done-checks already counted as CLEAN-compatible (P1/P2/P6/P14), and
  nothing in the hub treats a runbook's exit predicate differently.
  P12/P17 corrected to CLEAN, F5's route named as the `how` skill (5/5
  sims), and the hub's CLEAN arm now states the rule. The confirmation
  round against the amended text then returned P7 CLEAN 5/5 — the same
  anomaly class (a runbook that owns its whole loop; findings are read,
  not assumed on) — so P7 is corrected to CLEAN on the same grounds. These are
  deliberate semantics corrections, recorded here — not tuning to a
  failing sim: the same run left P8 at PROCEED against a 3/2 CLEAN
  split, because its correctness predicate is genuinely unstated.
- Verification corrections (2026-10-26, router-clause run for the
  contradiction-audit + .gitignore change): five blind sims returned CLEAN
  unanimously on P13, F4, and F5 against this file's PROCEED — the same
  anomaly class as the 2026-10-20 corrections (skill-contract done-checks
  already counted as CLEAN-compatible in P1/P2/P6/P14, and nothing in the hub
  treats a read-only analysis row differently). P13/F4/F5 corrected to CLEAN,
  F4's route named as the `how` skill (5/5 sims). Residual splits left as-is:
  P8's route (validate-only in 3/5 sims, verdict PROCEED unanimous — the
  pairing question is genuinely debatable, no done-claim in the prompt),
  P15 (4/5 PROCEED) and P16 (4/5 PROCEED) — majority agrees with the fixture,
  the minority reads are defensible judgment calls, not text bugs.
- Method: one simulation = one fresh agent routing every row blind (the
  expected columns withheld), walking the pre-invocation filter → intake
  gate → trigger table → skill-symptom check in `hub.md`, quoting the
  deciding text for each row. Any divergence from a row's expected route
  or intake verdict is a finding. The number of simulations per
  verification run is `values.md#router.simulation-count`; the clause
  that runs them lives in `runbooks/skill-authoring-run.md`.

| ID | Prompt | Expected route | Expected intake verdict |
|----|--------|----------------|--------------------------|
| P1 | find me bugs and simplify the uncommitted work | skills: `hunt-bugs`, then `simplify` (hunt first) | CLEAN |
| P2 | simplify the validate module, don't change behavior | skill: `simplify` solo | CLEAN |
| P3 | this code is too complicated, make it simpler | skill: `simplify` solo (the skill's contract supplies the done-check) | PROCEED |
| P4 | the worker keeps crashing, I don't know why | `runbooks/debugging.md` | PROCEED |
| P5 | can you find where the retry logic lives? | declined: direct answer (a locate — no work loop) | NEVER-ASKED |
| P6 | brainstorm three approaches for the retry logic in the worker | skill: `architect` solo | CLEAN |
| P7 | review the open PR and address the findings | `runbooks/bot-review-loop.md` | CLEAN (CONFIRM stands down — the runbook owns push authorization) |
| P8 | is this function correct? prove it | skills: `validate`, then `prove-it` (pinned order) | PROCEED |
| P9 | fix this typo in the README | declined: small-edit | NEVER-ASKED |
| P10 | what does the ingress lambda do? | declined: direct answer (a what-does-X-do) | NEVER-ASKED |
| P11 | make the worker faster | `runbooks/figure-it-out.md` with a measurement step | PROCEED |
| P12 | I'm about to merge, give it a final check | `runbooks/final-gate.md` | CLEAN |
| P13 | are there security issues in the webhook handler? | skill: `hunt-bugs` solo (security as a bug-class lens) | CLEAN |
| P14 | write the test first, then implement the SQS handler fix | skill: `tdd` (the skill check runs before the catch-all) | CLEAN |
| P15 | how will we verify this works before shipping? | skill: `verification-planning` solo | PROCEED |
| P16 | find the bug in this stack trace: KeyError: 'severity' at findings.py:42 in render | `runbooks/debugging.md` | PROCEED |
| F1 | clean up the formatting in lambda/common/diff.py | declined: small-edit | NEVER-ASKED |
| F2 | find the function that validates webhooks | declined: direct answer (a locate; `hunt-bugs` must not fire) | NEVER-ASKED |
| F3 | summarize what the last commit did | declined: direct answer (a summary) | NEVER-ASKED |
| F4 | run the retry logic and report what it does | work loop via the `how` skill, not a direct answer (requires code execution — past the valve boundary) | CLEAN |
| F5 | summarize how auth works across the worker and API | skill: `how` (past the valve boundary — multi-file synthesis is a work loop, not a direct answer) | CLEAN |
| P17 | the fanout module got wiped, rebuild it so everything works again | `runbooks/rebuild-from-contract.md` | CLEAN |
| F6 | the worker keeps crashing and the fanout module looks suspicious, find what's wrong | `runbooks/debugging.md` (present-but-broken is debugging; rebuild is only for gone-or-replaced) | PROCEED |
