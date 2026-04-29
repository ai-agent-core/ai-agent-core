# CI / CD Rules

The pipeline is the contract between writing code and shipping it.
A weak pipeline corrupts every other engineering practice. These
rules define the minimum quality bar for continuous integration
and deployment.

For the operational principles behind these rules, see
`principles/OPERATIONAL_PRINCIPLES.md`. For release strategy, see
`rules/RELEASE_RULES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# CI Is the Quality Gate

Every change MUST pass CI before merge. CI is not a hint; it is
the gate.

Required CI stages on every PR:

1. **Format / lint** — fast, deterministic.
2. **Type check** — for typed languages.
3. **Build** — produce the deployable artifact.
4. **Unit tests** — fast, isolated.
5. **Integration / contract tests** — real dependencies, real
   schema, scoped scope.
6. **Static analysis / SCA / SAST** — security and quality
   scans.
7. **Dependency vulnerability check** — known CVEs.
8. **Schema / migration check** — schema matches migrations on
   a clean DB.

PRs that fail any of these MUST NOT be merged. Skipping CI
("urgent fix") is forbidden — the urgent fix needs the gate
more, not less.

---

# Pipelines Are Code

CI / CD configuration lives in source control:

- `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`,
  `buildspec.yml`, etc.
- Reviewed in PRs.
- Versioned with the code it builds.

Forbidden:

- pipelines configured by hand in the CI tool's UI,
- click-ops in deployment platforms.

If a job change cannot be reviewed in a PR, it is invisible.

---

# Determinism Is Required

CI runs MUST be reproducible:

- pin runner OS / image,
- pin language toolchain version (`.tool-versions`, `mise`,
  `asdf`, container image),
- pin all dependencies (lockfile in source),
- pin third-party CI actions / orbs / templates by SHA, not by
  floating tag,
- restore the same dependency cache deterministically,
- forbid network calls in tests (except documented integration
  tests).

A green CI today should mean the same as a green CI six months
later from the same commit.

---

# Speed Targets

Default targets:

- PR feedback (lint + unit) within **5 minutes**,
- full PR pipeline within **15 minutes**,
- main → production deploy within **30 minutes** of a clean
  build (gates excepted).

Slow CI is not a fact of life; it is a bug. Cache, parallelize,
shard tests by timing, and split jobs across runners.

Tests that are too slow to run on every PR are too slow to be
useful — split into a regular fast run and a nightly thorough
run.

---

# Test Discipline in CI

- Tests run with a fresh, ephemeral DB / cache / queue (no
  shared state across runs).
- Flaky tests are quarantined immediately and fixed within a
  short window or deleted. A flaky test in `main` corrupts every
  signal.
- Test order is randomized; tests do not depend on each other.
- Coverage is reported but never the only quality signal —
  coverage targets are floors, not ceilings.

Forbidden:

- a known-flaky test marked "flaky" indefinitely,
- tests skipped in CI ("only locally") without ticketed
  follow-up,
- shared resources (a single DB, a single S3 bucket) used by
  parallel runs.

---

# Branching and Merge Discipline

Default: trunk-based development with short-lived branches
(< 2 days alive).

- `main` is always deployable.
- PRs are small (under ~400 lines diff is a good target;
  larger requires justification).
- Force-push to `main` is forbidden.
- Direct push to `main` is forbidden — PRs only, with review.
- Merges are squash-merge or rebase-merge with a clean commit
  history; no merge-commit clutter unless the team has decided
  otherwise.

Long-lived branches are a smell that often hides a deeper design
problem (too-large change, missing flag, unclear scope).

---

# Required Reviews and Checks

- At least one human reviewer (not the author).
- All required checks green.
- Branch up to date with `main` (or auto-rebased).
- Code-owners (for sensitive areas — auth, payments, infra,
  schema) included in review.
- For changes touching multiple owners, include all of them.

Self-merge of one's own PR is forbidden in production
repositories.

---

# Artifacts Are Built Once

The artifact deployed to production was built in CI from a
specific commit. The same artifact promotes through environments.

Required:

- one build per commit,
- artifact tagged by commit SHA,
- artifacts immutable after publication,
- environment differences are configuration, not different
  builds.

Forbidden:

- rebuilding the artifact at deploy time,
- promoting to staging the artifact built at "main" but to
  production a different one,
- environment-specific code paths gated by `if env == "prod"`.

The principle: **build once, deploy many.**

---

# Supply Chain Security

- All third-party CI actions / images pinned by SHA (not `@v3`).
- Container base images pinned by digest, scanned for CVEs,
  refreshed on a schedule.
- Build provenance generated (SLSA / cosign / sigstore) and
  verified at deploy time where supported.
- SBOM generated per artifact.
- Secrets used by CI are short-lived, scoped per workflow,
  preferably OIDC-federated to cloud roles rather than
  long-lived keys.

A compromised CI is a compromised production. Pretend it will
happen, and limit blast radius.

---

# Secrets in CI

- No secret in source control.
- No secret echoed in logs (mask, scrub).
- Use OIDC federation to cloud providers wherever supported —
  no long-lived keys.
- Per-workflow / per-environment scoping — a CI job for a docs
  build does not need production database credentials.
- Secrets rotate on schedule and on suspicion.

See `rules/SECRETS_RULES.md`.

---

# Deployment Strategy

Default: progressive rollout, never instant 100%:

- **Canary** — deploy to a small slice (1% / one zone), watch
  for SLO burn, expand gradually.
- **Blue / green** — bring up the new fleet, switch traffic,
  keep the old fleet warm for fast rollback.
- **Feature flags** — decouple release (deploy code) from
  rollout (turn on for users).

Required:

- automated rollback on burn-rate alert,
- documented rollback procedure (one command, faster than a
  forward-fix),
- pre-deploy and post-deploy verification (smoke tests, key
  metrics),
- soak time per stage before next stage.

Forbidden:

- manual `kubectl apply` / `ssh` to the box for production
  changes,
- "all instances at once" deploys for production services,
- deploys that go directly from PR to 100% with no canary,
- forward-fixes when rollback is faster.

---

# Environments

Minimum environments:

- **dev** — shared or per-developer; high-velocity.
- **staging / pre-prod** — production-like data shape, prod-like
  config, prod-like scale on critical paths.
- **prod** — what users hit.

Required:

- staging catches regressions before prod (otherwise it is
  decoration),
- production data does not leak to lower environments
  (anonymize or synthesize).

Forbidden:

- developers running queries against production for testing,
- staging data treated as ground truth.

---

# Database in CI / CD

- CI runs migrations from a clean DB on every build.
- Migration drift detected (live schema diff against migration
  set).
- Production migrations are decoupled from code deploy
  (expand-contract; see `rules/MIGRATION_RULES.md`).
- Migrations applied by automation, not by humans on a console.
- Rollback path documented per migration.

Forbidden:

- ORM auto-migration in production-bound branches,
- editing migrations after merge.

---

# Build Reproducibility and Hermeticity

Where reasonably possible:

- builds run hermetically (no internet at build time, only the
  dependency cache),
- the same input commit produces the same output bytes,
- vendor or proxy dependency mirrors so an upstream outage does
  not break CI.

Hermetic builds are the strongest defense against transient
upstream incidents and the only sound base for reproducible
artifacts.

---

# Quality Gates Beyond Tests

CI MUST also enforce:

- **Code style / format** (auto-fixed where safe; failure on
  drift),
- **License compliance** (no copyleft contamination of
  proprietary code, etc.),
- **Generated code drift** (regenerate and diff on every PR),
- **Documentation drift** (OpenAPI spec matches the
  implementation),
- **Bundle size** (frontend),
- **Schema breaking-change detection** (GraphQL, protobuf,
  OpenAPI).

The gate that does not exist is the gate that gets bypassed.

---

# Incident-Time CI / CD

When the system is on fire:

- a documented "fast path" exists (skipping non-essential gates)
  but every use is reviewed in the postmortem,
- rollback is faster than fix-forward,
- changes during an incident are merged with reduced ceremony
  *and* a follow-up to revisit them once stable,
- CI / CD itself has a defined posture during outages (do not
  freeze randomly; have a freeze policy).

A pipeline that gets in the way during incidents is a pipeline
that will be circumvented during incidents.

---

# Forbidden Anti-patterns

- "merge first, fix CI later,"
- jobs marked "allow failure" indefinitely,
- production deploys that depend on a particular individual,
- pipelines that nobody owns,
- environment-specific Dockerfiles or build flags,
- secrets fetched at deploy time from a tool nobody can audit,
- `:latest` tags on production-bound images,
- `terraform apply` / equivalent run from a developer laptop
  against production.

---

# Prime Directive

The pipeline is the engineering culture made executable. Make it
fast, deterministic, secure, and observable. Treat its failures
as production failures.

If shipping safely requires courage, the pipeline is broken.
