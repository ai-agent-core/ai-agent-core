---
name: infra-setup
description: Design and provision infrastructure as code — environments, network, identity, compute, storage, secrets, observability — reproducibly and safely.
---

# Infrastructure setup

Use this skill **whenever new infrastructure is being provisioned
or restructured** — a new service, a new environment, a new
region, a vendor swap.

Authoritative source: `rules/INFRA_RULES.md` and
`principles/OPERATIONAL_PRINCIPLES.md`.

---

## Step 0 — Confirm scope with the user

Before writing any IaC:

- which cloud / on-prem / hybrid?
- which environments (dev / staging / prod / per-developer)?
- which regions, which AZs?
- expected scale (req/s, data volume, growth shape)?
- compliance regime (PCI, HIPAA, GDPR, ISO 27001)?
- budget ceiling?

Reflect the confirmed scope into `tasks/todo.md`. Where the
choice is one-way (vendor, region, tenancy model), write an ADR
(skill `adr`).

---

## Step 1 — Pick the toolchain

Pick **one** IaC stack per environment and use it consistently:

- **Terraform / OpenTofu** — broad multi-cloud, mature ecosystem.
- **Pulumi** — IaC in real programming languages.
- **AWS CDK / Bicep / GCP Deployment Manager** — cloud-native.
- **Helm / Kustomize / Argo CD** — Kubernetes resources.
- **Crossplane** — Kubernetes-native infra control plane.

Mixing tools without a written reason is forbidden. Each tool has
a state model; managing the same resource from two tools is the
worst-of-both-worlds outcome.

---

## Step 2 — Multi-environment by construction

Mandatory separation:

- separate cloud accounts / projects / subscriptions per
  environment,
- separate IaC state files per environment,
- separate IAM trust domains,
- separate secrets stores.

Forbidden:

- shared accounts across environments,
- "we'll separate later" — it is much harder retroactively,
- production credentials usable from staging.

---

## Step 3 — Network topology

Default: private by default, public by exception.

- VPC / VNet with public, private, and (when needed) isolated
  subnets,
- compute that does not need to be reachable from the internet
  is in a private subnet,
- egress via NAT / proxy with logging,
- inter-service traffic stays within the VPC,
- security groups / firewall rules deny by default; explicit
  least-privilege allow,
- public load balancers expose a small, documented surface.

Forbidden:

- 0.0.0.0/0 ingress on database / cache / queue ports,
- security groups with broad "allow from self" spanning unrelated
  workloads,
- public buckets unless deliberately public-by-design.

---

## Step 4 — Identity and access

- workloads use platform-native identity (IAM roles, service
  accounts, managed identity, workload identity),
- humans use SSO / IdP with MFA; named accounts only,
- privileges scoped per workload, not per environment,
- privilege elevation is just-in-time, logged, time-bounded,
- break-glass procedure documented and audited on every use.

Forbidden:

- shared admin accounts,
- root credentials in any non-emergency flow,
- wildcard IAM (`*:*`) in production policies.

---

## Step 5 — Compute

For services:

- horizontally scalable; state lives in stores built for it,
- container images pinned by digest, scanned, refreshed on
  schedule,
- resource requests / limits declared,
- liveness / readiness / (optional) startup probes defined,
- graceful shutdown (SIGTERM → drain → exit),
- non-root user inside containers,
- min-replicas / max-replicas / scaling policy declared.

For Kubernetes specifically:

- namespaces by environment / team / workload,
- network policies default-deny inter-namespace,
- Pod Security Standards `restricted` profile,
- Pod Disruption Budgets,
- secrets via secrets manager (CSI driver / external secrets
  operator), not raw `Secret` objects bound to plaintext in git.

Choose Kubernetes deliberately — it is rarely the simplest answer
for small systems.

---

## Step 6 — Storage

For each datastore (DB, cache, queue, blob):

- documented RPO and RTO,
- automated backups,
- encryption at rest,
- access path through least-privilege IAM,
- retention and deletion schedule.

Backups are encrypted, in a separate trust domain, and **restored
periodically** (quarterly minimum). A backup that has never been
restored is a hope.

---

## Step 7 — Secrets

- secrets live in a secrets manager (KMS / Vault / Secrets
  Manager / Key Vault / SSM Parameter Store),
- IaC declares the *binding* (which secret a workload reads),
  not the value,
- rotation automated where supported,
- access logged.

Never:

- secrets in IaC source,
- secrets in git history,
- secrets in container images,
- shared secrets across environments.

See `rules/SECRETS_RULES.md` and skill `secrets-management`.

---

## Step 8 — DNS, certificates, edge

- DNS zones in IaC,
- TTLs sane,
- certificates managed by an automated authority (ACME / ACM /
  cert-manager),
- internal DNS / service mesh for service discovery; no
  hard-coded IPs,
- CDN in front of static assets and cacheable APIs where users
  are global.

A manual cert renewal is a future outage.

---

## Step 9 — Observability provisioning

Infrastructure must come with the observability stack:

- log shipping (Cloud Logging / CloudWatch / Loki / Datadog /
  Splunk),
- metrics (Cloud Monitoring / Prometheus / Datadog / New Relic),
- traces (OpenTelemetry / Jaeger / Tempo / X-Ray / Cloud Trace),
- alert / paging (PagerDuty / Opsgenie / Cloud-native).

Dashboards and alerts are IaC where the platform supports it.

See `rules/OBSERVABILITY_RULES.md` and skill `observability-setup`.

---

## Step 10 — Cost discipline

- tag every resource with at least: `env`, `service`, `owner`,
  `cost-center`,
- budgets and alerts on monthly spend per service / environment,
- idle resources are reaped (scheduled or automated),
- storage tiering and retention reduce long-term cost,
- auto-scaling caps prevent runaway cost.

Forbidden:

- untagged resources in production,
- environments without spend ceilings.

---

## Step 11 — Disaster recovery and multi-region

For each environment, the team has a written DR plan:

- failure scenarios,
- RPO / RTO per dataset,
- failover procedure (manual or automated),
- date of most recent rehearsal.

Multi-region: choose **active-passive** (simpler, RTO in
minutes-to-hours) or **active-active** (complex consistency,
necessary for low RTO and global latency). Document in an ADR.

Forbidden:

- "multi-region" that is just a backup copy with no failover
  rehearsal.

---

## Step 12 — Plan, review, apply

- every change goes through a PR,
- `terraform plan` (or equivalent) is posted,
- destructive operations flagged,
- environments gated (dev / staging / prod) with separate state,
- CI runs `plan`; CD runs `apply` only after approval,
- production `apply` happens via automation, never from a
  laptop.

A drift between state and reality is a vulnerability.

---

## Step 13 — Day 2

Before declaring infra "done":

- runbooks for the common failures (skill `incident-response`),
- on-call rotation set up,
- backups verified,
- observability live,
- a hello-world workload runs end-to-end with the same posture
  as the eventual production workload.

Infrastructure that has never run a real workload is a
hypothesis, not a system.

---

## Forbidden

- IaC drift (infra changed by hand, not reflected in code),
- single state file shared across environments,
- production-spanning monolithic modules,
- hard-coded IP addresses or hostnames,
- production resources without tags / owner,
- rollback "by remembering" — no documented procedure,
- production console access by default.

---

## When this skill says STOP

- The user has not confirmed environment / region / scale →
  ask before provisioning,
- the DR plan has never been tested → schedule a rehearsal
  before going live,
- backups exist but restoration has never been verified →
  block production launch.

Infrastructure must be reproducible, reviewable, and
recoverable. The team must be able to rebuild a region, recover
a dataset, and rotate a secret on schedule.

If only one engineer can rebuild it, the team cannot run it.
