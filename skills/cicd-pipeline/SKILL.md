---
name: cicd-pipeline
description: Design or extend a CI/CD pipeline — fast feedback, deterministic builds, supply-chain integrity, progressive deploy, fast rollback.
---

# CI / CD pipeline

Use this skill **whenever a pipeline is built, extended, or
hardened** — for a new project, a new service, or a structural
change to an existing pipeline.

Authoritative source: `rules/CICD_RULES.md` and
`principles/OPERATIONAL_PRINCIPLES.md`.

---

## Step 1 — Decide the shape

Pipelines have two halves:

- **CI** (continuous integration) — every change verified before
  merge.
- **CD** (continuous delivery / deployment) — every passing main
  promoted toward production with appropriate gates.

For each stage, decide:

- the trigger (PR, push, schedule, manual),
- the runner (self-hosted, cloud, ephemeral),
- the inputs (commit, dependency cache, secrets),
- the outputs (artifacts, reports),
- the failure semantics.

Pipelines live in source control as code. Click-ops in CI / CD
UI is forbidden.

---

## Step 2 — Required CI gates

On every PR, required (in roughly this order):

1. format / lint (fast, deterministic),
2. type check,
3. build (produce the artifact),
4. unit tests,
5. integration / contract tests,
6. static analysis (SAST),
7. dependency vulnerability scan (SCA),
8. secret scan,
9. license / SBOM check,
10. schema / migration check (clean DB).

Fast lane (lint + unit) returns within 5 minutes; full pipeline
within 15 minutes. Slower pipelines compound into engineer pain
that the team will route around.

Forbidden:

- "allow failure" indefinitely on a job that exists,
- merging a PR with red required checks,
- skipping CI for "urgent" fixes.

---

## Step 3 — Determinism

Reproducible builds mean:

- pinned runner OS / image,
- pinned language toolchain (`mise`, `asdf`, `.tool-versions`,
  container image),
- pinned dependencies (lockfile in source),
- pinned third-party CI actions / orbs by SHA, not floating tag,
- pinned base images by digest (`@sha256:…`),
- restored caches deterministically,
- no network calls from tests (except documented integration
  tests).

Same commit, same green build, six months later. If not, the
pipeline is broken.

---

## Step 4 — Speed

Slow CI is a bug. Mitigate:

- cache dependencies, build outputs, test artifacts,
- parallelize jobs (lint || type-check || tests),
- shard tests by historical timing,
- run integration tests with ephemeral DBs / containers in
  parallel,
- prefer incremental over full rebuilds where the build system
  supports it,
- separate "fast path" (every PR) from "thorough path" (nightly,
  pre-release).

Test parallelism requires test isolation — do not skip the
isolation work for the parallel-speed gain.

---

## Step 5 — Build once, deploy many

The artifact deployed to production is the artifact built in CI:

- one build per commit, tagged by SHA,
- artifacts immutable after publication,
- environment differences are configuration, not different
  builds,
- artifacts promoted across stages (no rebuild at deploy time).

Forbidden:

- environment-specific Dockerfiles,
- "if env == prod" code paths,
- staging built from a different commit than production.

---

## Step 6 — Supply-chain integrity

- pin third-party CI actions / images by SHA,
- generate SBOM per artifact,
- generate provenance (SLSA / cosign / sigstore) where supported,
- verify provenance at deploy time where supported,
- forbid post-install scripts from untrusted dependencies where
  the language permits,
- vendor / proxy dependency mirrors so upstream outages do not
  break CI.

A compromised CI is a compromised production. Limit blast
radius.

---

## Step 7 — Secrets in CI

- prefer **OIDC federation** to cloud IAM over long-lived static
  keys,
- scope secrets per workflow / per environment,
- mask in logs,
- rotate on schedule and on suspicion,
- never echo secrets in logs / stack traces.

See `rules/SECRETS_RULES.md`.

---

## Step 8 — Deployment strategy

Default: progressive rollout, never instant 100%.

- **Canary** — 1% → 5% → 25% → 100%, with gates per step.
- **Blue / green** — bring up new fleet, switch traffic
  fraction, keep old warm for fast rollback.
- **Region-by-region** — for multi-region services.
- **Tenant-by-tenant** — for multi-tenant systems.

Required:

- automated burn-rate alerts that pause / roll back,
- rollback faster than fix-forward,
- documented soak time per step.

Forbidden:

- "all instances at once," manual deploys, `kubectl apply` from
  laptops to prod.

See skill `release-strategy`.

---

## Step 9 — Database in the pipeline

- migrations run in CI on a clean DB,
- schema drift detection in CI,
- production migrations decoupled from code deploy
  (expand → migrate → contract; see skill `database-migration`),
- migrations applied by automation, not humans on a console.

A pipeline that conflates code deploy with destructive schema
change is a pipeline that takes the site down.

---

## Step 10 — Branching strategy

Default: trunk-based with short-lived branches.

- `main` is always deployable,
- PRs small (under ~400 lines target),
- merges squash or rebase (clean history),
- direct push to `main` forbidden,
- force-push to `main` forbidden.

Long-lived branches usually hide a problem the pipeline cannot
solve.

---

## Step 11 — Required reviews / checks

- ≥1 human reviewer (not the author),
- code-owners required for sensitive areas (auth, payments,
  schema, infra),
- branch up to date with `main` (auto-rebased OK),
- self-merge of one's own PR forbidden in production
  repositories.

---

## Step 12 — Observability for the pipeline itself

Track:

- pipeline success rate,
- time-to-feedback per stage,
- flakiness rate (per-test, per-job),
- queue time (how long jobs wait for runners),
- cost per pipeline run.

A pipeline that nobody monitors degrades silently.

---

## Step 13 — Incident-mode posture

When the system is on fire:

- a documented "fast path" exists (skipping non-essential gates),
  used sparingly and always reviewed in the postmortem,
- rollback is faster than fix-forward,
- incident commits get a follow-up issue automatically,
- there is a defined freeze policy (e.g. no deploys during
  high-revenue events without written approval).

A pipeline that gets in the way during incidents will be
circumvented during incidents. Design the fast path so it is the
official one.

---

## Forbidden

- jobs marked "allow failure" indefinitely,
- pipelines configured by hand in the CI tool's UI,
- secrets in source control,
- `:latest` tags on production-bound images,
- floating action references (`@v3`),
- `terraform apply` from a laptop against production,
- "merge first, fix CI later,"
- pipelines that depend on a particular individual.

---

## When this skill says STOP

- A required gate has no clear owner → assign one before
  shipping,
- the pipeline duration exceeds 30 minutes for the fast path →
  fix before adding more,
- rollback has not been tested → test before launching the
  pipeline.

The pipeline is the engineering culture made executable. Make it
fast, deterministic, secure, and observable. Treat its failures
as production failures.

If shipping safely requires courage, the pipeline is broken.
