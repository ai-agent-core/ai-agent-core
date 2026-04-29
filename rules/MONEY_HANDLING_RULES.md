# Money Handling Rules

Money is a domain with non-negotiable correctness requirements.
Off-by-one errors, rounding mistakes, and lost transactions cost
real money, real trust, and real legal exposure. These rules
apply to any system that records, computes, or moves monetary
value.

For data principles, see `principles/DATA_PRINCIPLES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Money Has Two Parts: Amount and Currency

A monetary value is **amount AND currency**. Anything that
represents money MUST carry both:

- type / class wrapper: `Money { amount, currency }`,
- DB schema: `amount` column AND `currency` column,
- API payload: `{ amount, currency }`.

Forbidden:

- a bare `decimal` / `int` field representing money,
- assuming a single global currency,
- defaulting currency at any layer below presentation.

If a system supports more than one currency, the currency is
loadbearing. If it supports only one today, it might support more
tomorrow — the design carries the currency anyway.

---

# Amount Representation

Amounts MUST be exact. Never floating-point.

Choose one representation per system and use it consistently:

- **Integer minor units** — store the smallest indivisible unit
  (cents / 銭 / pence). `100.00 USD` → `10000`.
  - Pros: exact, simple arithmetic, fast.
  - Cons: amount-per-unit varies per currency (JPY has 0
    decimal places, BHD has 3); the type alone does not encode
    decimal places.
- **Fixed-point decimal** — language-native decimal type
  (`Decimal`, `BigDecimal`, `NUMERIC(p, s)`).
  - Pros: explicit precision and scale.
  - Cons: requires careful library use; some platforms have
    weak support.

Forbidden:

- IEEE-754 floats / doubles,
- string concatenation arithmetic on monetary strings,
- mixing minor-units and major-units in different layers
  without explicit conversion at the boundary.

A money type is opaque to the rest of the application; arithmetic
goes through the money library, not through `+` on raw fields.

---

# Currency Codes

- ISO 4217 three-letter codes (`USD`, `JPY`, `EUR`, `BHD`).
- Stored in a typed enum or with a `CHECK` constraint, never as
  free text.
- Displayed using locale-appropriate formatting at the
  presentation layer; never persisted as `"$100"` or `"100円"`.
- Decimal places per currency are looked up from a maintained
  table, not hard-coded.

A money library / type knows the decimal places of each
currency. The application does not.

---

# Arithmetic and Rounding

- Operations on money: `add`, `subtract`, `multiply by scalar`,
  `divide by scalar`, `allocate (split with remainders)`,
  `compare`.
- Cross-currency arithmetic is forbidden — convert through an
  exchange operation that is logged with rate and timestamp.
- Rounding mode is **explicit** at every step. Banker's rounding
  (HALF_EVEN) is a common default; HALF_UP for many tax /
  invoicing rules. Pick per business rule and document it.
- Splitting an amount into N parts uses an **allocation**
  algorithm that distributes remainders deterministically (no
  cents lost or invented).

Forbidden:

- silently rounding,
- different rounding rules in different places without a
  documented reason,
- "we'll just round at the end" — rounding error compounds.

---

# Total = Components, Always

The total of a transaction equals the sum of its components.
Every breakdown that the user sees / the system audits MUST
reconcile:

```
sum(line items) + tax + shipping − discounts = total
sum(transactions) over an account = balance
```

Validation invariants run on every write. A drift detection job
runs continuously and alerts on anomalies — silent drift is the
worst failure mode.

Forbidden:

- computing `total` independently of components and storing
  both without reconciliation,
- displaying a total that does not match the breakdown,
- "we'll fix it in reporting."

---

# Idempotency Is Mandatory

Every operation that **causes a financial effect** MUST be
idempotent under retry:

- create payment, capture, refund, void, reverse, transfer,
  charge, payout, credit / debit on a ledger,
- subscription create / update / cancel,
- invoice create / void.

Required:

- caller-supplied `Idempotency-Key`,
- server stores `(key → request hash → response)` for a
  documented retention window,
- replay returns the original response,
- key collisions with a different body return a deterministic
  conflict,
- the idempotency record is written in the same transaction as
  the effect, not before or after.

Forbidden:

- "the network never retries" — yes, it does,
- generating the idempotency key on the server,
- relying on the database's primary-key duplicate to prevent
  double-charges. (Race conditions exist.)

A double-charge is the textbook payment incident; idempotency is
the textbook prevention.

---

# Ledgers Are Append-Only

Account balances and transaction histories are derived from an
append-only ledger of events:

- credits and debits (or amount-with-direction) entries,
- every entry references the cause (order, refund, adjustment),
- balances are computed (or materialized as a view) from the
  entries,
- entries are never updated or deleted; corrections are new
  entries that net to zero with the original.

Forbidden:

- mutating a transaction row to "fix" a value,
- deleting transactions,
- balance columns that are written directly without an entry.

Audit, reconciliation, and dispute resolution all depend on the
ledger being honest.

---

# Double-Entry Where Appropriate

For systems that move money between accounts (internal wallets,
inter-tenant settlements, marketplace flows), double-entry
bookkeeping is the default:

- every entry has matched debits and credits,
- the system as a whole is balanced (sum of all balances per
  asset class is zero, accounting for liabilities and equity),
- discrepancies are alerted, not silently auto-corrected.

The accounting model is a domain decision. Adopt it deliberately.

---

# Provider Boundary

External payment / banking providers (Stripe, Adyen, Braintree,
PayPal, GMO, Stripe Connect, banks) have their own model.

- An anti-corruption layer translates between the provider's
  model and the domain.
- Provider IDs are stored alongside internal IDs; never substitute
  one for the other.
- Provider amounts are converted to / from the domain
  representation at the boundary.
- Provider events (webhooks) are reconciled against internal
  state before being trusted.

Forbidden:

- letting the provider's data shape leak into domain code,
- treating a provider success response as the only proof of
  success — webhooks AND polling AND reconciliation.

See skill `payment-integration`.

---

# Webhooks Are Inputs, Not Truth

Webhook events from a provider are *inputs*, not authoritative
facts:

- verify signature AND timestamp before any processing,
- handle out-of-order delivery and replay,
- treat each event as `(event_id, payload)`; deduplicate by
  event id at the consumer,
- reconcile via daily / hourly snapshot pulls so a missed
  webhook does not silently leave state stale.

Forbidden:

- trusting the webhook body before verifying the signature,
- assuming exactly-once delivery,
- assuming webhooks always arrive (sometimes they do not).

---

# Reconciliation

Daily (or higher cadence) reconciliation between internal state
and external systems is mandatory:

- payments captured on provider vs. payments captured locally,
- payouts received vs. payouts expected,
- balances per account vs. ledger sum,
- bank statements vs. internal expected movements.

Discrepancies open tickets, not silent corrections. Discrepancies
that *do* require correction are made via new ledger entries,
not by editing rows.

---

# Tax, Fees, and Adjustments

- Tax computation is its own concern; pluggable tax engines
  (Avalara / TaxJar / hand-rolled) are integrated through a clear
  interface.
- Tax is computed at the right point in time (order vs. capture
  vs. invoice) per jurisdiction.
- Fees from the provider are reconciled separately from the
  customer-facing amount.
- Adjustments / write-offs / refunds follow the ledger discipline
  above.

Inclusive vs. exclusive tax presentation is locale-dependent;
always store the breakdown so the inclusive / exclusive view can
be derived.

---

# Currencies and Conversion

- Each transaction stores the original currency.
- If presented in a different currency, the conversion rate and
  rate timestamp are stored explicitly.
- Cross-currency totals are computed at a defined moment with a
  defined rate source.
- Holdings in multiple currencies are not silently summed; the
  display either picks a presentation currency or shows
  per-currency balances.

Forbidden:

- "we'll multiply by today's rate when querying" without
  storing the historical rate,
- mixed-currency invariants without an explicit FX strategy.

---

# PCI Scope and Card Data

If the system touches cardholder data, **scope reduction is the
default**:

- never store full PAN unless absolutely required,
- prefer tokenization at the provider; the system holds the
  token, not the card,
- if storing PAN is unavoidable, segregate to a PCI-scoped
  environment with the corresponding controls,
- CVV/CVC is **never** stored,
- fields display masked PAN at most (`**** **** **** 1234`).

PCI DSS is the floor. Reduce scope ruthlessly.

---

# Refunds and Reversals

- Refund is the *reverse* of a successful payment, not the
  *deletion* of one.
- Partial refunds reconcile against the original transaction.
- Refund attempts are themselves idempotent.
- Refunds outside the provider's window go through a manual
  reconciliation path; never silently credit local state without
  matching external action.

---

# Subscriptions and Recurring Billing

- Subscription state machine is explicit: trial / active / past
  due / paused / canceled / expired.
- Renewal events are at-least-once; consumers are idempotent.
- Failed-payment retries follow a documented schedule (dunning).
- Plan changes (upgrade / downgrade) document proration rules
  unambiguously.

---

# Currency Display vs. Storage

- Storage uses canonical form (minor units integer / decimal +
  ISO code).
- Display uses the user's locale and formatting.
- The boundary is explicit; no display-formatted strings ever
  enter the persistence or API contract.

---

# Forbidden Anti-patterns

- Floating-point money.
- Bare `amount` columns without `currency`.
- "Recompute total at read time" without storing the breakdown.
- Mutating ledger entries instead of appending corrections.
- Storing card data unnecessarily.
- Trusting a webhook before verifying the signature.
- Assuming exactly-once delivery.
- Logging full PAN, CVV, full bank account numbers, full IBANs
  where redaction is appropriate.
- "We'll worry about reconciliation when there is a problem."

---

# Prime Directive

Money flows must be auditable from the user-facing total down to
the last entry, and reconcilable to every external system that
participated. The system either knows where every cent came from
and went, or it does not — and "does not" is the failure that
destroys trust.

Money is a domain. Treat it like one.
