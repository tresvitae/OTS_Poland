---
name: Game Content Development
description: "Lua scripting for TFS 1.4.2 game engine (NPCs, spells, items, creatures). Use when: writing Lua scripts, creating/modifying game content, debugging game mechanics, adding quests or events, configuring creatures/spells/items, or testing in-game behavior. Covers: Lua 5.1 syntax, TFS API functions, script structure, creature behavior, spell systems."
applyTo: "adventure-ots/tfs/**/*.lua"
---

# Game Content Development Guidelines (TFS 1.4.2 Lua Scripting)

**Location**: `adventure-ots/tfs/data/`

All game content is scripted in Lua 5.1 (strict compatibility required). TFS 1.4.2 provides a rich API for creatures, spells, items, NPCs, and events. Scripts are hot-reloaded in most cases without restarting the server.

---

## 🚀 Quick Start

### Viewing/Changing Content
```bash
# Navigate to content folder
cd adventure-ots/tfs/data

# List content directories
ls -la

# Edit or create Lua scripts and XML configs
# Changes are often hot-reloaded (except major config changes)

# If changes don't take effect:
docker compose restart gameserver    # Full restart
```

### Test In-Game
1. Open OTClient
2. Connect to `127.0.0.1:7171`
3. Login with default credentials (`1` / `1`)
4. Test new content (NPCs, items, spells)
5. Check server logs if issues occur: `docker logs -f ots_engine`

---

## 📂 Directory Structure

```
tfs/data/
├── creaturescripts/        # Creature behavior (monsters, NPCs)
│   ├── login.lua           # Player login event
│   ├── logout.lua          # Player logout event
│   ├── death.lua           # Creature death handler
│   └── ...
├── spells/                 # Spell definitions
│   ├── instant/            # Instant-cast spells
│   ├── conjure/            # Conjure spells (create items)
│   ├── rune/               # Rune spells
│   └── ...
├── items/                  # Item behavior & use effects
│   ├── containers/
│   ├── tools/
│   └── ...
├── npc/                    # NPC dialogue & interaction
│   ├── npc_name.lua        # Individual NPC script
│   └── ...
├── scripts/                # General Lua utilities
│   ├── lib/
│   ├── functions/
│   └── ...
├── xml/                    # Configuration XML files
│   ├── creatures.xml       # Monster/NPC definitions
│   ├── items.xml           # Item definitions
│   ├── spells.xml          # Spell definitions
│   └── ...
├── world/                  # Map files (.otbm)
├── config.lua              # Main server configuration
└── startup.lua             # Server startup script
```

---

## 🔑 Lua 5.1 Language Fundamentals

### Basic Syntax (TFS-Compatible)
```lua
-- Comments use --

-- Variables
local playerName = "Adventurer"
local level = 50
local isAlive = true

-- Tables (dictionaries/arrays)
local player = {
  name = "Hero",
  level = 30,
  health = 100,
  items = { "sword", "shield" }
}

-- Access table values
print(player.name)        -- "Hero"
print(player["level"])    -- 30
print(player.items[1])    -- "sword"

-- Loops
for i = 1, 10 do
  print(i)
end

for key, value in pairs(player) do
  print(key, value)
end

-- Conditionals
if level >= 20 then
  print("High level!")
elseif level >= 10 then
  print("Mid level")
else
  print("Low level")
end

-- Functions
local function calculateDamage(baseDamage, multiplier)
  return baseDamage * multiplier
end

local damage = calculateDamage(10, 1.5)  -- 15
```

### String Operations
```lua
-- Concatenation
local message = "Hello, " .. playerName .. "!"

-- String functions
local text = "adventure ots"
print(string.upper(text))        -- "ADVENTURE OTS"
print(string.len(text))          -- 13
print(string.sub(text, 1, 9))    -- "adventure"
print(string.find(text, "ots"))  -- 12, "o"
```

### Table Operations
```lua
-- Creating tables
local inventory = {}
table.insert(inventory, "sword")    -- Add item
table.insert(inventory, "shield")

table.remove(inventory, 1)          -- Remove item at index 1

-- Get table size
print(#inventory)                   -- 1 (after removal)

-- Table iteration
for index, item in ipairs(inventory) do
  print(index, item)
end
```

---

## 🎮 TFS 1.4.2 API Essentials

### Creature Operations
```lua
-- Get creature by ID or name
local creature = Creature("PlayerName")
local monster = Creature(creatureId)

-- Creature properties
if creature then
  local health = creature:getHealth()
  local maxHealth = creature:getMaxHealth()
  local level = creature:getLevel()
  local vocation = creature:getVocation()
  local pos = creature:getPosition()
  
  -- Modify creature
  creature:addHealth(50)
  creature:setHealth(100)
  creature:addMana(20)
end

-- Check if creature is player
if creature:isPlayer() then
  print("Is a player")
end

-- Get all players/monsters in area
local spectators = Game.getSpectators(position, multifloor, onlyPlayers, minX, maxX, minY, maxY)
for _, creature in pairs(spectators) do
  print(creature:getName())
end
```

### Player Operations
```lua
-- Get player by name/ID
local player = Player("PlayerName")
local player = Player(playerId)

if player then
  -- Basic info
  local name = player:getName()
  local level = player:getLevel()
  local experience = player:getExperience()
  local account = player:getAccount()
  
  -- Inventory & items
  local item = player:getSlotItem(CONST_SLOT_HEAD)
  local itemCount = player:getItemCount(itemId)
  
  -- Inventory management
  player:addItem(itemId, count)
  player:removeItem(itemId, count)
  
  -- Mana & health
  player:addMana(100)
  player:setMana(100)
  player:addHealth(50)
  player:setHealth(100)
  
  -- Skills
  player:addSkillTries(SKILL_MELEE, 100)
  player:getSkillLevel(SKILL_MELEE)
  
  -- Spells & abilities
  player:learnSpell("spellname")
  player:forgetSpell("spellname")
end
```

### Item Operations
```lua
-- Get item instance
local item = Item(itemId)

if item then
  local itemId = item:getId()
  local count = item:getCount()
  local weight = item:getWeight()
  local owner = item:getTopParent()
  
  -- Modify item
  item:setCount(10)
  item:remove()
  
  -- Check item attributes
  local text = item:getAttribute(ITEM_ATTRIBUTE_TEXT)
  item:setAttribute(ITEM_ATTRIBUTE_TEXT, "Inscription")
end
```

### Position & Movement
```lua
-- Create position
local pos = Position(x, y, z)

-- Get distance
local distance = pos:getDistance(otherPos)

-- Move creature
creature:move(toPosition)
player:teleportTo(position)

-- Check if walkable
if getTile(position):getTopGround() then
  print("Tile is walkable")
end
```

### Combat & Damage
```lua
-- Deal damage
local damage = 50
local damageType = COMBAT_PHYSICAL
local effect = CONST_ME_HITAREA

creature:takeDamage(damage)
doTargetCombatHealth(cid, target, damageType, damage, damage, effect)

-- Healing
player:heal(amount)

-- Add status effect
player:addCondition(condition)
```

---

## 🧟 Creature Scripts (`creaturescripts/`)

### Directory Structure
```
creaturescripts/
├── scripts/
│   ├── login.lua        # OnLogin event
│   ├── logout.lua       # OnLogout event
│   ├── death.lua        # OnDeath event
│   ├── think.lua        # OnThink event
│   └── ...
└── default.xml          # Event registration (XML)
```

### Login Event
```lua
-- data/creaturescripts/scripts/login.lua
local ec = EventCallback()

function ec.onLogin(player)
  print(player:getName() .. " logged in!")
  
  -- Restore player state
  player:setHealth(player:getMaxHealth())
  player:setMana(player:getMaxMana())
  
  -- Grant login reward
  player:addExperience(100)
  
  -- Send message
  player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "Welcome back!")
  
  return true
end

ec:register()
```

### Death Event
```lua
-- data/creaturescripts/scripts/death.lua
local ec = EventCallback()

function ec.onDeath(creature, corpse, killer)
  if killer == nil then
    return true
  end
  
  if creature:isPlayer() and killer:isPlayer() then
    killer:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "You killed " .. creature:getName())
  end
  
  -- Grant killer experience
  if killer:isPlayer() then
    killer:addExperience(100)
  end
  
  return true
end

ec:register()
```

---

## ✨ Spell Scripts (`spells/`)

### Instant Spell Example
```lua
-- data/spells/instant/exori.lua
local spell = Spell()

spell.name = "Exori"
spell.words = "exori"
spell.needLogout = false
spell.level = 60
spell.mana = 100

function spell.onCastSpell(creature, variant)
  local spectators = Game.getSpectators(creature:getPosition(), false, true, 7, 7, 5, 5)
  
  for _, target in pairs(spectators) do
    if target ~= creature and target:isCreature() then
      -- Deal 150 physical damage
      local damage = 150
      target:takeDamage(damage)
      
      -- Show effect
      position:sendMagicEffect(CONST_ME_HITBYTYPE)
    end
  end
  
  return true
end

spell:register()
```

### Conjure Spell Example
```lua
-- data/spells/conjure/light_magic_missile.lua
local spell = Spell()

spell.name = "Light Magic Missile Rune"
spell.words = "adori gran"
spell.level = 15
spell.mana = 100
spell.target = false
spell.cooldown = 5
spell.castSound = SOUND_EFFECT_SPELL_CAST

function spell.onCastSpell(creature, variant)
  -- Create 3 runes
  local item = Game.createItem(12395, 3, creature:getPosition())
  
  if item then
    creature:addItemEx(item)
    creature:sendTextMessage(MESSAGE_STATUS_CONSOLE_GREEN, "3 Light Magic Missiles created.")
  end
  
  return true
end

spell:register()
```

---

## 🧠 NPC Scripts (`npc/`)

### Basic NPC
```lua
-- data/npc/npc_name.lua
local npc = Npc()

function npc.onCreatureAppear(cid)
  -- Called when creature sees NPC
end

function npc.onCreatureDisappear(cid)
  -- Called when creature leaves NPC
end

function npc.onCreatureSay(cid, class, text)
  if not npc:isFocused(cid) then
    return false
  end
  
  if text:lower() == "hello" then
    npc:say("Hello, traveler! What do you need?")
  elseif text:lower() == "job" then
    npc:say("I am a simple merchant.", cid)
  elseif text:lower() == "buy" then
    npc:openShopWindow(cid, {
      { name = "Sword", id = 3264, buy = 100 },
      { name = "Shield", id = 3264, buy = 80 }
    })
  end
  
  return true
end

function npc.onPlayerTrade(cid, action, itemid, count, coin, costume)
  return true
end

function npc.onThink()
  -- Called periodically
end

npc:register()
```

---

## ⚠️ XML Configuration

### Creature Definition (`creatures.xml`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<creatures>
  <creature name="Rat" nameDescription="a rat" race="blood" experience="5" speed="30" manacost="0">
    <health now="8" max="8"/>
    <look type="21" corpse="3058"/>
    <targetchange interval="4000" chance="10"/>
    <strategy attack="100" defense="0"/>
    <flags>
      <flag summonable="1"/>
      <flag attackable="1"/>
      <flag hostile="1"/>
      <flag illusionable="1"/>
      <flag convinceable="1"/>
      <flag pushable="1"/>
      <flag canpushitems="1"/>
      <flag canpushcreatures="0"/>
    </flags>
    <attacks>
      <attack name="melee" interval="1000" chance="100" range="1" min="-1" max="-3"/>
    </attacks>
    <defenses armor="1" defense="2">
      <defense name="healing" interval="1000" chance="10" range="0" min="4" max="8">
        <animate text="rururu" effect="2"/>
      </defense>
    </defenses>
    <voices interval="5000" chance="10">
      <voice sentence="Squeak!"/>
    </voices>
    <loot>
      <item id="2148" countmax="1" chance="40"/><!-- gold coin -->
    </loot>
  </creature>
</creatures>
```

### Spell Definition (`spells.xml`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<spells>
  <instant name="Exori" words="exori" lvl="60" mana="100" prem="0" range="1" casterTargetOrDirection="1" blockwalls="1" script="instant/exori.lua">
    <vocation name="Knight"/>
    <vocation name="Elite Knight"/>
  </instant>
</spells>
```

---

## 🐛 Common Pitfalls

### ❌ Using Global Variables Instead of Local
```lua
-- WRONG: Global scope pollution
function damageCreature(creature, amount)
  creature:takeDamage(amount)  -- 'creature' is now global!
end

-- CORRECT: Use local
local function damageCreature(creature, amount)
  creature:takeDamage(amount)
end
```

### ❌ Not Checking for Nil
```lua
-- WRONG: Will crash if player is nil
local player = Player("NonExistent")
player:addHealth(100)  -- ERROR!

-- CORRECT: Check first
local player = Player("NonExistent")
if player then
  player:addHealth(100)
end
```

### ❌ Forgetting Lua 5.1 Compatibility
```lua
-- WRONG: Lua 5.3+ syntax (table.pack, etc.)
local function test(...)
  local args = table.pack(...)  -- Not available in Lua 5.1
end

-- CORRECT: Lua 5.1 compatible
local function test(...)
  local args = { ... }
end
```

### ❌ Not Registering Scripts in XML
```lua
-- data/creaturescripts/scripts/login.lua exists
-- But data/creaturescripts/default.xml doesn't reference it
-- Result: Script never runs!

-- CORRECT: Register in XML
<!-- data/creaturescripts/default.xml -->
<event type="login" name="PlayerLogin" script="scripts/login.lua"/>
```

---

## 🔄 Hot-Reload & Testing

### Which Changes Require Restart?
| Change | Hot-Reload | Requires Restart |
|--------|-----------|------------------|
| Lua script in `scripts/` | ✅ Yes | ❌ No (usually) |
| Spell modifications | ✅ Yes | ❌ No (usually) |
| Item modifications | ✅ Yes | ❌ No (usually) |
| `config.lua` | ❌ No | ✅ Yes |
| `startup.lua` | ❌ No | ✅ Yes |
| XML changes (`spells.xml`, etc.) | ⚠️ Maybe | ✅ Usually Yes |

### Reloading Scripts
```bash
# Full restart (safest)
docker compose restart gameserver

# Check if running
docker ps | grep ots_engine

# View logs
docker logs -f ots_engine
```

### Debug Messages
```lua
-- Print to console (visible in logs)
print("Debug message: " .. tostring(value))

-- Send message to player
player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "Debug: " .. text)

-- View live logs
docker logs -f ots_engine | grep "Debug message"
```

---

## 📖 Reference

- [TFS 1.4.2 Lua API Wiki](https://github.com/otland/forgottenserver/wiki)
- [Lua 5.1 Manual](https://www.lua.org/manual/5.1/)
- [TFS 1.4.2 GitHub](https://github.com/otland/forgottenserver/tree/master)
- [OTServer Community](https://otland.net/)
- [TFS Configuration](../../../adventure-ots/tfs/config.lua.dist)
