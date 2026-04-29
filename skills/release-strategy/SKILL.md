---
name: release-strategy
description: Roll out a change safely — versioning, canaries, blue/green, feature flags, rollback. Decouple deploy from release; make releases boring.
---

# Release strategy

Use this skill **whenever a non-trivial change is being released**.

For a one-line typo to a non-user-facing service, follow the
normal CI / CD flow (skill `cicd-pipeline`). For anything that
affects users, follow this skill.

Authoritative source: `rules/RELEASE_RULES.md` and
`principles/OPERATIONAL_PRINCIPLES.md`.

---

## Premise

> Make releasing boring. Boring releases are safe releases.

The default of any non-trivial release is:

- **decoupled deploy from release** (skill `feature-flag`),
- **progressive rollout** (canary / blue-green / region /
  tenant),
- **fast rollback path** that any on-call can execute,
- **observability live** during the rollout.

If shipping requires courage, the system is not yet ready.

---

## Step 1 — Classify the change

| Kind                                | Strategy                                           |
| ----------------------------------- | -------------------------------------------------- |
| Internal refactor, no behavior      | Standard CI deploy                                 |
| New feature, low blast radius       | Flag + ramp                                        |
| New feature, high blast radius      | Flag + canary + soak per step                      |
| Schema change                       | Expand → migrate → contract (skill `database-migration`) |
| Public API change                   | New version, deprecation policy                    |
| Replacing a load-bearing component  | Strangler-fig + dual-run (skill `legacy-migration`) |
| Hotfix                              | Reduced ceremony, post-incident review             |

Pick the strategy at design time, not at deploy time. The strategy
shapes the implementation.

---

## Step 2 — Versioning

Every artifact has a version. Pick one strategy and use it
consistently:

- **SemVer** — libraries, public APIs.
- **CalVer** — products / services with continuous release.
- **Build SHA** — internal services where SemVer adds no signal.

Surface on every artifact (HTTP `/version`, CLI `--version`,
container label):

- semantic / cal version,
- commit SHA,
- build timestamp.

For public APIs, see skill `api-design` — versioning is part of
the contract.

---

## Step 3 — Decouple deploy from release

Default for any user-affecting change:

1. ship the code behind a feature flag (skill `feature-flag`),
2. flag default-off in production,
3. promote the artifact through environments,
4. release = flip the flag for a small cohort, observe, expand.

The deploy is uneventful. The release is the careful part.

---

## Step 4 — Pick the rollout pattern

### Canary

- 1% → 5% → 25% → 50% → 100% with soak time at each step,
- automated burn-rate alerts pause / roll back,
- one canary slice (region / cohort / instance) carries the new
  code,
- preferred default for back-end deploys.

### Blue / green

- new fleet stands up alongside the old,
- traffic switched fraction by fraction,
- old fleet stays warm for fast rollback,
- preferred when in-place upgrades are risky.

### Region-by-region

- one region at a time,
- preferred for multi-region services where simultaneous global
  rollout is too risky.

### Tenant-by-tenant

- one tenant cohort at a time,
- preferred for multi-tenant systems with diverse traffic
  shapes.

Required at every step:

- defined go / no-go criteria,
- soak time,
- rollback path tested before launch.

---

## Step 5 — Migration ordering

If the release includes a schema change:

1. migrate schema in **expand** mode (non-breaking),
2. deploy code that knows both shapes,
3. roll out the code progressively,
4. backfill / migrate data,
5. deploy code that uses only the new shape,
6. **contract** migrations after the soak period.

Skipping a step is the canonical "we deployed and the site went
down" cause.

See `rules/MIGRATION_RULES.md`.

---

## Step 6 — Rollback discipline

Every release has a defined rollback path:

- **one command** (script / pipeline button),
- **faster than fix-forward**,
- works without coordination ("any on-caller can do it"),
- tested in staging recently.

Forbidden:

- "rollback by remembering,"
- forward-fix on production while users are degraded because
  rollback "feels wrong,"
- rollback procedures that depend on a particular individual.

A failed release that rolled back smoothly is a good release.

---

## Step 7 — Observability for the rollout

Before flipping the first user:

- dashboards show the SLI before / during / after,
- alerts wired to burn-rate (skill `observability-setup`),
- per-cohort metrics (compare canary vs. baseline),
- correlation between flag flips and SLO burn is visible.

When the flag flips, the team can answer "did anything change?"
within minutes.

---

## Step 8 — Communicate

- **Internal** — incident / release channel: starts, advances,
  pauses, ends.
- **External (when user-affecting)** — release notes, status
  page (if maintenance window), customer comms (if requires
  user action).
- **On-call** — handoff brief for the next shift if the rollout
  spans rotations.

Silent releases cause silent outages.

---

## Step 9 — Public API: deprecation

Breaking API changes ship as a new version. Old version remains
available for an announced deprecation window:

- 6+ months for paid customers (typical),
- 3+ months for free,
- `Deprecation` and `Sunset` HTTP headers,
- changelog entry,
- explicit migration path,
- monitoring of usage on the old version,
- removal only after announced date and confirmed traffic
  decline.

See skill `api-design`.

---

## Step 10 — Hotfix path

Defined procedure for production-down emergencies:

- single, documented branch / pipeline path,
- reduced ceremony but **CI still runs**,
- review may be light but happens,
- post-incident review of every hotfix,
- the next normal release absorbs the hotfix.

Forbidden:

- "just SSH into the box,"
- hotfixes that bypass code review entirely,
- hotfixes that never make it back to `main`.

---

## Step 11 — Mobile / client release

Different shape than server release:

- store review delays — a bug ships for hours / days,
- old client versions persist for years,
- forward compatibility on the server side is mandatory,
- staged rollout via Play Console / TestFlight / App Store
  phased release,
- crash + error monitoring filtered by release,
- minimum-supported-version policy documented.

Forbidden:

- breaking server changes that assume all clients have updated,
- forced upgrades without a documented critical reason.

---

## Step 12 — Release notes

Every public release ships notes:

- new features (one line each, user-facing language),
- breaking changes (highlighted),
- bug fixes (linked to issues),
- security advisories where applicable,
- migration / upgrade instructions when needed,
- contributors.

For internal services, a simpler changelog tied to the deploy
record.

Forbidden:

- silent removal of public-facing behavior,
- "internal changes" as the entirety of release notes for a
  user-affecting release.

---

## Forbidden

- deploy = release with no canary, no flag, no rollback,
- "all instances at once" for production services,
- manual `kubectl apply` / `ssh` to the box for production,
- deploys that go directly from PR to 100% with no canary,
- forward-fixes when rollback is faster,
- release branches that diverge from `main`,
- force-push to release tags,
- versioning that drifts from what is deployed.

---

## When this skill says STOP

- there is no rollback path → fix it before launching,
- the rollout has no observability → add it first,
- the schema change is coupled to the code change in a single
  step → split into expand → migrate → contract.

Couple deploy to a progressive rollout; decouple visibility behind
flags; ensure rollback is the cheapest action available.

If shipping requires courage, the system is not ready to ship.
