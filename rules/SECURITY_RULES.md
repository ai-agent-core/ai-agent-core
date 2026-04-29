# Security Rules

Concrete, enforceable constraints. The principles behind these
rules live in `principles/SECURITY_PRINCIPLES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Input Validation at Every Boundary

Every value crossing a trust boundary MUST be validated:

- HTTP request bodies, headers, query strings, path parameters,
- webhook payloads,
- queue messages,
- file uploads,
- environment variables consumed by the app,
- responses from upstream third-party services.

Validation is structural (shape) AND semantic (meaning). After
validation, the value is wrapped in a type that says "trusted."
Untyped strings flowing into business logic are forbidden.

---

# Output Encoding

Output to a context MUST be encoded for that context:

- HTML — context-aware HTML escaping (text, attribute, URL,
  JS, CSS).
- SQL — parameterized queries only. String concatenation building
  SQL is forbidden.
- Shell — never build shell strings from user input. Use the
  argv-style interface of the language.
- JSON / XML — use the language's serializer; do not build by
  hand.
- Logs — redact PII and secrets before writing.

Forbidden:

- "we sanitize on input so we can output raw" — output context is
  not knowable at input time.
- Disabled escaping flags ("trust this string") without a written
  reason.

---

# Authentication

- Passwords (when used): argon2id (preferred) or bcrypt with a
  high cost factor. Never plain hash. Never MD5 / SHA-* alone.
- MFA available and required for privileged accounts.
- Session tokens: cryptographically random, sufficient entropy
  (≥128 bits), opaque to the client.
- JWTs: signed (asymmetric where the verifier is not the issuer),
  short-lived, with documented `aud`, `iss`, `exp`, `nbf`.
  Never trust a JWT without verifying signature and claims.
- `alg: none` and weak algorithms (`HS256` for cross-trust-domain)
  are forbidden.

See `rules/AUTHENTICATION_RULES.md`.

---

# Authorization

- Authorization is checked on the server, on every request that
  touches non-public data — even when the client also checks.
- Authorization decisions are centralized (policy engine,
  middleware, dedicated module), not scattered through
  controllers.
- Default decision: deny. Allow is opt-in per route / resource.
- Object-level authorization is enforced (the user can read /
  write *this specific* resource, not just the resource type).
- IDOR (Insecure Direct Object Reference) is the most common
  application security failure — every read or write of a
  resource by ID checks ownership / permission first.

Forbidden:

- using the presence of a token as authorization,
- relying on UI hiding to prevent access,
- "admin via header" / "admin via query param".

---

# Secrets

Secrets MUST:

- never be committed to source control (git history is forever),
- never be printed to logs (including stack traces),
- come from a secret manager (cloud KMS / Vault / SOPS / SSM
  Parameter Store) or a runtime-injected env var from one,
- be rotated on a schedule and on suspicion,
- be scoped to the workload that needs them.

Forbidden:

- `.env` checked into the repo,
- secrets in CI logs (mask, scrub, prefer OIDC over long-lived
  tokens),
- shared developer secrets (everyone uses their own credential),
- passing secrets via command-line arguments (visible in process
  listings).

See `rules/SECRETS_RULES.md`.

---

# Cryptography

- Use vetted libraries; never invent crypto primitives or modes.
- Symmetric: AES-GCM or ChaCha20-Poly1305 (AEAD).
- Asymmetric: Ed25519 / ECDSA P-256 / RSA-2048+ (RSA-3072+ for
  long-term).
- Hashing for integrity: SHA-256+. For passwords: argon2id /
  bcrypt — never SHA / MD5.
- Random for security purposes uses CSPRNG (`crypto/rand`,
  `secrets`, `getrandom`). `Math.random()` and `rand()` are
  forbidden for security.
- Constant-time comparison for secrets / tokens / signatures.
- Algorithm and version are embedded in any persisted ciphertext
  or token (`v1.aes-gcm.<...>`).

Forbidden:

- ECB mode,
- static IVs / nonces,
- "rolling our own."

---

# TLS Everywhere

- TLS 1.2 minimum; 1.3 preferred. SSL and TLS 1.0 / 1.1 forbidden.
- HSTS enabled with at least one year max-age in production.
- HTTP-only endpoints redirect to HTTPS; never serve secrets over
  HTTP.
- Internal service-to-service traffic is TLS too. "Inside the VPC"
  is not a security boundary.
- Certificate rotation is automated (e.g. ACME / cert-manager).
  Manual cert renewal is a future outage.

---

# Web-Specific Headers

For HTML-serving endpoints, set:

- `Strict-Transport-Security: max-age=31536000; includeSubDomains;
  preload`
- `Content-Security-Policy` — least privilege, no `unsafe-inline`
  / `unsafe-eval` unless justified per resource.
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin` (or
  stricter).
- `Permissions-Policy` — disable features the app does not use.
- `X-Frame-Options: DENY` / equivalent CSP `frame-ancestors`.

Cookies:

- `Secure`, `HttpOnly`, `SameSite=Lax` (or `Strict` for sensitive
  flows).
- `__Host-` prefix for session cookies where applicable.
- Short lifetime; rotate on privilege change.

---

# CSRF and CORS

- Mutating endpoints called from a browser MUST be protected:
  - SameSite cookies + custom header check, or
  - Anti-CSRF tokens, or
  - OAuth / JWT in `Authorization` header (not in cookies for
    cross-site).
- CORS allowlist is explicit, not `*`, except for truly public
  read-only endpoints.
- `Access-Control-Allow-Credentials: true` is forbidden with
  wildcard origins.

---

# Common Application Vulnerabilities

The following classes MUST be designed against:

- **Injection** (SQL, NoSQL, LDAP, OS command, header injection)
  — parameterize, use safe APIs.
- **XSS** — context-aware output encoding, CSP.
- **CSRF** — see above.
- **SSRF** — outbound HTTP from the server is restricted to
  allowlisted hosts; metadata endpoints (169.254.169.254) are
  blocked.
- **Path traversal** — never concatenate user input into file
  paths; canonicalize and verify within the allowed root.
- **Deserialization** — never deserialize untrusted data with
  language-native serializers (Java native, Python pickle, Ruby
  Marshal). JSON / protobuf / explicit schemas only.
- **XXE / XML expansion** — disable external entity processing
  in XML parsers.
- **IDOR** — see Authorization.
- **Mass assignment / over-posting** — parse only the fields the
  endpoint expects; reject unknown fields or strip them
  explicitly.
- **Open redirect** — only redirect to allowlisted origins.

OWASP Top 10 is the floor, not the ceiling.

---

# File Uploads

- Validate content-type AND magic bytes (do not trust the
  client-provided extension).
- Store outside the web root; serve via a separate endpoint or
  signed URL.
- Strip metadata for images that may carry geolocation EXIF.
- Enforce size limits.
- Scan for malware where threat model warrants.
- Filenames are not user-controllable on disk; rename on storage.

---

# Rate Limiting and Abuse Protection

- Per-IP and per-principal rate limits at the edge.
- Account lockout / progressive delay on auth failures, with care
  to avoid DoS by lockout (CAPTCHA / risk score).
- Webhook receivers verify signature AND timestamp (replay
  window).
- Resource-intensive endpoints (search, export, password reset)
  have stricter limits.
- Captcha or proof-of-work for unauthenticated, abuse-prone
  endpoints.

---

# Logging and Monitoring

- Authentication and authorization events are logged (success
  AND failure).
- Privileged actions are logged with actor and target.
- Logs do not contain passwords, tokens, full credit-card
  numbers, full personal identifiers, or secrets.
- Audit logs are append-only and stored separately from
  application logs.
- Anomaly detection runs on auth-failure spikes, geographic
  outliers, privilege changes.

---

# Dependency Hygiene

- Lockfiles in source.
- SCA scanning (e.g. Dependabot, Renovate, Snyk) on every PR.
- Critical / high vulnerabilities trigger an action — not "we
  will get to it."
- Disable unrestricted post-install scripts (npm `--ignore-scripts`
  for non-trusted dependencies; vendor pinning).
- SBOM generated and retained per release.

See `rules/DEPENDENCY_RULES.md`.

---

# Privacy and Personal Data

- Map every column / field that is personal data.
- Document lawful basis (where applicable), retention, and the
  right-to-deletion path per dataset.
- Pseudonymize for analytics; raw identifiers are not part of
  default downstream pipelines.
- Cross-border data transfers are deliberate decisions with a
  written basis.
- Per-user export and per-user deletion are first-class features,
  not future runbooks.

---

# Audit and Forensics

- Every privileged action is auditable: who, what, when, from
  where, with what result.
- Audit storage is immutable (append-only, write-once where
  possible).
- Time synchronization is reliable (NTP) — bad clocks ruin
  audits.
- Retention is documented and meets legal floors.

---

# Threat Model Required For

- public-facing services,
- multi-tenant systems,
- payment / financial flows,
- PII handling,
- authentication / authorization changes,
- new external integrations.

The threat model lives next to the design (ADR / spec) and is
re-evaluated when scope changes materially.

---

# Forbidden Anti-patterns

- "Security through obscurity" as the only protection.
- "Check it later, ship it now" — security is not a follow-up
  ticket.
- "Disable for testing" flags wired into production builds.
- IP-allowlist as the only authentication.
- Symmetric secrets shared across environments.
- Reusing secrets across services.
- Logging the full request body of authentication / payment
  endpoints.

---

# Prime Directive

Make the secure path the default path. Make the insecure path
require deliberate, reviewable opt-in. Assume every input is
hostile, every dependency is untrusted, every secret is a
capability.

A breach is a permanent fact about your system. Design as if it
will happen; build to detect, contain, and recover.
