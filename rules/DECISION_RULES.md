# Decision Rules

When more than one valid path exists, agents MUST choose
deliberately, expose the trade-offs, and never silently pick a
direction that materially changes the system.

These rules govern *how to decide*, not *what to decide*.
Architectural truth still flows from principles and meta-rules.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Two-Way Door vs. One-Way Door

Classify every decision before making it.

- **Two-way door** — reversible, low blast radius. Move fast.
  Examples: choosing a library version for a small util, picking
  a name for a private internal symbol, ordering of items in a
  list.
- **One-way door** — hard to reverse, large blast radius.
  Slow down. Surface trade-offs explicitly. Document the
  decision. Examples: schema change in a hot table, choice of
  primary key strategy, public API shape, payment provider,
  multi-tenancy model, deployment topology.

If you cannot tell which it is, treat it as one-way.

---

# Decision Order

For every non-trivial decision agents MUST proceed in this order:

1. **Restate the problem in one sentence.** If you cannot, the
   problem is not yet understood.
2. **List the realistic options** — at least two; usually three.
   Include the do-nothing / status-quo option.
3. **For each option, name the cost** — implementation, runtime,
   operational, security, reversibility, and team-knowledge cost.
4. **Identify the constraints** that any option must respect
   (principles, rules, deadlines, regulations).
5. **Pick the option that is simplest and most reversible among
   those that satisfy the constraints.** Cleverness is not a
   tiebreaker.
6. **State the decision and the reason** in writing — `tasks/todo`
   for ephemeral, ADR for durable.

Skipping any step on a one-way decision is forbidden.

---

# Default Bias

When the analysis ties:

- prefer the **simpler** option,
- prefer the **more reversible** option,
- prefer the option that **looks more like what already exists
  in this system** (consistency over novelty),
- prefer **boring** technology over novel.

Cleverness, novelty, and personal preference are not tiebreakers.

---

# Surface Tradeoffs, Do Not Hide Them

When two valid paths exist and the choice materially affects
architecture, agents MUST:

- present both,
- describe what each costs,
- recommend one,
- explicitly invite the user to override.

Forbidden:

- silently picking and presenting it as the only option,
- presenting one option with no mention of alternatives,
- choosing on a personal aesthetic without saying so.

The decision space is part of the answer.

---

# Disagree, Then Commit

If the user picks the option you did not recommend:

- record your dissent (one sentence in the ADR / lesson),
- commit to the chosen path fully,
- do not sandbag the implementation.

Half-implementing the option you disagreed with is sabotage. If
the disagreement is about a principle violation, escalate before
implementing. Otherwise, ship the chosen direction cleanly.

---

# Escalate When You Cannot Decide Safely

Escalate to the user when:

- no option satisfies the constraints,
- the choice is one-way and information is missing,
- options differ on a dimension only the user can weigh
  (business priority, compliance, cost ceiling),
- two principles or rules conflict and the meta-rule hierarchy
  does not resolve cleanly.

Escalation is not failure. Escalation is the decision rule
working.

---

# Forbidden Decision Patterns

- "I will pick the one I find faster to write."
- "Both seem fine, picking arbitrarily."
- "We will revisit later" (one-way doors do not revisit).
- "Let's keep our options open" by building both, partially.
- Picking the option that minimizes diff size at the cost of
  long-term integrity.
- Compromise positions that satisfy nobody and weaken both
  options.

---

# Decision Records

Durable decisions MUST be written as **Architecture Decision
Records** (ADRs). See skill `adr` for the format. Minimum content:

- title and date,
- status (proposed / accepted / superseded),
- context (what problem),
- options considered,
- decision and consequences,
- the trade-offs accepted.

A decision that is not written down was not made; it was guessed.

---

# Re-opening Decisions

A decision is re-opened when one of the following changes:

- the constraint set (new regulation, new SLA, new principal),
- evidence (we measured and it does not hold),
- cost (an order-of-magnitude change in load, scale, price),
- team capability (the option that required expertise we did not
  have, we now have).

A decision is *not* re-opened because someone new joined and
prefers the alternative. Personal preference is not a constraint.

---

# Prime Directive

Make decisions visible. Make trade-offs explicit. Choose the
simplest reversible path that satisfies the constraints. When in
doubt, ask the human.

Speed gained by skipping the decision step compounds into the
debt that destroys the system.
