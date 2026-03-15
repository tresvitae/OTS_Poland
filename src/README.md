# src/ — Kod źródłowy Multi-Agent System

> SDLC Stage 3: Implementation — Wieloagentowy system LangChain/LangGraph

## Struktura katalogów

```
src/
├── main.py                          # Punkt wejścia CLI
├── __init__.py
│
├── config/                          # Konfiguracja
│   ├── __init__.py
│   └── settings.py                  # .env, Anthropic API, ścieżki gry
│
├── agents/                          # Definicje agentów
│   ├── __init__.py
│   ├── supervisor.py                # 🎯 Router — kieruje do zespołów
│   ├── qa_reviewer.py               # 🔍 QA — walidacja kodu TFS 1.4.2
│   │
│   ├── backend/                     # Zespół Backendowy
│   │   ├── __init__.py
│   │   ├── devops_agent.py          # 🐳 Docker, SQL, config, VPS
│   │   └── lua_scripter.py          # ⚙️ Skrypty Lua, potwory, questy
│   │
│   ├── frontend/                    # Zespół Frontendowy
│   │   ├── __init__.py
│   │   ├── otclient_agent.py        # 🎮 OTClient moduły, IP, RSA
│   │   └── web_php_agent.py         # 🌐 MyAAC, PHP, CSS dark-fantasy
│   │
│   ├── integration/                 # Zespół Integracji Świata
│   │   ├── __init__.py
│   │   └── world_integrator.py      # 🗺️ XML Parser, koordynaty mapy
│   │
│   └── content/                     # Zespół Contentu
│       ├── __init__.py
│       └── lore_npc_agent.py        # 📜 Dialogi NPC, lore dark-fantasy
│
├── graph/                           # Logika LangGraph
│   ├── __init__.py
│   ├── state.py                     # AgentState — stan współdzielony
│   ├── routing.py                   # route_task(), should_review()
│   └── main_graph.py                # Główny graf hierarchiczny
│
├── tools/                           # Narzędzia (LangChain tools)
│   ├── __init__.py
│   ├── file_tools.py                # Zapis/odczyt plików Lua/XML
│   └── xml_parser_tools.py          # Parsowanie map-spawns/houses XML
│
└── prompts/                         # Prompty systemowe
    ├── __init__.py
    ├── supervisor_prompt.py          # Reguły routingu
    ├── qa_prompt.py                 # Checklist QA (TFS 1.4.2)
    ├── backend_prompts.py           # DevOps + Lua API reference
    ├── frontend_prompts.py          # OTClient + Web/PHP
    ├── content_prompts.py           # Dark fantasy guidelines
    └── integration_prompts.py       # XML parsing context
```

## Zmiany i dokonania (Faza Wdrożenia)

### Data: 2026-03-15

**Utworzono kompletny system wieloagentowy:**

1. **Infrastruktura** — `pyproject.toml` (LangChain + Anthropic + LangGraph + LangSmith), `.env.example`
2. **Zarządzanie i Kontrola Jakości** — Supervisor (router) + QA/Reviewer (PASS/WARN/FAIL)
3. **Zespół Backendowy** — DevOps Agent (Docker, SQL, config) + Lua Engine Scripter (TFS 1.4.2 API)
4. **Zespół Frontendowy** — OTClient Lua Dev (moduły, IP/RSA) + Web/PHP Developer (MyAAC, dark-fantasy CSS)
5. **Zespół Integracji Świata** — World Integrator & XML Parser (spawns, houses, koordynaty)
6. **Zespół Contentu** — Lore & NPC Writer (dialogi, opisy, mroczny klimat)
7. **Graf LangGraph** — `StateGraph` z conditional edges, QA gate, retry loop
8. **Narzędzia** — `file_tools.py` (zapis Lua/XML), `xml_parser_tools.py` (parsowanie map XML)
9. **Prompty** — 6 plików z pełnym kontekstem TFS 1.4.2, dark fantasy, bezpieczeństwa

**Kluczowe decyzje:**
- LLM: **Anthropic Claude** (Sonnet)
- Monitoring: **LangSmith Tracing** włączony
- Mapa: **NIE generowana przez AI** — pobrana gotowa (.otbm), tylko XML parsowany
- QA Gate: **obowiązkowy** krok przed zwróceniem kodu
- Protokół: **TFS 1.4.2** (nie Canary!) — QA waliduje zgodność API
