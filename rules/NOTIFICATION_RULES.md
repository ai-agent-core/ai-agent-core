# Notification Rules

Outbound notifications — transactional email, in-app messages,
SMS, push, webhooks — are part of the user-visible surface and
of the system's operational footprint. These rules govern how
they are designed, sent, and recovered from.

For the default mailer choice, see
`rules/STACK_DEFAULTS_RULES.md` (Resend on the Cloudflare path).
For event semantics, see `rules/EVENT_RULES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Channels

| Channel             | When                                                  |
| ------------------- | ----------------------------------------------------- |
| Transactional email | Account events, receipts, password resets, magic links, alerts |
| Marketing email     | Newsletters, promos — **separated** from transactional sender |
| In-app notification | Real-time UX feedback inside the product              |
| Push                | Mobile / web push when the user opted in              |
| SMS                 | High-stakes only (2FA, security alerts) — costly and abusable |
| Webhook (outbound)  | Notifying integrators / partners of business events   |

A given event MUST pick one or more channels deliberately, with
explicit reasoning. "Email everyone for everything" is the
canonical default that creates noise, opt-outs, and spam folders.

---

# Default mailer (Cloudflare path)

**Resend** is the default for transactional email:

- SDK: `resend` / HTTP API; works inside Cloudflare Workers.
- Sender authentication via SPF + DKIM + DMARC (records managed
  in Cloudflare DNS via IaC).
- Domain authentication enforced — no shared / open relay.
- Bounce / complaint webhooks consumed and recorded.
- Suppression list maintained (no manual edits in the vendor UI).

Choosing AWS SES / SendGrid / Postmark / Mailgun instead is a
deliberate, written decision (skill `adr`) — typically driven by
contractual terms or an existing tenant.

---

# Sender hygiene

- Transactional and marketing senders are **different**:
  - Transactional: `noreply@<apex>` or
    `<event>@<apex>`,
  - Marketing: `news@<sub>.<apex>` (subdomain segregation
    isolates reputation).
- DMARC alignment is `reject` (or at minimum `quarantine`) once
  legitimate sending is verified.
- All outbound mail goes through the authenticated sender. Free
  Gmail / personal SMTP for production mail is forbidden.
- Bounce / complaint feedback is processed automatically — a
  bouncing address is suppressed before the next send.

---

# Templates

- Templates are **source-controlled** alongside the application
  (`templates/email/<event>.{html,mjml,txt}`), not maintained in
  the vendor UI.
- One template per business event. Reusable layouts (header /
  footer / button) live in shared partials.
- Templates render server-side; the rendered output is logged
  with the recipient's hashed identifier, never the raw email
  body.
- Plain-text alternative is always shipped alongside HTML.
- `unsubscribe` and physical address footer where required by
  jurisdiction.
- Locale handling: per-user locale; fall back to project default
  (BCP-47).

---

# Idempotency and replay

Sending a notification more than once for the same business
event is the canonical failure mode (double-charge receipts,
duplicate alerts).

Required:

- Every send is keyed on a domain idempotency key (often the
  event ID + channel).
- Send state stored in the same transaction as the cause:
  `notification_outbox(idempotency_key, channel, recipient,
  status, sent_at, …)` with a unique constraint.
- Replays of the same key return the original outcome, not a
  re-send.
- Retries are bounded with exponential backoff and a DLQ.

See skill `event-driven` and `rules/EVENT_RULES.md` (outbox
pattern).

---

# Webhooks (outbound)

For events the system delivers to integrators:

- Signed body (HMAC over body + timestamp).
- `X-Signature-Timestamp` for replay protection (5-minute
  window typical).
- Per-consumer signing secret; rotation procedure documented.
- At-least-once delivery, with documented retry schedule and
  DLQ.
- Each event carries a stable `event_id` so consumers can
  deduplicate.
- Public schema versioning — adding fields is non-breaking;
  removing or retyping is breaking and ships as `/v2` or new
  event type.

See `rules/API_DESIGN_RULES.md` (webhook section).

---

# In-app notifications

- Backed by an explicit table; not transient UI state.
- Read / unread state per user.
- Server-pushed via WebSocket / SSE / polling per the budget.
- Truncated to a documented retention window; older items are
  archived or deleted.

---

# SMS

- Used only for high-stakes flows (2FA, security alerts).
- Per-recipient rate limits to prevent toll-fraud abuse
  (international destinations).
- Country allowlist by default; expand deliberately.
- SIM-swap risk acknowledged; SMS is a fallback factor, not the
  preferred MFA factor (see `rules/AUTHENTICATION_RULES.md`).

---

# Privacy and PII

- Recipients' addresses (email / phone) are PII and follow
  `principles/SECURITY_PRINCIPLES.md`.
- Never log full email content with PII at INFO level.
- Subject lines that reveal sensitive content
  ("Your bank balance") are forbidden.
- Right-to-deletion includes purging from suppression lists at
  the appropriate time and from the notification outbox per
  retention policy.

---

# Observability

- Per-channel send rate, success rate, bounce rate, complaint
  rate.
- Per-template render error rate.
- Per-event time-to-deliver SLO (e.g. password reset email
  arrives within 60 seconds p95).
- Alerts on bounce-rate spike, complaint-rate spike, vendor 5xx
  burst.
- Vendor outage runbook — fall back to a secondary provider for
  high-stakes flows (auth) where SLA warrants.

---

# Test discipline

- Unit tests assert template rendering for representative
  payloads.
- Integration tests verify the outbox row is written
  transactionally and the send is dispatched once.
- E2E tests use the vendor's sandbox / test mode; never the
  production sender.
- Snapshot the rendered HTML where templates are stable enough
  to make snapshot tests valuable.

---

# Forbidden anti-patterns

- "We'll add email later" — outbox-pattern shape is decided at
  schema-design time, not retrofitted.
- Sending from a developer's personal address.
- Leaking PII into subject lines, log messages, or third-party
  analytics.
- Storing the full sent body indefinitely (store the rendered
  artifact reference, not the body, when feasible).
- Marketing email from the same sender domain as transactional.
- Per-event ad-hoc HTML inlined in business code.
- Webhooks delivered without signature.

---

# Prime Directive

Notifications are commitments to the user. They must arrive
exactly when expected, exactly once per business event, exactly
where the user agreed to receive them — and never reveal more
than they should.

A duplicated receipt is a support ticket. A missing password
reset is a churned user. Treat the outbox like the ledger it
is.
