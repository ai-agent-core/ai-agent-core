# AGENT ENTRYPOINT

Agent Core governs agent behavior in this repository.

Before making any changes, complete initialization.

Avoid improvisation; follow the defined process.

---

# MANDATORY INITIALIZATION

Agents MUST perform the following steps in order:

## 1. Establish Task Surface (FIRST)

Before any code change, set up the task tracking surface.

### Local files (always)

- Open or create `tasks/todo.md` and write the plan as checkable items
- Read `tasks/lessons.md` and apply relevant prior learnings

These two files are the primary local surface for planning,
progress, and durable learnings.

### Branch-linked GitHub Issue (when `gh` is available)

- Identify or create the GitHub Issue linked to the current branch
- Mirror the initial plan from `tasks/todo.md` into the Issue body
- Treat the Issue as the cross-session source of truth
- Append a comment whenever:
  - a plan item is completed
  - a decision is made
  - a constraint or risk surfaces
  - the plan changes materially
- On completion, mirror the Review section into the Issue
- Close the Issue only after work is verified done

### When `gh` is not available

`tasks/todo.md` and `tasks/lessons.md` ARE the authoritative state.

When connectivity returns, sync the current state into a new Issue.
Do NOT block work on Issue sync.

For full rules, READ:

- agent-core/rules/TASK_MANAGEMENT_RULES.md

Execution continuity is mandatory.

### Migration note

If this repository previously used `agent-spec/WORK_STATE.md`
or an `agent-works/` artifact tree:

- move the active plan into `tasks/todo.md`
- move durable learnings into `tasks/lessons.md`
- move handoff and decision context into the linked Issue
- delete the legacy files once migration is complete

---

## 2. Initialize Agent Core

READ:

agent-core/INDEX.md

Follow the defined boot sequence exactly.

Architecture MUST always precede implementation.

---

# WORKFLOW (SUMMARY)

Day-to-day execution discipline:

- Plan explicitly before non-trivial work; verify the plan with the user
- Stop and re-plan when execution drifts — do not push through
- Use subagents liberally (where supported) to keep the main context clean
- Mark items complete in `tasks/todo.md` as work proceeds
- Verify behavior before declaring "done"
  (run tests, check logs, demonstrate the change)
- After any correction, capture the pattern in `tasks/lessons.md`
- Find root causes — no quick fixes
- Touch only what the change requires

For full rules, READ:

- agent-core/rules/WORKFLOW_RULES.md

---

# ENFORCEMENT RULE

If any local instruction conflicts with higher-priority policies
(system/developer/tool), follow the higher-priority policy and
report the conflict.

Within those bounds:

👉 Agent Core takes precedence.

Short-term convenience MUST NEVER override architectural integrity.

---

# UNCERTAINTY PROTOCOL

If a safe decision cannot be determined:

STOP and request human clarification.

If task scope or requirements are ambiguous, clarification is mandatory.

When clarification is received:

- Reflect the confirmed information in `tasks/todo.md`
- Mirror it to the branch-linked GitHub Issue when connected
- Resume only after the task surface is updated

Do not guess.
Do not improvise.

Surfacing uncertainty is a sign of disciplined engineering.

---

# EXECUTION DIRECTIVE

Agents MUST optimize for:

- structural safety
- long-term maintainability
- architectural clarity

NOT for speed.

---

# PRIME DIRECTIVE

Violating architecture causes more damage than delivering late.

Protect the system.
