# Task Management Rules

Defines how agents track plans, progress, and continuity across sessions.

A consistent task surface makes work resumable, auditable, and shareable.

All instructions in this repository are subject to higher-priority
policies (system/developer/tool). If a conflict exists, follow the
higher-priority policy and report the conflict.

---

# Surfaces (CRITICAL)

Two local files at project root:

- `tasks/todo.md` — current plan, progress, review section
- `tasks/lessons.md` — durable learnings from corrections and validated approaches

One remote system (when available):

- branch-linked GitHub Issue — persistent context shared across agents and humans

`tasks/todo.md` is the primary local surface.
The GitHub Issue mirrors state and persists context across resets.

---

# Required Workflow

## Step 1 — Plan First

Before starting non-trivial work:

- Write a plan to `tasks/todo.md` with checkable items
- Items SHOULD be small, verifiable steps
- Replace prior content when starting a new work unit
  (history lives in the Issue)

## Step 2 — Verify the Plan

Confirm scope and approach with the user before implementation begins.

If clarification is needed, surface it now.

## Step 3 — Track Progress

As work proceeds:

- mark items complete in `tasks/todo.md`
- add new items as scope reveals itself
- reflect blockers and open questions inline

## Step 4 — Explain Changes

At each meaningful step, share a high-level summary.

Do NOT bury context in tool output.

## Step 5 — Document Results

When the work unit is complete, add a Review section to `tasks/todo.md`:

- what was changed
- what was verified
- what remains open

## Step 6 — Capture Lessons

After ANY user correction, append to `tasks/lessons.md`:

- the pattern (rule)
- the reason (why)
- when this kicks in (how to apply)

Capture validated non-obvious approaches too — not just failures.

---

# GitHub Issue Sync

When the repository is connected to GitHub (`gh` available):

## On Work Start

- Identify or create a branch-linked Issue
- Mirror the initial plan from `tasks/todo.md` into the Issue body
- Treat the Issue as the authoritative cross-session state

## During Work

- Append a comment whenever:
  - a plan item is completed
  - a decision is made
  - a constraint or risk surfaces
  - the plan changes materially
- Comments SHOULD be terse and factual

## On Completion

- Mirror the Review section into the Issue
- Close the Issue only when work is verified done

## On Failure to Sync

If `gh` is unavailable, rate-limited, or Issue operations fail:

- Continue working with `tasks/todo.md` alone
- Retry sync when connectivity returns
- Do NOT block work on Issue sync

---

# When NOT Connected to GitHub

`tasks/todo.md` and `tasks/lessons.md` ARE the authoritative state.

Continue using them as the planning and learning surface.

When GitHub connectivity is restored,
sync the current state into a new Issue.

---

# Forbidden Behaviors

Agents MUST NOT:

- erase prior plans without preserving outcomes
  in the Issue or Review section
- mark items complete without verification
- skip `tasks/lessons.md` after a correction
- treat tool output as a substitute for plan tracking

Transparency over tidiness.

---

# Migration Note

If a project tracks state in legacy locations
(for example, `agent-spec/WORK_STATE.md` or an `agent-works/` artifact tree),
migrate the relevant content into:

- the active plan → `tasks/todo.md`
- durable learnings → `tasks/lessons.md`
- handoff and decision context → the linked GitHub Issue

The legacy files MAY be removed once migration is complete.

---

# Prime Directive

Make continuation effortless.

The next agent — human or AI — should resume in minutes,
not hours.
