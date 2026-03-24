# SQL (Adventure OTS)

This directory contains database initialization data used by Docker Compose during first MariaDB startup.

## Purpose

- Provide post-schema seed data for Adventure OTS
- Bootstrap a default admin account and character
- Keep startup deterministic for local/dev environments

## Contents

```text
sql/
├── 02_seed_data.sql   # Seed script executed after TFS schema
└── README.md
```

## Initialization Order

In Compose, MariaDB mounts two init scripts in order:

1. `./tfs/schema.sql` -> `/docker-entrypoint-initdb.d/01_schema.sql`
2. `./sql/02_seed_data.sql` -> `/docker-entrypoint-initdb.d/02_seed_data.sql`

Order matters:

- `01_schema.sql` creates tables (`accounts`, `players`, etc.)
- `02_seed_data.sql` inserts initial rows into those tables

## What 02_seed_data.sql Inserts

### 1) Default admin account

- `id`: `1`
- `name`: `1`
- `password` (SHA1): `356a192b7913b04c54574d18c28d46e6395428ab`
- `type`: `5` (admin role in account table semantics)
- `email`: `admin@adventure.ots`

Plain credentials for local/dev bootstrapping:

- login: `1`
- password: `1`

### 2) Default admin character

- `name`: `Admin`
- `group_id`: `6` (GOD)
- `account_id`: `1`
- high starting stats suitable for administration/testing

### Idempotency behavior

Both inserts use:

- `ON DUPLICATE KEY UPDATE ...`

This avoids hard failure if rows already exist with the same unique keys.

## Important Runtime Behavior

MariaDB init scripts in `/docker-entrypoint-initdb.d` run only when database volume is initialized for the first time.

That means:

- Editing `02_seed_data.sql` will not affect an already initialized database volume.
- To re-run seed scripts, you must recreate DB volume.

## Reinitialize Database (Development)

From `adventure-ots/`:

```bash
docker compose down -v
docker compose up -d --build db
```

Then start full stack if needed:

```bash
docker compose up -d --build
```

Warning:

- `down -v` removes all DB data (destructive for persistent progress).

## Verify Seed Data

Option A: use Adminer (debug profile)

```bash
docker compose --profile debug up -d adminer
```

Open:

- http://localhost:8081

Option B: query MariaDB directly

```sql
SELECT id, name, type, email FROM accounts WHERE id = 1;
SELECT id, name, group_id, account_id, level FROM players WHERE name = 'Admin';
```

## Security Notes

- The default credentials (`1` / `1`) are for local/dev bootstrap only.
- Change or remove seeded admin credentials before exposing environment publicly.
- Keep production DB secrets in environment variables or secret management, not in seed scripts.

## Compatibility Notes

- Seed script targets TFS 1.4.2 schema conventions.
- Account passwords are stored as SHA1 hashes for compatibility with current backend/game auth setup.

