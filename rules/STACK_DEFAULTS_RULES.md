# Stack Defaults

Single source of truth for the technology stack AI Agent Core
recommends as the **default** when starting a new project. Other
rules cite this file rather than restate the choices.

These are **defaults**, not laws. Choosing a different stack is a
deliberate, written decision (skill `adr`) — typically driven by
an external constraint (regulatory, vendor lock, scale, team
expertise), not by preference.

When multiple paths are listed, the path is chosen at project
bootstrap (skill `bootstrap-project`) and the choice is recorded
in an ADR.

---

# Two paths

AI Agent Core supports two well-trodden paths:

| Path                      | When                                                                |
| ------------------------- | ------------------------------------------------------------------- |
| **Edge / Cloudflare**     | Default. Greenfield SaaS, B2B / B2C web, fast time-to-deploy, low ops overhead. |
| **JVM / Quarkus**         | Large-scale enterprise systems, JVM ecosystem requirements, heavy domain modelling, complex transactions. |

Mixed deployments (frontend on Cloudflare, backend on Quarkus)
are a valid combination — see "Hybrid" below.

---

# Default path — Cloudflare

The first-choice stack for a new SaaS / web product.

## Frontend

| Concern              | Default                                                  |
| -------------------- | -------------------------------------------------------- |
| Framework            | **SvelteKit** + `@sveltejs/adapter-cloudflare`           |
| Language             | **TypeScript**, `strict: true`                           |
| Styling              | **Tailwind CSS** (tokens in `tailwind.config.ts`)        |
| Package manager      | **pnpm** with `pnpm-workspace.yaml`                      |
| Bundler / dev server | **Vite**                                                 |
| Hosting              | **Cloudflare Pages** (or Workers static assets)          |
| Tests                | **Vitest** (unit), **Playwright** (e2e)                  |

## Backend (default — edge runtime)

| Concern         | Default                                              |
| --------------- | ---------------------------------------------------- |
| Runtime         | **Cloudflare Workers**                               |
| Framework       | **Hono** (or fetch-handler directly when small)      |
| Language        | **TypeScript**, `strict: true`                       |
| Deploy tool     | **Wrangler** (`wrangler.toml`)                       |
| Local dev       | `wrangler dev --persist-to ../../.wrangler-shared`   |
| HTTP routing    | Hono router; OpenAPI as the contract                 |
| Auth            | OIDC / vendor IdP via Hono middleware                |
| Tests           | **Vitest** + Hono test client                        |

## Persistence and supporting services

| Concern                 | Default                                              |
| ----------------------- | ---------------------------------------------------- |
| OLTP database           | **Cloudflare D1** (SQLite class) for small/mid scale |
| Migrations              | `wrangler d1 migrations` or hand-rolled SQL versioned in `packages/db/migrations/` |
| Object storage          | **Cloudflare R2**                                    |
| Key-value / cache       | **Cloudflare KV**                                    |
| Realtime / state        | **Durable Objects**                                  |
| Queue                   | **Cloudflare Queues**                                |
| Cron                    | **Cloudflare Cron Triggers**                         |
| Observability           | **Workers Logs** + **Workers Analytics Engine**; pipe to a vendor (Logflare / Datadog / etc.) at scale |
| Secrets                 | `wrangler secret` (Workers Secrets), GitHub Actions OIDC for CI sync |
| DNS / TLS / CDN / WAF   | **Cloudflare** (proxied DNS, automatic certs, ratelimits, Bot Management) |

When D1 is too small (heavy joins, full-text search, hot-write
contention), graduate the data plane to:

- **Cloudflare Hyperdrive** + managed Postgres (Neon, Supabase,
  Aiven, etc.), or
- the JVM / Quarkus path with Postgres (see below).

## Email / mailer

| Concern         | Default                                              |
| --------------- | ---------------------------------------------------- |
| Transactional   | **Resend** (`@resend/node`)                          |
| From address    | Authenticated sender on the project's apex/sub      |
| DKIM / SPF / DMARC | Configured at Cloudflare DNS (managed by IaC)     |
| Templates       | Source-controlled HTML/MJML; one per business event |
| Webhooks        | Signed delivery webhooks for bounce / complaint feedback |

See `rules/NOTIFICATION_RULES.md` for the full contract.

## Payment

| Concern         | Default                                              |
| --------------- | ---------------------------------------------------- |
| Provider        | **Stripe** (or Stripe Connect for marketplaces)      |
| Integration     | Provider-hosted checkout / token-only flows; PCI scope reduced ruthlessly. |
| Webhook handler | Cloudflare Worker route, signed body verified, idempotent. |

See `rules/MONEY_HANDLING_RULES.md` and skill `payment-integration`.

## CI / CD

- **GitHub Actions** with **OIDC federation** to Cloudflare (no
  long-lived API tokens stored in CI).
- `pnpm install --frozen-lockfile` everywhere.
- Wrangler deploy for Workers; Pages deploy for static frontends.
- Artifact pinning: container digests, action SHA pinning.

See `rules/CICD_RULES.md`.

---

# Large-scale path — Quarkus / JVM

Use when the system has long-lived, heavily transactional domain
logic; multi-tenant data with complex consistency invariants;
JVM-ecosystem requirements; or a team with deep JVM expertise.

## Backend

| Concern             | Default                                                 |
| ------------------- | ------------------------------------------------------- |
| Framework           | **Quarkus**                                             |
| Language            | **Kotlin** preferred; **Java 21+** acceptable           |
| Build               | **Gradle** (Kotlin DSL) or Maven                        |
| HTTP                | RESTEasy Reactive / JAX-RS, or gRPC where appropriate   |
| Persistence ORM     | **Hibernate ORM** with Panache, or `jOOQ` for SQL-first |
| Connection pooling  | Agroal (Quarkus default)                                |
| Native image        | GraalVM native build for cold-start-sensitive workloads |
| Tests               | JUnit 5 + Quarkus DevServices (Testcontainers integrated) |
| Validation          | Hibernate Validator (JSR-380)                           |

## Persistence

| Concern             | Default                                                 |
| ------------------- | ------------------------------------------------------- |
| OLTP database       | **PostgreSQL** (managed: AWS RDS, GCP Cloud SQL, Aiven, Neon) |
| Migrations          | **Flyway** (`db/migration/V<N>__<name>.sql`)            |
| Entity generation   | **jeg** (database → entity reverse-generation)          |
| Schema source-of-truth | Flyway migration files (forward-only in production)  |
| Read replicas       | Configured deliberately; primary for writes; route reads with documented staleness tolerance. |

The **`${projectName}-entity` / `${projectName}-migration` /
`${projectName}-generator` triple** in
`rules/PROJECT_STRUCTURE_RULES.md` maps to:

- `${projectName}-migration` — the Flyway migration tree.
- `${projectName}-generator` — the jeg invocation that reads the
  schema produced by Flyway and emits typed entities.
- `${projectName}-entity` — the generated entities (treated as
  generated artifacts; never hand-edited).

## Operations

- **IaC**: Terraform / Pulumi against the chosen cloud
  (typically AWS / GCP).
- **Container**: distroless / minimal base images, scanned and
  digest-pinned.
- **Orchestration**: Kubernetes (managed: EKS / GKE) when scale
  warrants; otherwise a simpler runtime (Cloud Run, ECS Fargate,
  Fly.io). See `rules/INFRA_RULES.md`.
- **Observability**: OpenTelemetry SDK + Prometheus + Loki +
  Tempo, or a vendor (Datadog / New Relic / Honeycomb).

## Frontend (when paired)

The frontend defaults are **the same as the Cloudflare path** —
SvelteKit + TS + Tailwind + pnpm — but deployed to Cloudflare
Pages or to the chosen cloud's static hosting. The frontend talks
to the Quarkus backend over HTTPS / mTLS.

---

# Hybrid

Common combination:

- **Frontend**: SvelteKit on Cloudflare Pages.
- **Backend**: Quarkus on a managed Postgres + Kubernetes / Cloud
  Run.
- **Edge concerns** (auth at the edge, lightweight transforms,
  webhooks): Cloudflare Workers in front.
- **Email**: Resend.
- **Payment**: Stripe.

This is supported. The bounded-context rule still applies — keep
the frontend's domain types separate from the backend's, and use
an anti-corruption layer (`architectures/`) to translate.

---

# Path selection at bootstrap

Skill `bootstrap-project` confirms the path with the user before
any code is generated. The choice is captured as ADR-0001 (or
equivalent) and pinned in:

- `package.json` (`packageManager`),
- `pnpm-workspace.yaml`,
- `wrangler.toml` (Cloudflare path) or
  `gradle.properties` / `pom.xml` (Quarkus path),
- the project's README "Stack" section.

Mixing paths inside a single deploy unit (one Worker that
embeds Quarkus, etc.) is forbidden.

---

# Forbidden defaults

- npm / yarn for new JS / TS projects (use pnpm; ADR-back any
  exception).
- Self-rolled DNS / TLS / WAF when Cloudflare is on the path.
- Self-rolled email infrastructure (SMTP relays, etc.) when
  Resend or an equivalent SES / SendGrid is available.
- Hand-edited entities on the Quarkus path (entities are
  generated; edits to `${projectName}-entity` are forbidden).
- ORM auto-migration in production-bound branches on either
  path.

---

# Deviation protocol

When a project genuinely needs a different stack:

1. Write an ADR (skill `adr`) before bootstrapping.
2. State the constraint that forces the deviation.
3. State the cost being accepted (loss of shared tooling, more
   ops surface, smaller community-of-practice within the team).
4. Document how the project will still satisfy the relevant
   rules (security, observability, CI/CD, etc.) on the chosen
   stack.

A deviation without an ADR will be questioned in code review.

---

# Prime Directive

Default to the boring, integrated stack. Boring stacks ship.
Pick a different stack only when the team can articulate the
constraint that forces it — and write that constraint down where
the next engineer will find it.

The cheapest stack decision is the one the next person on the
team does not have to re-debate.
