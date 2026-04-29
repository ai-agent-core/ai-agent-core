---
name: database-design
description: Design or change a schema, picking storage, normalization, primary keys, indexes, and constraints — with the schema as a long-lived public API.
---

# Database design

Use this skill **whenever a new datastore is introduced, a new
table is added, or a non-trivial schema change is being designed**.

Authoritative source: `rules/DATABASE_RULES.md` and
`principles/DATA_PRINCIPLES.md`.

The schema outlives the application. Design accordingly.

---

## Step 1 — Choose the right storage

Before designing tables, choose the engine deliberately:

| Workload                                                    | Engine                       |
| ----------------------------------------------------------- | ---------------------------- |
| Transactional, mixed read/write, multi-row invariants       | Relational (Postgres default) |
| Variable shape per record, single-document atomicity        | Document (MongoDB)           |
| Known keys, large scale, cache-like                         | KV (Redis, DynamoDB)         |
| Append-heavy time-bucketed analytics                        | Time-series (ClickHouse, TS) |
| Full-text / faceted search                                  | Search (OpenSearch)          |
| Large blobs                                                 | Object store (S3 / GCS)      |

Default to Postgres. It is the boring, capable choice.

Write an ADR (skill `adr`) when picking anything other than the
default.

---

## Step 2 — Model the domain, then the tables

Domain modeling comes first. For each aggregate (skill
`aggregate-boundary`):

- identify the entities and value objects,
- identify the invariants the aggregate protects,
- identify the lifecycle (create → state transitions → archive),
- identify the access patterns (who reads, who writes, what
  queries).

Now translate to tables:

- one table per aggregate root, generally,
- value objects live inline (columns) or in child tables when
  multiplicity demands,
- avoid premature decomposition; bias toward fewer, larger tables
  inside an aggregate boundary.

---

## Step 3 — Primary keys

Pick deliberately:

- **UUID v7 / ULID** — distributed generation, time-orderable,
  default for most aggregates.
- **bigint sequence** — single-writer, dense, sortable when the
  workload is centralized.
- **composite key** — only for true junction tables (`(order_id,
  product_id)`).

Forbidden:

- v4 UUIDs as PKs on large hot tables (insert-locality hurts),
- natural keys (email, username) as PKs — they change,
- exposing internal PKs externally where enumeration is a risk.

Public-facing IDs MAY differ from internal PKs.

---

## Step 4 — Required columns

Every table generally has:

- `id` (PK)
- `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` — write-once.
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` — maintained.
- `version INTEGER NOT NULL DEFAULT 0` — for optimistic locking
  on mutable rows.

Add `created_by` / `updated_by` for audit-grade tables.
Add `deleted_at` if soft-delete (chosen deliberately, not by
default).

---

## Step 5 — Constraints (always, when supported)

Encode every domain invariant the engine can express:

- `NOT NULL` for required fields,
- `FOREIGN KEY ... ON DELETE` (`RESTRICT` / `CASCADE` / `SET NULL`)
  with the choice deliberate,
- `UNIQUE` for natural-key uniqueness,
- `CHECK` for value ranges, enum sets, format invariants,
- partial unique indexes for "at most one active" patterns.

Application validation drifts. The schema is the last defense.

---

## Step 6 — Indexes (with justification)

For each index, document:

- the query it accelerates (write the EXPLAIN),
- expected cardinality / selectivity,
- write-amplification trade-off.

Required defaults:

- index every FK referenced by JOIN or filter,
- index columns used in WHERE / ORDER BY / GROUP BY for hot
  queries.

Forbidden:

- "may be useful" speculative indexes,
- duplicate / overlapping indexes,
- indexes added without measurement.

---

## Step 7 — Normalization

Default to 3NF. Denormalize only when:

- a measured access pattern justifies it,
- the duplicated data has a documented authoritative source,
- a reconciliation mechanism exists (event, trigger, scheduled
  job).

Premature denormalization → unreconcilable inconsistencies later.

---

## Step 8 — Concurrency strategy

For every row that may be written by more than one actor, pick a
strategy and document it:

- **optimistic locking** (`version` column),
- **pessimistic locking** (`SELECT … FOR UPDATE`),
- **conditional updates** (`UPDATE … WHERE state = 'expected'`),
- **append-only events** (derive state).

"Last write wins" is a strategy *only* when chosen explicitly.

---

## Step 9 — Naming

- tables: plural snake_case,
- columns: snake_case, booleans as `is_*` / `has_*`,
- foreign keys: `<referenced_table_singular>_id`,
- timestamps: `created_at`, `updated_at`, `deleted_at`,
- indexes: `ix_<table>_<columns>`; unique: `uq_…`; checks:
  `chk_…`.

Consistent naming is a forcing function for readability — fight
for it.

---

## Step 10 — Verify

Before committing the design:

- run migrations on a fresh DB end-to-end,
- benchmark the dominant queries on representative data,
- review with someone who has read the locking and indexing
  implications,
- write the migration plan (skill `database-migration`) — every
  schema change has a migration plan,
- document right-to-deletion paths for any PII columns.

---

## Forbidden

- EAV (entity-attribute-value) tables as the default model.
- One mega-table with a `type` column hosting unrelated entities.
- `JSONB` columns used to avoid making schema decisions.
- Money as `FLOAT` / `DOUBLE`.
- Timestamps without timezone.
- ORM auto-migration on production-bound branches.

---

## When this skill says STOP

- The aggregate boundary is unconfirmed → run skill
  `aggregate-boundary` first.
- The query patterns are speculative → ask the user; do not
  invent.
- The engine choice is non-default and not yet justified → write
  the ADR first.

The schema is the part of the system most likely to outlive every
other layer. Design it like the contract it is.
