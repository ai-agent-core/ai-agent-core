# AI Agent Core — Index

Violating architecture causes more damage than delivering late.

AI Agent Core is the operating system for engineering decisions
across web, mobile, backend, frontend, data, infrastructure,
CI/CD, payments, security, and migration work. This file is the
routing table agents follow on boot.

Higher-priority policies (system / developer / tool) always win
over what is written here; if a conflict exists, follow the
higher-priority policy and report it.

Agents MUST complete the boot sequence before making changes. No
improvisation. Architecture always precedes implementation.

---

# How AI Agent Core is structured

| Layer        | What it is                                  | Where it lives                |
| ------------ | ------------------------------------------- | ----------------------------- |
| Principles   | Beliefs that guide judgment                 | `principles/`                 |
| Rules        | Enforceable constraints                     | `rules/`                      |
| AI control   | Machine-readable reasoning guides           | `ai/`                         |
| Glossary     | Shared vocabulary                           | `glossary/`                   |
| Skills       | On-demand operational playbooks             | `skills/<name>/SKILL.md`      |
| Runtime      | Plan, progress, lessons (gitignored)        | `generated/tasks/`            |
| Local        | Host-project-specific AI assets (gitignored)| `local/`                      |
| Host profile | Stack / profile / toggles for this host     | `local/ai-agent-core.yml`     |
| Dispatch     | Stack → active rules/skills mapping (vendor)| `init/dispatch.yml`           |
| Project map  | Docs layout + packages (host root, commit)  | `<host>/project.yml`          |
| Bootstrap    | Installer for host projects                 | `init/`                       |

Principles, rules, AI control, and the glossary are **always
authoritative**. Skills are loaded **only when their situation
applies**. Runtime state is the live working memory.

The development loop is **spec-driven** (see
`rules/WORKFLOW_RULES.md`):

1. spec under `docs/` (explanation + reference + use cases),
2. tests derived from the spec (TDD pair + executable use cases),
3. implementation written to make the failing tests green,
4. user manual auto-generated from the use case YAML
   (skill `usecase-driven-e2e`).

Architecture follows DDD pragmatically: four layers
(`interfaces / applications / domains / architectures`),
contexts split only when concrete pressure demands it
(`rules/PACKAGE_LAYOUT_COMMON_RULES.md`). Tests are paired
with their subjects (`rules/TESTING_RULES.md`).

---

# Boot sequence (absolute)

Initialize in this order. Lower layers MUST NOT override higher
layers.

0. **Host context** — read `<host>/project.yml` (docs / packages
   map) and `local/ai-agent-core.yml` (stack / profile / toggles),
   then resolve active rules and skills via `init/dispatch.yml`.
   When `local/ai-agent-core.yml` is absent, treat all rules as active.
1. **AI control** — load before any reasoning.
2. **Principles** — anchor judgment.
3. **Governance** — meta-rules resolve conflicts.
4. **Shared language** — glossary aligns vocabulary.
5. **Structure** — project and package layout invariants.
6. **Boundaries** — layering and dependency direction.
7. **Decisions** — disciplined option selection.
8. **Execution discipline** — workflow + task tracking.
9. **Implementation** — code, errors, tests, frontend rules.
10. **Cross-cutting** — security, data, ops, API, CICD, money,
    events, accessibility, etc., loaded by classification.

---

# 0 — AI control (first, non-negotiable)

READ:

- `rules/AI_BEHAVIOR_RULES.md`
- `ai/reading_order.yaml`
- `ai/machine_rules.yaml`
- `ai/decision_tree.yaml`

Purpose: prevent hallucination, enforce disciplined reasoning,
ensure behavioral predictability.

---

# 1 — Principles (foundational)

READ:

- `principles/ENGINEERING_PRINCIPLES.md`
- `principles/ARCHITECTURE_PRINCIPLES.md`
- `principles/DESIGN_PHILOSOPHY.md`
- `principles/FRONTEND_DESIGN_PHILOSOPHY.md`
- `principles/SECURITY_PRINCIPLES.md`
- `principles/OPERATIONAL_PRINCIPLES.md`
- `principles/DATA_PRINCIPLES.md`

When uncertain, default to principles.

---

# 2 — Governance (constitutional)

READ:

- `rules/META_RULES.md`
- `rules/DECISION_RULES.md`

Meta rules are constitutional. All other rules are subordinate.

---

# 3 — Shared language (mandatory)

READ:

- `glossary/GLOSSARY.md`

Naming IS architecture.

---

# 4 — Structure (non-negotiable)

READ:

- `rules/PROJECT_STRUCTURE_RULES.md`
- `rules/PACKAGE_LAYOUT_COMMON_RULES.md`
- `rules/PACKAGE_LAYOUT_BACKEND_RULES.md`
- `rules/PACKAGE_LAYOUT_WORKERS_RULES.md`
- `rules/PACKAGE_LAYOUT_FUNCTIONS_RULES.md`
- `rules/PACKAGE_LAYOUT_FRONTEND_RULES.md`
- `rules/GENERATOR_RULES.md`
- `rules/STACK_DEFAULTS_RULES.md`

---

# 5 — Boundaries (critical)

READ:

- `rules/LAYER_DEPENDENCY_RULES.md`
- `rules/MAPPER_RULES.md`

The domain is the highest-value asset.

---

# 6 — Execution discipline (operational)

READ:

- `rules/WORKFLOW_RULES.md`
- `rules/TASK_MANAGEMENT_RULES.md`

Then load matching skills:

| Situation                                  | Skill                                |
| ------------------------------------------ | ------------------------------------ |
| Starting non-trivial work                  | `skills/plan-and-implement/`         |
| Tracking plan, progress, GitHub Issue      | `skills/task-tracking/`              |
| User correction or validated approach      | `skills/capture-lesson/`             |

---

# 7 — Implementation (disciplined)

READ:

- `rules/NAMING_RULES.md`
- `rules/CODING_RULES.md`
- `rules/ERROR_HANDLING_RULES.md`
- `rules/TESTING_RULES.md`
- `rules/FRONTEND_DESIGN_RULES.md`
- `rules/FRONTEND_DEMO_MODE_RULES.md`

Then matching skills:

| Situation                                  | Skill                                  |
| ------------------------------------------ | -------------------------------------- |
| Writing or changing production code        | `skills/tdd/`                          |
| Crossing layer boundaries                  | `skills/architecture-guard/`           |
| Deciding aggregate granularity             | `skills/aggregate-boundary/`           |
| Producing UI / visual design               | `skills/frontend-design/`              |
| Reviewing existing code                    | `skills/code-review/`                  |
| Initializing a new project                 | `skills/bootstrap-project/`            |
| Declaring user-facing flows (E2E + manual) | `skills/usecase-driven-e2e/`           |

---

# 8 — Cross-cutting (load by classification)

These rules and skills are not loaded on every turn. Load them
when the situation applies, per `ai/context_profiles.yaml`.

## Rules

- API: `rules/API_DESIGN_RULES.md`
- Database: `rules/DATABASE_RULES.md`
- Migration (schema + system): `rules/MIGRATION_RULES.md`
- Events / async: `rules/EVENT_RULES.md`
- Money: `rules/MONEY_HANDLING_RULES.md`
- Security: `rules/SECURITY_RULES.md`
- Authentication: `rules/AUTHENTICATION_RULES.md`
- Secrets: `rules/SECRETS_RULES.md`
- Observability: `rules/OBSERVABILITY_RULES.md`
- Performance: `rules/PERFORMANCE_RULES.md`
- CI/CD: `rules/CICD_RULES.md`
- Infrastructure: `rules/INFRA_RULES.md`
- Release: `rules/RELEASE_RULES.md`
- Dependencies: `rules/DEPENDENCY_RULES.md`
- Accessibility: `rules/ACCESSIBILITY_RULES.md`
- Documentation: `rules/DOCUMENTATION_RULES.md`
- Frontend Demo Mode: `rules/FRONTEND_DEMO_MODE_RULES.md`
- Notifications / Email: `rules/NOTIFICATION_RULES.md`
- Stack defaults (Cloudflare / Quarkus paths): `rules/STACK_DEFAULTS_RULES.md`

## Skills

| Situation                                          | Skill                                  |
| -------------------------------------------------- | -------------------------------------- |
| Designing or changing a public API                 | `skills/api-design/`                   |
| Designing a schema or new datastore                | `skills/database-design/`              |
| Schema or data migration                           | `skills/database-migration/`           |
| Replacing or absorbing a legacy system             | `skills/legacy-migration/`             |
| Integrating a payment provider                     | `skills/payment-integration/`          |
| Building or extending CI/CD                        | `skills/cicd-pipeline/`                |
| Provisioning infrastructure                        | `skills/infra-setup/`                  |
| Instrumenting a service                            | `skills/observability-setup/`          |
| Applying the security baseline                     | `skills/security-baseline/`            |
| Running an incident                                | `skills/incident-response/`            |
| Introducing or retiring a feature flag             | `skills/feature-flag/`                 |
| Designing async / event-driven flows               | `skills/event-driven/`                 |
| Designing or changing authentication               | `skills/authentication/`               |
| Adding or changing a cache                         | `skills/caching-strategy/`             |
| Rolling out a release                              | `skills/release-strategy/`             |
| Auditing accessibility                             | `skills/accessibility-audit/`          |
| Managing secrets                                   | `skills/secrets-management/`           |
| Setting / enforcing performance budgets            | `skills/performance-budget/`           |
| Recording an architectural decision                | `skills/adr/`                          |
| Adding / updating / removing a dependency          | `skills/dependency-management/`        |
| Branching and commit hygiene                       | `skills/branching-and-commits/`        |

---

# Runtime state

`generated/tasks/todo.md` and `generated/tasks/lessons.md` are the
live planning surface. They are written by `init/bootstrap.sh`
the first time it runs and updated by agents during work.

`generated/` is gitignored by ai-agent-core. If `ai-agent-core` is
vendored into a host project (not a submodule), add the same path
to the host's `.gitignore`.

When `gh` is available, mirror state into a branch-linked GitHub
Issue. See `skills/task-tracking/SKILL.md`.

---

# Host-project-specific assets (`local/`)

`local/` is the **only** location agents should put or look for
host-project-specific AI assets that don't belong upstream in
ai-agent-core itself:

- Custom skills the host project relies on
  (`local/skills/<name>/SKILL.md`).
- Project-specific tools, prompts, or templates
  (`local/tools/`, `local/prompts/`, …).
- Vendor data, fixtures, or references the agent should consult
  (`local/references/`).
- Host-only overrides or notes that augment but do not contradict
  ai-agent-core principles or rules.

Rules:

- `local/` is gitignored by ai-agent-core itself; only `.gitkeep` is
  tracked. Host projects that vendor ai-agent-core and want to commit
  their `local/` content MUST add an inverse rule to their own
  `.gitignore` (e.g. `!ai-agent-core/local/`).
- Content here is **subordinate** to `principles/`, `rules/`,
  `ai/`, and the glossary. It MUST NOT contradict them. If a
  conflict exists, the higher layer wins; surface the conflict
  instead of silently overriding.
- Skills under `local/skills/` are loaded the same way as
  `skills/` — only when their situation applies. Prefer extending
  ai-agent-core upstream if a need is generalizable across projects.
- Do NOT relocate runtime task state into `local/`. That stays in
  `generated/`.

---

# Global enforcement

If any guidance conflicts with architecture, follow the
architecture, unless a higher-priority policy requires otherwise.

Short-term velocity MUST NEVER override long-term structural
integrity.

---

# Escalation protocol

If no safe decision emerges, pause and ask for human clarification.
Do not guess. Do not improvise. Uncertainty must be surfaced —
never hidden.

---

# Prime directive

Build systems that remain understandable, modifiable, structurally
safe, secure under attack, observable in production, and resilient
under change.

Optimize for future engineers. Not for present convenience.
