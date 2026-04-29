---
name: dependency-management
description: Add, pin, update, audit, and remove dependencies — keep the supply chain integrity, license compliance, and the build deterministic.
---

# Dependency management

Use this skill **whenever a dependency is being added, updated,
removed, or audited** — direct, transitive, third-party CI
actions, container base images, vendor SDKs.

Authoritative source: `rules/DEPENDENCY_RULES.md` and
`principles/SECURITY_PRINCIPLES.md`.

---

## Premise

A dependency is code you ship.

Pretend a malicious maintainer takes over a transitive package
tomorrow. The system runs the malicious code with your
privileges. The cheapest dependency is the one you do not have.

---

## Step 1 — Adding a dependency

Every new direct dependency is evaluated:

- **the problem it solves** — is it concrete enough to justify?
- **the cost of writing the equivalent ourselves** — is it
  smaller than the maintenance burden of the dependency?
- **maintenance status** — last release, recent maintainers,
  open security issues, abandoned forks?
- **license** — compatible with the project license?
- **transitive footprint** — how many other dependencies pull
  in?
- **popularity vs. drive-by-fork risk** — single-maintainer
  packages with very few downloads are riskier,
- **runtime cost** — binary / install size, cold-start, memory.

Add **not** because:

- "10k stars,"
- "I used it at my previous job,"
- "we might need it eventually."

If a dependency is added for a single function, prefer copying
the function (with attribution and license) over taking the
package.

---

## Step 2 — Lockfiles

Every project has a lockfile in source control:

- `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock`,
- `Cargo.lock`,
- `go.sum`,
- `poetry.lock` / `uv.lock` / `requirements.txt` (with hashes),
- `Gemfile.lock`,
- `composer.lock`.

Lockfiles are reviewed in PRs. Floating versions in production
lockfiles are forbidden.

---

## Step 3 — Pinning

- direct dependencies pinned to exact versions or constrained
  with a documented range,
- transitive dependencies pinned via the lockfile,
- container base images pinned by digest (`@sha256:…`),
- third-party CI actions / orbs pinned by SHA, not floating tag,
- toolchain versions pinned (`.tool-versions`, `mise`, `asdf`,
  `.nvmrc`, `rust-toolchain.toml`).

Forbidden:

- `^`, `~`, `latest`, `main` in production-bound declarations,
- Dockerfiles using `:latest`,
- "we'll pin it eventually."

Pinning is the floor of reproducibility. Without pinning, every
build is a different build.

---

## Step 4 — Updating dependencies

Updates are routine, automated, and reviewed:

- a tool (Renovate / Dependabot / Mend) opens PRs for updates,
- updates land continuously, not "once per quarter,"
- updates are batched sensibly (patch / minor) and per-major
  separately,
- security updates are prioritized and triaged on detection.

Forbidden:

- letting dependencies rot for 12+ months,
- mass-merging update PRs without testing,
- "the version we are on works, do not update."

A code base that has stopped receiving updates also stopped
receiving fixes.

---

## Step 5 — Vulnerability response

CI scans for known vulnerabilities (SCA):

- `npm audit` / `pnpm audit`,
- `cargo audit`,
- `pip-audit`,
- `bundle audit`,
- `govulncheck`,
- platform-native scanners (Snyk, GitHub Dependabot, Mend).

Required:

- **critical and high** severity findings block merge,
- a tracked process to triage, mitigate, or accept (with
  written justification),
- alerts on new advisories affecting deployed versions,
- supply-chain advisories (e.g. malicious package takeover) get
  the same treatment as code vulnerabilities.

A known-vulnerable dependency in production is an open ticket
with a clock.

---

## Step 6 — License compliance

- approved license list documented (e.g. MIT, BSD, Apache 2.0,
  ISC, MPL 2.0),
- restricted licenses (GPL, AGPL, custom) reviewed before use,
- license checks run in CI,
- license file shipped with the artifact where required.

Forbidden:

- depending on a project with no license,
- copyleft contamination of proprietary code,
- silent license category change (a dep that was MIT becomes
  GPL on a major version).

---

## Step 7 — Supply chain integrity

- verify provenance where supported (sigstore / cosign / signed
  releases),
- generate and retain SBOM per artifact,
- reproducible / hermetic builds where the toolchain supports
  them,
- forbid post-install scripts from untrusted dependencies where
  the language allows (`npm --ignore-scripts`),
- vendor mirrors / caches insulate from upstream outages and
  malicious takeovers.

A dependency manager that fetches arbitrary code from the
internet at build time is a supply-chain risk to manage, not a
feature to use casually.

---

## Step 8 — Internal (first-party) dependencies

For shared libraries inside the organization:

- versioned and released the same way as third-party
  dependencies,
- breaking changes follow the same SemVer rules,
- no "head-of-main" cross-repo dependencies in production
  branches,
- shared libraries have an owner, a changelog, a deprecation
  policy.

A first-party dependency without an owner is just shared bugs.

---

## Step 9 — Forks

If a fork is necessary:

- the reason is documented in an ADR (skill `adr`),
- the upstream relationship is explicit (PR open / abandoned /
  philosophical disagreement),
- the maintenance burden is owned by the team,
- the plan for de-forking (or replacement) is recorded,
- a tracking schedule reviews fork drift.

A fork that no one is responsible for is a future security
incident.

---

## Step 10 — Removing dependencies

A dependency that is no longer used is removed in the same PR
that stops using it. Dead dependencies cost:

- transitive surface area,
- security alerts,
- build time,
- audit overhead.

Forbidden:

- leaving "in case we need it again" — the lockfile is the
  graveyard,
- removing imports without removing the dependency,
- removing the dependency without verifying nothing else
  imports it.

Periodically (quarterly or per release) audit the dependency
tree and prune.

---

## Step 11 — Replacement discipline

When considering replacing a dependency:

- understand why the existing one was chosen,
- identify the actual deficiency (security? maintenance? cost?
  taste?),
- evaluate replacements with the same rigor as adding,
- migrate behind a feature flag / parallel implementation when
  the swap is non-trivial,
- write an ADR for non-trivial replacements.

Forbidden:

- replacing "because the new one is trendier,"
- big-bang swap of a load-bearing dependency.

---

## Step 12 — Vendor / third-party services

The same rules apply to *services* the system depends on:

- vendor lock-in is a real risk; mitigate where SLA / cost
  warrants,
- contracts and pricing are part of the dependency,
- vendor incident history affects the SLO of every feature
  using them,
- migration path off the vendor is at least sketched in an ADR
  before signing.

A vendor outage on the user path is your outage.

---

## Step 13 — Verify

Periodically (e.g. quarterly):

- run a fresh SCA scan; close or accept findings,
- run a license audit,
- review dependencies older than N months for upgrade
  opportunities,
- review the dependency tree for unused / suspicious entries,
- confirm SBOM generation is producing usable output.

---

## Forbidden

- "It pins itself" — relying on solver-derived versions in
  production,
- multiple lockfiles drifting in a monorepo,
- public registries used as the build runtime ("if the registry
  is down, the build fails"),
- `npm install` at deploy time,
- "latest" as a versioning strategy,
- forks without an upstream-tracking note,
- manual `wget` / `curl | sh` in CI without checksum verification.

---

## When this skill says STOP

- a new dep cannot be justified beyond convenience → write the
  function instead,
- a CVE is open against a deployed version → triage now, not
  later,
- the lockfile diverges between branches in a monorepo → fix
  before merging.

A code base that controls its dependencies controls its
destiny; one that does not, does not.

The cheapest dependency is the one you do not have.
