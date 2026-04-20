# Package Layout Rules — Frontend

This document defines the package layout for frontend projects.

Shared conventions (the four-layer convention, dependency
direction, bounded-context-first) are defined in
`rules/PACKAGE_LAYOUT_COMMON_RULES.md` and apply here.

---

# Default Stack

Unless the instructor specifies otherwise, Frontend projects use:

- **SvelteKit** (filesystem routing, SSR / SSG-capable)
- **Tailwind CSS** (utility-first styling)
- **TypeScript**

The four-layer architecture is framework-agnostic.

Patterns documented here translate to Next.js, Nuxt, Remix, Astro,
or Vite + React. Only the framework adapter layer changes.

---

# Four-Layer Mapping

```
interfaces/     user-facing UI             (Page, Layout, Component, Form)
applications/   screen behavior / state    (UseCase, Store, Composable, Converter)
domains/        business model             (AggregateRoot, Processor, Repository ...)
architectures/  external connectivity      (ApiClient, Storage, Analytics, ...)
```

Frontend has no persistent database of its own.

`architectures/` here represents the boundary to backend services,
browser APIs, and third-party services — not persistence.

---

# Framework-Mandated Folders

SvelteKit requires `src/routes/` for filesystem routing.

This folder sits **outside** the four-layer structure and MUST
act as a **thin adapter**.

Route files MUST delegate immediately into `interfaces/`.

No business logic, state handling, or layout composition in
`src/routes/`.

The same rule applies to `app/` (Next.js App Router), `pages/`
(Nuxt, Next.js Pages Router), and any equivalent folder in other
meta-frameworks.

---

# Example Layout

```
my-site/
  src/
    routes/                                   (SvelteKit, thin adapters)
      +layout.svelte
      order/
        place/
          +page.svelte                        (delegates to interfaces/)

    interfaces/
      order/
        PlaceOrderPage.svelte                 (page content)
        PlaceOrderForm.svelte                 (input UI)
      shared/
        AppLayout.svelte
        Button.svelte

    applications/
      order/
        placeOrderUseCase.ts                  (1 scenario = 1 module)
        placeOrderStore.ts                    (screen-local state)
        orderConverter.ts

    domains/
      order/
        Order.ts                              (AggregateRoot)
        PricingProcessor.ts
        OrderStatus.ts                        (ValueObject)
        OrderRepository.ts                    (interface)

    architectures/
      order/
        OrderApiClient.ts
        OrderRepositoryImpl.ts
      shared/
        httpClient.ts
        localStorageAdapter.ts
        analyticsClient.ts

    app.html
    app.css                                   (Tailwind directives only)

  tailwind.config.ts                          (design tokens)
  svelte.config.js
  tsconfig.json
```

---

# Stereotypes — `interfaces/`

**Page** — Top-level screen content (`.svelte`). Composes Layouts,
Components, and Forms. Calls `applications/` for behavior.

**Layout** — Reusable framing (headers, sidebars, shells).

**Component** — Reusable presentational unit. Pure UI. Props in,
events out. MUST NOT reach into `applications/` state directly;
state flows through props.

**Form** — Input UI. Validation display. Delegates submission to
a UseCase.

MUST NOT contain business logic.

MUST NOT fetch data directly from `architectures/` — always route
through `applications/`.

---

# Stereotypes — `applications/`

**UseCase** — One scenario per module. Exports functions or a
class whose methods represent user actions on the screen.

**One action = one method.**

Orchestrates domain objects and side-effect boundaries.

The frontend equivalent of a transaction boundary is the
**user action boundary**: load, submit, cancel, retry.

**Store** — Svelte store (`writable` / `readable` / `derived`).

Holds screen-local state.

MUST NOT hold global state beyond the scope it serves.

Use the smallest store surface the screen requires.

**Composable** — Reusable behavior module (the Svelte equivalent
of a React hook).

Exports a function returning state and actions.

Use when a behavior pattern recurs across screens.

**Converter** — Bidirectional translator between API response
shapes and domain objects, and between domain objects and UI
view-state.

---

# Stereotypes — `domains/`

Stereotype names and responsibilities are **identical to Backend**
(see `rules/PACKAGE_LAYOUT_BACKEND_RULES.md`).

Frontend domains are typically lighter — only the rules the UI
needs to apply locally (validation, formatting derivations,
client-side calculation).

**Repository** interfaces in a frontend domain represent API
contracts the UI depends on — not database operations.

**Processor** computes client-side derived values (price breakdown
display, form-level validation summaries, filtering) and takes
data access via callback as in Backend.

---

# Stereotypes — `architectures/`

**ApiClient** — Typed wrapper over backend HTTP endpoints.

Handles request shape, auth headers, error normalization.

**RepositoryImpl** — Implements a domain Repository interface by
calling ApiClient.

**StorageAdapter** — Thin wrapper over `localStorage`,
`sessionStorage`, or `IndexedDB`. Domain types in, domain types out.

**AnalyticsClient** — Wrapper over analytics SDKs.

**WebSocketClient** — Realtime connection management.

Framework-specific and browser-specific APIs live here only.

---

# Tailwind Rules

**Utility-first in markup.** Express styling through Tailwind
classes in the component template.

**Design tokens live in `tailwind.config.ts`** — colors, spacing,
type scale, breakpoints, shadows.

Hard-coded raw pixel values or hex colors in components are
FORBIDDEN.

If a value repeats, it belongs in `tailwind.config.ts`.

**`@apply` is used sparingly.** Only when:

- the same utility sequence repeats across many components
- the repetition is semantically meaningful (`btn-primary`, etc.)

Do NOT use `@apply` to recreate what a component abstraction
would solve more cleanly.

**Conditional classes** MUST use a typed class-composition helper
(`clsx`, `tailwind-merge`, or Svelte's `class:` directive) —
never string concatenation.

**Arbitrary values** (`[12px]`, `[#fff]`) are FORBIDDEN outside of
genuinely one-off exceptions. Name the token in the config instead.

**No CSS-in-JS libraries.** They fight Tailwind's mental model and
the utility-first discipline.

**Per-component `<style>` blocks** are allowed only for:

- genuinely local, non-reusable decoration
- animations that Tailwind cannot express concisely

Global CSS lives in `app.css` and contains only Tailwind directives
and minimal resets.

---

# Forbidden Patterns (Frontend)

- business logic inside Page, Layout, or Component
- `fetch()` calls from Page or Component
- Store used as a global dumping ground for unrelated state
- business rules duplicated between frontend and backend domains
  instead of shared types or derivations
- framework-mandated folders (`routes/`, `app/`, `pages/`)
  containing anything beyond thin delegation
- inline hex colors or pixel values instead of Tailwind tokens
- CSS-in-JS or styled-components introduced alongside Tailwind
- Converter logic duplicated across multiple Components
