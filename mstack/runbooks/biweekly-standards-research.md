---
name: biweekly-standards-research
description: Use when the biweekly standards research run is due: a rotating topic to research, ranked deltas to fold in, the portable core to re-distill, or a research PR to drive through the bot loop to a clean stop.
---

## Exit predicate

The run ends when one of these holds:

- a dated branch + PR is opened carrying a REPORT line, or
- a no-change run is reported with its evidence — what was researched, what was checked, why nothing shipped.

A run that researched and reported nothing is not a run. Silence is not an outcome.

## Requires

- A standards library with a topic backlog and a source checklist.
- The push binding (`HARNESS.md` §5).
- A human merge gate: only the human merges standards-repo PRs.

## Inputs

- `topic`: the rotating research topic for this run.
- `source-checklist`: sources already mined — checked first, never repeated.
- `theme-backlog`: candidate themes for future runs.

## Steps

1. **Pick the topic.** Take the next theme from the backlog. Check it against the source checklist — never mine a source twice. If the source is a plugin collection, mine ONE plugin this run.
2. **Research the topic.** Read the primary sources. Capture verbatim quotes with their provenance — a delta without a quote is a rumor.
3. **Rank the deltas.** Rank each candidate change by impact, each with its why. The human vetoes line-by-line: present every delta with its reason, never a pre-filtered list.
4. **Re-distill the portable core.** Fold accepted deltas into the distilled principles. **Never touch the sacred repo-specific section of the repo's AGENTS.md** — the sync owns everything above that line; nothing below it. No-change is a valid outcome — report it as such. Behavior-change edits are playground-validated before they ship.
5. **Capture lessons with the `reflect` skill.** Mine the run's Accepted / Rejected / Backlog. Backlog entries feed the next run's theme list.
6. **Open the dated branch + PR** via the harness push binding — never direct to main. Standards PRs merge on the human's click only.
7. **Drive the bot-review loop to a clean stop.** Address or disposition every finding; the freeze rule holds — never re-litigate a dispositioned finding.
8. **Update the checklist.** Record the mined sources and the shipped or rejected deltas. Update `references/distillation-record.json` on shipped changes — the runbook maintains it, creating it on first use.

**A no-change run still reports.** Research performed, sources checked, nothing worth shipping — that is a REPORT line, not an empty run.

## Reply:

```
## Reply: biweekly-standards-research REPORT

- Topic: <topic> — <source(s) mined>
- Outcome: shipped | no-change
- PR: <dated branch> → <PR URL> (shipped only)
- Deltas: <ranked list with whys, or "none — <reason>">
- Distillation: <changed | no-change> (+ playground evidence for behavior changes)
- Checklist: <sources recorded; deltas recorded as shipped/rejected>
- Reflect: <Accepted n | Rejected n | Backlog n → next-run themes>
- Assumptions: <none | listed>
- Open questions: <none | listed>
```

Every REPORT line carries the outcome. A shipped run without a PR URL is not shipped.
