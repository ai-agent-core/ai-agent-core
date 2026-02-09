# Architecture Principles

These principles define how systems MUST be structured.

Agents are REQUIRED to follow these principles when proposing or implementing architecture.

Architecture is not a preference.
It is a constraint.

---

# Architecture Before Implementation

Agents MUST design the structure before writing code.

DO NOT start implementation without understanding:

- system boundaries
- dependency flow
- domain separation

Code without structure is technical debt.

---

# Enforce Clear Layering

Systems MUST be organized into explicit layers.

Example:

- Presentation
- Application
- Domain
- Infrastructure

Each layer has a single responsibility.

Layer mixing is FORBIDDEN.

---

# Dependency Direction Is Sacred

Dependencies MUST flow inward.

Allowed direction:

Presentation → Application → Domain  
Infrastructure → Domain (via interfaces)

FORBIDDEN:

- Domain depending on Infrastructure
- Application depending on Presentation
- Circular dependencies

Violations are critical architectural failures.

---

# Protect the Domain

The Domain layer is the core of the system.

Agents MUST ensure the domain:

- remains framework-independent
- contains business logic only
- avoids technical concerns

Frameworks are replaceable.
The domain is not.

---

# Boundaries Over Convenience

Agents MUST NOT cross boundaries for convenience.

Examples of forbidden behavior:

- controllers calling repositories directly
- domain objects accessing databases
- leaking infrastructure models into domain

Shortcuts create fragility.

---

# Explicit Interfaces

Integration between layers MUST happen through clear interfaces.

Agents SHOULD favor:

- dependency inversion
- contract-driven design
- replaceable components

Hidden coupling is forbidden.

---

# Prefer Cohesion, Reject Coupling

High cohesion within components is REQUIRED.  
Tight coupling between components is FORBIDDEN.

Agents MUST group behavior with the data it belongs to.

Avoid “god classes” and distributed logic.

---

# Design for Change

Systems MUST be built with evolution in mind.

Agents SHOULD consider:

- how features will expand
- where variability is likely
- what must remain stable

Rigid systems fail under change.

---

# Avoid Architectural Novelty

Use proven patterns.

Agents MUST NOT introduce experimental architecture unless explicitly requested.

Boring architecture scales.
Novel architecture breaks.

---

# Separate Business Logic From Technology

Business rules MUST NOT depend on frameworks, databases, or delivery mechanisms.

The system should remain understandable even if technologies change.

Technology is a detail.
The model is the system.

---

# Optimize for Cognitive Load

Architecture MUST reduce the mental effort required to understand the system.

Agents SHOULD favor:

- predictable structure
- consistent naming
- obvious boundaries

If the design is hard to explain,
it is likely too complex.

---

# One System, One Style

Agents MUST maintain architectural consistency.

DO NOT mix multiple architectural styles without strong justification.

Inconsistency increases entropy.

---

# Architectural Integrity Over Speed

Agents MUST reject changes that compromise structure,
even if they accelerate delivery.

Speed gained through structural damage creates long-term drag.

---

# Core Directive

Build architectures that remain stable as the system grows.

Stability enables velocity.
