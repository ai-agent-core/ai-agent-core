# AGENT ENTRYPOINT

Agent Core governs agent behavior in this repository.

Before making any changes, complete initialization.

Avoid improvisation; follow the defined process.

---

# MANDATORY INITIALIZATION

Agents MUST perform the following steps in order:

## 1. Check Execution Continuity (FIRST)

Before any changes, verify whether this repository is connected to GitHub (`gh`).

If connected:

- Create or identify a GitHub Issue linked to the current branch
- Treat that branch-linked Issue as the authoritative execution state
- If local continuity is already being tracked in `agent-spec/WORK_STATE.md`, migrate that context into the branch-linked Issue when the Issue exists
- Review existing Issue context before starting work
- Use the Issue so anyone can quickly recover context and resume work after interruptions
- Append to the Issue whenever new facts, progress, decisions, or constraints are discovered while working

If not connected:

- Fall back to local continuity tracking in `agent-spec/WORK_STATE.md`

Execution continuity is mandatory.

---

## 2. Initialize Agent Core

READ:

agent-core/INDEX.md

Follow the defined boot sequence exactly.

Architecture MUST always precede implementation.

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

- Reflect the confirmed information in the branch-linked GitHub Issue
- Resume only after the Issue context is updated

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
