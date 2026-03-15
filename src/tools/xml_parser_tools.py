"""
Narzędzia do parsowania plików XML mapy OTS.

Parsuje map-spawns.xml i map-houses.xml → wyciąga koordynaty.
"""

import xml.etree.ElementTree as ET
from pathlib import Path

from langchain_core.tools import tool

from src.config.settings import WORLD_DIR


@tool
def parse_spawns_xml(filepath: str = "") -> str:
    """
    Parsuje plik map-spawns.xml i zwraca listę spawnów z koordynatami.

    Args:
        filepath: Opcjonalna ścieżka do pliku. Domyślnie: data/world/map-spawns.xml
    """
    if filepath:
        target = Path(filepath)
    else:
        target = WORLD_DIR / "map-spawns.xml"

    if not target.exists():
        return f"❌ Plik nie istnieje: {target}"

    try:
        tree = ET.parse(target)
        root = tree.getroot()
    except ET.ParseError as e:
        return f"❌ Błąd parsowania XML: {e}"

    spawns = []
    for spawn in root.findall(".//spawn"):
        cx = int(spawn.get("centerx", 0))
        cy = int(spawn.get("centery", 0))
        cz = int(spawn.get("centerz", 0))
        radius = int(spawn.get("radius", 0))

        monsters = []
        for monster in spawn.findall("monster"):
            name = monster.get("name", "?")
            mx = int(monster.get("x", 0))
            my = int(monster.get("y", 0))
            mz = int(monster.get("z", 0))
            spawntime = int(monster.get("spawntime", 60))
            monsters.append({
                "name": name,
                "abs_x": cx + mx,
                "abs_y": cy + my,
                "abs_z": cz + mz,
                "spawntime": spawntime,
            })

        npcs = []
        for npc in spawn.findall("npc"):
            name = npc.get("name", "?")
            nx = int(npc.get("x", 0))
            ny = int(npc.get("y", 0))
            nz = int(npc.get("z", 0))
            npcs.append({
                "name": name,
                "abs_x": cx + nx,
                "abs_y": cy + ny,
                "abs_z": cz + nz,
            })

        spawns.append({
            "center": {"x": cx, "y": cy, "z": cz},
            "radius": radius,
            "monsters": monsters,
            "npcs": npcs,
        })

    return _format_spawns(spawns)


@tool
def parse_houses_xml(filepath: str = "") -> str:
    """
    Parsuje plik map-houses.xml i zwraca listę domów z koordynatami wejść.

    Args:
        filepath: Opcjonalna ścieżka do pliku. Domyślnie: data/world/map-houses.xml
    """
    if filepath:
        target = Path(filepath)
    else:
        target = WORLD_DIR / "map-houses.xml"

    if not target.exists():
        return f"❌ Plik nie istnieje: {target}"

    try:
        tree = ET.parse(target)
        root = tree.getroot()
    except ET.ParseError as e:
        return f"❌ Błąd parsowania XML: {e}"

    houses = []
    for house in root.findall(".//house"):
        houses.append({
            "id": int(house.get("houseid", 0)),
            "name": house.get("name", "?"),
            "entry": {
                "x": int(house.get("entryx", 0)),
                "y": int(house.get("entryy", 0)),
                "z": int(house.get("entryz", 0)),
            },
            "rent": int(house.get("rent", 0)),
            "town_id": int(house.get("townid", 0)),
            "size": int(house.get("size", 0)),
            "beds": int(house.get("beds", 0)),
        })

    return _format_houses(houses)


@tool
def get_town_coordinates(town_name: str = "") -> str:
    """
    Wyciąga koordynaty świątyni (temple) dla miasta.
    Na razie zwraca placeholder — wymaga ręcznego podania lub konfiguracji.

    Args:
        town_name: Nazwa miasta (np. "Main Town")
    """
    # Te dane powinny pochodzić z config.lua lub map-towns.xml
    # Na razie: placeholder, użytkownik poda ręcznie
    return (
        f"⚠️ Koordynaty miasta '{town_name}' nie są jeszcze skonfigurowane.\n"
        f"Podaj ręcznie koordynaty świątyni (temple position) w formacie: X, Y, Z\n"
        f"Np. dla 'Main Town': 1000, 1000, 7\n\n"
        f"Te dane znajdziesz w:\n"
        f"- config.lua → town_id i pozycje startowe\n"
        f"- Remere's Map Editor → właściwości miasta"
    )


def _format_spawns(spawns: list) -> str:
    """Formatuje dane spawnów do czytelnego tekstu."""
    lines = [f"🗺️ Znaleziono {len(spawns)} stref spawnów:\n"]
    for i, spawn in enumerate(spawns, 1):
        c = spawn["center"]
        lines.append(f"--- Spawn #{i} ---")
        lines.append(f"  Centrum: ({c['x']}, {c['y']}, {c['z']}), radius: {spawn['radius']}")
        if spawn["monsters"]:
            lines.append(f"  Potwory ({len(spawn['monsters'])}):")
            for m in spawn["monsters"][:5]:  # max 5
                lines.append(f"    - {m['name']} → ({m['abs_x']}, {m['abs_y']}, {m['abs_z']}), respawn: {m['spawntime']}s")
            if len(spawn["monsters"]) > 5:
                lines.append(f"    ... i {len(spawn['monsters']) - 5} więcej")
        if spawn["npcs"]:
            lines.append(f"  NPC ({len(spawn['npcs'])}):")
            for n in spawn["npcs"]:
                lines.append(f"    - {n['name']} → ({n['abs_x']}, {n['abs_y']}, {n['abs_z']})")
    return "\n".join(lines)


def _format_houses(houses: list) -> str:
    """Formatuje dane domów do czytelnego tekstu."""
    lines = [f"🏠 Znaleziono {len(houses)} domów:\n"]
    for h in houses[:20]:  # max 20
        e = h["entry"]
        lines.append(
            f"  #{h['id']} {h['name']} → wejście: ({e['x']}, {e['y']}, {e['z']}), "
            f"czynsz: {h['rent']}gp, town: {h['town_id']}, rozmiar: {h['size']}, łóżka: {h['beds']}"
        )
    if len(houses) > 20:
        lines.append(f"  ... i {len(houses) - 20} więcej")
    return "\n".join(lines)
