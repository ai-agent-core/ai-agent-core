---
name: api-design
description: Design or change a public API. Pick the style, write the example call before the implementation, version deliberately, and lock down the contract.
---

# API design

Use this skill **whenever a new API is being designed, an existing
API is being extended in a non-trivial way, or a breaking change is
on the table**. Authoritative source: `rules/API_DESIGN_RULES.md`.

This skill is the operational loop. The rules are the law.

---

## Step 1 — Identify the audience

Before deciding anything else, name in one sentence:

- **Who** calls this API (web client, mobile, partner, internal
  service, batch job, CLI)?
- **What** do they need from each call (a result, a state change,
  a fan-out)?
- **How** will they use it (interactive UX, machine workflow,
  high-throughput, offline retries)?

Different audiences imply different constraints. A partner API
needs a stability story; an internal service can iterate faster.
Mobile clients need forward compatibility because old versions
linger.

If the audience is unclear, ask the user. Designing for "everyone"
designs for no one.

---

## Step 2 — Pick the style

| When                                                       | Style          |
| ---------------------------------------------------------- | -------------- |
| Public-facing, resource-oriented, broad clients            | REST / HTTP    |
| Diverse consumers with variable shape needs                | GraphQL        |
| Internal service-to-service, polyglot, high throughput     | gRPC / proto   |
| Server-pushed state, presence, real-time collaboration     | WS / SSE       |
| Async work, fan-out, decoupling                            | Message bus    |

Mixing styles for the same surface area is forbidden without a
written reason. If the choice is non-obvious, write an ADR (skill
`adr`) before implementing.

---

## Step 3 — Write the example first

Before any implementation, write:

- the example **request** the caller will make (curl / fetch / SDK
  snippet),
- the example **response** (success, the common error, an edge
  case),
- the example **call from the caller's primary language**.

If you cannot write the example without saying "well, it depends,"
the design is not yet ready.

Examples uncover ambiguity that wireframes hide.

---

## Step 4 — Apply the contract checklist

Run through `rules/API_DESIGN_RULES.md` and verify each:

- Resource-oriented URLs, correct HTTP method semantics
  (REST).
- Status codes used per spec (200/201/204/400/401/403/404/409/422/429/5xx).
- Validation: every field validated; structured 422 with per-field
  errors.
- Error shape: one consistent schema across the API (RFC 7807 or
  equivalent).
- Versioning: pick one strategy (URL path is simplest for public
  APIs); breaking changes mean a new version.
- Pagination: cursor-based for large datasets; defaults and max
  bounds documented.
- Idempotency: writes accept `Idempotency-Key`; replay safe.
- Authn / authz: declared per route; default deny; object-level
  checks.
- Rate limiting: per-route, per-principal, with `Retry-After`.
- Time / money / IDs: ISO 8601 UTC, money has `{ amount,
  currency }`, IDs opaque to clients.
- Nullability and unknown enum values handled gracefully.
- Filtering / sorting / selection use a uniform syntax across the
  API.
- Webhooks (if any): signed, timestamped, deduplicated.

Any "no" blocks completion until resolved or explicitly justified.

---

## Step 5 — Source-of-truth schema

The contract lives as machine-readable schema in source control:

- OpenAPI 3.x for REST,
- GraphQL SDL for GraphQL,
- `.proto` for gRPC,
- AsyncAPI for events.

CI verifies the implementation matches the schema. The doc is
generated, not hand-written.

If the spec drifts from the implementation, the build is broken.

---

## Step 6 — Versioning and deprecation plan

Before shipping:

- the version is declared,
- the deprecation policy is in writing (e.g. "old version
  available 6 months past sunset"),
- the changelog is updated,
- consumers know how to migrate.

Internal APIs follow the same rules with lighter ceremony.

---

## Step 7 — Test the contract

- contract tests against the schema,
- consumer-driven contract tests for known consumers,
- replay tests for idempotency,
- pagination tests (boundary, empty, single-item, large),
- error-response tests (every documented error returns the
  documented shape).

Forbidden:

- "we tested the happy path,"
- "the OpenAPI spec is documentation, not enforcement."

---

## Step 8 — Operate

After launch:

- monitor per-endpoint RED metrics (rate, errors, duration),
- watch p95 / p99 against the budget,
- watch for callers using the old version after deprecation,
- keep the changelog living.

---

## Forbidden

- RPC-style verbs in URLs (`POST /createOrder`).
- 200-only APIs that put errors in the body.
- "GET with body" endpoints.
- Secrets in URLs.
- Mass assignment (accepting any field the client sends).
- Different error shapes per endpoint.
- Returning 500 for input validation.
- Public-facing endpoints without rate limits.
- Endpoints returning entire datasets (no pagination).

---

## When this skill says STOP

- The audience is unclear → ask before designing.
- The schema cannot be written before the implementation → the
  design is not ready.
- A breaking change is needed without a versioning plan → escalate.

A well-designed API is the cheapest insurance against rewrites.
Spend the time once.
