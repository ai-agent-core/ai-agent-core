# Authentication Rules

Authentication answers *who is making this request*. Authorization
(*may they?*) is a separate decision that builds on top.

These rules govern the design and operation of authentication —
sessions, tokens, OAuth/OIDC flows, MFA, and password handling.

For the principles behind, see
`principles/SECURITY_PRINCIPLES.md`. For the security rules see
`rules/SECURITY_RULES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Authn vs. Authz Are Separate Concerns

- **Authentication** establishes identity (a verified claim
  about who).
- **Authorization** decides whether that identity may do this
  action on this resource.

Both must run on every non-public request. A valid token is
*not* permission. The presence of authentication does not imply
authorization.

Forbidden:

- treating "logged in" as a permission,
- conflating authn and authz checks in one middleware blob.

---

# Pick a Provider, Not a Protocol

For most systems, **delegate authentication** to a vendor /
identity provider:

- consumer products: Google / Apple / GitHub / Microsoft / LINE
  via OIDC.
- enterprise: SAML / OIDC against the customer's IdP, SCIM for
  provisioning.
- mixed: an identity platform (Auth0, WorkOS, Cognito, Clerk,
  Firebase Auth, Keycloak) that abstracts the providers.

Run your own password store only when there is a real reason
(regulatory, vendor cost at scale, deep customization). The cost
is high: hashing, MFA, account recovery, breach notification, etc.

Forbidden:

- inventing custom protocols,
- "we'll just hash passwords ourselves" without explicit
  ownership of the maintenance burden.

---

# Passwords (When Used)

If passwords ARE stored:

- hash with **argon2id** (preferred) or **bcrypt** with a strong
  cost factor — never plain hash, never SHA / MD5.
- store the algorithm + parameters with the hash so future
  migrations are possible (`$argon2id$v=19$...`).
- never log the password,
- never echo back the password in API responses,
- compare with constant-time equality at the library level.

Password requirements (per NIST SP 800-63B):

- minimum length 8 (preferably 12+),
- support up to ≥64 characters,
- support spaces and full Unicode,
- check against a breach list (HIBP or equivalent),
- forbid the most-common N passwords,
- do not enforce arbitrary composition rules ("must have an
  uppercase letter") — they don't help and frustrate users.

MFA is offered (and required for privileged accounts).

---

# MFA / 2FA

- Strongly preferred: WebAuthn / FIDO2 / passkeys.
- Acceptable: TOTP (RFC 6238) via authenticator app.
- Last resort: SMS OTP — vulnerable to SIM swap, document the
  risk.
- Push-based MFA must be phishing-resistant if used (no plain
  "approve" prompts; require number matching).

Required for any account that:

- has admin / staff privileges,
- can read or write production data,
- can initiate payment flows.

Recovery flows:

- backup codes (hashed at rest, single-use),
- documented identity-verification path that does not weaken the
  primary factor,
- rate-limited.

Forbidden:

- "remember this device" that bypasses MFA forever,
- recovery via email-only password reset for privileged
  accounts.

---

# Sessions

If using server-side sessions:

- session ID is cryptographically random, ≥128 bits entropy,
- stored server-side; the cookie carries only the ID,
- short lifetime with sliding expiry,
- regenerated on privilege change (login, role escalation, MFA
  step-up),
- destroyed server-side on logout (not just cookie removal).

If using stateless tokens (JWTs):

- short-lived access token (minutes), long-lived refresh token
  (days, with revocation),
- refresh tokens are rotated on use,
- revocation list / token introspection MUST exist for
  compromise response,
- JWT signed with strong asymmetric algorithm (`RS256`,
  `ES256`, `EdDSA`) when the verifier is not the issuer; HS256
  only when issuer == verifier,
- `alg: none` is forbidden,
- audience (`aud`), issuer (`iss`), expiry (`exp`), not-before
  (`nbf`) are validated,
- key rotation is supported (`kid` header).

Token claims contain identity and not authorization decisions
unless the authorization is checked at the verification point.

---

# Cookies

- `Secure`, `HttpOnly`, `SameSite=Lax` (or `Strict` for
  privileged flows).
- `__Host-` prefix where applicable (no Domain attribute, Secure,
  Path=/).
- Short lifetime; rotate on privilege change.
- Never put secrets / personal data in cookie values; cookies
  carry an opaque session ID or signed token.

---

# OAuth 2.0 / OIDC

Use the right flow for the client:

- **Authorization Code with PKCE** — web apps, mobile apps,
  SPAs (PKCE is mandatory for any public client).
- **Client Credentials** — service-to-service.
- **Resource Owner Password Credentials** — forbidden for new
  builds.
- **Implicit** — forbidden for new builds.
- **Device Code** — TVs, CLI, IoT.

Required:

- redirect URIs allowlisted exactly,
- `state` parameter (CSRF defense) is generated, stored, and
  validated,
- `nonce` validated for OIDC,
- ID token signature verified against the IdP's keys,
- access tokens scoped to the minimum required.

Forbidden:

- redirect URI matches "starts with",
- accepting tokens from any issuer ("we trust any signed JWT"),
- skipping signature verification because "we trust the source."

---

# Account Lifecycle

- **Sign-up**: email / phone verification before granting
  capabilities; CAPTCHA / risk score for abuse-prone flows.
- **Email change**: verify the new address; notify the old
  address; cool-down period for sensitive operations.
- **Password change / reset**: reset tokens are single-use,
  short-lived, bound to the account, delivered out of band.
- **Account deletion**: documented retention; right-to-deletion
  paths; tombstone / anonymization for audit trails.
- **Account recovery**: identity-proof process is
  rate-limited, logged, and reviewed for abuse.

Forbidden:

- account enumeration (different responses for "wrong password"
  vs. "user does not exist"),
- password reset that does not invalidate active sessions for
  the affected account.

---

# Brute Force and Credential Stuffing

- Per-account and per-IP rate limits with progressive delays.
- Detect credential stuffing (high failure rate across many
  accounts from one source) and block.
- Lockout policies that resist DoS-by-lockout (CAPTCHA / risk
  score over hard lockout).
- Monitoring on auth-failure spikes and geographic outliers.

---

# Privileged Access

For staff / admin / on-call accounts:

- separate identity (different account from personal customer
  account),
- MFA mandatory,
- short-lived role elevation (just-in-time) preferred over
  permanent admin,
- session timeout shorter than for regular users,
- audited usage,
- production access through bastion / SSO with MFA, not direct
  SSH / direct DB connections from random hosts.

Forbidden:

- shared admin accounts,
- a "root" account that everyone uses.

---

# Service-to-Service Authentication

- mTLS, signed JWTs, or platform-native service identity (IAM
  roles, workload identity, SPIFFE).
- Tokens scoped to a single audience.
- Tokens short-lived; long-lived shared secrets are forbidden
  for new builds.
- Network position is *not* identity.

A request inside the VPC is not authenticated by being inside
the VPC.

---

# Webhook Verification

Webhooks the system receives:

- shared secret per partner / integration, scoped narrowly,
- HMAC over body and timestamp,
- timestamp window enforced (replay protection, e.g. 5 minutes),
- signature verified before any processing,
- handler is idempotent on the event identity.

Webhooks the system sends:

- signing secret per consumer,
- documented verification scheme for receivers,
- rotation procedure,
- retry behavior documented.

---

# Audit and Forensics

Authentication events MUST be logged:

- successful login (user, time, IP, user-agent, factor),
- failed login (with rate limit on emitted detail to avoid
  enumeration),
- MFA enrollment / removal,
- password change,
- session creation / destruction,
- privilege elevation,
- account recovery initiation and completion.

Logs are append-only and stored separately from application
logs. They MUST NOT contain secrets, tokens, or password values.

---

# Forbidden Anti-patterns

- "Remember me" tokens that grant full session capabilities
  forever.
- IP allowlist as the only authentication.
- Magic-link / OTP without rate limit and expiration.
- Tokens in URLs (logged everywhere, leaked via referer).
- Long-lived JWTs that cannot be revoked.
- Admin login without MFA.
- Passwords sent via email in plain text.
- Sharing service account credentials between developers.
- Accepting unsigned JWTs.
- Custom-rolled crypto (HMAC done by hand, comparison without
  constant-time).

---

# Prime Directive

Authentication is the front door of the system. Make it strong by
default, observable when used, and impossible to bypass through
"interesting" alternative paths. Delegate to vendors with the
expertise where the cost-benefit favors it.

A breach of authentication is a breach of everything that
authentication was protecting.
