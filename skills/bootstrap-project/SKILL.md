---
name: bootstrap-project
description: Initialize a new project layout under Agent Core — mandatory modules, four-layer convention, migration-as-source-of-truth.
---

# Bootstrap project

Use this skill **only when initializing a new project layout** (a
new repository, a new module within a monorepo, or a new stack
under an existing project). Do not use it for routine work.

Authoritative rules:

- `agent-core/rules/PROJECT_STRUCTURE_RULES.md`
- `agent-core/rules/PACKAGE_LAYOUT_COMMON_RULES.md`
- `agent-core/rules/PACKAGE_LAYOUT_BACKEND_RULES.md`
- `agent-core/rules/PACKAGE_LAYOUT_FUNCTIONS_RULES.md`
- `agent-core/rules/PACKAGE_LAYOUT_FRONTEND_RULES.md`
- `agent-core/rules/GENERATOR_RULES.md`

---

## Phase 1 — confirm scope with the user

Before creating a single file, confirm:

- Project name (`${projectName}`).
- Target stacks (one or more of `backend`, `functions`, `frontend`).
- Persistence target (engine, hosting, migration tool).
- Whether existing infrastructure (API, generators, migration
  framework) already exists and SHOULD be reused per
  PROJECT_STRUCTURE_RULES.md "Prefer Existing Mechanisms."
- Initial bounded contexts and aggregates (see skill
  `aggregate-boundary` — bias toward fewer, larger aggregates).

Reflect the confirmed scope into `tasks/todo.md`.

### Default stacks (unless overridden)

| Stack      | Default                                                |
| ---------- | ------------------------------------------------------ |
| Frontend   | SvelteKit + TypeScript (strict) + Tailwind CSS + pnpm  |
| Backend    | per the team / language ADR (Java / Kotlin / Go / TS)  |
| Database   | PostgreSQL                                             |
| Infra      | IaC (Terraform / Pulumi / cloud-native)                |
| CI / CD    | GitHub Actions (or platform-native)                    |

Choosing a non-default stack is a deliberate, written decision —
skill `adr`.

---

## Phase 2 — mandatory modules (every project)

Create at the repository root:

- `${projectName}-entity` — generated persistence models from
  schema. No domain logic.
- `${projectName}-migration` — versioned migrations; the schema
  source of truth. Direct, unmanaged schema changes are forbidden.
- `${projectName}-generator` — deterministic, reproducible code
  generation against the schema.

The system MUST be reproducible from migrations alone. Manual
divergence from the schema is forbidden.

---

## Phase 3 — four-layer convention per stack module

Every stack module (backend, functions, frontend) adopts the same
four top-level layers (plural names):

```
interfaces/      -> HTTP / CLI / FN / UI shell
applications/    -> use cases, orchestrators
domains/         -> aggregates, repositories (interface), services
architectures/   -> infrastructure adapters
```

Inside each layer, organise by **bounded context first**, technical
role second. Flat `controllers/`, `services/`, `dtos/` at any layer
root is forbidden.

---

## Phase 4 — wire generator and migration

- Migrations land in `${projectName}-migration` only.
- `${projectName}-generator` reads migrations / live schema and
  emits into `${projectName}-entity`.
- Generation is deterministic and re-runnable. No manual patching
  of generated artifacts.

---

## Phase 5 — install Agent Core in the new project

If the new project will use Agent Core, run:

```bash
./agent-core/init/bootstrap.sh
```

This writes only `AGENTS.md` and `CLAUDE.md` to the project root,
and provisions `agent-core/generated/tasks/todo.md` and
`tasks/lessons.md` inside the agent-core directory.

`agent-core/generated/` is gitignored by agent-core itself. If
agent-core is vendored (not a submodule), add the same line to the
host project's `.gitignore`.

---

## Phase 6 — verify

- Tree matches the conventions above (run a tree dump and compare).
- Generator produces entities cleanly from the migration.
- A single end-to-end smoke test runs locally with no shared
  cloud / staging dependencies.

When verified, commit the layout. Open the work for normal feature
development; switch to skill `plan-and-implement` for the first
real feature.
