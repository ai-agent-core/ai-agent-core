# Installation

Agent Core is installed into a project using the bootstrap script.

Run the command from your project root.

---

## macOS / Linux

```bash
./agent-core/init/bootstrap.sh
```

---

## Windows (Command Prompt)

```bat
agent-core\init\bootstrap.cmd
```

---

## Windows (PowerShell)

```powershell
.\agent-core\init\bootstrap.cmd
```

---

# What This Does

The bootstrap installs the agent entrypoints and execution state:

- AGENTS.md
- CLAUDE.md
- agent-spec/WORK_STATE.md

These files establish the mandatory initialization protocol for all agents.

---

# After Installation (MANDATORY)

Immediately commit the generated files:

```bash
git add AGENTS.md CLAUDE.md agent-spec
git commit -m "Install Agent Core"
```

Agent continuity depends on these files being versioned.
