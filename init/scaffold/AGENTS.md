# AGENT ENTRYPOINT

Agent Core governs all agent behavior in this repository.

Agents MUST NOT begin reasoning, designing,
or generating code until initialization is complete.

Improvisation is forbidden.

---

# MANDATORY INITIALIZATION

Agents MUST perform the following steps in order:

## 1. Check Execution Continuity (FIRST)

Before any analysis, read:

agent-spec/WORK_STATE.md

If the file exists:

- Treat it as the authoritative execution state
- Resume from the recorded next step
- Do NOT re-analyze the project unnecessarily

If the file does not exist:

Create it before performing meaningful work.

Execution continuity is mandatory.

---

## 2. Initialize Agent Core

READ:

agent-core/INDEX.md

Follow the defined boot sequence exactly.

Skipping layers is forbidden.

Architecture MUST always precede implementation.

---

# ENFORCEMENT RULE

If any local instruction conflicts with Agent Core:

👉 Agent Core takes precedence.

Short-term convenience MUST NEVER override
architectural integrity.

---

# UNCERTAINTY PROTOCOL

If a safe decision cannot be determined:

STOP.

Request human clarification.

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
