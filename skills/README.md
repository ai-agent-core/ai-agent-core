# Agent Core Skills

Skills are the **on-demand playbooks** of Agent Core.

`agent-core/INDEX.md` defines *what to know*. Skills define
*what to do in a specific situation*. They are not loaded on
every turn — agents pick the matching skill when the situation
arises.

Each skill is a directory with a `SKILL.md` file, with YAML
frontmatter following the Claude Code Skills convention. They
can be mirrored into `.claude/skills/<name>/SKILL.md` in any
host project that wants Claude Code to auto-discover them.

---

## When to invoke which skill

### Engineering execution

| Situation                                  | Skill                       |
| ------------------------------------------ | --------------------------- |
| Starting non-trivial work                  | `plan-and-implement`        |
| Writing or changing production code        | `tdd`                       |
| Tracking plan, progress, GitHub Issue      | `task-tracking`             |
| User correction or validated approach      | `capture-lesson`            |
| Reviewing existing code                    | `code-review`               |
| Recording an architectural decision        | `adr`                       |
| Branching and commit hygiene               | `branching-and-commits`     |

### Architecture and design

| Situation                                  | Skill                       |
| ------------------------------------------ | --------------------------- |
| Crossing layer / dependency boundaries     | `architecture-guard`        |
| Deciding aggregate granularity             | `aggregate-boundary`        |
| Designing or changing a public API         | `api-design`                |
| Designing a schema or new datastore        | `database-design`           |
| Designing async / event-driven flows       | `event-driven`              |

### Migration

| Situation                                  | Skill                       |
| ------------------------------------------ | --------------------------- |
| Schema or data migration                   | `database-migration`        |
| Replacing or absorbing a legacy system     | `legacy-migration`          |

### Frontend

| Situation                                  | Skill                       |
| ------------------------------------------ | --------------------------- |
| Producing UI / visual design               | `frontend-design`           |
| Auditing accessibility                     | `accessibility-audit`       |

### Security and identity

| Situation                                  | Skill                       |
| ------------------------------------------ | --------------------------- |
| Applying the security baseline             | `security-baseline`         |
| Designing or changing authentication       | `authentication`            |
| Managing secrets                           | `secrets-management`        |

### Operations

| Situation                                  | Skill                       |
| ------------------------------------------ | --------------------------- |
| Building or extending CI/CD                | `cicd-pipeline`             |
| Provisioning infrastructure                | `infra-setup`               |
| Instrumenting a service                    | `observability-setup`       |
| Running an incident                        | `incident-response`         |
| Rolling out a release                      | `release-strategy`          |
| Introducing or retiring a feature flag     | `feature-flag`              |

### Performance and dependencies

| Situation                                  | Skill                       |
| ------------------------------------------ | --------------------------- |
| Setting / enforcing performance budgets    | `performance-budget`        |
| Adding or changing a cache                 | `caching-strategy`          |
| Adding / updating / removing dependencies  | `dependency-management`     |

### Domain

| Situation                                  | Skill                       |
| ------------------------------------------ | --------------------------- |
| Integrating a payment provider             | `payment-integration`       |

### Project lifecycle

| Situation                                  | Skill                       |
| ------------------------------------------ | --------------------------- |
| Initializing a new project layout          | `bootstrap-project`         |

---

## Hooking skills into Claude Code (optional)

If the host project wants Claude Code's native skill discovery,
copy or symlink:

```bash
mkdir -p .claude
ln -s ../agent-core/skills .claude/skills
# or, to copy:
# cp -R agent-core/skills .claude/skills
```

This is intentionally not done by `bootstrap.sh`. The bootstrap
only writes `AGENTS.md` and `CLAUDE.md` to the host project root
— the skill wiring is an explicit opt-in.

---

## How to write a new skill

A `SKILL.md` is a self-contained operational playbook for one
situation. It has:

- **YAML frontmatter** with `name` (kebab-case, matches dir) and
  `description` (one sentence, used by Claude Code for skill
  discovery),
- **a clear "use when"** statement at the top,
- **one or more numbered steps** that walk the agent through the
  decision,
- **a list of forbidden anti-patterns**,
- **a "when to STOP" section** — conditions under which the skill
  refuses to proceed and asks for help,
- **a prime directive** — one paragraph capturing the skill's
  spirit.

Skills are short enough to be loaded on demand without bloating
context. They cite the authoritative `rules/` and `principles/`
files; they do not duplicate them.
