---
name: observability-setup
description: Instrument a service with logs, metrics, and traces; define SLIs/SLOs; set burn-rate alerts; produce on-call dashboards and runbooks.
---

# Observability setup

Use this skill **when a new service is being instrumented, or when
an existing service's observability is being upgraded**.

Authoritative source: `rules/OBSERVABILITY_RULES.md` and
`principles/OPERATIONAL_PRINCIPLES.md`.

A feature is not designed until you can answer:

- is it working right now?
- for whom is it broken?
- what is it spending time on?
- what changed when it last broke?

---

## Step 1 — Pick the stack

Choose one set of tools per environment and use it consistently:

- **Logs**: Cloud Logging / CloudWatch Logs / Loki / Datadog /
  Splunk / ELK.
- **Metrics**: Cloud Monitoring / Prometheus / Datadog / New
  Relic.
- **Traces**: OpenTelemetry SDK + (Jaeger / Tempo / Datadog APM /
  X-Ray / Cloud Trace).
- **Alerting / Paging**: PagerDuty / Opsgenie / Cloud-native.

OpenTelemetry is the default instrumentation API; the backend
is replaceable.

---

## Step 2 — Logging

### Format

- Structured JSON in production. One log line = one JSON object.
- Required fields on every line: `timestamp` (ISO 8601 UTC),
  `level`, `service`, `env`, `message`, `trace_id`, `span_id`,
  `request_id` (when applicable).

### Levels

- `ERROR` — unexpected failure breaking a request or job.
- `WARN` — degraded but successful path.
- `INFO` — high-value milestones.
- `DEBUG` — dev only by default.
- `TRACE` — per-request opt-in only.

### What MUST be logged

- inbound request lifecycle (1 line: method, path, status,
  duration, principal, trace id),
- outbound calls (target, duration, status),
- state transitions on persistent entities,
- authn / authz events,
- background job lifecycle,
- migration progress.

### What MUST NOT be logged

- passwords, tokens, full PAN, full SSN, biometrics,
- full body of auth / payment / PII-bearing endpoints,
- repeated identical lines under load (deduplicate / sample),
- expected business outcomes at `ERROR` level.

---

## Step 3 — Metrics

### Naming

Consistent prefix per service: `<service>_<subsystem>_<name>`.

Units in suffix: `_seconds`, `_bytes`, `_total`, `_ratio`.

### Cardinality discipline

Forbidden as labels:

- raw user IDs,
- raw URL paths (use route templates: `/orders/{id}`),
- error messages,
- timestamps,
- IP addresses.

Acceptable: `route`, `method`, `status_class`, `error_class`,
`tenant` (low cardinality), `region`.

### RED metrics (services)

- **Rate** — requests per second per route,
- **Errors** — error rate per route,
- **Duration** — latency histogram per route (p50, p95, p99).

### USE metrics (resources)

- **Utilization** — % capacity used,
- **Saturation** — queue length, wait time,
- **Errors** — failure count.

---

## Step 4 — Traces

- root span per inbound request / job,
- span per outbound call (HTTP, DB, queue, cache),
- span per logical work unit inside the request that takes
  noticeable time,
- attributes: `service.name`, `service.version`, `operation`,
  route / job name, business identifiers (anonymized when
  sensitive),
- sampling: head-based (e.g. 10%) plus 100% on errors; provide a
  force-sample header for debugging.

W3C `traceparent` propagated across service boundaries.

---

## Step 5 — Define SLIs

For each user-facing journey, define a Service Level Indicator
that captures user experience:

- "fraction of `/checkout` requests under 500ms AND status <
  500,"
- "p99 of search responses under 1s,"
- "rate of message-processing success per minute on the orders
  topic."

SLIs avoid vanity metrics (e.g. CPU usage). They reflect what the
user feels.

---

## Step 6 — Define SLOs

For each SLI, set an SLO:

- 99.9% / 99.95% / 99.99% — pick deliberately; each "9" is an
  order of magnitude more cost.
- documented evaluation window (e.g. rolling 30 days),
- documented error budget = (1 − SLO) × time.

When the budget is gone, ship reliability work, not features.

---

## Step 7 — Alerts (burn-rate)

- alert on SLO **burn rate**, not raw error counts,
- multi-window burn-rate alerts (e.g. 1h fast burn AND 6h slow
  burn) to balance sensitivity and false positives,
- pages only when human action is needed *now*,
- every alert links to a runbook (see Step 9).

Forbidden:

- alerts without runbooks,
- alerts on individual single-host failures in a fleet,
- "alert on everything."

---

## Step 8 — Health endpoints

Every service exposes:

- `/livez` — process is alive (cheap, no dependencies),
- `/readyz` — process can accept traffic *now* (DB reachable,
  warm-up complete),
- optional `/startupz` — distinguished slow startup.

Forbidden:

- conflating liveness and readiness,
- a green liveness probe hiding a broken database.

---

## Step 9 — Dashboards and runbooks

### Dashboards

A small, hand-tended set per service:

- **service overview** (RED metrics by route),
- **dependency view** (latency / error of upstreams + DB),
- **business KPI view** (orders / sec, signups, payments),
- **on-call page** answering 3 AM questions in under 60 seconds.

A wall of 50 panels is not a dashboard.

### Runbooks

Every alert links to a runbook with:

- summary,
- first 3 things to check,
- known false positives,
- mitigation actions and required permissions,
- escalation path.

Runbooks live in source. Stale runbooks are worse than no
runbooks.

---

## Step 10 — Incident-mode tooling

Be prepared:

- force-sample a request (header) to capture a full trace,
- dump application state via an authenticated debug endpoint,
- bump log levels for one process / one route without redeploy
  (flag),
- capture profiling data on demand (CPU, heap).

These tools sit unused 99% of the time. The 1% they are needed,
nothing else will do.

---

## Step 11 — Sensitive data handling

- redact PII at the source, not at the sink,
- centralize redaction rules,
- treat log / metric storage as production data — encryption,
  access control, retention,
- the engineer browsing dashboards must not see what the
  application would deny them.

---

## Step 12 — Verify

Before declaring observability done:

- inject a synthetic failure → an alert fires → the runbook
  works,
- inject load → dashboards show the load → SLIs reflect it,
- inject slow upstream → traces locate the slow span,
- a stranger to the service can use the runbook to mitigate a
  common failure.

Observability you have not exercised is observability you do not
have.

---

## Forbidden

- `print()` / `console.log()` in production code,
- `try { } catch { /* ignore */ }` silencing errors,
- raw URL paths as metric labels,
- alerts that have fired-and-resolved themselves N times without
  human action,
- metrics emitted only when the team remembers,
- dashboards built once and never updated.

---

## When this skill says STOP

- there is no SLO → define one before instrumenting alerts,
- redaction is not in place → fix before logging in production,
- the alert has no runbook → write it before enabling the
  alert.

A production problem must reveal itself, locate itself, and
suggest its own recovery — through the system's own evidence.

Build observability while you build the feature. Adding it later
costs more and finds less.
