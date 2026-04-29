# Release Rules

A release is the moment users meet the change. These rules govern
how releases are versioned, gated, rolled out, and rolled back.

For pipeline mechanics, see `rules/CICD_RULES.md`. For
operational stance, see `principles/OPERATIONAL_PRINCIPLES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Decouple Deploy From Release

**Deploy** is putting code on servers. **Release** is making
behavior visible to users. Treat them as separate events.

Required mechanisms:

- feature flags decide who sees what,
- code lands behind a flag, then rolls out gradually,
- a flag kill-switch reverts visibility without redeploy.

Forbidden:

- features that go from PR straight to 100% of users,
- "release" as the moment a deploy lands,
- branch-deferred features held off `main` for weeks.

See skill `feature-flag`.

---

# Versioning

Every artifact has a version. Pick one strategy and use it
consistently:

- **Semantic Versioning (SemVer)** — `MAJOR.MINOR.PATCH` for
  libraries and public APIs.
- **CalVer** — `YYYY.MM.PATCH` for products and services with
  continuous release.
- **Build SHA** — for internal services where SemVer adds
  no signal.

Required on every artifact (HTTP `/version`, CLI `--version`,
container label):

- semantic / cal version,
- commit SHA,
- build timestamp.

Forbidden:

- silent breaking changes within a major version,
- version numbers that lie ("v1.2.3" but actually bumps API
  contract).

---

# Public API Compatibility

For any externally-consumed contract:

- additions are non-breaking (new optional field, new endpoint),
- removals / type changes / required-field additions are
  breaking,
- breaking changes ship a new major / version namespace; the old
  one remains available for an announced deprecation window.

See `rules/API_DESIGN_RULES.md`.

Internal services have lighter ceremony but the same principles.
Two callers means a contract.

---

# Rollout Strategy

Default: progressive rollout, never instant 100%.

- **Canary** — 1% → 5% → 25% → 100%, with soak time at each
  step and SLO burn-rate gates.
- **Blue / green** — bring up the new fleet, switch traffic
  fraction, keep the old fleet warm for fast rollback.
- **Region-by-region** — for multi-region services, one region
  at a time.
- **Tenant-by-tenant** — for multi-tenant systems, ramp by
  tenant cohort.

Required:

- automated burn-rate alerts that pause / roll back the rollout,
- pre-defined go / no-go criteria,
- documented soak time per step,
- rollback faster than fix-forward.

Forbidden:

- "all instances at once" for production services,
- a rollout that has no defined gates,
- declaring a rollout "complete" before observation windows are
  exhausted.

---

# Migrations and Rollouts Together

Schema migrations are decoupled from code rollout (see
`rules/MIGRATION_RULES.md` — expand → migrate → contract). A
release that requires "deploy code and run migration at the same
time" is not safe.

Order:

1. Migrate schema in expand mode (non-breaking).
2. Deploy code that knows both shapes.
3. Roll out the code progressively.
4. Backfill / migrate data.
5. Deploy code that uses only the new shape.
6. Contract migrations after the soak period.

Skipping a step is the canonical "we deployed and the site went
down" cause.

---

# Rollback Discipline

Every release has a defined rollback path:

- one command (script / pipeline button), faster than a
  forward-fix,
- works without coordination ("any on-caller can do it"),
- has been tested in staging recently,
- is preferred over forward-fix when latency matters more than
  pride.

Forbidden:

- "rollback by remembering,"
- forward-fixing on production while users are degraded because
  rollback "feels wrong,"
- rollback procedures that depend on a particular individual.

A failed release that rolled back smoothly is a good release.

---

# Release Notes

Every public release ships notes:

- new features (one line each, user-facing language),
- breaking changes (highlighted),
- bug fixes (linked to issues / tickets),
- security advisories where applicable,
- migration / upgrade instructions when needed,
- contributors / acknowledgements where appropriate.

Internal services keep a simpler changelog tied to the deploy
record.

Forbidden:

- "internal changes" as the entirety of release notes for a
  user-affecting release,
- silent removal of public-facing behavior.

---

# Deprecation

Public deprecations follow a documented playbook:

1. Announce — release notes, public docs, `Deprecation`
   header on HTTP responses, log warnings on usage.
2. Provide a migration path with examples.
3. Set a removal date with reasonable lead time (typically 6+
   months for paid customers, 3+ for free).
4. Remove only after the announced date and confirmed traffic
   approaches zero.

Forbidden:

- removing without announcement,
- "we will keep it forever" — every public surface deprecated
  someday.

---

# Release Cadence

Pick a cadence and stick to it:

- **Continuous** — every passing main → production. Default for
  internal services.
- **Train** — fixed cadence (e.g. weekly) regardless of merges.
- **Milestone** — feature-driven, suitable for SDKs / libraries.

Cadence is a property of the team's discipline, not of the
calendar. A team that releases weekly under stress will release
weekly when calm.

---

# Hotfix Process

Defined procedure for production-down emergencies:

- a single, documented branch / pipeline path,
- reduced ceremony but not zero (CI still runs),
- post-incident review of every hotfix,
- the next normal release absorbs the hotfix.

Forbidden:

- "just SSH into the box,"
- hotfixes that bypass code review,
- hotfixes whose changes never make it back to `main`.

---

# Mobile / Client-Side Release

Mobile app releases differ from server releases:

- store review delays mean a bug ships for hours / days before
  fix can land,
- old client versions persist for years,
- forced upgrades are user-hostile and should be rare.

Required:

- forward compatibility (clients tolerate new server fields,
  new optional values),
- minimum supported version policy,
- staged rollout (Play Console / TestFlight / App Store
  phased release),
- crash and error monitoring with release filtering.

Forbidden:

- breaking server changes that assume all clients have updated,
- forced upgrades without a documented critical reason.

---

# Library and SDK Release

For published libraries:

- SemVer strictly,
- public API is the contract; internal symbols are clearly
  marked,
- release artifacts signed,
- changelog updated atomically with the release,
- yanking a release follows the platform's process and a
  notice is posted.

---

# Forbidden Anti-patterns

- "We deploy on Fridays."
- Manual deployment steps recorded only in chat.
- Release branches that diverge from `main`.
- Force-push to release tags.
- Rolling out a feature with no kill-switch.
- Versioning that drifts from what is actually deployed.
- Deploy = release with no canary, no flag, no rollback.

---

# Prime Directive

Make releasing boring. Boring releases are safe releases. Couple
the deploy to a progressive rollout, decouple visibility behind
flags, and ensure rollback is the cheapest action available.

If shipping requires courage, the system is not ready to ship.
