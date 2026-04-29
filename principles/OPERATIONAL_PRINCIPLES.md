# Operational Principles

A system that cannot be operated is a system that does not work.

Code shipped without operability is a liability disguised as
delivery. Agents MUST treat observability, reversibility, and
blast-radius management as design constraints — not afterthoughts
appended once "the feature is done."

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Observability Is a Design Output

A feature is not designed until you can answer:

- Is it working right now?
- For whom is it broken?
- What is it spending time on?
- What changed when it last broke?

These questions translate into structured logs, metrics, and
traces, named consistently across the system. Observability is
emitted by the code that does the work, not by a side project that
tries to scrape it later.

---

# Logs, Metrics, Traces — Each for a Reason

Each telemetry primitive answers a different question:

- **Logs** explain *what happened* in narrative form, with a
  correlation ID, structured fields, and no PII.
- **Metrics** quantify *how often / how long / how big*; they
  power dashboards and alerts.
- **Traces** show *where the time went* across services and
  external calls.

Pick the right primitive for the question. Logs that are really
metrics blow up storage; metrics that are really traces lose
context; traces that are really logs lose aggregability.

---

# Reversibility Beats Cleverness

Prefer mechanisms you can undo:

- Feature flags over hard-coded rollouts.
- Expand-then-contract migrations over destructive ones.
- Blue/green or canary over big-bang deploys.
- Soft deletes for user-visible data; hard deletes only on a
  documented schedule.
- Idempotent operations with retry budgets, not one-shot calls.

A clever, irreversible action is a single point of failure for the
entire team. Reversibility is the cheapest insurance available.

---

# Blast Radius Is a Design Variable

When something goes wrong, how much breaks?

Architectural choices either contain or amplify failures:

- Bulkheads (per-tenant pools, per-feature queues) contain.
- Shared global state amplifies.
- Per-service databases contain; one giant DB amplifies.
- Circuit breakers and timeouts contain; unbounded retries
  amplify.
- Rate limits at every external boundary contain; unprotected
  endpoints amplify a misbehaving client into an outage.

Design assuming a downstream will fail. It will.

---

# Deploy Continuously, Roll Back Faster

Deployment is not a milestone. It is a routine, automated event
that takes minutes, not hours, and is usable at any hour without
heroics.

- Trunk-based development with short-lived branches.
- CI runs on every change; deploys on every passing main.
- Rollbacks are one command, fully automated, faster than
  forward-fixes.
- Database changes are decoupled from code changes
  (expand-contract).

If "deploy" is a noun (an event you schedule), the pipeline is
broken.

---

# Make the System Honest About Its Health

Health is not "the process is alive." Health is "is this component
fulfilling its contract?"

- **Liveness** — the process is responsive.
- **Readiness** — the process can accept traffic *now*.
- **Synthetic / business KPI** — the user-facing journey is
  working end-to-end.

A green liveness probe with broken readiness wastes traffic. A
green readiness probe with broken business KPI wastes users. All
three matter.

---

# SLOs Set the Bar; Errors Spend the Budget

Service Level Objectives turn "good enough" into a number. They
make trade-offs explicit:

- 99.9% / 99.95% / 99.99% — pick deliberately; each "9" is an
  order of magnitude more cost.
- Error budget = (1 − SLO) × time. When the budget is gone, ship
  reliability work, not features.
- Alerts fire on burn rate, not on raw failure counts. A spike
  that does not threaten the budget does not need to wake anyone.

SLOs without alerting on burn rate are decoration.

---

# Idempotency Is a Contract

Anything callable across an unreliable boundary (network,
queue, retry loop) MUST be idempotent or explicitly marked
single-shot:

- Use idempotency keys for write operations.
- Make creates upserts when retries are possible.
- Persist the idempotency record in the same transaction as the
  effect.
- Return the same response for replayed keys.

Without idempotency, retries become double-charges.

---

# Configuration Is Code, Not a Click

Production configuration MUST be:

- declared in source (Terraform, Pulumi, Helm, Kustomize), not in
  the cloud console,
- reviewed via PR,
- applied by automation, not by humans,
- diff-able and rollback-able.

Manual console changes are an emergency procedure, immediately
followed by reconciling the change back into IaC.

---

# Environments Are Pipelines, Not Snowflakes

Dev / staging / prod MUST share the same artifact (image, bundle,
binary) and differ only in configuration. If staging cannot
catch a problem before prod, staging is decoration.

Forbidden:

- "It only happens in prod."
- "Staging has different schema."
- Environment-specific code paths gated by `if env == "prod"`.

The pipeline is the source of truth; the environment is the
target.

---

# Cost Is a Non-Functional Requirement

Every architectural choice has a cost curve. Agents MUST consider:

- baseline cost at expected load,
- per-unit cost (per request, per active user, per stored GB),
- failure-mode cost (retry storms, log explosions),
- cost of *not* shipping the work (opportunity cost).

A "scales infinitely" answer that costs ten times the alternative
is the wrong answer. Pick the design that holds at the next
order-of-magnitude of load — not the next four.

---

# Data Is Liability and Asset

Storing data forever is not free:

- Storage costs money and grows.
- Retention has legal implications.
- Backups multiply both.

Every dataset has a documented retention policy. Cold tiers,
archive, and deletion schedules are part of the design, not a
future cleanup task.

---

# Run the System Yourself

Every engineer who builds a service should be reachable when it
breaks. The on-call rotation is a forcing function for operational
quality:

- runbooks exist and are recently tested,
- alerts are actionable,
- dashboards answer the questions that show up at 3 AM,
- the rotation is humane (no permanent on-callers, no two-person
  rotations, manageable page volume).

A service whose owner cannot be paged is a service no one owns.

---

# Postmortems Are Free Engineering

Every incident is a paid lesson. The team has already paid; the
lesson is recovered through the postmortem.

- Blameless framing (system, not people).
- Concrete timeline, with sources.
- Causes plural (no single root cause for non-trivial systems).
- Action items with owners and deadlines.
- Tracked to completion.

A postmortem with no completed action items is a story, not an
investment.

---

# Prime Directive

Build systems that announce when they are sick, contain damage
when they fail, and recover deliberately. The 3 AM operator —
who is also you in six months — must be able to tell what is
broken, why, and how to fix it, from the system's own evidence.

Operability is a feature.
