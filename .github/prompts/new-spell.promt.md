---
mode: agent
description: Tworzy kompletny spell dla TFS (revscriptsys) — plik Lua + rejestracja
---

Stwórz nowy spell dla TFS  (revscriptsys). Potrzebuję:

1. Plik `data/scripts/spells/${spellName}.lua` z:
   - `Spell()` object z pełną konfiguracją
   - `spell:onCastSpell(creature, var)` — z nil-safety na target
   - Obsługę cooldownu, mana cost, level requirement

2. Wpis do `data/scripts/lib/spells_config.lua` jeśli istnieje

3. Komunikat dla gracza jeśli spell misses/fails

Parametry spella: ${spellName}, vocation: ${vocation}, damage: ${minDmg}-${maxDmg}