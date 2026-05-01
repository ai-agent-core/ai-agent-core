# Frontend Demo Mode Rules

Every frontend application MUST support two runtime modes:

- **demo** — external connections are mocked. The UI is fully usable
  without any backend, API key, or third-party service. A "log in as
  demo user" affordance is visible on the login surface.
- **production** — external connections are live. Mocks are unreachable.

These rules define how that switch is wired so behavior stays
consistent across apps and so demo mode never leaks into production.

---

# Core Contract

## Mode source

Mode MUST be driven by a single public environment variable:

```
PUBLIC_APP_MODE = demo | production
```

The variable MUST be read through the framework's static-public env
channel (e.g. `$env/static/public` in SvelteKit). Runtime-dynamic
mode resolution is FORBIDDEN — builds that must behave as
production MUST be buildable without demo code reachable from the
entry point. This preserves tree-shaking of mock implementations.

Default when unset: **demo**. Production deploys MUST set the
variable explicitly; CI MUST fail if a production build is produced
without `PUBLIC_APP_MODE=production`.

## Mode module

Each app MUST expose a single module:

```
architectures/shared/mode.ts
```

Exports:

- `type AppMode = 'demo' | 'production'`
- `const MODE: AppMode`
- `isDemoMode(): boolean`
- `isProductionMode(): boolean`

No other module reads the env variable directly.

---

# DI Boundary

## Interface lives in domains/

Every external dependency (auth, customers, contracts, invoices,
storage, analytics, payments) is represented by an interface in
`domains/<context>/<Name>Repository.ts` (or `<Name>Gateway.ts` for
non-persistence boundaries).

## Implementations live in architectures/

`architectures/<context>/` MUST hold at minimum:

```
architectures/<context>/
  Real<Name>ApiClient.ts      // production — calls the real service
  Mock<Name>ApiClient.ts      // demo — in-memory or fixture-backed
  fixtures/
    <scenario>.ts             // static fixtures, reusable for E2E
```

Both implementations MUST fulfill the same interface declared in
`domains/`. No type divergence.

## Bootstrap

A single module MUST own the swap:

```
architectures/shared/bootstrapClients.ts
```

It exports a `getClients()` registry whose concrete members are
resolved exactly once, at first call, based on `MODE`.

`applications/` layer uses `getClients()` to obtain implementations.

`interfaces/` layer MUST NOT import from `architectures/` except
`bootstrapClients` (for UI branching on `mode`) and `mode.ts`
(for the same purpose). All data access MUST route through
`applications/`.

---

# Mock Implementation Rules

Mocks MUST:

- fulfill the domain interface exactly — no extra public methods
- read data from `architectures/<context>/fixtures/*` rather than
  hard-coding values inline (so the same fixtures feed E2E tests)
- return realistic shapes — IDs, timestamps, and JSON structures
  identical to production responses
- simulate latency with a small randomized delay for any call that
  would cross the network in production (50–200ms baseline), unless
  instantaneous behavior is specifically desired
- flag their return values as demo-origin where it matters —
  e.g. `AuthSession.isDemo = true` — so UI surfaces can signal it
- never call `fetch`, `XMLHttpRequest`, or third-party SDKs

Mocks MUST NOT:

- be gated on `process.env.NODE_ENV`
- be guarded by `if (DEV)` blocks that still compile in production
- be imported from `interfaces/` or `applications/` directly

---

# UI Surface Rules

## Demo mode banner

When `MODE === 'demo'`, the root layout MUST display a persistent
banner indicating demo mode. The banner MUST:

- identify the mode unambiguously (text "DEMO MODE" or equivalent)
- state the consequence in one line (data not persisted, external
  calls mocked)
- use a color distinct from production UI — a warning ochre is the
  default; do not use the primary accent color
- expose the active env var name in monospace so developers can
  confirm origin at a glance

## Demo login affordance

The login surface MUST conditionally render a "log in as demo user"
button when `MODE === 'demo'`. The button MUST:

- live visually below the primary credential form, separated by a
  horizontal divider — not as the primary CTA
- state the resulting action concretely ("デモアカウントで開始する"),
  not a generic verb
- call `AuthUseCase.loginAsDemoUser()`, which in turn calls
  `AuthRepository.loginAsDemoUser()` on the injected client

In production mode, the button MUST NOT render, and calls to
`AuthRepository.loginAsDemoUser()` on the real implementation MUST
throw to prevent accidental reachability.

---

# Fixtures

Fixtures are the source of truth for demo data.

- one `.ts` file per scenario (e.g. `demoTenantWith3Contracts.ts`)
- pure functions that return plain domain-shaped objects
- accept a `now: Date` parameter for any time-relative value to keep
  determinism for tests
- no random UUIDs without a seed; prefer deterministic ids with a
  `demo-` prefix so they are recognizable in logs

Fixtures MUST be re-usable by:

- MockApiClient implementations
- E2E tests (Playwright) that boot the app in demo mode

---

# Forbidden Patterns

- branching business logic on `MODE` inside `applications/` or
  `domains/` — the swap MUST happen at `architectures/` only
- placing a mock implementation inline in a UseCase file
- storing demo data in `localStorage` without a `demo.` key
  prefix — collisions with production state are prohibited
- shipping a build where both Real and Mock clients are loaded at
  runtime when only one mode is active (dead-code elimination must
  survive — keep bootstrap branching statically analyzable)
- reusing the primary accent color for the demo banner — it MUST
  remain visually distinct from production UI

---

# Checklist (before merging a surface that touches demo mode)

1. Does a new external boundary have both a `Real*` and `Mock*`
   implementation behind the same domain interface?
2. Are fixtures extracted into `architectures/<context>/fixtures/`?
3. Does the UI branch on `mode` only through `getClients().mode`?
4. In production mode, is the demo login button absent AND the
   `loginAsDemoUser()` path throwing?
5. Does the demo banner state the active env var name?
6. Is every mode branch statically analyzable so production builds
   tree-shake mock code out?

Any "no" blocks merge.
