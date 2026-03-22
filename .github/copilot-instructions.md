---
name: Adventure OTS Workspace Instructions
description: "Multi-component Tibia OTS server project (Protocol 10.98) with containerized microservices, game engine (TFS 1.4.2), backend API (Node.js), frontend (Next.js), Python LangGraph agents, and Docker Compose orchestration. Use when: developing any component; debugging deployment issues; implementing game features, API endpoints, or UI changes; extending the multi-agent orchestration system."
applyTo: "**"
---

# Adventure OTS Project Workspace Instructions

**Adventure OTS** is a private Tibia Open Source (OTS) server project for 5–10 players featuring a dark fantasy theme. It combines:
- **C++ Game Engine**: The Forgotten Server (TFS) 1.4.2 (Protocol 10.98)
- **Database**: MariaDB 10.11
- **REST API Backend**: Node.js + TypeScript + Express
- **Web Frontend**: Next.js 14 + Tailwind CSS (Dark Fantasy RPG theme)
- **Reverse Proxy**: Nginx
- **Orchestration**: Docker Compose + Python LangGraph multi-agent system

---

## 🚀 Quick Start

### Prerequisites
- **Docker Desktop** (Windows/Mac) or Docker Engine (Linux) with ≥4GB RAM allocated
- **Node.js 18+** (for local frontend/backend development, optional — also works in containers)
- **Python 3.11+** (for agent orchestration)

### Run All Services (First Time)
```bash
cd adventure-ots
docker compose up -d --build
# ⏳ Wait 5-15 minutes for TFS C++ compilation and database initialization
```

### Access Points
| Service | URL / Address |
|---------|---------------|
| **Frontend (AAC)** | `http://localhost` |
| **Backend Health Check** | `http://localhost/api/health` |
| **Game Server** | `127.0.0.1:7171` (in OTClient) |

### Stop All Services
```bash
docker compose down
```

---

## 📂 Project Structure

### Core Directories
- **`adventure-ots/`** — Main Docker Compose orchestration
  - `tfs/` — C++ game engine (TFS 1.4.2), Lua scripts, game data
  - `aac-backend/` — REST API (Node.js + TypeScript + Express)
  - `aac-frontend/` — Web UI (Next.js 14 + Tailwind CSS)
  - `nginx/` — Reverse proxy configuration
  - `sql/` — Database schemas and seed data
  - `client/` — OTClient V8 customized game client (C++)

- **`src/`** — Python agent orchestration (LangGraph + Anthropic Claude)
  - `agents/` — Backend, Frontend, Integration, Content, QA, Supervisor agents
  - `prompts/` — Agent system prompts
  - `tools/` — File I/O and XML parsing utilities
  - `config/` — Settings and environment configuration
  - `graph/` — LangGraph state machine and routing

- **`docs/`** — Project documentation
  - `design/` — Architecture, UI/UX, tech stack analysis
  - `research/` — Charter, requirements, technology analysis

---

## 🛠️ Development Commands

### Docker Compose (All Services)
```bash
cd adventure-ots

# Start all services in background
docker compose up -d --build

# View live logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f gameserver    # or: db, aac_api, aac_web, proxy

# Stop all services
docker compose down

# Restart a specific service
docker compose restart gameserver   # or: db, aac_api, aac_web, proxy
```

### Frontend Development (Next.js)
```bash
cd adventure-ots/aac-frontend

# Local dev server (hot-reload, proxies API via NEXT_PUBLIC_API_URL=/api)
npm run dev    # http://localhost:3000

# Production build
npm build

# Run production build locally
npm start
```

### Backend Development (Node.js + TypeScript)
```bash
cd adventure-ots/aac-backend

# Development with ts-node (hot-reload)
npm run dev    # http://localhost:3001 or configured port

# Build TypeScript to /dist
npm build

# Run production build
npm start
```

### Game Engine (TFS) — Logs Only
```bash
# TFS runs only in Docker, but you can inspect logs
docker logs -f ots_engine

# Common error patterns in logs:
# - "Connection refused" → Database still initializing (wait 30s, then restart)
# - "Map not found" → Verify mapName in tfs/config.lua matches file in tfs/data/world/
```

### Python Agent Orchestration
```bash
cd /root  # or wherever you run agents

# Configure environment
export ANTHROPIC_API_KEY="sk-..."
export LANGSMITH_API_KEY="..."  # Optional, for tracing

# Run agent supervisor
python src/main.py

# Run QA reviewer explicitly
python src/agents/qa_reviewer.py
```

---

## 🗝️ Key Development Patterns

### Game Content (Lua Scripts)
**Path**: `adventure-ots/tfs/data/`

Files here are mounted into the running TFS container at `/tfs/data`. Changes are **hot-reloaded** in most cases; for major changes, restart:
```bash
docker compose restart gameserver
```

Directories:
- `creaturescripts/` — NPC behavior, monster death handlers
- `spells/` — Spell definitions and effects
- `items/` — Item properties
- `npc/` — NPC dialogue and behavior
- `scripts/` — General Lua utilities

### Backend API Routes
**Path**: `adventure-ots/aac-backend/src/`

Structure:
- `auth.ts` — JWT authentication logic
- `db.ts` — Database connection (connects to `db` hostname on port 3306)
- `index.ts` — Express app setup
- `routes/` — API endpoint definitions

**Key convention**: Backend communicates with MariaDB using TFS schema directly (tables: `players`, `accounts`, `player_inventory`, etc.). All queries must be compatible with TFS 1.4.2 schema.

### Frontend Components & Pages
**Path**: `adventure-ots/aac-frontend/src/`

Structure:
- `app/` — Next.js 14 app router (pages, layouts)
- `components/` — React UI components
- `lib/` — Utilities, API client wrappers

**Key convention**: Dark Fantasy RPG theme using Tailwind CSS. All API calls must use `NEXT_PUBLIC_API_URL` (configured in `.env.local` or docker environment).

### Database Schema
**Path**: `adventure-ots/sql/schema.sql` and `adventure-ots/sql/02_seed_data.sql`

**Critical**: Changes to the TFS schema must be:
1. Added to `schema.sql` (runs on first container startup)
2. Verified against TFS 1.4.2 compatibility
3. Reflected in backend API route queries

Default seed data includes admin account (username: `1`, password: `1`).

### Python Agents
**Path**: `src/`

Agents are organized by domain (Backend, Frontend, Integration, Content, QA) and supervised by a top-level Supervisor. Each agent:
- Receives tasks from the Supervisor via LangGraph routing
- Uses Claude 3 Opus via LangChain for reasoning
- Operates on project files using file I/O and XML parsing tools
- Reports results back to the Supervisor

**Entry point**: `src/main.py`

---

## 🔗 Environment Variables

### Docker Compose (`.env` file at `adventure-ots/.env`)
```env
DB_PASSWORD=your_secure_password
MYSQL_ROOT_PASSWORD=same_as_above
MYSQL_DATABASE=tibia
MYSQL_USER=tibia_user
MYSQL_PASSWORD=same_as_DB_PASSWORD
JWT_SECRET=your_jwt_secret_here
NODE_ENV=development
```

### Python Agents
```bash
export ANTHROPIC_API_KEY="sk-..."
export LANGSMITH_API_KEY="..."          # Optional
export OPENAI_API_KEY="sk-..."          # If using OpenAI as fallback
```

---

## 🐛 Debugging & Common Issues

### Service Won't Start
```bash
# Check logs for the failing service
docker logs ots_engine      # Game engine
docker logs ots_db          # Database
docker logs aac_api         # Backend
docker logs aac_web         # Frontend
docker logs aac_proxy       # Nginx
```

### "Connection refused" for Game Server
**Cause**: Database not initialized yet.
```bash
# Wait ~30-60 seconds, then restart the game engine
docker compose restart gameserver
```

### "Map not found" Error in Game
**Cause**: Map filename mismatch in `config.lua` vs `tfs/data/world/` directory.
```bash
# Check configured map name
grep -i "mapName" adventure-ots/tfs/config.lua

# List available maps
ls adventure-ots/tfs/data/world/

# File names must match exactly (case-sensitive on Linux)
```

### Baked-In Defaults ⚠️
- **Default Admin Login**: username `1`, password `1` (SHA1 hashed in database)
- **Database Hostname**: `db` (internal Docker network only)
- **Frontend API Proxy**: `NEXT_PUBLIC_API_URL=/api`

### Frontend Won't Connect to Backend
Check:
1. Backend is running: `docker logs -f aac_api`
2. Port is exposed (usually 3001 or configured in docker-compose)
3. `NEXT_PUBLIC_API_URL` is set correctly in `.env.local` or docker-compose

### Python Agent Errors
Check ANTHROPIC_API_KEY is set and valid:
```bash
echo $ANTHROPIC_API_KEY
python -c "import anthropic; print(anthropic.__version__)"
```

---

## 📖 Additional Documentation

For architecture decisions, tech stack analysis, and detailed design docs, see:
- [Architecture Design](./docs/design/01_architecture_db.md)
- [UI/UX Design](./docs/design/02_ui_ux.md)
- [Tech Stack Analysis](./docs/design/04_tech_stack_analysis.md)
- [Project Charter](./docs/research/00_project_charter.md)
- [Requirements](./docs/research/03_requirements.md)

---

## 🤖 Agent Development Workflows

### When to Use the Python Agent System
The multi-agent LangGraph system (`src/main.py`) is designed to orchestrate multi-step development tasks:
- **Content Creation**: Write Lua scripts for NPCs, spells, items; Backend Supervisor → Content Agent
- **Backend Implementation**: Create API routes; Backend Supervisor → Backend Agent
- **Frontend Development**: Build React components; Frontend Supervisor → Frontend Agent
- **Integration**: SQL migrations, environment setup; Integration Agent
- **QA & Review**: Code review, testing; QA Agent

### Example: Add a New NPC
1. User describes NPC behavior to the Supervisor agent
2. Supervisor routes task to Content Agent
3. Content Agent writes Lua script to `tfs/data/npc/`
4. QA Agent reviews for compatibility with TFS 1.4.2
5. Report generated with changes

---

## ✅ Conventions & Best Practices

1. **Lua scripts** must be compatible with TFS 1.4.2 (strict Lua 5.1)
2. **Backend routes** use JWT tokens in `Authorization: Bearer <token>` header
3. **Database queries** must use TFS 1.4.2 schema table names exactly
4. **Frontend components** use Tailwind CSS utility classes (no inline styles)
5. **Commit messages** should reference component area: `[backend]`, `[frontend]`, `[tfs-content]`, `[agents]`
6. **Docker restarts** required after changes to: `config.lua`, `schema.sql`, `docker-compose.yml`

---

## 🚀 Next Steps

1. Run `docker compose up -d --build` to start the full stack
2. Visit `http://localhost` to verify the frontend loads
3. Check `http://localhost/api/health` to verify backend API
4. Use OTClient to connect to `127.0.0.1:7171` (default admin: `1` / `1`)
5. Explore `docs/` for architecture and design decisions
6. For AI-assisted development, use the Python agent CLI (`python src/main.py`)
