# Testing Rules

Tests define system behavior.

Agents MUST treat tests as executable specifications,
not as secondary validation artifacts.

Testing is a design activity.

---

# Specification Pairing

Agents MUST develop code using specification pairs:

Specification ↔ Implementation

Tests describe WHAT must happen.
Code defines HOW it happens.

Never invert this relationship.

---

# Test-Driven Implementation (Outside-In)

Agents MUST follow Test-Driven Implementation as mandated by
Engineering Principles.

The required rhythm:

1. a failing test — describes the next required behavior
2. minimal implementation — makes the test pass with the least code
3. safe refactoring — improves structure under the test's protection

Writing production code before its failing test exists is FORBIDDEN.

Writing tests "later" as a separate phase is FORBIDDEN.

Avoid designing large solutions before behavior is defined.

Behavior drives structure.

---

# Behavior Over Implementation

Tests MUST validate observable behavior.

FORBIDDEN:

- testing private methods
- asserting internal state
- coupling tests to implementation details

Tests must remain stable under refactoring.

---

# Perspective-Based Testing

Tests MUST be organized by behavioral perspective.

Each test should answer:

"What rule of the system is being verified?"

Avoid random case accumulation.

Structure tests around system guarantees.

---

# Test Naming Must Describe Behavior

Test names MUST function as documentation.

Preferred style:

shouldRejectCancellationWhenOrderIsShipped


Avoid vague names:

- testCancel()
- testService()

If the name is unclear,
the test is unclear.

---

# One Perspective, One Test Method

Each verified perspective MUST live in its own test method.

Verbose suites are acceptable.

Combined multi-perspective methods are not.

If a single scenario requires checking:

- the returned value
- side effects on persistence
- emitted signals or state changes

each MUST be a separate test method, even when setup is shared.

Multi-perspective tests hide failures.

Test suites optimize for clarity, not brevity.

---

# Tests Are Architectural Feedback

If tests are difficult to write,
agents MUST reconsider the design.

Hard-to-test code usually signals:

- hidden dependencies
- excessive coupling
- unclear responsibilities

Testing pressure improves architecture.

---

# Public API Focus

Tests MUST interact with the system through public interfaces.

Do NOT expose internals for test convenience.

Encapsulation must survive testing.

---

# Deterministic Tests Only

Tests MUST be deterministic.

Forbidden:

- time-dependent behavior
- network reliance
- shared mutable state

Flaky tests erode trust.

---

# Fast Tests Win

Prefer fast tests over slow ones.

The test suite should enable rapid feedback.

Slow feedback slows architecture evolution.

---

# Mocking Boundary (Strict)

Tests MUST reproduce real behavior as far as possible.

The default stance is to run tests against real domain objects
and real infrastructure — including a real database when
applicable.

Mocks are allowed ONLY at two specific boundaries:

- **Repository** — the interface declared in `domains/`,
  mocked to isolate persistence for targeted unit tests
- **external API clients** — to isolate third-party systems

Mocking any other stereotype is FORBIDDEN:

- Aggregate, Entity, ValueObject
- Processor, Specification, Policy, Factory
- UseCase, Converter, ApplicationDto
- Resource, Request, Response, Handler, Event, Result
- RepositoryImpl, ExternalClient
  (mock the interface in `domains/`, not the implementation)

The mock is the exception, not the posture.

---

# Local-First Execution

Unless the instructor specifies otherwise, tests MUST run
completely locally.

No network access.

No shared cloud services.

No staging databases.

Reproduce external dependencies locally:

- real database via a containerized instance (Testcontainers or
  equivalent)
- real message broker via a local container
- external APIs via recorded fixtures or mocked clients

Tests that require external credentials, remote endpoints, or
environment-specific setup are FORBIDDEN as the default.

Local reproducibility is a contract with every future engineer.

---

# Document the Test Perspective

Every test method MUST carry documentation explaining the
perspective it verifies.

In Java: JavaDoc on the test method.

In TypeScript, Kotlin, Python, or other languages: the equivalent
doc-comment convention immediately above the test.

The documentation MUST state:

- the specification requirement this perspective satisfies
- why this perspective is necessary to validate that requirement

FORBIDDEN:

- test methods without a documented perspective
- documentation that only restates the method name
- comments that describe implementation detail instead of
  specification

If the perspective cannot be articulated as a specification
requirement, the test is verifying an implementation detail —
not a behavior.

Remove it and write a test that expresses a real requirement.

---

# Tests Protect the Domain

Domain behavior MUST be thoroughly specified.

The domain is the highest-value layer.
Protect it with strong tests.

---

# Core Directive

Write tests that define behavior clearly enough
that future engineers can understand the system without reading the implementation.
