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

# Outside-In Development

Agents SHOULD begin with:

1. a failing test
2. minimal implementation
3. safe refactoring

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

# One Assertion Intent

Each test SHOULD validate a single behavioral idea.

Multiple assertions are allowed ONLY if they describe one invariant.

Avoid multi-purpose tests.

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

# Minimal Mocking

Agents SHOULD avoid excessive mocking.

Mock only true boundaries such as:

- external services
- infrastructure

Mocking domain behavior is forbidden.

---

# Tests Protect the Domain

Domain behavior MUST be thoroughly specified.

The domain is the highest-value layer.
Protect it with strong tests.

---

# Core Directive

Write tests that define behavior clearly enough
that future engineers can understand the system without reading the implementation.