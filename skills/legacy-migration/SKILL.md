---
name: legacy-migration
description: Replace or absorb a running legacy system using the strangler-fig pattern, anti-corruption layer, and slice-by-slice cutover.
---

# Legacy migration

Use this skill **whenever an existing running system is being
replaced, absorbed, re-platformed, or moved between
infrastructure / vendors / programming stacks**. This is *not*
the skill for schema migrations within a single DB — see skill
`database-migration` for that.

Authoritative source: `rules/MIGRATION_RULES.md`. Operational
stance: `principles/OPERATIONAL_PRINCIPLES.md`.

---

## Premise: never flag-day

The default migration pattern is the **strangler fig**: run the
new and old in parallel, route slices of traffic from old to new,
and retire the legacy when nothing routes to it.

Forbidden default:

- "we'll rebuild it and cut over one weekend,"
- "we'll keep both running but eventually pick one,"
- "the old system can stay because nobody touches it" (the
  on-call still does).

---

## Step 1 — Inventory the legacy

Before the first slice, document:

- every entry point (HTTP, queue, scheduled job, CLI, DB
  trigger, file drop, manual operator),
- every consumer (downstream service, BI, partner, exported
  report),
- every contract (HTTP, message schema, file format, DB shape),
- every business rule the legacy encodes (often un-documented;
  ask the people who run it),
- every known bug consumers depend on,
- the state of test coverage (often: low),
- the on-call risk profile.

The goal is a written map of "what the legacy does," accurate
enough that the new system can reach parity without surprises.

---

## Step 2 — Place the façade

Insert a façade in front of the legacy:

- HTTP: a reverse proxy / API gateway / load balancer.
- DB: a CDC stream / read-replica view / mediator service.
- Queue: a topic-renaming bridge.
- Filesystem: a watcher with router.

The façade owns the routing decision. From the consumer's
perspective, nothing changed.

The façade is the only place where "old vs. new" is decided.
Spreading that decision across consumers is forbidden.

---

## Step 3 — Build the anti-corruption layer (ACL)

The new system speaks its own (clean) domain language. The
legacy speaks its own (messy) one. The ACL translates:

- domain ↔ legacy concept names,
- domain types ↔ legacy types,
- domain rules ↔ legacy rules,
- domain identifiers ↔ legacy identifiers (with a mapping
  table).

Required:

- the ACL is the only place that knows the legacy model,
- new domain code never imports legacy types,
- the ACL is well-tested.

Forbidden:

- letting legacy field names "temporarily" leak into the new
  domain,
- "we'll rename it later."

The ACL is permanent until the legacy is retired.

---

## Step 4 — Pick the first slice

A slice is small, well-bounded, and high-information:

- a single endpoint, a single feature, a single tenant,
- ideally something high-traffic enough that parity / regression
  data accumulates fast,
- ideally something low-stakes enough that an early problem is
  recoverable.

Start with **read-only** slices when possible — they reveal the
parity gap without risking writes.

---

## Step 5 — Shadow / mirror traffic

Before cutting over, run the new path in shadow:

- the façade sends the request to *both* old and new,
- the response from old is returned to the user,
- the response from new is captured for comparison,
- a comparator flags differences,
- discrepancies are investigated until the new path is at
  parity.

Required:

- the comparator itself is tested (otherwise "no diffs" might
  mean a broken comparator),
- discrepancies are categorized (parity bug? legacy bug we
  inherited? acceptable?),
- a diff dashboard exists.

A shadow run with no diff signal is decoration; investigate the
comparator.

---

## Step 6 — Cutover the slice

Move the slice incrementally:

1. 1% of traffic to new.
2. Observe SLO burn, error rate, business KPI.
3. 5% → 25% → 50% → 100%.
4. Soak at each step (hours to days, depending on traffic).
5. Keep the old path warm for fast rollback.

Required:

- automated rollback on burn-rate alert,
- documented rollback procedure (one façade flag),
- observation window per step.

Forbidden:

- skipping ramps because "we tested it,"
- declaring cutover done before the soak period.

---

## Step 7 — Repeat

Take the next slice. Each cycle, the legacy shrinks. Each cycle,
the team's confidence grows. Each cycle, the runbook gets
sharper.

Track the migration as a backlog of slices. Estimate
completion as a percentage of legacy traffic / endpoints / data
moved.

---

## Step 8 — Decommission the legacy

Retire the legacy only when:

- no traffic routes to it (logs / metrics confirm zero hits over
  a soak window),
- no consumer references it,
- backups exist according to retention policy,
- a written sunset notice has been published,
- the legacy team / runbook / on-call is wound down.

Forbidden:

- removing legacy code "because nobody uses it" without
  observation evidence,
- decommissioning before the next quarter's reports / audits
  complete,
- silent removal of the legacy without a sunset notice for
  external consumers.

---

## Special cases

### Database-level migrations (system-of-record swap)

- Use change-data-capture (Debezium / Streaming Replication) to
  shadow the new store.
- Dual-write pattern with the new store as a follower until
  parity, then promote.
- See `rules/MIGRATION_RULES.md` for expand/migrate/contract.

### Monolith-to-services

- Each carved-out service starts as a façade slice.
- The "old monolith" is the legacy in this skill's vocabulary.
- Avoid carving services along technical lines (no
  "auth-service," "data-service" copy-paste); carve along
  business capabilities.

### Cloud / region migration

- The strangler shape applies: route a percentage of traffic to
  the new region with feature flags / DNS weighting,
- watch latency and errors,
- promote when stable.

---

## Forbidden

- "Just rebuild it and cut over."
- Removing legacy code paths before traffic actually drops to
  zero.
- Building the new system without parity tests against the
  legacy.
- Shadow runs without a diff comparator.
- "Migration complete" with the legacy still receiving traffic
  the team did not measure.
- Letting two writers diverge silently with no reconciliation
  loop.

---

## When this skill says STOP

- The inventory is incomplete → finish the inventory before
  building the façade.
- The legacy has un-discovered consumers → instrument first;
  you cannot migrate what you cannot see.
- A planned cutover lacks a rollback path → fix the rollback,
  delay the cutover.

Strangler-fig migrations succeed because they are boring. The
cutover is anticlimactic; that is the goal.

A successful legacy migration is one where the legacy quietly
goes dark, and nobody is awake at 3 AM that night.
