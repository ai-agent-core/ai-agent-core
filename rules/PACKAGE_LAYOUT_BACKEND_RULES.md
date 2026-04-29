# Package Layout Rules — Backend (Quarkus / JVM)

This document defines the package layout for the **Quarkus / JVM**
backend path — used when the system needs heavy domain modelling,
complex transactional invariants, JVM-ecosystem requirements, or
team JVM expertise.

For the **default (Cloudflare Workers + Hono + TypeScript) path**,
see `rules/PACKAGE_LAYOUT_WORKERS_RULES.md`. The path is chosen at
project bootstrap (skill `bootstrap-project`) per
`rules/STACK_DEFAULTS_RULES.md`.

Shared conventions (the four-layer convention, dependency
direction, bounded-context-first) are defined in
`rules/PACKAGE_LAYOUT_COMMON_RULES.md` and apply here.

The Quarkus / JVM backend follows the four-layer convention with
the stereotypes defined below.

## Stack defaults on this path

- **Framework**: Quarkus (RESTEasy Reactive / JAX-RS).
- **Language**: Kotlin preferred; Java 21+ acceptable.
- **Build**: Gradle (Kotlin DSL) or Maven.
- **Persistence**: Hibernate ORM with Panache, or jOOQ.
- **Migrations**: **Flyway** (`db/migration/V<N>__<name>.sql`).
- **Entity generation**: **jeg** (database → entity reverse-generation).
  Edits to the generated `${projectName}-entity` module are forbidden.
- **Tests**: JUnit 5 + Quarkus DevServices (Testcontainers).

---

# Example Layout

```
my-service/
  src/main/java/com/example/myservice/
    interfaces/
      order/
        OrderResource.java
        PlaceOrderRequest.java
        OrderResponse.java
    applications/
      order/
        OrderPlacementUseCase.java
        OrderConverter.java
        OrderDto.java
    domains/
      order/
        Order.java                  (AggregateRoot — hand-authored)
        OrderStatus.java            (ValueObject)
        PricingProcessor.java
        OrderRepository.java        (interface)
    architectures/
      order/
        OrderRepositoryImpl.java
        PaymentGatewayClient.java
        OrderEventPublisher.java

my-service-entity/                  (sibling module)
  src/main/java/com/example/myservice/entity/
    OrderEntity.java                (reverse-generated @Entity)
    OrderLineEntity.java
```

---

# Stereotypes — `interfaces/`

**Resource** — HTTP endpoint (JAX-RS). Receives Request, returns
Response. Keep thin. MUST NOT contain business logic.

**Request** — Input DTO at the HTTP boundary. MUST NOT leak into
`applications/` or `domains/`.

**Response** — Output DTO at the HTTP boundary. Same constraint
as Request.

**ExceptionMapper** — Translates exceptions into HTTP responses.

**MessagingConsumer** — Queue or event entrypoint. Peer to
Resource; same layering rules apply.

---

# Stereotypes — `applications/`

**UseCase** — One scenario, one class. Multiple methods per class.

**One method = one transaction boundary.**

Orchestrates domain objects and manages side-effect boundaries.

MUST NOT contain business logic itself.

**ApplicationDto** — Data contract between `applications/` and
`interfaces/`. Does not leak into `domains/`.

**Converter** — Bidirectional translator between domain objects
and ApplicationDto. Lives in `applications/`.

---

# Stereotypes — `domains/`

**AggregateRoot** — The parent Entity that owns a cluster of child
Entities. **Hand-authored.** Guards invariants. All external access
to the aggregate MUST go through the AggregateRoot.

**Entity** — Persistent concept with identity. Includes
reverse-generated child entities sourced from
`${projectName}-entity`.

**ValueObject** — Defined by equality and immutability. Used for
quantities, ranges, and **exclusive state classifications**.

**Processor** — Pure business computation.

Data access MUST be received via callback (for example,
`Function<Id, T>`).

Processor MUST NOT depend on Repository.

Cross-aggregate calculations live here.

**Specification** — Composable predicate.

Used for Repository queries, rule validation, and behavior selection.

NEVER used for exclusive classification — use ValueObject instead.

**Policy** — Variable business rule injected into a Processor as
a Strategy.

Introduce ONLY when a real variation exists.

**Factory** — Introduce ONLY when creation is complex enough that
constructors or static methods cannot carry the intent.

**Repository** — Collection-style abstraction over aggregates.

Interface lives in `domains/`.

One Repository per AggregateRoot.

DAO is NOT a stereotype in this layout. Persistence shape is
encapsulated inside RepositoryImpl.

---

# Stereotypes — `architectures/` (= infrastructure)

**RepositoryImpl** — Persistence implementation. Reconstructs
AggregateRoot from reverse-generated entities and persists state
changes.

**ExternalClient** — Adapter to external APIs or SDKs.

**MessagingPublisher** — Queue or event publisher.

**MessagingConsumerImpl** — Implementation detail of consumers
(deserialization, framework binding).

**ConfigBean** — Quarkus Producer, configuration, framework-specific
DI definitions.

---

# Test Layout

Backend tests MUST mirror the source package structure under
`src/test/java/`.

```
my-service/
  src/
    main/java/com/example/myservice/
      interfaces/ ...
      applications/ ...
      domains/ ...
      architectures/ ...
    test/java/com/example/myservice/
      interfaces/
        order/
          OrderResourceTest.java
      applications/
        order/
          OrderPlacementUseCaseTest.java
      domains/
        order/
          OrderTest.java
          PricingProcessorTest.java
          OrderStatusTest.java
      architectures/
        order/
          OrderRepositoryImplIT.java
```

## Density by Layer

- **`domains/`** — highest test density. Every AggregateRoot
  method, Processor calculation, Specification rule, Policy
  variant, and ValueObject equality has its own perspective test.
  The domain is the highest-value layer and carries the deepest
  coverage.

- **`applications/`** — one test class per UseCase. Each UseCase
  method (= one transaction boundary) has a dedicated test class
  or section, with separate test methods for the success path and
  every failure path that matters to the specification.

- **`interfaces/`** — Resource tests cover request / response
  contract, status-code mapping, and exception translation.
  Avoid duplicating domain assertions here.

- **`architectures/`** — integration tests only. Thin in count,
  heavy in realism. RepositoryImpl tests exercise a **real
  database via a local container**. ExternalClient tests use
  recorded fixtures or contract tests against a locally runnable
  stub.

## Mock Usage by Layer

Within the global Mocking Boundary (Repository and external API
only, per `rules/TESTING_RULES.md`), Backend layer testing
applies the following defaults:

- **`domains/` Processor tests** — no mocks. Data access callbacks
  are supplied as plain lambdas returning fixed test data.
- **`applications/` UseCase tests** — mock the Repository
  interface. DB is not started. Verifies orchestration and
  transaction shape only.
- **`interfaces/` Resource tests** — mock the UseCase. Verifies
  HTTP contract, status codes, and exception translation only.
  End-to-end verification is not performed here.
- **`architectures/` RepositoryImpl IT** — no mocks. Real DB via
  local container. ExternalClient uses recorded fixtures or
  contract tests.

## Naming

- unit tests: `XxxTest.java`
- integration tests that exercise real infrastructure: `XxxIT.java`

## Execution Constraints

Backend tests MUST satisfy the global Local-First Execution rule
(see `rules/TESTING_RULES.md`).

No test requires cloud resources, shared environments, or
external credentials to run.

`./gradlew test` (or equivalent) from a fresh checkout MUST
succeed on a developer machine with no setup beyond Docker.

---

# Persistence Module Relationship

Reverse-generated persistence entities live in a sibling module:

`${projectName}-entity`

- Contains reverse-generated `@Entity` classes (one per table).
- `domains/` uses these as child Entities.
- AggregateRoot (the parent Entity) is **hand-authored** and
  composes the generated children.
- `architectures/RepositoryImpl` reconstructs the AggregateRoot
  from these entities and persists state.

---

# Forbidden Patterns (Backend)

- flat `controllers/`, `services/`, `dtos/` at module root
- business logic inside Resource or UseCase
- AggregateRoot calling Repository directly
  (Repository is called by `applications/`)
- Processor depending on Repository interface
  (data MUST arrive as callback)
- Request or Response DTOs crossing into `applications/` or `domains/`
- JPA entities or framework beans leaking through
  `applications/` boundaries
