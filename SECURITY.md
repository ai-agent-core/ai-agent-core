# Security Policy

Agent Core is a text-content governance framework — it ships principles,
rules, skills, and shell installers. There is no persistent service, no
network surface, and no credential storage in this repository.

The narrow security surface is therefore:

1. The bootstrap and migration shell scripts (`init/bootstrap.sh`,
   `init/bootstrap.cmd`, `init/migration.sh`, `init/migration.cmd`).
2. The CI workflows under `.github/workflows/`.
3. The integrity of distributed governance text (no malicious payload
   smuggled into a rule or skill that an agent might execute blindly).

## Reporting a vulnerability

Please open a private security advisory via GitHub:

> **Repository → Security → Advisories → "Report a vulnerability"**

If you cannot use that channel, open a minimal public issue asking for a
private contact and we will follow up out of band.

Please do **not** post exploit details in public issues, discussions, or
pull requests until a fix is available.

## What we treat as in scope

- Bootstrap / migration scripts: arbitrary code execution, path traversal,
  unintended deletion, secret exfiltration via stdout / stderr.
- CI workflows: secret leakage, supply-chain takeover via unpinned
  third-party actions or images.
- Governance content: instructions that, if followed by an automated
  agent, would weaken security posture (e.g. recommending insecure
  defaults).

## What we treat as out of scope

- Vulnerabilities in tools the user separately installs (Claude Code,
  Cursor, Copilot, etc.).
- Security findings inside example snippets used for illustration in
  rules / skills.
- Issues only reachable by a user deliberately running the scripts with
  elevated privileges in a way the documentation does not endorse.

## Response targets

- Acknowledge: within 5 business days.
- Fix or mitigation plan: within 30 days for high / critical severity.
- Coordinated disclosure preferred over silent fixes.

## Hardening recommendations for adopters

When you vendor Agent Core into a host project:

- Pin `agent-core` by commit SHA or git submodule, not a floating tag.
- Review the diff before upgrading.
- Run the smoke tests in CI on a clean checkout.
- Add `agent-core/generated/` to your host `.gitignore` if vendoring
  without a submodule (the migration script can do this for you).

Thanks for helping keep Agent Core safe to adopt.
