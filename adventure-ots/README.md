# 🛡️ Adventure OTS — Docker Development Environment

Complete development environment for running a Tibia OTS server using Docker Compose.

## 🏗️ Stack

| Service | Container | Port | Description |
|---------|-----------|------|-------------|
| **MariaDB 10.11** | `ots_db` | `3306` | Database |
| **TFS 1.4.2** | `ots_engine` | `7171`, `7172` | Game engine |
| **Backend API** | `api` | `3001` (internal) | API (Node.js + TypeScript) |
| **Frontend** | `web` | `3000` (internal) | SPA website (Next.js + Tailwind) |
| **Nginx** | `proxy` | `80` | Reverse Proxy |

## 📂 Structure

```
adventure-ots/
├── docker-compose.yml          # Container orchestration
├── sql/
│   └── 02_seed_data.sql        # Admin account (1/1)
├── tfs/
│   ├── Dockerfile              # Build engine from source (Alpine)
│   ├── config.lua              # Docker configuration
│   ├── config.lua.dist         # Original configuration
│   ├── schema.sql              # TFS database schema
│   └── data/                   # Game data (maps, NPCs, spells…)
├── backend/
│   ├── Dockerfile              # Node.js 20 Alpine (multi-stage)
│   ├── package.json            # Express, mysql2, JWT, Helmet
│   └── src/                    # TypeScript API (routes, auth, db)
├── frontend/
│   ├── Dockerfile              # Next.js 14 standalone (multi-stage)
│   ├── package.json            # React 18, Tailwind CSS
│   └── src/                    # App Router (pages, components)
├── nginx/
│   ├── Dockerfile              # Nginx Alpine
│   └── nginx.conf              # Reverse proxy (/api → backend)
└── client/
    ├── Dockerfile              # OTClient Mehah
    ├── init.lua                # Entry point (setUniqueServer)
    └── data/things/            # ⚠️ Required Tibia assets
```

## 🚀 Quick Start

### Requirements
- Docker Desktop / Docker Engine + Docker Compose
- Minimum **4 GB RAM** for Docker
- Tibia assets (`.spr`, `.dat`) for protocol **10.98** placed in `client/data/things/1098/`

### Start

```bash
cd adventure-ots
docker compose up -d --build
```

> ⏱️ First run: **5–15 minutes** (TFS compilation from C++)

### Access

| Service | URL / Address |
|---------|---------------|
| **Website** | http://localhost |
| **API Backend** | http://localhost/api/health |
| **Game server** | `127.0.0.1:7171` (in client) |
| **Database** | `localhost:3306` |

> ✅ **Website status:** The website works correctly at `http://localhost`. Creating new users and saving to the database works correctly. These features are fully available after a container restart.

### Default account
- **Login:** `1`
- **Password:** `1`
- **Character:** `Admin` (GOD, level 100)

## 🔧 Configuration

### Database
Credentials (in `docker-compose.yml`, development defaults):
```
MYSQL_ROOT_PASSWORD: twoje_haslo
MYSQL_DATABASE: ots_baza
MYSQL_USER: forgottenserver
MYSQL_PASSWORD: tibia_pass
```

Schema and seed initialization order:
1. `tfs/schema.sql` -> mounted as `01_schema.sql`
2. `sql/02_seed_data.sql` -> mounted as `02_seed_data.sql`

Important:
- Init scripts run only on first DB volume creation.
- For seed and reinitialization details, see `adventure-ots/sql/README.md`.

### Game engine
Edit `tfs/config.lua`:
- `serverName` — server name
- `experienceStages` — experience stages
- `mapName` — map name (without `.otbm`)
- `ip` — for local Windows + Docker testing use `127.0.0.1` so character world connection resolves correctly

The RSA key (`key.pem`) is generated automatically when the `gameserver` container starts, if the file does not exist or is corrupted. The private key is persisted in Docker volume `tfs_keys` to prevent unexpected login handshake breakage after container recreation.

### Backend API
Environment variables (in `docker-compose.yml`):
- `JWT_SECRET` — change to a random string in production
- `DB_*` — database connection credentials

### Client
In `client/init.lua`:
```lua
EnterGame.setUniqueServer("127.0.0.1", 7171, 1098)
```

## 🛠️ Debugging

```bash
# Logs for all services
docker compose logs -f

# Start with debug profile (additional tools)
docker compose --profile debug up -d

# Logs for a specific service
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f nginx
docker compose logs -f gameserver
docker compose logs -f db

# Restart a service
docker compose restart backend

# Connect to the database
docker compose exec db mysql -uroot -pyour_password ots_baza

# Reset database (removes all data)
docker compose down -v
docker compose up -d --build
```

### Debug profile (Docker Compose)

A dedicated `debug` profile is defined in `docker-compose.yml`.

- Debug service: `adminer` (`ots_adminer`)
- Access: http://localhost:8081
- DB server in Adminer: `db`

Start the full environment with debug tools:

```bash
docker compose up -d --build
docker compose --profile debug up -d
```

Stop debug tools without stopping the main services:

```bash
docker compose --profile debug down
```

### Agent Debug (enhanced)

Agent file: `.github/agents/debug.agent.md`
Slash-command prompt: `.github/prompts/debug-ots.prompt.md`

The agent has been extended with:

- Docker-first workflow (reproduce, logs, hypotheses, verification)
- Checklist for common OTS problems (login, API, proxy, startup)
- Required final artefacts (proof of fix + no regression)
- Standardized final report format

This mode is recommended for issues such as: `ERROR 2`, `500 API`, `Connection refused`, `Map not found`.

Quick usage in GitHub Copilot Chat (VS Code):

```text
/debug-ots issue="Login ERROR 2 after character selection" context="account Patryk/test, stack running locally"
```

### Agent Database Workflow

For schema changes, seed updates, or SQL performance work:

- Agent: `.github/agents/mariadb.agent.md`
- Instruction: `.github/instructions/mariadb.instructions.md`

Use this path for MariaDB 10.11 and TFS 1.4.2 schema-compatible database tasks.

## ⚠️ Common issues

| Problem | Solution |
|---------|----------|
| TFS: "Connection refused" | DB is initializing — wait 30s, then `docker compose restart gameserver` |
| Client: `Connection failed. (ERROR 10061)` on login | `gameserver` is offline/refusing 7171. Check `docker logs -f ots_engine` and fix startup errors in `tfs/config.lua` |
| TFS: "Map not found" | Check `mapName` in `config.lua` vs files in `tfs/data/world/` |
| TFS: `config.lua: unexpected symbol near '#'` | Use Lua comments (`--`) instead of shell comments (`#`) in `tfs/config.lua`, then restart `gameserver` |
| TFS: "Missing RSA private key PEM header" | Remove old containers (`docker compose down`), optionally remove `tfs_keys` volume, and rebuild (`docker compose up -d --build`) |
| Client: `ERROR 2` + `End of file` during login | Usually RSA handshake mismatch; recreate `tfs_keys` volume and restart `gameserver`, then retest |
| Frontend: Blank page | `docker compose logs frontend` — check Next.js errors |
| API: 500 error | `docker compose logs backend` — check DB connection |
| Client: "Things not loaded" | Place `.spr`/`.dat` assets in `client/data/things/1098/` |
| DB: Missing tables | `docker compose down -v && docker compose up -d --build` |

## ✅ Login Incident Resolution Notes

The March 2026 local login incident was resolved with three coordinated fixes:

1. Stabilize and persist TFS RSA key (`tfs_keys` volume) and keep 10.98-compatible key size.
2. Align OTClient `OTSERV_RSA` public key with the active server private key used by `gameserver`.
3. Advertise local world IP via `ip = "127.0.0.1"` in `tfs/config.lua` for same-machine client/server testing.

Validation outcome: login server handshake succeeds, character list loads, and world login proceeds when `ots_engine` is online.
