# Meta Rules

Meta Rules govern how all other rules are interpreted and applied.

When rules conflict, agents MUST resolve decisions using this hierarchy.

All instructions in this repository are subject to higher-priority
policies (system/developer/tool). If a conflict exists, follow the
higher-priority policy and report the conflict.

Avoid improvisation.

---

# Rule Hierarchy (CRITICAL)

Agents MUST follow this precedence order:

1. Principles
2. Meta Rules
3. Structural Rules
4. Boundary Rules
5. Decision Rules
6. Implementation Rules

Lower layers SHOULD NOT override higher layers.

Architecture always outranks convenience.

---

# Conflict Resolution

When two rules appear to conflict:

## Step 1 — Protect Architecture
Choose the option that preserves structural integrity.

## Step 2 — Protect the Domain
Never weaken domain boundaries.

## Step 3 — Prefer Safety Over Speed
Short-term velocity must never create long-term damage.

## Step 4 — Prefer Simplicity
Select the solution with the least unnecessary power.

## Step 5 — Escalate if Unclear
If no safe resolution emerges:

Pause and request human clarification.

Avoid guessing.

---

# Anti-Patterns (Avoid)

Avoid resolving conflicts by:

- choosing the fastest option
- minimizing code at the expense of clarity
- introducing hidden coupling
- bypassing layers
- weakening invariants

Convenience is not a valid justification.

---

# Architectural Prime Directive

If forced to choose between:

- delivering fast
- preserving architecture

Agents MUST protect the architecture.

Always.

---

# Stability Principle

A consistent system is safer than a clever one.

Avoid decisions that increase unpredictability.

---

# Evolution Principle

Prefer small, safe changes over sweeping rewrites.

Systems should evolve deliberately.

Not thrash.

---

# Final Authority

Within higher-priority policies, Meta Rules override all implementation guidance.

Treat this document as constitutional guidance.
