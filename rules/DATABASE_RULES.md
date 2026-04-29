# Database Rules

The database is the system's center of gravity. Application code
is replaceable; data is not. These rules govern how schemas,
queries, and data access are built.

For higher-level principles, see `principles/DATA_PRINCIPLES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Pick the Right Storage for the Workload

Choose deliberately, document the choice in an ADR.

- **Relational (Postgres preferred)** — transactional workloads,
  multi-row invariants, mixed read/write, well-known shape.
- **Document (e.g. MongoDB)** — variable shape per record,
  per-document atomic writes only. Do not pretend it is
  relational.
- **Key-value (e.g. Redis, DynamoDB)** — known access keys, large
  scale, cache-like patterns, no ad-hoc query needs.
- **Time-series (e.g. ClickHouse, TimescaleDB)** — append-heavy,
  time-bucketed analytics.
- **Search (e.g. OpenSearch / Elastic)** — full-text, faceted
  search; not the system of record.
- **Object store (e.g. S3, GCS)** — blobs, files, exports.

Forbidden:

- defaulting to whatever the team used last project, without
  matching it to the workload,
- treating a single store as universally suitable.

When in doubt, default to Postgres. It is the boring, capable
choice.

---

# Schema Lives in Migrations

The schema is owned by versioned migration files in
`${projectName}-migration`. Every change goes through a migration.

Required:

- forward-only naming (`20260429_120000__add_orders_currency.sql`),
- one logical change per migration,
- migration files are immutable once merged,
- backward changes are new forward migrations,
- all migrations run end-to-end in CI on a clean DB.

Forbidden:

- editing a merged migration,
- creating tables / columns by hand in any environment,
- ORM auto-migration in production.

---

# Naming Conventions

- Tables: plural, snake_case: `orders`, `order_items`.
- Columns: snake_case: `created_at`, `customer_id`.
- Booleans: `is_*` / `has_*`: `is_paid`, `has_consent`.
- Foreign keys: `<referenced_table_singular>_id`: `customer_id`.
- Timestamps: `created_at`, `updated_at`, `deleted_at` (when
  soft-delete), all `TIMESTAMPTZ` in UTC.
- Enums: store as string + check constraint, or as a typed enum;
  not as integers without a lookup.
- Indexes: `ix_<table>_<columns>`; unique: `uq_<table>_<columns>`;
  primary: `pk_<table>`.
- Constraints: `chk_<table>_<rule>`.

Consistent naming is enforced — a one-off variation costs every
future reader.

---

# Required Columns on Every Row

Most tables benefit from:

- `id` — primary key (UUID v7 / ULID / bigint sequence).
- `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` — write-once.
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` — updated by
  trigger or app.
- `version INTEGER NOT NULL DEFAULT 0` — for optimistic locking
  on mutable rows.

Audit-grade tables additionally include `created_by`,
`updated_by`. Soft-delete tables include `deleted_at`.

Forbidden:

- timestamp columns without timezone,
- `updated_at` that the application forgets to maintain.

---

# Constraints Are Not Optional

Every invariant the domain knows MUST be enforced in the schema
when the engine supports it:

- `NOT NULL` for required fields.
- `FOREIGN KEY ... ON DELETE` (`RESTRICT` / `CASCADE` / `SET NULL`)
  with the choice deliberate, never the default by accident.
- `UNIQUE` for natural-key uniqueness.
- `CHECK` for value ranges, enum sets, format invariants.
- Partial unique indexes for "at most one active" patterns.

Application validation drifts. Schema constraints catch what code
forgets.

---

# Primary Keys

- Use UUID v7, ULID, or bigint sequence.
- Avoid v4 UUIDs for primary keys on large hot tables —
  insert locality matters.
- Never use natural keys (email, username) as primary keys.
- Composite primary keys are acceptable for true junction tables
  (`(order_id, product_id)`).

Public-facing IDs MAY be different from internal primary keys.
Where enumeration is a risk, expose opaque external IDs and keep
the internal sequence private.

---

# Indexes Are Justified

Every index has a written reason. Track in the migration body or
in a comment in the schema file:

- which query it supports,
- expected cardinality and selectivity,
- write-amplification trade-off.

Required:

- index every foreign key referenced by `JOIN` or filter,
- index columns used in `WHERE`, `ORDER BY`, `GROUP BY` for hot
  queries.

Forbidden:

- speculative "may be useful" indexes,
- duplicate / overlapping indexes,
- indexes added without an `EXPLAIN` measurement.

Periodically prune unused indexes. They cost on every write.

---

# Transactions

- Wrap every multi-row business invariant in a transaction.
- Keep transactions short — release locks fast.
- Use the right isolation level deliberately:
  - `READ COMMITTED` (Postgres default) — most workloads.
  - `REPEATABLE READ` / `SERIALIZABLE` for strong invariants;
    accept retry-on-serialization-failure.
- Never hold a transaction across a network call to a slow or
  external system.
- Cross-aggregate transactions are a smell — see skill
  `aggregate-boundary`.

Forbidden:

- transactions that span request boundaries,
- transactions opened in code with no explicit close,
- relying on auto-commit when invariants span rows.

---

# Concurrent Writes

Every row that can be written by more than one actor MUST have a
documented concurrency strategy:

- **Optimistic locking** — `version` column; `UPDATE ... WHERE
  version = :v` and bump on success.
- **Pessimistic locking** — `SELECT ... FOR UPDATE` inside a
  transaction.
- **Conditional updates** — `UPDATE ... WHERE state = 'expected'`.
- **Append-only events** — write a new event row, derive state.

"Last write wins" is a strategy only when documented and chosen.
Usually it is the bug.

---

# Avoid the ORM Trap

ORMs accelerate trivial cases and hide the expensive ones.

Required:

- the team can read and write raw SQL when needed,
- N+1 queries are detected (telemetry / lint / tests),
- generated SQL is reviewed for hot paths,
- migrations are not ORM-auto-generated in production-bound
  branches without review.

Forbidden:

- "the ORM will figure it out" performance arguments,
- lazy-loaded relations on hot paths,
- ORM features that obscure the SQL (implicit joins, magic
  proxies) used without understanding the cost.

The ORM is a productivity tool; the database is the system.

---

# N+1 Is Always a Bug

When a request issues one query plus N additional queries to
hydrate a list, the design is wrong. Resolve via:

- a single query with `JOIN`,
- a batched second query (`WHERE id IN (...)`),
- a dataloader / batched fetch in the application,
- denormalized read models.

Detect N+1 in tests for hot endpoints (assert query count).

---

# Read Patterns

- Read-your-write must work after a successful write — route the
  next read to the primary or wait for replication.
- Tolerate stale reads only where documented (analytics, lists).
- Materialize complex reads (views, summary tables, search
  indexes) when the query is hot enough to justify the cost of
  keeping it consistent.

---

# Connection Pooling and Limits

Every service that talks to the DB has bounded connections:

- per-instance pool size,
- per-service total cap (sum of replicas),
- pool waits time out and report — they do not block forever.

Use a connection pooler (e.g. PgBouncer) when many small
processes share a backend.

Forbidden: opening a connection per request, leaking connections,
or running migrations in the same pool as application traffic.

---

# Backups and Recovery

- Every database has documented RPO and RTO.
- Backups run automatically and are restored in periodic drills.
- Point-in-time recovery is configured for systems where data
  loss measured in minutes matters.
- Backups are encrypted, stored in a separate trust domain.
- Restores are tested at least quarterly.

A backup that has never been restored is a hope.

---

# PII and Sensitive Data

Every column carrying personal data:

- is tagged in the schema (column comment / catalog),
- is excluded from logs by default,
- has a documented retention policy,
- is reachable by the right-to-deletion path,
- is encrypted at column level when leakage risk warrants it.

Forbidden:

- copying production tables to developer machines,
- exporting PII to environments that lack the same protections,
- retroactively de-identifying when a real anonymization path
  exists upfront.

---

# Time, Currency, Locale

- Timestamps: `TIMESTAMPTZ`, stored UTC.
- Money: `NUMERIC(p, s)` with documented precision, or integer
  minor units, plus a `currency` column. Never `FLOAT`.
- Text: UTF-8, with collation chosen deliberately.
- Locale: store explicit locale identifiers (BCP-47); never
  format strings as the canonical form.

---

# Soft Delete vs. Hard Delete

For each table, decide explicitly:

- **Hard delete** — remove the row. Default for most tables;
  cleaner queries.
- **Soft delete** — set `deleted_at`. Use only when audit,
  recovery, or referential reasons demand it.

If soft delete is used:

- every default query filters `deleted_at IS NULL`,
- a documented job hard-deletes after retention,
- right-to-deletion paths run hard deletes regardless of
  retention.

Mixing soft and hard delete on related tables is a future bug.

---

# Schema Drift Detection

CI MUST verify:

- the live schema matches the migration set on a clean DB,
- the ORM model (when used) matches the schema,
- no migration was edited after merge.

Drift is a vulnerability: it means production is not what your
code says it is.

---

# Local Reproducibility

Every developer MUST be able to:

- spin up a clean DB locally (Docker / Testcontainers),
- run all migrations to the current head,
- seed minimum data for the test suite,
- reset to a known state in seconds.

A test suite that requires a shared cloud DB is forbidden by
default.

---

# Forbidden Anti-patterns

- "EAV" (entity-attribute-value) tables as the default model.
- One mega-table with a `type` column hosting unrelated entities.
- Denormalization without a documented justification or
  reconciliation path.
- Schema-less columns of `JSONB` used to avoid making schema
  decisions.
- Hand-edited rows in production to "fix" a bug.
- Application-side joins replacing DB-side joins for performance
  reasons that were never measured.
- Triggers used as a primary mechanism for business logic
  (acceptable for audit / `updated_at`, otherwise rare and
  documented).

---

# Prime Directive

The schema is the longest-lived artifact of the system. Design it
to be safe, queryable, evolvable, and recoverable. Optimize for
the engineer who reads this five years from now and the operator
who restores it at 3 AM.

Code is rewritten. Data must survive.
