# Project Structure Rules

These rules define the mandatory structure for all projects.

Agents MUST follow these standards when creating or modifying project layouts.

Consistency across projects is REQUIRED.

---

# Database as the Source of Truth

The database schema MUST be treated as the authoritative source for persistence structure.

Entities MUST be generated from the database schema.

Reverse generation is REQUIRED.

Manual divergence from the schema is FORBIDDEN.

---

# Migration Is Mandatory

All database resources MUST be migration-driven.

Schema changes MUST occur through versioned migrations.

Direct, unmanaged schema modification is strictly FORBIDDEN.

The system MUST always be reproducible from migrations alone.

---

# Mandatory Project Modules

Every project MUST define three responsibilities, each owned by
its own module / package:

- `${projectName}-entity`     — generated persistence models
- `${projectName}-migration`  — versioned schema migrations
- `${projectName}-generator`  — deterministic schema → entity codegen

Agents MUST enforce this triple. The concrete shape of each
depends on the path chosen in `rules/STACK_DEFAULTS_RULES.md`.

## Concrete shape per path

### Cloudflare path (default — TypeScript / Workers / D1)

Typical monorepo layout (matches the Sealess reference):

```
repo/
  packages/
    domain/                             (shared domain types)
    entity/                             (generated typed bindings)
  tools/
    db/                                 (migrations, seed, dev fixtures)
      migrations/
        0001_init.sql
        0002_orders_add_currency.sql
    generator/                          (schema → typed-helper generation)
```

| Triple role        | Default toolchain                                    |
| ------------------ | ---------------------------------------------------- |
| Migrations         | SQL files versioned under `tools/db/migrations/`,    |
|                    | applied via `wrangler d1 migrations apply <db>`,     |
|                    | forward-only in production.                          |
| Generator          | Custom TS script (or `drizzle-kit` / similar) that   |
|                    | reads the migration set / live D1 schema and emits   |
|                    | typed helpers into `packages/entity`.                |
| Entity             | `packages/entity` — typed query helpers and result   |
|                    | shapes. Treated as generated; never hand-edited.     |

### Quarkus / JVM path (large-scale)

Module-per-responsibility, as Gradle / Maven sibling modules:

| Triple role        | Default toolchain                                    |
| ------------------ | ---------------------------------------------------- |
| Migrations         | **Flyway** (`db/migration/V<N>__<name>.sql`),        |
|                    | forward-only in production. Reproducible from empty. |
| Generator          | **jeg** — reads the schema produced by Flyway and    |
|                    | emits JPA `@Entity` classes into `*-entity`.         |
| Entity             | `${projectName}-entity` — generated `@Entity` types. |
|                    | Manual edits forbidden.                              |

### Hybrid

A frontend on the Cloudflare path with a backend on the
Quarkus path uses the Quarkus triple for the backend and a
typed API client (generated from the OpenAPI / proto schema)
in the frontend package. The frontend has no separate
entity / migration / generator triple of its own.

---

## `${projectName}-entity`

Responsible for:

- generated persistence models / typed helpers,
- schema-derived objects,
- database representations.

This module SHOULD NOT contain domain logic. These are
persistence types, NOT domain entities.

Edits to generated artifacts are forbidden — change the schema
(via a migration) and regenerate.

---

## `${projectName}-migration`

Responsible for:

- schema evolution,
- version control of database structure,
- rollback capability (forward-only migrations: a "rollback" is
  a new forward migration),
- reproducible database setup from empty.

All structural changes MUST originate here.

Tools by path:

- Cloudflare path → SQL files + `wrangler d1 migrations`.
- Quarkus path → Flyway.

---

## `${projectName}-generator`

Responsible for:

- entity / typed-helper generation,
- schema synchronization,
- code generation workflows.

Generation MUST be deterministic and reproducible — same input
(schema + migration set) produces the same output bytes.

Tools by path:

- Cloudflare path → custom TS generator (or `drizzle-kit`
  introspection, etc.).
- Quarkus path → **jeg**.

Avoid manual patching of generated artifacts.

---

# Prefer Existing Mechanisms

When an existing project already provides:

- API infrastructure
- code generation
- migration frameworks
- shared tooling

Agents MUST prefer those mechanisms.

Avoid reinventing infrastructure unless explicitly justified.

Consistency across the ecosystem is more valuable than local optimization.

---

# Avoid Structural Drift

Projects SHOULD NOT invent custom layouts without strong justification.

Structural consistency enables:

- faster onboarding
- safer automation
- predictable AI behavior
- lower cognitive load

Deviation increases systemic risk.

---

# Core Directive

Build projects that are reproducible, automatable, and structurally predictable.
