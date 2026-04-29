# Accessibility Rules

Accessibility is not a discount feature for some users. It is a
correctness requirement: a UI that fails for keyboard users, for
screen readers, for users with low vision, motor impairment, or
cognitive load, is a broken UI.

These rules apply to every product surface (web, mobile, desktop,
emails, exports). Default target: **WCAG 2.2 Level AA**, with
Level AAA where the surface and audience warrant.

For the design philosophy behind, see
`principles/FRONTEND_DESIGN_PHILOSOPHY.md` and
`rules/FRONTEND_DESIGN_RULES.md`.

All instructions in this repository are subject to higher-priority
policies (system / developer / tool). If a conflict exists, follow
the higher-priority policy and report the conflict.

---

# Semantic Markup First

- Use the right HTML element for the job:
  `<button>` for actions, `<a>` for navigation, `<form>`,
  `<input>`, `<label>`, `<table>`, `<nav>`, `<main>`, `<article>`,
  `<header>`, `<footer>`.
- ARIA fills gaps. It does not replace semantic HTML.
  - First rule of ARIA: do not use ARIA when a native element
    would do.
- Heading levels (`h1` … `h6`) form the document outline. Skipping
  levels for visual styling is forbidden.
- Lists are `<ul>` / `<ol>` / `<dl>`, not divs styled to look
  like lists.

Forbidden:

- `<div onClick>` masquerading as a button,
- "click anywhere" pseudo-buttons,
- icon-only controls without an accessible name.

---

# Keyboard

Every interactive element MUST be:

- focusable in a logical order,
- operable with keyboard alone,
- visible-focused (focus indicator MUST NOT be removed without
  replacement),
- accessible without a mouse-only gesture (hover-only menus are
  forbidden as the only path).

Required:

- visible focus ring meets WCAG focus-visible contrast,
- skip-to-content link on each page,
- modal / dialog focus trapping with `Esc` to close,
- no focus traps outside dialogs.

Forbidden:

- positive `tabindex` values to "fix" tab order (fix the DOM
  instead),
- `tabindex="-1"` on elements that should be focusable.

---

# Screen Reader Compatibility

- Every interactive element has an accessible name (visible
  label, `aria-label`, or `aria-labelledby`).
- Form controls are associated with `<label>` (visible or
  visually hidden, never absent).
- Icon-only buttons have textual labels (visually hidden text or
  `aria-label`).
- Live regions (`aria-live="polite"` / `assertive`) announce
  asynchronous changes (form errors, search results, toasts).
- Decorative images use empty alt (`alt=""`); informative images
  have meaningful alt text.

Test with at least one screen reader (VoiceOver / NVDA / JAWS /
TalkBack) for any non-trivial flow. "It looks right" is not a
substitute.

---

# Color and Contrast

- Text contrast meets WCAG AA: 4.5:1 for normal text, 3:1 for
  large text.
- Non-text contrast (icons, controls, focus indicators) meets
  3:1 against adjacent colors.
- Color is never the only conveyance — combine with text, icons,
  patterns, position.
- Disabled vs. enabled states distinguishable to users with
  low vision and color blindness.
- Dark / light themes both meet contrast.
- Charts use color-blind-safe palettes; data is also distinguished
  by label, shape, or pattern.

Forbidden:

- error states distinguished only by red,
- success / failure conveyed only by color.

---

# Forms

- Every input has a visible, associated label.
- Required fields are marked in a way that does not depend on
  color or asterisk alone (use `required` attribute and labelled
  text).
- Error messages are:
  - associated with the field (`aria-describedby`),
  - announced (live region),
  - actionable (say what to fix, not "invalid input").
- Inline validation does not lock focus or block typing.
- Autocomplete attributes set (`autocomplete="email"`,
  `autocomplete="cc-number"`) for known fields.
- Inputs respect input mode and type (`type="email"`,
  `inputmode="numeric"`).
- Long forms split into manageable steps with clear progress.

Forbidden:

- placeholder used as the only label (disappears on input,
  insufficient contrast),
- forms that erase input on validation failure.

---

# Touch Targets and Motor Considerations

- Tap targets ≥ 44 × 44 pt minimum on touch devices.
- Adequate spacing between adjacent targets.
- Drag-and-drop has a keyboard-accessible alternative.
- Time limits on actions are avoidable, extendable, or
  warned-with-extension.
- Pointer gestures (multi-touch, path-based) have single-pointer
  equivalents.

---

# Motion and Vestibular

- Respect `prefers-reduced-motion` — disable or reduce
  decorative animation when the user has expressed the
  preference.
- Avoid auto-playing motion above the fold.
- No flashing more than 3 Hz (seizure risk).
- Parallax / large-area motion provided as an opt-in or paired
  with reduced-motion equivalents.

---

# Language and Reading

- `<html lang="...">` set on every page; `lang` attribute on
  inline content in a different language.
- Reading level appropriate to the audience; avoid unnecessary
  jargon.
- Numbers, dates, times, currency formatted per the user's
  locale.
- Right-to-left support where the audience requires it (proper
  bidi handling, `dir="rtl"`).

---

# Media

- Captions for prerecorded video (synchronized).
- Transcripts for audio.
- Audio description for video where the visual conveys content
  not in the audio track.
- Live media has captions where feasible (live captioning
  service or ASR with the limitation disclosed).
- Video controls are keyboard-accessible.

---

# PDFs, Emails, Exports

- PDFs include tags, reading order, language metadata; not just
  scanned images.
- HTML emails follow the same semantic / contrast / alt-text
  rules.
- Exported documents (CSV, Excel, slides) have logical structure
  (headers, names) that assistive tech can navigate.

---

# Mobile Native

- iOS: Dynamic Type, VoiceOver labels, adequate contrast,
  honor "Reduce Motion" / "Bold Text" / "Differentiate Without
  Color".
- Android: TalkBack labels, content descriptions, scaled text
  support, color and contrast per Material Design accessibility.
- Cross-platform: do not block accessibility features assuming
  a custom UI knows better.

---

# Testing and Tooling

- Automated checks in CI:
  - `axe-core` / `pa11y` / `lighthouse` for web,
  - platform-native linters where they exist,
  - color-contrast checks on design tokens.
- Manual checks before launch:
  - keyboard-only navigation through every primary flow,
  - screen reader pass on every primary flow,
  - zoom to 200% layout still works,
  - reduced-motion / high-contrast OS modes still work.
- Real-user testing with disabled users for high-stakes products.

Automated tools catch ~30% of issues. They are necessary, not
sufficient.

---

# Design System Discipline

The design system is the leverage point — getting it right
multiplies into every screen.

Required of components:

- accessible name, role, state out of the box,
- focus-visible styles by default,
- contrast tokens that meet AA without effort,
- examples include keyboard interaction and screen-reader
  expectations,
- ARIA usage justified or absent.

A design system that ships inaccessible primitives breaks every
team that builds on it.

---

# Process

- Accessibility review is a checklist on every design and PR
  that touches UI.
- Accessibility bugs are categorized and prioritized like any
  other bug — a critical accessibility bug is a critical bug.
- A11y owners exist (a person, a guild, a rotation), not
  "everyone is responsible therefore no one is."
- Customer-reported accessibility issues are first-class tickets
  with documented response times.

---

# Forbidden Anti-patterns

- Decorative SVGs without `aria-hidden="true"`.
- Removing focus styles globally (`*:focus { outline: none }`)
  without replacement.
- "Accessibility overlays" sold as a one-line fix; they break
  more than they fix and are an active liability.
- Buttons rendered as anchors (or vice versa) for styling.
- Custom dropdowns / date pickers that do not implement the full
  ARIA pattern.
- Tooltips that hold the only label of an action.
- Pages whose only structure is divs with classnames.

---

# Prime Directive

Build for everyone, including the user who cannot see, cannot
hear, cannot use a mouse, has a slow brain day, or is on a
two-year-old phone with low bandwidth. Inaccessibility is not a
deficit of the user — it is a defect of the product.

The accessible path is the same path. There is no alternate
mode.
