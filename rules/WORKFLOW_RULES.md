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

For any feature change, fix that alters behavior, or refactor that
crosses a public surface — *on the Standard or Heavy path*; see
Path selection below — the FIRST artifact agents produce is the
**specification**: not the code, not the test, not the issue.

When the Standard path applies, the order is non-negotiable:

```
  1. Spec (docs/, AsciiDoc)
       │
       │  (everything below derives from the spec, not from each other)
       │
       ├──► 2a. Unit / integration tests   (TESTING_RULES.md)
       │         │
       │         ▼
       │   3. Implementation (TDD: red → green → refactor — skill `tdd`)
       │
       └──► 2b. usecases/<feature>.yml     (skill `usecase-driven-e2e`)
                 │
        ┌────────┴────────┐
        ▼                 ▼
  4a. e2e/ verifier    4b. manual/ documenter
  (CI evidence)        (manual/dist/<feature>.html — committed)

  5. Verify spec coverage: every claim in the spec is realized by a
     test AND by a manual scenario — otherwise the work is not done.
```

## Per-step contract

1. **Spec** — `docs/explanation/<feature>.adoc` (WHY) and
   `docs/reference/<feature>.adoc` (WHAT). AsciiDoc by default;
   split into focused partials with `include::` rather than
   letting one file grow unbounded
   (`rules/DOCUMENTATION_RULES.md`). The spec under `docs/` is
   the single source of truth; tests, code, and manual are its
   consequence.

2. **Derive tests from the spec** — *both* layers are derived
   directly from the spec, not from each other:
   - **2a. Unit / integration** — fine-grained behavior and
     invariants (`rules/TESTING_RULES.md`).
   - **2b. Usecase YAML** — `usecases/<feature>.yml` declares
     end-user scenarios. This **same file** drives both the
     verifier (`e2e/`) AND the documenter (`manual/`); they
     never read each other's output (skill
     `usecase-driven-e2e`).

3. **Implement (TDD)** — code is written red → green →
   refactor (skill `tdd`). No production line exists without a
   failing test that demands it.

4. **Run the YAML through both consumers** — `pnpm verify` (or
   the equivalent) executes the verifier (assertions, evidence)
   and the documenter (snapshots, `manual/dist/<feature>.html`)
   in parallel. Hand-edits to `manual/dist/` are forbidden; the
   YAML is the source.

5. **Verify spec coverage** — re-read the spec next to the
   diff. Every claim in the spec MUST be realized by a test
   *and* by a manual scenario. Anything uncovered is unfinished.

## Test isolation (cross-cutting)

Every layer above runs **locally and reproducibly with no external
side effects** — no production / staging DB, no live third-party
tenant, no real recipients of email / SMS / webhooks. The same
command runs on the developer's laptop and in CI. See
`rules/TESTING_RULES.md` (Local-First Execution) and
`skills/usecase-driven-e2e/SKILL.md` (Isolation Contract) for the
full contract.

## Path selection (right-size the discipline)

Spec-driven discipline is calibrated. Pick the path that fits
the change; carrying heavy ceremony into a throwaway spike
produces the same drift as skipping ceremony on a critical
change.

- **Light path** — prototypes, internal one-off scripts,
  throwaway PoCs, exploratory spikes, time-boxed experiments.
  No formal `docs/explanation/<f>.adoc` is required up front,
  but: any code that ships still has tests, the work is
  flagged as experimental in the commit / PR so future
  readers see the discipline was relaxed deliberately, and the
  moment the experiment graduates to a kept feature it
  switches to the Standard path (write the spec retrospectively
  before merging the graduation PR).
- **Standard path** — most feature work and any behavior
  change. Full pipeline above (spec → tests + YAML → TDD →
  verifier + documenter → coverage check).
- **Heavy path** — regulated / financial / security-critical
  / public-API breaking changes. Standard + ADR (skill `adr`)
  + named additional reviewer + rollback plan. The spec MUST
  be linked from the PR description.

Two narrower escapes apply across all paths:

- **Bug fix on already-specified behavior** — write the
  failing test that reproduces the bug; the spec is presumed
  correct. If the fix reveals the spec was wrong, switch to
  Standard or Heavy and update the spec.
- **Pure rename / formatting / dead-code removal** — no
  behavior change. State this explicitly in the plan and
  proceed; no spec needed.

When in doubt, escalate one level (Light → Standard, Standard
→ Heavy) — the cost of over-disciplining a small change is
lower than the cost of under-disciplining a critical one.

The spec is short and disciplined — not a wall of text. Aim for
the minimum that lets a stranger understand the feature, the
scenarios, and the contract.

Ambiguity discovered late is expensive. Ambiguity discovered
early — at the spec — is cheap.

On Standard or Heavy paths: if the spec cannot be written, the
feature is not yet understood. STOP and clarify. (On the Light
path, an unwritable spec is sometimes the *point* of the spike
— the spike itself is the clarifying activity.)

---

# Use Subagents Liberally (Where Supported)

When the harness supports parallel or specialized subagents:

- Offload research, exploration, and parallel analysis
- Keep the main context window focused on synthesis and decisions
- Throw more compute at hard problems

One task per subagent.

Subagents return findings — the main agent synthesizes and
decides. Subagent context dies on return; capture findings in
your own message before the next batch of tool calls. The full
discipline (when to delegate, how to brief, batching parallel
calls, capturing findings before compaction) lives in
`skills/token-efficiency` — load it for research-heavy or
long-horizon sessions.

---

# Self-Improvement Loop

After ANY correction from the user:

1. Append the pattern to `.aiac/tasks/lessons.md`
2. Write rules for yourself that prevent the same mistake
3. Iterate until the mistake stops recurring

Capture wins too:

- When a non-obvious approach is validated, record it
- A lessons file that only captures failures drifts toward over-caution

Review `.aiac/tasks/lessons.md` at the start of new work.

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

# Unattended Work

When working overnight, while the user is away, on a hard
deadline, or whenever clarification is not available within
minutes, the rules above still apply but the contract on side
effects, checkpointing, and end-of-shift summaries tightens.
Load `skills/unattended-operation` at the start of any such
run — it carries the briefing checklist (human side) and the
execution discipline (agent side) plus the host pre-flight
(`caffeinate` / `systemd-inhibit`).

---

# Core Directive

Plan deliberately.
Execute transparently.
Verify before claiming done.
Learn from every correction.
