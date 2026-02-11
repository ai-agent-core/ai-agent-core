# Project Structure Rules

These rules define the mandatory structure for all projects.

Agents MUST follow these standards when creating or modifying project layouts.

Consistency across projects is REQUIRED.

---

# Database as the Source of Truth

The database schema MUST be treated as the authoritative source for persistence structure.

Entities MUST be generated from the database schema.

Reverse generation is REQUIRED.

Manual divergence from the schema is FORBIDDEN.

---

# Migration Is Mandatory

All database resources MUST be migration-driven.

Schema changes MUST occur through versioned migrations.

Direct, unmanaged schema modification is strictly FORBIDDEN.

The system MUST always be reproducible from migrations alone.

---

# Mandatory Project Modules

Every project MUST define the following modules at the repository root:

- `${projectName}-entity`
- `${projectName}-migration`
- `${projectName}-generator`

Agents MUST enforce this structure.

---

## `${projectName}-entity`

Responsible for:

- generated persistence models
- schema-derived objects
- database representations

This module SHOULD NOT contain domain logic.

These are persistence models, NOT domain entities.

---

## `${projectName}-migration`

Responsible for:

- schema evolution
- version control of database structure
- rollback capability
- reproducible database setup

All structural changes MUST originate here.

---

## `${projectName}-generator`

Responsible for:

- entity generation
- schema synchronization
- code generation workflows

Generation MUST be deterministic and reproducible.

Avoid manual patching of generated artifacts.

---

# Prefer Existing Mechanisms

When an existing project already provides:

- API infrastructure
- code generation
- migration frameworks
- shared tooling

Agents MUST prefer those mechanisms.

Avoid reinventing infrastructure unless explicitly justified.

Consistency across the ecosystem is more valuable than local optimization.

---

# Avoid Structural Drift

Projects SHOULD NOT invent custom layouts without strong justification.

Structural consistency enables:

- faster onboarding
- safer automation
- predictable AI behavior
- lower cognitive load

Deviation increases systemic risk.

---

# Core Directive

Build projects that are reproducible, automatable, and structurally predictable.
