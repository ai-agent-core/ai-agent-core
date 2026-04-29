---
name: performance-budget
description: Set explicit performance budgets, measure against them, fail CI on regression. Optimize the path that matters; leave the rest alone.
---

# Performance budget

Use this skill **whenever a performance-sensitive surface is being
designed, shipped, or audited** — a user-facing page, an
interactive endpoint, a hot service path, a background job that
must finish in a window.

Authoritative source: `rules/PERFORMANCE_RULES.md` and
`principles/OPERATIONAL_PRINCIPLES.md`.

---

## Premise

> Budgets, not vibes.

Performance is a feature with explicit numerical targets. Without
budgets:

- nobody owns the regression that crept in,
- "as fast as possible" is impossible to verify,
- effort goes into micro-optimizations that do not move user
  experience.

---

## Step 1 — Set the budget

For each performance-sensitive surface, set a budget in the spec
*before* implementation:

### Frontend (web page)

| Metric                                | Default target              |
| ------------------------------------- | --------------------------- |
| LCP (Largest Contentful Paint)        | < 2.5s on mid-tier 4G       |
| INP (Interaction to Next Paint)       | < 200ms                     |
| CLS (Cumulative Layout Shift)         | < 0.1                       |
| TBT (Total Blocking Time)             | < 200ms                     |
| Initial JS bundle (gzipped)           | < 200KB                     |
| Per-route code-split chunk (gzipped)  | < 50KB                      |
| Third-party JS                        | < 100KB total               |
| Critical CSS                          | inlined, < 14KB             |

Tighten for low-end markets / mobile-first products.

### Backend (interactive endpoint)

| Metric         | Default target |
| -------------- | -------------- |
| p50 latency    | < 100ms        |
| p95 latency    | < 300ms        |
| p99 latency    | < 1s           |
| Error rate     | < 0.1% (route- and SLO-dependent) |

Tighter targets for autocomplete / search; looser for read-mostly
endpoints with caching.

### Background job

- max wall-clock duration,
- min throughput,
- max queue lag.

### Database query (hot path)

- max ms in production p99,
- max rows examined,
- index used (verified by `EXPLAIN`).

Adjust per route based on its place in the user journey.

---

## Step 2 — Verify the budget can be measured

Budget without measurement is decoration. For each metric, ensure
the pipeline can:

- collect it in production (Real User Monitoring + APM),
- collect it in CI (synthetic perf test),
- alert on regression (CI gate or production burn-rate alert),
- attribute it to the change that caused it (deploy correlation).

If the metric cannot be measured, pick a different metric — or
build the measurement first.

---

## Step 3 — Profile, do not guess

No optimization without:

1. a reproducible benchmark or a profile,
2. a documented hypothesis,
3. a measured before / after delta.

Forbidden:

- "this should be faster" as justification,
- micro-optimizations on cold paths,
- tightening allocations on a path that spends 90% of its time
  in I/O,
- changes to "make it faster" without numbers.

The 10% of code that runs 90% of the time is where effort
belongs.

---

## Step 4 — Frontend optimization checklist

Before optimizing, audit:

- **Network** — TTFB, HTTP version (HTTP/2 or HTTP/3),
  preconnect/preload of critical resources, fonts loaded with
  `font-display`.
- **JavaScript** — bundle size, unused code, tree-shaken,
  code-split per route, third-party scripts kept tight.
- **Images** — responsive `srcset`, modern formats (AVIF / WebP),
  proper compression, dimensions specified to prevent CLS.
- **CSS** — critical CSS inlined, render-blocking minimized.
- **Fonts** — limited families and weights, subset, swap or
  optional display.
- **Caching** — sensible TTLs, immutable hashed assets, service
  worker if appropriate.

Optimization order: cut, defer, parallelize. The cheapest byte is
the one not sent.

---

## Step 5 — Backend optimization checklist

Before optimizing, audit:

- **Database** — every query on the hot path EXPLAINed, indexes
  in place, no N+1 (skill `database-design`).
- **Concurrency** — bounded pools, no synchronous blocking I/O
  on hot paths, parallelizable work parallelized.
- **External calls** — batched, parallelized where possible,
  bounded timeouts and retries with backoff.
- **Caching** — added only with documented invalidation (skill
  `caching-strategy`).
- **Serialization** — JSON / proto / msgpack chosen
  deliberately, not "default."
- **Hot-path allocations** — measured, reduced if profile points
  here.

---

## Step 6 — Bound concurrency

Every component consuming a finite resource MUST have bounded
concurrency:

- HTTP handler thread pools / worker counts,
- database connection pools,
- outbound HTTP client connection pools,
- queue worker counts,
- per-request fan-out (no unbounded `Promise.all`).

Saturation triggers backpressure (429 / queue full / shed load),
not unbounded resource growth.

---

## Step 7 — Timeouts and retries

Every external call:

- connect timeout,
- read timeout,
- total deadline propagated from the caller,
- retry policy bounded with jittered backoff,
- circuit breaker on sustained failure.

Defaults: aggressive timeouts (single-digit seconds, often
sub-second on the user path).

The wrong timeout is "no timeout."

---

## Step 8 — Streaming and pagination

- list endpoints paginate (skill `api-design`),
- DB cursor / chunked iteration for large reads,
- streaming responses (chunked / SSE / NDJSON) where
  appropriate.

Forbidden default: serializing a million-row result into a single
JSON response.

---

## Step 9 — Async path budgets

The async path has its own budget:

- max queue lag,
- per-message processing time,
- retries within a deadline,
- DLQ alerted (skill `event-driven`).

Async is not "fire and forget."

---

## Step 10 — Load testing

Before launch and before major changes, run load tests with:

- realistic traffic shape (warm-up, steady-state, burst),
- realistic data (production shape, anonymized),
- realistic upstream latency,
- saturation scenarios (DB pool exhausted, cache cold, one
  dependency failing).

A load test that only tests the happy path is decoration.

Document expected behavior under load: which queues fill, where
backpressure shows up, how recovery happens.

---

## Step 11 — CI enforcement

- bundle-size check on every PR (frontend),
- query-count assertion on hot endpoints (no N+1),
- Lighthouse / WebPageTest budget on every PR (where feasible),
- benchmark regression check on critical paths.

A regression that ships in CI is a regression that ships in prod.

---

## Step 12 — Operate

After launch:

- track each budget metric in production,
- alert on burn-rate against the budget,
- review weekly,
- treat regressions as bugs (revert preferred, "investigate
  later" is forbidden).

---

## Step 13 — Capacity planning

For each service:

- known requests-per-second per instance,
- baseline cost per request,
- documented saturation point,
- documented headroom (e.g. "we run at 30% of saturation").

When a load profile changes (new feature, growth, sale event),
re-run the math.

Forbidden:

- "we have autoscaling, so capacity is solved" — autoscaling
  hides cost spikes, not failure modes autoscaling cannot solve
  (DB connection limits, third-party rate limits, cold cache).

---

## Forbidden

- "Premature optimization is the root of all evil" used as a
  shield against any performance work,
- "It is fine on my machine,"
- caches added without invalidation,
- indexes added without measurement,
- concurrency added without bounds,
- timeouts left at framework default,
- retries without backoff,
- regressions accepted because the test suite passed.

---

## When this skill says STOP

- the surface ships without a budget → set it before launch,
- the budget cannot be measured → build measurement first,
- a regression has shipped without a tracked owner → revert or
  assign immediately.

Performance is a property of the design, not a postscript.
Establish the budget, measure against it, treat regressions as
bugs.

A fast system is a feature; a fast system whose speed is
intentional is the goal.
