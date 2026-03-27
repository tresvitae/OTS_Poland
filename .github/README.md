# .github Customization Hub

This directory contains Copilot customization assets for Adventure OTS:
- custom agents,
- instruction files,
- prompts,
- hooks,
- skills.

## Directory Map

- `agents/`: Specialized custom agents (`*.agent.md`)
- `instructions/`: File-scoped guidance (`*.instructions.md`)
- `prompts/`: Reusable slash prompts (`*.prompt.md`)
- `hooks/`: Workspace hook configuration
- `skills/`: Skill packs with focused workflows
- `copilot-instructions.md`: Always-on workspace routing guidance

## Agent Status

### Core

- `full-stack-engineer.agent.md`
- `api-game.agent.md`
- `ui-ux-master.agent.md`
- `docker-version-guardian.agent.md`
- `debug.agent.md`
- `expert-cpp-software-engineer.agent.md`
- `tibia-client-expert.agent.md`
- `tibia-knowledge-expert.agent.md`
- `lua-gameplay-content.agent.md`
- `nginx-edge-integration.agent.md`
- `qa-regression.agent.md`
- `tech-lead-orchestrator.agent.md`

### Optional

- `project-analyst.agent.md`
- `code-archeologist.agent.md`
- `readme.agent.md`
- `mariadb.agent.md`
- `git-workflow-master.agent.md`

### Deprecated

- `bootstrap-orchestrator.agent.md` (retire for day-to-day work; keep only for first-time bootstrap)

## Orchestrators

- `bootstrap-orchestrator.agent.md`
	- First-entry setup and bootstrap planner (deprecated for regular feature work).

- `tech-lead-orchestrator.agent.md`
	- Delegation-only coordinator for multi-component tasks.
	- Plans execution sequencing and routes work to existing specialists.

- `full-stack-engineer.agent.md`
	- Implementation-first coordinator with selective delegation.
	- Handles backend/frontend/nginx flow and hands off specialist subtasks when needed.

## Task-to-Agent Matrix

| Task | Preferred Agent |
|------|------------------|
| End-to-end backend/frontend feature | `full-stack-engineer.agent.md` |
| Backend API contract and route design | `api-game.agent.md` |
| Frontend UX and component architecture | `ui-ux-master.agent.md` |
| Lua gameplay scripts (spells/NPC/actions/events) | `lua-gameplay-content.agent.md` |
| Nginx proxy and edge behavior | `nginx-edge-integration.agent.md` |
| Regression and smoke validation | `qa-regression.agent.md` |
| Docker image/runtime stability | `docker-version-guardian.agent.md` |
| Runtime debugging and incident triage | `debug.agent.md` |
| TFS C++ server code | `expert-cpp-software-engineer.agent.md` |
| OTClient/OTCv8 work | `tibia-client-expert.agent.md` |
| Tibia/Open Tibia/OTS technical and community knowledge | `tibia-knowledge-expert.agent.md` |
| Database/schema/migrations | `mariadb.agent.md` |
| Documentation only | `readme.agent.md` |
| Git workflow issues | `git-workflow-master.agent.md` |

## Delegation Map (Current Workspace)

- Full stack web delivery: `full-stack-engineer.agent.md`
- API contract-heavy work: `api-game.agent.md`
- Frontend UX architecture: `ui-ux-master.agent.md`
- Lua gameplay content: `lua-gameplay-content.agent.md`
- Nginx edge and proxy integration: `nginx-edge-integration.agent.md`
- QA and regression validation: `qa-regression.agent.md`
- Docker/runtime stability: `docker-version-guardian.agent.md`
- Reproduce-first debugging: `debug.agent.md`
- TFS C++ server changes: `expert-cpp-software-engineer.agent.md`
- OTClient work: `tibia-client-expert.agent.md`
- Tibia/Open Tibia/OTS research and protocol context: `tibia-knowledge-expert.agent.md`
- Database/schema/migrations: `mariadb.agent.md`
- Documentation-only work: `readme.agent.md`
- Architecture discovery/risk mapping: `project-analyst.agent.md`, `code-archeologist.agent.md`
- Git workflow remediation: `git-workflow-master.agent.md`

## Canonical Web Paths

- Backend: `adventure-ots/backend`
- Frontend: `adventure-ots/frontend`
- Nginx: `adventure-ots/nginx/nginx.conf`
- Database: `adventure-ots/sql`, `adventure-ots/tfs/schema.sql`

Use backend/frontend naming consistently in all new customizations.

## Migration Note: Retiring bootstrap-orchestrator

Recommended phased retirement:
1. Keep `bootstrap-orchestrator.agent.md` only for first-time repository setup and initial Copilot bootstrapping.
2. Use `tech-lead-orchestrator.agent.md` for planning and delegation in ongoing development.
3. Use `full-stack-engineer.agent.md` for day-to-day implementation and specialist handoff.
4. Avoid routing normal feature/debug tasks through bootstrap once project baseline is established.

## Working Model

1. Pick agent by task domain.
2. Let matching instruction files provide file-level constraints.
3. Keep changes scoped to requested area.
4. Validate behavior after edits.

## Related References

- Workspace instructions: `.github/copilot-instructions.md`
- Authoring guidance for agents: `.github/instructions/agents.instructions.md`
- Nginx edge routing guidance: `.github/instructions/nginx-edge.instructions.md`
- MariaDB guidance: `.github/instructions/mariadb.instructions.md`
- QA regression guidance: `.github/instructions/qa-regression.instructions.md`
- Context and structure guidance: `.github/instructions/context-engineering.instructions.md`
