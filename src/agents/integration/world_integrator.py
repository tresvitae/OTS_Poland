"""
World Integrator & XML Parser Agent — kluczowy łącznik.

KLUCZOWA ZMIANA: Mapa NIE jest budowana — jest pobrana i gotowa.
Nie istnieje Agent AI do budowania mapy, bo LLM nie umie operować na plikach .otbm.

Ten agent:
1. Analizuje pliki XML mapy (map-spawns.xml, map-houses.xml)
2. Na podstawie koordynat (X, Y, Z) informuje inne agenty
3. Parsuje XML → JSON z koordynatami
"""

from langchain_core.messages import HumanMessage, SystemMessage

from src.config.settings import get_llm
from src.prompts.integration_prompts import INTEGRATION_SYSTEM_PROMPT
from src.tools.xml_parser_tools import parse_spawns_xml, parse_houses_xml, get_town_coordinates
from src.tools.file_tools import read_file, list_directory


INTEGRATION_TOOLS = [parse_spawns_xml, parse_houses_xml, get_town_coordinates, read_file, list_directory]


def create_world_integrator_agent():
    """Tworzy agenta World Integrator & XML Parser."""
    llm = get_llm()
    llm_with_tools = llm.bind_tools(INTEGRATION_TOOLS)

    def world_integrator_node(state: dict) -> dict:
        """Węzeł World Integrator w grafie LangGraph."""
        messages = state.get("messages", [])

        response = llm_with_tools.invoke(
            [SystemMessage(content=INTEGRATION_SYSTEM_PROMPT)] + messages
        )

        # Spróbuj wyciągnąć map_context z odpowiedzi
        map_context = state.get("map_context", {})

        return {
            "messages": messages + [response],
            "generated_code": response.content,
            "map_context": map_context,
            "current_team": "integration",
        }

    return world_integrator_node
