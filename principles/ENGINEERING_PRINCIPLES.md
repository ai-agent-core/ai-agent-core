# Engineering Principles

These principles define the foundation of all engineering decisions.

Agents MUST internalize these principles before writing code or proposing designs.

---

# System Over Local Optimization

Always prioritize system-wide consistency over local improvements.

DO NOT optimize a single component at the cost of architectural integrity.

Consistency is a feature.

---

# Architectural Correctness First

Correct architecture is more important than fast implementation.

Agents MUST prefer:

- clear boundaries
- explicit dependencies
- predictable behavior

Over:

- shortcuts
- hidden coupling
- implicit behavior

---

# Explicit Over Implicit

All dependencies MUST be visible.

Avoid magic behavior.

Avoid hidden side effects.

Prefer code that is obvious to future maintainers.

---

# Maintainability Is a Primary Requirement

Code is read far more than it is written.

Agents MUST optimize for:

- readability
- traceability
- debuggability

Never sacrifice maintainability for brevity.

---

# Prefer Simplicity, Reject Cleverness

Simple systems scale.
Clever systems collapse.

Agents MUST favor boring, well-understood patterns.

DO NOT introduce novelty without strong justification.

---

# Strong Boundaries Create Strong Systems

Well-defined boundaries are REQUIRED.

Agents MUST respect:

- layer separation
- domain integrity
- dependency direction

Boundary violations are critical failures.

---

# Testability Drives Design

If something is hard to test,
the design is likely wrong.

Agents SHOULD prefer designs that enable:

- deterministic behavior
- dependency injection
- isolation

---

# Fail Loudly

Avoid silent failure.

Errors MUST be:

- visible
- traceable
- actionable

Avoid swallowing exceptions.

---

# Avoid Premature Abstraction

Do not generalize early.

Agents MUST:

- implement what is needed now
- abstract only after patterns emerge

Overengineering is a defect.

---

# Long-Term Thinking

Favor decisions that improve the system over time.

Agents MUST consider:

- future change
- operational cost
- cognitive load

Short-term speed should not create long-term fragility.

---

# Core Directive

Build systems that remain understandable under change.

Durability is the goal.
