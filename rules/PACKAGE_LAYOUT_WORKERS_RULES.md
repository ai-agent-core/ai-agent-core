# Package Layout Rules — Backend (Cloudflare Workers + TypeScript)

This document defines the package layout for the **default
backend path**: a small / mid-scale backend deployed to
**Cloudflare Workers**, written in **TypeScript**, routed via
**Hono**, and bound to D1 / R2 / KV / Queues / Durable Objects.

For the **large-scale Quarkus / JVM path**, see
`rules/PACKAGE_LAYOUT_BACKEND_RULES.md`.

Shared conventions (the four-layer convention, dependency
direction, bounded-context-first) are defined in
`rules/PACKAGE_LAYOUT_COMMON_RULES.md` and apply here.

For the wider stack rationale, see `rules/STACK_DEFAULTS_RULES.md`.

---

# Stack defaults on this path

| Concern         | Default                                              |
| --------------- | ---------------------------------------------------- |
| Runtime         | **Cloudflare Workers**                               |
| Framework       | **Hono** (or fetch-handler directly when small)      |
| Language        | **TypeScript**, `strict: true`                       |
| Package manager | **pnpm** with `pnpm-workspace.yaml`                  |
| Deploy tool     | **Wrangler** (`wrangler.toml`)                       |
| OLTP            | **Cloudflare D1** (graduate to Postgres via Hyperdrive when needed) |
| Object store    | **Cloudflare R2**                                    |
| KV / cache      | **Cloudflare KV**                                    |
| Queue           | **Cloudflare Queues**                                |
| Realtime / state| **Durable Objects**                                  |
| Cron            | **Cloudflare Cron Triggers**                         |
| Tests           | **Vitest** + Hono test client                        |
| Mailer          | **Resend** (`rules/NOTIFICATION_RULES.md`)           |

---

# Example layout

A single Worker per business app (the Sealess pattern):

```
my-app-api/                         (single deployable Worker)
  src/
    index.ts                        (Worker entry — fetch handler / scheduled / queue)
    interfaces/
      order/
        OrderRoutes.ts              (Hono router for /orders/*)
        PlaceOrderRequest.ts        (input DTO + zod schema)
        OrderResponse.ts            (output DTO)
    applications/
      order/
        placeOrderUseCase.ts        (1 scenario = 1 module / 1 entry)
        orderConverter.ts
    domains/
      order/
        Order.ts                    (AggregateRoot — hand-authored)
        OrderStatus.ts              (ValueObject)
        PricingProcessor.ts
        OrderRepository.ts          (interface)
    architectures/
      order/
        D1OrderRepository.ts        (RepositoryImpl backed by D1)
        ResendNotificationClient.ts
        StripeApiClient.ts
      shared/
        bootstrapClients.ts         (DI swap: real ↔ mock per FRONTEND_DEMO_MODE_RULES)
  wrangler.toml                     (env, bindings, secrets, routes)
  package.json
  tsconfig.json                     (strict: true)
  vitest.config.ts
```

For multi-app monorepos (Sealess-shaped):

```
repo/
  apps/
    api/                            (Worker — see above)
    admin/                          (SvelteKit + adapter-cloudflare)
    app/                            (SvelteKit + adapter-cloudflare)
    landing/                        (SvelteKit + adapter-cloudflare)
  packages/
    domain/                         (shared domain types and policies)
    entity/                         (shared types — typed binding helpers)
  tools/
    db/                             (migrations + dev seed)
    generator/                      (schema → typed-helper generation)
  pnpm-workspace.yaml
```

---

# Stereotypes — delta from the JVM stereotypes

Only deltas are listed; anything not mentioned is identical to
`rules/PACKAGE_LAYOUT_BACKEND_RULES.md` (Quarkus path) at the
*conceptual* level.

## `interfaces/`

**Routes** — The Hono router for a bounded context. Mounts under
a prefix, attaches middleware (auth, CORS, rate limit), delegates
each handler to one UseCase. MUST stay thin.

```ts
const orders = new Hono<{ Bindings: Env }>();
orders.post('/', authRequired, async (c) => {
  const req = await c.req.json<PlaceOrderRequest>();
  const result = await placeOrderUseCase(c.env, req);
  return c.json(result, 201);
});
```

**Request / Response** — DTOs at the HTTP boundary. Validate
inputs with **zod** (or equivalent). Forbidden to flow into
`applications/` or `domains/` without conversion.

**Worker entry** (`src/index.ts`) — thin composition root that
mounts routers, wires bindings, and dispatches `fetch`,
`scheduled`, and `queue` events. No business logic.

## `applications/`

**UseCase** — One TypeScript module per scenario. Exports a
single function (or a class with one entry method) that takes
the `Env` (Worker bindings) and a typed input. The transaction
boundary is the UseCase invocation.

```ts
export async function placeOrderUseCase(env: Env, input: PlaceOrderInput): Promise<PlaceOrderResult> { ... }
```

Multi-method UseCases are forbidden — split per scenario.

**Converter** — Bidirectional translator between API DTOs and
domain objects.

## `domains/`

Identical responsibilities to the JVM path. TypeScript classes
with methods, value objects as branded types, repository
interfaces. **No** dependency on `architectures/` or framework
APIs.

## `architectures/`

The boundary to the runtime and to external services.

**RepositoryImpl** — Concrete repository. Talks to `env.DB` (D1),
`env.R2`, `env.KV`, etc.

**ApiClient** — Typed wrapper over outbound HTTP / vendor SDK.
Accepts the secret via `env.<SECRET_NAME>`, never reads
`process.env`.

**NotificationClient** — Wrapper over Resend (or other mailer).

**bootstrapClients.ts** — The single place where DI swaps real
↔ mock implementations based on
`PUBLIC_SEALESS_MODE` / equivalent flag. Required by
`rules/FRONTEND_DEMO_MODE_RULES.md` and applied here on the
backend symmetrically when the system supports demo mode.

---

# Worker runtime constraints

The Workers runtime is **not Node**. The following are forbidden
unless polyfilled deliberately:

- `fs`, `child_process`, `net`, `dgram`,
- Long-running event loops (CPU time per request is bounded;
  background work goes to `ctx.waitUntil()`),
- `Buffer` (use `Uint8Array` / `TextEncoder` / `TextDecoder`),
- Native modules / N-API.

Required:

- `compatibility_date` set deliberately in `wrangler.toml` and
  bumped only with a written reason.
- All package dependencies must be Workers-compatible (no Node
  built-ins).
- Long-running async work uses `ctx.waitUntil()` so the response
  returns first.

---

# `wrangler.toml` discipline

- One `wrangler.toml` per Worker. No "shared" wrangler config
  with conditional logic.
- Per-environment sections (`[env.development]`,
  `[env.production]`) declare bindings explicitly. No relying on
  a default that drifts.
- Bindings are typed in `src/env.d.ts` (`interface Env { … }`)
  and the Worker is generic over `Env`.
- Secrets are NEVER declared in `wrangler.toml`; they are
  injected via `wrangler secret put` (or GitHub Actions OIDC sync
  in CI). See `rules/SECRETS_RULES.md`.
- `routes` for production are pinned with `custom_domain = true`
  (or explicit zone routing); `workers_dev = true` is a dev
  convenience only.

---

# Bindings model

| Service          | Binding kind          | Access pattern                                       |
| ---------------- | --------------------- | ---------------------------------------------------- |
| D1 (SQL)         | `d1_databases`        | `env.DB.prepare('...').bind(...).all()`              |
| R2 (objects)     | `r2_buckets`          | `env.STORAGE.put(key, body)` / `.get(key)`           |
| KV               | `kv_namespaces`       | `env.CACHE.get(key)` / `.put(key, value, { ttl })`   |
| Queue (producer) | `queues.producers`    | `env.JOBS.send(message)`                             |
| Queue (consumer) | `queues.consumers`    | `queue(batch, env, ctx) { … }`                       |
| Durable Object   | `durable_objects`     | `env.DO_NAMESPACE.get(id).fetch(req)`                |
| Service binding  | `services`            | `env.SVC.fetch(req)`                                 |

Bindings are accessed through `architectures/` adapters, not
directly inside `applications/` or `domains/`. The `Env`
interface is the contract.

---

# Persistence on this path

- **Default**: D1 (SQLite class). Suitable for small / mid scale.
- **Migrations**: source-controlled SQL files in
  `tools/db/migrations/` (or `packages/db/migrations/`), applied
  via `wrangler d1 migrations apply`. Forward-only in production.
  Expand → migrate → contract per
  `rules/MIGRATION_RULES.md`.
- **Local dev**: `wrangler dev --persist-to ../../.wrangler-shared`
  uses a local SQLite mirror; `--remote` to talk to the production
  D1 (rare, deliberate).
- When D1 stops being adequate (heavy joins, hot writes, large
  datasets), graduate to Postgres via **Hyperdrive** or move to
  the Quarkus path. Do not paper over D1 limits in application
  code.

---

# Tests

- **Vitest** for unit tests of UseCases, domains, converters.
- **Hono test client** (`hono/testing`) for endpoint-level tests.
- Wrangler local-runtime integration via
  `@cloudflare/vitest-pool-workers` when binding-accurate tests
  matter.
- E2E tests (Playwright) live in the corresponding frontend app
  and exercise the deployed Worker over HTTP.

Mocking boundary follows `rules/TESTING_RULES.md`: mock at the
Repository interface (in `domains/`) and at external API
clients (`architectures/`); never mock UseCases, domain objects,
converters, or routes.

---

# Forbidden patterns (Workers backend)

- business logic inside Routes or the Worker entry,
- direct `env.DB.prepare()` calls from `applications/` or
  `domains/`,
- Node built-ins (`fs`, `child_process`, …) in production code,
- secrets read from `wrangler.toml` `[vars]` (use `wrangler
  secret put` / OIDC-injected),
- "service-of-services" megaworkers that mix unrelated business
  contexts in one binary,
- `process.env` reads (use the typed `Env`),
- mixing Hono routes for unrelated bounded contexts in a single
  router file (split per context),
- using the runtime's default fetch / route export when the
  system has Hono — pick one and use it consistently.

---

# Prime Directive

The Worker is the smallest deployable unit of the backend. Keep
it cohesive (one bounded context, or a small set with a clear
relationship), keep it Worker-runtime-clean, and keep the four
layers visible from the directory tree.

When the Worker stops being adequate — when D1 or runtime
constraints push back — graduate the data plane (Hyperdrive +
Postgres) or graduate the path (Quarkus / JVM). Do not blur the
boundary.
