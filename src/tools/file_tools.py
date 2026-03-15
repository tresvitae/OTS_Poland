"""
Narzędzia do zarządzania plikami gry (Lua, XML, config).

Tools dostępne dla agentów do zapisu/odczytu plików w adventure-ots/data/.
"""

from pathlib import Path

from langchain_core.tools import tool

from src.config.settings import DATA_DIR, ADVENTURE_OTS_DIR


@tool
def write_file(filepath: str, content: str) -> str:
    """
    Zapisuje plik o podanej ścieżce (względem adventure-ots/).
    Tworzy katalogi pośrednie jeśli nie istnieją.

    Args:
        filepath: Ścieżka względna od adventure-ots/ (np. "data/actions/scripts/quest_lever.lua")
        content: Treść pliku do zapisania
    """
    target = ADVENTURE_OTS_DIR / filepath
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    return f"✅ Zapisano: {target}"


@tool
def write_lua_script(filepath: str, content: str) -> str:
    """
    Zapisuje skrypt Lua do folderu data/ serwera OTS.

    Args:
        filepath: Ścieżka względna od data/ (np. "actions/scripts/quest_lever.lua")
        content: Kod Lua do zapisania
    """
    target = DATA_DIR / filepath
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    return f"✅ Zapisano skrypt Lua: {target}"


@tool
def write_xml_file(filepath: str, content: str) -> str:
    """
    Zapisuje plik XML (potwór, NPC, konfiguracja) do folderu data/.

    Args:
        filepath: Ścieżka względna od data/ (np. "monster/dark_rat.xml")
        content: Treść XML do zapisania
    """
    target = DATA_DIR / filepath
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    return f"✅ Zapisano XML: {target}"


@tool
def read_file(filepath: str) -> str:
    """
    Odczytuje zawartość pliku.

    Args:
        filepath: Ścieżka względna od adventure-ots/ (np. "data/monster/rat.xml")
    """
    target = ADVENTURE_OTS_DIR / filepath
    if not target.exists():
        return f"❌ Plik nie istnieje: {target}"
    return target.read_text(encoding="utf-8")


@tool
def list_directory(dirpath: str) -> str:
    """
    Listuje pliki i katalogi w podanej lokalizacji.

    Args:
        dirpath: Ścieżka względna od adventure-ots/ (np. "data/monster")
    """
    target = ADVENTURE_OTS_DIR / dirpath
    if not target.exists():
        return f"❌ Katalog nie istnieje: {target}"

    items = []
    for item in sorted(target.iterdir()):
        prefix = "📁" if item.is_dir() else "📄"
        items.append(f"{prefix} {item.name}")

    return f"Zawartość {dirpath}/:\n" + "\n".join(items) if items else f"Katalog {dirpath}/ jest pusty."
