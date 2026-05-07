# Token Efficiency Rules

Context is finite, paid-for, and lossy: as the window fills, older
tool results get compacted into summaries you can no longer trust
verbatim. Wasting tokens is wasting accuracy, latency, and money.

These rules apply to every session. Higher-priority policies
(system / developer / tool) win on conflict.

---

# Read narrowly

- Locate before reading. Use `grep` / `find` / `Glob` to identify
  the smallest set of files that must be opened.
- `Read` with `offset` / `limit` whenever the target span is
  known. Reading a 2000-line file to inspect 30 lines is a leak.
- Never re-read a file you just edited to "verify" — the editor
  errors if the change failed; the harness tracks state for you.

# Delegate breadth to subagents

- Multi-file searches, "where is X used", "how does Y work
  across the repo": send to a subagent (`Explore` for fast read-
  only lookup, `general-purpose` for synthesis). The subagent's
  context dies on return; only its findings cross back.
- Run independent subagents in parallel when their work does not
  depend on one another.
- Brief them like a colleague who just walked in: state the goal,
  the constraint, and the response shape (e.g. "under 200 words,
  list paths only").

# Capture findings before they scroll out

Tool results in your context are temporary. Anything you will
need later — a path, a line number, a config value, a decision —
restate it in your own message *before* the next batch of tool
calls. Once compaction kicks in, you cannot retrieve the exact
bytes; you only retain what you wrote down.

# Batch independent tool calls

When several tool calls have no data dependency, emit them in one
assistant turn (multiple tool blocks). One turn per dependency
edge, not one turn per call. Sequential chains are for genuinely
sequential work.

# Concise output to the user

- No preambles ("Let me start by…", "I'll now…"). Lead with the
  action or the answer.
- No trailing summary that recaps what the diff already shows. A
  one-sentence end-of-turn note is the ceiling.
- No restating the user's question back at them.
- Status updates only at moments that matter: a finding, a
  direction change, a blocker. Silent stretches are fine when
  there is nothing to report.

# Don't load what you won't use

- Skills are load-on-demand. Open `SKILL.md` only when the
  current task matches its trigger.
- Rule files referenced from another rule are pointers, not an
  invitation to open them. Follow the pointer only when the
  current decision requires what is in there.
- Stop reading a file the moment you have the answer.

# Don't generate filler

- No commentary code: comments that restate the line above earn
  zero, cost real tokens (`rules/DOCUMENTATION_RULES.md`).
- No defensive rewrites that touch unrelated code.
- No "in case you wanted it" extras the user did not ask for.
- Do not echo large file content back to the user — reference
  paths and line numbers (`file_path:line_number`).

# Re-use prior work

- Lessons live in `.aiac/tasks/lessons.md`. Read them at the
  start of new work; do not re-derive what is already recorded
  (`rules/WORKFLOW_RULES.md` Self-Improvement Loop).
- Memory holds durable facts about the user, project, and
  feedback. Check it before asking a clarifying question.

# Calibration

These rules trade a small upfront read (this file) for repeated
savings every session. If a rule starts costing more than it
saves, cut it. Brevity is a feature.
