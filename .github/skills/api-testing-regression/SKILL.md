---
name: api-testing-regression
description: 'API smoke and regression validation skill for Adventure OTS. Use when: verifying auth/routes/contracts, checking status codes, and producing reproducible pass/fail evidence for backend changes.'
license: MIT
---

# API Testing Regression

Use this skill to verify backend behavior and prevent contract regressions.

## When to Use

- Backend route changes
- Authentication or authorization flow updates
- DB query and response-shape changes
- Pre-release smoke checks
- Bugfix verification with evidence

## Workflow

1. Define target endpoints and expected responses.
2. Execute smoke checks (health, auth, key routes).
3. Validate status codes and response contracts.
4. Report pass/fail results in reproducible form.

## Guardrails

- Keep tests deterministic and environment-aware.
- Distinguish contract breaks from transient runtime issues.
- Include both happy path and error-path checks.
- Do not mark green without evidence for changed endpoints.

## Output Contract

1. Scope of endpoints tested
2. Expected vs actual
3. Pass/fail per check
4. Regression risks
