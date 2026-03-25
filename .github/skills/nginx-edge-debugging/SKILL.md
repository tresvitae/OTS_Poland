---
name: nginx-edge-debugging
description: 'Nginx edge and proxy troubleshooting for Adventure OTS. Use when: debugging routing, headers, timeouts, caching, and upstream connectivity between frontend/backend services.'
license: MIT
---

# Nginx Edge Debugging

Use this skill for reverse-proxy routing correctness and edge reliability.

## When to Use

- `/api` routing problems
- Frontend/backend reachability mismatches
- Header propagation issues (auth, forwarding)
- Timeout and caching anomalies
- Upstream 4xx/5xx incident investigation

## Workflow

1. Validate nginx config and route intent.
2. Verify upstream targets and response behavior.
3. Inspect logs and headers for mismatches.
4. Apply minimal config fix and re-validate key paths.

## Guardrails

- Keep `/api` to backend mapping unless explicitly changed.
- Preserve non-API to frontend routing behavior.
- Prefer explicit header directives for proxy-critical paths.
- Call out user-facing cache/timeout behavior changes.

## Output Contract

1. Route paths validated
2. Header/timeout findings
3. Applied config changes
4. Verification summary
