---
name: plan-and-implement
description: Explore → Plan → Implement → Verify → Commit. Separate research from execution so you do not solve the wrong problem fast.
---

# Plan and implement

Use this skill **before any non-trivial change**. Non-trivial means:

- 3+ steps, OR
- multi-file changes, OR
- architectural decisions, OR
- behavior changes that need verification.

Skip this skill for one-line typos, log-line additions, or single
variable renames. The diff fits in one sentence → just do it.

---

## Phase 0 — Spec (write the contract first)

When new development is decided (= not a fix or refactor on an
existing feature), the FIRST artifact is the **specification** —
written into `docs/`:

- `docs/explanation/<feature>.md` — WHY (business intent,
  constraints, design rationale).
- `docs/reference/<feature>.md` — WHAT (data shape, API
  surface, invariants).

Use cases are organized in the spec, with one section per
end-user scenario.

The spec drives both layers of testing:

- Unit / integration tests → derived from invariants &
  contracts in the spec.
- End-to-end use cases → declared in `e2e/usecases/<feature>.yml`
  (skill `usecase-driven-e2e`). Same YAML produces both the
  Playwright tests and the user manual under `docs/how-to/`.

Skip Phase 0 ONLY for fixes / refactors of an already-specified
feature.

If the spec cannot be written, the feature is not yet
understood. STOP and clarify.

See `rules/WORKFLOW_RULES.md` (Spec-Driven Development) and
`rules/DOCUMENTATION_RULES.md` (Specifications & Use Cases).

---

## Phase 1 — Explore (no edits)

Goal: understand the surface before changing it.

- Read the relevant files. Use subagents for breadth so the main
  context stays clean ("use a subagent to map how X works").
- Read `ai-agent-core/generated/tasks/lessons.md`; apply prior
  learnings before re-deciding things.
- If unsure which files matter, ask the user — do not guess.

Stop the moment you have enough to write the plan. More reading
without a plan is context burn.

---

## Phase 2 — Plan (write it down)

Write the plan into `ai-agent-core/generated/tasks/todo.md` as
checkable items. Each item should be small and verifiable.

Required content:

- Objective (one sentence).
- Plan (ordered checklist).
- Verification (how you will prove it works).
- Risks / open questions.

Then **confirm the plan with the user before implementation**, unless
the operating mode (e.g. auto mode) explicitly authorizes
proceeding without confirmation. When in doubt, confirm.

If GitHub is reachable, mirror the plan into the branch-linked
Issue per skill `task-tracking`.

---

## Phase 3 — Implement (one item at a time)

- Mark the active item as in-progress.
- For behavior changes, use skill `tdd` (RED → GREEN → REFACTOR).
- Touch only what the item requires. No drive-by refactors.
- After each item: tick the box, append a one-line update to the
  Issue (if connected), restate what is next.

If the plan starts to drift (the work is no longer what the plan
described), STOP. Do not push through. Re-plan: shrink scope, split
the item, or escalate.

---

## Phase 4 — Verify

Before declaring done, prove it:

- Tests pass (and a *new* test exists for any new behavior).
- Typecheck and lint clean.
- For UI: open the feature in a browser, hit the golden path and at
  least one edge case, watch for regressions.
- For backend: hit the endpoint or run the use case end-to-end.
- Read the diff once more as if reviewing a stranger's PR.

Cannot verify? Say so explicitly. Do not claim "done."

---

## Phase 5 — Commit and capture

- Commit with a message that explains *why*, not *what*.
- Mirror the Review section into `tasks/todo.md` and (if connected)
  into the Issue. Close the Issue only after verification.
- If the user corrected anything during the work, run skill
  `capture-lesson` before closing out.

---

## Anti-patterns this skill rejects

- Editing before reading.
- Planning in your head instead of in `tasks/todo.md`.
- "I'll write the test after." Forbidden — see skill `tdd`.
- Repeated re-tries on a failing approach. After two failed
  attempts, `/clear` (or wipe context) and restart with a sharper
  plan that incorporates what you learned.
