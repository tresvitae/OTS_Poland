"""
Definicja stanu grafu LangGraph — SharedState.

Zawiera wszystkie dane przepływające między agentami.
"""

from typing import Annotated
from typing_extensions import TypedDict

from langgraph.graph.message import add_messages


class AgentState(TypedDict):
    """
    Stan współdzielony między wszystkimi agentami w grafie.

    Atrybuty:
        messages: Historia konwersacji (LangChain messages)
        task_type: Typ zadania (backend, frontend, content, integration, finish)
        generated_code: Ostatnio wygenerowany kod (Lua/PHP/XML)
        qa_result: Wynik recenzji QA (PASS/WARN/FAIL + issues)
        current_team: Aktualnie aktywny zespół
        map_context: Dane z XML mapy (koordynaty, spawny, domy)
    """

    # Wiadomości — automatycznie łączone (append)
    messages: Annotated[list, add_messages]

    # Routing — do którego zespołu skierować
    task_type: str

    # Wygenerowany kod — do review przez QA
    generated_code: str

    # Wynik QA
    qa_result: dict

    # Aktualny zespół
    current_team: str

    # Kontekst mapy (z World Integrator)
    map_context: dict
