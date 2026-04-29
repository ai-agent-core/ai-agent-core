# Secrets Rules

A secret is a capability. Anyone with it can do what the secret
authorizes. These rules define how secrets are stored,
transmitted, and rotated.

For the principles behind these rules, see
`principles/SECURITY_PRINCIPLES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Definition

A *secret* is any value that grants authority and is not safe to
disclose. Includes:

- API keys / tokens (cloud, third-party, internal),
- database passwords / connection strings,
- private keys (TLS, signing, encryption),
- session signing secrets / JWT signing keys,
- OAuth client secrets,
- webhook signing secrets,
- service account credentials,
- any credential that authenticates a workload or user.

If the value being leaked would let an attacker do something,
treat it as a secret.

---

# Source of Truth

Production secrets live in a secrets manager:

- AWS Secrets Manager / SSM Parameter Store,
- Google Secret Manager,
- Azure Key Vault,
- HashiCorp Vault,
- 1Password / SOPS / SealedSecrets for some workflows.

Workloads read secrets at boot or via a CSI driver, not from
files in the image, not from environment variables baked at build
time.

Forbidden:

- secrets in source control (`.env`, `config.yaml`, `terraform`),
- secrets in build artifacts (Dockerfile, image layers),
- secrets in CI logs (mask, scrub, prefer OIDC),
- shared secret across multiple workloads when scope can be
  narrower,
- copying production secrets to laptops.

---

# Naming and Scoping

- Each secret has a documented owner and purpose.
- Each secret is scoped to a single workload (or a small,
  documented set).
- Names follow a convention: `<env>/<service>/<purpose>`.
- The catalog of secrets is reviewable; "what does the system
  hold and who can read it?" is answerable.

A secret named `prod-misc-2` with no owner is a future incident.

---

# Access

- Workloads use platform-native identity (IAM role, service
  account, managed identity) to authenticate to the secrets
  manager — no static credentials to read other credentials.
- Human access is named, time-bounded, and audited.
- Access logs are reviewable; anomalous reads are alerted.
- Read access is least-privilege per secret — not "developers
  read all of prod."

Forbidden:

- shared admin accounts to the secrets manager,
- ambient credentials (default profile on a laptop) authorized
  for production reads.

---

# Rotation

Every secret has a documented rotation schedule. Defaults:

- short-lived tokens (issued by IdP / OIDC): minutes-to-hours,
- API keys / passwords: 90 days unless platform supports
  shorter,
- signing keys: per-key strategy with deliberate validity,
- TLS certs: automatic via ACME / ACM / cert-manager.

Rotation is automated where the platform allows. Manual rotation
is a process, not a hope:

- the next rotation date is known,
- the procedure is documented,
- it has been performed at least once.

Forbidden:

- "we don't rotate, it's been working,"
- secrets without an owner aware of the rotation cadence.

A rotation that has never been done is a rotation that will fail
the day it is needed.

---

# Compromise Response

Treat any of the following as a compromised secret:

- secret committed to git (even if the commit is reverted —
  history is forever),
- secret printed in a log,
- secret displayed on a screen recorded externally,
- secret shared in chat / email / ticket,
- secret found by a scanner.

On compromise:

1. Rotate the secret immediately.
2. Audit usage during the exposure window.
3. Investigate root cause; fix the leak class.
4. Update detection so this class is caught earlier next time.

Reverting the commit is not enough. The secret is on the
attacker's laptop now.

---

# Detection

CI / pre-commit MUST scan for secrets:

- `trufflehog`, `gitleaks`, `detect-secrets`, or platform-native
  scanners,
- block PRs that introduce secrets,
- alert on secrets that slip through to `main` or to logs.

Forbidden:

- relying on humans to remember not to commit secrets,
- shipping without a secret scanner.

A secret already in git history must be revoked, then optionally
purged (history rewrite, BFG / `git filter-repo`).

---

# Local Development

- Each developer has their own credentials; no shared dev
  secret.
- Local dev uses a local secrets file ignored by git, or a
  per-developer entry in the secrets manager.
- Production-grade secrets MUST NOT be available on developer
  laptops by default.
- "Just use prod secrets locally to debug" is forbidden — use
  staging or anonymized data.

---

# Application Discipline

- Secrets are loaded once at boot or refreshed on a schedule;
  never embedded in source.
- Secrets are wrapped in types that prevent accidental logging
  (e.g. `Secret<T>` with redacted `Display` / `toString`).
- Comparison of tokens / signatures uses constant-time equality.
- Errors do not leak secrets in messages.
- Backtraces / panic dumps do not include secrets (configure the
  framework to redact).

Forbidden:

- logging the request body of authentication endpoints,
- printing environment variables in startup banners,
- sending secrets in error responses.

---

# Cryptographic Material

Long-lived signing / encryption keys deserve extra discipline:

- generated using HSM / KMS where possible,
- backed up via the KMS's own mechanisms, not as plaintext,
- versioned (so rotation is forward-compatible),
- usage logged.

Symmetric session-signing secrets:

- ≥256 bits of entropy,
- separate per environment,
- rotated at least annually,
- support for multiple active versions during rotation.

---

# CI / CD Secrets

CI workloads are themselves attack targets:

- prefer OIDC federation to cloud IAM over long-lived static
  keys,
- scope secrets per workflow / per environment,
- mask secrets in logs,
- forbid third-party CI actions / images that need broad
  privileges, unless pinned by SHA and reviewed.

A compromised CI is a compromised production. Pretend it will
happen and design accordingly.

See `rules/CICD_RULES.md`.

---

# Webhook Secrets

For webhooks the system *receives*:

- shared secret per partner / per integration, never global,
- payloads signed with HMAC over body and timestamp,
- timestamp window enforced (replay protection),
- signature verified before any processing.

For webhooks the system *sends*:

- signing secret negotiated per consumer,
- documented signature scheme,
- rotation procedure known to the consumer.

---

# Multi-tenant Secrets

When the system holds secrets *belonging to its tenants* (e.g.
their API keys to integrations they enable):

- store encrypted per tenant,
- envelope encryption with KMS keys,
- access checks include tenant ownership,
- right-to-deletion includes secret destruction,
- usage logs are tenant-scoped.

A tenant secret is a special category of liability. Treat it as
if it were your own master key.

---

# Forbidden Anti-patterns

- "Just put it in `.env` for now."
- One secret used by multiple environments.
- Secrets passed via command-line arguments (visible in
  process listings).
- Secrets bundled into container images.
- Logging "for debugging" the very secret you are loading.
- Rotation policy that no one knows about.
- Personal credentials shared with the team.

---

# Prime Directive

A secret is a capability. Treat its lifecycle — generation,
distribution, use, rotation, revocation — with the same rigor
you would treat the database it protects. The leak you can
recover from is the one you detected, rotated, and audited
immediately.

If a secret has never been rotated, it has not been managed.
