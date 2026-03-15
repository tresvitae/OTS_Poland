# Adventure OTS — Complete Docker Development Environment

Set up a fully working Tibia OTS development stack via Docker Compose: **MariaDB** (database), **TFS 1.4.2** (game server), **Apache/PHP + MyAAC** (website), plus client configuration for local play.

## User Review Required

> [!IMPORTANT]
> The TFS Dockerfile compiles from C++ source (Alpine multi-stage build). This takes **5-15 minutes** on first `docker compose build`. Subsequent builds use cache.

> [!IMPORTANT]
> The client `data/things/` directory is empty — you will need to place Tibia `.spr` and `.dat` files (matching protocol 1098/client 10.98) there manually for the client to work. The Docker setup handles server + website only.

> [!WARNING]
> Protocol version `1098` is set in the client [init.lua](file://wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/client/init.lua). Make sure your Tibia game assets match this version.

## Proposed Changes

### Database (MariaDB)

#### [NEW] [docker-entrypoint-initdb.d/](file:///wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/sql/)
- Create [sql/](file://wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/tfs/schema.sql) directory with a combined init script that imports [tfs/schema.sql](file://wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/tfs/schema.sql)
- MariaDB will auto-run [.sql](file://wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/tfs/schema.sql) files from this directory on first start

---

### Game Server (TFS)

#### [NEW] [config.lua](file:///wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/tfs/config.lua)
- Copy from [config.lua.dist](file://wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/tfs/config.lua.dist) with Docker-specific changes:
  - `ip = "0.0.0.0"` (listen on all interfaces in container)
  - `mysqlHost = "db"` (Docker service name)
  - `mysqlUser = "forgottenserver"` / `mysqlPass = "tibia"` / `mysqlDatabase = "forgottenserver"`
  - `serverName = "Adventure OTS"`

---

### Website (Apache + PHP + MyAAC)

#### [NEW] [Dockerfile](file:///wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/www/Dockerfile)
- Based on `php:8.2-apache`
- Enable `mod_rewrite`, install `pdo_mysql` extension
- Install Composer dependencies
- Copy MyAAC source to `/var/www/html`
- Set proper permissions for `system/cache`, `system/logs`, `system/php_sessions`

#### [NEW] [config.local.php](file:///wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/www/config.local.php)
- MyAAC configuration file pointing to MariaDB service (`db`) and TFS server path
- Sets `server_path` to `/srv/` (the TFS volume mount inside www container)

#### [NEW] [.htaccess](file:///wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/www/.htaccess)
- Copy from [.htaccess.dist](file://wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/www/.htaccess.dist) for Apache URL rewriting

---

### Docker Compose

#### [MODIFY] [docker-compose.yml](file:///wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/docker-compose.yml)
Three services:

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| `db` | `mariadb:10.11` | `3306:3306` | Database |
| `gameserver` | Built from `./tfs` | `7171:7171`, `7172:7172` | TFS game engine |
| `website` | Built from `./www` | `80:80` | MyAAC web panel |

- Shared `db_data` volume for persistent MariaDB storage
- [sql/](file://wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/tfs/schema.sql) directory mounted as MariaDB init scripts
- TFS `config.lua` bind-mounted into the container
- TFS `data/` shared with website container (for MyAAC to read `config.lua`)
- Health checks on `db` so `gameserver` and `website` wait for DB readiness

---

### Client

#### [MODIFY] [init.lua](file:///wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/client/init.lua)
- Add `EnterGame.setUniqueServer("127.0.0.1", 7171, 1098)` after `loadModules()` call
- This hardcodes the client to connect to the local server on port 7171 with protocol 1098

---

### Documentation

#### [NEW] [README.md](file:///wsl.localhost/Ubuntu/home/tresvitae/tibia/adventure-ots/README.md)
- Prerequisites (Docker, Docker Compose, Tibia assets)
- Quick start: `docker compose up --build`
- Service access URLs (website: `http://localhost`, game: `127.0.0.1:7171`)
- Default credentials
- Client setup instructions
- Troubleshooting section

## Verification Plan

### Automated Tests
1. **Docker Compose config validation**: Run `docker compose -f docker-compose.yml config` to validate the YAML syntax and service definitions
2. **Dockerfile syntax**: Verify both Dockerfiles can be parsed by running `docker compose build --dry-run` (if available)

### Manual Verification
- After `docker compose up --build`:
  1. Verify MariaDB starts and schema is imported: `docker compose exec db mysql -uforgottenserver -ptibia forgottenserver -e "SHOW TABLES;"`
  2. Verify TFS connects to DB and starts: Check `docker compose logs gameserver` for "The Forgotten Server" startup message
  3. Verify website is accessible: Open `http://localhost` in browser — should show MyAAC install wizard or homepage
  4. Verify client connects: Launch OTClient, it should auto-target `127.0.0.1:7171`
