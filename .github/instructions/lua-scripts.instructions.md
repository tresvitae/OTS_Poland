---
name: TFS Lua Scripts
description: "TFS 1.4.2 Lua scripting guidance for Adventure OTS. Use for gameplay scripts under tfs/data."
applyTo: "adventure-ots/tfs/data/**/*.lua"
---

# TFS 1.4.2 Lua Scripting Standards

Use these standards for all Lua files in `adventure-ots/tfs/data/`.

## 1. Nil Safety (Always)

Every `Player`/`Creature`/`Item` reference must be guarded:

```lua
-- BAD
local function onCastSpell(creature, var)
    creature:getPosition() -- may crash if creature is nil
end

-- GOOD
local function onCastSpell(creature, var)
    if not creature or not creature:isCreature() then
        return false
    end
    local pos = creature:getPosition()
end
```

## 2. Revscriptsys Registration

Scripts in `data/scripts/` are autoloaded, but each script object must be registered:

```lua
local exampleSpell = Spell("exampleSpell")
-- ... config ...
exampleSpell:register()
```

## 3. Avoid Deprecated API

| Deprecated | Preferred (TFS 1.4+) |
|---|---|
| `doPlayerAddItem(cid, id)` | `player:addItem(id)` |
| `getCreatureName(cid)` | `creature:getName()` |
| `getPlayerLevel(cid)` | `player:getLevel()` |
| `doSendMagicEffect(pos, e)` | `pos:sendMagicEffect(e)` |
| `getTileItemById(pos, id)` | `Tile(pos):getItemById(id)` |
| Creature IDs (`cid`) | Direct Lua objects |

## 4. Database Safety

Always escape user/player input and free query resources:

```lua
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

## 5. Loot Chance Rules

- Scale: `0` = never, `100000` = always (100%)
- `1000` = 1%, `500` = 0.5%, `100` = 0.1%
- Rolls are independent; sum may exceed `100000`
- `chance = 100000` is guaranteed drop

## 6. Global Event Hygiene

Global events must return `true` and clean temporary state:

```lua
local ExampleEvent = GlobalEvent("ExampleEvent")

function ExampleEvent.onThink(interval)
    for guid, data in pairs(tempStorage) do
        if os.time() > data.expires then
            tempStorage[guid] = nil
        end
    end
    return true
end

ExampleEvent:interval(60000)
ExampleEvent:register()
```

## 7. Storage Key Ranges

Use reserved ranges to avoid collisions:

```lua
STORAGE_QUEST_MAIN = 30000      -- 30000-30999
STORAGE_SYSTEM_PREMIUM = 40000  -- 40000-40999
STORAGE_CUSTOM_FEATURE = 50000  -- 50000+
```

## 8. Performance in Hot Paths

Avoid expensive calls in frequent events (`onThink`, combat loops). Cache where possible.

## 9. Quick Checklist

- Lua 5.1-compatible syntax only
- Nil-check all object access
- Prefer modern object API
- Keep DB calls escaped and resource-safe
- Keep hot-path logic lightweight
