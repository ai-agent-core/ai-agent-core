---
name: caching-strategy
description: Add or change a cache deliberately — pick the layer, define invalidation, prevent thundering herds, monitor hit rate, plan failure modes.
---

# Caching strategy

Use this skill **whenever a cache is being introduced or changed**.

Caching trades freshness for performance. Used well, it cuts
latency and cost. Used badly, it serves stale or wrong data,
hides bugs, and creates incidents that look like correctness
issues.

For performance principles, see `rules/PERFORMANCE_RULES.md`.

---

## Premise

> There are only two hard things in computer science: cache
> invalidation and naming things.
> — Phil Karlton

Treat the quote as a constraint, not a joke. Most cache problems
are invalidation problems.

---

## Step 1 — Justify the cache

Add a cache only when:

- the source-of-truth read is too slow to meet the budget,
- the data is read more than written,
- staleness can be reasoned about and bounded.

Forbidden:

- adding a cache "to be fast,"
- caching to mask an N+1 query (fix the query),
- caching to mask an unindexed read (add the index),
- caching writes without write-through coordination.

A cache below ~70% hit rate often costs more than it saves.

---

## Step 2 — Pick the layer

| Layer                | When                                                            |
| -------------------- | --------------------------------------------------------------- |
| Browser HTTP cache   | Static assets, public read-only API responses                    |
| CDN                  | Public, geographically dispersed, cacheable HTTP                 |
| Edge (Worker / KV)   | Per-region small reads, near-user                                |
| Application memory   | Per-instance, hot loops, immutable / quasi-immutable data        |
| Distributed cache    | Cross-instance shared (Redis, Memcached, DynamoDB, Hazelcast)    |
| Database query cache | Plan + result reuse; engine-managed                              |
| Materialized views   | Expensive joins / aggregations refreshed on schedule or event    |

A cache at the wrong layer either misses by sharing too narrowly
(per-instance for cross-instance data) or invalidates too broadly
(CDN for per-user data).

---

## Step 3 — Pick the invalidation strategy

### TTL (time-to-live)

- value expires after a fixed period,
- simplest; eventually consistent within the TTL,
- pick TTL deliberately — short for volatile data, longer for
  stable.

### Write-through

- writes update the cache and the source,
- consistent if both succeed; partial failure modes documented,
- additional latency on writes.

### Write-behind / write-back

- writes hit the cache; flushed asynchronously,
- low write latency, risk of loss on crash,
- only when the system can tolerate that loss.

### Cache-aside (lazy)

- reads check the cache first; on miss, load from source and
  populate,
- writes update the source and **invalidate** the cache (or set
  the new value),
- the most common pattern; explicit invalidation discipline
  required.

### Versioned key

- cache key includes a version that bumps on change,
- "invalidation" = use a new key; old keys age out,
- avoids the explicit-invalidate problem.

Pick one strategy per cache use case. Document it.

---

## Step 4 — Define key shape

- include all dimensions that matter for the result (tenant, user,
  language, currency, version),
- avoid keys that are too granular (cardinality explosion) or too
  coarse (cross-tenant data leak),
- include a version / namespace so a future invalidation is
  cheap (`v3:user:42:profile`),
- never include PII in keys that get logged.

Forbidden:

- per-user keys without tenant in multi-tenant systems,
- key shapes that share data between users / tenants who must
  not share.

---

## Step 5 — Prevent thundering herds

When a hot key expires, many requests miss simultaneously and
stampede the source.

Mitigations:

- **single-flight / request coalescing** — one request to the
  source per key per stampede; others wait for its result,
- **probabilistic early expiration** — refresh just before
  expiry,
- **stale-while-revalidate** — serve the stale value briefly
  while a background fetch refreshes,
- **jittered TTLs** — avoid synchronized expiry across keys.

A cache without thundering-herd protection is a cache that
amplifies the next outage.

---

## Step 6 — Bound resource usage

- bounded memory,
- defined eviction policy (LRU / LFU / TTL / size-based),
- per-key size limits,
- monitoring of evictions (high eviction rate = under-sized),
- circuit breaker for cache backend failures (do not stall the
  application when the cache is down).

A cache that grows without bound is a future OOM.

---

## Step 7 — Failure modes

What happens when the cache backend is unreachable?

- option A: **bypass** to the source (slower but correct);
  default,
- option B: **return error** (when the source cannot handle the
  load),
- option C: **return stale** (when freshness is not critical).

Document the choice. Verify behavior in test by killing the
cache.

Forbidden:

- a cache outage that takes down the application by default,
- silent fallback that masks the cache outage from monitoring.

---

## Step 8 — Consistency model

State explicitly what the cache promises:

- **strong consistency** — read after write returns the new
  value; rare and expensive,
- **read-your-write** — the writer sees their own update; common
  with cache invalidation on write,
- **bounded staleness** — at most N seconds out of date,
- **eventual consistency** — converges; no time bound.

If the consumer needs read-your-write, the cache strategy must
support it (write-through, or invalidate-on-write with the same
client routed to the source until propagation).

---

## Step 9 — Multi-tenant and security

- include tenant in every key,
- enforce tenant scope at the cache lookup layer (not just
  application code),
- avoid caching personally identifiable data unnecessarily,
- redact / minimize what is stored,
- treat the cache as production data — encryption, access
  control, retention.

A cross-tenant cache leak is a serious incident class.

---

## Step 10 — Observability

For each cache:

- **hit rate**, **miss rate**, **eviction rate**,
- **size**, **memory used**,
- **latency** (cache, miss-to-source),
- **error rate** to the cache backend,
- alerts on hit-rate collapse (often the first sign of a wrong
  invalidation),
- per-key cardinality (sample) to catch explosions.

If you cannot tell whether the cache helps, it is decoration.

---

## Step 11 — Tests

- cold cache: source is hit, cache is populated,
- warm cache: source is not hit on repeat,
- after invalidation: source is hit again,
- backend down: behavior matches the documented failure mode,
- thundering herd: under load with key expiry, the source is
  protected (single-flight works),
- security: tenant isolation holds.

A cache untested in these scenarios will surprise you in
production.

---

## Forbidden

- caches added without invalidation strategy,
- caches whose hit rate is unmonitored,
- caching to hide a missing index,
- caching writes without coordination,
- "we cache forever and update if we remember,"
- shared caches across tenants without explicit isolation,
- application-level caches in stateless services that defeat
  load balancing.

---

## When this skill says STOP

- the invalidation strategy cannot be stated → do not ship,
- there is no monitoring of hit rate → add before launch,
- the cache holds PII without justification → remove or
  anonymize.

A good cache is invisible: it cuts latency and cost, never
serves wrong data, fails open when the backend is down, and is
removable without breaking the system.

If the system depends on the cache being correct, the cache is
not a cache; it is a database.
