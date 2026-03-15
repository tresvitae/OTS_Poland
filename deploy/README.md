# [FAZA WDROŻENIA] Multi-Agent LangChain System — Adventure OTS

> Platforma agentowa oparta o **LangChain + LangGraph** do wspomagania projektowania, konfiguracji, testowania i administracji serwera OTS.

---

## Architektura: Hierarchiczny Supervisor

Wybrany wzorzec: **hierarchical supervisor** — gdy agentów jest więcej, pojedynczy supervisor gorzej sobie radzi, więc zastosowano supervisorów zespołowych i jednego nadrzędnego koordynatora.

```
                    Użytkownik
                        │
                        ▼
              ┌─────────────────────┐
              │   TOP SUPERVISOR    │ ← Odbiera polecenie, routuje
              │   (Router Agent)    │
              └──────────┬──────────┘
                         │ route_task()
          ┌──────────────┼──────────────┐──────────────┐
          ▼              ▼              ▼              ▼
    ┌───────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
    │ BACKEND   │ │ FRONTEND   │ │INTEGRATION │ │  CONTENT   │
    │ TEAM      │ │ TEAM       │ │ TEAM       │ │  TEAM      │
    │───────────│ │────────────│ │────────────│ │────────────│
    │• DevOps   │ │• OTClient  │ │• World     │ │• Lore &    │
    │• Lua      │ │  Lua Dev   │ │  Integrator│ │  NPC Writer│
    │  Scripter │ │• Web/PHP   │ │  XML Parser│ │  Dark      │
    │           │ │  Developer │ │            │ │  Fantasy   │
    └─────┬─────┘ └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
          └─────────────┴───────┬──────┴───────────────┘
                                ▼
                      ┌─────────────────┐
                      │   QA GATE       │
                      │   QA/Reviewer   │ ← Validacja kodu
                      │   PASS/WARN/FAIL│
                      └────────┬────────┘
                               ▼
                          WYNIK → Użytkownik
```

---

## Zespoły Agentów

### 1. Zarządzanie i Kontrola Jakości
| Agent | Rola |
|-------|------|
| **Supervisor (Router)** | Odbiera polecenia, analizuje i kieruje do zespołu |
| **QA/Reviewer** | Czyta kod Lua/PHP/XML, szuka bugów, waliduje TFS 1.4.2 |

### 2. Zespół Backendowy (Serwer & Baza)
| Agent | Rola |
|-------|------|
| **DevOps Agent** | Docker Compose, Dockerfiles, SQL, config.lua, VPS |
| **Lua Engine Scripter** | Skrypty data/ — questy, bossy, spawny, mechaniki |

### 3. Zespół Frontendowy (WWW & Klient)
| Agent | Rola |
|-------|------|
| **OTClient Lua Dev** | Moduły klienta, IP/RSA, interfejs gracza |
| **Web/PHP Developer** | MyAAC, szablony PHP, CSS dark-fantasy, strona |

### 4. Zespół Integracji Świata
| Agent | Rola |
|-------|------|
| **World Integrator & XML Parser** | Parsuje XML mapy, przekazuje koordynaty |

### 5. Zespół Contentu (Świat Gry)
| Agent | Rola |
|-------|------|
| **Lore & NPC Writer** | Dialogi NPC, opisy dark-fantasy, klimat |

---

## Kluczowe informacje

> **⚠️ Mapa NIE jest generowana przez AI.**
> Jest pobierana jako gotowy plik `.otbm`. LLM nie potrafi operować na binarnych plikach map.
> World Integrator Agent jedynie **parsuje XML-e** towarzyszące mapie (`map-spawns.xml`, `map-houses.xml`) i wyciąga koordynaty.

## Stack technologiczny

| Komponent | Technologia |
|-----------|-------------|
| LLM | Anthropic Claude (Sonnet) |
| Framework | LangChain + LangGraph |
| Monitoring | LangSmith Tracing |
| Silnik gry | TFS 1.4.2 (protokół 10.98) |
| Baza | MariaDB 10.11 |
| Strona | MyAAC + PHP 8.2 + Nginx |
| Klient | OTClient Mehah |

## Uruchomienie

```bash
# 1. Zainstaluj zależności
pip install -e .

# 2. Skonfiguruj .env (skopiuj z .env.example)
cp .env.example .env
# Edytuj .env — wstaw klucz Anthropic API

# 3. Uruchom system agentów
python src/main.py
```

## Zakres MVP

- Uruchomienie istniejącego serwera OTS i DB
- Supervisor w LangGraph z routingiem do zespołów
- 8 agentów specjalistycznych (DevOps, Lua, OTClient, Web, Integrator, Content, Supervisor, QA)
- QA Gate — obowiązkowa recenzja kodu przed zwróceniem wyniku
- Interaktywna pętla CLI z rekomendacjami