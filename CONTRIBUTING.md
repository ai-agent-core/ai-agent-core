# Contributing to AI Agent Core

Thanks for considering a contribution. AI Agent Core values **precision over
feature growth** — improvements to architectural safety, clarity,
determinism, or cross-agent consistency are warmly received. Adding rules
"just because" is not.

---

## Ways to contribute

| Kind                          | Where it lives           | When to add                                                 |
| ----------------------------- | ------------------------ | ----------------------------------------------------------- |
| New **principle**             | `principles/`            | A foundational belief not derivable from existing ones.     |
| New **rule**                  | `rules/`                 | A new enforceable invariant. Concrete, testable in review.  |
| New **skill**                 | `skills/<name>/SKILL.md` | A repeatable situation with its own playbook (≤300 lines).  |
| Updates to **routing**        | `ai/context_profiles.yaml` and `INDEX.md` | When you add or rename anything above. |
| Bootstrap / migration script  | `init/`                  | Layout changes between AI Agent Core versions.                 |
| README / CHANGELOG            | repo root                | User-visible changes.                                       |

---

## Before opening a PR

1. **Read the existing files.** Most "new rules" are sharper restatements of
   one already there.
2. **Run the smoke test locally:**

   ```bash
   bash init/bootstrap.sh   # in a tmp dir
   bash init/migration.sh
   ```

3. **Update routing** (`ai/context_profiles.yaml`, `INDEX.md`,
   `ai/reading_order.yaml`) when you add new files. CI verifies references.
4. **Update `skills/README.md`** if you added or renamed a skill.
5. **Commit message** explains the *why*. Why this rule? What incident or
   pattern motivated it?

---

## How to add a new rule

A `*_RULES.md` file is opinionated, terse, and enforceable. Structure:

```markdown
# <Name> Rules

<one paragraph problem statement>

For the principles behind these rules, see `principles/<...>.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# <Section 1>

<Concrete invariant>

Forbidden:
- <anti-pattern>

---

# Prime Directive

<one paragraph capturing the spirit>
```

Test: a stranger reading the rule should be able to enforce it in a code
review without further context.

---

## How to add a new skill

A skill is an **on-demand playbook** for a recognised situation. Don't write
a skill for every small task — write one for things the team handles
repeatedly the wrong way without it.

```markdown
---
name: skill-name
description: One sentence — used by Claude Code for skill discovery.
---

# <Skill name>

Use this skill **whenever <situation>**. Authoritative source: ...

## Step 1 — ...
## Step 2 — ...

## Forbidden
- ...

## When this skill says STOP
- ...

## Prime directive
<one paragraph>
```

Skills cite the authoritative `rules/` files; they do not duplicate them.

---

## How to add a new principle

Principles are rare. They live forever. Add one only when:

- it is foundational (every rule traces back to it),
- it is not derivable from existing principles,
- the team will defer to it in conflicts.

If you are not sure it qualifies, propose it as an issue first.

---

## Decisions

Significant additions (new rule families, vendor lock-in, breaking changes
to scaffold or context_profiles) come with an ADR — see skill
[`adr`](skills/adr/SKILL.md).

---

## Style

- Markdown, hard wrap around 80 chars where reasonable.
- Imperative mood for rules ("MUST", "SHOULD", "MAY", "Forbidden").
- Each file ends with a "Prime Directive" / "Core Directive" paragraph.
- No emoji in files (README aside) unless the user explicitly requests.

---

## Code of Conduct

Participation in AI Agent Core requires upholding the
[Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

---

## Licensing

Contributions are licensed under MIT (see [`LICENSE`](LICENSE)). By
submitting a PR you agree your contribution is offered under the same
terms.

---

## Thanks

AI Agent Core gets sharper with every well-grounded contribution. Even a tiny
PR — fixing a forbidden anti-pattern that lets bugs through, sharpening a
sentence that gets misread — meaningfully improves the agent runtime for
every team using it.
