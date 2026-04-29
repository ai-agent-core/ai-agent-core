---
name: task-tracking
description: Maintain tasks/todo.md and tasks/lessons.md inside agent-core/generated, and mirror state into the branch-linked GitHub Issue when gh is available.
---

# Task tracking

Use this skill **whenever a work unit starts, advances, or ends**.

Authoritative state lives in:

- `agent-core/generated/tasks/todo.md` — current plan, progress,
  review section.
- `agent-core/generated/tasks/lessons.md` — durable learnings.

If `gh` is reachable, the branch-linked GitHub Issue is the
cross-session source of truth. Without `gh`, the local files are
authoritative; sync to a fresh Issue when connectivity returns.

`tasks/todo.md` is short-lived: each new work unit replaces its
contents. History lives in the Issue and in commits, not in
`todo.md`.

---

## On work start

1. Open `tasks/todo.md`. If it still describes a finished work
   unit, archive its Review section into the linked Issue, then
   replace the file's contents with the new objective and plan.
2. Read `tasks/lessons.md`. Apply relevant prior lessons *before*
   re-deciding the same things.
3. If `gh` is available:
   - Find or create the branch-linked Issue.
   - Mirror the initial plan into the Issue body.
4. Confirm scope and approach with the user before implementing.

Required `tasks/todo.md` shape:

```
# Objective
<one sentence>

# Plan
- [ ] item 1
- [ ] item 2

# In Progress
<the one item currently being worked on>

# Completed
<finished items, chronological>

# Review
<populated when the work unit is done>
```

---

## During work

- Tick items in `tasks/todo.md` as soon as each finishes — do not
  batch. Verifiable progress beats tidy final commits.
- Add new items as scope reveals itself; never silently expand.
- When connected: append an Issue comment when
  - an item is completed,
  - a decision is made,
  - a constraint or risk surfaces,
  - the plan changes materially.
- Comments are terse and factual. Tool output is not a substitute
  for plan tracking.

---

## On work completion

1. Populate the Review section of `tasks/todo.md`:
   - what changed,
   - what was verified,
   - what remains open.
2. Mirror the Review into the Issue (if connected).
3. Close the Issue only after verification.
4. If the user corrected anything during the work, run skill
   `capture-lesson`.

---

## Forbidden

- Erasing prior plans without preserving outcomes in the Review or
  the Issue.
- Marking items complete without verification.
- Skipping `tasks/lessons.md` after a correction.
- Treating the model's tool output as the durable record.

Make continuation effortless. The next agent — human or AI —
should resume in minutes, not hours.
