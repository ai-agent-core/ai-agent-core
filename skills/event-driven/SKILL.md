---
name: event-driven
description: Design async / event-driven flows — pick a substrate, define event schemas, enforce idempotency and ordering, handle backpressure and DLQs.
---

# Event-driven

Use this skill **whenever async messaging is being added or
extended** — a new queue, a new topic, a new consumer, a new
event-sourced aggregate.

Authoritative source: `rules/EVENT_RULES.md`. Operational stance:
`principles/OPERATIONAL_PRINCIPLES.md`.

---

## Premise

Async messaging is not "synchronous, but later." It is a
different shape with different guarantees.

- delivery is **at-least-once** in the real world,
- ordering is **per-key**, not global,
- consumers are **idempotent on event identity**,
- delivery times are **non-deterministic**.

Build for these realities. Designing on the assumption that "the
broker is reliable" is the canonical failure mode.

---

## Step 1 — Sync or async?

Use async when:

- the work is genuinely deferred (notifications, exports,
  expensive computation),
- multiple consumers want the same event,
- producer must succeed regardless of consumer health,
- decoupling materially benefits the system.

Use sync when:

- the user is waiting,
- the operation is small,
- failure of the downstream means failure of the operation.

Forbidden:

- "async because it scales" without identifying the actual
  decoupling,
- "fire and forget" without a queue, timeout, retry, and DLQ.

---

## Step 2 — Pick the substrate

| When                                                       | Substrate                       |
| ---------------------------------------------------------- | ------------------------------- |
| Point-to-point job dispatch, retries, single consumer      | Queue (SQS / RabbitMQ / Tasks)  |
| Durable ordered log, multiple consumers, replay            | Event log (Kafka / Kinesis)     |
| Fan-out to many subscribers, no ordering needs             | Pub/Sub topic (SNS / EventBridge) |
| In-process producer-consumer                               | Channel (language-native)       |

Mixing without a written reason is forbidden. Different substrates
have different ordering, retention, and delivery semantics.

---

## Step 3 — Define the event

Events are facts ("OrderPlaced", "PaymentCaptured"). Past tense.

Required envelope:

- `event_id` (UUID),
- `event_type`,
- `event_version`,
- `occurred_at` (ISO 8601 UTC),
- `producer` (service name + version),
- `trace_id`,
- `idempotency_key` (often == `event_id`).

Schema in protobuf / Avro / JSON Schema, registered, versioned,
additive-only by default.

Forbidden:

- imperative names (`PlaceOrder` is a command, not an event),
- "meta" events that try to describe future state,
- payloads that include PII when an ID + lookup would do.

---

## Step 4 — Producer side

### State + event consistency: the outbox pattern

When a producer must update its state AND publish an event, the
two steps MUST be transactional:

1. write the event into an `outbox` table in the same DB
   transaction as the state change,
2. a relay process reads the outbox and publishes,
3. the relay marks rows published once acknowledged.

Forbidden:

- publishing the event before the DB commits (lost on rollback),
- publishing after the DB commits without an outbox (lost on
  crash),
- dual-write to broker and DB without coordination.

---

## Step 5 — Consumer side: idempotency

Every consumer MUST be idempotent on the event identity:

- store processed event IDs in a deduplication table (or bloom
  filter for high scale),
- write the dedupe row in the same transaction as the effect,
- replay returns the original outcome.

The **inbox pattern** is the consumer-side analogue of outbox:
the consumer writes "I processed event X" together with the
effect.

Forbidden:

- consumers that mutate state without an idempotency check,
- relying on a database unique constraint alone — race
  conditions exist; coordinate explicitly.

---

## Step 6 — Ordering

Ordering is per-partition / per-key. Pick the partition key
deliberately:

- per-aggregate (per-order, per-user) when ordering matters
  within an aggregate,
- avoid partition keys that create hot partitions (e.g. partition
  by tenant when one tenant is 80% of traffic),
- global ordering is rare and expensive.

Document the partition contract for every topic; consumers depend
on it.

Forbidden:

- assuming global FIFO,
- changing partition keys without a migration plan,
- relying on producer timestamps for ordering across producers.

---

## Step 7 — Retries and DLQ

Every consumer:

- bounded retries with exponential backoff and jitter,
- maximum age (give up after N hours / days),
- a **dead-letter queue (DLQ)** for messages that exhaust
  retries,
- DLQ is **monitored and alerted** — never an unattended bin.

Forbidden:

- infinite retries (mask bugs, consume capacity),
- DLQs without alerts,
- "we'll check the DLQ later" — later is never.

A DLQ depth above zero for a sustained period is an open
incident.

### Poison messages

A consistently-failing message:

- detected (consecutive failures with the same `event_id`),
- diverted to DLQ after the threshold,
- preserved with failure history,
- alerted to humans with enough context to remediate.

---

## Step 8 — Backpressure

Producers respect consumer capacity:

- queue depth is observable,
- producers throttle / shed when queues exceed thresholds,
- batch sizes bounded,
- broker quotas / partitions / shards sized for peak.

Forbidden:

- unbounded `for x in input: queue.publish(x)`,
- producers oblivious to consumer health,
- "scale the consumer infinitely" as a substitute.

---

## Step 9 — Schema evolution

Expand → migrate → contract:

1. producers emit both old and new shape (or new with
   additive-only fields tolerated by old consumers),
2. consumers upgrade,
3. producers stop emitting old fields after the soak period.

Forbidden:

- breaking field changes without versioned successors,
- removing fields the same release they stop being produced.

---

## Step 10 — Sagas / process managers

For multi-step business transactions across aggregates / services,
use a saga:

- explicit state machine,
- forward steps and compensating steps,
- idempotency at every step,
- timeouts and escalation paths,
- observability per saga instance.

Forbidden:

- multi-service "transactions" relying on chained synchronous
  calls,
- distributed two-phase commit unless the substrate genuinely
  supports it.

A saga is an explicit object in the system, not a sequence of
hopeful calls.

---

## Step 11 — Observability

Same discipline as `rules/OBSERVABILITY_RULES.md`:

- trace context propagated across messages (W3C `traceparent` in
  metadata),
- per-event logs include `event_id`, `event_type`,
  `partition_key`, `trace_id`, consumer identity,
- metrics: throughput, consumer lag, DLQ depth, error rate,
  processing duration,
- alerts on lag burn-rate (sustained lag growth).

A pipeline you cannot trace is a pipeline you cannot debug.

---

## Step 12 — Testing

- unit-test consumers with synthetic events,
- test idempotency: same event delivered N times → same outcome,
- test out-of-order delivery,
- contract tests with the schema registry,
- integration tests with a real broker (containerized) where
  feasible,
- load tests including burst patterns from producers.

Forbidden:

- mocking the broker so deeply the test verifies nothing about
  delivery semantics,
- testing only the happy path.

---

## Forbidden

- async-everywhere: hiding synchronous user-facing flows behind
  brokers because "events scale,"
- consumers that block on synchronous downstream calls without
  timeouts,
- treating a broker as a long-term query store,
- reordering / overwriting events,
- "delete the bad event from Kafka" — events are immutable,
  publish a correction,
- cross-cutting consumer logic copy-pasted into 10 services
  instead of a shared library.

---

## When this skill says STOP

- the partition / ordering contract is unclear → define before
  shipping,
- there is no DLQ alert → fix before going live,
- the schema is not in source control with a versioning plan →
  add it.

An event-driven system survives consumer crashes, broker
hiccups, and out-of-order delivery — by design, not by luck.

If the system relies on the broker behaving perfectly, the
system is not yet built.
