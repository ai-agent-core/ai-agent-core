# Layer Dependency Rules

These rules strictly define how layers may depend on each other.

Agents MUST enforce these rules at all times.

Layer violations are critical failures.

---

# Canonical Layer Model

Systems MUST follow this dependency flow:

Presentation → Application → Domain  
Infrastructure → Domain (via interfaces)

Dependencies MUST point inward.

Never outward.

---

# Domain Layer (Highest Protection)

The Domain layer is the center of the system.

It MUST remain independent from:

- frameworks
- databases
- web layers
- external services

FORBIDDEN:

- importing infrastructure modules
- referencing ORM entities
- accessing network clients
- reading environment configuration

The domain must be portable.

---

# Application Layer

The Application layer orchestrates use cases.

Allowed dependencies:

- Domain

FORBIDDEN:

- direct database access
- calling controllers
- embedding infrastructure logic

Application defines WHAT happens.
Infrastructure defines HOW.

---

# Presentation Layer

Responsible only for:

- request handling
- response shaping
- validation
- authentication boundaries

FORBIDDEN:

- business logic
- repository access
- domain mutation outside use cases

Controllers must remain thin.

---

# Infrastructure Layer

Implements technical concerns such as:

- persistence
- messaging
- external APIs
- file systems

Infrastructure MAY depend on Domain interfaces.

NEVER the opposite.

---

# Interface Rule (Critical)

Ownership of interfaces MUST belong to the inner layer.

Example:

Domain defines:

`OrderRepository`

Infrastructure implements it.

FORBIDDEN:

Domain referencing implementation classes.

Dependency inversion is REQUIRED.

---

# No Layer Skipping

Agents MUST NOT bypass layers.

FORBIDDEN:

Presentation → Domain  
Presentation → Infrastructure  
Application → Database

Always go through the proper boundary.

Shortcuts are architectural damage.

---

# Model Separation

Agents MUST separate models across layers.

DO NOT leak:

- ORM entities into domain
- API DTOs into domain
- persistence schemas into business logic

Mapping is REQUIRED.

Yes, even if it feels repetitive.

Repetition is safer than coupling.

---

# Cross-Layer Utilities

Shared utilities MUST NOT introduce reverse dependencies.

If a utility requires infrastructure,
it does NOT belong in domain.

When unsure:

Move outward, not inward.

---

# Circular Dependency Ban

Circular dependencies are strictly FORBIDDEN.

Agents MUST restructure code immediately if a cycle appears.

A cycle indicates a broken boundary.

---

# Framework Containment Rule

Framework code MUST stay at the edges.

Agents MUST prevent frameworks from spreading inward.

Example:

BAD:
Domain annotations tied to ORM.

GOOD:
Framework annotations confined to infrastructure.

Frameworks are tools.
Not the core.

---

# Testing Boundary Integrity

Architecture SHOULD remain enforceable through tests when possible.

Agents SHOULD favor designs compatible with tools such as:

- ArchUnit
- dependency validation
- module boundaries

If architecture cannot be tested,
it is too weak.

---

# When Unsure

Agents MUST choose the safer path:

→ prefer stronger boundaries  
→ prefer more separation  
→ prefer explicit mapping

Safety over convenience.

---

# Core Directive

Protect the dependency flow.

Once dependency direction collapses,
architecture follows.
