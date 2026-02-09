# Work State

This document externalizes agent working memory.

Agents MUST update this file during meaningful progress.

Internal session memory is NOT reliable.

This file is the authoritative execution state.

---

# Current Objective

Describe the single active objective.

Only ONE objective should exist at a time.

If priorities change, rewrite this section.

---

# Execution Status

- NOT_STARTED
- IN_PROGRESS
- BLOCKED
- REVIEW_REQUIRED
- COMPLETED

Select one.

---

# Completed Work

List completed steps in chronological order.

Use short, factual entries.

Example:

- Defined repository interfaces
- Implemented aggregate root
- Added transaction boundary

Avoid narrative.

---

# Next Step (MANDATORY)

Describe the next atomic action.

The next agent MUST be able to resume work immediately
without re-analysis.

Bad example:
"Continue implementation"

Good example:
"Implement PostgreSQL repository for Order aggregate"

Be precise.

---

# Decisions Made

Record decisions that affect architecture.

Include brief reasoning.

Example:

Decision:
Use optimistic locking.

Reason:
Reduces contention while preserving consistency.

Do NOT log trivial choices.

---

# Constraints

List active constraints.

Examples:

- Must preserve backward compatibility
- Database schema already deployed
- External API cannot change

Constraints prevent unsafe improvisation.

---

# Open Questions

Document unresolved uncertainties.

Agents MUST escalate rather than guess.

Example:

- Should this aggregate enforce uniqueness,
  or should it be delegated to the database?

Unanswered questions are safer than hidden assumptions.

---

# Risks

List known risks.

Example:

- Potential N+1 query issue
- Migration may lock table

Surfacing risk is a sign of disciplined engineering.

---

# Handoff Notes (CRITICAL)

Write a short note for the next agent.

Assume zero context.

Include:

- where to continue
- what to avoid
- anything fragile

Think of this as a cockpit transfer.

Clarity is safety.

---

# Forbidden Behaviors

Agents MUST NOT:

- erase history
- rewrite completed work
- compress context
- hide uncertainty

Transparency over tidiness.

---

# Prime Directive

Make continuation effortless.

Reduce restart cost to near zero.
