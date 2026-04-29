# Runbooks

Operational procedures. Every alert, every deployment, every recovery
procedure has a runbook. Runbooks are tested in calm times and used
in storms.

## Required sections per runbook

- **Symptoms** — what the alert / situation looks like.
- **Diagnosis** — first 3 things to check.
- **Mitigation** — actions to take, with required permissions.
- **Escalation** — who to page if the playbook does not resolve.
- **Known false positives** — when the alert lies.

## Naming

`<system>-<situation>.md` — for example `api-high-latency.md`,
`db-failover.md`, `auth-token-rotation.md`.

## Maintenance

A runbook that has not been used since it was written has probably
rotted. Review on every related change. The change that obsoletes
the runbook MUST update the runbook.

See `ai-agent-core/rules/DOCUMENTATION_RULES.md` and
`ai-agent-core/rules/OBSERVABILITY_RULES.md`.
