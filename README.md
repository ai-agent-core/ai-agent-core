# Agent Core

**Agent Core is a governance layer for AI-assisted software engineering.**

It provides a structured control system that ensures agents reason,
design, and implement software with architectural discipline.

Agent Core is not a prompt collection.

It is an execution framework for controlled intelligence.

---

# Why Agent Core Exists

Modern AI coding tools are powerful — but without constraints, they drift.

Common failure patterns:

- architectural inconsistency
- uncontrolled agent improvisation
- short-term decisions damaging long-term systems
- code that future engineers must rewrite

Agent Core prevents this by enforcing structured decision-making.

**Architecture must not emerge accidentally.**

---

# Who This Is For

Agent Core is designed for engineers and teams who:

- build production systems with AI agents
- care about long-term maintainability
- want deterministic agent behavior
- enforce architectural boundaries
- treat AI as an engineering partner — not a code generator

If you are experimenting casually, Agent Core is probably unnecessary.

If you are building systems meant to last, it becomes extremely valuable.

---

# What Agent Core Provides

### Governance

A control layer that defines how agents must reason before writing code.

### Deterministic Initialization

Every agent follows the same boot sequence:

1. Check execution state
2. Load architectural principles
3. Follow enforced rules
4. Then implement

No improvisation.

### Execution Continuity

Agents externalize working memory into:

```
agent-spec/WORK_STATE.md
```

This allows another agent to resume work instantly when limits,
sessions, or models change.

AI work becomes interruptible — without losing context.

### Architectural Protection

Agent Core enforces:

- dependency direction
- layer isolation
- domain protection
- explicit contracts

Short-term speed never overrides structural safety.

---

# Installation

Install Agent Core using the bootstrap script from your project root.

## macOS / Linux

```bash
./agent-core/init/bootstrap.sh
```

## Windows (Command Prompt)

```bat
agent-core\init\bootstrap.cmd
```

## Windows (PowerShell)

```powershell
.\agent-core\init\bootstrap.cmd
```

---

# What Gets Installed

The bootstrap generates:

- `AGENTS.md` — the mandatory execution entrypoint
- `CLAUDE.md` — redirects compatible agents
- `agent-spec/WORK_STATE.md` — externalized execution memory

These files establish the initialization protocol for all agents.

---

# After Installation (MANDATORY)

Commit the generated files immediately:

```bash
git add AGENTS.md CLAUDE.md agent-spec
git commit -m "Install Agent Core"
```

Agent continuity depends on versioned execution state.

---

# Core Philosophy

### Architecture precedes implementation.

### Structural integrity outweighs convenience.

### Controlled intelligence beats improvisation.

### Systems should not require future rewrites.

Agent Core optimizes for long-term engineering safety.

---

# How It Works (Conceptual)

Agent Core separates concerns into four layers:

## Principles
Foundational beliefs guiding decisions.

## Rules
Enforceable constraints on agent behavior.

## AI Control
Machine-readable reasoning guidance.

## Execution State
Externalized working memory for continuity.

Together, these create a predictable agent runtime.

---

# When NOT to Use Agent Core

Agent Core may be excessive if:

- you are prototyping rapidly
- the code will be discarded
- architectural consistency is irrelevant
- agents are used only for small tasks

Agent Core is intentionally opinionated.

It favors safety over speed.

---

# Design Goals

Agent Core is built to be:

- lightweight
- dependency-free
- OS-agnostic
- bootstrap-driven
- structurally strict
- interruption-safe

It should feel invisible — yet protective.

---

# Contributing

Contributions are welcome if they improve:

- architectural safety
- clarity
- determinism
- cross-agent consistency

Please avoid adding complexity without structural benefit.

Agent Core values precision over feature growth.

---

# Philosophy in One Sentence

**Prevent architectural drift before it begins.**

---

# License

MIT
