# Documentation

This directory holds the project's documentation. Layout is the
**Diátaxis framework** plus ADRs and runbooks — the structure used by
Django, GitLab, Cloudflare, and others.

| Section          | Purpose                                                   | Audience question     |
| ---------------- | --------------------------------------------------------- | --------------------- |
| `tutorials/`     | Learning-oriented walkthroughs                            | "How do I get started?" |
| `how-to/`        | Task-oriented recipes                                     | "How do I X?"         |
| `reference/`     | Information-oriented technical descriptions               | "What is X?"          |
| `explanation/`   | Understanding-oriented discussions of concepts and design | "Why is it like this?" |
| `adr/`           | Architecture Decision Records                             | "Why did we decide X?" |
| `runbooks/`      | Operational procedures for alerts, deploys, incidents     | "What do I do when X happens?" |

The four Diátaxis quadrants are intentionally separate. A page that
mixes tutorial and reference helps no one. If a page does not fit a
quadrant cleanly, split it.

For governance on what gets documented and how, see
`ai-agent-core/rules/DOCUMENTATION_RULES.md`.

For the manifest declaring this layout, see `project.yml` at the
repo root.
