# mstack — Design Spec

- **Version:** 0.0.1 (draft)
- **Date:** 2026-10-09
- **Status:** draft — awaiting human review
- **Home:** `mstack/` at the root of CarreroMarcos/standards
- **Reference:** pstack (backnotprop/pstack) — format and layered architecture only; never cloned

## 1. Intent

Build a portable runbook system — the **procedures layer** the standards
library doesn't have. Principles say what to do; runbooks say how to run
the loop. A single hub entry point takes "goal + done-check" and drives
the right runbook, so an agent can own a whole loop (design, build,
verify, report) while the human's holds stay encoded as blocking steps.

Success looks like: Marcos gives one prompt plus a checkable finish
condition and trusts the loop — the agent produces the same artifacts a
manual run would, asks nothing beyond the single intake round, and bypasses
zero gates.

## 2. Decisions (locked)

| # | Decision | Date |
|---|----------|------|
| 1 | Build from scratch; pstack is a format/architecture reference only | 2026-10-09 |
| 2 | Home: `mstack/` at standards repo root (easy push via dated branch + PR) | 2026-10-09 |
| 3 | Hub: yes — one entry point routing prompts to runbooks | 2026-10-09 |
| 4 | Multi-harness: Muse agents, Claude Code, OpenCode, Cursor | 2026-10-09 |
| 5 | V1 scope: all six runbooks + hub at once (superseded by #14: seven) | 2026-10-09 |
| 6 | Approach A: self-contained `mstack/` (nothing references outside the folder) | 2026-10-09 |
| 7 | `values.md` as SSOT for magic numbers; lint-enforced | 2026-10-09 |
| 8 | Version 0.0.1; `mstack/VERSION` file | 2026-10-09 |
| 9 | Harness list: Muse agents, Claude Code, OpenCode, Cursor, **Codex** | 2026-10-09 |
| 10 | Hub invocation name confirmed: `/mstack` | 2026-10-09 |
| 11 | `check-values.sh` covers hub, runbooks, skills, **and** principles-distilled.md | 2026-10-09 |
| 12 | Skills layer added (the missing third layer): `mstack/skills/`, six adapted skills in v0.0.1 (superseded by #14: thirteen) | 2026-10-09 |
| 13 | HARNESS.md steps must be grounded in **web research** (official docs per harness), not memory | 2026-10-09 |
| 14 | Sim-mining complete 2026-10-09 (4 agents over the pstack clone): skills 6→13, runbooks 6→7 (`figure-it-out` fallback); autonomy machinery folds into orchestrator/bot-review/final-gate instead of new files | 2026-10-09 |
| 15 | Taste-mining out of scope (hub routing rule to external skill); spec approved → implementation via writing-plans + subagent-driven-development | 2026-10-09 |

## 3. Layout

```
mstack/
├── README.md                  # what it is, clone instructions, one-line usage
├── VERSION                    # 0.0.1
├── hub.md                     # the router (thin)
├── values.md                  # SSOT for magic numbers
├── principles-distilled.md    # distilled principle pointers (portable-core bar)
├── HARNESS.md                 # per-harness translation notes
├── runbooks/
│   ├── bot-review-loop.md
│   ├── overnight-orchestrator.md
│   ├── skill-authoring-run.md
│   ├── biweekly-standards-research.md
│   ├── measurement-eval.md
│   ├── final-gate.md
│   └── figure-it-out.md     # fallback runbook when no runbook matches
├── skills/
│   ├── validate.md          # blinded eval protocol (adapts eval.md)
│   ├── measure.md           # measurement-validity questions (adapts benchmark-checklist)
│   ├── prove-it.md          # verify against the real artifact (+ test razor, sequence brackets)
│   ├── interrogate.md       # adversarial red-team: intent-first, consensus synthesis, lead judgment
│   ├── show-work.md         # decision log TSV + transcript audit + cross-model Attention
│   ├── correct.md           # fix ladder + mining procedure + proof requirement + rule↔enforcer table
│   ├── verify-app.md        # generate + maintain project-local verify-<app> skills
│   ├── architect.md         # 5-phase design + 8 design red flags
│   ├── how.md               # grounding primitive: parallel explorers → fixed-section synthesis
│   ├── why.md               # rationale as evidence: epistemics tiers + Preserve/Change/Avoid/Risk
│   ├── blast-radius.md      # the one safety fact + 5-level certainty ladder
│   ├── reflect.md           # session lesson capture → Accepted/Rejected/Backlog
│   └── mstack-help.md       # meta-router: which skill for X, never starts work
├── scripts/
│   └── check-values.sh        # magic-number lint
└── references/
    └── eval-protocol.md       # how a runbook earns its place
```

Versioning: `mstack/VERSION` holds the version. Patch = wording/fix-level
changes. Minor = new runbook, new skill, or new `values.md` entry. Major =
hub contract or Reply-contract change. Bumped on the biweekly sync when
shipped changes warrant it; a principles re-distillation alone does not
bump.

## 4. File format

The hub, each runbook, and each skill carry Agent Skills frontmatter:
`name`, and `description` written as **triggers/symptoms**
(followable-docs technique), not content summaries. `README.md`,
`values.md`, and `HARNESS.md` stay frontmatter-free for drop-in cleanliness
(portable-core precedent). Runbook bodies use the proven shape:

1. Checkable exit predicate stated **first**.
2. Imperative numbered steps.
3. Bolded constraints.
4. Skipped steps kept visible as `skip: <reason>`.
5. Closing **Reply:** contract fixing the report shape.

Voice: positive recipes, bad/good pairs, quantified tripwires — his
standards voice, name-agnostic per the portable bar.

Every runbook opens with two blocks: `Requires` (the loop bindings it
assumes — e.g. "a review bot posting canonical comments; a human merge
gate" — the seam a foreign repo adapts) and `Inputs` (per-run parameters
passed in by the hub or operator: repo path, PR number, theme backlog,
source checklist — never referenced by path). Runbooks name skills inline
in backticks. `hub.md` carries `disable-model-invocation: true` (pstack
precedent) — it never hijacks casual turns; runbooks and skills are invoked
by name or hub routing only.

## 5. Hub behavior

The hub (`hub.md`, invoked as `/mstack`) does routing, never the work:

1. Reads the prompt; requires the five prompt elements (goal, done-check,
   proof wanted, known context, real constraints). If the intake gate fires
   BLOCKING, it asks for exactly what's missing — nothing else.
2. Matches against the trigger table → runbook path. Never names skills
   unprompted; the runbook names what it needs.
3. Copies the runbook's steps verbatim into the todo list **before** any
   task-specific todos.
4. Applies the distilled principles at runbook start (steering vocabulary,
   one phrase per principle).
5. Consults `HARNESS.md` for harness-specific verbs (spawning subagents,
   background runs, todo lists) across Muse agents, Claude Code, OpenCode,
   Cursor, and Codex.

Operator phrases the hub recognizes: "i'm stepping away" (session override —
stop asking, keep going), "new task" (re-match the playbook instead of
continuing). Routing rules: restate-first for noisy/vague input (one message
before any code); never lead with a theory of the cause; a duration is not a
finish condition; name a skill only to override a specific choice.
Invocation discipline: the hub is for work that needs rigor — a small obvious
edit doesn't get it. Role-based cost control stays harness-neutral
(`HARNESS.md`).

Intake gate (vagueness circuit breaker). Before routing, the hub checks
whether the prompt is sufficient to form a checkable exit predicate:
- **BLOCKING — stop and ask:** goal missing or unintelligible; done-check
  missing or uncheckable ("make it better", "trust it was done right");
  scope ambiguous AND the task has irreversible consequences (merge, deploy,
  delete, force-push, closing someone else's PR).
- **PROCEED WITH LOGGED ASSUMPTIONS:** vague but fully reversible
  (investigation, read-only analysis, drafts). The hub states its
  assumptions up front; they enter the decision log and surface in the Reply
  / morning report for correction after the fact.
- **NEVER ASK FOR:** the how (the runbook owns it); a theory of the cause;
  anything a runbook's grounding phase determines (which files, which
  tools). At most one round of questions — batch what's blocking, ask once,
  then go.
Restatement-first still applies to noisy input: one restatement message
before any code. A correction costs one message; a misread costs a run.
Precedence: holds win over session overrides. If BLOCKING fires under "i'm
stepping away", the hub does not ask into the void — it parks the run with a
pause-safely resume note and reports what's missing. "Scope ambiguous" has
concrete triggers: no named target; verb without object; two plausible
readings of the done-check. "Fully reversible" is defined negatively:
touches none of the enumerated irreversible actions and produces no external
side effects. The gate reads for intent — his messages are often
speech-to-text; a vague-but-intelligible prompt is never bounced for
grammar.

## 6. The seven runbooks (v0.0.1)

| Runbook | Loop it encodes | Exit predicate shape |
|---------|-----------------|----------------------|
| `bot-review-loop.md` | PR babysit: poll canonical review comments → address non-low findings → Mars-law recheck → freeze rule → confident-stop on bot infra failure | PR merged by human, or all findings dispositioned with bot loop green / confident-stop flagged |
| `overnight-orchestrator.md` | Spec → implement → bot-review → Oracle-gate cycle on the headless laptop (tmux), off-thread coordination, morning handoff report | Oracle APPROVE + green CI, or dead-end write-up |
| `skill-authoring-run.md` | RED-GREEN-REFACTOR verification loop, per-paragraph razor, trigger probes + neighbor regression, token-cost metric, technique-vs-reference kill decision | Skill passes eval protocol or is killed with reasons |
| `biweekly-standards-research.md` | Rotating-topic research → portable-core re-distillation → dated branch + PR via push tooling → bot loop → checklist updates | PR opened with REPORT line, or no-change reported |
| `measurement-eval.md` | Perf comparisons (A/B alternation, medians, run-to-run variation), benchmark-checklist questions, recording results for future trust | Named number with limiter identified, or explicit "not measured" |
| `final-gate.md` | The gate contract: unmasked verify, Oracle brief assembly, holds-vs-autonomy adjudication, report by technique | Verdict (approve/hold) with evidence per claim |
| `figure-it-out.md` | Fallback when no runbook matches: frame a falsifiable predicate → design the workflow → hypothesis loop → audit trail → verify | VERIFIED / NOT VERIFIED / INCONCLUSIVE (never a pass) |

The autonomy simulation produced machinery that folds into the existing
runbooks rather than new files. `overnight-orchestrator.md` gets:
exit-predicate-first + never-relax-the-predicate; wake design (event watcher
+ heartbeat fallback); smallest-justified-change + discard-what-didn't-help;
mid-run discovery ownership; per-iteration decision-log checkpoints; hourly
audit tick with runbook re-read (anti-drift); fresh-subagent spawn rules;
worker brief template (GOAL / SCOPE / CONTEXT / ACCEPTANCE / VERIFY / TIMEBOX
/ FORBIDDEN / REPORT / STANDING); liveness probing + retry-by-mode table; the
reaches-human vs never-reaches-human escalation split; pause-safely /
session-pickup durability; pilot-before-fanout. `bot-review-loop.md` gets:
verifier≠author on a different model family ("CI green is not a verdict");
patch-id staleness rule (a rebase voids the verdict unless patch-id is
unchanged); CI-flake classification ladder (one fresh build, never a blind
job retry; identical second failure reclassifies); merge-frontier discipline;
babysit modes (drive / background / threads-only / check); skeptical triage
with a shared dismissal rubric. `final-gate.md` gets: judge≠author,
contiguous-verified-run landing, "inconclusive" as a valid verdict, and the
evidence-or-red-flag Reply contract. `final-gate.md`'s cross-model reviewer
degrades to same-model with an explicit caveat flag where only one model
family is available.
`bot-review-loop.md` also gets: no thread replies (dismissals go in the
Reply disposition report, never on the thread — only the bot and Marcos post
in threads); stale-review SHA check (the review's commit SHA must match the
PR head — on mismatch, freeze/dismiss, never re-litigate); one babysitter
per PR; per-finding dispositions in the Reply (fixed / dismissed-with-reason
/ frozen); the canonical marker `<!-- pr-reviewer:canonical:v1 -->`.
`overnight-orchestrator.md` also gets: an operator-stop path (tmux →
zero-writes order → pause-safely + wip commit); Jira is a projection — never
hand-edit it. `biweekly-standards-research.md` also gets: never touch the
sacred repo-specific AGENTS.md section; update
`references/distillation-record.json` on shipped changes;
never-repeat-a-source; ONE plugin per run. `skill-authoring-run.md` also
gets: workspace source ↔ repo copy kept byte-identical; never edit a skill
mid-task — fix it in its own PR. (`figure-it-out.md` sits in runbooks/
rather than skills/ to keep the hub's never-names-skills contract intact —
a deliberate deviation from pstack.)

## 7. Skills layer (the missing layer)

The original draft had two layers (hub + runbooks). pstack's third layer —
situational tools invoked at a step's need — was missing. mstack has it:
`mstack/skills/`.

- **Role:** the doing layer. A runbook step names a skill when that step
  needs it ("run the `measure` skill before trusting the number"); the hub
  never auto-invokes skills. Skills are invoked by name or by runbook step
  only.
- **Selection bar:** same bar as principles (survives any stack; changes
  behavior under pressure — verified, not assumed), plus no duplication: a
  skill never restates a standard, it references it by pointer. Standards
  are rules; skills are tools.
- **Adaptation rule:** her content is rewritten in his voice, stripped of
  Cursor/model-slug coupling, fitted with his gates where relevant, and
  given a measurement clause where relevant. Adapted, never copied. Skills
  reference named principles in `principles-distilled.md`, never
  `standards/` paths.
- **v0.0.1 skills (13):**

| Skill | Does | Adapts |
|-------|------|--------|
| `validate` | Blinded eval protocol for testing a runbook/prompt change before promoting it, with blinding non-negotiables (observer-effect mitigations) | pstack `eval.md` |
| `measure` | Measurement-validity questions (limiter, parity, ≥5 interleaved runs, end-to-end relevance) as a checklist; inconclusive is a valid verdict | pstack `benchmark-checklist` + `explain-the-number` |
| `prove-it` | Verify against the real artifact, not a proxy or self-report; includes the test falsifiability razor and before/after sequence brackets | pstack `principle-prove-it-works` + `principle-test-behavior-not-implementation` + `principle-sequence-verifiable-units` |
| `interrogate` | Adversarial red-team: state intent first, ≥2 independent reviewers, consensus synthesis, lead-judgment buckets (Act on / Consider / Noted / Dismissed), Agreement Map, never auto-apply | pstack `interrogate` |
| `show-work` | Append-only decision log (TSV, evidence-as-pointer), end-of-run transcript audit, mandatory cross-model-family Attention section | pstack `show-me-your-work` |
| `correct` | Fix ladder (make impossible → lint/types → test → doc last) **plus** the machinery: mining procedure (a class counts at 2 occurrences), proof requirement (every new check fails on a real past mistake), rule↔enforcer pairing table | pstack `correct` / `encode-lessons-in-structure` |
| `verify-app` | **Generate** project-local `verify-<app>` skills (interviews the repo: surface/run/drive/observe/isolate; Launch/Doctor/Drive/Evidence/Cleanup template; proved end-to-end before handoff) **and maintain** them (scheduled audit → clean / changed / blocked; never touches product code; generated skills live in the target repo, not in mstack/) | pstack `create-verification-skill` + `maintain-verification-skill` |
| `architect` | 5-phase design (Ground → Sketch → Agree → Implement → Scrap); arena rule (≥2 structurally distinct candidates); 8 design red flags; rationale template with synthesis decision | pstack `architect` |
| `how` | Grounding primitive: simple-vs-complex routing, parallel explorers with distinct angles, one explainer → fixed sections (Overview / Key Concepts / How It Works / Where Things Live / Gotchas) | pstack `how` |
| `why` | Rationale as evidence: coverage map with null-results-as-findings, confidence tiers (Found / Infer / Competing / Unknown), Preserve / Change / Avoid / Risk constraint conversion | pstack `why` |
| `blast-radius` | Find the ONE fact a change is safe because of; push it down the 5-level certainty ladder (said-so → pointed-at-line → walked-the-failure → ran-it → reproduced-in-app) | pstack `blast-radius` |
| `reflect` | Session lesson capture: three-lens mining → Accepted / Rejected / Backlog; feeds the biweekly run; structural-enforcement check prefers lint/script over doc | pstack `reflect` |
| `mstack-help` | Meta-router: answers "which skill for X", hands over a prompt, links the source — never starts work | pstack `poteto-help` |

- **Deliberately not taken:** `tdd` (his TESTING.md owns it), `no-comments`/`comment-sicko` (CODE-QUALITY covers it), `teach`/`recall`/`bro` (not procedures-layer needs), `automate-me` (mstack is his from birth), `make-bot-ui`/`typescript-best-practices`/model slugs/`~/.cursor` paths (harness-coupled), `swarm`'s config (keep the parallel-lane pattern only), benny's Slack pack (keep the fail-closed stage pattern only), owner-merges-own-PR (conflicts with human-merge-only), never-block-on-the-human looseness (already adjudicated).
- **Mining pass:** complete 2026-10-09 — four simulation agents over the pstack clone confirmed no other high-impact piece missed. Further skills enter only through the selection bar (see §11 growth governor).

## 8. Holds as blocking steps

Where mstack deliberately diverges from pstack's never-block-on-the-human
looseness. Every runbook encodes these as **numbered steps the loop cannot
pass**, never as ambient context:

- Merge policy is repo-scoped: standards-repo PRs (specs, skills, runbooks)
  merge on his click only; pr-reviewer code PRs may merge after Oracle
  APPROVE + green CI. `tf-*` deploy tags are never pushed without his
  explicit approval (pushing one auto-applies Terraform).
- Dated branch + PR; never direct to main — except simple doc edits on his
  explicit verbal go-ahead.
- Destructive-scope confirmation before any deletion.
- Freeze rule: never re-litigate a dispositioned finding.
- Unmasked verify before any claim of done (real state, not agent summary).
- Off-thread coordination: only the bot and Marcos ever post in PR threads;
  all inter-agent coordination happens off-thread.
- Bot infra-failure confident-stop: on repeated bot-review infra failure,
  stop confidently and report — never fake a trigger commit.

## 9. values.md — magic-number SSOT

**Problem:** magic numbers inline in runbooks go stale silently.

**Mechanism:**

1. Every magic number lives in `mstack/values.md` as a named entry:
   name, value, unit, why, used-in (which runbooks/skills).
2. Runbooks reference values **by name** (`per values.md#mars-law-interval`);
   they never inline a literal. The only literals allowed are structural
   ("7 runbooks", "step 1") — see the lint's allowlist.
3. Numbers originating in the library are mirrored as named entries with a
   source pointer (e.g. `source: standards/CODE-QUALITY.md §5`).
   `values.md` is the SSOT *for mstack*; `standards/` remains the SSOT for
   the library; the biweekly sync reconciles the two.
4. Seed entries: `mars-law.interval` (120s), `mars-law.flatten-rounds` (2),
   `heartbeat.interval`, `flake-retry.count` (1 fresh build),
   `eval.run-floor` (5), `correct-mining.class-threshold` (2 occurrences),
   `audit-tick.interval`, `intake-gate.max-question-rounds` (1),
   `interrogate.min-reviewers` (2), `growth-governor.occurrences` (2).
5. Enforcement: `scripts/check-values.sh` (rg where available, POSIX grep
   fallback) scans the hub, runbooks, skills, and `principles-distilled.md`
   for magic-looking bare numbers (digits with units: `120s`, `2 rounds`,
   `3 retries`) and fails when one isn't declared in `values.md`. Runs in
   the eval protocol and on the biweekly sync. The allowlist lives in an
   `## Allowlist` section in values.md (entry + reason); the lint stays
   dumb. A human dispositions the rest — same shape as the hedge grep.

## 10. Portability and sync

- **Self-containment is enforced** by `scripts/check-refs.sh` (run in eval
  Stage 1 and on the biweekly sync): no runbook, hub, skill, or script may
  reference any path outside `mstack/`. The pattern covers `../`, absolute
  home paths, and bare repo URLs. Source pointers in `values.md`
  (e.g. `source: standards/CODE-QUALITY.md §5`) are provenance metadata,
  not load-time references — they contain no relative path and are exempt.
- **Principles enter only via `principles-distilled.md`**, under the
  portable-core selection bar (survives any stack; changes agent behavior
  under pressure — verified, not assumed). It must define a stable named
  principle vocabulary (one name = one rule); the hub cites names, never
  paraphrases. Re-distilled on the biweekly research run; no-change is a
  valid outcome.
- **`HARNESS.md`** translates the handful of harness-specific verbs for
  Muse agents, Claude Code, OpenCode, Cursor, and Codex. Runbooks stay
  harness-neutral. Every HARNESS.md claim must be grounded in **web
  research** against each harness's official docs — never from memory.
  (An implementation-plan step, verified before HARNESS.md ships.)
  HARNESS.md must also specify the wake-on-event requirement (watcher
  subagent + heartbeat fallback) and per-harness isolation options
  (worktrees) — the need behind her `/loop`, translated harness-neutrally.
  HARNESS.md carries a per-runbook capability matrix (full / degraded /
  unsupported) with fallback behavior per cell — if a harness lacks
  background execution, the overnight runbook is unsupported there, not
  silently broken.
- **Sync vehicle:** the existing `biweekly-standards-research` cron gains
  an mstack step (re-distill principles, re-run `check-values.sh` and
  `check-refs.sh`, reconcile `values.md` against `standards/`). Same dated
  branch + PR; his veto.
- **Harness definitions:** Muse agents = this runtime (subagent.spawn,
  background exec, file tools); Claude Code, OpenCode, Cursor, Codex = the
  products of those names — the web-research step fills in each one's
  verbs. **Push abstraction:** the Muse-harness binding is `gh_push.py`;
  HARNESS.md defines the equivalent per harness (or marks push
  unsupported). Runbooks say "push via the harness binding," never a
  literal command.
- **Distribution (v0.0.1):** manual copy of `mstack/` into the target
  repo; automate later.

## 11. Validation (eval protocol)

Two stages, defined in `references/eval-protocol.md`:

- **Stage 1 — playground:** a subagent executes the runbook against a
  scratch target; the runbook itself passes a followable-docs audit
  (bold-skeleton test, hedge grep, `check-values.sh` clean).
- **Stage 2 — pilot:** a real low-stakes run (next taste-mining or biweekly
  PR driven through the runbook).
- **Bar:** (a) artifact parity with a manual run and zero clarifying
  questions; (b) zero bypassed gates; (c) audit pass. If it fails, the
  **runbook** is the defect, not the agent.
- **Pilot-before-fanout:** before a runbook scales to parallel lanes, one
  unit runs the whole path to falsify the brief template.
- **Growth governor:** a new skill is added only when the same failure shows
  up twice. v0.0.1's thirteen are the seeded set; the selection bar, not
  enthusiasm, admits the fourteenth. The `reflect` skill's Backlog is the
  ledger that counts occurrences.
- Skills go through the same protocol (adapted: the playground stage is
  trigger-probe execution, not a full run).
- Stage 2 pilot is a real low-stakes run of the encoded loop (e.g. his next
  taste-mining or biweekly PR) — generic in the shipped protocol, his
  instances as examples.

## 12. Out of scope for v0.0.1

- A pstack-style `/automate-me` transcript miner (no personal-mode generator;
  mstack is his from birth).
- Model-role configuration (no per-role model slugs; harness decides).
- Scheduled drift monitoring of runbooks beyond the biweekly sync.
- Any change to `standards/` layout or the portable-core file.
- Further skills beyond the v0.0.1 thirteen — mining continues through
  the selection bar, one skill at a time.
- Taste-mining loop (hub routes to the external skill; not an mstack
  runbook).

## 13. Open questions

1. ~~Taste-mining scope~~ — decided 2026-10-09: out of scope. The hub carries a routing rule to the external taste-mining skill; no mstack runbook.
