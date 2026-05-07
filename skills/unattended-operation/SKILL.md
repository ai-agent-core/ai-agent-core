---
name: unattended-operation
description: Discipline for AI work performed without a human in the loop — overnight, while the user is away, on a hard deadline, in a CI / scheduled context, or whenever clarification cannot arrive within minutes. Trigger when the user signals an extended-duration task, mentions sleeping/leaving/AFK, sets a deadline more than ~30 min out, or runs the agent under cron/CI. Both the briefing checklist (human side) and the execution discipline (agent side) apply.
---

# Unattended operation

The cost of a wrong decision is higher when nobody is watching,
so the contract tightens on both sides — briefing and
execution. Open this skill at the start of any unattended run.

---

## Two-sided contract

Autonomous work has a *briefing side* (what the human writes
before walking away) and an *execution side* (how the agent
behaves while alone). Both halves MUST be present; one without
the other produces drift.

---

## Briefing checklist (human side)

When handing the agent an unattended task, the prompt MUST
include:

1. **Definition of done** — observable, concrete. "Tests pass
   and feature flag is wired" beats "make it work".
2. **Deadline** — absolute time with timezone (`2026-05-09
   08:00 JST`), not relative ("by tomorrow"). The agent
   budgets effort against it.
3. **Scope boundary** — what is *out of scope*. "Do not touch
   `infra/` or any migration file." Implicit scope creeps.
4. **Pre-authorized destructive ops** — explicit *and scoped*
   allowlist. Bad: "you may push". Good: "`git push origin
   feature/foo` only — no force-push, no `main`, no
   `release/*`". Default-deny if not listed.
5. **Pre-authorized external comms** — Slack, email, GitHub
   issues, deploys to staging, with the exact target ("post
   to #releases on completion"). Default-deny.
6. **Where to log** — `.aiac/tasks/todo.md` for live progress,
   `.aiac/tasks/lessons.md` for durable learnings. Anything
   else needs a path.
7. **Stop-vs-guess policy** — "if blocked, stop and leave a
   note" or "make a reasonable assumption and flag it in the
   summary". Default = stop.

A briefing missing these fields is incomplete. The agent
SHOULD restate any defaults it inferred at the top of its
first reply so the user can correct course before walking
away.

---

## Execution discipline (agent side)

### Plan and track

- Use `TaskCreate` / `TaskUpdate` for every trackable subtask.
  The user reads the task list to audit progress; keep it
  honest — `in_progress` while working, `completed` only when
  done with proof.
- Spec-driven workflow still applies
  (`rules/WORKFLOW_RULES.md`). Never skip the spec because
  "no one is watching".

### Checkpoint discipline

- Commit at every green bar. One behavior per commit. The
  repo must be runnable at every commit, so an interrupted
  shift leaves no half-state.
- NEVER `git push`, force-push, rebase shared branches, or
  publish artifacts unless explicitly pre-authorized in the
  briefing.
- NEVER amend a commit to mask a hook failure — write a new
  commit fixing the issue.

### Default-deny on side effects

Without explicit pre-authorization, do NOT:

- push to any remote, deploy, or publish,
- post to Slack / email / Discord / Linear / GitHub Issues,
- mutate any third-party tenant (Stripe, Resend, payment
  providers, cloud control planes),
- run destructive shell ops outside the working tree,
- exfiltrate secrets, credentials, internal docs, or paste
  large repository content into chat / web requests.

When in doubt, leave a note in `.aiac/tasks/todo.md` and
stop.

### Errors

- **Transient** (network blip, rate limit, flaky test, port
  in use): retry with backoff. Three attempts is the ceiling
  before treating it as irrecoverable.
- **Irrecoverable** (compiler error you cannot diagnose,
  missing credential, ambiguous spec, contradictory
  requirements): STOP. Write a clear, dated note to
  `.aiac/tasks/todo.md`: what you tried, what blocked, what
  input you need. Do not thrash; do not fabricate.

Pushing through a broken plan amplifies damage.

### Tests must stay local

`pnpm verify` (or equivalent) runs with no network, no shared
cloud, no live third-party tenants — same command on the
laptop, in CI, and in this session. See
`rules/TESTING_RULES.md` (Local-First Execution) and
`skills/usecase-driven-e2e` (Isolation Contract).

### Budget awareness

- The deadline is visible. As you approach it, prioritize
  *finishing what's started* over polish or scope expansion.
- If the deadline passes with work incomplete, STOP — write
  the end-of-shift summary and exit. Do not silently overrun.
- Token cost rises faster when alone (no human to bound the
  exploration). Apply `skills/token-efficiency` aggressively.

---

## Periodic and end-of-shift summary

After every completed sub-task, append a one-line entry to
`.aiac/tasks/todo.md` with timestamp + outcome.

Before stopping (deadline reached, work done, or blocked),
the agent MUST leave an **end-of-shift summary** at the top
of `.aiac/tasks/todo.md`:

```
## End-of-shift — <UTC timestamp>

- Done: <bullet list with commit SHAs>
- Open: <what remains, with next concrete action>
- Assumptions made: <list — these are the items most likely
  to need user review>
- Risky / unverified: <areas that compiled and tested but the
  agent could not fully validate>
- User should review first: <ordered list of files / commits>
```

This summary is the single artifact the user reads when they
return. Make it the most useful thing in the repo at that
moment.

---

## Host-side pre-flight (one-liner for the user)

Prevent the host machine from sleeping while the agent works.
A sleeping host is the most common cause of overnight runs
that "just stopped".

- **macOS** (default for nightly): `caffeinate -is -w $(pgrep -n claude)`
  — `-i` blocks idle sleep, `-s` blocks system sleep on AC
  power. Display is allowed to sleep (cheaper, no visual
  burn-in). `-w <pid>` ties caffeinate's lifetime to the
  Claude process: when the agent finishes or crashes, sleep
  resumes. Lid must stay open unless an external display is
  attached (clamshell mode).
- **macOS** (also keep display awake, e.g. for a demo):
  `caffeinate -dimsu` — full power, useful when watching the
  run live.
- **Linux**: wrap the long-running invocation —
  `systemd-inhibit --what=idle:sleep --who=claude
  --why='unattended run' <command>`. The inhibit lifts when
  the wrapped command exits.
- **Windows**: WSL2 is the supported path (use the Linux
  form). Native Windows is out of scope; if you must run
  there, set the sleep timer manually in Power Options
  before the run and restore after.

---

## Forbidden anti-patterns

- "I went ahead and also refactored X" — scope expansion
  without authorization.
- "I couldn't reach the staging API so I disabled the test"
  — silent test deletion to make the green light appear.
- "I assumed the user wanted Y" — assumption without being
  flagged in the end-of-shift summary.
- An overnight run with no commits and no
  `.aiac/tasks/todo.md` updates — invisible work is
  unverifiable work.
- `git push` to a shared branch without explicit
  pre-authorization.

---

## Prime directive

The user has chosen to trust the agent with hours of
unattended time. Every action must hold up to a calm, well-
rested review the next morning. When in doubt, leave a note
and stop — never guess into a one-way door.
