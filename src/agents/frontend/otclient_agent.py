"""
OTClient Lua Dev Agent — specjalista od interfejsu klienta.

Konfiguruje:
- Moduły Lua w OTClient Mehah
- Adres IP serwera
- Klucze RSA
- Wyłączanie market module
"""

from langchain_core.messages import HumanMessage, SystemMessage

from src.config.settings import get_llm
from src.prompts.frontend_prompts import OTCLIENT_SYSTEM_PROMPT
from src.tools.file_tools import write_file, read_file, list_directory


OTCLIENT_TOOLS = [write_file, read_file, list_directory]


def create_otclient_agent():
    """Tworzy agenta OTClient Lua Dev."""
    llm = get_llm()
    llm_with_tools = llm.bind_tools(OTCLIENT_TOOLS)

    def otclient_node(state: dict) -> dict:
        """Węzeł OTClient Dev w grafie LangGraph."""
        messages = state.get("messages", [])

        response = llm_with_tools.invoke(
            [SystemMessage(content=OTCLIENT_SYSTEM_PROMPT)] + messages
        )

        return {
            "messages": messages + [response],
            "generated_code": response.content,
            "current_team": "frontend",
        }

    return otclient_node
