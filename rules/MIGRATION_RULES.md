# Migration Rules

These rules govern *both* schema migrations and large-scale system
migrations (legacy → new system, on-prem → cloud, monolith →
service split, store-A → store-B).

The unifying principle: **migrations are reversible until proven
otherwise**, and proven otherwise only on the smallest possible
scope.

For the data-layer principles behind these rules, see
`principles/DATA_PRINCIPLES.md`. For the operational stance, see
`principles/OPERATIONAL_PRINCIPLES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Migration Categories

Treat each category with the discipline its blast radius demands.

1. **Schema migration** — DDL changes within a single database.
2. **Data migration** — moving / transforming rows within or
   between datastores.
3. **System migration** — replacing or absorbing a running system
   (legacy app retirement, vendor swap, datacenter move).
4. **Code migration** — changing framework, language, runtime
   while keeping behavior.

Different categories share the same playbook: **expand → migrate
→ contract**, with monitoring and reversibility at each step.

---

# Expand → Migrate → Contract (Universal)

Three phases, never compressed:

1. **Expand** — add the new shape (column, table, index, endpoint,
   queue, system) alongside the old. Old code keeps working,
   nothing has been deleted, traffic still flows the old way.
2. **Migrate** — backfill, dual-write, dual-read, gradually shift
   traffic. Compare old and new. Validate before continuing.
3. **Contract** — once all consumers have moved and a soak period
   has passed, remove the old shape.

Skipping the soak period is the canonical way to learn what
silent traffic was using the old path.

---

# Schema Migrations: Online Discipline

Schema changes that touch live tables MUST be designed not to
block production:

- **Add column** — `NULL` or with a cheap default first; backfill
  in batches; switch to `NOT NULL` after.
- **Drop column** — stop reading first, stop writing second, drop
  third. Verify in logs that no caller still references it
  before drop.
- **Rename** — never rename in place. Add new, dual-write, switch
  reads, drop old.
- **Change type** — add new column, dual-write with conversion,
  cut over reads, drop old.
- **Add index** — use `CREATE INDEX CONCURRENTLY` (Postgres) or
  the engine equivalent; never block writes.
- **Add foreign key** — add `NOT VALID` first; backfill / clean;
  `VALIDATE CONSTRAINT` second.
- **Add unique constraint** — build the index concurrently first,
  then attach.

Forbidden in a single migration:

- DDL statements that take long table-level locks on hot tables,
- destructive changes (drops, renames-in-place) without a
  documented multi-phase plan,
- migrations whose duration is unknown.

Migrations are reviewed by someone who has read the locking
implications, not by autopilot.

---

# Backfill Discipline

Backfilling existing rows MUST:

- run in bounded batches (size and rate),
- be resumable (checkpoint after each batch),
- tolerate concurrent writes to the same rows,
- log progress and ETA,
- run in a long-running job, not a single transaction.

Forbidden:

- `UPDATE … (entire table)` as a single statement on production,
- backfills with no progress visibility,
- backfills that double-count when restarted.

A million-row backfill that fails halfway and cannot resume is the
most common cause of incident-during-migration.

---

# Dual-Write and Dual-Read

When migrating between two systems / two columns / two tables:

1. Start writing to both (dual-write). Old is authoritative.
2. Compare reads from both for a soak period. Investigate every
   discrepancy.
3. Flip authority to new (still writing both). Reads from new.
4. Stop dual-write once new is the source of truth and the soak
   period has elapsed without discrepancy.
5. Remove the old surface.

Required mechanisms:

- shadow-read comparison or sampled diff job,
- monitoring on dual-write success rate,
- rollback path at every step.

Common failure: the comparison code has bugs, "no discrepancies"
means the comparator is silently broken. Test the comparator
itself.

---

# Online Migration Tooling

For high-write tables, prefer purpose-built tools:

- `pg_repack`, `pt-online-schema-change`, `gh-ost`, `Spirit` —
  online table rewrites,
- logical replication / change-data-capture for cross-system
  moves,
- streaming pipelines (Debezium, Kafka Connect) for large data
  moves.

Hand-rolled migrations of large hot tables are forbidden by
default; the failure modes are well known and the tools exist.

---

# Reversibility Plan Is Mandatory

Every non-trivial migration ships with a written rollback plan:

- the trigger conditions for rollback (data discrepancy, error
  budget burn, operator judgement),
- the exact steps to reverse each phase,
- the maximum data loss tolerated by rollback,
- the time-to-rollback expected.

If the plan reads "we cannot roll back," the migration is not
ready. Either pre-stage rollback artifacts or escalate.

---

# Dry Run Before Production

Every production migration MUST have run end-to-end against a
representative dataset:

- staging with production-shape data (size and skew matter),
- timing measured,
- locks observed,
- failure injection (kill mid-backfill, restart),
- rollback rehearsed.

"It worked on the dev DB" is not evidence. Dev DBs are toys.

---

# Communication Plan

Production migrations affect operators, on-call, support, and
sometimes customers. Required:

- pre-announcement to the on-call rotation,
- a runbook (start / monitor / rollback),
- explicit go/no-go criteria,
- post-migration verification checklist,
- summary written within one business day after completion.

Silent migrations cause silent outages.

---

# Legacy System Migration: Strangler Fig

Replacing a running legacy system follows the **strangler fig**
pattern, never a flag-day cutover:

1. Place a façade in front of the legacy system (proxy, router,
   gateway).
2. Identify a small, well-bounded slice (one endpoint, one
   feature, one tenant).
3. Reimplement that slice in the new system. Route traffic for
   that slice via the façade. Compare results.
4. Cut over the slice when the new implementation is at parity.
5. Repeat slice by slice. Legacy shrinks.
6. Retire legacy when nothing routes to it.

Required:

- shadow / mirror traffic for new slices before cutover,
- a comparator that flags behavioral diffs,
- ability to flip back per slice.

Forbidden:

- "we'll migrate everything in one weekend,"
- removing the legacy code path before traffic actually drops to
  zero,
- rebuilding without parity tests.

See skill `legacy-migration` for the operational playbook.

---

# Anti-corruption Layer

When integrating with a legacy or external system whose model is
incompatible:

- introduce an **anti-corruption layer** (ACL) that translates
  between the new domain language and the foreign model,
- the ACL is the only place that knows the legacy model,
- the rest of the system speaks the new language only.

Forbidden:

- letting legacy types leak into the new domain,
- "temporarily" using the legacy field names in the new code.

The ACL is permanent until the foreign system is retired.

---

# Data Migration Verification

Every data migration ends with verifiable parity:

- row counts match (with documented expected diff),
- key invariants hold (sums, balances, referential integrity),
- sample compare on critical fields,
- spot-check on the longest tail (oldest / newest / largest /
  edge cases).

A migration with no verification step is not finished.

---

# Forbidden Anti-patterns

- "Big-bang" cutover without a tested rollback.
- Editing migrations that have already been applied to any shared
  environment.
- Backfills without batching, monitoring, or resumability.
- Dropping columns the same day the code stops referencing them.
- Migrations that depend on application code being deployed
  *exactly* simultaneously (unsafe ordering).
- Production-only "fix-up" SQL run by hand without record.
- Renaming in place on production tables.
- Stopping dual-write before the soak period concluded.
- Skipping the dry run because the team is confident.

---

# Prime Directive

A migration that succeeds is invisible to users.

A migration that fails reveals the rollback plan and the
monitoring you put in place. Design assuming you will need both.
