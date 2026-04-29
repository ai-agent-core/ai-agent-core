---
name: feature-flag
description: Decouple deploy from release with flags — short-lived release flags, kill-switches, experimentation, with explicit cleanup discipline.
---

# Feature flag

Use this skill **whenever a flag is being introduced, used, or
retired**.

A feature flag is leverage: it lets the team ship code separately
from making it visible. Used well, flags reduce risk, enable
canaries, and unlock experimentation. Used badly, flags become
permanent technical debt that no one understands.

---

## Premise

> Deploy ≠ Release.

- **Deploy** is putting code on servers.
- **Release** is making behavior visible to users.

A flag is the gate between them.

---

## Flag types — pick deliberately

| Type                  | Purpose                                          | Lifespan       |
| --------------------- | ------------------------------------------------ | -------------- |
| Release flag          | Roll out a feature gradually                     | Short (days)   |
| Kill switch / ops    | Disable a path under incident                    | Long (years)   |
| Permission / entitlement | Gate features by tenant / plan / role        | Long           |
| Experiment / A-B     | Compare variants for measurement                 | Short (weeks)  |

Mixing types in one flag is forbidden. A release flag that became
a permanent permission is now both — and neither cleanly.

---

## Lifecycle

Every release / experiment flag MUST have:

1. **Owner** — person or team.
2. **Created date.**
3. **Removal target date** — explicit; if it passes, it goes on
   the cleanup backlog.
4. **Documented kill-switch behavior** — what does "off" do?
5. **Default state** for new environments.

Long-lived flags (kill switches, permissions) have:

- documented purpose,
- review cadence (annual at least),
- owner who can be paged.

A flag without an owner is debt.

---

## Naming

- prefix by type: `release.`, `kill.`, `perm.`, `exp.`,
- domain in the middle: `release.checkout.new-ui`,
- avoid negative names (`disable-x`); prefer affirmative
  (`enable-x` or `x.v2`),
- experiment names include the experiment id.

Forbidden:

- generic `feature1`, `temp_flag`,
- names that lie about state (`enable_*` whose default is on,
  whose absence enables, etc.).

---

## Storage and evaluation

- flags live in a flag service (LaunchDarkly, Unleash, ConfigCat,
  homegrown) — not in `.env`,
- evaluation is fast (cached / SDK-side, falls back to safe
  default on outage),
- **default value on outage is documented** (usually "off" / the
  pre-flag behavior),
- evaluation is observable (telemetry counts how often each flag
  evaluates each value).

A flag service outage MUST NOT brick the application.

---

## Targeting

For most flags, simple is best:

- **boolean** by environment (dev / staging / prod),
- **percentage rollout** (1% → 5% → 25% → 100%),
- **tenant / user list** (allow-list specific tenants for canary
  cohorts),
- **rule-based** (region, plan, account age) — only when needed.

Forbidden:

- complex targeting trees nobody understands,
- targeting that depends on data the application does not have
  at evaluation time.

---

## Rollout discipline (release flags)

Standard ramp:

1. internal-only (employees, dogfood),
2. 1% of users,
3. 5% / 25% / 50%,
4. 100%,
5. clean up (remove the flag from code).

Each step:

- has a documented soak time,
- watches the SLI / error budget,
- has an automated rollback path (flip the flag off),
- has explicit go / no-go criteria.

Forbidden:

- flipping straight from 0% → 100% on a real release,
- "we'll just turn it on for everyone tonight,"
- skipping the soak time because the metric "looked fine."

---

## Kill switches

For risky paths (payment provider call, third-party integration,
expensive computation), maintain a kill switch:

- on by default,
- documented effect when off (return cached / fall back to
  alternative / fail closed with a clear error),
- tested at least once: actually flipped in staging, observed,
  flipped back.

A kill switch that has never been flipped is a hope.

---

## Experiments (A/B)

If used:

- defined hypothesis and metric BEFORE the experiment starts,
- sample size and duration calculated upfront,
- exposure logged once per user, not on every evaluation,
- results analyzed with statistical rigor (pre-registered
  metrics, multiple-comparison correction),
- experiments are NOT the path to production for risky changes —
  use a release flag for risk, an experiment flag for
  measurement.

Forbidden:

- "p < 0.05" on the first metric that looked good,
- experiments whose results never get analyzed,
- experiments running indefinitely.

---

## Cleanup discipline

Flags rot. Without active cleanup, every flag eventually becomes
permanent technical debt that conditions hidden behavior.

- release flags retired within their target removal date,
- post-rollout: flag removed from code, then from the flag
  service,
- experiment flags removed at experiment end,
- a quarterly review of flags older than N months,
- the **cleanup PR is part of the rollout**, not a separate
  ticket.

Forbidden:

- "we'll clean it up later," for years,
- removing the flag from the service while leaving the code
  branches in,
- dead code branches behind permanently-on flags.

---

## Anti-patterns to refuse

- **Flag spaghetti** — combinations of flags that nobody can
  enumerate. If you have N release flags overlapping in effect,
  only one of you understands the system.
- **Flag-as-config** — a "flag" that is really a configuration
  knob; promote to config.
- **Flag-as-permission** — a release flag that became a per-
  tenant permission silently; rename and re-type.
- **Default-yes flags with absence-as-on semantics** — a missing
  flag should not silently enable a feature.

---

## Observability

- per-flag evaluation rate (per value),
- per-flag rate of change in evaluation (sudden ramp),
- alerts on unexpected drift in flag evaluation,
- correlation of flag changes with SLO burn (the most common
  incident contributor is "we just changed a flag").

When something breaks, "what flag changed in the last hour?"
should be answerable in seconds.

---

## Verification

For any new flag, before merging:

- the off path works,
- the on path works,
- the toggle is observable,
- the default behavior on flag-service outage is the safe one,
- the cleanup is in someone's calendar / backlog.

---

## Forbidden

- flags without owners,
- flags without removal dates (for short-lived types),
- flags that gate destructive operations without a written
  on/off contract,
- flags evaluated in code paths nobody monitors,
- flags whose default depends on the order of evaluation,
- "test-only" flags that ship to production.

---

## When this skill says STOP

- a flag would gate a destructive operation without a tested
  off-path → fix before merging,
- a flag has been "almost ready to remove" for more than its
  target lifespan → schedule the cleanup, do not ship more
  features behind it.

A great flag system is an invisible one: features ship safely,
incidents are mitigated quickly, and code stays clean as flags
retire on schedule.
