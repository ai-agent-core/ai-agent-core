---
name: payment-integration
description: Integrate a payment provider correctly — idempotency, webhooks, ledger discipline, reconciliation, PCI scope reduction.
---

# Payment integration

Use this skill **whenever a payment provider is being integrated,
extended, or replaced** (Stripe, Adyen, Braintree, PayPal, GMO,
Pay.JP, Square, banks via direct rails, etc.).

Authoritative source: `rules/MONEY_HANDLING_RULES.md` and
`principles/SECURITY_PRINCIPLES.md`.

Mistakes here cost real money, real chargebacks, and real legal
exposure. Follow this skill end-to-end.

---

## Premise

Build the integration as if every webhook will be duplicated,
every API call will be retried, and the provider will go down
during your highest-revenue minute. Because all three will
happen.

---

## Step 1 — Choose the integration model

| Model                      | When                                                 |
| -------------------------- | ---------------------------------------------------- |
| Provider-hosted checkout   | Lowest PCI scope, fastest. Default.                  |
| Direct API + tokenization  | More UX control, still SAQ-A or SAQ-A-EP scope.      |
| Custom card form (in-frame)| Significantly more PCI burden; rare for new builds.  |
| Direct card storage        | Forbidden unless there is no other option and PCI    |
|                            | scope is owned and audited.                          |

Default to provider-hosted or token-only flows. **Reduce PCI
scope ruthlessly.**

---

## Step 2 — Reduce PCI scope

- Never store full PAN unless absolutely required.
- CVV / CVC is **never** stored. Period.
- Use the provider's tokenization (Stripe `pm_*`, Adyen recurring
  reference, etc.); the system holds the token, not the card.
- Display masked PAN at most (`**** **** **** 1234`).
- Card form fields enter via the provider's iframe / SDK; they
  do not transit the application's network.

If storing PAN is unavoidable, segregate to a PCI-scoped
environment with the corresponding controls — and reconsider the
design first.

---

## Step 3 — Idempotency on every effect

Every operation that causes a financial effect MUST be
idempotent under retry:

- **create payment intent / authorize / capture / refund / void**
  — pass an `Idempotency-Key` to the provider AND store one
  internally,
- internal idempotency: `(idempotency_key → request_hash →
  response)` table, written in the **same transaction** as the
  effect,
- replays return the original outcome,
- key collisions with a different body return a deterministic
  conflict.

Forbidden:

- assuming the network will not retry,
- generating idempotency keys server-side after receiving the
  request (the client must own the key),
- relying on a unique-constraint race-loss as the dedupe.

The textbook payment incident is the double-charge. Idempotency is
the textbook prevention.

---

## Step 4 — Webhooks: verify, dedupe, reconcile

Webhooks are inputs, not truth.

Verification:

- HMAC signature over body and timestamp,
- timestamp window enforced (replay protection, e.g. 5 min),
- signature verified before any processing.

Deduplication:

- store `(provider_event_id)` with a unique constraint,
- on receipt: insert; if duplicate, return success without
  re-processing.

Ordering:

- assume out-of-order delivery; do not require monotonicity,
- when state machines disallow a transition, log and ignore
  rather than fail.

Reconciliation:

- daily (or hourly) snapshot pull from the provider,
- compare provider state with internal state,
- discrepancies open tickets, never silent corrections.

Missing a webhook is a normal occurrence. The system must not
depend on every webhook arriving.

---

## Step 5 — State machine

Model payment state explicitly:

```
created → requires_payment_method → requires_confirmation
       → requires_action → processing → succeeded
                                      → failed
                                      → canceled
```

(or whatever the provider's model is — encode it locally so the
domain knows it).

- transitions are validated server-side,
- terminal states are immutable except for refunds (which are
  modelled as new transactions, not state changes),
- timeouts (auth aged out, capture window expired) are explicit
  jobs, not implicit.

---

## Step 6 — Ledger discipline

Append-only ledger of money movements:

- entries reference the cause (order, refund, fee, payout,
  adjustment),
- balances are derived from entries (or materialized views),
- corrections are *new entries that net to zero with the
  original*, never edits.

Double-entry where the system moves money between internal
accounts (marketplace, wallet, settlement).

See `rules/MONEY_HANDLING_RULES.md` for the full set of rules.

---

## Step 7 — Reconciliation

Daily reconciliation against the provider:

- payments captured (provider) vs. payments captured (internal),
- payouts received vs. expected,
- fees reconciled separately from customer-facing amounts,
- balances per account vs. ledger sum.

Discrepancies open tickets. Discrepancies that need correction
are made via new ledger entries.

A payment integration without reconciliation is a slow leak.

---

## Step 8 — Refunds and disputes

- Refund is the *reverse* of a successful payment, not the
  *deletion* of one.
- Refunds are themselves idempotent.
- Partial refunds reconcile against the original.
- Refunds outside the provider's window go through manual
  reconciliation.
- Disputes / chargebacks are received via webhook, modelled as
  ledger entries, and reflected in dashboards. Dispute deadlines
  are tracked; missed deadlines lose money.

---

## Step 9 — 3-D Secure / SCA

- For European payments, 3DS / SCA is the default unless
  explicitly exempted.
- The flow has multiple round-trips with redirect / iframe steps;
  handle them in the state machine.
- For low-risk flows, exemptions (TRA, low-value) may apply but
  must be documented.

---

## Step 10 — Subscriptions and recurring billing

- Subscription state machine: trial / active / past_due / paused /
  canceled / expired.
- Renewal events are at-least-once; consumers idempotent.
- Failed-payment retries follow a documented dunning schedule.
- Plan changes (upgrade / downgrade) document proration rules
  unambiguously.
- Cancellation is honored at the documented effective date; do
  not double-charge after cancellation.

---

## Step 11 — Multi-currency

- Each transaction stores its original currency.
- If presented in another currency, store rate and rate
  timestamp.
- Cross-currency totals are computed at a defined moment with a
  defined rate source.
- Provider settlement currency may differ from buyer currency;
  reconciliation must align.

---

## Step 12 — Testing

- The provider's test mode is the default in development and
  staging.
- Test webhook handlers with the provider's CLI / dashboard event
  sender.
- Integration tests cover:
  - happy path,
  - duplicate webhook,
  - out-of-order webhook,
  - webhook signature failure,
  - replay (timestamp out of window),
  - retry of a payment intent (idempotency),
  - refund (full and partial),
  - dispute / chargeback,
  - 3DS challenge.
- Load test the webhook receiver — providers can fire bursts.

Forbidden:

- mocking the provider so deeply tests verify nothing about
  delivery semantics,
- testing only the happy path.

---

## Step 13 — Observability

- per-provider RED metrics (rate, errors, duration),
- payment success rate per provider / per method / per region,
- webhook lag (time between provider event timestamp and local
  processing),
- chargeback rate,
- alerts on burn rate of payment success rate against SLO.

A payment failure spike must be visible within minutes.

---

## Forbidden

- Storing CVV / CVC.
- Bare floats for money.
- Currency assumed to be a global default.
- Trusting webhook bodies without signature verification.
- Relying on the provider's success response as the only source
  of truth.
- Deleting or editing ledger entries.
- "We'll worry about reconciliation when there is a problem."
- Custom-rolled crypto for webhook verification.

---

## When this skill says STOP

- The provider's idempotency / webhook story is unclear → ask
  the user; do not guess.
- The team has no PCI compliance plan and the design touches
  card data → escalate.
- Dispute / chargeback handling is undefined → finalize before
  shipping.

Money flows must be auditable from the user-facing total down to
the last entry, and reconcilable to the provider. Anything else
is a slow loss the team will discover later in a chargeback
report.

Build the integration to survive the bad day.
