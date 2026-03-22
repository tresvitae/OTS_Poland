---
name: TFS C++ Server
description: "C++ development standards for Adventure OTS TFS 1.4.2 server code."
applyTo: "adventure-ots/tfs/src/**/*.{cpp,h,hpp}"
---

# TFS 1.4.2 C++ Server Development Standards

Apply these rules to all server-side C++ changes under `adventure-ots/tfs/src/`.

## 1. Language and Style

- Target C++20
- Keep naming aligned with existing TFS style
- Prefer small, focused functions and explicit ownership
- Treat warnings as errors (`-Werror`)

## 2. Safety Rules

- Never assume pointers are valid after async/deferred execution
- Always re-resolve creature/player by ID before use
- Guard nullable values before access

```cpp
uint32_t creatureId = creature->getID();
g_scheduler.addEvent(createSchedulerTask(2000, [creatureId]() {
    if (Creature* c = g_game.getCreatureByID(creatureId)) {
        g_game.combatChangeHealth(nullptr, c, -50);
    }
}));
```

## 3. Dispatcher and Scheduler

- Use `g_dispatcher.addTask(...)` for immediate main-thread work
- Use `g_scheduler.addEvent(...)` for delayed execution
- Capture IDs by value, not raw pointers by reference

## 4. Combat Changes

- Prefer existing combat pipeline (`CombatParams`, `CombatDamage`, `Combat::...`)
- Keep damage calculations deterministic and testable
- Validate attacker/target pointers before combat calls

## 5. Lua Event Bridge Changes

When editing event glue code:
- Reserve script environment before Lua calls
- Push userdata and metatables correctly
- Keep error handling and early return guards

## 6. Database Access

- Use the existing database abstraction (`Database` wrappers)
- Avoid direct low-level connector calls outside the abstraction
- Keep SQL changes compatible with current TFS schema

## 7. Build System Updates

When adding new source files, include them in the relevant CMake target and verify a full reconfigure/build.

## 8. Performance Notes

- Avoid repeated map scans in tight loops
- Cache expensive lookups when safe
- Keep allocator churn low in hot combat/event paths

## 9. Review Checklist

- Compiles with C++20 and no warnings
- No unsafe deferred pointer usage
- Uses existing server abstractions and conventions
- Keeps behavior backward-compatible unless explicitly intended
