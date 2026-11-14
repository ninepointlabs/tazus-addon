# content/learn.json

Hand-written teaching and rotation content for **Learn the Shaman** and the **Rotation** tab (including its Totems & imbues and Mana sub-tabs). `tools/build_data.py` turns it into `Data/Learn.lua`.

Rules (the weekly recheck must keep to them):

- Only facts from `research/data.json` or the archived pages behind it. Every entry lists `sources` (URLs).
- Anything not stated by a source, stated by only one third-party site, or conflicting between sources gets `"unconfirmed": true` and a short `"flag"`. The addon shows the flag in-game.
- Don't invent numbers (costs, coefficients, cooldowns, durations). Riptide's numbers and Totemic Call's cooldown conflict between sources: say so, don't pick one.
- Spell keys must match `data.json` names exactly (`spells_by_level[].name` without " (talent)"); talent keys match the talent names in `research/talents_shaman.json`.
- Never list removed spells as current: **Lava Burst, Fire Nova Totem, Tranquil Air Totem, dual wield**. There is **no group Bloodlust/Heroism** (Rage of the Farseer is personal).
- Use the **Nov 10/11 hotfix** numbers for Enhancement (Stormstrike 100% / 8 s, Maelstrom Weapon 20% per stack at all ranks, 6-10 procs per minute, Mental Dexterity 33/66/100%) and the hotfix intent (Windfury at the heart of Enhancement; imbues and weapon totems stack).
- Horde Troll character: Alliance-only (Dwarf) and Skyborne-only content belongs in data, not in lessons. An entry may carry `"faction"`; the addon hides other-faction entries.

## Sections

`version`, `checked`, `spells`, `talents`, `mechanics`, `totems`, `roles`, `leveling` (per spec), `mistakes`, `lessons` (unlock at `level`, optional `spec`), `first_learn_hints`, `rotation`.

`mechanics[]` entries may carry `"topic": "mana"` (shown on Rotation › Mana). `totems[]` articles (totems, weapon imbues, shields, Maelstrom Weapon, Fire Nova) show on Learn › Totems & imbues and Rotation › Totems & imbues.

`rotation.<Elemental|Enhancement|Restoration>.<solo|dungeon|raid>` = `{ summary, kind: "damage"|"healing", priority: [{spell, when, note}], tips, unconfirmed, flag, sources }`. Restoration uses `kind: "healing"` (the on-screen helper shows a list).

`when` must be one the engine (`Modules/Rotation.lua`) understands:
`always`, `manual` (listed for reading, never suggested by the on-screen helper), `buff_missing`, `debuff_missing`, `ready`, `out_of_combat`, `in_combat`, `usable`, `in_melee`, `imbue_missing`, `shield_missing`, `fire_totem_out` (Fire Nova), `no_fire_totem`, `mana_above:N`, `mana_below:N`, `target_hp_below:N`, `proc:<Buff name>`, `target_debuff_missing:<Debuff name>`, `stacks_below:<Aura>:N`, `stacks_at_least:<Aura>:N`, `totem_missing:<Earth|Fire|Water|Air>`. `tests/run.lua` fails if a step uses anything else or names a spell the research doesn't know.

After editing: `python3 tools/build_data.py && lua5.1 tests/run.lua`.
