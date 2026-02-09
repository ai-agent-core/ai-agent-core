# Naming Rules

Consistent naming is REQUIRED across all projects.

Names define intent.
Intent defines architecture.

Agents MUST follow these conventions.

---

# Core Principles

Names MUST be:

- explicit
- unambiguous
- domain-oriented
- consistent

Avoid clever or decorative naming.

Clarity always wins.

---

# Ubiquitous Language

All names MUST align with the domain language.

Agents MUST NOT invent synonyms.

Example:

If the domain says `Order`,
DO NOT introduce:

- Purchase
- Request
- Ticket

One concept → One name.

---

# Aggregate Roots

Aggregate roots MUST use singular nouns.

Correct:

- Order
- Customer
- Invoice

Forbidden:

- OrderEntity
- CustomerModel
- InvoiceRecord

Domain objects are not persistence models.

---

# Repository

Repositories MUST follow:

<AggregateName>Repository


Examples:

- OrderRepository
- CustomerRepository

Forbidden:

- OrderDAO
- OrderService
- OrderManager

A repository is a collection abstraction.
Name it accordingly.

---

# Application Services

Application services MUST end with:

UseCase


Examples:

- CreateOrderUseCase
- CancelOrderUseCase

Avoid vague suffixes:

Forbidden:

- Processor
- Manager
- Handler

Behavior must be obvious from the name.

---

# Domain Services

Domain services MUST end with:

DomainService


Example:

- PricingDomainService

Use only when behavior does not naturally belong to an entity.

Do NOT create services prematurely.

---

# Persistence Models

Persistence models MUST be clearly marked.

Recommended suffixes:

- JpaModel
- DbModel
- Record
- Table

Forbidden:

- Entity

Avoid confusion with domain entities.

---

# Data Transfer Objects

DTOs MUST be explicitly labeled.

Recommended:

- OrderResponse
- CreateOrderRequest
- OrderSummary

Forbidden:

- OrderDTO (too generic)

The name must reveal intent.

---

# Interfaces vs Implementations

Interfaces MUST remain neutral.

Example:

OrderRepository


Implementations MUST reveal the technology.

Examples:

- JpaOrderRepository
- PostgresOrderRepository

Technology belongs at the edge.

---

# Boolean Naming

Boolean variables MUST read naturally.

Preferred:

- isPaid
- hasAccess
- canCancel

Avoid:

- flag
- status
- value

Names should answer yes/no questions.

---

# Method Naming

Methods MUST describe behavior.

Preferred:

- cancelOrder()
- calculateTotal()

Avoid generic verbs:

- process()
- handle()
- execute()

Specificity improves readability.

---

# Avoid Technical Leakage

Domain names MUST NOT expose technical concerns.

Forbidden examples:

- OrderDTO inside domain
- PaymentEntity inside domain

The domain speaks business language only.

---

# Length Guidelines

Names SHOULD be long enough to be clear,
but short enough to remain readable.

Prefer clarity over brevity.

---

# Consistency Over Perfection

If a naming pattern already exists,
follow it.

Do NOT introduce stylistic variation.

Consistency reduces cognitive load.

---

# Core Directive

If a name requires explanation,
it is a bad name.