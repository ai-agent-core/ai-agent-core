# Package Layout Rules — Functions (Serverless)

This document defines the package layout for serverless function
projects.

Shared conventions (the four-layer convention, dependency
direction, bounded-context-first) are defined in
`rules/PACKAGE_LAYOUT_COMMON_RULES.md` and apply here.

Serverless functions follow the four-layer convention, but the
four layers are distributed across the repository rather than
placed inside every function package.

Each individual function contains only `interfaces/` and
`applications/`.

`domains/` and `architectures/` live once, as shared modules,
and are imported by every function.

This keeps each function small, readable, and single-purpose
while preserving the four-layer architecture at the repository
level.

---

# Example Layout

```
my-functions/
  functions/
    place-order/
      src/main/java/com/example/placeorder/
        interfaces/
          PlaceOrderHandler.java        (Function entrypoint)
          PlaceOrderEvent.java          (input)
          PlaceOrderResult.java         (output)
        applications/
          PlaceOrderUseCase.java        (single entry method, 1 tx)
          PlaceOrderConverter.java
      build.gradle
    cancel-order/
      (same shape)

  shared/
    my-functions-domain/                (shared module)
      src/main/java/com/example/domains/
        order/
          Order.java                    (AggregateRoot)
          PricingProcessor.java
          OrderStatus.java              (ValueObject)
          OrderRepository.java          (interface)

    my-functions-architecture/          (shared module)
      src/main/java/com/example/architectures/
        order/
          OrderRepositoryImpl.java
          PaymentGatewayClient.java

  my-functions-entity/                  (sibling, reverse-generated)
```

---

# Sizing Rule

**1 Function = 1 scenario = 1 UseCase = 1 transaction.**

Each function has exactly one entry point and one transactional
action.

FORBIDDEN:

- multiple UseCase methods routed by a switch statement inside
  a single function
- multi-purpose handlers that decide their behavior from event
  contents
- reusing one function binary to serve unrelated actions

If two actions share domain logic, share the domain module —
not the function.

---

# Runtime Reference Example

Rules use **AWS Lambda (Java)** as the concrete reference
runtime.

Patterns translate directly to:

- Google Cloud Functions / Cloud Run Functions
- Azure Functions
- Cloudflare Workers (with a TypeScript adaptation)
- Quarkus Funqy

Runtime-specific bindings live in `interfaces/` (for the handler
adapter) and `architectures/` (for any framework-level setup).

Domain and application code MUST remain runtime-agnostic.

---

# Stereotypes — Delta From Backend

Only the deltas are listed; anything not mentioned is identical
to `rules/PACKAGE_LAYOUT_BACKEND_RULES.md`.

## `interfaces/`

**Handler** — Function entrypoint. Replaces Resource. Receives
the runtime event, delegates to UseCase, returns the Result.

MUST remain thin. No business logic.

**Event** — Input DTO at the function boundary. Replaces Request.

Represents the shape of the runtime event (Lambda event, CloudEvent,
HTTP request payload, queue message).

Runtime-specific event types MUST NOT leak past `interfaces/`.

**Result** — Output DTO at the function boundary. Replaces
Response.

`ExceptionMapper` does not exist as a stereotype. Each Handler is
responsible for translating exceptions into a Result directly.

`MessagingConsumer` is not a separate stereotype. If the function
is triggered by a queue or event bus, the Handler itself is the
consumer.

## `applications/`

**UseCase** — One class per function. A single entry method. That
method is the transaction boundary.

Multiple methods within a function UseCase are FORBIDDEN.

**Converter** — Bidirectional translator between Event / Result
and domain objects.

**ApplicationDto** — Used only when intermediate application-level
data shapes are needed. Most small functions will not need one.

## `domains/` and `architectures/`

Identical to Backend stereotypes.

They live in shared modules, not inside individual function
packages.

---

# Shared Module Rules

Every Functions project MUST define:

- `${projectName}-domain` — all AggregateRoot, Entity, ValueObject,
  Processor, Specification, Policy, Factory, Repository interfaces.
- `${projectName}-architecture` — all RepositoryImpl, ExternalClient,
  MessagingPublisher, ConfigBean.
- `${projectName}-entity` — reverse-generated persistence entities.

Each function module depends on these shared modules.

Duplicating domain or architecture code across function packages
is FORBIDDEN.

---

# Forbidden Patterns (Functions)

- `domains/` or `architectures/` folders inside a function package
- domain code duplicated across multiple function packages
- a single function serving more than one business action
- runtime-specific event types passed into `applications/` or `domains/`
- Handler containing business logic
- UseCase with multiple entry methods
- inlining domain calculation inside Handler to "save a file"
