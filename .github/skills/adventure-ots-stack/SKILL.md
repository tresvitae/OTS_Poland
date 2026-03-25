---
name: adventure-ots-stack
description: 'Dedicated architecture skill for Adventure OTS. Use when: planning or debugging cross-component changes spanning TFS 1.4.2, backend API, frontend, nginx, MariaDB, and Docker Compose.'
license: MIT
---

# Adventure OTS Stack

Use this skill to reason about the full platform as one system.

## When to Use

- Cross-component feature work (backend + frontend + nginx)
- Integration incidents (login/API/proxy/service startup)
- Local environment orchestration and dependency checks
- Route flow validation (`/api` vs frontend)
- Stack-level documentation or architecture updates

## System Map

- TFS 1.4.2 game server: `adventure-ots/tfs`
- Backend API (Node.js + TypeScript): `adventure-ots/backend`
- Frontend (Next.js + Tailwind): `adventure-ots/frontend`
- Reverse proxy (nginx): `adventure-ots/nginx`
- Database (MariaDB): compose service `db`
- Orchestration: `adventure-ots/docker-compose.yml`

## Workflow

1. Identify affected services and paths.
2. Confirm contract boundaries (API schema, proxy routes, DB expectations).
3. Apply minimal scoped changes in each component.
4. Validate end-to-end behavior through docker compose smoke checks.

## Guardrails

- Keep TFS schema compatibility.
- Treat backend API contracts as frontend source of truth.
- Preserve nginx routing rule: `/api` to backend, non-API to frontend.
- Avoid unrelated refactors during integration fixes.

## Output Contract

1. Components touched
2. Integration impact
3. Verification evidence
4. Residual risk
