---
name: architecture-guard
description: Before any change that crosses layer boundaries, dependency direction, or domain purity, run this checklist. Refuse changes that weaken the architecture even if they are faster.
---

# Architecture guard

Use this skill **before merging any change that touches layer
boundaries, dependency direction, or the domain layer**. The skill
is a checklist; it does not rewrite the architecture rules. The
authoritative rules live in:

- `ai-agent-core/principles/ARCHITECTURE_PRINCIPLES.md`
- `ai-agent-core/rules/LAYER_DEPENDENCY_RULES.md`
- `ai-agent-core/rules/PACKAGE_LAYOUT_*_RULES.md`
- `ai-agent-core/rules/MAPPER_RULES.md`

---

## Four-layer convention (all stacks)

Every project — backend, functions, frontend — has the same four
top-level layers (plural names, constant across stacks):

```
interfaces/      -> entrypoints (HTTP, CLI, FN, UI shell)
applications/    -> use cases, orchestrators
domains/         -> aggregates, entities, value objects, repositories (interface)
architectures/   -> infrastructure adapters implementing domain interfaces
```

Inside each layer, packages are organised by **bounded context
first**, technical role second. A flat `controllers/` or `services/`
at any layer root is forbidden.

---

## Allowed dependency flow

```
interfaces/  ->  applications/  ->  domains/
architectures/  ->  domains/   (via interfaces declared in domains/)
```

Forbidden:

- `domains/` depending on any other layer.
- `applications/` depending on `interfaces/` or `architectures/`.
- `architectures/` depending on `applications/` or `interfaces/`.
- Any circular dependency at any granularity.

---

## Pre-merge checklist

Run through every item before declaring the change architecturally
safe. A single "no" blocks merge.

1. Does the change keep `domains/` framework-free, persistence-free,
   transport-free?
2. Does every cross-layer call go through an interface declared in
   `domains/` (dependency inversion)?
3. Are the new files placed under `<layer>/<context>/...`, not under
   technical-role-first folders?
4. Does the diff *avoid* introducing:
   - controllers calling repositories directly?
   - domain objects accessing databases / HTTP / framework APIs?
   - infrastructure types leaking into `domains/`?
5. Are persistence models clearly distinguished from domain entities
   (e.g. `OrderRecord`, `OrderJpaModel`, never bare `OrderEntity`)?
6. Is the boundary between aggregates intact? See skill
   `aggregate-boundary` if granularity is in question.
7. Does the diff respect existing patterns? If it introduces a new
   stylistic variation, has it been justified architecturally and
   confirmed with the user?

---

## Refusal protocol

If a request would violate the checklist:

- Refuse silently-fast paths. Speed is not a justification.
- Surface the architectural cost in plain language ("this couples
  Domain to Postgres; we lose framework independence").
- Offer the smallest correctly-layered alternative.
- Escalate to the user if the alternative materially changes scope
  or effort.

The domain is the highest-value asset. Guard it relentlessly.
Short-term velocity must never override long-term structural
integrity.
