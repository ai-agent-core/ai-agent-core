# API Design Rules

A public API is a long-lived contract. Every consumer (clients,
mobile apps, partners, internal services, automation) depends on
it. Breakage costs are measured in support load, customer churn,
and lost trust. Agents MUST design APIs with that lifespan in
mind.

These rules apply to HTTP/REST, GraphQL, gRPC, JSON-RPC, message
contracts, and any other surface exposed beyond a single deploy
unit.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Pick the Right Style for the Right Reason

- **REST / HTTP** — public-facing, cacheable, broad client
  ecosystem, resource-oriented domains.
- **GraphQL** — multiple consumers with different shape needs,
  highly variable read patterns, single backend-for-frontend.
- **gRPC / protobuf** — internal service-to-service, high
  throughput, strongly typed contracts, polyglot back ends.
- **WebSocket / SSE** — server-pushed state, real-time
  collaboration, presence.
- **Message-based (queue/topic)** — async work, decoupling,
  fan-out.

Choosing the style is a one-way decision. Use skill `api-design`
to do it properly. Mixing styles inside the same context window
without a written reason is forbidden.

---

# Design From the Caller's View

The first artifact of an API design is **the example call** the
caller will make and **the example response** they will see —
not the implementation.

If you cannot write the example without saying "well, it depends,"
the API is not yet designed.

---

# Resources Over Verbs (REST)

REST endpoints MUST be resource-oriented:

- `POST /orders` — create an order
- `GET /orders/{id}` — read one
- `GET /orders?status=open&customer={id}` — list with filters
- `PATCH /orders/{id}` — partial update
- `DELETE /orders/{id}` — delete

Forbidden:

- RPC-style verbs in URLs: `POST /createOrder`, `POST /doStuff`.
- Different verbs encoding the same resource: `/orders` and
  `/order/list` and `/getAllOrders`.
- HTTP methods used incorrectly (`POST` for read, `GET` with side
  effects).

If a use case truly does not fit the resource model (e.g.
`/orders/{id}/cancellations`, `/exports`), encode it as a
sub-resource or as a side-effect resource — not as a verb in the
path.

---

# HTTP Semantics Are Contracts

HTTP method semantics MUST be respected:

- `GET` — safe, idempotent, cacheable. No side effects.
- `HEAD` — same as `GET`, no body.
- `PUT` — idempotent full replace.
- `PATCH` — partial update, idempotency depends on payload.
- `POST` — create, action, non-idempotent by default.
- `DELETE` — idempotent (deleting an absent resource is fine).

Status codes MUST mean what they mean:

- `200` — success with body
- `201` — created (with `Location` for the created resource)
- `204` — success, no body
- `400` — client error (request malformed)
- `401` — unauthenticated
- `403` — authenticated but not authorized
- `404` — resource not found
- `409` — conflict (versioning, duplicate)
- `410` — gone (deliberately removed)
- `422` — validation failure (semantic, not syntactic)
- `429` — rate-limited
- `500` — server failure (generic)
- `503` — service unavailable (with `Retry-After`)

Forbidden:

- `200 OK { "error": ... }` — disguising failures as success.
- `404` for "you do not have access" (use `403`, or `404` only
  to hide existence, deliberately).
- 5xx for input errors.

---

# Request Validation Is Mandatory

Every endpoint MUST validate every field before touching domain
logic:

- type, range, enum membership, length, format,
- required vs. optional fields,
- forbidden combinations.

Validation errors return `422` with a structured body that names
each invalid field. A single error message about "validation
failed" is forbidden; clients need to know what to fix.

---

# Error Bodies Are Structured

Every error response (4xx, 5xx) MUST follow a single, documented
shape across the API. Recommended (RFC 7807 / Problem Details
or equivalent):

```json
{
  "type":   "https://example.com/errors/validation",
  "title":  "Validation failed",
  "status": 422,
  "code":   "ORDER_INVALID_QUANTITY",
  "detail": "Quantity must be positive.",
  "instance": "/orders",
  "errors": [
    { "field": "quantity", "code": "MIN", "message": "Must be > 0." }
  ],
  "traceId": "..."
}
```

Forbidden:

- different error shapes per endpoint,
- error messages that leak stack traces,
- error messages that leak SQL or framework internals,
- bare strings as error bodies.

`code` is stable and machine-readable; `message` is human-readable
and may change.

---

# Versioning Is Mandatory and Explicit

Every public API MUST be versioned. Pick one strategy and use it
consistently:

- URL path: `/v1/orders` (most common, simplest).
- Header: `Accept: application/vnd.example.v1+json`.
- Query parameter (discouraged for production).

Mixing strategies within the same API surface is forbidden.

When breaking changes are needed, ship a new version. Run the old
version with a published end-of-life date. Never break callers in
place.

What counts as breaking:

- removing a field,
- renaming a field,
- changing a field's type,
- changing a status code,
- making an optional field required,
- changing the meaning of a value.

Adding optional fields and new endpoints is non-breaking.

---

# Pagination Is Required for Lists

List endpoints MUST paginate. Pick one strategy and document it.

- **Cursor-based** (preferred for large datasets, stable under
  inserts):
  - `GET /orders?cursor=abc&limit=50`
  - response includes `next_cursor`, `prev_cursor`.
- **Offset-based** (acceptable for small, mostly-static lists):
  - `GET /orders?offset=100&limit=50`
  - degrades on deep offsets and on inserts.

Required:

- a hard maximum on `limit`,
- a default `limit`,
- a stable sort key (creation time, ID),
- consistent response shape: `{ data: [...], pagination: {...} }`.

Forbidden:

- "return everything" as a default,
- response shapes that mix paginated and non-paginated arrays,
- sorts that are not deterministic (ties without a tiebreaker).

---

# Idempotency for Writes

Any non-idempotent write that may be retried (mobile clients,
flaky networks, queues) MUST accept an `Idempotency-Key` header.

- The server stores the key, the request hash, and the response
  for a documented retention window.
- Replay returns the original response, not a re-execution.
- Different request body for the same key returns a deterministic
  conflict.
- Idempotency keys live in the same transactional boundary as the
  effect (see `OPERATIONAL_PRINCIPLES.md`).

---

# Authentication and Authorization at the Boundary

Every non-public endpoint MUST:

- declare its authentication requirement in code (annotation,
  middleware, route metadata),
- declare its authorization requirement explicitly (role,
  permission, ownership predicate),
- fail with `401` for missing / invalid auth,
- fail with `403` for valid auth without permission.

Forbidden:

- "we forgot to add the middleware" — make auth-required the
  default; public is opt-in.
- mixing authentication and authorization checks (a token is not
  a permission).
- relying on the framework's default route exposure.

See `rules/AUTHENTICATION_RULES.md`.

---

# Rate Limit at the Edge

Every public endpoint MUST be rate-limited:

- per IP and per principal,
- by route or route group, not globally,
- with `429` and `Retry-After` on rejection,
- with `X-RateLimit-Limit`, `X-RateLimit-Remaining`,
  `X-RateLimit-Reset` headers when feasible.

Internal endpoints exposed to other services MUST also have
quotas. A misbehaving caller must not be able to take the system
down.

---

# Avoid Chatty Endpoints

A typical use case should not require N+1 round trips:

- expose related resources via embedded fields or batch endpoints
  where it materially reduces round-trips,
- support `?fields=` selection or GraphQL when consumers need
  variable shapes,
- offer batch read endpoints (`GET /orders?ids=1,2,3`) when the
  caller needs many.

Forbidden defaults:

- mobile clients required to fan out 30 requests for a single
  screen,
- endpoints that hydrate everything on every read regardless of
  what the caller needs.

---

# Time, Money, IDs

- Times in payloads MUST be ISO 8601 UTC with offset
  (`2026-04-29T12:34:56Z` or with explicit `+00:00`). No locale
  formats. No epoch milliseconds in mixed APIs.
- Money MUST be `{ amount: <minor units integer or string
  decimal>, currency: "JPY" }`. Never bare floats. See
  `rules/MONEY_HANDLING_RULES.md`.
- IDs are opaque strings to the client. Internal numeric IDs are
  not exposed where guessability matters.

---

# Nullability and Defaults

Every field's nullability MUST be documented and consistent
between request and response:

- absent fields and `null` fields MUST not mean different things
  unless documented (and they should not),
- partial updates explicitly distinguish "not provided" from
  "set to null,"
- enum fields document the full value set; clients MUST handle
  unknown values gracefully (forward compatibility).

---

# Filtering, Sorting, Selection

Standardize the syntax across the API:

- `?filter[status]=open&filter[customer]=123`
- `?sort=created_at,-priority`
- `?fields=id,status,total`

Document the supported filter operators (`eq`, `gt`, `lt`, `in`,
`contains`) once for the API, not per endpoint.

Forbidden:

- arbitrary search predicates that translate into raw SQL,
- different syntax per endpoint.

---

# Webhooks Have Their Own Rules

If the system delivers webhooks:

- payloads MUST be signed (HMAC over body with timestamp).
- timestamps prevent replay (`X-Signature-Timestamp`).
- delivery is at-least-once, with documented retry schedule and
  dead-letter behavior.
- consumers receive an idempotency-friendly event ID.
- there is a verifiable test endpoint for partners.

A webhook without a signed body is not a webhook; it is an
unauthenticated POST.

---

# Documentation Is Part of the API

The API is undocumented until consumers can:

- discover every endpoint,
- see every field's type, nullability, and example,
- find error codes and their meanings,
- generate a client.

Use OpenAPI / GraphQL schema / .proto as the source of truth.
Doc generators consume it; humans review the generated docs.

If the doc and the implementation disagree, the doc is wrong by
default — but the next CI run should fail until they agree.

---

# Public APIs Have a Lifecycle

For external APIs:

- announce deprecations before scheduled removal (typically 6+
  months for paid customers, 3+ months for free),
- emit `Deprecation` and `Sunset` HTTP headers,
- keep a public changelog,
- never remove a version silently.

---

# Forbidden Anti-patterns

- chatty boolean response envelopes (`{ ok: true }` for success,
  `{ ok: false, ... }` for errors mixed with `2xx`).
- "GET with body" except where the protocol explicitly supports
  it.
- secrets in URLs.
- 200-only APIs that put status in a body field.
- exposing internal IDs (DB primary keys) where guessability,
  enumeration, or scraping matters; use opaque external IDs.
- magic strings in enum fields without a defined value set.
- mixing camelCase and snake_case in the same response.

---

# Prime Directive

The API is the contract. The implementation serves the contract,
not the other way around. Design the contract to be the kind of
thing a stranger could implement against, then implement it.

Stable APIs are the bedrock other systems are built on. Do not
casually crack the bedrock.
