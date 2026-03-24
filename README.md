# Adventure OTS
# OTS_Poland


# 🛡️ Tibia OTS Project - MVP (Protocol 10.98)

System for managing and deploying a Tibia Open Source (OTS) server based on **Docker** container architecture.

## 🏗️ System Architecture (Stack)

* **Game Engine:** The Forgotten Server (TFS) 1.4.2
* **Database:** MariaDB 10.11 (LTS)
* **Backend API:** Node.js + TypeScript + Express
* **Frontend SPA:** Next.js 14 + Tailwind CSS (Dark Fantasy RPG)
* **Reverse Proxy:** Nginx
* **Orchestration:** Docker Compose

---

## 📂 Project Structure

```text
.
├── adventure-ots/
│   ├── docker-compose.yml     # Main orchestration file
│   ├── sql/                   # Seed data (admin account)
│   ├── tfs/                   # Game engine (src, data, config.lua, schema.sql)
│   ├── backend/               # REST API (Node.js + TypeScript)
│   ├── frontend/              # SPA website (Next.js + Tailwind CSS)
│   ├── nginx/                 # Reverse Proxy
│   └── client/                # Configured OTClient Mehah
├── src/                       # Project scripts
├── docs/                      # Documentation
└── deploy/                    # Deployment configuration

```

---

## 🚀 Quick Start (First Run)

### 1. Prerequisites

Make sure you have the following installed:

* Docker Desktop (Windows/Mac) or Docker Engine (Linux).
* Minimum 4 GB RAM allocated to Docker.

### 2. Required Assets

Before the first run, place the Tibia **10.98** asset files in the client directory:

```
adventure-ots/client/data/things/1098/
  ├── Tibia.spr    # Sprite sheet (protocol 10.98)
  └── Tibia.dat    # Object definitions (protocol 10.98)
```

> ⚠️ **Missing these files** will cause the game client to display a "Things not loaded" error. Obtain verified 10.98 data files from the OTLand community.

### 3. Start

Open a terminal in the `adventure-ots` folder and run:

```bash
docker compose up -d --build
```

> ⏱️ *First run takes 5–15 minutes (C++ engine compilation).*
>
> ℹ️ The RSA key (`key.pem`) is generated automatically in the `gameserver` container at `tfs/key.pem` when the container starts, if the file does not exist or is corrupted.

### 4. Access

| Service | URL / Address |
| --- | --- |
| **Website** | http://localhost |
| **API Health Check** | http://localhost/api/health |
| **Game server** | `127.0.0.1:7171` (in client) |

### Default account
- **Login:** `1`
- **Password:** `1`
- **Character:** `Admin` (GOD, level 100)

---

## 🤖 Instructions for LangChain Agents

If you use AI agents for project development, pass them these guidelines:

1. **Context:** This project is a microservices system in Docker containers. Lua script changes → `/tfs/data`. API changes → `/backend/src`. UI changes → `/frontend/src`.
2. **Database:** Schema changes must be reflected in `tfs/schema.sql`. The backend connects directly to TFS tables.
3. **Connectivity:** All services communicate over the internal Docker network (hostname: `db`).
4. **Auth:** The backend uses JWT; passwords are stored as SHA1 hashes (compatible with TFS 1.4.2).

---

## 🛠️ Debugging & Logs

If something is not working, check the logs for the affected service:

| Problem | Command |
| --- | --- |
| **Engine not starting** | `docker logs ots_engine` |
| **API errors** | `docker logs api` |
| **Website errors** | `docker logs web` |
| **Proxy issues** | `docker logs proxy` |
| **Database issues** | `docker logs ots_db` |

### Common errors:

* **"Connection refused" (TFS):** The database is still initializing. Wait 30 seconds and restart the engine: `docker compose restart gameserver`.
* **"Map not found":** Check that the filename in `tfs/data/world/` matches `mapName` in `config.lua`.
* **Missing tables in database:** Make sure `schema.sql` is mounted during the first start.

---

## ✅ Current Run Status

* **Website** works correctly at `http://localhost`.
* **Registration:** Creating new users and saving to the database works correctly.
* **Note:** All features are fully available after a container restart.

---

## 📝 Roadmap

* [x] Deploy system (Backend + Frontend + Nginx)
* [ ] Import a finished map into `tfs/data/world/`.
* [ ] Change `JWT_SECRET` to a secure random string in production.
* [ ] Disable the Market module in OTClient.
* [ ] Test login with character `1/1` or one created via the website.


### Recent changes

- 2026-03-24 - fix: enhance RSA key management and error handling in Docker setup; fix: improve executable search logic and streamline packaging process; Small update Tibia client expert Agent.; replace downloadnig place of otclient; feat: add CODEOWNERS to enforce reviews from @tresvitae; feat: Add frontend for Adventur


### Client changes

- [Client] 2026-03-24 - fix: enhance RSA key management and error handling in Docker setup; feat: Add frontend for Adventure OTS with highscores, login, registration, and online player features; docs: add detailed README files for AAC frontend, Nginx reverse proxy, and SQL initialization; chore: remove outdated GitHub workflows a

