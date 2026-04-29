---
name: branching-and-commits
description: Use trunk-based development with short-lived branches, small atomic commits, conventional messages, and squash-merges to keep history honest and bisectable.
---

# Branching and commits

Use this skill **as the default for all version-control work**.
This is the floor — sharper team-specific conventions extend it,
they do not replace it.

Authoritative source: `rules/CICD_RULES.md` and
`rules/RELEASE_RULES.md`.

---

## Premise

Git history is the system's biographical record. A clean history
makes:

- bisecting bugs cheap,
- code review focused,
- onboarding faster,
- rollback straightforward.

A messy history compounds: every PR after it is a little harder.

---

## Step 1 — Branching model

Default: **trunk-based development** with short-lived branches.

- `main` is always deployable.
- Branches live < 2 days where possible.
- Branches are named `<author>/<short-topic>` or
  `<area>/<short-topic>` (e.g. `kk/order-cancel-flow`,
  `payments/idempotency-keys`).
- Long-running branches (release branches, multi-month
  rewrites) require explicit team agreement and a sync plan.

Forbidden:

- direct push to `main`,
- force-push to `main` / shared branches,
- branches that diverge from `main` for more than a sprint
  without rebasing,
- "personal sandboxes" that accumulate unrelated changes.

---

## Step 2 — Branch from where

- branch from `main` for new work,
- rebase regularly onto `main` (daily for active branches),
- merge `main` only via fast-forward / rebase, not via merge
  commits, in feature branches.

A branch that has not pulled `main` in a week is starting to
fight the rest of the team.

---

## Step 3 — Commits: small and atomic

Each commit:

- represents one logical change,
- compiles and passes tests on its own,
- has a message that explains the *why*.

A commit is atomic when it can be reverted alone without leaving
the codebase broken.

Anti-patterns:

- "WIP" / "fix" / "more changes" commits in the merged history,
- 1,000-line commits that touch unrelated areas,
- commits that mix refactor + behavior change (split them),
- commits that mix style / formatting + logic.

Use `git rebase -i` to clean up a branch before review (or
squash-merge — see Step 6).

---

## Step 4 — Commit messages

Default to conventional-commit style or a similar agreed
convention:

```
<type>(<scope>): <short summary in imperative>

<body explaining why, the trade-offs, the constraints>

<footer with refs / breaking changes>
```

Types:

- `feat` — new behavior (user-facing or system),
- `fix` — bug fix,
- `refactor` — internal restructure, no behavior change,
- `perf` — performance improvement,
- `docs` — documentation only,
- `test` — test changes,
- `chore` — toolchain / dependencies / build,
- `ci` — pipeline changes,
- `style` — formatting only.

Rules for the message:

- summary in imperative present tense ("Add", not "Added"),
- ≤ 72 chars on the summary line,
- body wraps at ~80 chars,
- body explains *why*, not *what* (the diff shows the what),
- references issues / tickets in the footer.

Forbidden:

- empty commit messages,
- "fix bug" / "update code" / "minor changes" — say which bug,
- copy-pasting the diff into the message,
- trailing markers added by tools you do not understand.

---

## Step 5 — PR shape

PRs are small. Default target: under ~400 lines diff. Larger
requires justification.

A PR has:

- a focused scope (one feature, one fix, one refactor),
- a description that summarises the change,
- linked spec / issue / ADR,
- a test plan,
- screenshots / before-after for UI,
- notes on follow-ups.

Forbidden:

- PRs that mix unrelated changes,
- PRs that drag on for weeks while `main` evolves,
- PRs with no description.

---

## Step 6 — Merge strategy

Pick **one** per repo and stick with it:

- **squash merge** — keeps `main` linear; PR becomes one
  commit. Default for most repos.
- **rebase merge** — preserves PR commits onto `main`. Use
  when commits are individually meaningful and have been
  curated.
- **merge commit** — preserves a merge bubble. Acceptable for
  some monorepo / library workflows; usually noisier than
  helpful.

Forbidden:

- squashing rebase-meant repos,
- rebasing squash-meant repos,
- merge commits with default messages ("Merge branch …").

---

## Step 7 — Required gates

A PR merges only when:

- all required CI checks are green,
- ≥ 1 human reviewer (not the author) has approved,
- code-owners (sensitive areas: auth, payments, schema, infra)
  approved,
- branch is up to date with `main` (auto-rebased OK),
- conversations resolved.

Self-merge of one's own PR is forbidden in production
repositories.

---

## Step 8 — Reverts

Reverting is a normal action, not a failure:

- revert via `git revert` (preserves history),
- the revert PR includes a brief note ("reverting because
  …"),
- a follow-up issue captures the actual fix plan.

Forbidden:

- "force-push to undo" on shared branches,
- silent reverts with no rationale.

---

## Step 9 — Bisect-friendly history

Practices that keep `git bisect` cheap:

- small commits,
- each commit compiles and passes tests,
- refactors and behavior changes split,
- monorepos: prefer paths that let bisect run a focused subset
  of tests.

A commit that breaks the build "for now" is the commit that
makes future bisects impossible.

---

## Step 10 — Tagging

For repos that release artifacts:

- tags are immutable (`v1.2.3`),
- tag from `main` (or release branches),
- annotated tags with release notes,
- forbidden: deleting / re-creating tags after they have been
  pushed.

For library releases see skill `release-strategy`.

---

## Step 11 — Hooks (optional but recommended)

Pre-commit / pre-push hooks run cheap checks locally:

- formatter,
- lint,
- secret scanner,
- conventional-commit message check.

Hooks are advisory, not authoritative — CI is the gate. Bypass
flags (`--no-verify`) are forbidden by default; their use is
reviewed.

---

## Step 12 — Working with rebases

- `git rebase -i` for cleaning up a branch before review,
- `git pull --rebase` for daily updates,
- never rebase a public / shared branch others may have based
  work on,
- if a public rebase is unavoidable, communicate before
  force-pushing.

---

## Forbidden

- direct push / force-push to `main`,
- merge of red CI,
- self-merge in production repos,
- "WIP" commits in merged history,
- empty / lazy commit messages,
- PRs that bundle unrelated changes,
- editing tags after release,
- `--no-verify` for skipping pre-commit hooks without a written
  reason,
- amending or rebasing commits already pushed to a shared
  branch others may have based work on.

---

## When this skill says STOP

- a PR is over ~1000 lines and not splittable → split before
  review (the reviewer cannot do this work for you),
- a commit message is "fix" → rewrite before pushing,
- the branch has been alive for a week → rebase or merge today.

History is the audit trail of why the system is what it is.
Treat it like one. The next engineer to bisect a regression
will thank you — that engineer is, often, you.
