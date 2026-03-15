"""
Lua Engine Scripter Agent — najbardziej zapracowany agent.

Pisze wszystkie systemy do folderu data/:
- Spawny, zachowania bossów
- Mechaniki questów
- Actions, movements, talkactions, spells
- Monster XML, NPC XML + Lua
"""

from langchain_core.messages import HumanMessage, SystemMessage

from src.config.settings import get_llm
from src.prompts.backend_prompts import LUA_SCRIPTER_SYSTEM_PROMPT
from src.tools.file_tools import write_lua_script, write_xml_file, read_file, list_directory


# Narzędzia dostępne dla Lua Scripter Agent
LUA_SCRIPTER_TOOLS = [write_lua_script, write_xml_file, read_file, list_directory]


def create_lua_scripter_agent():
    """Tworzy agenta Lua Scripter z narzędziami do zapisu skryptów gry."""
    llm = get_llm()
    llm_with_tools = llm.bind_tools(LUA_SCRIPTER_TOOLS)

    def lua_scripter_node(state: dict) -> dict:
        """Węzeł Lua Scripter w grafie LangGraph."""
        messages = state.get("messages", [])
        map_context = state.get("map_context", {})

        # Dodaj kontekst mapy (koordynaty) jeśli dostępny
        context_msg = ""
        if map_context:
            context_msg = (
                f"\n\nKontekst mapy (koordynaty z World Integrator):\n"
                f"{_format_map_context(map_context)}"
            )

        system_prompt = LUA_SCRIPTER_SYSTEM_PROMPT + context_msg

        response = llm_with_tools.invoke(
            [SystemMessage(content=system_prompt)] + messages
        )

        return {
            "messages": messages + [response],
            "generated_code": response.content,
            "current_team": "backend",
        }

    return lua_scripter_node


def _format_map_context(ctx: dict) -> str:
    """Formatuje kontekst mapy do czytelnego tekstu."""
    parts = []
    if "towns" in ctx:
        for town in ctx["towns"]:
            pos = town.get("temple", {})
            parts.append(
                f"- Miasto: {town.get('name', '?')} (ID: {town.get('id')}) "
                f"→ temple: ({pos.get('x')}, {pos.get('y')}, {pos.get('z')})"
            )
    if "npc_positions" in ctx:
        for npc in ctx["npc_positions"]:
            pos = npc.get("position", {})
            parts.append(
                f"- NPC: {npc.get('name', '?')} → ({pos.get('x')}, {pos.get('y')}, {pos.get('z')})"
            )
    return "\n".join(parts) if parts else "Brak danych mapy."
