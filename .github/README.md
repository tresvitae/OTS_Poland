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

## Primary Agents

- `docker-version-guardian.agent.md`
	- Docker and runtime reproducibility guard for `Dockerfile*` and compose changes.

- `full-stack-engineer.agent.md`
	- Full-stack implementation for `adventure-ots/backend`, `adventure-ots/frontend`, and nginx-aware integrations.

- `ui-ux-master.agent.md`
	- Primary UI and UX specialist for frontend architecture, usability, accessibility, and interaction quality.

- `tailwind-css-expert.agent.md`
	- Compatibility shim for legacy Tailwind workflows.
	- Prefer `ui-ux-master.agent.md` for new work.

## Canonical Web Paths

- Backend: `adventure-ots/backend`
- Frontend: `adventure-ots/frontend`
- Nginx: `adventure-ots/nginx/nginx.conf`

Use backend/frontend naming consistently in all new customizations.

## Working Model

1. Pick agent by task domain.
2. Let matching instruction files provide file-level constraints.
3. Keep changes scoped to requested area.
4. Validate behavior after edits.

## Related References

- Workspace instructions: `.github/copilot-instructions.md`
- Authoring guidance for agents: `.github/instructions/agents.instructions.md`
- Context and structure guidance: `.github/instructions/context-engineering.instructions.md`
