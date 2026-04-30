---
name: capture-lesson
description: After any user correction or any validated non-obvious approach, append a durable lesson to tasks/lessons.md so the same conversation does not happen twice.
---

# Capture lesson

Trigger this skill when **any** of the following happens:

- The user corrects your approach ("no, not like that", "stop
  doing X", "you missed Y").
- The user validates a non-obvious choice without pushback ("yes,
  exactly that"). Confirmations are quieter than corrections —
  watch for them.
- A debugging cycle ends with a finding that was not obvious from
  the code alone.

Lessons are written into
`.aiac/tasks/lessons.md`. They survive across
sessions, across agents, and across model upgrades.

---

## What belongs in lessons.md

Save things that future-you cannot rederive from the codebase:

- A constraint the user enforces ("integration tests must hit a
  real DB; mocks once masked a broken migration").
- A non-obvious convention specific to this project.
- A failure mode the user has seen recur and wants prevented.
- A validated trade-off so it is not re-debated next time.

Do **not** save:

- Things visible from `git log` or current code.
- Generic best practices that already live in `ai-agent-core/rules/`.
- Per-task details ("we fixed bug 1234"). Ephemeral context lives
  in the Issue and the commit message.

If the lesson is not durable, do not write it.

---

## Format

Append to `tasks/lessons.md`:

```
## <short rule, imperative if possible>

**Why:** <the reason, ideally a real incident or strong preference>

**How to apply:** <when this kicks in and where to be alert>
```

The **Why** matters more than the rule itself. Without the why,
future-you will follow the rule blindly and miss the edge case
where it does not apply.

---

## Self-improvement loop

After writing the lesson, ask:

1. Could a `rules/` file or a hook prevent this class of mistake
   automatically? If yes, propose the rule or hook to the user
   instead of relying on memory.
2. Is the lesson contradicting an existing one? If yes, update or
   remove the older one. Do not let `lessons.md` accumulate
   contradictions.
3. Did the same lesson appear before? If yes, the rule did not
   stick — escalate. Either it is too vague, or it belongs in
   `rules/`, not in `lessons.md`.

---

## Review cadence

At the start of any new work unit, **read `lessons.md` first**.
Apply lessons proactively. Lessons are not archived knowledge;
they are the active operating procedure for this project.
