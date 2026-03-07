# Technology Stack Analysis & Compatibility

> **SDLC Stage 2: Design — Document 04**
> Compatibility analysis of the decided technology stack

---

## 1. Decided Stack

| Layer | Technology | Version | Role |
|-------|-----------|---------|------|
| **OS** | Ubuntu Server | 24.04 LTS | Host OS (VPS + local dev) |
| **Orchestration** | Docker Compose | v2 (latest) | Container management |
| **Game Server** | The Forgotten Server (TFS) | 1.4.2 | Game engine (C++) |
| **Protocol** | Tibia Protocol | 10.98 | Client ↔ server communication |
| **Game Client** | OTClient Mehah | Latest | Player-facing game client |
| **Database** | MariaDB | 10.11+ | Persistent data store |
| **Web Server** | Nginx | Latest | Reverse proxy + static files |
| **Web Runtime** | PHP | 8.2 or 8.3 | AAC backend |
| **Web App** | MyAAC | Latest (1.x) | Account management website |
| **Scripting** | Lua | 5.2+ (bundled in TFS) | Game content & logic |

---

## 2. Compatibility Matrix

```
✅ = Confirmed compatible   ⚠️ = Works with caveats   ❌ = Conflict
```

| Component A | Component B | Status | Notes |
|------------|------------|--------|-------|
| Ubuntu 24.04 | Docker Compose v2 | ✅ | Native support, ships in apt |
| Ubuntu 24.04 | TFS 1.4.2 (compile) | ✅ | Boost 1.83 included; install `libboost-locale-dev`, `libboost-json-dev` |
| TFS 1.4.2 | MariaDB 10.11 | ✅ | MariaDB is a drop-in MySQL replacement; TFS MySQL connector works |
| TFS 1.4.2 | Protocol 10.98 | ✅ | TFS 1.4.2 was built for 10.98 — native match |
| OTClient Mehah | Protocol 10.98 | ✅ | Confirmed working; Mehah supports 8.x through 13.x protocols |
| OTClient Mehah | TFS 1.4.2 | ⚠️ | Works, but Mehah's **market module** was rewritten for Canary only — disable or patch |
| MyAAC | PHP 8.2 | ✅ | v1.x explicitly supports PHP 8.1+; 8.2 fixes already merged |
| MyAAC | PHP 8.3 | ✅ | Community-confirmed working; minor deprecation warnings possible |
| MyAAC | MariaDB 10.11 | ✅ | Drop-in MySQL replacement; no schema issues |
| MyAAC | TFS 1.4.2 schema | ✅ | MyAAC natively supports TFS 1.x schemas |
| Nginx | PHP 8.x (php-fpm) | ✅ | Standard configuration; well-documented |
| Docker | MariaDB 10.11 | ✅ | Official Docker image: `mariadb:10.11` |
| Docker | TFS 1.4.2 | ✅ | Dockerfile compile from source inside container |
| Docker | Nginx + PHP-FPM | ✅ | Many base images available |

---

## 3. Component Deep Dive

### 3.1 OTClient Mehah (vs V8) — Why Mehah is Better

| Aspect | OTClient V8 | OTClient Mehah |
|--------|------------|----------------|
| **Status** | ❌ Discontinued (stable but no updates) | ✅ **Actively maintained** |
| **Protocol 10.98** | ✅ Native | ✅ Supported |
| **Protocol 12.x+** | ❌ Requires heavy patching | ✅ Native |
| **Rendering** | Good | **Better** (render optimization, anti-aliasing, floor shadowing) |
| **Features** | Lighting, pathfinding, outfit module | All of V8's + **protobuf, text scaling, idle animations, crosshairs** |
| **Battle module** | Slower | **Optimized** |
| **Community** | Lots of legacy modules | Growing ecosystem, TFS team endorses it |
| **Compilation (2025)** | Needs older libs, painful on modern OS | Compiles cleanly with modern toolchains |
| **Future-proof** | 🔴 Dead end | 🟢 Will support future protocols |

> **Verdict:** Mehah is the correct choice. It supports 10.98, is actively developed, and won't become a dead end if you upgrade protocol later.

### 3.2 TFS 1.4.2 on Ubuntu 24.04

**Confirmed working.** Ubuntu 24.04 ships Boost 1.83 which meets TFS requirements. Build dependencies:

```bash
sudo apt install -y \
  build-essential cmake git \
  libboost-all-dev libboost-locale-dev libboost-json-dev \
  libluajit-5.1-dev libmysqlclient-dev \
  libpugixml-dev libfmt-dev
```

> ⚠️ **Note:** Compile inside Docker (multi-stage build) to keep the host clean and ensure reproducibility.

### 3.3 MariaDB 10.11 with TFS

MariaDB 10.11 is an LTS release (supported until ~2028). Fully compatible with TFS's MySQL queries. No schema adjustments needed.

```yaml
# docker-compose.yml snippet
database:
  image: mariadb:10.11
  environment:
    MYSQL_DATABASE: adventureots
```

### 3.4 MyAAC + PHP 8.2/8.3

MyAAC v1.x requires PHP 8.1+. Confirmed patches for PHP 8.2 deprecations (`utf8_encode`/`utf8_decode`). PHP 8.3 community-confirmed.

**Recommended: PHP 8.2** (wider testing, fewer edge-case warnings).

### 3.5 Nginx + PHP-FPM

Standard web stack. Nginx serves static assets, proxies PHP requests to `php-fpm`.

```
                    ┌───────────┐
  :80/:443 ────────►│  Nginx    │
                    │  (static) │
                    │     │     │
                    │     ▼     │
                    │  PHP-FPM  │
                    │  (MyAAC)  │
                    └─────┬─────┘
                          │
                          ▼
                    ┌───────────┐
                    │ MariaDB   │
                    │  10.11    │
                    └───────────┘
```

---

## 4. Identified Risks & Mitigations

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| R1 | **Mehah market module incompatible with TFS 1.4.2** — rewritten for Canary server only | 🟡 Medium | Disable market module in OTClient or use community TFS-compatible patch. Market is a "Could" requirement anyway |
| R2 | **PHP 8.3 deprecation warnings** in some MyAAC plugins | 🟢 Low | Use PHP 8.2 instead (stable, tested). Upgrade later when MyAAC catches up |
| R3 | **TFS compile warnings** with GCC 14 on Ubuntu 24.04 | 🟢 Low | Compile inside Docker with pinned Ubuntu 22.04 base if needed; or suppress non-critical warnings |
| R4 | **RSA key mismatch** between Mehah client and TFS | 🟡 Medium | Replace default RSA keys on both sides during setup; document the process |
| R5 | **Black squares in custom map** on OTClient | 🟢 Low | Ensure `items.otb` version matches protocol 10.98; use correct Tibia.dat/Tibia.spr pair |
| R6 | **Docker networking** — containers can't see each other | 🟢 Low | Use Docker Compose network; reference services by container name (e.g., `database` not `localhost`) |

---

## 5. Version Pinning Strategy

> Pin exact versions in Docker images and config to prevent "works on my machine" issues.

| Component | Pin To | How |
|-----------|--------|-----|
| Ubuntu | 24.04 | `FROM ubuntu:24.04` in Dockerfile |
| MariaDB | 10.11 | `image: mariadb:10.11` in docker-compose |
| PHP | 8.2 | `FROM php:8.2-fpm` in web Dockerfile |
| Nginx | stable | `FROM nginx:stable-alpine` |
| TFS | 1.4.2 | Git tag: `git checkout release-1.4.2` |
| OTClient Mehah | Latest release tag | Pin to specific release commit hash |
| Boost | 1.83 (apt) | System package in Docker build |

---

## 6. Final Docker Compose Architecture

```
┌─────────────────────────────────────────────────┐
│                 Docker Compose                   │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐ │
│  │ TFS      │  │ MariaDB  │  │ Nginx + PHP   │ │
│  │ 1.4.2    │  │ 10.11    │  │ 8.2-FPM       │ │
│  │          │  │          │  │ (MyAAC)        │ │
│  │ :7171    │  │ :3306    │  │ :80 / :443    │ │
│  │ :7172    │  │ (int)    │  │               │ │
│  └────┬─────┘  └─────┬────┘  └───────┬───────┘ │
│       │               │              │          │
│       └───────────────┴──────────────┘          │
│              otsnet (bridge)                     │
│                                                  │
│  ┌──────────┐                                   │
│  │ Backup   │  ← daily mysqldump                │
│  │ service  │                                   │
│  └──────────┘                                   │
└─────────────────────────────────────────────────┘
         │                           │
    :7171/:7172                   :80/:443
         │                           │
    ┌────┴────┐               ┌──────┴──────┐
    │OTClient │               │  Browser    │
    │ Mehah   │               │ (MyAAC)     │
    └─────────┘               └─────────────┘
```

---

## 7. Verdict

> [!TIP]
> **This stack is solid. No blocking conflicts detected.**

| Aspect | Assessment |
|--------|-----------|
| **Overall compatibility** | ✅ All components are confirmed compatible |
| **Biggest advantage** | Mehah (actively maintained) + Docker (reproducible) + Ubuntu 24.04 LTS (supported until 2029) |
| **Biggest risk** | Market module on Mehah (minor — just disable it, it's a "Could" feature) |
| **Recommended PHP** | 8.2 (over 8.3) for maximum AAC stability |
| **Future upgrade path** | Clean — can upgrade TFS and protocol later without changing infra |

---

## 8. Open Questions for Improvement

| # | Question | Impact |
|---|----------|--------|
| Q1 | **Which VPS provider?** (Hetzner, OVH, DigitalOcean, Contabo?) | Affects price, DDoS protection, location (EU/PL for low latency) |
| Q2 | **VPS specs?** (1 vCPU/1 GB RAM minimum, or more?) | TFS + MariaDB + Nginx in Docker needs at least 1 GB; 2 GB recommended |
| Q3 | **HTTPS for website?** (Let's Encrypt free cert or skip for friends-only?) | Recommended even for private — free with Certbot |
| Q4 | **TFS 1.4.2 or 1.5?** Mehah supports both. 1.5 has newer features but less community scripts | Could affect available Lua scripts and creature/spell XML packs |
| Q5 | **Build OTClient Mehah from source or use a release binary?** | Building from source gives full control but takes time; prebuilt binary is faster |
