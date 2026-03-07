# Adventure OTS — Project Charter

> **Document:** 00 — Project Charter
> **Date:** 2026-03-07
> **Status:** Draft — Pending Stakeholder Approval

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

> Build a private Tibia Open Server from scratch for a small group of neighbourhood friends — delivering the authentic Tibia MMORPG experience with custom content, on a self-hosted infrastructure.

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
| **Custom Map** | Original map with towns, dungeons, quest areas (~500×500 tiles) |
| **Game Content** | Lua scripts for creatures, spells, NPCs, quests, events |
| **Deployment** | Docker Compose on Ubuntu (local machine or VPS) |
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
| Game Client | OTClient V8 | Latest |
| Website | MyAAC (PHP) | Latest |
| Web Server | Nginx | Latest |
| Containerization | Docker + Docker Compose | Latest |
| OS | Ubuntu LTS | 22.04+ |
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
| **Project Owner / Admin** | tresvitae | Architecture decisions, server admin, development |
| **Players** | Friends (5–10) | Playtesting, feedback, content ideas |
| **GM (Game Master)** | TBD (1–2 friends) | In-game moderation, event hosting |

---

## 10. Constraints

| Constraint | Details |
|-----------|---------|
| **Budget** | $0–$10/month (free hosting or cheap VPS) |
| **Team size** | 1 developer (tresvitae) + volunteer helpers |
| **Timeline** | No hard deadline — hobby project |
| **Hardware** | Available: local machine or $5–10 VPS |
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

## 12. Open Questions for Improvement

> [!IMPORTANT]
> These questions should be answered before moving to Phase 2 (System Design). They will shape key design decisions.

### Game Design Questions

| # | Question | Impact |
|---|----------|--------|
| Q1 | **What Tibia era do you want to emulate?** (7.4 old school, 8.6 classic, 10.x modern?) | Affects creature roster, spell list, items, and nostalgia factor |
| Q2 | **Experience/skill rate multiplier?** (1x real Tibia, 5x fast, 50x ultra?) | Determines how quickly friends hit endgame |
| Q3 | **PvP type?** (Open PvP, Optional PvP, Hardcore PvP?) | Changes entire combat/social dynamic |
| Q4 | **Custom lore/theme or replica of real Tibia?** | Affects map design, NPC names, quest narratives |
| Q5 | **How many vocations?** (Classic 4 or add custom ones like Monk?) | Impacts balance and spell/item design |

### Map & Content Questions

| # | Question | Impact |
|---|----------|--------|
| Q6 | **Starting town name and theme?** (Medieval? Fantasy? Polish-themed?) | Sets creative direction for the entire map |
| Q7 | **Real Tibia map or fully custom?** | Custom = unique but more work; real = nostalgic but less original |
| Q8 | **Level range of initial content?** (1–50? 1-100? 1-200?) | Determines amount of creatures, spawns, and quest content needed |

### Infrastructure Questions

| # | Question | Impact |
|---|----------|--------|
| Q9 | **Host locally or on a VPS?** | Local = free but requires port forwarding/VPN; VPS = $5-10/month, always-on |
| Q10 | **How will friends connect?** (LAN, VPN like Tailscale/ZeroTier, or public IP?) | Affects firewall, DDoS exposure, and setup complexity |
| Q11 | **Domain name?** (e.g., adventure-ots.pl, or just IP address?) | Affects website URL, client config, and first impression |

### Team & Process Questions

| # | Question | Impact |
|---|----------|--------|
| Q12 | **Any friends willing to help with map creation or Lua scripting?** | More hands = faster content; could assign roles |
| Q13 | **How often should the server run?** (24/7 or scheduled hours?) | Affects hosting choice and expectations |
| Q14 | **Language for in-game content?** (Polish? English? Mix?) | Affects NPC dialogues, quest text, website language |

---

## Approval

| Stakeholder | Status | Date |
|-------------|--------|------|
| tresvitae (Project Owner) | ⬜ Pending | — |

---

> **References:**
> - [01_technology_requirements.md](01_technology_requirements.md)
> - [02_architecture.md](02_architecture.md)
> - [03_requirements.md](03_requirements.md)
