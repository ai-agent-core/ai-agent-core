# Documentation Rules

Documentation is part of the system. Out-of-date documentation is
worse than missing documentation: it lies authoritatively. These
rules govern what gets documented, where, and how it is kept
honest.

For workflow, see `rules/WORKFLOW_RULES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# What MUST Be Documented

For every project / service:

- **README** — what it is, how to run it locally, where to look
  for more.
- **Onboarding** — first-day experience for a new contributor;
  measured by them, not by the author.
- **Public API** — every endpoint, message, and contract,
  generated from a source of truth (OpenAPI, GraphQL schema,
  protobuf).
- **Architecture overview** — bounded contexts, dependencies,
  flow of a typical request.
- **Specifications & use cases** — for every feature, the WHY
  (`docs/explanation/<feature>.md`), the WHAT
  (`docs/reference/<feature>.md`), and the user-facing how-to
  (`docs/how-to/<feature>.md` — generated from executable use
  cases, see below).
- **ADRs** — significant decisions with their context and
  consequences (skill `adr`).
- **Runbooks** — for every alert, deploy, restore, on-call
  procedure.
- **Postmortems** — for every meaningful incident.

Click-by-click UI tutorials are NOT hand-written. They are
generated from executable use cases (skill `usecase-driven-e2e`)
so they cannot rot — when the UI changes, the test fails before
the docs become a lie.

What is NOT documented (defer to the code):

- function-by-function inventories,
- comments restating what a clear name already says,
- hand-written click-by-click tutorials (use the usecase
  pipeline instead).

---

# Format and Location

- Docs live in source control with the code they describe.
- Markdown is the default; diagrams are versioned (Mermaid in MD
  preferred over binary images, or accompanied by source).
- Pages are short and linkable. A wall-of-text page that nobody
  finishes serves no one.
- The repo's top-level `README.md` is the front door; everything
  else is reachable from it.

External docs platforms (Notion, Confluence, ReadMe.io) are
acceptable when the audience requires them, but the source of
truth lives with the code where feasible.

---

# README Structure

Every project's `README.md` answers, in order:

1. **What it is** — one paragraph.
2. **Who is it for** — audience and use cases.
3. **Quick start** — minimum steps to a running system.
4. **Architecture diagram** — high-level shape (one image or
   Mermaid).
5. **How to run tests** — single command preferred.
6. **How to deploy** — link to the runbook.
7. **Where to ask** — chat channel, on-call, owner.
8. **License**.

The first three are enough for a stranger to decide whether they
are in the right place.

---

# Architecture Decision Records (ADRs)

Significant, durable decisions ARE documented as ADRs. See skill
`adr`.

A decision is significant when:

- it is a one-way door (hard to reverse),
- it materially affects more than one team / service,
- it sets a precedent the team will follow,
- it locks in a vendor / technology / topology,
- a year from now someone will ask "why did we do it this way?"

ADR location: `docs/adr/NNNN-title.md` or equivalent. Numbered
sequentially. Status: proposed → accepted → superseded.

A decision without an ADR was not made; it was guessed.

---

# Specifications & Use Cases (Diátaxis layout)

Each feature owns three doc artifacts under the project's
`docs/` tree:

- `docs/explanation/<feature>.md` — **WHY**: business intent,
  constraints, design rationale.
- `docs/reference/<feature>.md` — **WHAT**: schema, API surface,
  invariants, contracts.
- `docs/how-to/<feature>.html` (or `.md`) — **HOW**: end-user
  procedure with screenshots. **Auto-generated** from the
  executable use cases under `e2e/usecases/<feature>.yml`
  (skill `usecase-driven-e2e`).

Authorship rules:

- Explanation & reference are hand-authored (or AI-drafted from
  product requirements; human-reviewed before merge).
- How-to is **generated** — never hand-edited. Editing the YAML
  source updates both the E2E test and the manual.
- Use cases are derived from the spec (= explanation +
  reference). The spec is the single source of truth; the YAML
  formalizes the spec into executable form.

This makes the loop:

```
spec (WHY/WHAT) → use cases (YAML) → E2E tests + user manual
```

… and keeps the manual structurally synchronized with the
implementation.

---

# Runbooks

Every alert, every deployment, every recovery procedure has a
runbook. See `rules/OBSERVABILITY_RULES.md`.

Required sections:

- **Symptoms** — what the alert / situation looks like.
- **Diagnosis** — first 3 things to check.
- **Mitigation** — actions to take, with required permissions.
- **Escalation** — who to page if the playbook does not resolve.
- **Known false positives** — when the alert lies.

Runbooks are tested in calm times, used in storms. A runbook that
has not been used since it was written has probably rotted.

---

# Postmortems

Every meaningful incident gets a postmortem within one week:

- timeline (UTC, with sources),
- impact (who, how many, how long),
- contributing causes (plural — never one root cause for
  non-trivial systems),
- what went well,
- what went poorly,
- action items with owners and deadlines,
- tracked to completion.

Required posture: blameless. Address the system, not the person.

A postmortem with no completed action items is a story.

---

# API Documentation

Generated from the source of truth (OpenAPI / GraphQL schema /
protobuf):

- every endpoint, request, response, error code,
- every field's type, nullability, format,
- examples for the common cases,
- auth requirements per endpoint,
- pagination, idempotency, rate-limiting headers documented
  globally,
- changelog kept current.

If the spec and the implementation drift, CI fails.

Forbidden:

- hand-written API docs that drift from the implementation,
- incomplete docs published as "draft" indefinitely.

---

# Code Comments

Default: write no comments. The name and structure are the
documentation.

Add a comment ONLY for:

- a non-obvious WHY (constraint, invariant, workaround for a
  specific bug, behavior that would surprise a careful reader),
- a public API surface that benefits from doc-generated help
  (exported function / type),
- a `TODO` / `FIXME` with a tracked ticket reference.

Forbidden:

- comments restating the code (`// increment counter`
  next to `counter++`),
- commented-out code (delete it; git remembers),
- attribution / "added by X for ticket Y" — the VCS records
  this,
- `// Hack:` / `// Quick fix:` without a tracked plan.

---

# Public Code Documentation (libraries / SDKs)

When the code is a library or SDK consumed by other engineers:

- every exported type / function has a doc comment,
- examples for the common cases,
- documented error semantics,
- migration guide on breaking changes,
- a changelog,
- the doc is generated and shipped with releases.

Generated docs are a contract. Treat them like one.

---

# Onboarding Documentation

The onboarding doc is the most-read and most-rotted document in
the repo. Mitigate:

- pair the next new contributor with the doc; let them edit as
  they go,
- automate what you can (setup script, devcontainer),
- review the onboarding doc once a quarter,
- success metric: new contributor can run the system locally and
  ship a small change in their first day.

---

# Diagrams

- Architectural diagrams use a consistent notation (e.g. C4),
- diagrams are sources (Mermaid, Structurizr, PlantUML) committed
  to the repo, never only PNGs in chat,
- box-and-arrow diagrams show the right level of detail; the
  level should be stated up front,
- sequence diagrams for flows where order matters,
- entity-relationship diagrams for non-trivial schemas.

Forbidden:

- a single diagram that tries to show every detail at every
  level,
- diagrams unreadable in greyscale (color is not the only signal).

---

# Glossary

A glossary captures the project's ubiquitous language. Every
non-trivial domain term:

- has a definition,
- has examples,
- has known synonyms (and their preferred form),
- is the canonical reference for naming decisions.

Inconsistent vocabulary produces inconsistent systems. The
glossary is the antidote.

---

# Public-Facing Docs

For developer-facing products:

- versioned docs per major API version,
- examples in the languages the audience uses,
- runnable / copyable code samples,
- changelog,
- deprecation notices visible at the page level.

For end-user products:

- task-oriented help (what they want to do, not what every screen
  has),
- searchable,
- localized,
- accessible (`rules/ACCESSIBILITY_RULES.md`).

---

# Documentation in Code Reviews

The PR description is documentation:

- summarize the change,
- link to the spec / issue / design doc,
- describe how it was tested,
- note any follow-ups.

PRs are the historical record of intent. Effortful PR descriptions
pay back permanently.

---

# Maintenance

Documentation rots like code. Treat it accordingly:

- review on every related PR,
- the change that obsoletes the doc must update the doc,
- doc-only PRs are fine,
- "doc debt" is a class of debt with a tracked backlog,
- broken links are bugs.

When the doc and the code disagree, the doc is wrong by default
— and a PR fixes it within the day.

---

# Forbidden Anti-patterns

- "We will document it later."
- Wiki pages that have not been updated since the original
  author left.
- Documentation in chat-only ("ask in #channel for the latest").
- Multiple sources of truth for the same fact (drift guaranteed).
- A README that describes the system as it was three rewrites
  ago.
- Long Markdown documents that no one ever finishes.
- Documentation that exists only to satisfy an audit.

---

# Prime Directive

Documentation is a debt the team owes to the future. Pay it as
you go. The next engineer — possibly you, six months from now —
will thank the team that wrote the readme they actually use, and
curse the team that wrote one nobody read.

If a fact is important enough to know, it is important enough to
write down where it can be found.
