"""
Główny graf hierarchicznego supervisora — LangGraph StateGraph.

Architektura:
    Top Supervisor (router)
    ├── Backend Team → DevOps Agent, Lua Scripter
    ├── Frontend Team → OTClient Dev, Web/PHP Dev
    ├── Integration Team → World Integrator
    ├── Content Team → Lore & NPC Writer
    └── QA Gate → QA/Reviewer Agent
"""

from langgraph.graph import StateGraph, END

from src.graph.state import AgentState
from src.graph.routing import route_task, should_review, after_qa

from src.agents.supervisor import create_supervisor_agent
from src.agents.qa_reviewer import create_qa_agent
from src.agents.backend.devops_agent import create_devops_agent
from src.agents.backend.lua_scripter import create_lua_scripter_agent
from src.agents.frontend.otclient_agent import create_otclient_agent
from src.agents.frontend.web_php_agent import create_web_php_agent
from src.agents.integration.world_integrator import create_world_integrator_agent
from src.agents.content.lore_npc_agent import create_lore_npc_agent


def build_graph() -> StateGraph:
    """
    Buduje główny graf LangGraph z hierarchicznym supervisorem.

    Przepływ:
        1. Supervisor → analizuje polecenie, decyduje o zespole
        2. route_task() → kieruje do Backend / Frontend / Integration / Content
        3. Zespół wykonuje zadanie
        4. should_review() → decyduje czy wysłać do QA
        5. QA Agent → sprawdza kod
        6. after_qa() → PASS/WARN → finish, FAIL → retry
    """

    # Tworzenie nodów
    supervisor = create_supervisor_agent()
    qa_agent = create_qa_agent()
    devops = create_devops_agent()
    lua_scripter = create_lua_scripter_agent()
    otclient = create_otclient_agent()
    web_php = create_web_php_agent()
    world_integrator = create_world_integrator_agent()
    lore_npc = create_lore_npc_agent()

    # ── Budowa grafu ──────────────────────────────────────
    graph = StateGraph(AgentState)

    # Dodaj węzły
    graph.add_node("supervisor", supervisor)
    graph.add_node("backend", _backend_team(devops, lua_scripter))
    graph.add_node("frontend", _frontend_team(otclient, web_php))
    graph.add_node("integration", world_integrator)
    graph.add_node("content", lore_npc)
    graph.add_node("qa_review", qa_agent)

    # ── Krawędzie ─────────────────────────────────────────

    # Start → Supervisor
    graph.set_entry_point("supervisor")

    # Supervisor → routing do zespołów
    graph.add_conditional_edges(
        "supervisor",
        route_task,
        {
            "backend": "backend",
            "frontend": "frontend",
            "integration": "integration",
            "content": "content",
            "finish": END,
        },
    )

    # Każdy zespół → QA review lub finish
    for team in ["backend", "frontend", "integration", "content"]:
        graph.add_conditional_edges(
            team,
            should_review,
            {
                "qa_review": "qa_review",
                "finish": END,
            },
        )

    # QA → finish lub retry (→ powrót do supervisora)
    graph.add_conditional_edges(
        "qa_review",
        after_qa,
        {
            "finish": END,
            "retry": "supervisor",
        },
    )

    return graph.compile()


def _backend_team(devops_node, lua_scripter_node):
    """
    Łączy DevOps i Lua Scripter w jeden węzeł zespołu backendowego.
    Decyduje, którego agenta użyć na podstawie treści wiadomości.
    """

    def backend_node(state: dict) -> dict:
        messages = state.get("messages", [])
        last_msg = messages[-1].content.lower() if messages else ""

        # Heurystyka: docker/sql/config → DevOps, reszta → Lua Scripter
        devops_keywords = [
            "docker", "compose", "dockerfile", "sql", "baza", "database",
            "config.lua", "vps", "deploy", "backup", "firewall", "nginx",
            "mariadb", "myaac", "config.php", "infrastruktur",
        ]

        if any(kw in last_msg for kw in devops_keywords):
            return devops_node(state)
        else:
            return lua_scripter_node(state)

    return backend_node


def _frontend_team(otclient_node, web_php_node):
    """
    Łączy OTClient Dev i Web/PHP Dev w jeden węzeł zespołu frontendowego.
    """

    def frontend_node(state: dict) -> dict:
        messages = state.get("messages", [])
        last_msg = messages[-1].content.lower() if messages else ""

        # Heurystyka: otclient/klient/moduł → OTClient, reszta → Web/PHP
        otclient_keywords = [
            "otclient", "klient", "client", "moduł", "module",
            "hud", "interfejs", "rsa", "ip serwera",
        ]

        if any(kw in last_msg for kw in otclient_keywords):
            return otclient_node(state)
        else:
            return web_php_node(state)

    return frontend_node
