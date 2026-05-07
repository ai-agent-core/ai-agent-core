<!--
Thanks for the PR. A small, focused PR is reviewed faster than a large one.
Aim for under ~400 lines diff where possible.
-->

## Summary

<!-- One or two sentences. What does this change do, and why? -->

## Motivation

<!--
Why is this needed? What incident, recurring agent mistake, or gap motivated
it? If this PR adds a rule or skill, link to the situation it addresses.
-->

## Type of change

- [ ] New principle
- [ ] New rule (`rules/*_RULES.md`)
- [ ] New skill (`skills/<name>/SKILL.md`)
- [ ] Update to existing principle / rule / skill
- [ ] Bootstrap / migration tooling
- [ ] Routing (`ai/context_profiles.yaml`, `INDEX.md`, `ai/reading_order.yaml`)
- [ ] Documentation (README, CONTRIBUTING, etc.)
- [ ] Other

## Routing updates

If this PR adds or renames a rule / skill / principle, confirm the routing
is updated:

- [ ] `INDEX.md`
- [ ] `ai/context_profiles.yaml` (relevant `contributions.*` and
      `fallback.load_all`)
- [ ] `ai/reading_order.yaml` (when implementation-layer)
- [ ] `skills/README.md` (when adding / renaming a skill)

## Verification

- [ ] `bash init/bootstrap.sh` runs cleanly in a tmp dir.
- [ ] `bash init/migration.sh` runs cleanly in a tmp dir.
- [ ] CI smoke tests pass (will run automatically).
- [ ] All file references in `INDEX.md` and `context_profiles.yaml` resolve.

## Decision (for non-trivial changes)

If this is a one-way decision (vendor lock-in, breaking change to scaffold,
new rule family), link to the ADR:

<!-- docs/adr/NNNN-title.adoc or "n/a — reversible change" -->

## Anything reviewers should focus on?

<!-- Tricky bits, areas where you want a second opinion, follow-ups. -->
