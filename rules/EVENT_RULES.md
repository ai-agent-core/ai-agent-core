# Event Rules

Asynchronous, message-driven systems trade synchronous coupling
for delivery semantics, ordering uncertainty, and at-least-once
reality. These rules govern how events, queues, and event-driven
flows are designed.

For the operational stance, see
`principles/OPERATIONAL_PRINCIPLES.md`. For data, see
`principles/DATA_PRINCIPLES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Choose Sync or Async, Deliberately

Async messaging is not "synchronous, but later." It is a
different shape with different guarantees.

Use async when:

- the work is genuinely deferred (notifications, exports,
  expensive computation),
- consumers are decoupled from producers,
- multiple consumers want the same event,
- the producer must succeed regardless of consumer health.

Use sync when:

- the user is waiting for the result,
- the operation is small,
- failure of the downstream means failure of the operation.

Forbidden:

- async because "it scales" without identifying the actual
  decoupling,
- "fire and forget" without a queue, timeout, retry, and DLQ.

---

# Pick the Right Substrate

- **Message queue** (SQS, RabbitMQ, Cloud Tasks): point-to-point
  job dispatch, single consumer per message, retries.
- **Event log** (Kafka, Kinesis, Pub/Sub event mode): durable
  ordered log, multiple consumers, replayable.
- **Pub/Sub topic** (SNS, EventBridge, Pub/Sub): fan-out to many
  subscribers without ordering guarantees.
- **In-process channels**: same-process producer-consumer; never
  a substitute for cross-service messaging.

Mixing substrates without a written reason is forbidden. Use
skill `event-driven` to pick.

---

# Events Are Facts

An event represents *something that happened*. It is named in
past tense and carries the data the consumers need:

- `OrderPlaced`, `PaymentCaptured`, `UserDeleted`,
  `EmailDeliveryFailed`.

Forbidden:

- imperative names (`PlaceOrder`, `RetryPayment`) — those are
  commands, not events,
- events that try to describe future state ("about to happen"),
- events that mean different things in different contexts.

Once an event is published, it is immutable. Corrections are new
events.

---

# Event Schema and Versioning

Every event has a schema:

- protobuf, Avro, or JSON Schema,
- versioned (additive evolution preferred),
- registered in a schema registry where the substrate supports
  it,
- consumers MUST tolerate unknown fields (forward compatibility),
- producers MUST NOT remove or rename fields without a versioned
  successor.

Required envelope fields on every event:

- `event_id` (UUID), `event_type`, `event_version`,
- `occurred_at` (ISO 8601 UTC),
- `producer` (service name + version),
- `trace_id` for cross-service correlation,
- `idempotency_key` (often == event_id).

A consumer-side schema mismatch must be a typed error, not a
crash.

---

# Delivery Semantics

The default of every real-world messaging substrate is
**at-least-once**. Design for it:

- consumers are idempotent on `event_id` (or a domain idempotency
  key),
- duplicate delivery does not produce duplicate effects,
- exactly-once is a marketing term, not an operational
  guarantee. Treat it as at-least-once with idempotency on top.

Forbidden:

- consumer logic that assumes exactly-once,
- consumer logic that assumes ordered delivery without ordered
  partitions / keys,
- consumer logic that assumes immediate delivery.

---

# Ordering

Ordering is **per-key / per-partition**, not global. Pick a
partition key carefully — it locks every consumer pattern that
relies on ordering.

- Order by aggregate ID (per-order, per-user) when ordering
  matters within an aggregate.
- Global ordering is rare and expensive.
- If a consumer needs ordering, document it; producers respect
  the partition key contract.

Forbidden:

- assuming global FIFO,
- changing partition keys without a migration plan,
- relying on timestamps for ordering across producers
  (clock skew is real).

---

# Idempotent Consumers

Every consumer MUST be idempotent on the message identity:

- store processed event IDs (or domain keys) in a deduplication
  table,
- write the dedupe row in the same transaction as the effect,
- replays return the original outcome (success or terminal
  failure).

Forbidden:

- consumers that mutate state without an idempotency check,
- "we will dedupe in the database with a unique constraint"
  alone — race conditions exist; the consumer must coordinate.

---

# Outbox Pattern (For Reliable Publishing)

When a producer must update its state AND publish an event, the
two steps MUST be transactional:

1. Write the event into an `outbox` table in the same DB
   transaction as the state change.
2. A relay process reads the outbox and publishes to the broker.
3. The relay marks rows published once acknowledged.

This gives "exactly the events that match committed state."

Forbidden:

- publishing the event before the DB commits (lost-on-rollback
  events),
- publishing the event after the DB commits without an outbox
  (lost-on-crash events),
- relying on dual writes without a coordination mechanism.

---

# Inbox Pattern (For Reliable Consumption)

Symmetric to outbox: a consumer that must record "I processed
this event" alongside the effect uses an `inbox` table. The
combination of inbox + outbox makes the system tolerant of
crashes, retries, and duplicate delivery.

---

# Retries and Dead-Letter Queues

Every consumer has:

- bounded retries with exponential backoff and jitter,
- a maximum age (give up after N hours / days),
- a **dead-letter queue (DLQ)** for messages that exhausted
  retries,
- DLQ is monitored, alerted, and triaged — never an unattended
  bin.

Forbidden:

- infinite retries (consumes capacity, masks bugs),
- DLQs without alerts,
- "we will check the DLQ later" — later is never.

A DLQ depth above zero for a sustained period is an open
incident.

---

# Poison Messages

A poison message is one that fails permanently regardless of
retry. Required handling:

- detect (consecutive failures with the same `event_id`),
- divert to DLQ after the threshold,
- preserve the message and its failure history,
- alert humans, with enough context to remediate.

A poison message blocking a partition is the textbook async
incident; design to detect and divert.

---

# Backpressure

Producers MUST respect consumer capacity:

- queue depth is observable,
- producers throttle / shed when queues exceed thresholds,
- batch sizes are bounded,
- broker quotas / partitions / shards are sized for peak.

Forbidden:

- unbounded `for x in input: queue.publish(x)`,
- producers oblivious to consumer health,
- "scale the consumer infinitely" as a substitute for
  backpressure.

---

# Schema Evolution

Schema changes follow expand → migrate → contract:

1. Producers emit both old and new shape (or new with
   additive-only fields tolerated by old consumers).
2. Consumers upgrade to read the new shape.
3. Producers stop emitting old fields after the soak period.

Forbidden:

- breaking field changes without a versioned successor,
- removing fields the same release they stop being produced.

---

# Time and Clocks

- Timestamps are UTC.
- Producer-set `occurred_at` is the authority for "when did this
  happen."
- Broker-set timestamps describe receipt, not occurrence.
- Consumers do not assume monotonicity across producers.
- Clock skew is real; do not rely on sub-second cross-service
  timestamps for ordering.

---

# Sagas and Process Managers

For multi-step business transactions that span aggregates /
services, use a saga (or process manager):

- explicit state machine,
- forward steps and compensating steps,
- idempotency at every step,
- timeouts and escalation paths,
- observability per saga instance (where it is, where it has
  been, what failed).

Forbidden:

- multi-service "transactions" relying on chained synchronous
  calls,
- "two-phase commit" between unrelated services unless the
  substrate genuinely supports it.

A saga is an explicit object in the system, not a sequence of
hopeful calls.

---

# Observability for Async

- Trace context propagates across messages
  (W3C `traceparent` carried in event metadata).
- Per-event logs include `event_id`, `event_type`,
  `partition_key`, `trace_id`, consumer identity.
- Metrics: per-topic throughput, consumer lag, DLQ depth, error
  rate, processing duration.
- Alerts on lag burn-rate (sustained lag growth), not raw
  consumer-count drops.

A pipeline you cannot trace is a pipeline you cannot debug.

---

# Testing Async Systems

- Unit-test consumers with synthetic events.
- Test idempotency: same event delivered N times produces the
  same outcome.
- Test out-of-order: events delivered in unexpected order do not
  corrupt state.
- Contract tests with the schema registry.
- Integration tests with a real broker (containerized) where
  feasible.

Forbidden:

- testing only the happy path,
- mocking the broker so deeply the test verifies nothing about
  delivery semantics.

---

# PII and Privacy in Events

- Events traverse multiple consumers; PII in events spreads
  fast.
- Minimize personal data in event payloads,
- Use IDs / references that consumers fetch under their own
  authorization,
- Apply right-to-deletion policies to event storage too (Kafka
  topics, blob archives).

A retention policy that cleans the database but leaves a 90-day
event log retains the data, regardless.

---

# Forbidden Anti-patterns

- Async-everywhere: hiding synchronous user-facing flows behind
  brokers because "events scale."
- Consumers that block on synchronous downstream calls without
  timeouts.
- Treating a broker as a database (long-term query store).
- Reordering / overwriting events.
- "Delete the bad event from Kafka" — events are immutable;
  publish a correction.
- Cross-cutting consumer logic copy-pasted into 10 services
  instead of a shared library.

---

# Prime Directive

An event-driven system survives consumer crashes, broker hiccups,
and out-of-order delivery — by design, not by luck. Build for
at-least-once delivery, idempotent consumers, observable lag, and
reconciled state.

If the system relies on the broker behaving perfectly, the system
is not yet built.
