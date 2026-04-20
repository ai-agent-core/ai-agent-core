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

### `agent-works` Continuity Protocol (MANDATORY)

- Create `agent-works/` at project root.
- For each work unit, create a folder under `agent-works/` with an English snake_case title.
- Inside that folder, create a management text file named `<YYYYMMDD_HHMMSS>.txt`.
- Store all related artifacts (patches, reports, tool outputs, logs) in the same folder using:
  - `<YYYYMMDD_HHMMSS>_001.<ext>`
  - `<YYYYMMDD_HHMMSS>_002.<ext>`
  - Continue incrementing as needed.
- After local files are created, run `gh` flow:
  - If a linked Issue already exists, append a comment with the latest context and artifact dump references.
  - If no linked Issue exists, create one and record the work-unit context.
- If Issue creation or comment posting fails (including no `gh` connection or rate limits):
  - Continue tracking only in local `agent-works/<work_unit>/`.
  - Keep creating new timestamped `.txt` records and numbered artifacts with the same naming rules.
  - Retry Issue sync later in oldest-first order (oldest unresolved work-unit first).
- When Issue sync succeeds, create `.issue` in that work-unit folder and store the Issue identifier (for example `#123` or full URL).
- All files inside `agent-works/` are commit targets.
- To close work:
  - Create `.closed` in the work-unit folder first.
  - Then close the linked GitHub Issue.
  - Only after close succeeds, delete the work-unit folder.

If not connected:

- Fall back to local continuity tracking in `agent-spec/WORK_STATE.md`
- Also apply the same `agent-works` protocol locally until GitHub connectivity is restored.

Execution continuity is mandatory.

---

## 2. Initialize Agent Core

Agent Core uses **profile-based context loading** to minimize
token cost while keeping full governance available.

### 2a. Always load Core

READ, in this order:

- `agent-core/INDEX.md`
- `agent-core/principles/ENGINEERING_PRINCIPLES.md`
- `agent-core/principles/ARCHITECTURE_PRINCIPLES.md`
- `agent-core/principles/DESIGN_PHILOSOPHY.md`
- `agent-core/rules/AI_BEHAVIOR_RULES.md`
- `agent-core/rules/META_RULES.md`
- `agent-core/glossary/GLOSSARY.md`
- `agent-core/ai/context_profiles.yaml`

These establish governance and the routing table.

### 2b. Classify the task

Assign tags across three dimensions:

- `activity`: one of `implementation`, `structure_design`,
  `visual_design`, `bootstrap`, `review`
- `stack`: zero or more of `backend`, `functions`, `frontend`
- `topic`: zero or more of `aggregate_boundary`, `persistence`,
  `test_authoring`, `naming`, `error_handling`

When a single instruction spans multiple stacks (for example,
backend and frontend together), assign all applicable stack tags.

When tagging is uncertain, prefer to **attach additional tags**
rather than fewer. The loading mechanism deduplicates.

### 2c. Load profile contributions

For every assigned tag, read the files listed under
`contributions.<tag>` in `context_profiles.yaml`.

Take the **union** of all contribution lists, remove duplicates,
and load the result.

### 2d. Fallback — load all

If no tag can be assigned with confidence, OR classification
itself cannot be completed, load every file listed under
`fallback.load_all`.

Fallback is the **safe default**. Prefer it over skipping
governance.

### 2e. Dynamic expansion

If scope widens during work (for example, a backend task starts
touching frontend), assign the additional tag and load only the
delta files. Full re-initialization is not required.

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
