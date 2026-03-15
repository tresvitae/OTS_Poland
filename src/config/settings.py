"""
Konfiguracja aplikacji — ładowanie zmiennych środowiskowych i ustawienia LLM.
"""

import os
from pathlib import Path

from dotenv import load_dotenv

# ── Ścieżki ─────────────────────────────────────────────────
ROOT_DIR = Path(__file__).resolve().parent.parent.parent  # tibia/
SRC_DIR = ROOT_DIR / "src"
ADVENTURE_OTS_DIR = ROOT_DIR / "adventure-ots"
DATA_DIR = ADVENTURE_OTS_DIR / "data"

# ── Ładowanie .env ───────────────────────────────────────────
load_dotenv(ROOT_DIR / ".env")

# ── Anthropic (Claude) ───────────────────────────────────────
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")
LLM_MODEL = os.getenv("LLM_MODEL", "claude-sonnet-4-20250514")
LLM_TEMPERATURE = float(os.getenv("LLM_TEMPERATURE", "0.2"))

# ── LangSmith Tracing ───────────────────────────────────────
LANGCHAIN_TRACING_V2 = os.getenv("LANGCHAIN_TRACING_V2", "true")
LANGCHAIN_API_KEY = os.getenv("LANGCHAIN_API_KEY", "")
LANGCHAIN_PROJECT = os.getenv("LANGCHAIN_PROJECT", "adventure-ots-agents")

# ── Serwer OTS ───────────────────────────────────────────────
SERVER_IP = os.getenv("SERVER_IP", "127.0.0.1")
SERVER_NAME = os.getenv("SERVER_NAME", "Adventure OTS")

# ── Baza danych ──────────────────────────────────────────────
DB_NAME = os.getenv("DB_NAME", "adventureots")
DB_USER = os.getenv("DB_USER", "otserver")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")

# ── Ścieżki danych gry ──────────────────────────────────────
SCRIPTS_DIR = DATA_DIR / "scripts"
MONSTERS_DIR = DATA_DIR / "monster"
NPC_DIR = DATA_DIR / "npc"
WORLD_DIR = DATA_DIR / "world"
XML_DIR = DATA_DIR / "XML"
ACTIONS_DIR = DATA_DIR / "actions"
MOVEMENTS_DIR = DATA_DIR / "movements"
TALKACTIONS_DIR = DATA_DIR / "talkactions"
CREATURESCRIPTS_DIR = DATA_DIR / "creaturescripts"
GLOBALEVENTS_DIR = DATA_DIR / "globalevents"
SPELLS_DIR = DATA_DIR / "spells"


def get_llm():
    """Tworzy instancję Anthropic LLM z ustawieniami."""
    from langchain_anthropic import ChatAnthropic

    return ChatAnthropic(
        model=LLM_MODEL,
        temperature=LLM_TEMPERATURE,
        anthropic_api_key=ANTHROPIC_API_KEY,
    )
