---
name: docker-compose-ops
description: 'Docker Compose operations for Adventure OTS services. Use when: starting/rebuilding stacks, checking health, investigating logs, handling service dependencies, and validating runtime behavior.'
license: MIT
---

# Docker Compose Ops

Use this skill for reliable local operations of the multi-service stack.

## When to Use

- Full stack bring-up and teardown
- Service rebuild and restart flows
- Runtime log triage by service
- Compose networking and health checks
- Data volume reset scenarios

## Workflow

1. Start or rebuild required services.
2. Verify container health and status.
3. Inspect logs for targeted services.
4. Confirm service connectivity and route reachability.

## Guardrails

- Call out data-loss risk before `down -v`.
- Avoid unnecessary no-cache builds.
- Prefer targeted restarts over full stack restarts.
- Keep compose operations aligned with documented service names.

## Output Contract

1. Commands run
2. Service state results
3. Errors and root cause clues
4. Recovery actions
