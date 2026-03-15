# Adventure OTS — Documentation

> SDLC-driven project documentation

## SDLC Stage 1: Research & Analysis ✅

| # | Document | Status |
|---|----------|--------|
| 00 | [**Project Charter**](00_project_charter.md) | 📋 Pending Approval |
| 01 | [Technology Requirements](01_technology_requirements.md) | ✅ Complete |
| 02 | [System Architecture](02_architecture.md) | ✅ Complete |
| 03 | [Requirements (Functional & Non-Functional)](03_requirements.md) | ✅ Complete |

## SDLC Stage 2: Design 📐

| # | Document | Covers |
|---|----------|--------|
| 01 | [Architecture & Database](design/01_architecture_db.md) | ER diagram, SQL schema, Docker Compose, data flow |
| 02 | [UI/UX Design](design/02_ui_ux.md) | Website wireframes, game client HUD, visual design |
| 03 | [Schedule & Backlog](design/03_schedule_backlog.md) | MVP scope, product backlog, Gantt timeline |

## SDLC Stage 3: Implementation 🛠️

| # | Component | Location | Status |
|---|-----------|----------|--------|
| 01 | [Multi-Agent System](../src/README.md) | `src/` | ✅ Struktura agentów |
| 02 | [Deploy & Architecture](../deploy/README.md) | `deploy/` | ✅ Architektura supervisora |
| 03 | Supervisor + QA Gate | `src/agents/supervisor.py`, `qa_reviewer.py` | ✅ Routing + kontrola jakości |
| 04 | Backend Team | `src/agents/backend/` | ✅ DevOps + Lua Scripter |
| 05 | Frontend Team | `src/agents/frontend/` | ✅ OTClient + Web/PHP |
| 06 | Integration Team | `src/agents/integration/` | ✅ World Integrator (XML) |
| 07 | Content Team | `src/agents/content/` | ✅ Lore & NPC Writer |
| 08 | LangGraph | `src/graph/` | ✅ Hierarchiczny supervisor |
| 09 | Narzędzia | `src/tools/` | ✅ File tools + XML parser |

> **Stack:** LangChain + LangGraph + Anthropic Claude + LangSmith Tracing
> **Mapa:** Pobrana gotowa (.otbm) — nie generowana przez AI