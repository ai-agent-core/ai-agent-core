# Observability Rules

A system without observability is a system you cannot debug, tune,
or trust. These rules define how logs, metrics, and traces are
produced and connected, so that production behavior is visible to
the team that built it.

For the principles behind these rules, see
`principles/OPERATIONAL_PRINCIPLES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Three Signals, Three Purposes

| Signal     | Answers                                | Cost shape           |
| ---------- | -------------------------------------- | -------------------- |
| Logs       | What happened, in narrative form       | High at write volume |
| Metrics    | How often / how long / how big         | Cardinality-bounded  |
| Traces     | Where the time went across services    | Sampled              |

Pick the right signal for the question. Logs that should be
metrics blow up storage; metrics that should be traces lose causal
context; traces used for free-text search lose aggregation.

---

# Logging

## Format

- **Structured JSON** by default. One log line = one JSON object.
- Required fields on every line: `timestamp` (ISO 8601 UTC),
  `level`, `service`, `env`, `message`, `trace_id` (when in a
  request context), `span_id`, `request_id`.
- Free-text log lines are forbidden in production code paths.

## Levels

- `ERROR` — an unexpected failure that breaks a request or job.
  Pages on burn rate.
- `WARN` — degraded behavior or edge cases that succeeded;
  triaged but not alerted.
- `INFO` — high-value milestones (request started/completed,
  job dispatched, state transition).
- `DEBUG` — useful in development; off in production by default.
- `TRACE` — never on by default; per-request opt-in only.

Forbidden:

- Logging at `ERROR` for expected business outcomes ("user not
  found" on a lookup that legitimately allows misses).
- `INFO` storms ("entered function X") that drown the signal.
- Logging the full request/response body of high-volume endpoints
  outside an explicit debug session.

## What MUST be logged

- One line per inbound request: method, path, status, duration,
  user/session id (or anonymized), trace id.
- One line per outbound call to an external system: target,
  duration, status / error class, retry count.
- State transitions on persistent entities (order placed →
  order shipped).
- Authn / authz events (success and failure).
- Background job lifecycle (started, finished, failed).
- Migration progress for long-running migrations.

## What MUST NOT be logged

- Passwords, tokens, full payment instrument numbers, secrets,
  full social IDs, raw biometrics.
- The full body of auth / payment / PII-bearing endpoints —
  redact fields explicitly.
- Stack traces in production for expected failures (404, validation).
- Repeated identical lines under load (deduplicate / sample).

## Correlation

Every log line in a request scope MUST carry the same
`trace_id` (and `span_id` if applicable) so traces, logs, and
metrics tie together. The trace ID propagates across service
boundaries (W3C `traceparent`).

---

# Metrics

## Naming

- Use a consistent prefix per service: `<service>_<subsystem>_<thing>`.
- Units in the suffix: `_seconds`, `_bytes`, `_total`, `_ratio`.
- Counters end in `_total`; histograms in `_seconds` or
  `_bytes`.

## Labels (cardinality discipline)

Labels create combinatorial cardinality. Forbidden as labels by
default:

- raw user IDs,
- raw URL paths (use route templates: `/orders/{id}`, not
  `/orders/12345`),
- error messages,
- timestamps,
- IP addresses.

Acceptable labels: `route`, `method`, `status_class` (`2xx`,
`5xx`), `error_class`, `tenant` (when low cardinality), `region`.

A metric with millions of label combinations is a bug.

## RED + USE

For services, emit:

- **Rate** — requests per second per route.
- **Errors** — error rate per route.
- **Duration** — latency histogram per route (p50, p95, p99).

For resources (CPU, memory, disk, queue, pool, cache):

- **Utilization** — % capacity used.
- **Saturation** — queue length, wait time.
- **Errors** — failure count.

## SLI → SLO → Alert

- Define SLIs (e.g. "fraction of `/checkout` requests under 500ms
  AND with status < 500") that match user experience.
- Define SLOs against the SLIs (e.g. 99.9% over 30 days).
- Alert on **burn rate** (fast burn / slow burn windows), not
  on raw error counts.
- Page only when the budget is at risk over a meaningful window.

A page that does not threaten the budget is noise. Noisy
on-callers stop reading alerts.

---

# Tracing

## Required spans

- One root span per inbound request / job.
- One span per outbound call (HTTP, DB, queue, cache).
- One span per logical work unit inside the request that takes
  noticeable time (parse, validate, business rule, write).

## Attributes

Every span carries:

- `service.name`, `service.version`,
- `operation`,
- request route / job name,
- relevant business identifiers (anonymized / hashed when
  sensitive),
- error fields when the span errored.

## Sampling

- Head-based sampling at the edge with a fixed rate
  (e.g. 10% of normal traffic, 100% of error traffic).
- Tail-based sampling for high-throughput services.
- A way to force-sample a request via header for debugging.

A trace that exists for one in a thousand requests does not help
debug the request in front of you — provide a force-sample path.

---

# Health Endpoints

Every service exposes:

- **`/livez`** — the process is alive (cheap, no dependencies).
- **`/readyz`** — the process can accept traffic *now* (DB
  reachable, dependencies ready, warm-up complete).
- Optional **`/startupz`** — distinguished slow startup from
  unhealthy.

Forbidden:

- conflating liveness and readiness in one endpoint,
- a green liveness probe that hides a broken database,
- health endpoints that themselves depend on traffic-path data
  (creating a feedback loop).

---

# Dashboards

Each service has a small, hand-tended set of dashboards:

- a **service overview** (RED metrics by route),
- a **dependency view** (latency / error of upstreams and DB),
- a **business KPI view** (orders / sec, signups, payments),
- an **on-call page** that answers the 3 AM questions in under
  60 seconds.

A wall of 50 panels per service is not a dashboard; it is an
unread newspaper.

---

# Alerts

- Every alert has an owner (a team / a rotation), an SLO it
  protects, and a documented runbook link.
- Alerts page only when human action is required *now*. Issues
  that can wait until business hours are tickets, not pages.
- Every page is reviewed in retrospective: was it actionable?
  Was the runbook helpful? If "no" — fix the alert or the
  runbook.
- Alerts that have fired-and-resolved themselves more than N
  times in a quarter without human intervention either get tuned
  or auto-resolved.

Forbidden:

- alerts without runbooks,
- alerts that page on individual single-host failures in a
  fleet,
- "monitor everything, alert on everything."

---

# Runbooks

Every alert links to a runbook with:

- summary of what the alert means,
- the first three things to check,
- known false-positive scenarios,
- mitigation actions (with required permissions),
- escalation path.

Runbooks live in source control alongside the service. Stale
runbooks are worse than no runbooks; review on every related
incident.

---

# Sensitive Data Handling

The observability pipeline carries the same data risks as the
application:

- redact PII at the source, not at the sink,
- centralize redaction rules so they cannot be forgotten,
- treat the log/metric storage as production data — encrypted,
  access-controlled, retention-bounded,
- the engineer browsing dashboards must not see what the
  application would deny them.

---

# Local Development

- Logs print human-readable in dev (text formatter), structured
  JSON in production. Never the reverse.
- Tracing has a no-op exporter in dev unless explicitly enabled.
- Engineers can correlate logs / traces / metrics locally with the
  same `trace_id` they would see in production.

---

# Incident Mode Tooling

Be prepared:

- a way to **force-sample** a request (header) to capture a full
  trace.
- a way to **dump** application state via a debug endpoint behind
  authentication.
- a way to bump log levels for one process or one route without
  redeploy (e.g. via flags).
- a way to capture profiling data on demand (CPU profile, heap
  dump).

These tools sit unused 99% of the time. The 1% they are needed,
nothing else will do.

---

# Forbidden Anti-patterns

- `print()` / `console.log()` left in production code.
- `try { … } catch { /* ignore */ }` silencing errors with no
  signal.
- Logging the same event multiple times across layers.
- Metrics emitted only when the team remembers.
- Alerts on the wrong cause of the wrong thing
  (e.g. CPU > 80% as a primary alert when latency is the SLI).
- Dashboards built once and never updated.

---

# Prime Directive

A production problem must reveal itself, locate itself, and
suggest its own recovery — through the system's own evidence.

Build observability while you build the feature. Adding it later
costs more and finds less.
