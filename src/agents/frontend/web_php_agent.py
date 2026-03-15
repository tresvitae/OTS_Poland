"""
Web/PHP Developer Agent — modyfikuje MyAAC, pisze kod strony.

Tworzy:
- Szablony PHP (dark-fantasy klimat)
- CSS (mroczny styl)
- Layouty stron (server info, download, rules)
- Integracja z bazą danych (rejestracja, tworzenie postaci)
"""

from langchain_core.messages import HumanMessage, SystemMessage

from src.config.settings import get_llm
from src.prompts.frontend_prompts import WEB_PHP_SYSTEM_PROMPT
from src.tools.file_tools import write_file, read_file, list_directory


WEB_PHP_TOOLS = [write_file, read_file, list_directory]


def create_web_php_agent():
    """Tworzy agenta Web/PHP Developer."""
    llm = get_llm()
    llm_with_tools = llm.bind_tools(WEB_PHP_TOOLS)

    def web_php_node(state: dict) -> dict:
        """Węzeł Web/PHP Dev w grafie LangGraph."""
        messages = state.get("messages", [])
        map_context = state.get("map_context", {})

        # Dodaj kontekst mapy (town_id, temple position) jeśli dostępny
        context_msg = ""
        if map_context and "towns" in map_context:
            towns_info = []
            for town in map_context["towns"]:
                pos = town.get("temple", {})
                towns_info.append(
                    f"Town ID: {town.get('id')}, Name: {town.get('name')}, "
                    f"Temple: ({pos.get('x')}, {pos.get('y')}, {pos.get('z')})"
                )
            context_msg = (
                f"\n\nKontekst mapy (dane od World Integrator):\n"
                f"{chr(10).join(towns_info)}\n"
                f"Użyj tych danych do konfiguracji tworzenia postaci w MyAAC."
            )

        system_prompt = WEB_PHP_SYSTEM_PROMPT + context_msg

        response = llm_with_tools.invoke(
            [SystemMessage(content=system_prompt)] + messages
        )

        return {
            "messages": messages + [response],
            "generated_code": response.content,
            "current_team": "frontend",
        }

    return web_php_node
