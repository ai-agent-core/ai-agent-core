<div align="center">

# AI Agent Core

**Production-grade governance for AI coding agents.**
Principles, rules, and skills that keep Claude Code, Cursor, Copilot, and
custom agents from drifting away from your architecture.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Smoke tests](https://img.shields.io/github/actions/workflow/status/ai-agent-core/ai-agent-core/smoke.yml?branch=main&label=smoke%20tests)](.github/workflows/smoke.yml)
[![Skills](https://img.shields.io/badge/skills-30-blue)](skills/)
[![Rules](https://img.shields.io/badge/rules-34-purple)](rules/)
[![Stack: SvelteKit · pnpm · TS · Tailwind](https://img.shields.io/badge/default%20frontend-SvelteKit%20%C2%B7%20TS%20%C2%B7%20Tailwind%20%C2%B7%20pnpm-orange)](rules/PACKAGE_LAYOUT_FRONTEND_RULES.md)

</div>

---

## What is this?

AI Agent Core is a **governance layer for AI-assisted software engineering**.
Drop it into any project. Your AI agents read it on every session and follow
it across architecture, domain modeling, testing, security, observability,
CI/CD, payments, and migrations.

Works with **Claude Code**, **Cursor**, **GitHub Copilot**, **Aider**, and any
agent that respects `AGENTS.md` / `CLAUDE.md` conventions. Skills follow the
[Claude Code Skills](https://code.claude.com/docs/skills) format and can be
mounted at `.claude/skills/` for native auto-discovery.

> Architecture must not emerge accidentally.

---

## Install

From the host project root:

```bash
# vendor ai-agent-core (or git submodule add)
git clone https://github.com/ai-agent-core/ai-agent-core.git
./ai-agent-core/init/bootstrap.sh

git add AGENTS.md CLAUDE.md && git commit -m "Install AI Agent Core"
```

Windows:

```bat
ai-agent-core\init\bootstrap.cmd
```

That's it. The bootstrap writes:

- **`AGENTS.md`** / **`CLAUDE.md`** — agent entrypoints (commit).
- **`project.yml`** — declares the docs layout (Diátaxis-extended by
  default) and the packages map. Team-wide map of "what is here, why".
  Commit.
- **`docs/`** — Diátaxis-extended scaffold (`tutorials`, `how-to`,
  `reference`, `explanation`, `adr`, `runbooks`) with READMEs explaining
  what belongs in each section. Commit.
- **`.aiac/config.yml`** — host stack profile
  (frontend / backend / database / profile / toggles). Drives which
  rules and skills apply for this project, via
  `ai-agent-core/init/dispatch.yml`. Edit to match reality.
- **`.aiac/tasks/{todo,lessons}.md`** — runtime plan + durable
  lessons. Committed by default; hosts that prefer per-developer
  state may add `.aiac/tasks/` to `.gitignore`.

Existing files are never overwritten. Re-running bootstrap aborts.

---

## What you get

```text
your-project/
├── AGENTS.md                ← agents read this first
├── CLAUDE.md                ← redirect for Claude Code
├── project.yml              ← docs layout + packages map (commit)
├── docs/                    ← Diátaxis-extended scaffold (commit)
│   ├── tutorials/           ← learning-oriented walkthroughs
│   ├── how-to/              ← task recipes
│   ├── reference/           ← API / config / schema descriptions
│   ├── explanation/         ← concepts, design rationale
│   ├── adr/                 ← Architecture Decision Records
│   └── runbooks/            ← operational procedures
├── .aiac/                   ← host-owned AI agent state (commit)
│   ├── config.yml           ← host stack profile (drives dispatch)
│   ├── tasks/               ← runtime plan + lessons (commit by default)
│   │   ├── todo.md
│   │   └── lessons.md
│   ├── skills/              ← host-only skills (optional)
│   ├── tools/               ← host-only tooling (optional)
│   └── references/          ← fixtures the agent should consult
└── ai-agent-core/           ← vendor tree (read-only)
    ├── INDEX.md             ← routing table for agents
    ├── init/
    │   └── dispatch.yml     ← rule × stack mapping (vendor)
    ├── principles/          ← non-negotiable foundations (7 files)
    ├── rules/               ← enforceable invariants (34 files)
    ├── skills/              ← on-demand playbooks (30 SKILL.md)
    └── ai/                  ← machine-readable routing
```

The agent loads only what the current task needs (`.aiac/config.yml`
+ `init/dispatch.yml` + classification → context profile). 17k lines of
governance, but the per-turn footprint stays small.

---

## Why AI Agent Core

Modern AI coding tools are powerful — but **without constraints they drift**.

| Symptom                                    | What AI Agent Core does about it                            |
| ------------------------------------------ | -------------------------------------------------------- |
| Architecture inconsistency PR-by-PR        | Layer / dependency / aggregate rules enforced on review  |
| Plausible code that fails real edge cases  | TDD skill is mandatory for behavior change               |
| Migrations that break prod at the worst moment | Expand→migrate→contract enforced; rollback required  |
| Money math wrong in subtle ways            | `MONEY_HANDLING_RULES` + `payment-integration` skill     |
| "It works on my machine" deploys           | CICD / observability / release-strategy rules            |
| Schemas that lie to consumers              | Database / API design rules treat schema as public API   |
| Same correction every time                 | `capture-lesson` skill writes durable rules into project |

AI Agent Core covers the full surface: **web frameworks, frontend, backend,
databases, infrastructure, CI/CD, security, observability, payments,
accessibility, and legacy-system migration**.

---

## Configuring for your stack

`.aiac/config.yml` declares the host's stack and profile.
AI Agent Core uses it to scope which rules and skills apply.

```yaml
stack:
  frontend: sveltekit          # sveltekit | react | vue | none
  backend: cloudflare-workers  # cloudflare-workers | quarkus | spring | node | none
  package_manager: pnpm
  database: d1                 # d1 | postgres | mysql | sqlite | none
  language: typescript

profile: web-saas              # web-saas | api-only | mobile-bff | library | internal-tool

toggles:
  payments: false              # enable MONEY_HANDLING_RULES + payment-integration
  i18n: false
  pii: false
  multi_tenant: false
  realtime: false
  mobile: false
```

The mapping from these choices to active rules and skills lives in
[`init/dispatch.yml`](init/dispatch.yml). Edit `.aiac/config.yml`,
not the dispatch file.

When `.aiac/config.yml` is absent (older installs), agents treat
all rules as active — backwards-compatible.

---

## Documentation layout

`project.yml` declares where docs live and how they are structured.
The default preset `diataxis-extended` ships the **Diátaxis framework**
(tutorials / how-to / reference / explanation) plus **ADRs** and
**runbooks** — the structure used by Django, GitLab, and Cloudflare.

```yaml
docs:
  root: docs/
  layout: diataxis-extended
  sections: [tutorials, how-to, reference, explanation, adr, runbooks]
packages: []                   # add entries as the project grows
```

When packages or documentation sections change, `project.yml` MUST
be updated in the same change. See
[`PROJECT_STRUCTURE_RULES.md`](rules/PROJECT_STRUCTURE_RULES.md) and
[`DOCUMENTATION_RULES.md`](rules/DOCUMENTATION_RULES.md).

---

## How it compares

|                                   | AI Agent Core | `.cursorrules` / Cursor Rules | `CLAUDE.md` alone | Prompt collections | Spec-driven (e.g. SpecKit) |
| --------------------------------- | :--------: | :---------------------------: | :---------------: | :----------------: | :------------------------: |
| Architectural principles          | ✅          | minimal                       | minimal           | ❌                  | partial                    |
| Enforceable rules with hierarchy  | ✅          | flat list                     | flat list         | ❌                  | per-spec                   |
| Situational skills (on-demand)    | ✅          | ❌                             | ❌                 | partial            | ❌                          |
| TDD / DDD discipline              | ✅          | ❌                             | ❌                 | ❌                  | partial                    |
| Security / observability / payments | ✅          | ❌                             | ❌                 | partial            | ❌                          |
| Schema + system migration playbook | ✅          | ❌                             | ❌                 | ❌                  | ❌                          |
| Runtime task tracking             | ✅          | ❌                             | partial           | ❌                  | ✅                          |
| Self-improvement loop             | ✅          | ❌                             | ❌                 | ❌                  | ❌                          |
| Multi-agent compatibility         | ✅          | Cursor only                   | Claude only       | varies             | varies                     |
| Bootstrap + migration tooling     | ✅          | ❌                             | ❌                 | ❌                  | partial                    |

The differentiator is the **integrated layering**: principles → rules →
skills → runtime, with deterministic routing between them.

---

## Skills catalog (30)

<details>
<summary><b>Engineering execution</b> (7)</summary>

`tdd` · `plan-and-implement` · `task-tracking` · `capture-lesson` ·
`code-review` · `adr` · `branching-and-commits`

</details>

<details>
<summary><b>Architecture & design</b> (5)</summary>

`architecture-guard` · `aggregate-boundary` · `api-design` ·
`database-design` · `event-driven`

</details>

<details>
<summary><b>Migration</b> (2)</summary>

`database-migration` · `legacy-migration`

</details>

<details>
<summary><b>Frontend</b> (2)</summary>

`frontend-design` · `accessibility-audit`

</details>

<details>
<summary><b>Security & identity</b> (3)</summary>

`security-baseline` · `authentication` · `secrets-management`

</details>

<details>
<summary><b>Operations</b> (6)</summary>

`cicd-pipeline` · `infra-setup` · `observability-setup` ·
`incident-response` · `release-strategy` · `feature-flag`

</details>

<details>
<summary><b>Performance & dependencies</b> (3)</summary>

`performance-budget` · `caching-strategy` · `dependency-management`

</details>

<details>
<summary><b>Domain & lifecycle</b> (2)</summary>

`payment-integration` · `bootstrap-project`

</details>

Each skill is a self-contained playbook (≤300 lines) loaded on demand.
Browse them in [`skills/`](skills/).

---

## Default stacks

AI Agent Core ships two well-trodden paths. Pick at bootstrap and
record the choice in an ADR — see
[`STACK_DEFAULTS_RULES.md`](rules/STACK_DEFAULTS_RULES.md).

### Default path — Cloudflare (greenfield SaaS / web)

| Concern         | Default                                                       |
| --------------- | ------------------------------------------------------------- |
| Frontend        | **SvelteKit** + `@sveltejs/adapter-cloudflare` + **TypeScript** strict + **Tailwind** + **pnpm** |
| Backend         | **Cloudflare Workers** + **Hono** + TypeScript, deployed via **Wrangler** |
| OLTP            | **Cloudflare D1** (graduate to Postgres via Hyperdrive when needed) |
| Object / KV     | **Cloudflare R2** / **KV**                                    |
| Queue / Cron / Realtime | **Queues** / **Cron Triggers** / **Durable Objects**  |
| Email           | **Resend**                                                    |
| Payment         | **Stripe** (Connect when marketplace)                         |
| DNS / TLS / WAF | **Cloudflare** (proxied DNS, ACME-managed certs)              |
| CI / CD         | **GitHub Actions** with OIDC federation to Cloudflare         |

### Large-scale path — Quarkus / JVM

| Concern         | Default                                                       |
| --------------- | ------------------------------------------------------------- |
| Backend         | **Quarkus** (Kotlin preferred; Java 21+ acceptable)           |
| OLTP            | **PostgreSQL** (managed: RDS / Cloud SQL / Aiven / Neon)      |
| Migrations      | **Flyway**                                                    |
| Entity gen      | **jeg** (schema → entity reverse generation)                  |
| Frontend (paired) | Same as the default path (SvelteKit + Tailwind + pnpm)      |
| IaC             | Terraform / Pulumi against the chosen cloud                   |

Hybrid (Cloudflare frontend + Quarkus backend) is supported.

The four-layer architecture (`interfaces / applications / domains /
architectures`) is the same on both paths — only the adapter layer
changes.

---

## Use with Claude Code (optional)

AI Agent Core skills follow the [Claude Code Skills](https://code.claude.com/docs/skills)
SKILL.md format. To enable native auto-discovery in your host project:

```bash
mkdir -p .claude
ln -s ../ai-agent-core/skills .claude/skills
# or:  cp -R ai-agent-core/skills .claude/skills
```

The bootstrap intentionally does **not** symlink — it is an explicit
opt-in.

---

## Upgrading from an older version

When you replace or update `ai-agent-core/`, run the migration script from the
host project root:

```bash
./ai-agent-core/init/migration.sh           # dry run
./ai-agent-core/init/migration.sh --apply   # execute
```

It relocates user content from legacy locations (`tasks/`, `agent-works/`,
`agent-spec/WORK_STATE.md`, `agent-input/`, plus older
`ai-agent-core/local/` and `ai-agent-core/generated/`) into the host-owned
`.aiac/` tree, removes deprecated AI Agent Core scaffolding, and
**refreshes `AGENTS.md` / `CLAUDE.md`** from the current scaffold when
they carry the `Generated by ai-agent-core` marker — backing the previous
version up to `migration-backup-<UTC>/` so any additions are recoverable.

Pass `--keep-entrypoints` if you want to refresh everything *except*
`AGENTS.md` / `CLAUDE.md`. If your file has had its generation marker
removed (i.e. you adopted it as user-authored), the script never
overwrites it — drift is reported only.

Backups land at `<host>/.aiac/migration-backup-<UTC>/`. Idempotent.

---

## Documentation

- [`INDEX.md`](INDEX.md) — boot sequence and routing table.
- [`principles/`](principles/) — engineering, architecture, security,
  operational, data foundations.
- [`rules/`](rules/) — 34 enforceable rule files.
- [`skills/`](skills/) — 30 on-demand playbooks.
- [`ai/context_profiles.yaml`](ai/context_profiles.yaml) — task
  classification → loaded files.
- [`CHANGELOG.md`](CHANGELOG.md) — release history.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — how to add rules / skills.

---

## Who this is for

- Teams shipping production systems with AI agents.
- Engineers who care about long-term maintainability.
- Builders of payment, multi-tenant, or PII-handling systems.
- Anyone tired of correcting the same agent mistakes repeatedly.

**Not for:** rapid throwaway prototypes, scripts, or one-off scratch code.
AI Agent Core is intentionally opinionated. It favours safety over speed.

---

## Status & roadmap

- ✅ v1.0 — 7 principles, 34 rules, 30 skills, bootstrap + migration tooling.
- 🚧 More skills (e.g. `mobile-release`, `data-pipeline`).
- 🚧 Plug-ins for Cursor `.cursor/rules/` and Copilot custom instructions.
- 🚧 Optional MCP server exposing rules and skills as queryable resources.

See [issues](../../issues) for current roadmap and open work.

---

## Contributing

Contributions welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md). AI Agent Core
values precision over feature growth: improvements to architectural safety,
clarity, determinism, or cross-agent consistency are warmly received.

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Philosophy in one sentence

> **Prevent architectural drift before it begins; build for the engineer who
> reads this code in five years and the operator who pages at 3 AM.**

---

## Keywords

`AI coding agents` · `Claude Code` · `AGENTS.md` · `CLAUDE.md` ·
`Cursor rules` · `Copilot` · `governance` · `DDD` · `TDD` · `Clean
Architecture` · `agent skills` · `sub-agents` · `prompt engineering` ·
`Cloudflare Workers` · `Wrangler` · `Hono` · `D1` · `SvelteKit` · `pnpm` ·
`TypeScript` · `Resend` · `Stripe` · `Quarkus` · `Flyway`

---

## License

[MIT](LICENSE)
