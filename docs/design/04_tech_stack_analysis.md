# Technology Stack — Final Decision & Analysis

> **SDLC Stage 2: Design — Document 04**
> Updated: 2026-03-07 — MVP-focused stack analysis

---

## 1. Final Stack (MVP)

| Layer | Technology | Version | Role |
|-------|-----------|---------|------|
| **OS** | Ubuntu Server | 24.04 LTS | VPS + local dev |
| **Orchestration** | Docker Compose | v2 | Container management |
| **Game Server** | The Forgotten Server (TFS) | **1.4.2** | Game engine (C++) |
| **Protocol** | Tibia Protocol | **10.98** | Client ↔ server |
| **Game Client** | OTClient Mehah | Latest | Player client (**market module OFF**) |
| **Database** | MariaDB | 10.11 | Data store |
| **Web Server** | Nginx | Latest | Reverse proxy + **HTTPS termination** |
| **Web Runtime** | PHP | **8.2** | AAC backend |
| **Web App** | MyAAC | Latest (1.x) | Account management (MVP website) |
| **TLS** | Let's Encrypt + Certbot | Latest | **Free HTTPS certificate** (auto-renew) |
| **Scripting** | Lua | 5.2+ (bundled) | Game content |

---

## 2. Why TFS 1.4.2 (Not Nekiro TFS 1.5 Downgrades)

> [!IMPORTANT]
> **Nekiro's `TFS-1.5-Downgrades` does NOT support protocol 10.98.** It only has branches for:
> - 7.72
> - 8.0
> - 8.60
>
> The project is also **discontinued** (August 2022). Using it for 10.98 would require writing a custom protocol downgrade from scratch — a massive, risky undertaking that contradicts our MVP approach.

### Decision Matrix

| Criteria | TFS 1.4.2 (Official) | Nekiro 1.5 Downgrades | TFS 1.6 (Latest) |
|----------|----------------------|-----------------------|-------------------|
| **Protocol 10.98** | ✅ **Native support** | ❌ No 10.98 branch | ❌ Targets 12.x+ |
| **Stability** | ✅ Official stable release | ⚠️ Discontinued base | ⚠️ Newer, less tested |
| **Community scripts** | ✅ Enormous library | ❌ Minimal | ⚠️ Limited |
| **MyAAC compatibility** | ✅ Native | ⚠️ Schema differs | ⚠️ Schema differs |
| **OTClient Mehah** | ✅ Confirmed working | ❓ Untested combo | ✅ Primary target |
| **Datapack included** | ✅ Full | ❌ No datapack | ⚠️ Different format |
| **MVP risk** | 🟢 Low | 🔴 **High** | 🟡 Medium |
| **Protocol downgrade effort** | None needed | **Massive** (months of C++ work) | Massive |

> **Verdict for MVP:** **TFS 1.4.2** is the only sensible choice for protocol 10.98. It's stable, well-documented, compatible with all other components in our stack, and has the largest ecosystem of community scripts.

---

## 3. Compatibility Matrix

```
✅ = Confirmed   ⚠️ = Minor caveat   ❌ = Conflict
```

| A | B | Status | Notes |
|---|---|--------|-------|
| Ubuntu 24.04 | Docker Compose v2 | ✅ | Native support |
| Ubuntu 24.04 | TFS 1.4.2 compile | ✅ | Boost 1.83 included |
| TFS 1.4.2 | Protocol 10.98 | ✅ | **Native match** |
| TFS 1.4.2 | MariaDB 10.11 | ✅ | Drop-in MySQL replacement |
| OTClient Mehah | Protocol 10.98 | ✅ | Confirmed on Otland |
| OTClient Mehah | TFS 1.4.2 | ⚠️ | Market module → Canary only. **Turn it OFF** |
| MyAAC | PHP 8.2 | ✅ | PHP 8.1+ required, 8.2 patches merged |
| MyAAC | MariaDB 10.11 | ✅ | Works as MySQL replacement |
| MyAAC | TFS 1.4.2 schema | ✅ | Native support |
| Nginx | PHP 8.2 (php-fpm) | ✅ | Standard setup |
| Nginx | Let's Encrypt (Certbot) | ✅ | Free TLS cert, auto-renew every 90 days |

---

## 4. MVP Stack Rules

> Think **minimum effort, maximum stability.**

| Principle | Decision |
|-----------|----------|
| **Use official, stable releases** | TFS 1.4.2 (not forks, not discontinued projects) |
| **Don't modify C++ code** | All customization via Lua and config.lua |
| **Use battle-tested combos** | TFS 1.4.2 + 10.98 + OTClient Mehah = proven triple |
| **Turn off what you don't need** | Market module OFF, premium system OFF |
| **Pin versions** | Lock every component to exact version in Docker |
| **Prefer prebuilt where possible** | OTClient Mehah release binary, MariaDB Docker image |

---

## 5. OTClient Mehah — Market Module Disabled

The Mehah market module was rewritten to work with Canary (not TFS 1.4.2). For MVP:

**In OTClient Mehah `modules/` directory:**
```
modules/
  game_market/           ← DISABLE (rename to game_market.disabled)
```

**Or in `modules/game_market/game_market.otmod`:**
```yaml
enabled: false
```

Market is a "Could" priority feature (FR-15.4). Not needed for MVP. Players trade using the **secure trade window** (FR-15.2) which works perfectly.

---

## 6. Version Pinning (Docker)

```yaml
# docker-compose.yml
services:
  gameserver:
    build:
      context: ./server
    # TFS 1.4.2 pinned via git tag in Dockerfile

  database:
    image: mariadb:10.11       # pinned

  web:
    build:
      context: ./web
    ports:
      - "80:80"
      - "443:443"             # HTTPS
    volumes:
      - letsencrypt:/etc/letsencrypt
    # PHP 8.2-fpm + Nginx + Certbot pinned in Dockerfile

  certbot:
    image: certbot/certbot
    volumes:
      - letsencrypt:/etc/letsencrypt
      - ./web/webroot:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h; done'"

  backup:
    image: databack/mysql-backup

volumes:
  letsencrypt:
```

**Dockerfile (TFS):**
```dockerfile
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y \
  build-essential cmake git \
  libboost-all-dev libluajit-5.1-dev \
  libmysqlclient-dev libpugixml-dev libfmt-dev
RUN git clone --branch release-1.4.2 --depth 1 \
  https://github.com/otland/forgottenserver.git /srv/tfs
WORKDIR /srv/tfs/build
RUN cmake .. && make -j$(nproc)
```

**Dockerfile (Web):**
```dockerfile
FROM php:8.2-fpm-alpine
RUN docker-php-ext-install pdo_mysql mysqli
COPY ./myaac /var/www/html
```

---

## 7. Risks (MVP-Focused)

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| R1 | Mehah market module crashes with TFS 1.4.2 | 🟡 Medium | **Disable it** — already decided |
| R2 | RSA key mismatch (client ↔ server) | 🟡 Medium | Replace RSA keys on both sides during setup |
| R3 | PHP 8.2 deprecation warnings in MyAAC | 🟢 Low | Known patches exist; non-blocking |
| R4 | Missing Tibia.dat/Tibia.spr for 10.98 | 🟢 Low | Use verified 10.98 data files from community |
| R5 | TFS compile fail on Ubuntu 24.04 | 🟢 Low | Build inside Docker; Ubuntu 24.04 confirmed working |

---

## 8. Future Upgrade Path

| When | What | From → To |
|------|------|----------|
| Post-MVP (optional) | Protocol upgrade | 10.98 → 12.x (with Mehah) |
| Post-MVP (optional) | Server upgrade | TFS 1.4.2 → TFS 1.6 |
| Post-MVP (optional) | Re-enable market | Patch Mehah market for TFS |
| Post-MVP (optional) | Custom domain | Duck DNS → .xyz or .pl |

---

## 9. Verdict

> [!TIP]
> **Stack is locked for MVP. No conflicts. Ready for implementation.**

```
   OTClient Mehah (10.98, market OFF)
          │
     TCP :7171/:7172
          │
   ┌──────┴──────┐
   │ TFS 1.4.2   │◄──── Lua scripts + config.lua
   │ (10.98)     │◄──── map.otbm + spawns
   └──────┬──────┘
          │
          ▼
   ┌──────────────┐     ┌──────────────────┐     ┌──────────┐
   │ MariaDB      │◄───►│ MyAAC (PHP 8.2)  │◄───►│ Certbot  │
   │ 10.11        │     │ + Nginx          │     │ (LE TLS) │
   └──────────────┘     └────────┬─────────┘     └──────────┘
                                 │
                         HTTPS :443 (+ :80 redirect)
                                 │
                           Player Browser
```
