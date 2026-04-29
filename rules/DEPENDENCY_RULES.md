# Dependency Rules

A dependency is code you ship. These rules govern how dependencies
are chosen, pinned, audited, and replaced.

For the security stance, see `principles/SECURITY_PRINCIPLES.md`
(supply chain).

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Adding a Dependency Is a Decision

Every new dependency MUST be evaluated:

- the problem it solves,
- the cost of writing the equivalent ourselves,
- the maintenance status (active, archived, last release date,
  open security issues, recent maintainers),
- license compatibility,
- transitive footprint,
- popularity vs. drive-by-fork risk,
- runtime cost (binary size, install size, cold-start, memory).

A dependency is **not** added because:

- "it has 10k stars,"
- "I used it at my previous job,"
- "we might need it eventually."

If a dependency is added for a single function, prefer copying
the function (with attribution and license) over taking the whole
package.

---

# Lockfiles in Source

Every project MUST have a lockfile in source control:

- `pnpm-lock.yaml` (preferred for JS / TS — see below),
- `package-lock.json` / `yarn.lock` (only when pnpm cannot be used),
- `Cargo.lock`,
- `go.sum`,
- `poetry.lock` / `uv.lock` / `requirements.txt` (with hashes),
- `Gemfile.lock`,
- `composer.lock`.

Lockfiles are reviewed in PRs. Floating versions in production
lockfiles are forbidden.

## Default JS / TS package manager

For JavaScript and TypeScript projects, the default package manager
is **pnpm**:

- fastest install,
- strict node_modules layout (catches phantom dependencies),
- first-class workspaces / monorepo support,
- lockfile (`pnpm-lock.yaml`) is the source of truth.

Pin the pnpm version via `packageManager` in `package.json`
(Corepack-friendly). CI installs with `pnpm install --frozen-lockfile`.

Choosing `npm` or `yarn` instead is a deliberate, written decision
(skill `adr`) — typically driven by an external constraint, not by
preference.

---

# Pinning Strategy

- Direct dependencies pinned to exact versions or constrained
  with a documented range.
- Transitive dependencies pinned via the lockfile.
- Container base images pinned by digest (`@sha256:...`),
  refreshed on a schedule.
- CI actions / orbs / templates pinned by SHA, not by floating
  tag (`@v3` is not pinning).
- Toolchain versions pinned (`.tool-versions`, `mise`, `asdf`,
  `.nvmrc`, `rust-toolchain.toml`).

Forbidden:

- `^`, `~`, `latest`, `main` in production-bound declarations,
- Dockerfiles using `:latest`,
- "we'll pin it eventually."

Pinning is the floor of reproducibility. Without pinning, every
build is a different build.

---

# Updating Dependencies

Updates are routine, automated, and reviewed:

- a tool (Renovate, Dependabot, Mend) opens PRs for updates,
- updates land continuously, not "once per quarter,"
- updates are batched sensibly (patch / minor) and per-major
  separately,
- security updates are prioritized and triaged on detection,
  not on convenience.

Forbidden:

- letting dependencies rot for 12+ months,
- "the version we are on works, do not update,"
- mass-merging update PRs without testing.

A code base that has stopped receiving updates is also stopped
receiving fixes.

---

# Vulnerability Response

CI scans for known vulnerabilities (SCA):

- `npm audit`, `pnpm audit`,
- `cargo audit`,
- `pip-audit`,
- `bundle audit`,
- `govulncheck`,
- platform-native scanners (Snyk, GitHub Dependabot, JFrog Xray).

Required:

- critical and high severity findings block merge,
- a tracked process to triage, mitigate, or accept (with written
  justification),
- alerts on new advisories affecting deployed versions,
- supply-chain advisories (e.g. malicious package takeover) get
  the same treatment as code vulnerabilities.

Forbidden:

- ignoring scanner output by default,
- "the scanner is noisy" as a permanent justification.

A known-vulnerable dependency in production is an open ticket
with a clock.

---

# License Compliance

Every dependency's license is known and acceptable:

- approved license list documented (e.g. MIT, BSD, Apache 2.0,
  ISC, MPL 2.0),
- restricted licenses (GPL, AGPL, custom) reviewed before use,
- license checks run in CI,
- license file shipped with the artifact where required.

Forbidden:

- depending on a project with no license,
- copyleft contamination of proprietary code,
- silently switching license category (a dep that was MIT
  becomes GPL on a major version).

---

# Supply Chain Integrity

- Verify provenance where supported (sigstore / cosign / signed
  artifacts).
- Generate and retain SBOM (Software Bill of Materials) per
  artifact.
- Reproducible / hermetic builds where the toolchain supports
  them.
- Forbid post-install scripts from untrusted dependencies where
  the language allows (`npm --ignore-scripts`, etc.).
- Vendor mirrors / caches insulate from upstream outages and
  malicious takeovers.

A dependency manager that fetches arbitrary code from the
internet at build time is a supply-chain risk to manage, not a
feature to use casually.

---

# Internal Dependencies

For first-party libraries inside the organization:

- versioned and released the same way as third-party
  dependencies,
- breaking changes follow the same SemVer rules,
- no "head-of-main" cross-repo dependencies in production
  branches,
- shared libraries have an owner, a changelog, and a deprecation
  policy.

A first-party dependency without an owner is just shared code,
which is just shared bugs.

---

# Forks

If a fork is necessary:

- the reason is documented,
- the upstream relationship is explicit (PR open / abandoned /
  philosophical),
- the maintenance burden is owned by the team,
- the plan for de-forking (or replacement) is recorded.

A fork that no one is responsible for is a future security
incident.

---

# Removing Dependencies

A dependency that is no longer used is removed in the same PR
that stops using it. Dead dependencies cost:

- transitive surface area,
- security alerts,
- build time.

Forbidden:

- leaving "in case we need it again" — the lockfile is the
  graveyard.

Periodically (quarterly or per release) audit the dependency tree
and prune.

---

# Replacement Discipline

When considering replacing a dependency:

- understand why the existing one was chosen,
- identify the actual deficiency (security? maintenance? cost?
  taste?),
- evaluate replacements with the same rigor as adding a new
  dependency,
- migrate behind a feature flag / parallel implementation when
  the swap is non-trivial,
- write an ADR (skill `adr`) for non-trivial replacements.

Forbidden:

- replacing "because the new one is trendier,"
- big-bang swap of a load-bearing dependency.

---

# Vendor / Third-Party Service Dependencies

The same rules apply to *services* the system depends on:

- vendor lock-in is a real risk; mitigate where the cost / SLA
  warrants it,
- contracts and pricing are part of the dependency,
- the vendor's incident history affects the SLO of every
  feature using them,
- the migration path off the vendor is at least sketched in an
  ADR before signing.

A vendor outage on the user path is your outage. Treat the
choice with that gravity.

---

# Forbidden Anti-patterns

- "It pins itself" — relying on solver-derived versions in
  production.
- Multiple lockfiles drifting against each other in a monorepo.
- Public registries used as the build runtime ("if the registry
  is down, the build fails").
- `npm install` at deploy time.
- "Latest" as a versioning strategy.
- Forks in source-control with no upstream-tracking note.
- Manual `wget` / `curl | sh` of binaries in CI without checksum
  verification.

---

# Prime Directive

A dependency is a long-term commitment. Choose it like one,
maintain it like one, retire it like one. A code base that
controls its dependencies controls its destiny; one that does
not, does not.

The cheapest dependency is the one you do not have.
