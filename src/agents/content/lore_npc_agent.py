"""
Lore & NPC Writer & Content Adapter Agent — buduje klimat Dark Fantasy.

Skupia się wyłącznie na warstwie fabularnej:
- Dialogi NPC w formacie XML/Lua
- Opisy mrocznego świata dark-fantasy
- Zmiana nazw NPC, modyfikacja tekstów powitalnych
- Dopasowywanie opisów przedmiotów do mrocznego klimatu
"""

from langchain_core.messages import HumanMessage, SystemMessage

from src.config.settings import get_llm
from src.prompts.content_prompts import CONTENT_SYSTEM_PROMPT
from src.tools.file_tools import write_xml_file, write_lua_script, read_file, list_directory


CONTENT_TOOLS = [write_xml_file, write_lua_script, read_file, list_directory]


def create_lore_npc_agent():
    """Tworzy agenta Lore & NPC Writer."""
    llm = get_llm()
    llm_with_tools = llm.bind_tools(CONTENT_TOOLS)

    def lore_npc_node(state: dict) -> dict:
        """Węzeł Lore & NPC Writer w grafie LangGraph."""
        messages = state.get("messages", [])
        map_context = state.get("map_context", {})

        # Dodaj pozycje NPC z kontekstu mapy
        context_msg = ""
        if map_context and "npc_positions" in map_context:
            npc_info = []
            for npc in map_context["npc_positions"]:
                pos = npc.get("position", {})
                npc_info.append(
                    f"- {npc.get('name', '?')}: ({pos.get('x')}, {pos.get('y')}, {pos.get('z')})"
                )
            context_msg = (
                f"\n\nPozycje NPC z mapy (dane od World Integrator):\n"
                f"{chr(10).join(npc_info)}"
            )

        system_prompt = CONTENT_SYSTEM_PROMPT + context_msg

        response = llm_with_tools.invoke(
            [SystemMessage(content=system_prompt)] + messages
        )

        return {
            "messages": messages + [response],
            "generated_code": response.content,
            "current_team": "content",
        }

    return lore_npc_node
