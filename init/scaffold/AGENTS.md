# AGENT ENTRYPOINT

Agent Core governs agent behavior in this repository.

Before making any changes, complete initialization.

Avoid improvisation; follow the defined process.

---

# MANDATORY INITIALIZATION

Agents MUST perform the following steps in order:

## 1. Check Execution Continuity (FIRST)

Before any changes, read:

agent-spec/WORK_STATE.md

If the file exists:

- Treat it as the authoritative execution state
- Resume from the recorded next step
- Avoid unnecessary re-analysis

If the file does not exist:

- Create it before performing meaningful work

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
