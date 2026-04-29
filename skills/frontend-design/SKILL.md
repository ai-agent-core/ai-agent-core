---
name: frontend-design
description: Resist the AI-template default in UI work. Every element must justify its existence; every composition must contain a deliberate point of strength.
---

# Frontend design

Use this skill **whenever you produce or modify UI / visual design**
— layouts, landing pages, components, copy, ornamentation,
information density. Authoritative rules:

- `agent-core/principles/FRONTEND_DESIGN_PHILOSOPHY.md`
- `agent-core/rules/FRONTEND_DESIGN_RULES.md`

This skill is the operational checklist; the rules are the law.

---

## The default failure mode

Without active resistance, AI agents converge on templates: correct
but weak, tidy but forgettable, plausible but hollow, recognisable
as "AI-generated." Template is the gravity. Every step below is a
counter-force.

---

## Pre-design clarification

Before designing, name in one sentence:

- The single audience.
- The posture the brief implies (restraint vs. deliberate chaos,
  cold precision vs. warm expression, dense vs. sparse, restrained
  ornament vs. assertive identity).

If you cannot, ask the user. "For everyone" is for no one.

---

## Element gate ("what breaks if removed?")

For every element on the page (label, number, gradient, icon,
column, divider), answer:

> If this element is removed, what breaks?

If the answer is not immediate and specific, the element is noise.
Cut it.

Common retrofit patterns to refuse:

- Decorative English-style section labels (FEATURES / WHY US / OUR
  MISSION) without a semantic role.
- 01 / 02 / 03 ornaments on items with no inherent order.
- Gradients, glassmorphism, blurs used only for "atmosphere."
- Icons placed to fill space next to short text.
- Symmetric three-column layouts chosen because three is tidy.

---

## Copy: concrete beats abstract

Refuse vocabulary that signals AI-template output:

- Innovative / Next-Generation / Smart / Seamless
- 革新的 / 効率化 / 最適化 / シームレス

Prefer specific numbers, named use cases, proper nouns.

CTAs MUST describe the *resulting action*:

- ❌ "Learn More" / "Get Started"
- ✅ "Try free for 5 minutes" / "Generate your invoice now"

---

## Composition: at least one anchor of strength

Polish is the floor; strength is the product. Every composition
MUST contain at least one deliberate, recognisable point of
strength. Tidiness alone is not an achievement.

Counteract the default toward symmetry and neutrality consciously.

---

## Sections are chapters, not cards

Sections MUST connect: problem → solution → outcome. Isolated
feature blocks placed in sequence without narrative coherence are
forbidden, even if each block is individually correct. A page is a
story, not a catalog.

---

## UX is human factors

UX decisions cite a named human-factor principle:

- Fitts's law — target size and distance drive acquisition time.
- Hick's law — more choices → more decision latency.
- Cognitive load — working memory is bounded.
- F / Z scanning patterns — visual flow is predictable.
- Tap-target floor — 44 × 44 pt minimum.

"It feels usable" is not a justification.

---

## Completion gate

Before declaring the design done, every answer must be yes:

1. Is this distinguishable from template output?
2. Can the audience be named in one sentence?
3. Does the composition contain at least one deliberate anchor of
   strength?
4. Does every element survive the "what breaks if removed?" test?
5. Do sections form a narrative, not a list?
6. Is every UX decision backed by a named human-factor principle?

Any "no" blocks completion. No exceptions.

---

## Verification

For browser-rendered output, open the feature in a browser, take a
screenshot, and compare it to the brief. Iterate on the artifact,
not on the description of the artifact.
