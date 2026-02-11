# Error Handling Rules

Errors are a first-class design concern.

Agents MUST treat failure as an expected condition,
not an exception to ignore.

Systems MUST remain diagnosable under failure.

---

# Fail Fast

Agents MUST detect errors as early as possible.

DO NOT allow corrupted state to propagate.

Validate inputs at boundaries.
Reject invalid data immediately.

Early failure reduces systemic damage.

---

# Never Swallow Exceptions

Catching an exception without handling it is FORBIDDEN.

Forbidden patterns:

- empty catch blocks
- logging without action
- converting errors into silent nulls

Every error must lead to an explicit outcome.

---

# Preserve Context

Errors MUST carry meaningful context.

Include:

- identifiers
- relevant state
- operation details

Avoid generic messages such as:

"Something went wrong"

Make diagnostics actionable.

---

# Prefer Domain Errors

Business failures SHOULD be represented as domain-level errors.

Examples:

- `InsufficientFundsError`
- `OrderAlreadyShippedError`

Do NOT rely on technical exceptions to model business rules.

The domain must speak the business language.

---

# Technical vs Domain Failures

Agents MUST distinguish between:

## Domain failures
Expected outcomes driven by business rules.

## Technical failures
Unexpected infrastructure or system problems.

These SHOULD NOT be conflated.

---

# Do Not Leak Infrastructure Errors

Infrastructure exceptions SHOULD NOT cross into the domain.

Translate them at the boundary.

Example:

DatabaseTimeoutException  
→ PersistenceUnavailableError

Protect the domain from technical noise.

---

# Use Exceptions Intentionally

Exceptions are for exceptional conditions.

DO NOT use exceptions for normal control flow.

Prefer explicit results when failure is expected.

---

# Avoid Null as Failure

Returning null is FORBIDDEN when representing failure.

Prefer:

- Optional
- Result types
- Either patterns

Null hides intent and causes runtime surprises.

---

# Make Failures Observable

Failures MUST be visible.

Systems SHOULD support:

- structured logging
- tracing
- correlation IDs

If a failure cannot be observed,
it cannot be fixed.

---

# Boundary Validation

All external inputs MUST be validated at system boundaries.

Never trust:

- user input
- external APIs
- message queues

Trust is not a strategy.

---

# Idempotency Awareness

Agents SHOULD consider idempotency in operations that may retry.

Systems must remain safe under duplicate execution.

---

# Avoid Error Translation Chains

Repeated wrapping of errors reduces clarity.

Translate once at the boundary.
Preserve the root cause.

Clarity beats abstraction.

---

# Consistent Error Strategy

Projects MUST adopt a unified error strategy.

Avoid mixing patterns such as:

- exceptions
- error codes
- result objects

Pick a strategy.
Apply it consistently.

---

# Protect System Stability

When failure occurs,
agents MUST favor system stability over partial progress.

Safe rollback is preferred over undefined state.

---

# Core Directive

Design systems that fail loudly,
recover safely,
and remain diagnosable.
