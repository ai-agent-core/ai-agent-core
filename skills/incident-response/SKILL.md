---
name: incident-response
description: Run an incident — detect, declare, mitigate, communicate, recover, postmortem. Blameless, evidence-driven, and oriented to restoring service first.
---

# Incident response

Use this skill **when something is broken in production and users
are affected** (or are about to be).

The skill has two halves:

1. **Live**: stabilize and communicate during the incident.
2. **After**: postmortem, action items, follow-through.

Authoritative source: `principles/OPERATIONAL_PRINCIPLES.md` and
`rules/OBSERVABILITY_RULES.md`.

---

## Premise

The goal during an incident is **mitigation**, not root cause.
Root cause is for the postmortem.

Mitigation paths in order of preference:

1. roll back the most recent change (deploy, flag, config),
2. flip a feature flag / kill-switch,
3. drain or fail over traffic,
4. scale out (if saturation is the cause),
5. apply a hotfix (last resort).

Forward-fix is rarely faster than rollback. Trust the rollback.

---

## Step 1 — Detect and declare

A page fires; a customer reports; you notice. Within minutes:

- **acknowledge** the alert,
- open a dedicated incident channel (chat),
- pin the trace ID, dashboard link, recent deploys,
- declare an **Incident Commander (IC)** — one person, owns
  decisions and communication,
- declare a severity (use the team's documented scale; SEV1 for
  user-impacting outage, SEV2 for partial degradation, etc.).

If unsure whether it is an incident: declare it. Closing a small
incident is cheaper than missing a real one.

---

## Step 2 — Stabilize

The IC drives toward mitigation. Specific actions:

- **What changed?** Last deploy, last flag, last config, last
  migration. Roll back if a change correlates.
- **What's the blast radius?** Which users / tenants / regions /
  endpoints?
- **Is it spreading?** Saturation? Retry storm? Cascade?
- **Mitigate first, diagnose second.** Apply the cheapest action
  that stops the bleeding even before you understand the cause.

Communicate every action taken in the incident channel: time,
person, action, observed effect. Even "I tried X, no change."

---

## Step 3 — Communicate

- **Internal** — incident channel updates every 10–30 min while
  active. Status, what's been tried, current hypothesis, next
  step.
- **External** — status page updated when user-impacting,
  language is honest and actionable. "We are investigating
  errors on / login" beats "We are aware of an issue."
- **Stakeholders** — leadership / support / partners notified at
  the documented thresholds.
- Do not speculate on root cause publicly during the incident.
  "We are investigating" is honest. Specific guesses can become
  permanent record.

---

## Step 4 — Roles

For non-trivial incidents, separate roles:

- **Incident Commander (IC)** — decisions and prioritization,
  not the keyboard.
- **Operations / Subject-matter expert** — at the keyboard,
  applying mitigations.
- **Communications lead** — internal updates, status page,
  customer-facing.
- **Scribe** — timeline, decisions, observations (cheap insurance
  for the postmortem).

For small incidents, one person can wear multiple hats — but
keeping IC distinct from Operations is highly valuable even for
SEV2.

---

## Step 5 — Resolve

Once the symptom is gone:

- **monitor** the previously-broken signal for a soak window
  (often 30–60 min) before declaring resolved,
- post a final summary (start time, resolution time, what
  mitigated, what remains),
- close the status page with appropriate language,
- ensure on-call for the next shift has a written hand-off if
  follow-up work is pending,
- schedule the postmortem.

Forbidden:

- declaring resolved at the first green dashboard,
- closing the channel without a written summary,
- leaving the next shift without context.

---

## Step 6 — Postmortem

Within one week:

1. **Timeline** — UTC, with sources (logs, alerts, chat, deploy
   records). Specific minutes.
2. **Impact** — who was affected, how many, how long, what they
   experienced.
3. **Detection** — how the incident was noticed; could it have
   been noticed sooner?
4. **Mitigation** — what stopped the bleeding; how long that
   took; could it have been faster?
5. **Contributing causes** — plural. There is no single root
   cause for non-trivial systems.
6. **What went well** — capture so the team repeats it.
7. **What went poorly** — the things to fix.
8. **Action items** — owner + deadline + ticket. Tracked to
   completion.

**Blameless framing** is mandatory. The system, not the person.
"Why did the engineer do X" is the wrong question; "why did the
system make X feel like the right thing to do" is the right one.

A postmortem with no completed action items is a story.

---

## Step 7 — Action items

- prioritized,
- tracked in the same backlog as feature work,
- visible owner per item,
- deadline set,
- closure tracked (the next time a similar incident happens, the
  team checks: did the action item help?).

Action items decay if not made visible. Keep them on a board.

---

## Step 8 — Pattern recognition

Across multiple incidents, look for:

- the same contributing cause appearing more than once,
- the same alert firing repeatedly without change,
- the same runbook always missing the right step,
- the same component as the source.

When the pattern is clear, do **systemic** work — invest in the
class of fix that retires the pattern, not just this instance.

---

## Anti-patterns

- declaring "false alarm" without evidence (often it is the
  early signal of a real incident),
- mitigating by "restart and pray,"
- forward-fixing instead of rolling back because it feels less
  embarrassing,
- writing a postmortem that names individuals,
- "single root cause" framing for complex incidents,
- action items without owners,
- skipping postmortems for "small" incidents (the small ones are
  the cheapest lessons).

---

## When this skill says STOP

- you are alone and the incident is SEV1 → page another engineer
  before continuing. Two-person rule for high-risk mitigations.
- the mitigation might cause data loss → escalate before
  applying.
- the root cause looks like a security breach → switch to the
  security-incident playbook (different posture: contain,
  preserve evidence, involve security, do not just "restart").

---

## Prime directive

The on-call who reads this is also you in six months. Build the
process you would want to find on the worst day. Mitigate fast,
communicate honestly, postmortem ruthlessly, and turn lessons
into fewer pages next quarter.

Every incident is a paid lesson. Recover the value.
