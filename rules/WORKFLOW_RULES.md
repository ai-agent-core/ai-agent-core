# Workflow Rules

These rules define HOW agents execute work day-to-day.

Disciplined execution beats raw capability.

All instructions in this repository are subject to higher-priority
policies (system/developer/tool). If a conflict exists, follow the
higher-priority policy and report the conflict.

---

# Plan Before Acting

Agents MUST plan explicitly before non-trivial work.

Non-trivial means:

- 3+ steps
- architectural decisions
- multi-file changes
- behavior changes that need verification

If a planning surface is available
(plan mode, scratch plan, design note),
USE IT.

Skip explicit planning ONLY for simple, obvious fixes.

---

# Stop and Re-Plan When Things Drift

If execution starts going sideways:

STOP.

Do not push through.

Re-plan immediately.

Pushing through a broken plan amplifies damage.

---

# Spec-Driven Development

When new development is decided, the FIRST artifact agents produce
is the specification — not the code, not the test, not the issue.

The order is non-negotiable:

1. **Specification** — write / update docs under `docs/`
   (explanation + reference) so the WHY and the WHAT are
   articulated. Use cases are organized here, with one section
   per scenario the user can perform.
2. **Tests from the spec** — derive both fine-grained tests
   (unit / integration, see `rules/TESTING_RULES.md`) and
   end-to-end usecase scenarios (skill `usecase-driven-e2e`)
   directly from the spec. The spec is the SoR; the tests are
   its executable form.
3. **Implementation** — write code TDD-style (skill `tdd`) to
   make the failing tests green.
4. **Verify the spec is satisfied** — re-read the spec next to
   the diff. If anything in the spec is not yet covered by a
   test, the work is not done.

The spec is short and disciplined — not a wall of text. Aim for
the minimum that lets a stranger understand the feature, the
scenarios, and the contract.

Ambiguity discovered late is expensive.
Ambiguity discovered early — at the spec — is cheap.

If the spec cannot be written, the feature is not yet understood.
STOP and clarify.

---

# Use Subagents Liberally (Where Supported)

When the harness supports parallel or specialized subagents:

- Offload research, exploration, and parallel analysis
- Keep the main context window focused on synthesis and decisions
- Throw more compute at hard problems

One task per subagent.

Subagents return findings — the main agent synthesizes and decides.

---

# Self-Improvement Loop

After ANY correction from the user:

1. Append the pattern to `tasks/lessons.md`
2. Write rules for yourself that prevent the same mistake
3. Iterate until the mistake stops recurring

Capture wins too:

- When a non-obvious approach is validated, record it
- A lessons file that only captures failures drifts toward over-caution

Review `tasks/lessons.md` at the start of new work.

---

# Verify Before "Done"

Agents MUST NOT mark a task complete without proof it works.

Verification SHOULD include:

- running tests
- comparing behavior against the baseline
- checking logs for unexpected signals
- demonstrating the change behaves as specified

Ask: "Would a senior engineer approve this?"

If you cannot answer yes — keep working.

---

# Demand Elegance for Non-Trivial Changes

Before presenting non-trivial work, agents SHOULD pause and ask:

"Is there a more elegant solution?"

If a fix feels hacky:

Implement the elegant version, knowing what you know now.

Skip this loop for simple, obvious fixes.

Do NOT over-engineer simple work in the name of elegance.

---

# Fix Bugs Autonomously

When given a clear bug report:

Just fix it.

Do not request hand-holding for the obvious next step.

When logs, errors, or failing tests already point at the cause:

Resolve them.

The user should not need to babysit failing CI.

---

# Find Root Causes

Agents MUST NOT apply temporary fixes that mask underlying issues.

When a problem appears:

- identify the root cause
- repair the root cause
- avoid quick fixes that defer the work

Senior-developer standards apply to every change.

---

# Minimal Impact

Changes SHOULD only touch what the work requires.

Avoid:

- speculative refactors
- unrequested cleanups
- broad rewrites attached to small fixes

Small changes are reviewable.
Large changes hide bugs.

---

# Core Directive

Plan deliberately.
Execute transparently.
Verify before claiming done.
Learn from every correction.
