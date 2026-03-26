---
name: MariaDB Development
description: "MariaDB 10.11 LTS guidance for Adventure OTS. Use when: writing migrations, editing seed data, optimizing queries, validating schema compatibility, or troubleshooting DB connectivity. Covers: TFS 1.4.2 schema rules, safe migration patterns, idempotent seeds, and Docker Compose verification."
applyTo: "adventure-ots/sql/**,adventure-ots/docker-compose.yml,adventure-ots/backend/src/db.ts,adventure-ots/tfs/schema.sql"
---

# MariaDB Development Guidelines

**Location**: `adventure-ots/sql/`, `adventure-ots/docker-compose.yml`, `adventure-ots/backend/src/db.ts`

Adventure OTS uses MariaDB 10.11 with TFS 1.4.2-compatible schema semantics.

## Initialization Contract

Compose mounts scripts in strict order:
1. `./tfs/schema.sql` -> `/docker-entrypoint-initdb.d/01_schema.sql`
2. `./sql/02_seed_data.sql` -> `/docker-entrypoint-initdb.d/02_seed_data.sql`

Init scripts run only on first DB volume creation.

## Migration Policy

1. Use additive, backward-compatible changes by default.
2. Name migration files with stable ordering, for example: `03_add_feature_x.sql`.
3. For breaking changes, include explicit risk and rollback steps.
4. Validate against TFS schema expectations before merge.

## Seed Data Policy

1. Keep seed scripts idempotent (`ON DUPLICATE KEY UPDATE` where appropriate).
2. Do not hard-fail on re-application in development workflows.
3. Keep default admin/bootstrap rows development-only and documented.

## Query and Performance Rules

1. Use MariaDB SQL syntax and engine-compatible features.
2. Recommend parameterized query usage for backend integration.
3. Validate indexes for frequent lookup/join paths.
4. Use `EXPLAIN` for heavy queries before performance recommendations.

## Verification Commands

```bash
docker compose ps db
docker compose logs -f db
docker compose exec db mysql -uroot -p"$MYSQL_ROOT_PASSWORD" ots_baza -e "SHOW TABLES;"
```

## Safety Guardrails

1. Warn before destructive commands such as `docker compose down -v`.
2. Warn before table/column removal in core TFS tables.
3. Require rollback or recovery notes for risky schema operations.
