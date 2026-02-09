# Mapper Rules

Mappers are responsible only for translating between domain models and persistence models.

They MUST NOT contain business logic.

---

# Core Responsibility

A mapper MUST:

- convert persistence models into domain models
- convert domain models into persistence models

Nothing more.

---

# Forbidden Behavior

Mappers MUST NOT:

- enforce business rules
- validate domain invariants
- perform calculations
- call external services
- access repositories

If logic is required, it belongs in the domain.

---

# Domain Protection

Mapping MUST preserve domain purity.

Persistence concerns MUST NOT leak into domain models.

Examples of forbidden leakage:

- ORM annotations
- lazy-loading dependencies
- database identifiers exposed as primitives

---

# Explicit Mapping

Mappings SHOULD be explicit.

Avoid hidden or reflection-based transformations when they reduce clarity.

Readable mapping is preferred over clever mapping.

---

# Fail Fast

If a persistence model cannot be safely mapped to a domain model,
the mapper MUST fail immediately.

Silent corruption is forbidden.

---

# No Partial Aggregates

Mappers MUST NOT create incomplete domain aggregates.

Either construct a valid aggregate,
or fail.

---

# Simplicity Over Automation

Prefer simple mapping strategies.

Automation is allowed only if it does not:

- obscure behavior
- hide field transformations
- reduce debuggability

Clarity is the priority.

---

# Core Directive

Mappers translate.
Domains decide.
Repositories coordinate.
