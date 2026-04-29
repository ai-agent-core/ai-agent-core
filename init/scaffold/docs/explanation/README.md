# Explanation

Understanding-oriented documentation. Explanation pages answer
"why is the system like this?" — they discuss concepts, trade-offs,
and the shape of the design.

## What belongs here

- Architecture overview ("how the system fits together").
- Conceptual primers on domain terms.
- Discussions of trade-offs that shaped the design.
- Background on why this technology / pattern was chosen (the WHY;
  the actual decision and its consequences belong in `../adr/`).

## What does NOT belong here

- Step-by-step instructions → `../tutorials/` or `../how-to/`.
- API tables → `../reference/`.
- Numbered, dated decisions → `../adr/`.

## Style

- Discursive. Allowed to take its time, since the goal is
  understanding.
- Diagrams encouraged (Mermaid, committed source preferred over
  binary images per `DOCUMENTATION_RULES.md`).
- Cross-link freely to ADRs, reference, and runbooks where the
  reader will go next.
