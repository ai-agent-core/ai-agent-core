# AGENT CORE INDEX

Violating architecture causes more damage than delivering late.

Agent Core is the operating system for engineering decisions.

All instructions in this repository are subject to higher-priority
policies (system/developer/tool). If a conflict exists, follow the
higher-priority policy and report the conflict.

Agents MUST complete this boot sequence before making changes.

Avoid improvisation.

Architecture ALWAYS precedes implementation.

---

# BOOT SEQUENCE (ABSOLUTE)

Agents MUST initialize in the following order:

0. AI Control
1. Principles
2. Governance
3. Shared Language
4. Structure
5. Boundaries
6. Decisions
7. Implementation

Do not skip layers.

Lower layers MUST NEVER override higher layers.

---

# 0. AI CONTROL (FIRST — NON-NEGOTIABLE)

Defines how agents think and behave.

READ:

- rules/AI_BEHAVIOR_RULES.md
- ai/reading_order.yaml
- ai/machine_rules.yaml
- ai/decision_tree.yaml

Agents MUST NOT act before internalizing this layer.

Purpose:

- prevent hallucination
- enforce disciplined reasoning
- ensure behavioral predictability

Uncontrolled intelligence is systemic risk.

---

# 1. PRINCIPLES (FOUNDATIONAL)

Defines the philosophical backbone of the system.

READ:

- principles/ENGINEERING_PRINCIPLES.md
- principles/ARCHITECTURE_PRINCIPLES.md
- principles/DESIGN_PHILOSOPHY.md
- principles/FRONTEND_DESIGN_PHILOSOPHY.md

Purpose:

- anchor decision-making
- align engineering values
- eliminate short-term thinking

When uncertain, default to principles.

---

# 2. GOVERNANCE (CONSTITUTIONAL)

Defines how rules are interpreted and how conflicts are resolved.

READ:

- rules/META_RULES.md

Meta Rules function as constitutional law.

All other rules are subordinate.

Purpose:

- establish rule hierarchy
- eliminate ambiguity
- stabilize decision-making

Without governance, rules collapse into opinion.

---

# 3. SHARED LANGUAGE (MANDATORY)

A shared vocabulary prevents conceptual drift.

READ:

- glossary/GLOSSARY.md

Purpose:

- enforce ubiquitous language
- eliminate synonym chaos
- stabilize models

Naming IS architecture.

Inconsistent language produces inconsistent systems.

---

# 4. STRUCTURE (NON-NEGOTIABLE)

Ensures systems remain reproducible,
predictable, and operationally stable.

READ:

- rules/PROJECT_STRUCTURE_RULES.md
- rules/PACKAGE_LAYOUT_COMMON_RULES.md
- rules/PACKAGE_LAYOUT_BACKEND_RULES.md
- rules/PACKAGE_LAYOUT_FUNCTIONS_RULES.md
- rules/PACKAGE_LAYOUT_FRONTEND_RULES.md
- rules/GENERATOR_RULES.md

Purpose:

- enforce deterministic layouts
- guarantee regeneration safety
- scale engineering patterns

Structural mistakes compound silently.

Protect the structure aggressively.

---

# 5. BOUNDARIES (CRITICAL)

Protects the domain and enforces dependency direction.

READ:

- rules/LAYER_DEPENDENCY_RULES.md
- rules/MAPPER_RULES.md

Purpose:

- preserve domain purity
- prevent infrastructure leakage
- maintain layer integrity

The domain is the highest-value asset.

Guard it relentlessly.

---

# 6. DECISIONS (MANDATORY)

Guides agents when multiple valid paths exist.

READ:

- rules/DECISION_RULES.md

Purpose:

- ensure consistent judgment
- prevent architectural drift
- block convenience-driven design

When no safe path is obvious:

Pause and request clarification.

Avoid guessing.

---

# 7. IMPLEMENTATION (DISCIPLINED EXECUTION)

Defines how code is written,
how failures are handled,
and how behavior is verified.

READ:

- rules/NAMING_RULES.md
- rules/CODING_RULES.md
- rules/ERROR_HANDLING_RULES.md
- rules/TESTING_RULES.md
- rules/FRONTEND_DESIGN_RULES.md

Purpose:

- produce senior-level code
- ensure diagnosable failures
- define behavior through tests

Implementation MUST reflect architecture.

Never the reverse.

---

# GLOBAL ENFORCEMENT

If any guidance conflicts with architecture:

Follow the architecture unless a higher-priority policy requires otherwise.

Short-term velocity MUST NEVER override
long-term structural integrity.

---

# ESCALATION PROTOCOL

If no safe decision emerges:

Pause and ask for human clarification.

Do not guess.  
Do not improvise.

Uncertainty must be surfaced — never hidden.

---

# PRIME DIRECTIVE

Build systems that remain:

- understandable
- modifiable
- structurally safe
- resilient under change

Optimize for future engineers.

Not present convenience.
