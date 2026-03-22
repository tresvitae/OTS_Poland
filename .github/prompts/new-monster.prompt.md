---
mode: agent
description: Generuje kompletnego nowego potwora dla TFS 1.5 — plik Lua w data/monster/ z logiką skryptów, loot table i AI flags
---

Stwórz kompletnego nowego potwora dla TFS 1.5 (revscriptsys). Użyj następujących parametrów:

**Parametry do uzupełnienia (zapytaj jeśli nie podano):**
- Nazwa: ${monsterName}
- Typ: ${monsterType} (np. undead, demon, animal, humanoid)
- Poziom trudności: ${difficulty} (easy/medium/hard/boss)
- Lokalizacja w świecie: ${location}

---

## Struktura pliku: `data/monster/${monsterName}.lua`

Wygeneruj plik Lua z WSZYSTKIMI sekcjami poniżej. Nie używaj przestarzałego formatu XML.

### Sekcja 1: Definicja MonsterType

```lua
local mtype = Game.createMonsterType("${monsterName}")
local monster = {}

monster.description = "${monsterName}"
monster.experience = 0        -- oblicz na podstawie statystyk
monster.outfit = {
    lookType = 0,             -- do uzupełnienia z Tibia wiki
    lookHead = 0,
    lookBody = 0,
    lookLegs = 0,
    lookFeet = 0,
}

monster.health = 0
monster.maxHealth = monster.health
monster.race = RACE_BLOOD     -- RACE_BLOOD / RACE_UNDEAD / RACE_FIRE / RACE_ENERGY / RACE_VENOM
monster.corpse = 0            -- item ID korpusu

monster.speed = 0
monster.manaCost = 0
```

### Sekcja 2: Odporności i immunities

```lua
monster.flags = {
    summonable = false,
    attackable = true,
    hostile = true,
    convinceable = false,
    pushable = false,
    rewardBoss = false,         -- true tylko dla bossów
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
    -- Przykład: { type = "fire", combat = true, condition = true }
}
```

### Sekcja 3: Combat — ataki i spelle

```lua
monster.attacks = {
    -- Zawsze zacznij od melee
    { name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = 0 },
    -- Dodaj spelle odpowiednie do typu potwora
    -- Przykład ranged: { name = "combat", interval = 2000, chance = 15, type = COMBAT_FIREDAMAGE, minDamage = -100, maxDamage = -150, range = 7, shootEffect = CONST_ANI_FIRE, effect = CONST_ME_FIREAREA }
    -- Przykład AoE:    { name = "combat", interval = 3000, chance = 10, type = COMBAT_EARTHDAMAGE, minDamage = -80, maxDamage = -120, radius = 3, effect = CONST_ME_POISONAREA }
}

monster.defenses = {
    defense = 0,
    armor = 0,
    -- Healing: { name = "combat", interval = 2000, chance = 5, minDamage = 50, maxDamage = 100, effect = CONST_ME_MAGIC_BLUE, type = COMBAT_HEALING }
}
```

### Sekcja 4: Loot table

```lua
monster.loot = {
    -- Format: { id = ITEM_ID, chance = MAX_100000, minCount = 1, maxCount = 1 }
    -- Chance 100000 = 100%, 50000 = 50%, 1000 = 1%, 100 = 0.1%
    -- Zawsze dodaj złoto odpowiednie do poziomu trudności
    { id = Item.ids.gold_coin, chance = 100000, minCount = 1, maxCount = 100 },
}
```

### Sekcja 5: Rejestracja

```lua
-- Ten blok ZAWSZE na końcu pliku
mtype:loadLoot(monster.loot)
mtype:loadCombat(monster.attacks, monster.defenses)
mtype:loadImmunities(monster.immunities)
mtype:loadFlags(monster.flags)
mtype:loadConfig(monster)
```

---

## Po wygenerowaniu pliku:

1. Sprawdź czy `monster.experience` jest sensowne względem HP i damage (przybliżona formuła: `exp ≈ hp * 0.7 + maxDamage * 10`)
2. Upewnij się że `lookType` jest poprawnym ID z Tibia sprite library
3. Dodaj potwora do `data/monster/monsters.xml` jeśli projekt używa XML-based loading (TFS < 1.4)
4. Dla TFS 1.4+ z revscriptsys — plik w `data/monster/` ładuje się automatycznie
5. Zaproponuj lokalizację spawnów w `data/world/` jeśli podano lokalizację