# Security Principles

Security is a primary design constraint, not a final-pass review.

A system cannot be retrofitted into safety. The architecture either
absorbs hostile input by design, or it does not. Agents MUST treat
security as an engineering principle on the same level as
correctness and maintainability.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Assume Hostile Input

Every value crossing a trust boundary is hostile until validated.
Trust boundaries include:

- HTTP / RPC / gRPC requests from clients
- Webhook payloads from third parties
- Message-queue messages
- File uploads
- Environment variables in shared environments
- Output of upstream services

Validation is structural (shape) and semantic (meaning). Both are
required. Validation belongs at the boundary, not deep in business
logic. Once inside the boundary, types should encode that the value
is already trusted.

---

# Least Privilege

Every component, credential, role, network path, and database user
MUST run with the smallest privilege set that lets it do its job.

Concretely:

- Application database users have row-level minimum scope; no
  superuser, no DDL in production.
- IAM roles are scoped per workload, not per environment.
- Service-to-service calls use scoped tokens, not wildcard keys.
- Developers do not share production credentials; access is named,
  audited, and time-bounded.

If "make it work" required granting broad privileges, the design
is wrong. Narrow the privilege; do not preserve the design.

---

# Defense in Depth

A single compromised layer must not equal a compromised system.
Independent layers MUST validate independently:

- Network (segmentation, firewalls, VPC).
- Identity (authn, authz, MFA).
- Application (input validation, output encoding, rate limits).
- Data (encryption at rest and in transit, row-level rules).
- Audit (immutable logs, tamper detection).

If removing one layer would expose data, the system depended on
that layer alone. Add a second.

---

# Secure by Default

Defaults MUST be the safe choice. Optional knobs may relax safety,
but the default must never require a user to remember to flip a
switch in order to be safe.

- HTTPS is on by default; HTTP is opt-in.
- Cookies are `Secure`, `HttpOnly`, and `SameSite=Lax` by default.
- Authn-required is the default; public is opt-in per route.
- Admin endpoints are not exposed publicly by default.
- Logging redacts PII by default; un-redacted is opt-in and
  reviewed.

Insecure defaults compound. Every developer that does not know
about the knob inherits the unsafe state.

---

# Never Trust the Client

The client is part of the user-agent surface, not the authority.

- Authorization decisions MUST happen on the server.
- Validation that protects business rules MUST run on the server,
  even if the client also validates.
- Client-only feature gates are UX, not security.
- Tokens, identifiers, and prices coming from the client are
  inputs, not facts.

If a feature can be unlocked by editing local storage, the security
boundary was not on the server.

---

# Secrets Are Capabilities, Not Configuration

Secrets — API keys, signing keys, DB passwords, tokens — grant
authority. They MUST be:

- never stored in source control,
- never printed to logs,
- rotated on a schedule and on suspicion,
- short-lived where the platform supports it,
- delivered by a secret manager (not `.env` checked in, not Slack,
  not screenshots).

Treat any leaked secret as compromised. Rotate first, investigate
later.

---

# Cryptographic Discipline

Do not invent cryptography. Use vetted primitives and libraries.

- Hashing passwords: argon2id (preferred) or bcrypt with a strong
  cost factor. Never plain SHA / MD5.
- Symmetric encryption: AEAD (AES-GCM, ChaCha20-Poly1305).
- Asymmetric: ECDSA P-256 / Ed25519 / RSA-2048+.
- Random for security purposes uses CSPRNG (`crypto/rand`,
  `secrets`), never `Math.random()`.
- Compare secrets with constant-time equality.
- Algorithms have versions. Embed the algorithm and version in the
  ciphertext / token so future migrations are possible.

If the design requires an arbitrary cipher mode you cannot name,
the design is wrong. Stop and consult.

---

# Identity Is the New Perimeter

Authentication answers *who*; authorization answers *may they*.
Both must be present for every request that touches non-public
data. Network position MUST NOT substitute for identity.

- Service-to-service: mTLS, signed JWTs, or platform-native
  service identity. Not "trusted IPs."
- User sessions: server-side session store or signed tokens with
  short expiry plus refresh.
- Authorization is centralized and auditable, not scattered across
  controllers.

When a request enters the system, the question "who is this and
what may they do?" must have an answer in the first ten lines of
the handler.

---

# Audit What Matters

Security relies on the ability to reconstruct what happened. Every
sensitive action MUST produce an immutable audit record:

- authentication events (login, logout, failure)
- authorization denials
- privilege grants and changes
- access to sensitive resources (PII, financial)
- configuration / secret rotation
- administrative operations

Audit logs are append-only, separated from application logs, and
retained on a documented schedule. They MUST NOT contain the
sensitive data they describe — only references.

---

# Privacy Is a Design Constraint

Personal data is a liability, not an asset. Collect the minimum,
keep it the minimum time, and protect it accordingly.

- Map every field that is personal data and document its lawful
  basis, retention period, and deletion path.
- Anonymized analytics defaults beat raw user IDs.
- Right-to-deletion paths are part of the schema, not a runbook.
- Cross-border data transfer is a deliberate decision, not an
  accident of which region someone provisioned a bucket in.

If it would be a headline if leaked, design as if it will be.

---

# Supply Chain Is Part of the Application

A dependency is code you ship. Treat it accordingly.

- Pin dependencies (lockfiles in source).
- Verify provenance (signatures, SLSA, signed releases).
- Generate and review SBOMs.
- Patch on a schedule; respond to advisories on detection, not
  on convenience.
- Forbid unrestricted post-install scripts where possible.

A trojan in a transitive dependency runs with your privileges.
Pretend it does, and design to limit the blast radius.

---

# Threat Model Before Architecture

For any system handling money, PII, auth, multi-tenant data, or
externally-exposed surfaces, agents MUST produce a threat model
before architecture is finalized:

- assets (what is worth attacking)
- actors (who might attack)
- entry points and trust boundaries
- abuse cases ("how would I break this?")
- mitigations and residual risk

If the threat model has not been written, the architecture is
incomplete.

---

# Fail Closed

When in doubt, deny. A failed authorization check denies access.
A failed integrity check rejects the message. A failed feature
flag does not silently grant the gated capability.

Open-by-default failure modes turn outages into breaches.

---

# Treat Compliance as a Floor

PCI DSS, GDPR, HIPAA, SOC 2, and similar regimes encode hard-won
lessons. Comply, then exceed where engineering judgement says the
floor is too low. Treat compliance as the minimum acceptable
state, not the goal.

Compliance does not equal security. Security is the goal;
compliance is the audit.

---

# Prime Directive

Build systems that fail safely, expose surface deliberately, and
make the secure path the obvious path. The user who follows the
default must be safe; the developer who copies the example must be
safe; the operator who runs the runbook must be safe.

Security that depends on remembering is no security.
