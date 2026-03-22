---
mode: agent
description: "Generate a complete TFS 1.4.2 monster (Lua revscriptsys) with balanced stats, attacks, loot, and registration guidance."
---

Create a complete new monster for TFS 1.4.2 (revscriptsys).

If required parameters are missing, ask a short clarification question first.

Parameters:
- Name: `${monsterName}`
- Type: `${monsterType}` (undead, demon, animal, humanoid, elemental)
- Difficulty: `${difficulty}` (easy/medium/hard/boss)
- World location: `${location}`

---

## File target

`adventure-ots/tfs/data/monster/${monsterName}.lua`

Generate Lua with all sections below. Avoid deprecated API usage.

### Section 1: MonsterType definition

```lua
local mType = Game.createMonsterType("${monsterName}")
local monster = {}

monster.description = "${monsterName}"
monster.experience = 0
monster.outfit = {
    lookType = 0,
    lookHead = 0,
    lookBody = 0,
    lookLegs = 0,
    lookFeet = 0,
}

monster.health = 0
monster.maxHealth = monster.health
monster.race = RACE_BLOOD
monster.corpse = 0

monster.speed = 0
monster.manaCost = 0
```

### Section 2: Flags and immunities

```lua
monster.flags = {
    summonable = false,
    attackable = true,
    hostile = true,
    convinceable = false,
    pushable = false,
    rewardBoss = false,
    illusionable = false,
    canPushItems = true,
    canPushCreatures = false,
    targetDistance = 1,
    staticAttackChance = 90,
    runHealth = 0,
    healthHidden = false,
    isBlockable = false,
    canWalkOnEnergy = false,
    canWalkOnFire = false,
    canWalkOnPoison = false,
}

monster.immunities = {
    -- Example: { type = "fire", combat = true, condition = true }
}
```

### Section 3: Combat (attacks and abilities)

```lua
monster.attacks = {
    -- Always start with melee
    { name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = 0 },
    -- Add skills/spells matching monster type and difficulty
}

monster.defenses = {
    defense = 0,
    armor = 0,
    -- Optional healing entry may be added for hard/boss monsters
}
```

### Section 4: Loot table

```lua
monster.loot = {
    -- Format: { id = ITEM_ID, chance = 0..100000, minCount = 1, maxCount = 1 }
    -- 100000 = 100%, 1000 = 1%, 100 = 0.1%
    -- Include baseline gold by difficulty
    { id = Item.ids.gold_coin, chance = 100000, minCount = 1, maxCount = 100 },
}
```

### Section 5: Registration

```lua
-- Always keep this block at the end
mType:register(monster)
```

---

## Output requirements

1. Return complete Lua content only once (no duplicate variants).
2. Include a short balancing note: why HP/damage/exp are consistent.
3. Include a quick spawn suggestion based on `${location}`.
4. If XML registration is needed in this specific repo, mention exact file and entry; otherwise state that revscriptsys autoload applies.
5. Keep all code Lua 5.1-compatible.