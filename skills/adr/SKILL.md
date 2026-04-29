---
name: adr
description: Write an Architecture Decision Record. Capture context, options, decision, and consequences in a one-page document committed alongside the code.
---

# ADR — Architecture Decision Record

Use this skill **whenever a non-trivial decision is being made** —
a one-way door, a vendor / technology choice, a topology, a
public API contract, a multi-tenancy model. Anything you might
need to explain in a year.

Authoritative source: `rules/DECISION_RULES.md`.

A decision that is not written down was not made; it was guessed.

---

## When an ADR is required

- One-way doors (hard to reverse, large blast radius).
- Decisions that bind multiple teams / services.
- Vendor / technology choices that lock in capability.
- Significant architectural patterns (CQRS / event sourcing /
  saga / multi-tenancy strategy).
- Public API shape decisions.
- Compliance / regulatory choices that shape the system.

When NOT required:

- Internal renames, formatting choices, library version bumps,
  routine implementation tactics.
- Reversible two-way-door decisions.
- Decisions already made by an existing ADR (link, do not
  duplicate).

---

## Format

ADRs are short — one page is the target, two pages is the
ceiling. They are markdown, numbered sequentially, in
`docs/adr/`.

Filename: `NNNN-short-title.md` (zero-padded, kebab-case).

Required structure:

```markdown
# NNNN. Short title

- **Status:** proposed | accepted | superseded by ADR-XXX
- **Date:** YYYY-MM-DD
- **Authors:** name <handle>, name <handle>
- **Reviewers:** name <handle>

## Context

What problem are we solving? Why now? What constraints apply
(business, regulatory, technical, team capability, deadline)?
What did we already try, if anything?

Two short paragraphs. The reader should be able to recreate the
problem space without context from elsewhere.

## Options considered

For each realistic option (at least two; usually three):

### Option A — short name
- summary,
- pros,
- cons,
- cost (implementation, runtime, operational, security,
  reversibility, team-knowledge),
- examples / prior art if relevant.

### Option B — short name
…

### Option C — do nothing / status quo
Always include. Many ADRs are correctly resolved by "we keep what
we have."

## Decision

We choose **Option X** because **Y**.

State the decision crisply. Bold the choice. Make the reasoning
visible — the *why* matters more than the *what* in five years.

## Consequences

What becomes true because of this decision?

- positive consequences,
- negative consequences (yes, list them — they are real),
- what becomes harder,
- what becomes easier,
- what we are committing to maintain,
- what we lose option-value on.

## Alternatives left open

What we deliberately did **not** decide. What is reversible if
the constraints change. The conditions under which this ADR
should be revisited.

## References

- links to specs, docs, prior incidents, prior ADRs,
- links to vendor docs / RFCs.
```

---

## Status lifecycle

- **Proposed** — under review, not yet binding.
- **Accepted** — the team operates by this decision.
- **Superseded by ADR-XXX** — replaced; the link is mandatory.

ADRs are immutable once accepted. Corrections come as a new ADR
that supersedes the old. The chain of ADRs preserves the
historical reasoning.

---

## How to write a good ADR

- **Lead with the problem, not the solution.** A reader who
  disagrees with the chosen option should still find the
  context fair.
- **Be honest about cost.** A pros-only writeup looks like a
  sales document; future-you will not trust it.
- **Include the do-nothing option.** Many decisions are
  correctly resolved by "we keep what we have."
- **Name the trade-off the team is accepting.** Not "this is
  perfect" — "this gives us X at the cost of Y, which we judge
  acceptable because Z."
- **Cite measurements.** When numbers exist, use them. When they
  do not, say so and document the assumption.
- **Keep it short.** A one-page ADR that gets read beats a
  ten-page one that rots.
- **Write for the engineer in two years**, not for today's
  meeting attendees.

---

## How to read existing ADRs

Before proposing a new architecture / pattern / vendor:

- search the ADR directory for prior decisions in the same area,
- if a prior ADR applies and is still valid, cite it,
- if a prior ADR no longer applies, write a new ADR that
  supersedes it (do not silently re-decide).

A new pattern that contradicts an unsuperseded ADR is either:

- an oversight (cite it correctly), or
- a new ADR (write it).

---

## When to revisit

Re-open an ADR when one of the inputs changes:

- the constraint set changed (new regulation, new SLA, new
  principal),
- evidence changed (we measured and the assumption did not
  hold),
- cost changed (an order-of-magnitude change in load, scale,
  price),
- team capability changed (the option that required expertise
  we did not have, we now have).

Do **not** revisit because someone new joined and prefers the
alternative. Personal preference is not a constraint.

---

## Anti-patterns to avoid

- ADRs that read like sales documents (every section pushes one
  option).
- ADRs that are written *after* the implementation, retrofitting
  reasoning.
- ADRs without a "do nothing" option.
- ADRs that quietly soften a decision the team did not really
  agree on (use proposed → discuss → accept, do not pre-accept).
- ADRs that cite no constraints — every decision is constrained;
  surface the constraints.
- "We will choose later" — that is the absence of a decision,
  not a decision.

---

## Storage and discovery

- ADRs live in `docs/adr/` (or equivalent) in source control,
- numbered sequentially across the project,
- a top-level `docs/adr/README.md` lists them with one-line
  summaries,
- ADR list is part of the onboarding doc.

---

## Verify

A good ADR meets:

- a stranger to the project can read it and reconstruct the
  problem,
- they can identify what trade-offs were accepted,
- they can recognize when the ADR should be revisited,
- they can find relevant prior ADRs.

If the ADR fails any of these, revise it.

---

## Prime directive

Decisions that shape the system live forever in the system. Make
them visible. Make trade-offs explicit. Make the path the team
took recoverable a year from now.

The decision you do not write down is the one you will re-debate.
