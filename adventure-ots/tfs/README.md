# TFS Engine (Adventure OTS)

This directory contains the game server engine for Adventure OTS, based on The Forgotten Server (TFS) 1.4.2.

The service is built from C++ source and runs in Docker as the core MMORPG server.

## Purpose

- Build and run TFS game server binary
- Load world map, monsters, NPCs, scripts, and game systems
- Connect to MariaDB schema used by TFS and backend API
- Expose game/login/status ports for Tibia clients

## Directory Overview

```text
tfs/
├── Dockerfile               # Multi-stage build for TFS binary and runtime image
├── docker-entrypoint.sh     # Runtime bootstrap (RSA key validation/generation)
├── config.lua               # Active server configuration (mounted in compose)
├── config.lua.dist          # Distribution/default template
├── schema.sql               # TFS database schema (mounted into MariaDB init)
├── key.pem.pub              # Public key reference
├── CMakeLists.txt           # Top-level CMake configuration
├── cmake/                   # CMake helper modules
├── src/                     # C++ engine source
└── data/                    # Lua scripts, XML, map, content assets
```

## Runtime Architecture

In Docker Compose:

- Service name: `gameserver`
- Container name: `ots_engine`
- Depends on healthy `db` service
- Exposed ports:
  - `7171` (login/status)
  - `7172` (game protocol)

Mounted volumes:

- `./tfs/config.lua` -> `/srv/config.lua`
- `./tfs/data` -> `/srv/data`
- `./tfs/schema.sql` -> `/srv/schema.sql`

Because `config.lua` and `data/` are bind-mounted, content/config changes are reflected in container filesystem immediately. Some changes still require service restart to take effect.

## Docker Build and Runtime

`Dockerfile` uses two stages:

1. Build stage (`ubuntu:22.04`)
	- Installs compiler toolchain and native dependencies
	- Builds `tfs` binary with CMake + Make
2. Runtime stage (`ubuntu:22.04`)
	- Installs runtime libraries only
	- Copies built `/bin/tfs`, `data/`, `*.dist`, `*.sql`, entrypoint

Container entrypoint:

- Runs `docker-entrypoint.sh`
- Validates persisted RSA key at `/srv/keys/key.pem`
- Regenerates a 1024-bit RSA private key if missing/invalid or incompatible
- Creates `/srv/key.pem` symlink for TFS runtime compatibility
- Starts server process with `exec /bin/tfs`

## Build System Notes

Top-level CMake currently sets:

- CMake minimum: 3.10
- Language standard: C++17
- Non-Windows warnings: `-Wall -Werror`
- Optional IPO/LTO when supported
- Optional LuaJIT selection via `USE_LUAJIT`

The project links against Boost, fmt, Crypto++, MariaDB client libs, Lua/LuaJIT, PugiXML, and Threads.

## Key Config (config.lua)

Adventure OTS overrides in active `config.lua` include:

- `ip = "127.0.0.1"` (local Docker + local client setup)
- `loginProtocolPort = 7171`
- `gameProtocolPort = 7172`
- `serverName = "Adventure OTS"`
- `motd = "Welcome to Adventure OTS!"`

Database settings (Compose network aware):

- `mysqlHost = "db"`
- `mysqlUser = "root"`
- `mysqlPass = "twoje_haslo"`
- `mysqlDatabase = "ots_baza"`

Gameplay rates/stages configured:

- EXP stages: `1-8 x7`, `9-20 x6`, `21-50 x5`, `51-100 x4`, `101+ x3`
- Rates: `rateSkill = 3`, `rateLoot = 2`, `rateMagic = 3`

Map configuration:

- `mapName = "forgotten"`
- Map files present in `data/world/`:
  - `forgotten.otbm`
  - `forgotten-spawn.xml`
  - `forgotten-house.xml`

## Data and Script Areas

Main content folders under `data/`:

- `actions/`
- `creaturescripts/`
- `globalevents/`
- `monster/`
- `movements/`
- `npc/`
- `spells/`
- `talkactions/`
- `weapons/`
- `scripts/`
- `lib/`
- `XML/`

Use these directories to extend gameplay systems, NPC behavior, spells, and world interactions.

## Database Integration

- TFS schema is defined in `schema.sql`
- MariaDB init mounts this file as `01_schema.sql`
- Additional seed data is mounted from `../sql/02_seed_data.sql` as `02_seed_data.sql`

This means first DB bootstrap creates schema and then seeds default admin account/character.

## Typical Commands

From `adventure-ots/`:

Start only DB + game server:

```bash
docker compose up -d --build db gameserver
```

Follow game server logs:

```bash
docker logs -f ots_engine
```

Restart game server after major config/content changes:

```bash
docker compose restart gameserver
```

## Troubleshooting

1. Connection refused on game port
	- DB may still be initializing.
	- Wait for DB healthcheck, then restart gameserver.

2. Map not found
	- Ensure `mapName` in `config.lua` matches files in `data/world/`.
	- Do not include `.otbm` extension in `mapName`.

3. DB auth/connection failures
	- Verify `mysqlHost`, `mysqlUser`, `mysqlPass`, `mysqlDatabase` in `config.lua`.
	- Confirm values match Compose environment for DB service.

4. Script/content changes not visible
	- Some Lua/data changes need restart even with bind mount.
	- Restart `gameserver` container.

5. Key.pem issues
	- Entrypoint auto-generates key when invalid/missing.
	- Key is persisted in Docker volume `tfs_keys` to avoid rotation on container recreation.
	- Check logs for key generation message.

6. OTClient login error `ERROR 2` / `End of file`
	- This usually indicates RSA handshake mismatch (not wrong credentials).
	- Ensure the server key is stable and 1024-bit (required for this 10.98 setup).
	- Recreate key volume and restart if needed:
	```bash
	docker compose down
	docker volume rm adventure-ots_tfs_keys
	docker compose up -d --build gameserver
	```

7. OTClient login error `ERROR 10061`
	- `gameserver` is not listening on login port (7171), usually because TFS failed during startup.
	- Check `docker logs -f ots_engine` for early config errors.
	- One common cause is invalid Lua comments in `config.lua`.
	- Use `--` comments, not `#` comments.

## Security and Operations Notes

- Current setup is optimized for local/dev containerized stack.
- Default DB credentials in project examples are not production-safe.
- Use strong secrets and hardened network/access controls for public deployments.

