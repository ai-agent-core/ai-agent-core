# Infrastructure Rules

Infrastructure is the substrate every other system depends on. It
must be reproducible, reviewable, and recoverable. These rules
define the minimum bar for infrastructure design and operation.

For the operational stance, see
`principles/OPERATIONAL_PRINCIPLES.md`. For deploys see
`rules/CICD_RULES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Default infrastructure target

The default infrastructure target is **Cloudflare** — Workers,
Pages, D1, R2, KV, Queues, Durable Objects, Cron Triggers, plus
proxied DNS / TLS / WAF managed in the same Cloudflare account.
For the full list and rationale, see
`rules/STACK_DEFAULTS_RULES.md`.

A Cloudflare-first stack means most "infra" is declared via
`wrangler.toml` and `wrangler` commands rather than Terraform.
That is acceptable — wrangler config IS the IaC for that path.

Pick a different target (AWS / GCP / on-prem / Azure) only when
a constraint forces it (large-scale Quarkus path, regulatory,
existing tenant). Record the choice in an ADR.

---

# Infrastructure as Code (Mandatory)

All production infrastructure MUST be declared in code:

- networks, subnets, routes, firewalls,
- compute (VMs, container clusters, serverless, Workers),
- storage (databases, buckets, queues, KV, R2, D1),
- identity (IAM roles, service accounts, policies),
- DNS records,
- secrets manager bindings (the binding, not the secret value),
- monitoring resources (alerts, dashboards as code where
  feasible).

Tooling by target:

- **Cloudflare path**: `wrangler.toml` per app + Terraform /
  Pulumi for account-level resources (Zone settings, Pages
  projects, R2 buckets, Access policies). Wrangler is invoked
  by GitHub Actions via OIDC federation, not from laptops.
- **AWS / GCP / Azure path**: Terraform / OpenTofu, Pulumi, AWS
  CDK, Bicep. Helm / Kustomize for Kubernetes resources.

Pick **one** primary stack per environment and use it consistently.

Forbidden:

- console click-ops in production,
- "I'll script it later" — the script is the design, not a
  follow-up.

---

# Plan Before Apply

`terraform plan` (or equivalent) MUST be posted on every change
PR:

- a human reviewer reads the plan,
- destructive operations (replace, delete) are flagged
  prominently,
- environments are gated (dev / staging / prod) with separate
  state.

CI runs `plan`; CD runs `apply` only after approval.

Forbidden:

- `apply` from a developer laptop against production,
- merges without a posted plan,
- "minor changes go directly."

---

# Multi-Environment by Construction

Dev / staging / prod share the same module structure, differ only
in configuration:

- separate accounts / projects / subscriptions,
- separate state files,
- separate IAM trust domains,
- separate secrets stores.

Forbidden:

- shared accounts across environments,
- "we'll separate later" — separation is much harder retroactively
  than upfront,
- production credentials usable from staging.

---

# Network Topology

Default posture: private by default, public by exception.

- VPC / VNet with public, private, and (when needed) isolated
  subnets.
- Compute that does not need to be reachable from the internet
  is in a private subnet.
- Egress to the internet is via a NAT gateway / proxy with
  logging.
- Inter-service traffic stays within the VPC.
- Security groups / firewall rules deny by default; least-privilege
  allow rules.
- Public load balancers expose a small, documented surface.

Forbidden:

- 0.0.0.0/0 ingress on database / cache / queue ports,
- security groups with broad allow-from-self that spans unrelated
  workloads,
- public buckets unless deliberately public-by-design.

---

# Identity and Access

- Workloads use platform-native identity (IAM roles for service
  accounts, instance profiles, managed identities). No
  long-lived static keys for production workloads.
- Human access is named and short-lived (SSO, IdP, time-bounded
  elevation). Shared admin accounts are forbidden.
- Permissions are scoped to the workload's needs.
- Privilege elevation is logged and reviewable.
- Break-glass procedures exist, are documented, and are audited
  on every use.

Forbidden:

- root / superuser credentials in any non-emergency flow,
- permissions wildcards (`*:*`) in production policies,
- service accounts whose scope spans environments.

---

# Secrets Storage

Secrets live in a secrets manager, never in IaC source:

- KMS / Vault / Secrets Manager / SSM Parameter Store / Sealed
  Secrets,
- IaC declares the *binding* (which secret a workload reads),
  not the value,
- rotation is automated where supported,
- access is logged and monitored.

See `rules/SECRETS_RULES.md`.

---

# Compute

- Stateless services horizontally scale; state lives in stores
  built for it.
- Container images are pinned by digest, not `:latest`.
- Base images are scanned and refreshed on a schedule.
- Resource requests / limits are declared (CPU, memory, disk,
  network).
- Health, liveness, and readiness probes are defined.
- Graceful shutdown is implemented (SIGTERM → drain → exit).

Forbidden:

- production workloads running as root inside containers,
- containers built without `USER` directive,
- pods with no resource limits,
- "burst forever" workloads with no upper bound.

---

# Kubernetes Specifics (When Used)

- Namespaces by environment / team / workload.
- Network policies that default-deny inter-namespace traffic.
- Pod Security Standards: `restricted` profile by default.
- Read-only root filesystem where possible.
- No privileged containers in production.
- Horizontal Pod Autoscaler with sane min / max.
- Pod Disruption Budgets defined.
- Secrets via the secrets manager (CSI driver / external secrets
  operator), not raw `Secret` objects bound to plaintext in git.

Choose Kubernetes deliberately. It is rarely the simplest answer
for small systems.

---

# Storage

- Each datastore (DB, cache, queue, blob) has documented:
  RPO, RTO, backup schedule, retention, encryption, access path.
- Backups are encrypted, stored in a separate trust domain, and
  restored periodically.
- Encryption at rest is enabled (default for managed services).
- Storage scales by design (autoscale, sharded, partitioned)
  for any dataset that may grow without bound.

Forbidden:

- production data in unmanaged ad-hoc volumes,
- backups stored only in the same account / region as the
  primary,
- production data in storage that has no documented retention
  or recovery path.

---

# DNS and Certificates

- DNS zones managed in IaC.
- TTLs sane (low enough for fast cutover, high enough to avoid
  request floods).
- Certificates managed by an automated authority (ACME / ACM /
  cert-manager).
- Certificate expirations alerted at least 30 days out (target
  zero alerts in practice; renewal must be automatic).
- Internal DNS / service mesh used for service discovery; not
  hard-coded IPs.

A manual cert renewal is a future outage.

---

# Cost Discipline

- Tag every resource with at least: `env`, `service`, `owner`,
  `cost-center`.
- Budgets and alerts on monthly spend per service / per
  environment.
- Idle resources are reaped (weekly review or automated).
- Storage tiering and retention reduce long-term cost without
  losing recoverability.
- Auto-scaling caps prevent runaway cost from a misbehaving
  workload.

Forbidden:

- untagged resources in production,
- "we forgot we left that running,"
- environments without spend ceilings.

---

# Disaster Recovery

For each environment, the team has a written DR plan:

- failure scenarios (region, AZ, datastore corruption, account
  compromise),
- RPO and RTO per dataset,
- failover procedure (manual or automated),
- the most recent date this was rehearsed.

DR that has never been tested is a hope. Rehearse on a schedule.

---

# Multi-Region (When Required)

Choose deliberately:

- **Active-passive** — secondary region warm, manual or
  automated failover. Simpler. Acceptable RTO measured in
  minutes-to-hours.
- **Active-active** — both regions take traffic. Complex
  consistency model. Necessary for low RTO and for global
  latency.

Each comes with consistency, cost, and operational complexity
trade-offs. Document the choice in an ADR.

Forbidden:

- "multi-region" that is just a backup copy with no failover
  rehearsal.

---

# Networking Performance

- Cross-region calls on the user path are forbidden by default
  (latency budget).
- Service meshes' overhead is measured, not assumed.
- Connection pooling, keep-alive, and HTTP/2 used where they pay.
- CDN in front of static assets and cacheable APIs where users
  are global.

---

# Observability for Infra

Beyond app telemetry, infrastructure exposes:

- node / pod / instance health,
- network throughput and error rates per LB,
- DB primary lag, replica lag, connection saturation,
- queue depth / consumer lag,
- cost trend per service.

Same dashboard / alert discipline as
`rules/OBSERVABILITY_RULES.md`.

---

# Change Windows and Freezes

- Production changes have known windows and a defined freeze
  policy (e.g. no deploys during high-revenue events without
  written approval).
- Emergency changes are allowed but explicit and logged.
- Database migrations on hot tables follow
  `rules/MIGRATION_RULES.md`.

---

# Forbidden Anti-patterns

- IaC drift (infrastructure changed by hand, not reflected in
  code).
- Single state file shared across environments.
- "We will modularize later" — production-spanning monolithic
  modules.
- Hard-coded IP addresses or hostnames.
- Permissions scoped per-environment instead of per-workload.
- Production resources without tags / owner.
- Rollback "by remembering" — no documented procedure.

---

# Prime Directive

Infrastructure must be reproducible, reviewable, and recoverable.
The team must be able to rebuild a region, recover a dataset,
and rotate a secret on schedule. Anything else is borrowing
operational capability you may not have on the day you need it.

If only one engineer can rebuild it, the team cannot run it.
