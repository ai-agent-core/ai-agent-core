---
name: database-migration
description: Plan and execute a schema or data migration safely — expand, migrate, contract — with reversibility, monitoring, and dry runs.
---

# Database migration

Use this skill **whenever a schema change or data migration
touches a non-empty production-bound table**.

Authoritative source: `rules/MIGRATION_RULES.md` and
`principles/DATA_PRINCIPLES.md`.

For systemic migrations (legacy retirement, vendor swap), see
skill `legacy-migration`.

---

## Step 1 — Classify the change

| Change                                | Risk                  |
| ------------------------------------- | --------------------- |
| Add nullable column                   | Low                   |
| Add `NOT NULL` column with default    | Medium                |
| Backfill                              | Medium → High         |
| Add index                             | Medium                |
| Add foreign key                       | Medium                |
| Change column type                    | High                  |
| Rename column                         | High                  |
| Drop column                           | High                  |
| Rewrite primary key                   | Very high             |

For anything Medium or higher, follow the full **expand → migrate
→ contract** loop.

---

## Step 2 — Expand → Migrate → Contract

Three phases, never compressed.

### Expand
Add the new shape (new column, new table, new index) without
breaking the old. Old code keeps working.

Examples:
- `ALTER TABLE orders ADD COLUMN currency_v2 TEXT;` (NULLable
  initially).
- `CREATE INDEX CONCURRENTLY ix_orders_status_created_at ON ...;`
- New table alongside an old one.

### Migrate
- Deploy code that writes both shapes.
- Backfill existing rows in batches.
- Deploy code that reads the new shape (with fallback).
- Compare old vs. new for a soak period.

### Contract
- Remove the old shape only after:
  - all writers updated,
  - all readers updated,
  - soak period completed without discrepancies,
  - logs / metrics show zero traffic to the old surface.

Skipping a phase is the canonical "we deployed and the site went
down" cause.

---

## Step 3 — Online operations

Schema changes that touch live tables MUST avoid blocking writes:

- **Add column**: NULL or with a cheap default; backfill in
  batches; switch to NOT NULL after.
- **Drop column**: stop reading first, stop writing second, drop
  third. Verify no caller still references it before drop.
- **Rename**: never rename in place. Add new, dual-write, switch
  reads, drop old.
- **Change type**: add new column, dual-write with conversion,
  cut over, drop old.
- **Add index**: `CREATE INDEX CONCURRENTLY` (Postgres). Never
  block writes.
- **Add foreign key**: `NOT VALID` first; backfill / clean;
  `VALIDATE CONSTRAINT` second.
- **Add unique constraint**: build the index concurrently first,
  then attach.

For high-write tables prefer purpose-built tools (`pg_repack`,
`pt-online-schema-change`, `gh-ost`) over hand-rolled DDL.

---

## Step 4 — Backfill discipline

Backfilling existing rows MUST:

- run in bounded batches (size and rate),
- be resumable (checkpoint after each batch),
- tolerate concurrent writes,
- log progress and ETA,
- run as a long-running job, not one big transaction.

Forbidden:

- `UPDATE ... (entire table)` in a single statement.
- Backfills with no progress visibility.
- Backfills that double-count when restarted.

Pseudocode:

```
loop:
  rows = SELECT id FROM t
         WHERE needs_backfill = true
         ORDER BY id LIMIT batch_size FOR UPDATE SKIP LOCKED
  if empty: break
  for r in rows:
    UPDATE t SET ... WHERE id = r.id
  COMMIT
  sleep(throttle)
```

---

## Step 5 — Reversibility plan

Every non-trivial migration ships with a written rollback plan:

- triggers for rollback (data discrepancy, error budget burn,
  operator judgement),
- exact reversal steps per phase,
- maximum data loss tolerated,
- expected time-to-rollback.

If the plan reads "we cannot roll back," the migration is not
ready.

---

## Step 6 — Dry run

Every production migration MUST have run end-to-end against a
representative dataset:

- staging with prod-shape data (size and skew matter),
- timing measured,
- locks observed,
- failure injection (kill mid-backfill, restart),
- rollback rehearsed.

"It worked on a dev DB" is not evidence.

---

## Step 7 — Communication

- pre-announce to the on-call rotation,
- runbook (start / monitor / rollback) committed,
- explicit go / no-go criteria,
- post-migration verification checklist,
- summary written within one business day after completion.

Silent migrations cause silent outages.

---

## Step 8 — Verification

End every migration with parity:

- row counts match (with documented expected diffs),
- key invariants hold (sums, balances, referential integrity),
- spot checks on the longest tail (oldest, newest, edge cases),
- monitoring shows the new path serving traffic without errors.

A migration with no verification step is not finished.

---

## Forbidden

- "Big bang" cutover without tested rollback.
- Editing a migration after it has been applied to any shared
  environment.
- Backfills without batching, monitoring, or resumability.
- Dropping a column the same day code stops referencing it.
- Renaming a column in place.
- Stopping dual-write before the soak period concluded.
- Production-only "fix-up" SQL run by hand without record.

---

## When this skill says STOP

- The reversibility plan reads "we cannot roll back" → escalate.
- The dry run revealed unbounded duration → redesign.
- Monitoring / observability are not in place → fix first; you
  cannot operate what you cannot see.

A migration that succeeds is invisible to users. A migration that
fails reveals the rollback plan and the monitoring you put in
place. Design assuming you will need both.
