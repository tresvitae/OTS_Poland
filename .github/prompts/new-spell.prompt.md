---
mode: agent
description: "Create a complete TFS 1.4.2 revscriptsys spell (Lua file + optional config update + validation notes)."
---

Create a new spell for TFS 1.4.2 (revscriptsys) for Adventure OTS.

If any required parameter is missing, ask a short clarification question first.

Required parameters:
- `spellName`
- `vocation`
- `minDmg`
- `maxDmg`

Deliverables:
1. Create `adventure-ots/tfs/data/scripts/spells/${spellName}.lua` with:
   - `Spell()` object and full configuration
   - `onCastSpell(creature, variant)` implementation
   - nil-safety checks for creature and target/variant
   - cooldown, mana, and minimum level requirements
   - user-facing message when cast fails or misses

2. If file exists, append/update `adventure-ots/tfs/data/scripts/lib/spells_config.lua`.

3. Provide a short validation checklist:
   - registration status
   - potential balancing concerns
   - quick in-game test commands/steps

Constraints:
- Use Lua 5.1-compatible syntax.
- Prefer modern TFS object API over deprecated `do*` helpers.
- Keep logic readable and safe (no unchecked global/object access).
- Do not invent paths outside `adventure-ots/tfs/data/`.
