---
title: Dev Loop — the agentic build loop, as operated
version: "1.4"
scope: Runbook for the agentic build loop (PR reviewer dev loop)
consult_when: "When operating the ticket to implement to verify to review to gate to merge loop."
last_reviewed: 2026-09-29
---

# Dev Loop — the agentic build loop, as operated

Reconstructed 2026-09-27 from live activity on the pr-reviewer repo (PRs
#75–#119), the repo's process docs, and the orchestrator's own account of a
session. This is the loop a unit of work travels from spec task to merged
main. Repo-specific names are marked; the shape is the reusable part.

## Sections

- **One pass, end to end** — the ticket → spec → PR → Oracle → merge shape
- **Loop Contract** — written before iteration 1: gates, budgets, blast radius
- **Orchestration patterns** — bounded fan-out, verifier merge, hold-out verification, sequential vs parallel
- **Roles** — fixer, bot reviewer, Oracle, orchestrator; who may do what
- **Platform vs. discipline** — what's repo-specific vs reusable
- **Human-side exceptions** — verbal approval only, and what it covers
- **Incidents that wrote the rules** — the history behind the gates
- **Failure handling** — every failure mode hit in practice
- **Loop Ledger** — the running record
- **Test discipline** — what the loop demands of tests
- **Environment** — where the loop runs
- **Verification terms** — unmasked verify and the other defined terms

## One pass, end to end

1. **Ticket.** Jira tickets are projections of `specs/<n>/tasks.md`
   (`tools/sync_tasks_to_jira.py`, run by the `sync-jira.yml` workflow;
   dry-run on PRs, manual dispatch otherwise). One ticket = one PR (pairs of
   related tasks can share one). One-off tickets may be created manually.
   Jira is progress tracking only — the HLD and the specs are the source of
   truth.
2. **Implement.** A fixer agent implements on a branch. The fixer never
   pushes and never merges — forbidden in every brief.
3. **Independent verify, pre-push (orchestrator).** Per-commit custody/scope
   check, full test suite in a clean shell, ruff/format, pre-commit. This is
   the "custody law": it exists because PR #114's squash accidentally
   carried in-progress code from a shared worktree's local main. Like the
   Oracle, the verifier never reads the fixer's reasoning — contract, gate
   output, and diff only.
4. **Push + PR.** `git push -u origin <branch>`, `gh pr create`.
5. **Bot rounds.** Wait ~120s (bot latency; +45s if the round is
   absent/errored/unchanged), then fetch the bot's canonical comment
   (fenced `pr-reviewer:canonical` marker — exactly one per PR, PATCHed in
   place). Disposition every finding: fix it, or accept it as a documented
   residual. False positives are disproven with file/byte evidence, not
   argued. The bot reads the thread before posting — a dispositioned finding
   is never re-raised (reviewer-side freeze rule). Promote repeated
   dispositions into standing rules: a false-positive class disproven twice
   stops being raised. Track the bot's resolution rate (fixed findings ÷
   raised findings), not its finding count — volume is not value. Push →
   next round. Hard stop when the finding count flattens for two rounds;
   watch for oscillation too — a finding that flips state across rounds is
   oscillating, not converging: escalate instead of looping. Frozen residuals
   go into the Oracle gate brief as "open at freeze, rulings demanded."
   A dispositioned finding that recurs is not re-litigated (freeze rule).
6. **Ticket hygiene.** PATCH the CI checkbox, post the Jira PR comment, move
   the ticket to In Review.
7. **Oracle gate.** Adversarial gate on a v2 brief. The Oracle is a blind
   verifier: its inputs are the brief, the diff, and the test output only —
   it never sees the fixer's reasoning, because a verifier that reads the
   maker's reasoning nods along with it. The gate runs hold-out checks the
   fixer never saw (the fixer iterates against the visible suite; the gate
   adds checks the maker never saw — anti curve-fitting). APPROVE →
   squash-merge (green CI required — green CI gates the merge, never a bot
   verdict), then post "Oracle: APPROVE. Merged \<sha\>."
   CHANGES_REQUESTED → fix on the branch → push → the bot re-reviews on
   every push, including gate-ordered remediations → focused re-gate
   embedding the fresh round.
8. **Next.** Move to the next ticket in the JQL queue.

## Loop Contract

Written before iteration 1. The contract names: the binary executable gate (what command proves done), the token budget, max rounds, the no-progress limit (stall detector — N rounds with no progress → stop and escalate), the wall-clock cap, and the blast radius (what the loop may touch, and what it must never touch — no prod deploys, no self-scheduling). Every incident the loop survives gets ratcheted into this contract as a permanent gate, hook, or convention.

## Orchestration patterns

The loop's shape generalizes beyond this repo:

- **Fan out with bounded parallelism; merge through a verifier.** Independent lanes run in parallel under a fixed cap; one verifier reads the full reports before anything merges. A verifier that reads summaries-of-summaries is a rumor mill — verify from the artifacts, never from hints.
- **Hold-out verification.** The gate tests what the maker never saw (above: the Oracle's hold-out checks). A verifier iterating against the same suite the maker used is curve-fitting, not verification.
- **Sequential where dependent, parallel where independent.** Dependent stages run in order with handoff validation at each boundary; independent lanes fan out. Don't parallelize what shares state.

## Roles

- **Orchestrator.** Verifies, pushes, opens PRs, dispositions bot findings,
  runs gates, merges. The only actor that merges.
- **Fixer.** Implements on a branch. Never pushes, never merges.
- **Bot reviewer.** Adversarial reviewer, not a gate. Its findings must be
  dispositioned, not obeyed — PRs have merged with a carried MEDIUM (#115)
  and with LOWs (#117, #118). Convergence = LOWs or explicitly accepted
  residuals.
- **Oracle.** Adversarial merge gate. Verdicts: APPROVE / CHANGES_REQUESTED.
- **Explorer / librarian.** On-demand only, not per-PR. Explorer's codebase-
  recon lane is covered by a prebuilt codegraph index; librarian's
  external-docs lane comes up for library-API verification or
  unfamiliar-repo discovery.

## Platform vs. discipline

- **oh-my-opencode-slim** is the plugin platform the session runs on: agent
  roster, background job board, skills, session reuse.
- **The deepwork skill** is the workflow discipline layered on top:
  spec-first, thin slices, phase gates, qa ledger. Its state file
  (`.slim/deepwork/<rollout>.md`, git-ignored) is the de-facto batch state.

## Human-side exceptions — verbal approval only

- **Spec PRs** (e.g. #114): human-side by law, outside the ticket-PR gate
  law. Marcos merges these himself.
- **Simple doc edits** may skip PRs entirely on his verbal go-ahead (a chat
  message — nothing more formal). Usually no code; typically a self-review,
  and most of the time still Oracle-gated even without a PR.
- **Deploy tags (`tf-*`)** are never pushed by the orchestrator. They need
  his explicit approval (asked at ≥90% confidence); pushing one
  auto-applies.

## Incidents that wrote the rules

- **#114** — merged by his own click 34s after the bot's Review #1, with a
  HIGH open. The PR claimed "tasks-only delta (no code)" while carrying
  ~900 lines of production/test code; branch contamination from a shared
  worktree. Origin of the custody law.
- **#115** — the worker dropped a `synchronize` event; an empty-commit
  retrigger recovered it.
- **#88** — the only merge-without-review on record (review landed 82 min
  after merge). Has not recurred.

## Failure handling (all hit in practice)

- Every retry names what changed since the last attempt — a retrigger
  without a changed hypothesis is a loop, not a recovery.
- Bot posts "could not be completed" → exactly one empty-commit retrigger,
  re-run the wait protocol. If it errors again, note timestamp/PR/sha and a
  log window in the state file, then proceed.
- Bot review still absent at 120s+45s → note it in the state file, proceed.
- `pytest | tail` lies about the exit code — gate pushes on the real RC:
  write output to a file, check `$?`, grep the summary line.
- Exported AWS creds poison the suite — run capture and pytest in separate
  shells.

## Loop Ledger

Each stage writes a receipt before the loop moves on: who ran it, what was
checked, the evidence hash (diff, test output tail, file:line refs), and a
timestamp. The ledger is the audit form of the custody law. Secrets are
masked in the ledger (`[REDACTED]`) — receipts prove what happened, not what
the credentials were. Write the receipt before stopping — a stage that
crashed without a receipt didn't happen.

## Test discipline

- **Tests run against the installed package** (src layout) — a test that passes against repo-root files but fails against the packaged artifact is a release-day surprise.
- **Async tests force interleaving** — use `asyncio.gather` / task groups to force task interleaving and expose missing locks; keep shared fixtures read-only or copy-per-test; put timeouts on tests that can deadlock. A timeout turns "CI hangs for 6 hours" into a failing test with a name.
- **CLI tests test handlers, not argv strings** — subcommands map to handler functions taking parsed args; test handlers directly, the entrypoint thinly (exit codes). Parsing is the framework's job.
- **Lazy imports for startup** — CLI/dev-server startup pays import cost on every invocation; defer heavy imports to the code path that needs them (measure with `python -X importtime` before guessing).
- **Prefer the framework's test seam** — fixtures over setup/teardown; `dependency_overrides` (FastAPI) to swap a dependency with a fake instead of patching import paths.

## Environment

The session runs on a headless Ubuntu laptop (24/7), reached over Tailscale
SSH from a phone (ShellFish iOS, tmux sessions). Stopping or steering the
loop = that tmux session.

## Verification terms

- **Unmasked verify** — the orchestrator's pre-push checklist term: verify
  against the real state (actual files, actual test output) rather than
  trusting the fixer's summary. Confirmed by Marcos from the orchestrator's
  reasoning.

