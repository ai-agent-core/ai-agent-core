# Coding Rules

Code MUST reflect architectural intent.

Readable code is REQUIRED.
Predictable code is REQUIRED.
Maintainable code is REQUIRED.

Clever code is FORBIDDEN.

---

# Prefer Clarity Over Cleverness

Agents MUST write code that is immediately understandable.

Avoid:

- hidden behavior
- surprising side effects
- overly compact expressions

Code should be obvious to future readers.

---

# Optimize for Readability

Code is read more than it is written.

Agents MUST favor:

- clear naming
- simple control flow
- minimal nesting

If something requires explanation,
rewrite it.

---

# Functions Must Be Small

Functions SHOULD do one thing.

Recommended guideline:

- Prefer under ~20 lines
- Avoid deep branching

Large functions indicate unclear responsibility.

---

# Single Responsibility

Each class MUST have one reason to change.

Avoid "god classes".

If a class accumulates unrelated behavior,
split it.

---

# Explicit Dependencies Only

Dependencies MUST be visible.

Use constructor injection.

FORBIDDEN:

- hidden globals
- service locators
- runtime dependency lookup

Explicit systems are safer systems.

---

# Immutability Preferred

Prefer immutable objects whenever possible.

Mutation SHOULD be intentional and controlled.

Uncontrolled mutation increases cognitive load.

---

# Avoid Boolean Parameters

Boolean parameters obscure intent.

Avoid:

createUser(true)


Prefer:

createAdminUser()


Make behavior explicit.

---

# Fail Fast

Agents MUST NOT hide errors.

Validate early.
Throw early.

Silent failure is forbidden.

---

# No Defensive Overengineering

Do NOT introduce abstraction without evidence.

Avoid:

- speculative generalization
- premature extensibility

Build for today's requirements.
Refactor when patterns emerge.

---

# Comments Are Not a Substitute for Good Code

Prefer self-explanatory code.

Use comments ONLY to explain:

- why something exists
- non-obvious constraints
- architectural decisions

Do NOT comment the obvious.

---

# Consistent Error Handling

Errors MUST be:

- meaningful
- actionable
- traceable

Avoid generic exceptions.

Provide context.

---

# Logging With Intent

Logs MUST provide diagnostic value.

Avoid noisy logging.

Log:

- state transitions
- failures
- boundary crossings

Do NOT log everything.

Signal beats noise.

---

# Avoid Temporal Coupling

Code SHOULD NOT depend on execution order unless explicitly required.

Hidden sequencing creates fragile systems.

Make ordering explicit.

---

# Prefer Composition Over Inheritance

Favor composition.

Inheritance SHOULD be rare and justified.

Deep hierarchies increase rigidity.

---

# Keep Constructors Simple

Constructors MUST NOT contain business logic.

They should only establish valid state.

Complex initialization belongs elsewhere.

---

# Protect the Domain

Domain models MUST remain free from:

- framework annotations
- infrastructure concerns
- transport models

The domain is the core.
Keep it clean.

---

# Consistency Over Personal Style

Follow existing patterns.

Do NOT introduce stylistic variation.

Local preference must yield to system consistency.

---

# Leave the Code Better

When modifying code:

- improve naming
- simplify logic
- reduce ambiguity

Small improvements compound over time.

---

# Core Directive

Write code that a senior engineer would not need to rewrite.