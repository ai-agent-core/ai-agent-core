---
name: authentication
description: Design or extend authentication — sessions, tokens, OAuth/OIDC flows, MFA, password handling, account lifecycle, with secure defaults.
---

# Authentication

Use this skill **whenever an authentication flow is being designed
or changed** — sign-up, login, password handling, MFA, OAuth /
OIDC integration, session management, service-to-service auth.

Authoritative source: `rules/AUTHENTICATION_RULES.md` and
`principles/SECURITY_PRINCIPLES.md`.

---

## Step 0 — Decide: vendor or build?

For most systems, **delegate authentication to a vendor / IdP**:

- consumer products: Google / Apple / GitHub / LINE / Microsoft
  via OIDC,
- enterprise: customer's IdP via SAML / OIDC + SCIM,
- mixed: identity platform (Auth0, WorkOS, Cognito, Clerk,
  Firebase Auth, Keycloak) abstracting the providers.

Run your own password store only when the cost-benefit favors it.
Password reset, MFA, breach response, account recovery — each is
a non-trivial system.

If building in-house, write an ADR (skill `adr`) acknowledging
the maintenance burden.

---

## Step 1 — Separate authn and authz

- **authn** establishes identity,
- **authz** decides whether that identity may do this action on
  this resource.

Both run on every non-public request. Treat them as distinct
checks; "logged in" is not permission.

---

## Step 2 — Passwords (if used)

If passwords ARE stored:

- hash with **argon2id** (preferred) or **bcrypt** with a strong
  cost factor — never plain hash, never SHA / MD5,
- store algorithm + parameters with the hash (`$argon2id$v=19$…`),
- never log the password,
- never echo back in API responses,
- constant-time comparison (use the library API, not raw
  equality).

Password requirements (per NIST SP 800-63B):

- minimum length 8 (preferably 12+),
- support up to ≥64 characters,
- support spaces and full Unicode,
- check against a breach list (HIBP or equivalent),
- forbid the most-common N passwords,
- do not enforce arbitrary composition rules ("must have an
  uppercase letter") — they harm UX without improving security.

Offer MFA. Require it for privileged accounts.

---

## Step 3 — MFA / 2FA

Strongly preferred:

- **WebAuthn / FIDO2 / passkeys** (phishing-resistant).

Acceptable:

- **TOTP** via authenticator app (RFC 6238).

Last resort:

- **SMS OTP** — vulnerable to SIM swap; document the risk.

Push-based MFA must be phishing-resistant if used (number
matching, not plain "approve").

Required for accounts that:

- have admin / staff privileges,
- can read or write production data,
- can initiate payment flows.

Recovery flows:

- backup codes (hashed at rest, single-use),
- documented identity-verification path that does not weaken the
  primary factor,
- rate-limited.

Forbidden:

- "remember this device" that bypasses MFA forever,
- email-only password reset for privileged accounts.

---

## Step 4 — Sessions

### Server-side sessions

- session ID cryptographically random (≥128 bits entropy),
- stored server-side; cookie carries only the ID,
- short lifetime with sliding expiry,
- regenerated on privilege change (login, role escalation, MFA
  step-up),
- destroyed server-side on logout.

### Stateless tokens (JWTs)

- short-lived access token (minutes), long-lived refresh
  (with revocation),
- refresh tokens rotated on use,
- revocation list / introspection MUST exist for compromise
  response,
- signed with strong asymmetric algorithm (`RS256`, `ES256`,
  `EdDSA`) when verifier ≠ issuer; `HS256` only when issuer ==
  verifier,
- `alg: none` and weak algorithms forbidden,
- `aud`, `iss`, `exp`, `nbf` validated on every verification,
- `kid` header used; key rotation supported.

Claims contain identity, not authorization decisions, unless the
authz check happens at the verification point.

---

## Step 5 — Cookies

- `Secure`, `HttpOnly`, `SameSite=Lax` (or `Strict` for
  privileged flows),
- `__Host-` prefix where applicable,
- short lifetime; rotate on privilege change,
- never put secrets / personal data in cookie values; cookies
  carry an opaque session ID or signed token.

---

## Step 6 — OAuth 2.0 / OIDC

Pick the right flow for the client:

- **Authorization Code with PKCE** — web, mobile, SPA (PKCE
  mandatory for public clients),
- **Client Credentials** — service-to-service,
- **Resource Owner Password Credentials** — forbidden for new
  builds,
- **Implicit** — forbidden for new builds,
- **Device Code** — TVs, CLI, IoT.

Required:

- redirect URIs allowlisted **exactly** (not "starts with"),
- `state` (CSRF defense) generated, stored, validated,
- `nonce` validated for OIDC,
- ID token signature verified against the IdP's keys,
- access tokens scoped to minimum needed.

Forbidden:

- accepting tokens from any issuer,
- skipping signature verification because "we trust the source,"
- "starts with" redirect URI matching.

---

## Step 7 — Account lifecycle

- **Sign-up**: email / phone verification before granting
  capabilities; CAPTCHA / risk score for abuse-prone flows.
- **Email change**: verify new address; notify old; cool-down for
  sensitive operations.
- **Password change / reset**: tokens single-use, short-lived,
  bound to the account, delivered out of band; password change
  invalidates active sessions.
- **Account deletion**: documented retention; right-to-deletion
  paths; tombstone / anonymization for audit.
- **Account recovery**: identity-proof process is rate-limited,
  logged, reviewed.

Forbidden:

- account enumeration (different responses for "wrong password"
  vs. "user does not exist"),
- password reset that does not invalidate active sessions for
  the account.

---

## Step 8 — Brute force / credential stuffing

- per-account and per-IP rate limits with progressive delays,
- detect credential stuffing (high failure rate across many
  accounts from one source),
- lockout policies that resist DoS-by-lockout (CAPTCHA / risk
  score over hard lockout),
- monitoring on auth-failure spikes and geographic outliers.

---

## Step 9 — Privileged / staff access

- separate identity from personal customer account,
- MFA mandatory,
- short-lived role elevation (just-in-time) over permanent admin,
- shorter session timeout,
- audited usage,
- production access through bastion / SSO with MFA.

Forbidden:

- shared admin accounts,
- a "root" account everyone uses.

---

## Step 10 — Service-to-service

- mTLS, signed JWTs, or platform-native service identity (IAM
  roles, workload identity, SPIFFE),
- tokens scoped to a single audience,
- short-lived; long-lived shared secrets are forbidden for new
  builds,
- network position is **not** identity.

---

## Step 11 — Audit

Authentication events logged:

- successful login (user, time, IP, user-agent, factor),
- failed login (rate-limit emitted detail to avoid enumeration),
- MFA enrollment / removal,
- password change,
- session creation / destruction,
- privilege elevation,
- account recovery initiation and completion.

Logs are append-only and stored separately from application logs.
They do not contain secrets, tokens, or password values.

---

## Step 12 — Verify

Before declaring the auth design done:

- attempt to authenticate with an unsigned token → rejected,
- attempt with `alg: none` JWT → rejected,
- attempt with expired token → rejected,
- attempt to take over an account via password reset without
  the email link → fails,
- attempt cross-site request to mutating endpoint → fails (CSRF
  defense works),
- review audit logs for the test session — every event is there
  with no PII at the wrong level.

---

## Forbidden

- "Remember me" tokens that grant full session capabilities
  forever,
- IP allowlist as the only authentication,
- magic-link / OTP without rate limit and expiration,
- tokens in URLs,
- long-lived JWTs that cannot be revoked,
- admin login without MFA,
- passwords sent via email in plain text,
- sharing service-account credentials between developers,
- accepting unsigned JWTs,
- custom-rolled crypto.

---

## When this skill says STOP

- a password store is being built without a documented owner →
  reconsider; delegate to a vendor,
- an OAuth flow is being designed with a "starts with" redirect
  match → fix immediately,
- privileged accounts ship without MFA → block.

Authentication is the front door of the system. Make it strong by
default, observable when used, and impossible to bypass through
"interesting" alternative paths.

A breach of authentication is a breach of everything it was
protecting.
