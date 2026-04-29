---
name: aggregate-boundary
description: Confirm aggregate granularity with the instructor before splitting responsibilities. Bias toward fewer, larger aggregates.
---

# Aggregate boundary

DDD is a tool, not an ideology. Over-applied DDD fragments business
reality and creates more damage than it prevents. This skill exists
because the AI default is to over-separate.

Use this skill **before**:

- creating a new aggregate root,
- splitting an existing aggregate,
- introducing a second repository where one might suffice,
- designing a new bounded context boundary.

Source of truth: `ai-agent-core/principles/ARCHITECTURE_PRINCIPLES.md`
(section "Right-Size the Aggregation Unit").

---

## Required protocol

Agents MUST NOT decide aggregate granularity unilaterally. Before
separating, do all three:

1. **Identify** what the business treats as a single unit of work.
2. **Confirm** that unit explicitly with the instructor (the user).
   Quote back what you heard, ask for correction.
3. **Separate only along the confirmed boundary.**

If the instructor cannot articulate the unit, STOP. Resolve the
ambiguity first. Do not code through it.

---

## Bias toward fewer, larger aggregates

When in doubt, err toward a single larger aggregate. Split only
when a *concrete invariant* demands it.

### Symptoms of over-separation (the AI default — resist)

- A single business action cascades across many repositories.
- Cross-aggregate transactions become routine.
- Terms the business treats as "one thing" are fragmented across
  models.
- Changing one concept requires synchronized edits across many
  packages.

### Symptoms of under-separation

- Invariants from unrelated concerns collide inside one aggregate.
- Unrelated business rules share state.
- The aggregate grows unbounded.

Both are failures. Over-separation is the more common default.
Resist it.

---

## Decision script (use verbatim if helpful)

When you need to ask:

> Before I split this, I want to confirm the business unit. Today,
> the business treats X and Y as **one** thing or as **two**? In
> particular, does a single business action ever modify both X and
> Y atomically?

Wait for the answer. Then either keep one aggregate or split, never
both.

---

## After the decision

- Reflect the confirmed boundary into `tasks/todo.md`.
- If `gh` is available, mirror it into the Issue.
- If the boundary will recur as a project rule, capture it via
  skill `capture-lesson` so the next agent does not re-debate it.
