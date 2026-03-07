# Adventure OTS — Project Charter

> **Document:** 00 — Project Charter
> **Date:** 2026-03-07
> **Last Updated:** 2026-03-07
> **Status:** ✅ Approved — All design decisions confirmed

---

## 1. Project Overview

| Field | Value |
|-------|-------|
| **Project Name** | Adventure OTS (OTS_Poland) |
| **Project Type** | Private Tibia Open Server |
| **Target Audience** | 5–10 neighbourhood friends |
| **Project Owner** | tresvitae |
| **Start Date** | March 2026 |
| **Methodology** | SDLC (Waterfall-inspired, phased) |

### Vision Statement

> Build a private Tibia Open Server from scratch for a small group of neighbourhood friends — delivering a **dark fantasy RPG experience** with custom Polish-language lore, staged progression (levels 1–100), and Open PvP, deployed on a VPS with a public domain.

---

## 2. Business Justification

| Reason | Details |
|--------|---------|
| **Why?** | Shared nostalgia for Tibia; desire to play together on a private, customizable server |
| **Who benefits?** | A small group of friends (5–10 players) |
| **What problem does it solve?** | Official Tibia lacks customization; public OTS servers are unreliable, crowded, and not private |
| **What makes it unique?** | Custom map, custom quests designed for our group, controlled environment, zero pay-to-win |

---

## 3. Project Scope

### 3.1 In Scope

| Area | Deliverable |
|------|-------------|
| **Game Server** | TFS 1.4.2 (protocol 10.98) compiled and configured |
| **Game Client** | OTClient V8 customized with server branding |
| **Database** | MariaDB 10.11 with full schema (accounts, players, items, houses) |
| **Website** | MyAAC — account registration, character management, highscores, server info |
| **Custom Map** | Dark fantasy original map, levels 1–100 content, base town (~500×500 tiles) |
| **Game Content** | Lua scripts for creatures, spells, NPCs, quests, events |
| **Deployment** | Docker Compose — local (dev) + VPS (test/prod), public IP, domain name |
| **Language** | NPCs & webapp in Polish 🇵🇱, code/config/docs in English 🇬🇧 |
| **Documentation** | Setup guide, admin guide, player guide |

### 3.2 Out of Scope (Phase 1)

| Excluded | Reason |
|----------|--------|
| Mobile client | Complexity; not needed for friends-only LAN/VPN setup |
| Payment/donation system | No monetization — this is a friends-only server |
| Multi-server clustering | Single world is sufficient for 5–10 players |
| Custom C++ engine modifications | Use TFS as-is; extend only via Lua and configuration |
| Public marketing / SEO | Private server; no public players |

---

## 4. Technology Stack (Decided)

| Layer | Technology | Version |
|-------|-----------|---------|
| Game Server | The Forgotten Server (TFS) | 1.4.2 |
| Protocol | Tibia Protocol | 10.98 |
| Scripting | Lua | 5.2+ |
| Database | MariaDB | 10.11 |
| Game Client | OTClient Mehah | Latest |
| Website | MyAAC (PHP) | Latest |
| Web Server | Nginx | Latest |
| Web Runtime | PHP | 8.2 |
| TLS / HTTPS | Let's Encrypt + Certbot | Free cert |
| Containerization | Docker + Docker Compose | Latest |
| OS | Ubuntu Server | 24.04 LTS |
| Map Editor | Remere's Map Editor (RME) | Latest |
| Version Control | Git | — |

*Full details: [01_technology_requirements.md](01_technology_requirements.md)*

---

## 5. Architecture Summary

```
 [OTClient] ◄──TCP 7171/7172──► [TFS Game Server]
                                      │
                   ┌──────────────────┼──────────────────┐
                   │                  │                  │
              [Lua Scripts]     [Map .otbm]        [MariaDB]
              (content)         (world)                 │
                                                        │
                                    [MyAAC Website] ◄───┘
                                     (PHP + Nginx)
                                         ▲
                                    HTTP :80
                                         │
                                   [Player Browser]
```

**Key architectural decisions:**
- Single-threaded dispatcher for game state safety (no data races)
- Scheduler-dispatcher pattern for timed events  
- All game content in Lua (no C++ recompilation for content changes)
- Shared database between server and website
- Dockerized deployment for reproducibility

*Full details: [02_architecture.md](02_architecture.md)*

---

## 6. Key Requirements Summary

### Functional (73 requirements, 17 groups)

| Priority | Count | Examples |
|----------|-------|---------|
| **Must** | 46 | Account login, combat, creatures, spells, items, movement, map, NPCs |
| **Should** | 23 | Housing, guilds, chat channels, skull system, day/night, quest log |
| **Could** | 4 | Market/auction house, premium accounts |

### Non-Functional (38 requirements, 9 categories)

| Category | Key Targets |
|----------|------------|
| Performance | 20 ticks/sec, <100ms response, <50ms LAN latency |
| Security | RSA+XTEA, SSH hardening, firewall, input validation |
| Reliability | 99% uptime, auto-restart, 5-min auto-save |
| Backup | Daily DB dumps, 7-day retention, <30min RTO |

*Full details: [03_requirements.md](03_requirements.md)*

---

## 7. Milestones & Phases

| Phase | Name | Deliverables | Est. Duration |
|-------|------|-------------|---------------|
| **1** | Research & Analysis ✅ | Tech stack, architecture, requirements docs | Complete |
| **2** | System Design | DB schema, API contracts, Lua script structure, Docker blueprints | ~1 week |
| **3** | Infrastructure Setup | Docker Compose, TFS build, DB init, MyAAC deploy | ~1 week |
| **4** | Map creation | Custom map with 2–3 towns, dungeons, hunting grounds | ~2–3 weeks |
| **5** | Content Development | Creatures, spells, NPCs, quests, items (Lua) | ~2–3 weeks |
| **6** | Client Setup | OTClient branding, config, distribution package | ~2–3 days |
| **7** | Testing & QA | Gameplay testing, balance, security checks | ~1 week |
| **8** | Launch & Operations | Deploy production, distribute client, onboard friends | ~2–3 days |

---

## 8. Risks & Mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| R1 | TFS build fails on target OS | Medium | High | Use Docker to isolate build environment |
| R2 | Protocol mismatch (client ↔ server) | Medium | High | Lock TFS 1.4.2 + OTClient V8 + protocol 10.98 as a verified triple |
| R3 | DDoS attacks | Low | High | Host behind NAT/VPN for friends-only; expose only to trusted IPs |
| R4 | Data loss (crash, corruption) | Low | High | Auto-save 5min, daily backups, Git-versioned configs |
| R5 | Map creation takes too long | High | Medium | Start with small map; expand post-launch |
| R6 | Lua scripting bugs | High | Medium | Test each script individually; use existing TFS community scripts as base |
| R7 | Friends lose interest | Medium | Medium | Launch MVP fast; add content iteratively |
| R8 | Security vulnerabilities in AAC | Medium | High | Use latest MyAAC with SQL injection protection; HTTPS via Let's Encrypt |

---

## 9. Stakeholders & Roles

| Role | Person | Responsibilities |
|------|--------|-----------------|
| **Solo Developer / Admin** | tresvitae | All development, infrastructure, map, scripts, admin |
| **Players** | Friends (5–10) | Playtesting, feedback, content ideas |
| **GM (Game Master)** | tresvitae (self) | In-game moderation, event hosting |

---

## 10. Constraints

| Constraint | Details |
|-----------|---------|
| **Budget** | $0–$10/month (cheap VPS + free domain) |
| **Team size** | **1 solo developer** (tresvitae) — code, infra, map, content |
| **Timeline** | No hard deadline — hobby project |
| **Hardware** | Local machine (dev) + VPS (test/prod) |
| **Availability** | Server runs on **scheduled hours** (not 24/7) |
| **Legal** | OTS is community/fan project; no commercial use |

---

## 11. Success Criteria

| # | Criteria | Measurement |
|---|---------|-------------|
| S1 | Server runs stable for 24+ hours without crash | Uptime monitoring |
| S2 | All friends can connect, create account, enter game | On-launch test |
| S3 | Core gameplay works: walk, fight, loot, quest, level up | Play session |
| S4 | Custom map has at least 2 towns and 5 hunting areas | Map review |
| S5 | At least 3 custom quests playable end-to-end | Quest walkthrough |
| S6 | Server can restart and restore state within 5 minutes | Recovery test |

---

## 12. Design Decisions (Answered)

> ✅ All questions answered on 2026-03-07. These decisions are now **locked** for Phase 2+.

### Game Design Decisions

| # | Question | **Decision** |
|---|----------|-------------|
| Q1 | Tibia era / protocol | **Tibia 10.98** (TFS 1.4.2 + OTClient V8) |
| Q2 | Experience rate | **Staged: ~20x–50x at low levels → 2x–3x at high levels** |
| Q3 | PvP type | **Open PvP** |
| Q4 | Lore / theme | **Custom lore, dark fantasy RPG** (not a Tibia replica) |
| Q5 | Vocations | **Classic 4** — Knight, Paladin, Sorcerer, Druid |

### Map & Content Decisions

| # | Question | **Decision** |
|---|----------|-------------|
| Q6 | Map theme | **Dark fantasy** — base town with gothic/medieval atmosphere |
| Q7 | Real or custom map | **Fully custom** — original world design |
| Q8 | Level range | **Levels 1–100** (full content for MVP) |

### Infrastructure Decisions

| # | Question | **Decision** |
|---|----------|-------------|
| Q9 | Hosting model | **Local** (development) + **VPS** (testing & production) |
| Q10 | Player connection | **Public IP** (via VPS), domain name for easy access |
| Q11 | Domain name | **Use a domain** — see recommendations below |

### Team & Process Decisions

| # | Question | **Decision** |
|---|----------|-------------|
| Q12 | Team composition | **Solo developer** — tresvitae handles all code, infra, map, content |
| Q13 | Server schedule | **Scheduled hours** (announced in advance, not 24/7) |
| Q14 | Language | **Polish** 🇵🇱 for NPC dialogues + webapp · **English** 🇬🇧 for code, configs, docs |

---

## 13. Domain Name Recommendations

### Free Options

| Service | Domain Format | Best For | Notes |
|---------|-------------|----------|-------|
| **Duck DNS** | `adventure-ots.duckdns.org` | ★★★★★ | Free, supports dynamic IP, instant setup, no signup |
| **No-IP** | `adventure-ots.ddns.net` | ★★★★ | Free tier (3 hostnames), well-known, auto-updater |
| **freedns.afraid.org** | `adventure-ots.mooo.com` (+ many others) | ★★★★ | Free, huge selection of subdomains |
| **eu.org** | `adventure-ots.eu.org` | ★★★ | Free for EU individuals, looks professional, slow approval |

### Cheap Paid Options (~$1–3/year)

| Registrar | Domain | Price | Notes |
|-----------|--------|-------|-------|
| **Namecheap** | `adventure-ots.xyz` | ~$1/year | Cheapest real TLD, full control |
| **Namecheap** | `adventure-ots.online` | ~$2/year | Clean and modern |
| **OVH** | `adventure-ots.ovh` | ~$3/year | Included with OVH VPS |

> **Recommendation:** Start with **Duck DNS** (free, instant, works with VPS). If you want something more polished later, buy a `.xyz` or `.online` domain for ~$1–3/year on Namecheap.

---

## 14. Experience Stages Configuration

> Based on decision Q2: Staged rates starting high and decreasing.

| Level Range | Experience Rate | Skill Rate | Magic Rate | Rationale |
|-------------|----------------|-----------|------------|----------|
| 1 – 20 | **50x** | 30x | 15x | Fast start, get into the game quickly |
| 21 – 40 | **30x** | 20x | 10x | Still quick, learning vocations |
| 41 – 60 | **15x** | 10x | 8x | Slowing down, content gets serious |
| 61 – 80 | **5x** | 5x | 5x | Meaningful grind, quest-focused |
| 81 – 100 | **3x** | 3x | 3x | Endgame, hard-earned progress |
| 100+ | **2x** | 2x | 2x | Post-MVP expansion content |

Configured in `data/XML/stages.xml`:
```xml
<stages>
  <stage minlevel="1" maxlevel="20" multiplier="50" />
  <stage minlevel="21" maxlevel="40" multiplier="30" />
  <stage minlevel="41" maxlevel="60" multiplier="15" />
  <stage minlevel="61" maxlevel="80" multiplier="5" />
  <stage minlevel="81" maxlevel="100" multiplier="3" />
  <stage minlevel="101" maxlevel="999" multiplier="2" />
</stages>
```

---

## Approval

| Stakeholder | Status | Date |
|-------------|--------|------|
| tresvitae (Project Owner) | ✅ Approved | 2026-03-07 |

---

> **References:**
> - [01_technology_requirements.md](01_technology_requirements.md)
> - [02_architecture.md](02_architecture.md)
> - [03_requirements.md](03_requirements.md)
