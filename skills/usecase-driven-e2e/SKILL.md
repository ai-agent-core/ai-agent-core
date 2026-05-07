---
name: usecase-driven-e2e
description: Declare end-user flows as YAML use cases. The same source feeds two independent consumers — a Playwright runner that produces verification evidence, and a docgen that produces the end-user operation manual. DRY is bounded to inputs (YAML + schema + runner-core); outputs are owned by their consumer.
---

# Usecase-driven E2E

Use this skill when a feature has user-visible flows that span
UI + API + DB. A single YAML feeds two **independent** consumers:

- the Playwright **verifier** (`e2e/`) — proves on a per-usecase
  basis that every flow declared in the spec actually works;
- the **documenter** (`manual/`) — produces the end-user
  operation manual (`manual/dist/<feature>.html`).

Spec → usecases → verifier + documenter is the spec-driven loop
made concrete (see `rules/WORKFLOW_RULES.md`).

If a flow can be verified at the unit / integration layer
without ceremony, prefer that layer (`rules/TESTING_RULES.md`).
Reserve E2E for genuine cross-layer behavior.

---

## Concerns and their single responsibilities

The pipeline is intentionally split into modules so each has
exactly one reason to change.

| Module                       | Single responsibility                          | Audience            | Lifecycle      |
| ---------------------------- | ---------------------------------------------- | ------------------- | -------------- |
| `docs/`                      | specification — WHY (`explanation/`) + WHAT (`reference/`) | engineers           | hand-authored  |
| `usecases/<f>.yml`           | declarative source of user flows               | shared input        | hand-authored  |
| `packages/usecase-schema/`   | type contract for the YAML                     | shared dependency   | versioned      |
| `packages/usecase-runner/`   | YAML → browser execution engine                | shared dependency   | versioned      |
| `e2e/`                       | spec coverage verification + evidence          | engineers / CI      | per-PR run     |
| `manual/`                    | end-user operation guide                       | end users           | per-feature publish |

DRY is bounded to **inputs** (YAML, schema, runner-core).
**Outputs are not shared.** If `e2e/` and `manual/` happen to
capture the same screen, they each produce their own copy — the
cropping, resolution, and overlay rules differ by purpose, so
forcing reuse couples concerns that have no reason to be coupled.

---

## Isolation Contract (non-negotiable)

Both the verifier and the documenter MUST be self-contained:
they execute entirely within the developer's container or the CI
runner, and produce ZERO side effects on any system outside that
boundary.

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
- The process must succeed with `--network=none` (or its CI
  equivalent). If a run needs the public internet, it is not
  E2E — it is integration with an external system, and belongs
  elsewhere.

CI runs the same commands as local — no credentials, no live
endpoints, no privileged access. Deploy verification (= "smoke
test against staging") is a separate concern with its own
tooling and is not handled by this skill.

A run that touches the outside world is a failed run, even if
the assertions pass.

---

## Why this split

- **Different purposes** — e2e is *verification* (does the spec
  hold?). manual is *explanation* (how does a user operate it?).
  The artifacts they want from a browser session are not the
  same artifacts.
- **Different audiences** — e2e is read by engineers and CI;
  manual is read by end users. Conflating them produces docs
  full of assertion noise and tests full of cosmetic rules.
- **Different lifecycles** — a failing assertion blocks merge.
  A regenerated screenshot doesn't. Letting one block the other
  is structural confusion.
- **Manuals stop rotting** — when the UI changes, the verifier
  fails before the manual becomes a lie.
- **AI agents have one canonical input** — YAML is the input
  contract for both "test this feature" and "explain this
  feature". Anything else is derived.

---

## Layered architecture

```
Layer 1: spec                docs/explanation/<f>.adoc, docs/reference/<f>.adoc
              │
              ▼
Layer 2: usecases (SoR)      usecases/<f>.yml
              │
   ┌──────────┴──────────┐
   ▼                     ▼
Layer 3: schema          Layer 4: runner-core
packages/usecase-schema  packages/usecase-runner
   │                     │
   └──────────┬──────────┘
              │  (both shared, both versioned)
   ┌──────────┴──────────┐
   ▼                     ▼
Layer 5a: verifier      Layer 5b: documenter
e2e/spec.ts             manual/generator/docgen.ts
   │                     │
   ▼                     ▼
e2e/.output/             manual/dist/<f>.html
(gitignored evidence)    (committed product)
```

The two consumers (verifier, documenter) never import each
other. They share Layer 3 (schema) and Layer 4 (runner-core),
nothing else.

---

## YAML contract (minimal)

```yaml
feature: invoice-schedules        # kebab-case = file slug
title: 定期請求の使い方
description: |
  Feature-level intro paragraph.
implements:                       # spec back-references
  - docs/explanation/invoice-schedules.adoc
  - docs/reference/invoice-schedules.adoc
docs:
  category: 請求業務
  diataxis: how-to                # for engineer-facing index in docs/
manual:
  category: 請求業務              # for end-user manual TOC
scenarios:
  - id: full-flow
    title: 定期請求を登録して、運用してみる
    description: Scenario-level prose.
    ignore_in_manual: false       # true = verifier-only (= internal coverage)
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

### Verbs and their owners

The same YAML is read through two lenses. Each consumer owns
specific verbs:

| Verb       | Verifier (`e2e/`)             | Documenter (`manual/`)             |
| ---------- | ----------------------------- | ---------------------------------- |
| `visit`    | drive the browser             | drive the browser                  |
| `click` / `fill` / `select` / `check` | execute & assert reachable | execute (used to advance state)    |
| `expect`   | **assert — must pass**        | ignored (no manual impact)         |
| `snapshot` | optional evidence frame       | **primary output — red-box + caption** |

The verifier never reads `manual/`. The documenter never reads
`e2e/.output/`. They are siblings driven by the same YAML.

---

## Runner conventions

Shared (lives in `packages/usecase-runner/`):

- **Demo mode boot** — the app is started in demo / fixture
  mode per the Isolation Contract above.
- **Dialog auto-accept** — native `confirm()` / `alert()` are
  accepted by default. Scenarios verifying cancellation opt in
  explicitly.
- **Dedicated dev port** — the webServer runs on a port that is
  NOT the developer's main `dev` port (avoid collisions).
- **Identical command local & CI** — no environment-specific
  branching, no privileged secrets, no live tenants.

Verifier-only (`e2e/spec.ts`):

- runs every step of every scenario,
- treats `expect` as a hard assertion,
- treats `snapshot` as optional evidence (writes to
  `e2e/.output/test-results/`, not committed).

Documenter-only (`manual/generator/docgen.ts`):

- runs scenarios where `ignore_in_manual !== true`,
- before each `snapshot`, draws a red box around the element
  targeted by the next `click / fill / select / check` so the
  manual visually shows "press here next",
- writes PNGs to `manual/snapshots/<f>/<scenario>/<name>.png`
  and renders `manual/dist/<f>.html` from AsciiDoc + brand CSS.

---

## Output policy

Each consumer owns its outputs. Directories never overlap.

```
e2e/
├── spec.ts                          # verifier — uses runner-core
├── playwright.config.ts
└── .output/                         # gitignored
    ├── html-report/                 # Playwright report
    └── test-results/                # traces, optional evidence frames

manual/
├── generator/
│   ├── docgen.ts                    # documenter — uses runner-core
│   └── themes/<brand>.css
├── snapshots/<f>/<scenario>/*.png   # COMMITTED — manual figures (red-box overlay)
└── dist/<f>.html                    # COMMITTED — end-user operation manual
```

`e2e/.output/` is ephemeral test exhaust — CI uploads it as an
artifact, no commit. `manual/snapshots/` and `manual/dist/` are
publication assets — committed so the manual is shippable
without rebuilding.

If both consumers happen to capture the same screen, that is
fine — they each produce their own PNG with the parameters that
fit their purpose (resolution, cropping, overlay). Forcing reuse
couples two concerns that diverge over time.

---

## Package commands

```
pnpm install:browsers   # Playwright browser DL (one-time)
pnpm e2e                # run verifier — assertions + evidence
pnpm manual             # run documenter — snapshots + HTML
pnpm verify             # = pnpm e2e && pnpm manual (CI default)
```

CI may run `pnpm e2e` and `pnpm manual` in parallel — they share
no state. Verifier failure does not invalidate the manual; the
manual is a publication asset, not a test artifact.

---

## Reference shape

Smallest workable shape — scaffold all of these on first
introduction; don't fold any module into another.

```
repo/
├── docs/                              # specification (engineer-facing)
│   ├── explanation/
│   ├── reference/
│   └── adr/
├── usecases/                          # source of truth
│   └── <feature>.yml
├── packages/
│   ├── usecase-schema/                # type contract (commit, shared)
│   │   └── index.ts
│   └── usecase-runner/                # execution engine (commit, shared)
│       └── index.ts
├── e2e/                               # verification (engineer / CI)
│   ├── spec.ts
│   ├── playwright.config.ts
│   └── .output/                       # gitignored
└── manual/                            # operation manual (end-user)
    ├── generator/
    │   ├── docgen.ts
    │   └── themes/
    ├── snapshots/                     # committed
    └── dist/                          # committed
```

In single-package projects (no `packages/` workspace), inline
`usecase-schema` and `usecase-runner` as two top-level files
(`usecase-schema.ts`, `usecase-runner.ts`); the responsibilities
stay separated even if the directory layer flattens.

---

## When this skill says STOP

- The feature has no user-facing flow → use unit / integration
  tests instead.
- The flow depends on real Stripe / real DB to mean anything →
  the test is integration, not E2E. Move it.
- The YAML cannot be written without seeing the implementation
  first → the spec (Layer 1) is missing. Write it before
  writing the YAML.
- Pressure to "share the same screenshot between e2e and manual"
  → reject. They have different cropping / resolution / overlay
  needs. Each consumer owns its outputs.
