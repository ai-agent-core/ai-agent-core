# Performance Rules

Performance is a feature with budgets, not a heroic optimization
phase at the end. These rules define how performance is designed
in, measured, and protected.

For the operational stance, see
`principles/OPERATIONAL_PRINCIPLES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Budgets, Not Vibes

Every user-facing surface has explicit budgets, agreed upfront:

- frontend page: TTFB, LCP, INP, total JS bundle, total network
  bytes.
- backend endpoint: p50, p95, p99 latency; max error rate.
- background job: max wall-clock duration; throughput floor.
- database query: max ms on hot path; max rows examined.

Budgets are written in the spec. CI fails when a change blows the
budget. Performance regressions are reverted, not "investigated
later."

Forbidden:

- "as fast as possible" as a target,
- shipping without a budget on a user-facing path,
- unbounded operations on hot paths.

---

# Measure First, Optimize Second

No optimization without:

1. a reproducible benchmark or a profile,
2. a documented hypothesis,
3. a measured before / after delta.

Forbidden:

- guessing the bottleneck,
- "this should be faster" as a justification,
- micro-optimizations on cold paths.

The 10% of code that runs 90% of the time is where effort
belongs. Profile first, change second.

---

# Frontend Budgets (Web)

Default targets for an interactive page:

- LCP (Largest Contentful Paint) < 2.5s on a mid-tier device on
  a 4G network,
- INP (Interaction to Next Paint) < 200ms,
- CLS (Cumulative Layout Shift) < 0.1,
- TBT (Total Blocking Time) < 200ms,
- main bundle (gzipped) < 200KB for the first route, < 50KB
  per code-split chunk,
- third-party JS budget: < 100KB total (analytics, A/B,
  error reporting, fonts) — measured.

Critical-path resources MUST be:

- on the same origin or preconnected,
- minified, compressed (Brotli / gzip),
- HTTP/2 or HTTP/3,
- cacheable with sensible TTLs and immutable hashing.

Forbidden:

- shipping unused libraries,
- blocking script tags above the fold,
- web fonts loaded with no `font-display` strategy,
- large hero images served unoptimized (no responsive `srcset`,
  no AVIF / WebP, no compression).

---

# Backend Latency Budgets

For an interactive HTTP endpoint:

- p50 < 100ms,
- p95 < 300ms,
- p99 < 1s,

with budgets adjusted per route based on its place in the user
journey. Aggressive endpoints (search, autocomplete) have
tighter budgets.

Hot paths MUST:

- avoid synchronous blocking I/O,
- avoid N+1 queries,
- never call external APIs serially when they can be batched or
  parallelized,
- never hold long-lived locks.

p99 matters: it is what users complain about. p50 is for
dashboards.

---

# Database Performance

- Every query on a hot path has been EXPLAINed.
- Required indexes are present (see `rules/DATABASE_RULES.md`).
- Reads tolerate stale data only when documented.
- Long-running analytical queries do not run on the OLTP
  primary; they run on a replica or a warehouse.
- The connection pool is sized; saturation alerts exist.
- Common slow patterns (full scans on large tables, missing
  index scans) trigger alerts in production telemetry.

Forbidden:

- ORM-generated SQL on hot paths without review,
- application-side `JOIN` (load-and-merge) replacing a
  database `JOIN` without a measured reason.

---

# Caching

Cache only when:

- the source-of-truth read is too slow to meet the budget,
- the data is read more than written,
- staleness can be reasoned about and bounded.

Required:

- documented invalidation strategy (TTL, write-through, explicit
  invalidation, versioned key),
- cache hit-rate metric — a cache below ~70% hit rate often
  costs more than it saves,
- single-flight (request coalescing) for expensive cache misses
  to prevent thundering herds,
- bounded memory and eviction policy.

See skill `caching-strategy`.

Forbidden:

- caches that hide stale data behind unrelated TTLs,
- caches whose invalidation is undocumented,
- "we cache forever and update if we remember."

---

# Concurrency Limits

Every component that consumes a finite resource MUST have a
bounded concurrency:

- HTTP handler thread pools / worker counts,
- database connection pools,
- outbound HTTP client connection pools,
- queue worker counts.

Saturation triggers backpressure (429 / queue full / shed load),
not unbounded resource growth.

Forbidden:

- unbounded `Promise.all` / `goroutine` fan-out from a request,
- unbounded retries that amplify the load that caused the
  failure,
- async fire-and-forget without a queue, timeout, or budget.

---

# Timeouts and Retries

Every external call has:

- a connect timeout,
- a read timeout,
- a total deadline propagated from the caller,
- a retry policy with bounded attempts and jittered backoff,
- a circuit breaker (or equivalent) that opens on sustained
  failure.

Defaults: aggressive timeouts (single-digit seconds, often
sub-second on the user path). The wrong timeout is "no timeout."

Forbidden:

- retry storms (no backoff, no jitter, no cap),
- retries on non-idempotent operations without idempotency keys,
- "default" library timeouts left unset.

---

# Bulk and Batch Operations

For any operation that processes more than one row:

- batch size is bounded and documented,
- progress is checkpoint-able and resumable,
- commit cadence is explicit (per N rows / per batch),
- failure isolation: one bad row does not fail the whole batch
  unless that is the documented intent.

Forbidden:

- "load all rows into memory" defaults,
- single transactions over millions of rows,
- batch jobs with no progress reporting.

---

# Streaming and Pagination

Long-result reads MUST be streamed or paginated:

- API list endpoints paginate (see
  `rules/API_DESIGN_RULES.md`),
- DB cursor / chunked iteration for large reads,
- streaming responses (chunked, SSE, NDJSON) where appropriate.

Forbidden defaults: serializing a million-row result into a
single JSON response.

---

# Asynchronous Work

Any work that is not strictly required for the response MUST move
to async:

- email / notification dispatch,
- heavy reporting,
- cache warm-ups,
- third-party syncs.

The async path has its own budget, retries, and dead-letter
behavior. Async is not "fire and forget." See skill
`event-driven`.

---

# Load Testing

Before launch and before major changes, run load tests with:

- realistic traffic shape (warm-up, steady-state, burst),
- realistic data (production shape, anonymized),
- realistic upstream latency,
- saturation scenarios (DB pool exhausted, cache cold,
  one dependency failing).

A load test that only tests the happy path is decoration.

Document expected behavior under load: which queues fill, where
backpressure shows up, how recovery happens.

---

# Capacity Planning

For each service:

- known requests-per-second per instance,
- baseline cost per request,
- documented saturation point,
- documented headroom (e.g. "we run at 30% of saturation").

When a load profile changes (new feature, growth, sale event),
re-run the math and re-plan.

Forbidden:

- "we have autoscaling, so capacity is solved" — autoscaling
  hides cost spikes, not failures of the failure modes
  autoscaling cannot solve (DB connection limits, third-party
  rate limits, cold cache).

---

# Memory and Resources

- Long-running services have bounded heap / RSS targets.
- Memory leaks are detected (steady growth on a stable workload
  triggers an investigation).
- File descriptors, sockets, and other limits are monitored.
- Goroutines / threads / promises in flight are bounded and
  observable.

A process that runs out of memory after 18 hours is not a
production-ready service.

---

# Mobile and Constrained Environments

If the system serves mobile clients:

- payloads are compact (avoid sending data the client never
  uses),
- clients tolerate slow networks (timeouts, retries, offline
  modes),
- versioning allows older clients to keep working,
- battery and bandwidth are first-class budgets.

The 90th percentile mobile user is on a flaky 4G connection on a
two-year-old phone. Build for them, not for the developer's
laptop.

---

# Forbidden Anti-patterns

- "Premature optimization is the root of all evil" used as a
  shield against any performance work.
- "It is fine on my machine."
- Caches added without invalidation.
- Indexes added without measurement.
- Concurrency added without bounds.
- Timeouts left at the framework default.
- Retries without backoff.
- Performance regressions accepted because the test suite passed.

---

# Prime Directive

Performance is a property of the design, not a postscript.
Establish the budget, measure against it, and treat regressions
as bugs. Optimize the path that matters, leave the rest alone.

A fast system is the second-best feature. The best is a fast
system whose speed is intentional.
