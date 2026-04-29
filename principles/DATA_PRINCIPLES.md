# Data Principles

Data outlives code.

Application code is rewritten. Frameworks are replaced. Schemas
endure. Data persists across releases, across rewrites, often
across companies. Agents MUST treat data design with discipline
proportional to its lifespan, not to the urgency of the feature
that introduced it.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Schema Is a Public API

Every table, column, and index is a contract with every consumer:
the application, future migrations, BI tools, downstream systems.

- Renaming a column breaks consumers you may not know about.
- Type changes propagate.
- "Just drop it" is rarely cheap.

Treat schema with the same rigor as a public HTTP API. Add things
deliberately; remove things slowly.

---

# Migrations Are the Source of Truth

The schema lives in versioned, append-only migrations. Not in:

- the running database,
- a `schema.sql` snapshot maintained by hand,
- the ORM's introspection at boot.

Required properties:

- Migrations are forward-only in production. Backward steps are
  new forward migrations.
- Migrations are deterministic (no `NOW()` baked into a default
  column for reproducibility-sensitive defaults; explicit values).
- Migrations are reproducible from empty: anyone can recreate the
  schema by running them in order.
- Migrations are reviewed in PRs alongside the code that needs
  them.

If the production DB drifted from migrations, the next deploy is a
gamble.

---

# Expand, Migrate, Contract

Schema changes that touch live tables MUST follow expand → migrate
→ contract:

1. **Expand** — add the new shape (new column, new table, new
   index) in a non-breaking way. Old code keeps working.
2. **Migrate** — backfill data, deploy code that reads/writes the
   new shape, run dual-write if needed.
3. **Contract** — once all consumers have moved, remove the old
   shape.

Skipping a phase is the canonical cause of "we deployed and the
site went down."

---

# Money Is Not a Float

Monetary values MUST be stored as integers in the smallest unit of
the currency (e.g. minor-units / cents / 銭), or as fixed-point
decimals (`NUMERIC(p, s)` with documented precision). Never as
floating point.

The currency code is part of the value. A column called `amount`
without a `currency` column is a bug waiting to happen.

See `rules/MONEY_HANDLING_RULES.md` for the full set of money
rules.

---

# Time Is UTC, Stored as Timestamp-with-Timezone

Persistent timestamps MUST be:

- stored in UTC,
- typed as timestamp-with-timezone (`TIMESTAMPTZ`, `DateTime<Utc>`,
  `Instant`),
- never as strings,
- never as "local time of whoever inserted it."

Display-time is a presentation concern; persistence is UTC. A
`created_at` with no timezone is a future bug.

---

# Identifiers Are Stable

Primary keys MUST be:

- immutable (changing them breaks every reference),
- meaningful only as identifiers (not "this also encodes status"),
- chosen to match the system's needs:
  - **UUID v7** / ULID — distributed generation, time-orderable.
  - **Bigint sequence** — single-writer, dense, sortable.
  - Avoid v4 UUIDs for primary keys on large tables when ordering
    matters; locality of insert hurts under load.

Natural keys (email, username, SKU) MUST NOT be primary keys.
They change. Use them as unique constraints, not as the identity.

---

# Constraints Are Documentation Plus Enforcement

Every invariant the domain requires MUST be enforced at the
schema level when the database supports it:

- `NOT NULL` for fields that are never optional.
- Foreign keys for references that must hold.
- `CHECK` constraints for value ranges and enumerated states.
- `UNIQUE` constraints for natural-key uniqueness.

Application-only validation drifts. The schema is the last
defense.

When a domain invariant cannot be expressed as a constraint,
document it in a comment on the column / table.

---

# Normalize Until It Hurts, Denormalize Until It Works

Default to third normal form. Denormalize only when:

- a measured access pattern justifies it,
- the duplicated data has a documented authoritative source,
- a mechanism exists to re-derive the duplicate (event, trigger,
  scheduled job).

Premature denormalization is the most common reason for
inconsistencies that cannot be reconciled later.

---

# Indexes Are Not Free

Indexes accelerate reads at the cost of writes, storage, and
buffer pool. For each index, justify:

- the query it accelerates,
- expected hit rate,
- write amplification,
- whether a partial / covering / multi-column index is more
  appropriate.

Forbidden by default:

- "Just add an index on every foreign key."
- Indexes added without query plans.
- Duplicate indexes (multiple indexes that cover the same prefix).

Periodically prune unused indexes. They cost on every write.

---

# Transactions Encode Invariants

Transactions are not "wrap everything just in case." They are the
atomic unit of an invariant.

- Every business invariant that spans multiple rows must be
  enforced inside a single transaction.
- Transactions should be short. Long transactions hold locks and
  amplify contention.
- Cross-aggregate transactions are a smell — see skill
  `aggregate-boundary`. Prefer eventual consistency between
  aggregates with explicit reconciliation.

Set isolation levels deliberately. The default of your DB is not
necessarily the right one for your invariant.

---

# Concurrent Writes Need a Strategy

For any row that can be written by more than one actor, choose a
strategy and document it:

- **Optimistic locking** with a `version` column.
- **Pessimistic locking** with `SELECT … FOR UPDATE`.
- **Conditional updates** (`UPDATE … WHERE state = 'expected'`).
- **CRDTs** when truly concurrent and commutative.

"Last write wins" is a strategy *only* when documented and
understood. Often it is the bug.

---

# Soft Delete and Hard Delete Are Different Decisions

For each resource decide:

- whether to soft-delete (mark `deleted_at`) or hard-delete,
- the retention period before hard delete,
- which queries see soft-deleted rows (default: none),
- the audit trail for the deletion.

Soft delete is not free: it complicates every query. Use it where
recovery, audit, or referential integrity demands it. Use hard
delete elsewhere — and respect right-to-deletion regimes.

---

# Backups Are Not Backups Until Restored

A backup that has never been restored is a hope, not a backup.

- Restore drills run on a schedule (at least quarterly).
- RPO (recovery point objective) and RTO (recovery time objective)
  are documented per dataset.
- Backups are encrypted, stored in a separate trust domain, and
  retained on a documented schedule.
- Point-in-time recovery is configured for systems where data
  loss measured in minutes matters.

Operational survival depends on the answer to "can we restore?",
not "are we backing up?"

---

# Read Replicas Are Not Free Throughput

Read replicas trade replication lag for read capacity. The
trade-off MUST be explicit:

- Which reads tolerate stale data (analytics, lists).
- Which reads must be consistent (post-write read, balance check).
- How replica lag is measured and alerted.
- The fallback when a replica is too far behind.

A replica without lag monitoring is a future user-visible
inconsistency.

---

# Cross-System Consistency Is a Choice

When more than one system stores related state (e.g. DB +
search index + cache + analytics warehouse + payment provider),
consistency is not automatic.

Choose deliberately:

- **Outbox pattern** — write the event in the same transaction as
  the state change; deliver asynchronously.
- **Change data capture** — stream commits to downstream systems.
- **Saga / process manager** — coordinate multi-step business
  transactions with compensation.
- **Two-phase commit** — almost never; it costs more than people
  expect.

Whichever you pick, write it down in an ADR. The "how" of
cross-system consistency tends to be invisible to readers six
months later, until it breaks.

---

# Analytics Is Not the System of Record

The data warehouse is a derived store. The OLTP database is the
system of record. Do not let analytics queries dictate OLTP
schema, and do not let OLTP downtime stem from BI workloads.

Replicate, transform, and let the warehouse own its own shape.

---

# PII Is Tracked, Tagged, and Limited

Every column carrying personal data MUST be:

- tagged in metadata (column comment, data catalog),
- listed in the privacy inventory,
- subject to the right-to-deletion path,
- excluded from logs and analytics by default.

Forbidden: copying a production table to a developer laptop.
Anonymized snapshots only.

---

# Prime Directive

Design schemas, transactions, and data flows for the engineer who
will inherit this system in five years, after three rewrites of
the application code. The schema is the part most likely to
survive — protect it accordingly.

Application code is a tactic. Data is the system.
