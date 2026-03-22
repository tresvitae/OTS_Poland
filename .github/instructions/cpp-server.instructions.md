---
applyTo: "src/**/*.{cpp,h,hpp}"
---

# TFS 1.5 C++ Development — Zasady Copilota

## Stack i standard

- **C++20** — używaj `std::string_view`, `if constexpr`, designated initializers, ranges
- **Boost** (system, iostreams, locale, json) — już linkowane przez CMake
- **fmtlib** (`#include <fmt/format.h>`) — zamiast `std::string::operator+` i `sprintf`
- **pugixml** — do parsowania XML (monsters, items, map)
- **MariaDB C API** — przez `Database` wrapper w `src/database.h`, nigdy raw MySQL calls

## Konwencja kodowania TFS

```cpp
// Nazwy klas: PascalCase
class CreatureEvent { };

// Metody: camelCase
void CreatureEvent::executeOnDeath(Creature* creature);

// Stałe/enumy: UPPER_SNAKE lub scoped enum
enum class CombatType_t : uint8_t {
    COMBAT_NONE = 0,
    COMBAT_PHYSICALDAMAGE = 1 << 0,
    COMBAT_FIREDAMAGE = 1 << 1,
};

// Członkowie klasy: camelCase bez prefixu
class Player {
    uint32_t level = 1;        // nie: m_level, mLevel, _level
    std::string name;
};
```

## Creature ID — nigdy nie używaj uint32_t bezpośrednio

```cpp
// ŹLE — stary styl, podatny na dangling pointer po śmierci creature
uint32_t creatureId = creature->getID();
// ... później ...
Creature* c = g_game.getCreatureByID(creatureId);  // może być nullptr!

// DOBRZE — sprawdź nullptr zawsze
if (Creature* target = g_game.getCreatureByID(creatureId)) {
    target->setHealth(target->getHealth() - damage);
}
```

## Scheduler i Dispatcher — eventy asynchroniczne

```cpp
// Dispatcher — natychmiastowe wykonanie w main game thread
g_dispatcher.addTask(createTask([this, creatureId]() {
    // Capture by value dla ID, nigdy by reference dla pointerów
    if (Creature* creature = g_game.getCreatureByID(creatureId)) {
        creature->onEndCondition(CONDITION_FIRE);
    }
}));

// Scheduler — opóźnione wykonanie
g_scheduler.addEvent(createSchedulerTask(
    2000,  // opóźnienie w ms
    [creatureId]() {
        if (Creature* c = g_game.getCreatureByID(creatureId)) {
            g_game.combatChangeHealth(nullptr, c, -50);
        }
    }
));
```

## Modyfikacja Combat — przez CombatParams

```cpp
// Zawsze używaj CombatParams zamiast bezpośrednich wywołań
CombatParams params;
params.combatType = COMBAT_FIREDAMAGE;
params.impactEffect = CONST_ME_HITBYFIRE;
params.distanceEffect = CONST_ANI_FIRE;

CombatDamage damage;
damage.primary.type = params.combatType;
damage.primary.value = -uniform_random(minDamage, maxDamage);

// Zawsze sprawdź czy attacker/target nie są nullptr
if (attacker && target) {
    Combat::doCombatHealth(attacker, target, damage, params);
}
```

## Nowe systemy — rejestracja eventów

```cpp
// W src/events.cpp lub dedykowanym pliku — wzorzec TFS
void Events::eventCreatureonDeath(Creature* creature, ...) {
    // 1. Sprawdź Lua bindings
    if (!scriptInterface.reserveScriptEnv()) {
        return;
    }
    ScriptEnvironment* env = scriptInterface.getScriptEnv();
    env->setScriptId(info.creatureOnDeath, &scriptInterface);

    // 2. Push argumenty
    lua_State* L = scriptInterface.getLuaState();
    scriptInterface.pushFunction(info.creatureOnDeath);
    LuaScriptInterface::pushUserdata<Creature>(L, creature);
    LuaScriptInterface::setMetatable(L, -1, "Creature");

    // 3. Wywołanie z error handling
    scriptInterface.callFunction(1);
}
```

## CMake — dodawanie nowych plików

Przy dodaniu nowego `.cpp` do `src/`:
```cmake
# src/CMakeLists.txt — dodaj do listy źródeł
target_sources(tfslib PRIVATE
    # ... istniejące pliki ...
    twoj_nowy_plik.cpp   # dodaj tutaj
)
```
Nie zapomnij: po zmianie CMakeLists wymagany jest `cmake --build build` od nowa (nie tylko recompile).

## Warningi jako błędy — CMake flagi

TFS kompiluje z `-Werror`. Każdy warning = failed build: