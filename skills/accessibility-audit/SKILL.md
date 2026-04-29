---
name: accessibility-audit
description: Audit a UI for WCAG 2.2 AA compliance — semantic markup, keyboard, screen-reader, contrast, motion, forms, media — with manual passes that automated tools miss.
---

# Accessibility audit

Use this skill **whenever a UI surface (web, mobile, email,
exported document) is being designed, reviewed, or audited**.

Authoritative source: `rules/ACCESSIBILITY_RULES.md` and
`principles/FRONTEND_DESIGN_PHILOSOPHY.md`.

Automated tools catch ~30% of issues. This skill is the manual
floor that catches the rest.

---

## Premise

Accessibility is correctness, not a discount feature. A UI that
fails for keyboard users, screen-reader users, low-vision users,
or motor-impaired users is a broken UI.

Default target: **WCAG 2.2 Level AA**.

---

## Step 1 — Automated pass

Run the automated checks first; they are cheap and catch the
trivial errors:

- web: `axe-core` / `pa11y` / `lighthouse`,
- mobile iOS: Accessibility Inspector,
- mobile Android: Accessibility Scanner,
- design tokens: contrast checker against WCAG ratios.

Triage findings before continuing — a noisy automated report can
mask the manual issues.

---

## Step 2 — Keyboard pass

Open the surface. Unplug or ignore the mouse. Try to:

- reach every interactive element with `Tab` / `Shift+Tab`,
- activate every interactive element with `Enter` / `Space`,
- close every overlay with `Esc`,
- read every text region without scrolling traps,
- complete each primary user flow keyboard-only.

Failures:

- elements unreachable by keyboard,
- focus order does not follow visual order,
- focus disappears (no visible focus ring) — fix even if
  designers asked for it,
- focus traps outside dialogs,
- modal dialogs without focus management.

A "no" on any primary flow blocks completion.

---

## Step 3 — Screen-reader pass

Pick at least one screen reader and walk every primary flow:

- VoiceOver (macOS / iOS),
- NVDA (Windows),
- JAWS (Windows),
- TalkBack (Android).

For each interactive element, the screen reader should announce:

- **role** (button, link, checkbox, dialog, list…),
- **name** (visible label, `aria-label`, or `aria-labelledby`),
- **state** (pressed, expanded, selected, disabled),
- **value** (when applicable: slider position, input contents).

Failures:

- icon-only buttons announced as "button" with no name,
- form fields without associated labels,
- modal dialogs not announced as dialogs,
- live regions silent (form errors / toasts not announced),
- semantic headings missing or out of order.

Test with the screen reader's *actual* behavior, not your
expectation of it.

---

## Step 4 — Contrast and color pass

- text contrast ≥ 4.5:1 (normal text), ≥ 3:1 (large text),
- non-text contrast ≥ 3:1 (icons, controls, focus indicators)
  against adjacent colors,
- color is never the only conveyance — combine with text /
  icons / patterns / position,
- disabled vs. enabled distinguishable to low-vision and
  color-blind users,
- both light and dark themes meet contrast,
- charts use color-blind-safe palettes; data also distinguished
  by label / shape / pattern.

Failures:

- error states distinguished only by red,
- success / failure conveyed only by color,
- dark-mode contrast not checked,
- charts unreadable in greyscale.

---

## Step 5 — Forms pass

For every form:

- every input has a visible, associated label,
- required fields marked in a way independent of color or
  asterisk alone,
- error messages associated with the field
  (`aria-describedby`), announced via live region, and
  *actionable* ("Enter at least 8 characters" beats "invalid
  input"),
- inline validation does not lock focus or block typing,
- autocomplete attributes set (`autocomplete="email"`,
  `autocomplete="cc-number"`),
- inputs respect input mode and type
  (`type="email"`, `inputmode="numeric"`),
- long forms split into manageable steps.

Failures:

- placeholder used as the only label,
- form erases input on validation failure,
- error message in a tooltip-only context.

---

## Step 6 — Touch / motor pass

For touch surfaces:

- tap targets ≥ 44 × 44 pt,
- adequate spacing between adjacent targets,
- drag-and-drop has a keyboard-accessible alternative,
- time limits avoidable, extendable, or warned-with-extension,
- pointer gestures (multi-touch, path-based) have single-pointer
  equivalents.

---

## Step 7 — Motion / vestibular pass

- respect `prefers-reduced-motion` — disable or reduce
  decorative animation when set,
- avoid auto-playing motion above the fold,
- no flashing > 3 Hz,
- parallax and large-area motion provided as opt-in or paired
  with reduced-motion equivalents.

---

## Step 8 — Zoom and reflow pass

- 200% zoom: layout still works, no horizontal scroll on text,
- text spacing override: line-height, letter-spacing, word-spacing
  do not break layout,
- mobile portrait / landscape both reflow correctly,
- minimum viewport width supported documented (typically 320 px).

---

## Step 9 — Language and reading pass

- `<html lang="...">` set; inline content in different language
  has `lang`,
- reading level appropriate to the audience,
- numbers, dates, times, currency formatted per locale,
- right-to-left support where required (`dir="rtl"`).

---

## Step 10 — Media pass

- video has captions (synchronized) for prerecorded,
- audio has transcript,
- audio description for video where visuals carry content not in
  audio,
- video controls keyboard-accessible,
- no auto-play with sound.

---

## Step 11 — Document outline pass

- one `<h1>` per page representing the main subject,
- heading levels form a logical outline (no jumps from `<h1>`
  to `<h3>` for styling),
- landmarks present (`<header>`, `<main>`, `<nav>`, `<footer>`,
  `<aside>`),
- skip-to-content link first in tab order.

---

## Step 12 — Real-user testing (high-stakes products)

Automated and manual checks catch most issues. For high-stakes
products (e-commerce checkout, banking, healthcare,
government), include real users with disabilities:

- recruit through specialist partners,
- compensate fairly,
- test the primary flows on the user's own assistive tech,
- document findings and iterate.

What the team imagines as "accessible" and what users experience
often diverge.

---

## Step 13 — Design-system leverage

Most accessibility wins compound through the design system. Audit:

- every primitive component has accessible name / role / state
  out of the box,
- focus-visible by default,
- contrast tokens meet AA,
- usage examples include keyboard interaction and screen-reader
  expectations,
- ARIA usage justified or absent.

A design system that ships inaccessible primitives breaks every
team that builds on it.

---

## Reporting findings

Structure the audit report:

```
[BLOCKER]   <one-line summary>           — page / component
[MAJOR]     <one-line summary>           — page / component
[MINOR]     <one-line summary>           — page / component
[QUESTION]  <one-line summary>           — page / component
```

For each item:

- WCAG criterion violated,
- assistive tech used to find it,
- smallest fix.

---

## Forbidden

- "Accessibility overlays" sold as a one-line fix — they break
  more than they fix and are an active liability.
- Removing focus styles globally without replacement.
- Decorative SVGs without `aria-hidden="true"`.
- Buttons rendered as anchors (or vice versa) for styling.
- Custom dropdowns / date pickers without full ARIA pattern.
- Tooltips holding the only label of an action.
- Pages whose only structure is divs with classnames.

---

## When this skill says STOP

- a primary flow is unusable keyboard-only → block completion,
- a critical action has no accessible name → fix before
  shipping,
- the design system primitives fail accessibility → fix at the
  primitive, not at every consumer.

Build for everyone, including the user who cannot see, cannot
hear, cannot use a mouse, has a slow brain day, or is on a
two-year-old phone.

There is no alternate accessible mode. The accessible path is
the same path.
