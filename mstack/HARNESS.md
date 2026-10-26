# HARNESS.md — per-harness translation notes

Runbooks are harness-neutral. They name verbs (spawn a subagent, keep a
todo list, wake on an event); this file translates each verb into the
six supported harnesses. A runbook never hardcodes a harness primitive —
it points here.

The six harnesses: **Muse agents**, **Claude Code**, **OpenCode**,
**Cursor**, **Codex**, **Antigravity** (Google DeepMind / agy runtime).

Research rule, enforced: every verb claim carries its official-doc source
URL inline. Claims that could not be verified in official docs are marked
`unverified` and the cell degrades to the documented fallback. Section 6
lists everything that could not be verified.

When the runner or toolchain itself is broken (missing toolchain, blocked
install), improvise the nearest equivalent and log it as a harness fault —
never as a failed attempt. This binds corpus-wide: every runbook and skill
inherits it from here; debugging.md's ledger row is the per-run record.

## 1. Verb translations

Each cell names the native primitive. `Muse agents` and `Antigravity` claims are first-hand
(observed in runtime; no public URL exists). First-hand claims carry their
date (`first-hand YYYY-MM-DD`) and outrank doc-sourced claims for that
runtime — docs describe the product, first-hand describes the machine.
OpenCode claims dated 2026-10-26 were audited under the oh-my-opencode-slim
plugin over opencode v2.1.4 — not vanilla opencode; its surface (agent
roster, task lifecycle, wake behavior) is what the cells describe. The
earlier 2026-10-10 findings came from a vanilla v2.0.26 audit, which is
why some are refused below.

### Spawn a subagent

| Harness | Primitive |
|---|---|
| Muse agents | `subagent.spawn` with a self-contained brief unverified (under ruling, see §6; child agent, own context, result delivered back) |
| Claude Code | Task / Agent tool: `subagent_type`, optional `run_in_background`, optional `isolation` (https://code.claude.com/docs/en/sub-agents) |
| OpenCode | `subagent` tool spawning one of the runtime's named agents — this runtime is opencode v2.1.4 under the oh-my-opencode-slim plugin, so vanilla's `general`/`explore` are not exposed here: `council`, `designer`, `explorer`, `fixer`, `librarian`, `observer`, `oracle` (`general` refuted first-hand 2026-10-26: "Unknown agent: general"). Optional `model`, `sessionID` (resume a previous child session), and `background` parameters; `@` mentions; child sessions with results delivered back (first-hand 2026-10-26; earlier audit 2026-10-10; official docs still name `task` + `scout`: https://opencode.ai/docs/agents/) |
| Cursor | Agent's Task tool; custom subagents as markdown files in `.cursor/agents/` (also reads `.claude/agents/`, `.codex/agents/`) (https://cursor.com/docs/subagents) |
| Codex | Prompt-driven subagent workflows ("spawn two agents", "one agent per point"); custom agents as TOML files in `.codex/agents/` (https://developers.openai.com/codex/subagents) |
| Antigravity | `invoke_subagent` tool: `TypeName` (`self`, `research`, `image-generator`, or defined type), `Role`, `Prompt`, optional `Model` (`inherit`, `flash_lite`, `flash`, `pro`), optional `Workspace` (`inherit`, `branch`, `share`). Child runs detached with own context and delivers results back via reactive messaging; `send_message` delivers follow-ups. Dynamic agent definition via `define_subagent`; lifecycle management via `manage_subagents` (`list`, `kill`, `kill_all`) (first-hand 2026-10-26) |

### Run in background

| Harness | Primitive |
|---|---|
| Muse agents | `muse.exec` with `background: true`; poll with `process.poll` / `process.log` unverified (under ruling, see §6) |
| Claude Code | Task `run_in_background`; background sessions via `claude agents` (https://code.claude.com/docs/en/sub-agents) |
| OpenCode | first-hand 2026-10-26 on v2.1.4: `subagent(background: true)` detached runs confirmed; the runtime tracks the child on a background job board and wakes the parent automatically on completion, result delivered — no polling. Lifecycle tools: `task_result` (retrieve a completed child's final message — verified), `task_status` (tracked state by alias; its deep status probe errors on this build, non-fatal), `task_message` (queue a non-interrupting message), `task_cancel`, `task_revive`. Earlier: confirmed 2026-10-10. Fallback unchanged: shell backgrounding (`&`, `nohup`) |
| Cursor | Subagent foreground vs background modes; `is_background` frontmatter on custom subagents; `/in-cloud` hands work to a cloud subagent (https://cursor.com/docs/subagents) |
| Codex | `degraded` — no first-class detached background subagent documented. Fallbacks: `codex exec` (headless, JSONL stream) backgrounded with `&` and polled; hook handlers may set `async: true` to run in the background (https://developers.openai.com/codex/hooks) |
| Antigravity | `run_command` with `WaitMsBeforeAsync` (auto-backgrounds to a task if command exceeds threshold) or `IsDaemon: true`; `manage_task` (`list`, `status`, `send_input`, `kill`). Completed background tasks notify and wake the agent automatically without polling (first-hand 2026-10-26) |

### Keep a todo list

| Harness | Primitive |
|---|---|
| Muse agents | Todo lists (tracked items) — unverified (under ruling, see §6) |
| Claude Code | TodoWrite / TodoRead tools (https://docs.claude.com/en/api/agent-sdk/todo-tracking — cited via search; not confirmed on code.claude.com this session) |
| OpenCode | refuted first-hand 2026-10-10 (opencode v2.0.26), re-confirmed 2026-10-26 (v2.1.4): no todo tool exists under any name. Fallback: plan state in repo files — same as Cursor |
| Cursor | `unverified` — no official todo tool found in the docs surveyed. Fallback: plan state in repo files (e.g. `plan.md` checklists) |
| Codex | `todo_write` / `update_plan` built-in solver tools (https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide/) |
| Antigravity | Artifact system (`write_file` with `ArtifactMetadata` for persistent task lists and experiment logs stored in `<appDataDir>/brain/<conversation-id>`) or plan files in repo (`plan.md`); `/plan` slash command for plan generation. No dedicated `todo_write` tool (first-hand 2026-10-26) |

### Invoke a skill / markdown file

| Harness | Primitive |
|---|---|
| Muse agents | Read the `SKILL.md` and follow its instructions unverified (under ruling, see §6) |
| Claude Code | Native `SKILL.md` + Skill tool; Agent Skills open standard; `disable-model-invocation` frontmatter (https://code.claude.com/docs/en/skills) |
| OpenCode | `skill` tool (loads a `SKILL.md` by id; confirmed first-hand 2026-10-26 on v2.1.4); native `SKILL.md` support (docs: https://opencode.ai/docs/tools/; https://opencode.ai/docs/skills/ — skills page cited via search results, not opened this session) |
| Cursor | Agent Skills (`SKILL.md`); the official subagents doc directs single-purpose tasks to "a skill or command instead" (https://cursor.com/docs/subagents). Skill directory path `.cursor/skills/` is third-party-reported, `unverified` in official docs |
| Codex | `.agents/skills/<name>/SKILL.md` with `name` + `description` frontmatter (https://developers.openai.com/codex/skills) |
| Antigravity | Native Agent Skills: directories with `SKILL.md` containing YAML frontmatter (`name`, `description`). Agent reads instructions via `read_file` on trigger, or executes helper scripts in `scripts/`. Built-in: `~/.gemini/antigravity-cli/builtin/skills/`; user: `~/.gemini/skills/` (first-hand 2026-10-26) |

### Watch a condition / wake on an event

| Harness | Primitive |
|---|---|
| Muse agents | No event system — unverified (under ruling, see §6). Fallback: heartbeat polling loop (section 2) |
| Claude Code | Hooks: `Stop`, `SubagentStop`, `Notification`, `SessionEnd` fire scripts on agent-loop events (https://code.claude.com/docs/en/hooks). No timer primitive — external conditions still need the heartbeat fallback |
| OpenCode | Plugin hooks: `session.idle`, `session.created`, `session.deleted`, `tool.execute.before/after`, `todo.updated`, `file.watcher.updated` (https://opencode.ai/docs/plugins/). First-hand 2026-10-26: completed background subagents/tasks wake the parent automatically, no polling; `wait_for_user` pauses for external human action until the next user message; `question` tool collects structured user input mid-run. No timer/condition primitive — heartbeat fallback stands for external conditions |
| Cursor | Hooks in `.cursor/hooks.json`: `stop` hook may return `followup_message` to re-arm the loop, bounded by `loop_limit`; also `subagentStart` / `subagentStop`, `sessionStart` / `sessionEnd` (https://cursor.com/docs/hooks). No timer primitive — heartbeat fallback |
| Codex | `notify` in `config.toml`: runs a program on `agent-turn-complete` with a JSON payload — fire-and-forget, observer-only, cannot block (https://developers.openai.com/codex/config-reference). Lifecycle hooks `Stop`, `SubagentStop` (trust-reviewed before first run) (https://developers.openai.com/codex/hooks). No timer primitive — heartbeat fallback |
| Antigravity | First-class `schedule` tool: one-shot timers (`DurationSeconds`) or recurring cron (`CronExpression`), with optional early wakeup via `TimerCondition` (`'never'`, `'any'`, or matching sender ID). Background tasks and subagents wake the agent reactively without polling sleep (first-hand 2026-10-26) |

### Isolate work (worktrees)

| Harness | Primitive |
|---|---|
| Muse agents | `git worktree` via shell; subagents share the parent checkout unverified (under ruling, see §6) |
| Claude Code | `git worktree` via Bash; the Agent tool exposes an `isolation` option (https://code.claude.com/docs/en/sub-agents) |
| OpenCode | First-class on this runtime: `worktree_create` / `worktree_list` / `worktree_remove` (first-hand 2026-10-26 on v2.1.4; create → list → remove cycle exercised live; worktrees live under the opencode data dir at `worktree/<hash>/<name>`). Fallback: plain `git worktree` via Bash (https://opencode.ai/docs/plugins/) |
| Cursor | First-class: "ask for isolation and each subagent runs in its own copy of the project" — an isolated git worktree with its own branch and working directory, or a cloud environment with a dedicated VM (https://cursor.com/docs/subagents) |
| Codex | `degraded` — no native per-subagent worktree. Fallbacks: `git worktree` via shell; `sandbox_mode` (`read-only` for verifiers) (https://developers.openai.com/codex/subagents) |
| Antigravity | First-class: `invoke_subagent` exposes `Workspace: 'share'` (worktree-style shared repo directory without duplicating storage) and `Workspace: 'branch'` (isolated branch/clone); plain `git worktree` via `run_command` (first-hand 2026-10-26) |

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
| Muse agents | none available | background exec loop unverified (under ruling, see §6) |
| Claude Code | `Stop` / `Notification` hooks | background task + sleep |
| OpenCode | `session.idle` / `file.watcher.updated` plugin hooks; background task completion wakes the agent automatically (first-hand 2026-10-26) | shell loop |
| Cursor | `stop` hook with `followup_message` + `loop_limit` | hook script sleeps between re-arms |
| Codex | `notify` script writes a flag file on `agent-turn-complete`; `Stop` hook | shell loop polling the flag |
| Antigravity | `schedule` tool with `TimerCondition`, or reactive wakeup on subagent/task message | `schedule` tool with `DurationSeconds` interval from `values.md` (no shell sleep, native reactive wakeup) |

Requirement: the heartbeat arm never busy-waits. Its interval comes from
`values.md#heartbeat.interval` by name, never as an inline literal, and
each tick is logged so a stalled loop is distinguishable from a quiet one.

## 3. Isolation options

| Harness | Options |
|---|---|
| Muse agents | `git worktree` via shell unverified (under ruling, see §6). Subagents share the checkout — isolate by hand before delegating write work |
| Claude Code | `git worktree` via Bash; Agent tool `isolation` option (https://code.claude.com/docs/en/sub-agents) |
| OpenCode | first-class `worktree_create` / `worktree_list` / `worktree_remove` (first-hand 2026-10-26); `git worktree` via Bash (https://opencode.ai/docs/plugins/) |
| Cursor | Per-subagent isolated git worktree with own branch (first-class); whole-agent isolation via worktree or cloud subagent VM (https://cursor.com/docs/subagents) |
| Codex | `git worktree` via shell; `sandbox_mode: read-only` for verifier-style subagents (https://developers.openai.com/codex/subagents) |
| Antigravity | `invoke_subagent` with `Workspace: 'share'` (shared repo worktree) or `Workspace: 'branch'` (isolated clone/branch); `git worktree` via `run_command` (first-hand 2026-10-26) |

Rule of thumb for runbooks: verifiers get a worktree or a read-only
sandbox; fixers get a branch. The runbook states which, this table says
how on each harness.

## 4. Capability matrix

Rows: the ten runbooks. Columns: the six harnesses.
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
| OpenCode | degraded — background subagents confirmed first-hand 2026-10-26; poll loop via shell heartbeat; round tracking falls back to a state file (no todo tool) |
| Cursor | degraded — loop maps to the `stop`-hook `followup_message` pattern, but round tracking falls back to a state file (no documented todo tool) |
| Codex | degraded — loop maps to a shell heartbeat poll; `notify` cannot re-arm a loop (fires once per turn, observer-only) |
| Antigravity | full — fixer and verifier via invoke_subagent, poll/timer via schedule or run_command |

### overnight-orchestrator

Detached long run with wake-on-event, heartbeat, and escalation.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | full — background subagent tasks with automatic completion wake (first-hand 2026-10-26); `session.idle` plugin hook as watcher; shell heartbeat baseline |
| Cursor | degraded — background and cloud subagents exist, but no documented timer/cron primitive; heartbeat fallback |
| Codex | degraded — no first-class background session; `codex exec` backgrounded with `&`, `notify` + heartbeat for wake |
| Antigravity | full — schedule tool handles detached cron/timer with reactive wakeup; background subagents and tasks |

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
| Antigravity | full — native skill reading; brain artifacts or plan files for tracking |

### biweekly-standards-research

Research rotating topics, write files, open a dated branch + PR.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | full |
| Cursor | full |
| Codex | full |
| Antigravity | full — research subagent, file tools, git via run_command |

### measurement-eval

Interleaved runs, median + range, falsifiable checks. Sequential.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — todo list falls back to plan files in the repo |
| Cursor | degraded — todo list falls back to plan files in the repo |
| Codex | full |
| Antigravity | full — sequential execution via run_command, falsifiable checks, artifacts for run logs |

### final-gate

Verifier-never-author on an isolated checkout; blocking verdict.

| Harness | Cell |
|---|---|
| Muse agents | full — worktree via shell |
| Claude Code | full — worktree via Bash, Agent `isolation` option |
| OpenCode | full — first-class `worktree_create` / `worktree_remove` (first-hand 2026-10-26); verifier child session in its own worktree |
| Cursor | full — per-subagent isolated worktree is first-class |
| Codex | degraded — no native per-subagent worktree; `git worktree` via shell plus `read-only` sandbox for the verifier |
| Antigravity | full — invoke_subagent(Workspace: 'share') or git worktree via run_command; verifier subagent |

### figure-it-out

Fallback runbook: spawn, probe, track, report. Minimal verbs.

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — todo list falls back to plan files in the repo |
| Cursor | degraded — todo list falls back to plan files in the repo |
| Codex | full |
| Antigravity | full — invoke_subagent, run_command probe, artifacts for tracking |

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
| Antigravity | full — invoke_subagent with brief and Workspace isolation; artifacts for state tracking |

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
| Antigravity | full — repro and bisect via run_command, edit_file for minimal fix, verification test |

### rebuild-from-contract

Record a baseline, inventory the surviving contract, implement leaf-first,
iterate against the gate. Sequential and single-agent: shell, file reads,
one artifact write, plus run-state writes (the recorded baseline).

| Harness | Cell |
|---|---|
| Muse agents | full |
| Claude Code | full |
| OpenCode | degraded — todo list falls back to plan files in the repo |
| Cursor | degraded — todo list falls back to plan files in the repo |
| Codex | full |
| Antigravity | full — baseline recorded in artifacts, file tools, iterate against gates |

### Matrix notes

- 60 cells filled: 42 full, 18 degraded, 0 unsupported. No cell is
  unsupported because every runbook degrades to shell + files +
  heartbeat, which all six harnesses provide. If a future harness lacks
  a shell, its column gets real `unsupported` cells with "run this
  runbook on a shelled harness" as the alternative.
- Cursor's and OpenCode's recurring degradation is one missing primitive: no documented todo tool (Cursor), no existing todo tool — refuted first-hand 2026-10-10 (OpenCode). The fallback (plan files in the repo) is cheap and inspectable, so the degradation is minor.
- Codex's recurring degradation is background + per-subagent worktrees, falling back to the same shell idioms the runbooks already use for polling. (OpenCode background execution was previously listed here; first-hand 2026-10-10 confirms the primitive exists, re-confirmed 2026-10-26 with a full task lifecycle.)
- OpenCode re-audit 2026-10-26 (opencode v2.1.4): spawnable agents are the named specialist set (`council`, `designer`, `explorer`, `fixer`, `librarian`, `observer`, `oracle` — `general` refuted); worktree commands are first-class (`worktree_create` / `worktree_list` / `worktree_remove`, exercised live); background tasks wake the parent reactively with results delivered. final-gate and overnight-orchestrator flipped degraded → full on these findings.
- Antigravity achieves 10/10 full cells: native `schedule` tool (cron and timer with reactive wakeup) satisfies overnight-orchestrator and bot-review-loop without shell sleep; `invoke_subagent` provides native worktree isolation (`Workspace: 'share'` / `'branch'`); and brain artifacts provide persistent state tracking.

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
| Antigravity | degraded — no equivalent binding; `gh` CLI via `run_command` (operator supplies auth) |

`gh_push.py` is the reference implementation of the contract. Porting it
(or a thinner `gh`-CLI wrapper) to another harness is operator work, not
runbook work — the runbooks stay unchanged either way.

## 6. What could not be verified

From official docs, during this session's research:

- **OpenCode background subagents — resolved.** Confirmed first-hand
  2026-10-10; re-verified 2026-10-26 (v2.1.4) with the full lifecycle:
  `task_result`, `task_status`, `task_message`, `task_cancel`,
  `task_revive`; completion wakes the parent automatically with the
  result delivered. Official docs remain silent.
- **OpenCode worktrees — resolved first-hand 2026-10-26 (v2.1.4).**
  `worktree_create` / `worktree_list` / `worktree_remove` exist and were
  exercised live (create → list → remove). Official docs still don't
  document them; the claims are first-hand, not doc-sourced.
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
- **Timer/cron primitive for agents.** Stated as "not found in the docs surveyed"
  for the original five harnesses (why the heartbeat arm is their portable
  baseline). Antigravity provides a first-class native `schedule` tool (cron +
  one-shot timer with `TimerCondition` and reactive wakeups), verified
  first-hand 2026-10-26.
- **OpenCode tool names (corrected first-hand 2026-10-10; re-audited
  2026-10-26 on v2.1.4).** The spawn primitive is the `subagent` tool,
  not the documented `task` tool. The 2026-10-26 roster: `council`,
  `designer`, `explorer`, `fixer`, `librarian`, `observer`, `oracle` —
  `general` refuted ("Unknown agent: general"), superseding the earlier
  `general`/`explore` audit. No todo tool exists under any name
  (`todowrite`/`todoread` refuted 2026-10-10; re-confirmed 2026-10-26).
  No timer/condition primitive — heartbeat fallback stands.
- **Muse-agents first-hand cells vs this runtime (operator ruling
  needed).** The Muse column claims first-hand `subagent.spawn`,
  `muse.exec`, `process.poll`, and todo lists — but the 2026-10-10
  audited surface of this runtime exposes `subagent`, `shell`, and no
  todo tool. Either "Muse agents (this runtime)" names a different
  runtime than the one audited, or the Muse column is stale. No Muse
  cell rewritten pending the operator's ruling.
- **Antigravity runtime (confirmed first-hand 2026-10-26).** Google DeepMind / agy runtime. Native primitives verified:
  - Subagents: `invoke_subagent` (with `TypeName`, `Role`, `Prompt`, `Model`, `Workspace: 'inherit'|'branch'|'share'`), `define_subagent`, `manage_subagents` (`list`, `kill`, `kill_all`), `send_message`. Child execution runs detached with automatic reactive wakeup upon message delivery or completion.
  - Background execution: `run_command` with auto-backgrounding via `WaitMsBeforeAsync` threshold or `IsDaemon: true`; `manage_task` (`list`, `status`, `send_input`, `kill`). Completed tasks wake the agent reactively without polling.
  - Scheduling / Wake-on-event: first-class `schedule` tool supporting one-shot timers (`DurationSeconds`) and recurring cron expressions (`CronExpression`) with `TimerCondition` early wakeups. Never use shell sleep for agent timing.
  - State tracking: conversation brain artifacts (`write_file` with `ArtifactMetadata` for task lists, plans, and persistent state); `/plan` slash command. No dedicated `todo_write` solver tool.
  - Skills: native `SKILL.md` support with YAML frontmatter at `~/.gemini/antigravity-cli/builtin/skills/` and `~/.gemini/skills/`.
  - Push abstraction: uses `gh` CLI via `run_command` with ambient operator credentials (e.g. `gh auth git-credential`).
