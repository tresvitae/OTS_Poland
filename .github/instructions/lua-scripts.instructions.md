---
applyTo: "data/**/*.lua"
---

# TFS 1.5 Lua Scripting — Zasady Copilota

## Nil Safety — ZAWSZE

Każde odwołanie do creature/player/item MUSI być poprzedzone nil-checkiem:

```lua
-- ŹLE
local function onCastSpell(creature, var)
    creature:getPosition()  -- crash jeśli creature nil lub offline
end

-- DOBRZE
local function onCastSpell(creature, var)
    if not creature or not creature:isCreature() then
        return false
    end
    local pos = creature:getPosition()
end
```

## Revscriptsys — rejestracja skryptów

Pliki w `data/scripts/` ładują się automatycznie. Każdy plik MUSI kończyć się rejestracją:

```lua
-- Spell
local exampleSpell = Spell("exampleSpell")
-- ... konfiguracja ...
exampleSpell:register()

-- Action
local exampleAction = Action()
-- ... konfiguracja ...
exampleAction:register()

-- TalkAction
local exampleTalk = TalkAction("/example")
-- ... konfiguracja ...
exampleTalk:register()
```

## Deprecated API — nigdy nie używaj

| Stare (deprecated) | Nowe (TFS 1.4+) |
|---|---|
| `doPlayerAddItem(cid, id)` | `player:addItem(id)` |
| `getCreatureName(cid)` | `creature:getName()` |
| `getPlayerLevel(cid)` | `player:getLevel()` |
| `doSendMagicEffect(pos, e)` | `pos:sendMagicEffect(e)` |
| `getTileItemById(pos, id)` | `Tile(pos):getItemById(id)` |
| Numery creature ID (`cid`) | Bezpośrednie obiekty Lua |

## Database — tylko przez db.query z escape

```lua
-- ŹLE — podatne na SQL injection
db.query("SELECT * FROM players WHERE name = '" .. playerName .. "'")

-- DOBRZE
local query = string.format(
    "SELECT `id`, `level` FROM `players` WHERE `name` = %s",
    db.escapeString(playerName)
)
local resultId = db.storeQuery(query)
if resultId ~= false then
    local level = result.getDataInt(resultId, "level")
    result.free(resultId)
end
```

## Loot tables — zasady prawdopodobieństwa

- Skala: `0` = nigdy, `100000` = zawsze (100%)
- `1000` = 1%, `500` = 0.5%, `100` = 0.1%
- Suma szans w tabeli może przekraczać 100000 — TFS rzuca niezależnie dla każdej pozycji
- Item z `chance = 100000` to **guaranteed drop** — dodawaj świadomie

## Eventy globalne — cleanup po sobie

```lua
local GlobalEventExample = GlobalEvent("ExampleTimer")

function GlobalEventExample.onThink(interval)
    -- cleanup tymczasowych danych
    for guid, data in pairs(tempStorage) do
        if os.time() > data.expires then
            tempStorage[guid] = nil
        end
    end
    return true  -- MUSI zwrócić true, inaczej event się wyłącza
end

GlobalEventExample:interval(60000)  -- co 60 sekund
GlobalEventExample:register()
```

## Storage keys — unikaj konfliktów

Używaj zarezerwowanych zakresów dla własnych featurów:
```lua
-- Definiuj w data/lib/constants.lua
STORAGE_QUEST_MAIN      = 30000  -- questy: 30000-30999
STORAGE_SYSTEM_PREMIUM  = 40000  -- system features: 40000-40999
STORAGE_CUSTOM_FEATURE  = 50000  -- własne dodatki: 50000+
```

## Wydajność — unikaj w hot-path

```lua
-- ŹLE w onThink() wywoływanym co 2s dla każdego monstera
local allPlayers = Game.getPlayers()  -- kosztowne

-- DOBRZE — cache na poziomie globalnym, refresh co N sekund
local cachedPlayerCount = 0
local lastCacheTime = 0
local function getPlayerCount()
    if os.time() - lastCacheTime > 30 then
        cachedPlayerCount = #Game.getPlayers()
        lastCacheTime = os.time()
    end
    return cachedPlayerCount
end
```