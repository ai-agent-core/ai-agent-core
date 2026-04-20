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

# Domain-Driven Package Structure

Packages MUST be organized around the domain — not around technical roles.

Top-level structure MUST reflect bounded contexts and aggregates.

FORBIDDEN default layouts:

- flat `controllers/`, `services/`, `dtos/`, `repositories/` at the root
- packages named only after technical concerns
- domain concepts scattered across unrelated technical folders

REQUIRED pattern:

- bounded context at the top
- aggregate or cohesive concept below it
- technical layering exists only within each domain package

The domain shape MUST be visible from the package tree alone.

If an outsider cannot infer the business from the folder structure,
the structure is wrong.

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

# Right-Size the Aggregation Unit

DDD is a tool, not an ideology.

Over-applied DDD fragments business reality into unrelated pieces
and creates more damage than it prevents.

Aggregate and responsibility boundaries MUST reflect
actual business invariants —
never theoretical decomposition for its own sake.

## Agree the unit with the instructor

Agents MUST NOT decide aggregation granularity unilaterally.

Before separating responsibilities, agents MUST:

1. identify what the business treats as a single unit of work
2. confirm that unit explicitly with the instructor
3. separate only along the confirmed boundary

If the instructor cannot articulate the unit,
stop and resolve the ambiguity before coding.

## Bias toward fewer, larger aggregates

When in doubt, err toward a single larger aggregate.

Split only when a concrete invariant demands it.

Symptoms of over-separation (CRITICAL):

- a single business action cascades across many repositories
- cross-aggregate transactions become routine
- terms treated as "one thing" by the business are fragmented across models
- changes to one concept require synchronized edits in multiple packages

Symptoms of under-separation:

- invariants from unrelated concerns collide inside one aggregate
- unrelated business rules share state
- the aggregate grows unbounded

Both are failures — but over-separation is the more common AI default.

Resist it.

---

# Boundaries Over Convenience

Avoid crossing boundaries for convenience.

Examples to avoid:

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

Avoid hidden coupling.

---

# Prefer Cohesion, Reject Coupling

High cohesion within components is REQUIRED.  
Avoid tight coupling between components.

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

Avoid introducing experimental architecture unless explicitly requested.

Boring architecture scales.
Novel architecture breaks.

---

# Separate Business Logic From Technology

Business rules SHOULD NOT depend on frameworks, databases, or delivery mechanisms.

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
