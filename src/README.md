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

## 🛠️ Instrukcja pracy nad LangChain (Development Guide)

Aby pracować nad systemem LangChain/LangGraph i rozwijać sztuczną inteligencję w projekcie, postępuj zgodnie z poniższymi wskazówkami, które bazują na obecnej architekturze zdefiniowanej w katalogu `src/`.

### 1. Konfiguracja środowiska i uruchomienie lokalnie
1. **Zmienne środowiskowe:** Skopiuj `.env.example` do `.env` w głównym katalogu projektu i skonfiguruj klucze API:
   - `ANTHROPIC_API_KEY` — (Wymagany) Służy do komunikacji z bazowym modelem LLM (Claude Sonnet), który napędza procesy myślowe wszystkich agentów w systemie.
   - `LANGCHAIN_API_KEY` — (Zalecany) Służy do odizolowanej integracji z platformą LangSmith. Pozwala ona monitorować całą aplikację LangChain: śledzić błędy i wykonanie promptów, debugować przebieg działania LangGraphu i diagnozować zużycie/koszty tokenów za zapytania.
2. **Przygotowanie środowiska i instalacja pakietów:**
   Zaleca się stworzenie izolowanego środowiska wirtualnego dla projektu. Proces (np. w głównym katalogu projektu) przebiega następująco:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # na systemach Linux/macOS
   # na Windows użyj: .venv\Scripts\activate
   
   # Aby zainstalować system LangChain oraz wymagane pakiety:
   pip install -e .
   ```
3. **Uruchomienie CLI:** Będąc w tym samym, aktywnym środowisku oraz z wewnątrz katalogu głównego repozutorium, uruchamiamy interfejs agentów w konsoli poleceniem:
   ```bash
   python -m src.main
   ```
4. **LangSmith Tracing:** Na cele debugowania procesów myślowych logiki powinieneś dodatkowo upewnić się, że posiadasz zmienne bazowe `LANGCHAIN_TRACING_V2=true` oraz `LANGCHAIN_PROJECT="adventure-ots-agents"` wpisane w pliku `.env`. Wtedy z użyciem swojego `LANGCHAIN_API_KEY` będziesz w stanie przeglądać UI LangSmith w przeglądarce.

### 2. Rozwój Przepływu (LangGraph) — `src/graph/`
Logika i "ścieżki" myślowe systemu żyją głównie w **LangGraph**. Modyfikując proces lub dodając nowych specjalistycznych Agentów:
- Aktualizuj schemat ogólnego stanu komunikacji i kontekstu: `src/graph/state.py`.
- Wszelkie zasady dotyczące tego do którego agenta "skieruje" Supervisor należy umieszczać jako reguły (conditional edges) zlokalizowane w `src/graph/routing.py` oraz podpiąć w budowaniu głównego drzewa (`src/graph/main_graph.py`).

### 3. Rozszerzanie Możliwości o Narzędzia (Tools) — `src/tools/`
Jeżeli pożądana jest nowa interakcja z infrastrukturą silnika:
1. Skryptuj narzędzie używając `@tool` z biblioteki `langchain_core.tools`.
2. Dodaj dogłębny, bardzo szczegółowy docstring oraz `BaseModel` args do każdego narzędzia. Ma to kluczowe znaczenie w poprawności pracy inteligentnego LLMa (ponieważ system bazuje na Function Calling LLM'a). Np. w `src/tools/file_tools.py` lub `src/tools/xml_parser_tools.py`.
3. Podepnij narzędzie do określonego zespołu (agenta backendowego/contentowego itp.) w katalogu `src/agents/`. Pamiętaj, aby nie przeładowywać narzedziami jednego agenta bezcelowymi funkcjami, nadawaj uprawnienia narzędziowe kontekstowo.

### 4. Dopieszczanie Zespołów Agentów i Promptów — `src/prompts/` i `src/agents/`
- Konteksty systemowe znajdują się w `src/prompts/`. Rozbudowując wiedzę któregoś z agentów — np. dodając wsparcie dla innych typów potworów — staraj się robić to poprzez rozszerzanie odpowiedniego pliku (np. `src/prompts/backend_prompts.py`).
- Pamiętaj, aby w promptach naciskać w sposób widoczny na zgodność tworzonych poleceń z Dark Fantasy style i The Forgotten Server 1.4.2 API.
- Rejestrując nowego Agenta utwórz nową klasę/węzeł odpowiadający nowemu członkowi personelu w `src/agents/`, przypisz mu instrukcję startową i jego własny ekwipunek toolsów. Następnie upewnij się, że wpisałeś go w sieć połączeń main_graph LangGraph.
