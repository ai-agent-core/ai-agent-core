# Agent Core

**Agent Core is a governance layer for AI-assisted software
engineering — covering web frameworks, frontend, backend,
databases, infrastructure, CI/CD, payments, security,
observability, and migrations.**

It is a structured control system that ensures agents reason,
design, and implement software with architectural discipline,
across the full surface area of real-world systems.

Agent Core is not a prompt collection. It is an execution
framework for controlled intelligence.

---

# Why Agent Core exists

Modern AI coding tools are powerful — but without constraints
they drift. Common failure patterns:

- architectural inconsistency,
- uncontrolled agent improvisation,
- short-term decisions damaging long-term systems,
- code that future engineers must rewrite,
- security and operability treated as afterthoughts,
- migrations that break production at the wrong moment.

Agent Core prevents this by enforcing structured decision-making.

**Architecture must not emerge accidentally.**

---

# Who this is for

Engineers and teams who:

- build production systems with AI agents,
- care about long-term maintainability,
- want deterministic agent behavior,
- enforce architectural boundaries,
- ship software that handles money, PII, multi-tenant data, or
  high availability,
- treat AI as an engineering partner — not a code generator.

If you are experimenting casually, Agent Core is probably
unnecessary. If you are building systems meant to last, it
becomes extremely valuable.

---

# What Agent Core covers

### Always-loaded foundations

- **Principles** — engineering, architecture, design, frontend,
  security, operational, data.
- **Governance** — meta-rules and decision discipline.
- **Glossary** — shared vocabulary.
- **Reading order** and **context profile** — deterministic
  routing.

### On-demand operational playbooks (Skills)

| Domain                  | Skills                                                                                  |
| ----------------------- | --------------------------------------------------------------------------------------- |
| Engineering execution   | tdd, plan-and-implement, task-tracking, capture-lesson, code-review, adr, branching-and-commits |
| Architecture            | architecture-guard, aggregate-boundary, api-design, database-design, event-driven       |
| Migration               | database-migration, legacy-migration                                                    |
| Frontend                | frontend-design, accessibility-audit                                                    |
| Security & identity     | security-baseline, authentication, secrets-management                                   |
| Operations              | cicd-pipeline, infra-setup, observability-setup, incident-response, release-strategy, feature-flag |
| Performance & deps      | performance-budget, caching-strategy, dependency-management                             |
| Domain                  | payment-integration                                                                     |
| Project lifecycle       | bootstrap-project                                                                       |

### Cross-cutting rules (loaded by classification)

API design, database, migration, events, money, security,
authentication, secrets, observability, performance, CI/CD,
infrastructure, release, dependency, accessibility,
documentation.

### Deterministic initialization

Every agent follows the same boot sequence:

1. Load AI control.
2. Load principles.
3. Apply governance / glossary / structure / boundaries.
4. Pick the matching skill for the current situation.
5. Implement under discipline.

### Execution continuity

Agents externalize working memory into:

```
agent-core/generated/tasks/todo.md      current plan + progress + review
agent-core/generated/tasks/lessons.md   durable learnings
```

`generated/` is gitignored by agent-core itself. When the host
repository is connected to GitHub, state mirrors into a
branch-linked Issue (skill: `task-tracking`).

### Architectural protection

Agent Core enforces dependency direction, layer isolation, domain
protection, explicit contracts, observability-by-design,
secure-by-default, and reversible operations. Short-term speed
never overrides structural safety.

---

# Installation

Run the bootstrap from the host project root (one directory above
`agent-core/`).

## macOS / Linux

```bash
./agent-core/init/bootstrap.sh
```

## Windows (Command Prompt or PowerShell)

```bat
agent-core\init\bootstrap.cmd
```

The bootstrap writes:

- `AGENTS.md` — entrypoint at the host project root.
- `CLAUDE.md` — short redirect to AGENTS.md at the host project
  root.
- `agent-core/generated/tasks/todo.md` — runtime plan surface.
- `agent-core/generated/tasks/lessons.md` — durable lessons
  surface.

Nothing else is generated at the host project root.
`agent-core/generated/` is gitignored. If you vendor `agent-core`
without using a git submodule, add the same line to the host
project's `.gitignore`.

After installation, commit the entrypoints:

```bash
git add AGENTS.md CLAUDE.md
git commit -m "Install Agent Core"
```

---

# Optional: enable Claude Code skill auto-discovery

If you want Claude Code to discover Agent Core skills natively in
the host project, copy or symlink them into `.claude/skills/`:

```bash
mkdir -p .claude
ln -s ../agent-core/skills .claude/skills
# or:
# cp -R agent-core/skills .claude/skills
```

This is an explicit opt-in. The bootstrap does not do it
automatically — only `AGENTS.md` and `CLAUDE.md` are written to
the host root.

---

# Core philosophy

Architecture precedes implementation.

Structural integrity outweighs convenience.

Controlled intelligence beats improvisation.

Operability is a feature.

Security is the default path.

Data outlives code.

Systems should not require future rewrites.

Agent Core optimizes for long-term engineering safety.

---

# How it works (conceptual)

Agent Core separates concerns:

- **Principles** — foundational beliefs guiding decisions.
- **Rules** — enforceable constraints on agent behavior.
- **AI control** — machine-readable reasoning guidance.
- **Glossary** — shared vocabulary.
- **Skills** — on-demand operational playbooks.
- **Runtime state** — externalized working memory.

Together, these create a predictable agent runtime.

---

# When NOT to use Agent Core

- You are prototyping rapidly.
- The code will be discarded.
- Architectural consistency is irrelevant.
- Agents are used only for small, throwaway tasks.

Agent Core is intentionally opinionated. It favors safety over
speed.

---

# Design goals

Agent Core is built to be:

- comprehensive — covering the full surface of real-world
  systems,
- lightweight at runtime — load only what the situation needs,
- dependency-free,
- OS-agnostic,
- bootstrap-driven,
- structurally strict,
- interruption-safe.

It should feel invisible — yet protective.

---

# Contributing

Contributions are welcome if they improve architectural safety,
operational quality, security posture, clarity, determinism, or
cross-agent consistency. Avoid adding complexity without
structural benefit. Agent Core values precision over feature
growth.

---

# Philosophy in one sentence

**Prevent architectural drift before it begins; build for the
engineer who reads this code in five years and the operator who
pages at 3 AM.**

---

# License

MIT
