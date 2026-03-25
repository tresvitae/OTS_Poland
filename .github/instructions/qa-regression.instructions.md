---
name: QA Regression Validation
description: "Regression-focused validation guidance for Adventure OTS. Use when: verifying backend/frontend/nginx/gameplay changes, executing smoke checks, and reporting reproducible pass/fail evidence."
applyTo: "adventure-ots/**,.github/workflows/**"
---

# QA Regression Validation Guidelines

Use these rules for post-change verification and release confidence checks.

## Validation Priorities

1. Confirm the changed behavior works as intended.
2. Check adjacent surfaces most likely to regress.
3. Report evidence in a reproducible command-driven format.

## Baseline Smoke Checklist

1. Service status snapshot (`docker compose ps`).
2. Backend health endpoint check.
3. Frontend reachability check.
4. Nginx API vs frontend route behavior check.
5. Targeted check for the specific feature touched.

## Reporting Format

For each check, include:
1. Command or action performed.
2. Expected result.
3. Actual result.
4. Pass/Fail outcome.

## Regression Guardrails

1. Treat missing verification evidence as unresolved risk.
2. Call out known gaps (for example missing automated tests).
3. Distinguish confirmed defects from assumptions.
4. Provide a clear go/no-go recommendation when asked.
