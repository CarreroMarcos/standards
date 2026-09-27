---
title: Dev Loop — the agentic build loop, as operated
version: "1.0"
scope: Runbook for the agentic build loop (PR reviewer dev loop)
last_reviewed: 2026-09-27
---

# Dev Loop — the agentic build loop, as operated

Reconstructed 2026-09-27 from live activity on the pr-reviewer repo (PRs
#75–#119), the repo's process docs, and the orchestrator's own account of a
session. This is the loop a unit of work travels from spec task to merged
main. Repo-specific names are marked; the shape is the reusable part.

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
   carried in-progress code from a shared worktree's local main.
4. **Push + PR.** `git push -u origin <branch>`, `gh pr create`.
5. **Bot rounds.** Wait ~120s (bot latency; +45s if the round is
   absent/errored/unchanged), then fetch the bot's canonical comment
   (fenced `pr-reviewer:canonical` marker — exactly one per PR, PATCHed in
   place). Disposition every finding: fix it, or accept it as a documented
   residual. False positives are disproven with file/byte evidence, not
   argued. Push → next round. Hard stop when the finding count flattens for
   two rounds; frozen residuals go into the Oracle gate brief as "open at
   freeze, rulings demanded." A dispositioned finding that recurs is not
   re-litigated (freeze rule).
6. **Ticket hygiene.** PATCH the CI checkbox, post the Jira PR comment, move
   the ticket to In Review.
7. **Oracle gate.** Adversarial gate on a v2 brief. APPROVE → squash-merge
   (green CI required — green CI gates the merge, never a bot verdict),
   then post "Oracle: APPROVE. Merged \<sha\>." CHANGES_REQUESTED → fix on
   the branch → push → the bot re-reviews on every push, including
   gate-ordered remediations → focused re-gate embedding the fresh round.
8. **Next.** Move to the next ticket in the JQL queue.

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

- Bot posts "could not be completed" → exactly one empty-commit retrigger,
  re-run the wait protocol. If it errors again, note timestamp/PR/sha and a
  log window in the state file, then proceed.
- Bot review still absent at 120s+45s → note it in the state file, proceed.
- `pytest | tail` lies about the exit code — gate pushes on the real RC:
  write output to a file, check `$?`, grep the summary line.
- Exported AWS creds poison the suite — run capture and pytest in separate
  shells.

## Environment

The session runs on a headless Ubuntu laptop (24/7), reached over Tailscale
SSH from a phone (ShellFish iOS, tmux sessions). Stopping or steering the
loop = that tmux session.

## Verification terms

- **Unmasked verify** — the orchestrator's pre-push checklist term: verify
  against the real state (actual files, actual test output) rather than
  trusting the fixer's summary. Confirmed by Marcos from the orchestrator's
  reasoning.

