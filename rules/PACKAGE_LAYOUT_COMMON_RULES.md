# Package Layout Rules — Common

This document defines the shared conventions that govern package
layout across all stacks.

Stack-specific rules live in:

- `rules/PACKAGE_LAYOUT_BACKEND_RULES.md`
- `rules/PACKAGE_LAYOUT_FUNCTIONS_RULES.md`
- `rules/PACKAGE_LAYOUT_FRONTEND_RULES.md`

Package structure is the visible shape of the domain.

Agents MUST follow the shared rules below for every new module,
and MUST NOT invent alternative layouts without explicit
architectural justification agreed with the instructor.

---

# The Four-Layer Convention (ALL STACKS)

Every project — backend, functions, frontend — MUST adopt a
four-layer top-level package structure:

- `interfaces/`
- `applications/`
- `domains/`
- `architectures/`

All plural.

The four names are constant across all stacks.

Stack-specific details vary only within each layer.

Layering is non-negotiable.

---

# Dependency Direction (ALL STACKS)

Allowed dependency flow:

`interfaces/` → `applications/` → `domains/`

`architectures/` → `domains/` (via interfaces declared in `domains/`)

FORBIDDEN:

- `domains/` depending on any other layer
- `applications/` depending on `interfaces/` or `architectures/`
- `architectures/` depending on `applications/` or `interfaces/`
- any circular dependency at any granularity

`architectures/` implements contracts declared in `domains/`.

Dependency inversion is mandatory at the `architectures/` boundary.

---

# Bounded Context First

Within each layer, packages MUST be organized first by bounded
context, and only within that context by technical concern.

FORBIDDEN:

- flat `controllers/`, `services/`, `dtos/` at any layer root
- technical folders at a higher level than domain folders

REQUIRED shape:

```
<layer>/<context>/<stereotype-files>
```

The business domain MUST be visible from the package tree alone.

---

# Core Directive

The layout is the architecture made visible.

Protect it as strictly as the domain itself.
