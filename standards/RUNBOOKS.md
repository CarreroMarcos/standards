---
title: Runbooks and Incident Response Standard
version: "1.0"
scope: Writing runbooks that work at 3 a.m. and running an incident without improvising judgment under pressure
consult_when: "When writing or following a runbook, when an alert fires, or when deciding whether something is an incident at all."
last_reviewed: 2026-10-25
---

# Runbooks and Incident Response Standard

**Core principle:** nobody improvises judgment at 3 a.m. — the runbook carries the decisions made in daylight, and the incident process carries the ones that can't be pre-made.

## Sections

- **One runbook per symptom** — engineers search by what they see
- **The runbook template** — trigger, impact, first 5 minutes, mitigations, escalation, comms, verification
- **Declare early** — over-declaring is cheap
- **Roles: commander coordinates, responders respond** — one incident, one commander
- **Mitigate before root cause** — stop the bleeding first
- **Verify with metrics, not feelings** — the graph proves it
- **Close the loop** — every incident updates its runbook or deletes it
- **Runbook hygiene** — linked from the alert, tested, pruned
- **Agents executing runbooks** — the runbook bounds the agent, it does not bless improvisation

## One runbook per symptom

**Engineers search by what they see, not by system architecture.** "Checkout API returning 503s," "BGP session flapping," "disk full on the worker" — one symptom, one runbook. A runbook covering a whole service is a manual nobody opens; a runbook covering one alert is a checklist somebody follows.

- Name the file for the symptom or the alert, not the component.
- If two symptoms share most steps, they still get two runbooks with a shared link — deduplication that costs a reader a hop at 3 a.m. is not a saving.
- A runbook nobody opens during its incident is a failed runbook, whatever its author thinks of it.

## The runbook template

**Copy-paste commands, not descriptions of commands.** Every step is written for a tired reader who has never seen this service: what to run, what good output looks like, what to do when it doesn't match.

- **Trigger:** the alert or symptom that starts this runbook, verbatim as it appears.
- **Impact check:** who is affected and how badly — the first questions, with the dashboard or query that answers them.
- **First 5 minutes:** the three or four checks that discriminate the common causes, in order. Dashboards linked, queries pasted, no tribal knowledge assumed.
- **Mitigations, most likely first:** rollback, scale, failover, feature flag — each as an exact command, each with its own rollback. A mitigation without a way back is a second incident.
- **Escalation:** when to escalate and to whom, with the channel — not "escalate if stuck" but "escalate if the cause is not found in 15 minutes." Time-boxed escalation beats hero-soloing.
- **Communication:** who must be informed, with a message template. Status updates are timed, specific, and regular — long silences invite executives to interrupt responders for status.
- **Verification:** the exact metric and threshold that proves resolution (error rate under X, latency under Y, health checks green for 10 minutes). See below.

## Declare early

**Anyone may declare an incident, and doubt resolves toward declaring.** Over-declaring is cheap — a declared incident that turns out minor costs a channel and a page. Under-declaring is how a contained issue becomes a breach notification: the response clock, the severity, and the notification obligations all start at declaration, and none of them run retroactively.

- Classify severity within the first five minutes. Severity sets who gets paged and what the response clock is — it is a triage decision, not a verdict on the cause.
- A rough severity ladder, adapted per team: SEV-1, confirmed breach or full outage, page immediately; SEV-2, major degradation or suspected breach, page on-call; SEV-3, contained or single-tenant impact with a workaround, business hours; SEV-4, minor anomaly or near-miss, ticket and triage.
- Do not wait for the cause before declaring. "We don't know why yet" is a reason to declare, not to delay.

## Roles: commander coordinates, responders respond

**One incident, one Incident Commander (IC), and the IC does not debug.** The IC coordinates, tracks tasks, runs comms, and declares resolution. The moment the most senior engineer is both commanding and debugging, nobody is coordinating — tasks duplicate, comms stall, and the bridge talks over itself.

- The first responder is interim IC until explicitly handed off; handoff is stated, not assumed.
- Roles are named in the declaration message: IC, responder/operator lead, comms lead, scribe. A declaration message carries title, severity, IC, channel, dashboard, and runbook link — everything a joiner needs without asking.
- Joiners take a task or stay out. An incident bridge with everyone talking and nobody owning a task is slower than a bridge with three people.

## Mitigate before root cause

**Stop the bleeding, then find the wound.** Roll back the deploy, fail over, disable the flag, scale up — mitigation restores service while root-cause analysis waits. A customer does not care why the site is down; they care that it is back up.

- If the hypothesis is strong enough, roll back on it — do not keep digging for certainty while users are affected.
- Preserve evidence before destructive mitigations: restarting everything first destroys the logs that explain the incident. Capture state, then restart.
- A fragile workaround is not a resolution. Resolution requires the service restored and verified, alerts normal, and a rollback or permanent fix in place — not a held-together workaround that reopens ten minutes later.

## Verify with metrics, not feelings

**Data proves success.** "It feels faster" is not verification. The runbook states the metric, the threshold, and the observation window before the incident starts — e.g., error rate under 0.5% and latency under 200 ms, sustained for 10 minutes — and resolution is declared only when the numbers hold for that window.

- Watch the dashboards after the mitigation, don't just check once. A graph that recovers and relapses was never resolved.
- State the impact in the resolution message: duration, estimated affected users or requests, mitigation applied, and the postmortem date. The resolution message is the incident's first draft of history.

## Close the loop

**Every incident updates its runbook or deletes it — no third option.** Schedule the postmortem while memories are fresh (SEV-1 and SEV-2 always get one, within a few working days), assign follow-up actions with owners, and fold what the incident taught back into the runbook that was used: a step that was wrong gets corrected, a missing step gets added, a step that was never needed gets cut.

- The postmortem asks what the system did, not who failed. Blame-free is not decoration: a review that punishes the responder teaches the next responder to hide the timeline.
- An incident with no runbook produces one, written from the timeline while it is fresh. An incident that exposed a runbook as stale produces a corrected runbook, not a ticket to correct it someday.

## Runbook hygiene

**Link the runbook from the alert itself.** A runbook that takes a search to find at 3 a.m. is a runbook that won't be found. The alert carries the link; the runbook carries the dashboard links and the queries.

- Test the commands: a runbook whose commands were never pasted and run is a draft. Every command in it has been executed against the real system, or is marked untested and untrusted.
- Review on a cadence and prune without sentiment: after every major incident, and at least quarterly across the set. A stale runbook is worse than a missing one — it sends a responder down a path that no longer exists, with confidence.
- Steps that are always the same are candidates for automation. A runbook that a script can execute should become a script with a runbook wrapped around the judgment calls, not a document that a human retypes.

## Agents executing runbooks

**The runbook bounds the agent; it does not bless improvisation.** An agent handed a runbook follows its steps and its escalation triggers — when the runbook says escalate at 15 minutes without a cause, the agent escalates instead of inventing a step. Destructive mitigations (deletes, drops, failovers that drop traffic) stay under the verify-before-destructive gate in `AGENTIC-SAFETY.md`: confirm the exact target and authorization first, even mid-incident.

- An agent that cannot complete a runbook step says which step and why, and escalates — it does not substitute a plausible-looking alternative. A substituted step during an incident is an unreviewed change to production.
- Runbook steps that publish anything (status pages, public posts, screenshots) go through the sanctioned publication path in `AGENTIC-SAFETY.md` ("PixelLeak: never improvise a publication channel") — an incident is exactly when the temptation to improvise a public destination is highest, and exactly when it is least acceptable.
