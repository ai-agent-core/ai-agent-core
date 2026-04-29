---
name: code-review
description: Review a diff or branch against AI Agent Core principles. Flag architecture, domain, naming, and testing violations before approving.
---

# Code review

Use this skill **whenever you review existing or proposed code**,
including your own diff before declaring work done.

A code review under AI Agent Core is not a style pass. It is an
architectural integrity check.

---

## Pass order (top-down)

Review in this order. Earlier failures gate later checks.

### 1. Boundaries

- Does the diff respect the four-layer convention
  (`interfaces/applications/domains/architectures/`)?
- Is dependency direction correct
  (`interfaces → applications → domains`,
  `architectures → domains` via interface)?
- Is `domains/` framework-free and infrastructure-free?
- See skill `architecture-guard` for the full checklist.

### 2. Aggregates

- Is aggregate granularity confirmed with the user, not invented?
- Does a single business action stay inside a single aggregate
  whenever possible?
- See skill `aggregate-boundary`.

### 3. Naming

- Aggregates: singular noun, no `Entity`/`Model`/`Record` suffix.
- Repositories: `<Aggregate>Repository`.
- Application services: `<Verb>UseCase`. No `Manager`, no
  `Handler`, no `Processor`.
- Persistence models: `JpaModel`, `DbModel`, `Record`, `Table` —
  never bare `Entity`.
- DTOs: explicit (`OrderResponse`, `CreateOrderRequest`), never
  `OrderDTO`.
- Booleans: `isPaid`, `hasAccess`, `canCancel`. Not `flag`,
  `status`, `value`.

### 4. Coding

- Functions small, single-responsibility, low nesting.
- Constructor-injected dependencies; no globals, no service
  locators, no runtime lookup.
- Immutability preferred; mutation intentional and contained.
- No boolean parameters that obscure intent.
- No defensive abstractions without evidence.
- Comments explain *why*, never *what*.
- Errors meaningful, actionable, traceable; no silent failures.

### 5. Tests

- Every behavior change is covered by a *new* test that defines it
  (skill `tdd`).
- Tests interact only through public interfaces.
- Each test method verifies one perspective; the perspective is
  documented.
- Mocking is limited to repository interfaces and external API
  clients. Anything else is forbidden.
- Tests are deterministic and local-first.

### 6. Frontend (when applicable)

- Run skill `frontend-design`'s completion gate.
- Debug UI lives only in the outermost layout's debug header; it
  does not interfere with production screens.

---

## Output format

When reporting findings, structure them as:

```
[BLOCKER]   <one-line summary>           — file:line
[MAJOR]     <one-line summary>           — file:line
[MINOR]     <one-line summary>           — file:line
[QUESTION]  <one-line summary>           — file:line
```

For each item, state the rule it violates (or the principle it
weakens) and the smallest fix that would resolve it.

---

## When to refuse approval

- Any BLOCKER on Boundaries, Aggregates, or Tests.
- Any change that weakens domain integrity for a faster path.
- Any "we will fix it later" claim that is not already a tracked
  task in `tasks/todo.md` or the Issue.

Speed is temporary. Structural damage is permanent.
