---
name: overnight-pr-reviewer
description: >
  WORKED EXAMPLE — not portable. One instantiation of the overnight-orchestrator
  runbook: how the author's PR-reviewer repo runs its unattended loop, with its
  Oracle gate, bot-review cycle, deploy-tag policy, and issue-tracker projection.
---

# Worked example — not portable

This is one instantiation of `runbooks/overnight-orchestrator.md`: how the author's PR-reviewer repo runs its unattended loop. Everything below this line is repo-specific — the gate, the policy, the tooling. The portable machinery lives in `runbooks/overnight-orchestrator.md` and `runbooks/deep-work.md`; this file shows how one team filled the pattern.

## The run

- **Repo:** the PR-reviewer — two serverless functions (ingress + worker), infrastructure as code, a managed Terraform workspace. The loop's job: spec-to-gate hardening cycles overnight.
- **Host:** a headless Ubuntu host, one tmux session per run. The run survives disconnects because tmux does.
- **Branch:** a dated branch per run, opened as a PR against main. The author merges on his click only — the orchestrator never merges.

## The dev-loop shape

Spec → implement → bot-review → gate, per unit. Implement the smallest change that could falsify the current hypothesis; discard what didn't help instead of accumulating it.

- The bot review is advisory, but every finding must be dispositioned — per `runbooks/bot-review-loop.md` (recheck discipline, the freeze rule on dispositioned findings, off-thread coordination: only the bot and the author post in PR threads).
- The merge gate: Oracle APPROVE plus green CI on the final diff, or a dead-end write-up. No code merges without both.

## Repo policy

- **Deploy tags (`tf-*`):** never pushed without the author's explicit approval — pushing one auto-applies the infrastructure change.
- **Issue tracker:** a projection of the run's task list. The task list is the source of truth — never hand-edit the tracker; when they disagree, fix the projection.
- **Destructive scope:** state the deletion scope explicitly and wait for the author before any deletion.

## Operator-stop

Attach to the tmux session, issue the zero-writes order, pause-safely, cut a work-in-progress commit, and report the resume state. The run resumes through deep-work's resume chain, the decision log among its referenced files.
