---
name: usecase-driven-e2e
description: Declare end-user flows as YAML use cases. One source produces both Playwright E2E tests (with red-box highlights) and the AsciiDoc/HTML user manual. The Sealess `e2e/` workspace is the model case.
---

# Usecase-driven E2E

Use this skill when a feature has user-visible flows that span
UI + API + DB. The same YAML drives:

- the Playwright **E2E test** (executed locally and in CI),
- the **user manual** (`docs/how-to/<feature>.html`,
  brand-styled HTML rendered from AsciiDoc).

Spec → use cases → tests + manual is the spec-driven loop made
concrete (see `rules/WORKFLOW_RULES.md`).

If a flow can be verified at the unit / integration layer
without ceremony, prefer that layer (`rules/TESTING_RULES.md`).
Reserve E2E for genuine cross-layer behavior.

---

## Isolation Contract (non-negotiable)

The runner MUST be self-contained: it executes entirely within
the developer's container or the CI runner, and produces ZERO
side effects on any system outside that boundary.

Hard prohibitions during a run:

- writes to a production / staging database, queue, or cache,
- charges, payments, refunds, or any state change in a
  production payment provider,
- emails, SMS, push notifications, or webhooks delivered to
  real recipients,
- file uploads to a production object store,
- API calls that mutate any third-party tenant
  (Stripe live, Resend live, Slack, etc.),
- requests against shared QA / staging tenants that other
  humans rely on.

How to satisfy the contract:

- Run the app in **demo / fixture mode** (mocked clients
  swapped in at the dependency-injection boundary; see
  `rules/FRONTEND_DEMO_MODE_RULES.md`).
- Use a **containerized database** (Testcontainers, local D1
  via `wrangler dev --local`, ephemeral SQLite, etc.). Never a
  shared instance.
- Mock or record-replay external API clients. Live keys are
  forbidden.
- Email / notification senders default to a **console / capture
  mode** that records output instead of sending it.
- The test process must succeed with `--network=none` (or its
  CI equivalent). If a test needs the public internet, it is
  not E2E — it is integration with an external system, and
  belongs elsewhere.

CI runs the same command as local — no credentials, no live
endpoints, no privileged access. Deploy verification (= "smoke
test against staging") is a separate concern with its own
tooling and is not handled by this skill.

A run that touches the outside world is a failed run, even if
the assertions pass.

---

## Why one source

- **Manuals stop rotting.** When the UI changes, the test fails
  before the manual becomes a lie.
- **Tests stop being write-only.** Each scenario doubles as the
  product's onboarding screenshot.
- **AI agents have a single artifact to read & write.** YAML is
  the input contract for "explain how this feature works" and
  "test that this feature works".

---

## Layered architecture

```
Layer 1: spec                docs/explanation/<f>.md, docs/reference/<f>.md
              │
              ▼
Layer 2: use cases (SoR)     e2e/usecases/<f>.yml
              │
   ┌──────────┴──────────┐
   ▼                     ▼
Layer 3a: runner       Layer 3b: docgen
(Playwright)           (AsciiDoc + HTML)
   │                     │
   ▼                     ▼
e2e/.output/snapshots/  docs/how-to/<f>.html
```

The schema is shared (= types + zod), runtimes are independent.
Re-running docgen does not require re-running the browser.

---

## YAML contract (minimal)

```yaml
feature: invoice-schedules        # kebab-case = file slug
title: 定期請求の使い方
description: |
  Feature-level intro paragraph.
implements:                       # spec back-references
  - docs/explanation/invoice-schedules.md
  - docs/reference/invoice-schedules.md
docs:
  category: 請求業務
  diataxis: how-to
scenarios:
  - id: full-flow
    title: 定期請求を登録して、運用してみる
    description: Scenario-level prose.
    ignore_in_docs: false         # true = test only (= internal)
    steps:
      - { do: visit, path: /invoice-schedules, as: 定期請求 }
      - { do: snapshot, name: list-initial, caption: 一覧画面 }
      - { do: click, text: 新規追加 }
      - { do: fill, label: タイトル, value: 月次サポート料 }
      - { do: select, label: 顧客, option: 佐藤商事株式会社 }
      - { do: expect, text: 月次サポート料 }
```

Action vocabulary (7): `visit / click / fill / select / check /
expect / snapshot`. Selector picks ONE of: `text` (default),
`label`, `role+name`, `testId`. Numeric prefixes are forbidden
(see `rules/PROJECT_STRUCTURE_RULES.md` — order is implicit in
list position).

---

## Runner conventions

- **Demo mode boot** — the app is started in demo / fixture
  mode per the Isolation Contract above. Authentication, DB
  writes, and external APIs are mocked at the DI boundary.
- **Auto-highlight** — before each `snapshot`, the runner draws
  a red box around the element targeted by the next `click /
  fill / select / check`. The user manual then visually shows
  "press here next."
- **Dialog auto-accept** — native `confirm()` / `alert()` are
  accepted by default. Tests verifying cancellation opt in
  explicitly.
- **Dedicated dev port** — the webServer runs on a port that is
  NOT the developer's main `dev` port (avoid collisions).
- **Identical command local & CI** — the same `pnpm e2e` runs
  locally and in CI. No environment-specific branching, no
  privileged secrets, no live tenants.

---

## Output policy

All generated artifacts go under one gitignored root:

```
e2e/
├── usecases/<feature>.yml          # commit
├── runner.spec.ts, schema.ts, docgen.ts
└── .output/                        # gitignored
    ├── snapshots/<feature>/<scenario>/<name>.png
    ├── docs/<feature>.adoc         # AsciiDoc source
    ├── docs-html/<feature>.html    # Brand-themed HTML
    ├── docs-html/style.css
    ├── html-report/                # Playwright report
    └── test-results/               # traces, evidence
```

Local runs do not pollute git status. CI uploads `.output/` as
an artifact for review.

---

## Package commands (root `package.json`)

```
pnpm e2e:install   # one-time browser DL
pnpm e2e:test      # run E2E, refresh snapshots
pnpm e2e:docs      # rebuild manual from snapshots + YAML
pnpm e2e           # test + docs (the usual command)
```

CI workflow runs `pnpm e2e` and uploads `.output/` regardless
of pass/fail.

---

## Model case

The **Sealess** repo's `e2e/` workspace is the reference
implementation:

- 4 source files at top level (`schema.ts`, `runner.spec.ts`,
  `docgen.ts`, `playwright.config.ts`) — easy to read.
- Brand CSS theme (= bitboxx) under `e2e/themes/`.
- Single YAML per feature under `e2e/usecases/`.
- 7 actions, 4 selector types, no numeric prefixes — the
  minimum that produces a complete manual.

When introducing this skill into a new project, copy the same
shape; do not re-invent the schema.

---

## When this skill says STOP

- The feature has no user-facing flow → use unit / integration
  tests instead.
- The flow depends on real Stripe / real DB to mean anything →
  the test is integration, not E2E. Move it.
- The YAML cannot be written without seeing the implementation
  first → the spec (Layer 1) is missing. Write it before
  writing the YAML.
