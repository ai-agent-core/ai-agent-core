# Frontend Design Rules

These rules translate Frontend Design Philosophy into
enforceable constraints.

Philosophy shapes taste.

Rules prevent regression.

Agents MUST apply these rules to every UI, visual, or
interaction decision.

---

# Enforcement Scope

These rules apply to:

- landing pages, marketing surfaces, product dashboards
- component design, layout, typography, color, motion
- copy and microcopy on user-facing surfaces
- any artifact that a human perceives

If a decision affects what a user sees, reads, or touches,
these rules apply.

---

# Prohibited Patterns

Each pattern below is a common AI-template default.

FORBIDDEN unless a concrete justification is recorded per the
Intent-Reading Procedure below.

## Layout

- three-column feature sections used as a reflex fallback
- fully centered page structures across every section
- card-first layouts (rounded rectangle + shadow) used everywhere
- hero → 3-column → CTA as a template scaffold
- fully symmetric, evenly-sized card grids
- whitespace added to "look spacious" with no narrative role

## Content

- abstract headlines without committed meaning
  - Innovative / Next Generation / Smart / Seamless / 革新的 / 最適化 / シームレス
- summary-style copy that refuses to commit to a specific user or outcome
- repeating identical sentence-ending patterns (e.g., every line closing with ～します)
- bullet lists used where prose would carry the meaning better

## Text Decoration

- English-style section labels without semantic role
  - FEATURES / WHY US / OUR MISSION / OUR VISION
- numerical prefixes on items with no inherent order (01 / 02 / 03)
- all-caps accent text used purely for "style"

## Visual

- gradients (notably purple → blue) used for "atmosphere" without intent
- glassmorphism, heavy blur, or frosted effects as a default aesthetic
- stock-style illustrations or icons with no narrative link to the content
- "icon + one-line label" blocks repeated as a filler pattern
- photography disconnected from the story the page is telling

## Information Architecture

- uniform visual weight across all information
- zero quantitative proof (numbers, named customers, concrete outcomes)
- unclear or missing primary action
- sections presented as independent cards rather than narrative steps

## UX and Motion

- animation used as decoration rather than as guidance
- fade or slide used as a reflex transition everywhere
- ignoring `prefers-reduced-motion`
- tap targets smaller than 44 × 44 pt on touch surfaces
- designs that rely on color alone to convey meaning
- body text contrast below WCAG AA (4.5:1 body, 3:1 large text)

## Call-to-Action

INSUFFICIENT — FORBIDDEN as final copy:

- "Learn More"
- "Get Started"
- "Click Here"
- any generic verb unattached to a concrete outcome

REQUIRED — CTA states the concrete result:

- "Try free for 5 minutes"
- "Generate your invoice now"
- "Download the full report (12 pages)"

---

# Intent-Reading Procedure

Before producing any surface, agents MUST execute these steps
in order.

## Step 1 — Name the Audience

State the target audience in a single sentence.

If the instructor did not specify, request clarification.

Do NOT assume a generic "everyone".

## Step 2 — Read the Posture

Identify the instructor's posture across these dimensions:

- **restraint vs. expression** — minimal, or assertive?
- **temperature** — cold precision, or warm emotion?
- **density** — dense information, or generous breathing room?
- **order vs. deliberate break** — clean grids, or intentional asymmetry?
- **ornament level** — spare, or rich?

Evidence sources:

- existing brand materials, site, or logo
- prior word choices in the brief
- adjacent products or references the instructor cites
- what the brief *omits* — silence carries meaning

If evidence is missing or contradictory, STOP and ask.

## Step 3 — Name the Anchor of Strength

Decide the single anchor of strength this surface will carry.

No composition ships without a named anchor.

## Step 4 — Draft the Narrative

Write the problem → solution → outcome arc as prose before
committing to sections.

Sections follow the narrative, not the reverse.

## Step 5 — Justify Each Element

For every planned element, record:

- its role in the narrative
- what breaks if the element is removed
- the human-factor principle it respects (if a UX decision)

Elements without a record MUST be removed.

---

# Pre-Commit Judgment Checklist

Before considering any surface complete, answer every item.

Any "no" blocks completion.

1. Can the audience be named in one sentence?
2. Can the posture be named across the five dimensions above?
3. Is there exactly one named anchor of strength?
4. Does every element survive the "what breaks if removed?" test?
5. Are all CTAs concrete about the resulting action?
6. Do sections form a narrative rather than a list?
7. Is every UX decision tied to a named human-factor principle?
8. Are accessibility minimums met — tap targets, WCAG AA contrast, reduced-motion?
9. Does the output differ clearly from a generic template baseline?

---

# Escalation Protocol

STOP and request clarification from the instructor when any of
the following occurs:

- the target audience cannot be named
- the posture cannot be read from available evidence
- no anchor of strength can be identified
- the narrative arc cannot be constructed

Do NOT ship a design to fill the gap.

Ambiguity surfaced early costs less than a templated deliverable.

---

# Core Directive

Template is the default.

These rules exist to break that default on every surface,
every time.
