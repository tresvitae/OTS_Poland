---
name: Adventure OTS Workspace Instructions
description: "High-signal Copilot routing instructions for Adventure OTS. Use when: deciding which agent/instruction to apply for backend, frontend, nginx, Docker, gameplay scripts, or cross-component work."
applyTo: "**"
---

# Adventure OTS Project Workspace Instructions

Adventure OTS is a multi-component Tibia project (Protocol 10.98) with:
- TFS 1.4.2 game engine,
- MariaDB database,
- Node.js + TypeScript backend,
- Next.js + Tailwind frontend,
- Nginx reverse proxy,
- Python orchestration agents.

## Routing Guide

Use this matrix to choose the right specialization quickly.

| Task | Primary Agent | Primary Instruction |
|------|---------------|---------------------|
| Backend API, DB query, auth flow | `AAC Full-Stack TypeScript Engineer` | `.github/instructions/backend.instructions.md` |
| Frontend page/component UX work | `UI/UX Master - Adventure OTS` | `.github/instructions/frontend.instructions.md` |
| Tailwind legacy workflows | `tailwind-ots-expert` (compatibility) | `.github/instructions/frontend.instructions.md` |
| Docker image/runtime stability | `docker-version-guardian` | `.github/instructions/containerization-docker-best-practices.instructions.md` |
| TFS Lua gameplay scripts | domain content agent | `.github/instructions/lua-scripts.instructions.md` |
| TFS C++ server changes | `C++ Expert` | `.github/instructions/cpp-server.instructions.md` |
| Cross-cutting planning | `tech-lead-orchestrator` | `.github/instructions/context-engineering.instructions.md` |

## Canonical Paths

- Backend: `adventure-ots/backend`
- Frontend: `adventure-ots/frontend`
- Nginx: `adventure-ots/nginx/nginx.conf`
- TFS C++: `adventure-ots/tfs/src`
- TFS Lua: `adventure-ots/tfs/data`

If older docs mention `aac-backend` or `aac-frontend`, treat those as legacy naming.

## Key Development Rules

1. Keep backend as source of business logic; keep frontend focused on UX and typed API consumption.
2. Keep API contracts explicit and stable.
3. Maintain TFS 1.4.2 schema compatibility in backend SQL.
4. Keep Docker changes reproducible and version-aware.
5. Avoid broad refactors outside requested scope.

## Nginx Integration Rule

When backend or frontend route behavior changes, verify proxy behavior in `adventure-ots/nginx/nginx.conf`:
- `/api/` routes to backend,
- everything else routes to frontend,
- headers and timeouts remain appropriate.

## Where To Find Operations Details

For compose commands, startup, debugging, and environment setup, use:
- `adventure-ots/README.md`
- service-level READMEs under `adventure-ots/backend`, `adventure-ots/frontend`, and `adventure-ots/nginx`.
