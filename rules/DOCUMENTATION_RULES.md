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
- **Specifications** — for every feature, the WHY
  (`docs/explanation/<feature>.adoc`) and the WHAT
  (`docs/reference/<feature>.adoc`). `docs/` is engineer-facing,
  hand-authored, and written in AsciiDoc.
- **Operation manual** — the end-user-facing how-to lives at
  `manual/dist/<feature>.html` and is **generated** from
  executable use cases (skill `usecase-driven-e2e`). `manual/`
  is a separate top-level concern from `docs/`; see below.
- **ADRs** — significant decisions with their context and
  consequences (skill `adr`).
- **Runbooks** — for every alert, deploy, restore, on-call
  procedure.
- **Postmortems** — for every meaningful incident.

Click-by-click UI tutorials are NOT hand-written. They are
generated from executable use cases (skill `usecase-driven-e2e`)
into `manual/`, so they cannot rot — when the UI changes, the
verifier fails before the manual becomes a lie.

What is NOT documented (defer to the code):

- function-by-function inventories,
- comments restating what a clear name already says,
- hand-written click-by-click tutorials (use the usecase
  pipeline instead).

---

# Format and Location

- Docs live in source control with the code they describe.
- **AsciiDoc (`.adoc`) is the default for engineer-facing docs
  under `docs/`** (explanation, reference, ADRs, runbooks).
  AsciiDoc gives us first-class includes (`include::`),
  attributes, and cross-references — which is what makes the
  next rule (file splitting) actually work.
- **Split docs into small, single-purpose files.** A spec is a
  composition of focused fragments, not one long page. Use
  AsciiDoc `include::` to assemble a top-level
  `docs/<area>/<feature>.adoc` from per-section partials under
  `docs/<area>/<feature>/` (e.g. `_overview.adoc`,
  `_constraints.adoc`, `_api.adoc`). One file = one concern.
  A wall-of-text page that nobody finishes serves no one.
- Diagrams are versioned (Mermaid blocks inside AsciiDoc — i.e.
  `[mermaid]\n----\n...\n----` — preferred over binary images,
  or accompanied by source).
- The repo's top-level `README.md` is the front door (Markdown
  by GitHub convention); everything engineer-facing under
  `docs/` is reachable from it.
- `rules/*.md` and `skills/*/SKILL.md` remain Markdown — they
  are tooling inputs (Claude Code consumes them as `.md`) and
  are out of scope for the AsciiDoc default.

External docs platforms (Notion, Confluence, ReadMe.io) are
acceptable when the audience requires them, but the source of
truth lives with the code where feasible.

The AsciiDoc default is *provisionally accepted* — see
`docs/adr/0001-doc-format-asciidoc.adoc`. There is a scheduled
reassessment with explicit reversion triggers. If you hit a
trigger (real tooling friction, deeply nested `include::`,
contributor pain), surface it before working around it.

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

ADR location: `docs/adr/NNNN-title.adoc`. Numbered
sequentially. Status: proposed → accepted → superseded.

A decision without an ADR was not made; it was guessed.

---

# Specifications, Use Cases, and Operation Manual

The pipeline is split into three **independent** top-level
concerns. Each has one responsibility and one audience.

## `docs/` — specification (engineer-facing, hand-authored)

Each feature owns two doc artifacts under `docs/`, written in
AsciiDoc:

- `docs/explanation/<feature>.adoc` — **WHY**: business intent,
  constraints, design rationale.
- `docs/reference/<feature>.adoc` — **WHAT**: schema, API
  surface, invariants, contracts.

Each of these is a composition root: when a section grows past
a screen or two, split it into a partial under a sibling
directory (`docs/explanation/<feature>/_<section>.adoc`) and
pull it in with `include::`. The top-level file stays a table
of contents over its own fragments.

Plus the cross-cutting engineer-facing artifacts:
`docs/adr/<NNNN>-<title>.adoc`, `docs/runbooks/<name>.adoc`,
etc. — all AsciiDoc.

`docs/` is hand-authored (or AI-drafted from product
requirements; human-reviewed before merge). It is **not** where
end users go.

## `usecases/` — single source of truth (shared input)

Each feature has one declarative YAML:

- `usecases/<feature>.yml` — derived from the spec, formalizes
  it into executable form.

This file is the **only** input shared between the verifier and
the documenter. See `skills/usecase-driven-e2e/SKILL.md` for the
schema and verb semantics.

## `manual/` — operation manual (end-user-facing, generated)

The end-user-facing how-to lives in its own top-level root:

- `manual/dist/<feature>.html` — **HOW**: end-user procedure
  with screenshots. **Auto-generated** by the documenter
  (`manual/generator/docgen.ts`) from `usecases/<feature>.yml`.
- `manual/snapshots/<feature>/...` — figures with red-box
  overlays showing "press here next".

Manuals are committed (publication assets — shippable without
rebuild). Hand-edits to `manual/dist/` are forbidden; edit the
YAML source.

## Why split `docs/` and `manual/`

- **Audiences differ.** `docs/` is read by engineers; `manual/`
  is read by end users. Mixing them produces docs full of
  jargon and manuals full of internals.
- **Lifecycles differ.** Specs are hand-authored and reviewed;
  manuals are regenerated whenever the YAML changes.
- **Authorship differs.** Specs are written; manuals are
  produced.
- **MECE.** A feature's WHY lives in `docs/explanation/`, its
  WHAT in `docs/reference/`, its declarative flow in
  `usecases/`, its verification in `e2e/`, its end-user
  procedure in `manual/`. No artifact has two homes.

## The loop

```
spec (docs/<area>/<feature>.adoc, hand-authored AsciiDoc)
   │
   ▼
usecases/<f>.yml (derived from spec)
   │
   ├─→ e2e/        (verifier — proves spec coverage; CI evidence)
   └─→ manual/     (documenter — publishes end-user guide)
```

The verifier and the documenter never read each other's
outputs. They share only the YAML and the runner-core (see
skill `usecase-driven-e2e`).

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
- Long single-file specs that no one ever finishes — split with
  `include::` instead.
- Hand-rolled `.md` under `docs/` when the project's spec
  artifacts are supposed to be `.adoc` (mixed formats fragment
  the toolchain).
- Documentation that exists only to satisfy an audit.

---

# Prime Directive

Documentation is a debt the team owes to the future. Pay it as
you go. The next engineer — possibly you, six months from now —
will thank the team that wrote the readme they actually use, and
curse the team that wrote one nobody read.

If a fact is important enough to know, it is important enough to
write down where it can be found.
