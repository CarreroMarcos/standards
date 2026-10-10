# HARNESS.md — per-harness translation notes

Runbooks are harness-neutral. They name verbs (spawn a subagent, keep a
todo list, wake on an event); this file translates each verb into the
five supported harnesses. A runbook never hardcodes a harness primitive —
it points here.

The five harnesses: **Muse agents** (this runtime), **Claude Code**,
**OpenCode**, **Cursor**, **Codex**.

Research rule, enforced: every verb claim carries its official-doc source
URL inline. Claims that could not be verified in official docs are marked
`unverified` and the cell degrades to the documented fallback. Section 6
lists everything that could not be verified.

## 1. Verb translations

Each cell names the native primitive. `Muse agents` claims are first-hand
(observed in this runtime; no URL exists). First-hand claims carry their
date (`first-hand YYYY-MM-DD`) and outrank doc-sourced claims for that
runtime — docs describe the product, first-hand describes the machine.

### Spawn a subagent

| Harness | Primitive |
|---|---|
| Muse agents | `subagent.spawn` with a self-contained brief (first-hand, date unknown — under ruling, see §6; child agent, own context, result delivered back) |
| Claude Code | Task / Agent tool: `subagent_type`, optional `run_in_background`, optional `isolation` (https://code.claude.com/docs/en/sub-agents) |
| OpenCode | `subagent` tool spawning a subagent (`general`, `explore` — no `scout`); optional `background` and `sessionID` parameters; `@` mentions; child sessions (first-hand 2026-10-10; official docs still name `task` + `scout`: https://opencode.ai/docs/agents/) |
| Cursor | Agent's Task tool; custom subagents as markdown files in `.cursor/agents/` (also reads `.claude/agents/`, `.codex/agents/`) (https://cursor.com/docs/subagents) |
| Codex | Prompt-driven subagent workflows ("spawn two agents", "one agent per point"); custom agents as TOML files in `.codex/agents/` (https://developers.openai.com/codex/subagents) |

### Run in background

| Harness | Primitive |
|---|---|
| Muse agents | `muse.exec` with `background: true`; poll with `process.poll` / `process.log` (first-hand, date unknown — under ruling, see §6) |
| Claude Code | Task `run_in_background`; background sessions via `claude agents` (https://code.claude.com/docs/en/sub-agents) |
| OpenCode | first-hand 2026-10-10: `subagent(background: true)` detached runs confirmed in this runtime; official docs silent. Fallback unchanged: shell backgrounding (`&`, `nohup`) |
| Cursor | Subagent foreground vs background modes; `is_background` frontmatter on custom subagents; `/in-cloud` hands work to a cloud subagent (https://cursor.com/docs/subagents) |
| Codex | `degraded` — no first-class detached background subagent documented. Fallbacks: `codex exec` (headless, JSONL stream) backgrounded with `&` and polled; hook handlers may set `async: true` to run in the background (https://developers.openai.com/codex/hooks) |

### Keep a todo list

| Harness | Primitive |
|---|---|
| Muse agents | Todo lists (tracked items; first-hand, date unknown — under ruling, see §6) |
| Claude Code | TodoWrite / TodoRead tools (https://docs.claude.com/en/api/agent-sdk/todo-tracking — cited via search; not confirmed on code.claude.com this session) |
| OpenCode | refuted first-hand 2026-10-10 on this runtime (opencode v2.0.26): no todo tool exists under any name. Fallback: plan state in repo files — same as Cursor |
| Cursor | `unverified` — no official todo tool found in the docs surveyed. Fallback: plan state in repo files (e.g. `plan.md` checklists) |
| Codex | `todo_write` / `update_plan` built-in solver tools (https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide/) |

### Invoke a skill / markdown file

| Harness | Primitive |
|---|---|
| Muse agents | Read the `SKILL.md` and follow its instructions (first-hand, date unknown — under ruling, see §6) |
| Claude Code | Native `SKILL.md` + Skill tool; Agent Skills open standard; `disable-model-invocation` frontmatter (https://code.claude.com/docs/en/skills) |
| OpenCode | `skill` tool; native `SKILL.md` support (https://opencode.ai/docs/tools/; https://opencode.ai/docs/skills/ — skills page cited via search results, not opened this session) |
| Cursor | Agent Skills (`SKILL.md`); the official subagents doc directs single-purpose tasks to "a skill or command instead" (https://cursor.com/docs/subagents). Skill directory path `.cursor/skills/` is third-party-reported, `unverified` in official docs |
| Codex | `.agents/skills/<name>/SKILL.md` with `name` + `description` frontmatter (https://developers.openai.com/codex/skills) |

### Watch a condition / wake on an event

| Harness | Primitive |
|---|---|
| Muse agents | None — no event system (first-hand, date unknown — under ruling, see §6). Fallback: heartbeat polling loop (section 2) |
| Claude Code | Hooks: `Stop`, `SubagentStop`, `Notification`, `SessionEnd` fire scripts on agent-loop events (https://code.claude.com/docs/en/hooks). No timer primitive — external conditions still need the heartbeat fallback |
| OpenCode | Plugin hooks: `session.idle`, `session.created`, `session.deleted`, `tool.execute.before/after`, `todo.updated`, `file.watcher.updated` (https://opencode.ai/docs/plugins/). No condition-watch primitive — heartbeat fallback |
| Cursor | Hooks in `.cursor/hooks.json`: `stop` hook may return `followup_message` to re-arm the loop, bounded by `loop_limit`; also `subagentStart` / `subagentStop`, `sessionStart` / `sessionEnd` (https://cursor.com/docs/hooks). No timer primitive — heartbeat fallback |
| Codex | `notify` in `config.toml`: runs a program on `agent-turn-complete` with a JSON payload — fire-and-forget, observer-only, cannot block (https://developers.openai.com/codex/config-reference). Lifecycle hooks `Stop`, `SubagentStop` (trust-reviewed before first run) (https://developers.openai.com/codex/hooks). No timer primitive — heartbeat fallback |

### Isolate work (worktrees)

| Harness | Primitive |
|---|---|
| Muse agents | `git worktree` via shell; subagents share the parent checkout (first-hand, date unknown — under ruling, see §6) |
| Claude Code | `git worktree` via Bash; the Agent tool exposes an `isolation` option (https://code.claude.com/docs/en/sub-agents) |
| OpenCode | `degraded` — no first-class agent-facing worktree command found in official docs. Fallbacks: plain `git worktree` via Bash; plugin context exposes a worktree path (https://opencode.ai/docs/plugins/) |
| Cursor | First-class: "ask for isolation and each subagent runs in its own copy of the project" — an isolated git worktree with its own branch and working directory, or a cloud environment with a dedicated VM (https://cursor.com/docs/subagents) |
| Codex | `degraded` — no native per-subagent worktree. Fallbacks: `git worktree` via shell; `sandbox_mode` (`read-only` for verifiers) (https://developers.openai.com/codex/subagents) |

## 2. The wake-on-event requirement

The wake-on-event contract (named `/loop` in runbook prose): every runbook that waits on an
external condition implements **both** arms —

1. **Watcher arm.** If the harness exposes an event for the condition
   (section 1, row 5), wire it. Otherwise skip this arm.
2. **Heartbeat arm.** A polling loop that re-checks the condition every
   heartbeat interval, per `values.md#heartbeat.interval`, and logs each
   tick. The heartbeat is the portable baseline; the watcher is an
   optimization.

Per-harness `/loop` mapping:

| Harness | Watcher arm | Heartbeat arm |
|---|---|---|
| Muse agents | none available | background exec loop (first-hand, date unknown — under ruling, see §6) |
| Claude Code | `Stop` / `Notification` hooks | background task + sleep |
| OpenCode | `session.idle` / `file.watcher.updated` plugin hooks | shell loop |
| Cursor | `stop` hook with `followup_message` + `loop_limit` | hook script sleeps between re-arms |
| Codex | `notify` script writes a flag file on `agent-turn-complete`; `Stop` hook | shell loop polling the flag |

Requirement: the heartbeat arm never busy-waits. Its interval comes from
`values.md#heartbeat.interval` by name, never as an inline literal, and
each tick is logged so a stalled loop is distinguishable from a quiet one.

## 3. Isolation options

| Harness | Options |
|---|---|
| Muse agents | `git worktree` via shell (first-hand, date unknown — under ruling, see §6). Subagents share the checkout — isolate by hand before delegating write work |
| Claude Code | `git worktree` via Bash; Agent tool `isolation` option (https://code.claude.com/docs/en/sub-agents) |
| OpenCode | `git worktree` via Bash (no first-class command; https://opencode.ai/docs/plugins/) |
| Cursor | Per-subagent isolated git worktree with own branch (first-class); whole-agent isolation via worktree or cloud subagent VM (https://cursor.com/docs/subagents) |
| Codex | `git worktree` via shell; `sandbox_mode: read-only` for verifier-style subagents (https://developers.openai.com/codex/subagents) |

Rule of thumb for runbooks: verifiers get a worktree or a read-only
sandbox; fixers get a branch. The runbook states which, this table says
how on each harness.

## 4. Capability matrix

Rows: the nine runbooks. Columns: the five harnesses.
`full` = every step maps to a documented first-class primitive.
`degraded` = all steps achievable, at least one via a fallback named in
the cell. `unsupported` = a step cannot be done; the cell names the
alternative. Push mechanics are judged separately in section 5, not here.

### bot-review-loop

Poll the PR for new bot reviews, recheck on an interval, stop when the
review count flattens; fixer and verifier subagents in the loop.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — background primitive unverified; run the poll loop via shell backgrounding |
| Cursor | degraded — loop maps to the `stop`-hook `followup_message` pattern, but round tracking falls back to a state file (no documented todo tool) |
| Codex | degraded — loop maps to a shell heartbeat poll; `notify` cannot re-arm a loop (fires once per turn, observer-only) |

### overnight-orchestrator

Detached long run with wake-on-event, heartbeat, and escalation.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — background via shell; heartbeat covers wake |
| Cursor | degraded — background and cloud subagents exist, but no documented timer/cron primitive; heartbeat fallback |
| Codex | degraded — no first-class background session; `codex exec` backgrounded with `&`, `notify` + heartbeat for wake |

### skill-authoring-run

Sequential author → verify loop against the writing-skills protocol. No
background, no wake, no push.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — todo list falls back to plan files in the repo |
| Cursor | degraded — todo list falls back to plan files in the repo |
| Codex | full |

### biweekly-standards-research

Research rotating topics, write files, open a dated branch + PR.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | full |
| Cursor | full |
| Codex | full |

Research and file mechanics are first-class everywhere; push auth is the
operator's setup step (section 5).

### measurement-eval

Interleaved runs, median + range, falsifiable checks. Sequential.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — todo list falls back to plan files in the repo |
| Cursor | degraded — todo list falls back to plan files in the repo |
| Codex | full |

### final-gate

Verifier-never-author on an isolated checkout; blocking verdict.

| Harness | Cell |
|---|---|
| Muse agents | full — worktree via shell |
| Claude Code | full — worktree via Bash, Agent `isolation` option |
| OpenCode | degraded — no first-class worktree command; `git worktree` via shell |
| Cursor | full — per-subagent isolated worktree is first-class |
| Codex | degraded — no native per-subagent worktree; `git worktree` via shell plus `read-only` sandbox for the verifier |

### figure-it-out

Fallback runbook: spawn, probe, track, report. Minimal verbs.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — todo list falls back to plan files in the repo |
| Cursor | degraded — todo list falls back to plan files in the repo |
| Codex | full |

### deep-work

Delegated subagent execution: lane briefs to fixer subagents, artifacts
verified against real state, adversarial gate on the merged work, a
run-scoped state directory. Spawn and todo are the only special verbs —
no wake-on-event, no per-subagent isolation, no push.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — todo list falls back to plan files in the repo |
| Cursor | degraded — todo list falls back to plan files in the repo |
| Codex | full |

### debugging

Repro first, bisect, fix smallest, verify against real state. Sequential
and single-agent: shell, version control, and a todo list.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — todo list falls back to plan files in the repo |
| Cursor | degraded — todo list falls back to plan files in the repo |
| Codex | full |

### Matrix notes

- 45 cells filled: 27 full, 18 degraded, 0 unsupported. No cell is
  unsupported because every runbook degrades to shell + files +
  heartbeat, which all five harnesses provide. If a future harness lacks
  a shell, its column gets real `unsupported` cells with "run this
  runbook on a shelled harness" as the alternative.
- Cursor's and OpenCode's recurring degradation is one missing primitive: no documented todo tool (Cursor), no existing todo tool — refuted first-hand 2026-10-10 (OpenCode). The fallback (plan files in the repo) is cheap and inspectable, so the degradation is minor.
- Codex's recurring degradation is background + per-subagent worktrees, falling back to the same shell idioms the runbooks already use for polling. (OpenCode background execution was previously listed here; first-hand 2026-10-10 confirms the primitive exists.)

## 5. Push abstraction

The contract: work lands on a dated branch, commits are pushed, a PR
opens against the default branch. The operator never pushes to the
default branch directly. The harness binding is the piece that performs
this — the runbooks name the contract, never the tool.

| Harness | Binding |
|---|---|
| Muse agents | `gh_push.py` — pushes via the git-database API: atomic multi-file commits, branch create, PR open |
| Claude Code | degraded — no equivalent binding; `gh` CLI via Bash (operator supplies auth) |
| OpenCode | degraded — no equivalent binding; `gh` CLI via Bash (operator supplies auth) |
| Cursor | degraded — no equivalent binding; `gh` CLI via Bash (operator supplies auth) |
| Codex | degraded — no equivalent binding; `gh` CLI via Bash (operator supplies auth) |

`gh_push.py` is the reference implementation of the contract. Porting it
(or a thinner `gh`-CLI wrapper) to another harness is operator work, not
runbook work — the runbooks stay unchanged either way.

## 6. What could not be verified

From official docs, during this session's research:

- **OpenCode background subagents.** Third-party sources describe an
  experimental flag; official docs are silent. Marked degraded, not
  filled from memory.
- **OpenCode worktrees.** No first-class agent-facing worktree command
  in official docs; community plugins exist. Marked degraded.
- **OpenCode skills page.** `skill` tool confirmed at
  https://opencode.ai/docs/tools/; the dedicated skills page
  (https://opencode.ai/docs/skills/) was cited from search results, not
  opened this session.
- **Claude Code TodoWrite.** Confirmed via the API docs
  (https://docs.claude.com/en/api/agent-sdk/todo-tracking), cited
  through search; not confirmed on code.claude.com this session.
- **Cursor todo.** No official todo tool found in the docs surveyed.
  Marked degraded with a file fallback.
- **Cursor skill paths.** Skills themselves are official; the
  `.cursor/skills/` directory path is third-party-reported, unverified
  in official docs.
- **Codex `notify`.** Documented at
  https://developers.openai.com/codex/config-reference; payload details
  and fire-and-forget semantics corroborated by third-party sources, not
  re-verified against official docs this session.
- **Muse agents.** First-hand observation only; no public docs URL
  exists for this runtime's tool surface.
- **No harness documents a timer/cron primitive for agents.** Stated as
  "not found in the docs surveyed" — that is why the heartbeat arm is
  the portable baseline, not a claim about any harness's roadmap.
- **OpenCode tool names (corrected first-hand 2026-10-10).** The spawn
  primitive is the `subagent` tool (`general`, `explore` — no `scout`),
  not the documented `task` tool; no todo tool exists in this runtime
  under any name (`todowrite`/`todoread` refuted); background subagents
  (`subagent(background: true)`) confirmed, previously marked unverified.
  Five matrix cells flipped `full` → `degraded` on the todo finding; the
  §5 count and notes updated in the same change.
- **Muse-agents first-hand cells vs this runtime (operator ruling
  needed).** The Muse column claims first-hand `subagent.spawn`,
  `muse.exec`, `process.poll`, and todo lists — but the 2026-10-10
  audited surface of this runtime exposes `subagent`, `shell`, and no
  todo tool. Either "Muse agents (this runtime)" names a different
  runtime than the one audited, or the Muse column is stale. No Muse
  cell rewritten pending the operator's ruling.
