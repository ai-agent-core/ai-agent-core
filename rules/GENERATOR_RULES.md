# Generator Rules

Generators are responsible for enforcing architectural consistency across projects.

Generators MUST NOT be treated as convenience tools.

They are structural enforcement mechanisms.

---

# Architecture Enforcement

Generators MUST produce code that conforms to:

- layer boundaries
- dependency direction
- module structure
- naming conventions

Generated code MUST be architecturally safe by default.

Unsafe generation is forbidden.

---

# Deterministic Output

Generation MUST be deterministic.

The same inputs MUST always produce the same outputs.

Non-deterministic generation is forbidden.

Reproducibility is mandatory.

---

# Schema-Driven Generation

When persistence is involved, generators MUST use the database schema as the source of truth.

Manual structural divergence is forbidden.

The schema defines the structure.
Generators reflect it.

---

# No Manual Editing of Generated Code

Generated artifacts MUST NOT be manually modified.

If customization is required:

→ modify the generator  
→ extend safely via composition

Never patch generated files.

---

# Regeneration Safety

Projects MUST remain safe to regenerate at any time.

Generation MUST NOT destroy:

- domain logic
- custom application code
- handwritten behavior

Clear separation between generated and handwritten code is REQUIRED.

---

# Prefer Generation Over Repetition

If a pattern appears more than once,
agents SHOULD consider generator expansion.

Repetition is a signal.
Generators remove it.

---

# Protect the Domain

Generators MUST NOT:

- generate domain behavior
- embed business logic
- define domain invariants

Domain knowledge belongs to humans.

Generators create structure.
Not meaning.

---

# Integration With Existing Ecosystem

If proven generation mechanisms already exist,
agents MUST prefer them.

Reinventing generators increases systemic risk.

Consistency across projects is more valuable than novelty.

---

# Generator Scope Control

Generators MUST remain focused on structure.

They MUST NOT evolve into:

- workflow engines
- decision systems
- business rule processors

Overreach creates fragility.

---

# Core Directive

Generators exist to make the correct architecture the easiest architecture to build.
