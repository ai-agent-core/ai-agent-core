# Glossary

This glossary defines the canonical vocabulary used across the system.

Agents and engineers MUST use these terms consistently.

Synonyms are forbidden unless explicitly defined.

Inconsistent language produces inconsistent architecture.

Naming is architecture.

---

# Core Concepts

## Architecture
The high-level structural design of a system, including boundaries,
dependencies, and interaction patterns.

Architecture governs long-term system behavior.

It MUST NOT emerge accidentally.

---

## Domain
The core business knowledge the system exists to model and protect.

The domain is the highest-value asset.

Infrastructure must serve the domain — never the reverse.

---

## Domain Model
A structured representation of domain concepts,
rules, and invariants.

The model must reflect reality clearly enough
to support safe evolution.

---

## Boundary
A clear separation between parts of the system that prevents
uncontrolled coupling.

Strong boundaries enable independent change.

Weak boundaries create systemic risk.

---

## Layer
A logical separation of responsibilities within the system.

Layers enforce dependency direction
and protect architectural clarity.

Typical dependency flow:

Outer → Inner  
Infrastructure → Application → Domain

Never reverse this direction.

---

## Dependency Direction
The mandated flow of dependencies toward the domain.

Dependencies MUST point inward.

The domain must remain independent.

---

## Entity
An object defined by identity and continuity over time.

Entities encapsulate critical business state.

They MUST protect their invariants.

Entities belong to the domain.

---

## Value Object
An immutable object defined entirely by its attributes.

Value Objects:

- have no identity
- are interchangeable
- are safe to share

Prefer Value Objects when identity is unnecessary.

---

## Aggregate
A consistency boundary that groups related entities
under a single transactional rule.

Aggregates protect invariants.

External access MUST go through the aggregate root.

---

## Aggregate Root
The entry point that controls access to an aggregate.

It is responsible for enforcing business rules.

Direct modification of internal members is forbidden.

---

## Invariant
A rule that must always remain true within the domain.

If an invariant can be broken,
the model is incorrect.

Protect invariants aggressively.

---

## Repository
An abstraction responsible for retrieving and persisting
aggregate roots.

Repositories belong to the domain layer as interfaces.

Implementations belong to infrastructure.

Repositories MUST NOT contain business logic.

---

## Infrastructure
Technical capabilities that support the domain,
such as databases, messaging systems, and external services.

Infrastructure is replaceable.

The domain is not.

---

## Application Layer
Coordinates use cases and orchestrates domain behavior.

It does NOT contain core business rules.

Think of it as a workflow layer.

---

## Use Case
A defined interaction that produces a meaningful business outcome.

Use cases describe intent — not implementation mechanics.

---

## Contract
An explicit definition of behavior between components.

Contracts eliminate ambiguity.

Implicit contracts create hidden failures.

---

## Mapper
A component responsible for translating between models
across boundaries.

Mapping MUST be explicit.

Hidden transformations are forbidden.

---

## Generator
A deterministic mechanism that produces artifacts
from a defined source.

Generators MUST be reproducible.

Manual drift from generated artifacts is forbidden.

---

## Structural Integrity
The condition in which architectural boundaries,
dependency direction, and domain isolation remain intact.

Structural damage compounds silently.

Protect it aggressively.

---

## Accidental Architecture
Structure that emerges unintentionally from local decisions.

Warning signs:

- inconsistent patterns
- unclear ownership
- duplicated concepts

Accidental architecture is systemic risk.

---

## Governance
The system by which rules are interpreted,
prioritized, and enforced.

Without governance, rules devolve into opinion.

---

## Principle
A foundational belief that guides decision-making.

Principles inform judgment when rules are insufficient.

---

## Rule
An enforceable constraint on behavior or design.

Rules reduce ambiguity.

They are not suggestions.

---

## Meta Rule
A rule that governs how other rules are applied.

Meta Rules function as constitutional law.

---

## Boot Sequence
The mandatory reading and initialization order
required before agents act.

Skipping the boot sequence is forbidden.

---

## Escalation
The act of requesting human clarification
when no safe decision is apparent.

Escalation is a sign of discipline —
not weakness.

---

## Structural Drift
The gradual erosion of architectural clarity
caused by repeated small violations.

Drift is rarely noticed until correction is expensive.

Prevent it early.

---

## Prime Directive
The overriding objective that guides all design decisions:

Preserve long-term architectural integrity
over short-term convenience.
