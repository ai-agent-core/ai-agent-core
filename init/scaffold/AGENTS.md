# Agent Entrypoint

This repository is governed by Agent Core. Read the layers below
in order before any non-trivial change. Higher-priority policies
(system / developer / tool) always win over what is written here.

Agents MUST resolve the boot sequence to a concrete reading list.
Improvisation is not permitted.

---

# Boot sequence

1. **Open the runtime task surface.**
   `agent-core/generated/tasks/todo.md` and `…/lessons.md` are
   the authoritative local plan and durable learnings. Do not
   write them anywhere else. Skill:
   `agent-core/skills/task-tracking`.

2. **Load Agent Core core context.**
   Read `agent-core/INDEX.md` and follow it. INDEX is the routing
   table for principles, governance, language, structure,
   boundaries, decisions, execution, and implementation.

3. **Classify the task and load the matching context profile.**
   See `agent-core/ai/context_profiles.yaml`. Prefer over-tagging
   to under-tagging; the loader deduplicates.
   When uncertain, load `fallback.load_all`.

4. **Pick the relevant skills before acting.**
   Skills under `agent-core/skills/` carry the *how* — TDD,
   planning, architecture review, migration, observability,
   security baseline, payment integration, CI/CD, etc. Load only
   those that apply to the current task.

Architecture always precedes implementation.

---

# Skills (load on demand)

### Engineering execution

| When                                         | Skill                                         |
| -------------------------------------------- | --------------------------------------------- |
| About to start non-trivial work             | `agent-core/skills/plan-and-implement`        |
| Writing or changing production code         | `agent-core/skills/tdd`                       |
| Planning, tracking, resuming work           | `agent-core/skills/task-tracking`             |
| User corrected something                    | `agent-core/skills/capture-lesson`            |
| Reviewing existing code                     | `agent-core/skills/code-review`               |
| Recording an architectural decision         | `agent-core/skills/adr`                       |
| Branching / commits / PR shape              | `agent-core/skills/branching-and-commits`     |

### Architecture and design

| When                                         | Skill                                         |
| -------------------------------------------- | --------------------------------------------- |
| Crossing aggregate / layer boundaries       | `agent-core/skills/architecture-guard`        |
| Deciding aggregate granularity              | `agent-core/skills/aggregate-boundary`        |
| Designing / changing a public API           | `agent-core/skills/api-design`                |
| Designing a schema or new datastore         | `agent-core/skills/database-design`           |
| Designing async / event-driven flows        | `agent-core/skills/event-driven`              |

### Migration

| When                                         | Skill                                         |
| -------------------------------------------- | --------------------------------------------- |
| Schema or data migration                    | `agent-core/skills/database-migration`        |
| Replacing or absorbing a legacy system      | `agent-core/skills/legacy-migration`          |

### Frontend

| When                                         | Skill                                         |
| -------------------------------------------- | --------------------------------------------- |
| Producing UI / visual design                | `agent-core/skills/frontend-design`           |
| Auditing accessibility                      | `agent-core/skills/accessibility-audit`       |

### Security and identity

| When                                         | Skill                                         |
| -------------------------------------------- | --------------------------------------------- |
| Applying the security baseline              | `agent-core/skills/security-baseline`         |
| Designing / changing authentication         | `agent-core/skills/authentication`            |
| Managing secrets                            | `agent-core/skills/secrets-management`        |

### Operations

| When                                         | Skill                                         |
| -------------------------------------------- | --------------------------------------------- |
| Building or extending CI/CD                 | `agent-core/skills/cicd-pipeline`             |
| Provisioning infrastructure                 | `agent-core/skills/infra-setup`               |
| Instrumenting a service                     | `agent-core/skills/observability-setup`       |
| Running an incident                         | `agent-core/skills/incident-response`         |
| Rolling out a release                       | `agent-core/skills/release-strategy`          |
| Introducing / retiring a feature flag       | `agent-core/skills/feature-flag`              |

### Performance and dependencies

| When                                         | Skill                                         |
| -------------------------------------------- | --------------------------------------------- |
| Setting / enforcing performance budgets     | `agent-core/skills/performance-budget`        |
| Adding or changing a cache                  | `agent-core/skills/caching-strategy`          |
| Adding / updating / removing dependencies   | `agent-core/skills/dependency-management`     |

### Domain

| When                                         | Skill                                         |
| -------------------------------------------- | --------------------------------------------- |
| Integrating a payment provider              | `agent-core/skills/payment-integration`       |

### Project lifecycle

| When                                         | Skill                                         |
| -------------------------------------------- | --------------------------------------------- |
| Initializing a new project layout           | `agent-core/skills/bootstrap-project`         |

Each skill has a `SKILL.md` with a self-contained prompt. Treat
the skill as the playbook for that situation.

---

# Runtime state location

- `agent-core/generated/tasks/todo.md` — current plan and
  progress.
- `agent-core/generated/tasks/lessons.md` — durable lessons
  across work units.

`agent-core/generated/` is gitignored by agent-core. The host
project SHOULD also gitignore it if `agent-core` is vendored
rather than a git submodule.

If `gh` is available, mirror state into a branch-linked Issue per
`agent-core/skills/task-tracking`. Without `gh`, the local files
are authoritative.

---

# Host-project-specific assets (`agent-core/local/`)

Anything **specific to this project** that an AI agent needs —
custom skills, project prompts, tools, references — goes under
`agent-core/local/`. Examples:

- `agent-core/local/skills/<name>/SKILL.md` — host-only skills.
- `agent-core/local/tools/` — host-only tooling notes / scripts
  the agent may consult.
- `agent-core/local/references/` — fixtures, vendor docs, schema
  snapshots the agent should read on demand.

Constraints:

- `agent-core/local/` is gitignored by agent-core itself (only
  `.gitkeep` is tracked upstream). To commit your project's
  customizations, override the rule in your project's own
  `.gitignore`, e.g.:

  ```
  !agent-core/local/
  ```

- Content under `local/` MUST NOT contradict agent-core principles,
  rules, or AI control files. Higher layers win; surface conflicts
  rather than silently overriding.
- Skills under `agent-core/local/skills/` follow the same load-on-
  demand pattern as `agent-core/skills/`. Prefer upstreaming a skill
  to agent-core if it generalizes beyond this project.
- Runtime task state stays in `agent-core/generated/`, not `local/`.

---

# Verification gate

Do not declare work complete without proof:

- failing-test → passing-test transition (skill: `tdd`),
- typecheck / lint / SAST / SCA clean,
- behavior demonstrated against the spec or screenshot,
- where relevant: budget met (skill: `performance-budget`),
- accessibility pass for UI (skill: `accessibility-audit`).

If you cannot verify, say so explicitly and stop.

---

# Uncertainty protocol

Pause and ask the user when:

- the safe path is not obvious,
- task scope is ambiguous,
- a request would cross an architectural boundary,
- a request implies more change than stated,
- a one-way decision lacks the information to make it safely
  (skill: `adr`).

Reflect any clarification into `tasks/todo.md` (and the linked
Issue, if connected) before resuming.

Do not guess. Do not improvise.

---

# Prime directive

Violating architecture causes more damage than delivering late.
Protect the system. Optimize for the engineer who reads this
code in two years and the operator who pages at 3 AM.
