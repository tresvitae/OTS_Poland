"""
Supervisor Agent (Router) — centralny nadzorca systemu agentów.

Odbiera polecenia użytkownika i kieruje je do odpowiedniego zespołu:
- Backend Team (DevOps + Lua Scripter)
- Frontend Team (OTClient + Web/PHP)
- Integration Team (World Integrator)
- Content Team (Lore & NPC Writer)
"""

from langchain_core.messages import HumanMessage, SystemMessage

from src.config.settings import get_llm
from src.prompts.supervisor_prompt import SUPERVISOR_SYSTEM_PROMPT


def create_supervisor_agent():
    """Tworzy agenta Supervisora z promptem systemowym."""
    llm = get_llm()

    def supervisor_node(state: dict) -> dict:
        """
        Węzeł supervisora w grafie LangGraph.
        Analizuje polecenie i zwraca decyzję routingu.
        """
        messages = state.get("messages", [])

        response = llm.invoke(
            [SystemMessage(content=SUPERVISOR_SYSTEM_PROMPT)] + messages
        )

        # Parsuj decyzję routingu z odpowiedzi
        route = _parse_route(response.content)

        return {
            "messages": messages + [response],
            "current_team": route,
            "task_type": route,
        }

    return supervisor_node


def _parse_route(response_text: str) -> str:
    """
    Parsuje odpowiedź supervisora i wyciąga docelowy zespół.

    Supervisor powinien odpowiedzieć jednym z:
    - BACKEND
    - FRONTEND
    - INTEGRATION
    - CONTENT
    - FINISH (zadanie zakończone)
    """
    response_upper = response_text.upper()

    team_keywords = {
        "BACKEND": "backend",
        "FRONTEND": "frontend",
        "INTEGRATION": "integration",
        "CONTENT": "content",
        "FINISH": "finish",
    }

    for keyword, team in team_keywords.items():
        if keyword in response_upper:
            return team

    # Domyślnie → backend (najczęściej używany)
    return "backend"
