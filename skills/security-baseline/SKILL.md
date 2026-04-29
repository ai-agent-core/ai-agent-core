---
name: security-baseline
description: Apply the minimum security posture to a service — input validation, authn/authz, secrets, headers, dependencies, rate limits, logs, threat model.
---

# Security baseline

Use this skill **for every new service, and for any existing
service whose baseline has not been audited recently**. This is
the floor — not the ceiling.

Authoritative source: `principles/SECURITY_PRINCIPLES.md` and
`rules/SECURITY_RULES.md`.

---

## Step 0 — Threat model first

For any service handling money, PII, auth, multi-tenant data, or
externally-exposed surfaces, write a threat model before
finalizing architecture:

- **assets** — what is worth attacking?
- **actors** — who might attack? (script kiddie, competitor,
  state-level, insider)
- **entry points / trust boundaries** — where does untrusted
  data cross into the system?
- **abuse cases** — "how would I break this if I were attacking?"
- **mitigations and residual risk** — what is reduced; what is
  accepted; who signed off?

A service designed without a threat model is a service designed
to be discovered the hard way.

---

## Step 1 — Input validation

Every value crossing a trust boundary is hostile until validated:

- HTTP request body, headers, query, path,
- webhook payloads,
- queue messages,
- file uploads,
- environment variables consumed by the app,
- responses from upstream third-party services.

Validation is structural AND semantic. After validation, wrap the
value in a typed "trusted" form. Untyped strings flowing into
business logic are forbidden.

Mass-assignment / over-posting is forbidden — accept only the
fields the endpoint expects.

---

## Step 2 — Output encoding

Encode for the context:

- HTML — context-aware escaping (text / attribute / URL / JS /
  CSS),
- SQL — parameterized only,
- shell — argv interface, never string concat,
- logs — redact PII / secrets at source.

---

## Step 3 — Authentication

- delegate to a vendor / IdP where possible (OIDC, SAML),
- if storing passwords: argon2id (preferred) or bcrypt with high
  cost factor,
- MFA available; required for privileged accounts,
- session tokens cryptographically random with sufficient entropy
  (≥128 bits), opaque to client,
- JWTs signed asymmetrically when verifier ≠ issuer; never
  `alg: none`,
- cookies: `Secure`, `HttpOnly`, `SameSite=Lax`/`Strict`,
  `__Host-` prefix when applicable, short lifetime.

See skill `authentication`.

---

## Step 4 — Authorization

- enforced server-side, on every non-public request,
- centralized (policy engine / middleware / dedicated module),
- default decision: **deny**,
- object-level checks (the user can read / write *this specific*
  resource, not just the resource type) — IDOR is the #1 web
  vulnerability,
- distinct from authentication.

---

## Step 5 — Secrets

- in a secrets manager,
- workloads use platform-native identity to read,
- per-workload scope,
- rotated on schedule and on suspicion,
- masked in logs,
- never in source / Dockerfile / CI logs / chat / email.

See skill `secrets-management` and `rules/SECRETS_RULES.md`.

---

## Step 6 — Network and HTTP

- TLS 1.2 minimum (1.3 preferred); SSL / TLS 1.0 / 1.1 forbidden,
- HSTS (≥1y `max-age`, `includeSubDomains`, preload in
  production),
- internal service-to-service: TLS too. "Inside the VPC" is not a
  security boundary.

Web HTML responses set:

- `Strict-Transport-Security`,
- `Content-Security-Policy` (no `unsafe-inline` / `unsafe-eval`
  unless justified per resource),
- `X-Content-Type-Options: nosniff`,
- `Referrer-Policy: strict-origin-when-cross-origin`,
- `Permissions-Policy`,
- `X-Frame-Options: DENY` / CSP `frame-ancestors`.

CORS allowlist is explicit, not `*`, except truly public
read-only endpoints. `Access-Control-Allow-Credentials: true`
with wildcard origin is forbidden.

---

## Step 7 — Common vulnerability classes

Designed-against by default:

- **Injection** (SQL, NoSQL, LDAP, OS, header) — parameterize.
- **XSS** — context-aware encoding + CSP.
- **CSRF** — SameSite cookies + custom header / anti-CSRF tokens
  / token in `Authorization` header.
- **SSRF** — outbound HTTP allowlisted; metadata endpoints
  (169.254.169.254) blocked.
- **Path traversal** — never concat user input into paths;
  canonicalize and verify within an allowed root.
- **Deserialization** — never native-deserialize untrusted data
  (Java native, Python pickle, Ruby Marshal).
- **XXE** — disable external entity processing in XML parsers.
- **IDOR** — see Authorization.
- **Open redirect** — only redirect to allowlisted origins.

---

## Step 8 — Rate limiting and abuse protection

- per-IP and per-principal rate limits at the edge,
- per-route quotas,
- account lockout / progressive delay on auth failures (DoS-by-
  lockout-aware),
- webhook receivers verify signature AND timestamp,
- resource-intensive endpoints (search, export, password reset)
  have stricter limits,
- captcha / proof-of-work for unauthenticated abuse-prone
  endpoints.

---

## Step 9 — File uploads (when applicable)

- validate content-type AND magic bytes,
- store outside web root; serve via separate endpoint or signed
  URL,
- strip metadata for images that may carry geolocation EXIF,
- enforce size limits,
- scan for malware where threat model warrants,
- rename files on storage; do not preserve client filename on
  disk.

---

## Step 10 — Dependencies and supply chain

- lockfile in source,
- SCA on every PR,
- critical / high severity blocks merge,
- post-install scripts disabled for untrusted dependencies where
  possible,
- SBOM generated per release,
- third-party CI actions / images pinned by SHA.

See skill `dependency-management` and
`rules/DEPENDENCY_RULES.md`.

---

## Step 11 — Logging and audit

- authn / authz events logged (success and failure),
- privileged actions logged (actor, target, result),
- audit logs append-only, separate from application logs,
- logs do not contain secrets, full PAN, full SSN, passwords,
  full tokens,
- anomaly detection on auth-failure spikes, geographic outliers,
  privilege changes.

---

## Step 12 — Privacy

- map every column / field that is personal data,
- document lawful basis, retention, right-to-deletion path,
- anonymize for analytics; raw identifiers are not part of
  default downstream pipelines,
- cross-border transfers are deliberate decisions with a written
  basis.

---

## Step 13 — Verify

Before declaring the baseline done, verify each:

- `curl` known-bad inputs against the API → all rejected at
  validation,
- attempt unauthenticated and cross-tenant access → all
  rejected,
- inspect logs → no secrets, no PII at the wrong level,
- run a security headers scanner against the public surface,
- run an SCA scan; triage findings,
- do a tabletop walk-through of the threat model and confirm each
  mitigation is actually in place.

Skipping verification means the baseline is aspirational.

---

## Forbidden

- "we'll add security later,"
- security-by-obscurity as the only protection,
- IP-allowlist as the only authentication,
- shared admin / shared service-account secrets,
- "disable for testing" flags wired into production builds,
- logging the full body of auth / payment endpoints,
- assuming framework defaults are safe (audit them).

---

## When this skill says STOP

- the threat model has not been written for a high-stakes
  service → write it first,
- secret scanning is not in place → fix before pushing,
- the team cannot answer "what happens if a secret leaks?" →
  define the response before launch.

Make the secure path the default path. Make the insecure path
require deliberate, reviewable opt-in.

A breach is a permanent fact about the system. Build to detect,
contain, and recover.
