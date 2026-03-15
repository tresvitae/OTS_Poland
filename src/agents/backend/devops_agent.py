"""
DevOps Agent — Database/Infrastructure/DevOps dla Adventure OTS.

Tworzy:
- docker-compose.yml, Dockerfiles
- Skrypty SQL inicjalizacyjne
- Konfigurację serwera (config.lua, config.php)
- Skrypty backupu i firewalla
"""

from langchain_core.messages import HumanMessage, SystemMessage

from src.config.settings import get_llm
from src.prompts.backend_prompts import DEVOPS_SYSTEM_PROMPT
from src.tools.file_tools import write_file, read_file, list_directory


# Narzędzia dostępne dla DevOps Agent
DEVOPS_TOOLS = [write_file, read_file, list_directory]


def create_devops_agent():
    """Tworzy agenta DevOps z narzędziami do zarządzania infrastrukturą."""
    llm = get_llm()
    llm_with_tools = llm.bind_tools(DEVOPS_TOOLS)

    def devops_node(state: dict) -> dict:
        """Węzeł DevOps w grafie LangGraph."""
        messages = state.get("messages", [])

        response = llm_with_tools.invoke(
            [SystemMessage(content=DEVOPS_SYSTEM_PROMPT)] + messages
        )

        return {
            "messages": messages + [response],
            "generated_code": response.content,
            "current_team": "backend",
        }

    return devops_node
