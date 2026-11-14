# research/data.json schema (Tazu's Addon, Shaman)

Same shape as Andric's Addon (Priest, `/home/tim/Projects/wow-forever-priest-addon/research/data.json`), Parzelle's Addon
(Mage, `/home/tim/Projects/parzelles-addon/research/data.json`) and Tristan's Addon (Paladin,
`/home/tim/Projects/tristans-addon/research/data.json`), with Shaman additions (totems, imbues, shields, reagents) and **no `pvp` object**.
Read Tristan's for examples. `research/NOTES.md` is the starting summary; `research/raw/` holds the archived pages (HTML + MD).

**Every record** (list item or dict) carries `source_url` (the page the fact came from) and `checked` (`"2026-11-14"`, or the date
of the source record you copy). Never invent spell IDs, item IDs, quest IDs, NPC IDs, currency IDs, coordinates, stats, costs,
cooldowns or durations: use only what a raw page (or a page you fetched and archived in `research/raw/`) states.
Unknown -> omit the field (or `null`) and add a `gaps[]` entry. Conflicts -> add a `conflicts[]` entry.
Facts from one secondary/low-confidence site only (foreverguide, bindonforever, dailyrespawn, wow-forever.gg, endgametools, foreverdb ...)
get `"unconfirmed": true` and a short `"flag"`.

DATA WARNINGS (see NOTES.md): **Lava Burst, Fire Nova Totem, Tranquil Air Totem, dual wield** are removed: never list them as current.
No group **Bloodlust/Heroism** (Rage of the Farseer is personal). Riptide numbers and the Totemic Call cooldown conflict: record both, pick neither.
Stormstrike: 100% weapon damage, 8 s cooldown after the Nov 10/11 hotfix; it is a 15-point row-4 talent in Forever's trees
(`research/talents_shaman.json`: required_points 15 -> reachable at level 25), so IV DB's "level 40" field is a conflict entry.
Weapon imbues + weapon totems stack since the Nov 10/11 hotfix (overrides the deep dive). Pre-Nov 10 Enhancement advice
(Flametongue/spell-power meta, Stormstrike 150%/6 s, Maelstrom 20 PPM) is stale: keep it only as a `conflicts[]`/`talent_changes[]` record.
Several Icy Veins "ability learned" links point at high-rank IDs (10408, 10438, 10463): do not call them rank 1.

`tools/build_data.py` turns `data.json` into `Data/*.lua`. Spell names must be the exact English in-game names.
Specs are `"Elemental"`, `"Enhancement"`, `"Restoration"` (the Elemental talent tree is named "Elemental Combat" in the calculator data).

## Core part (`research/parts/core.json`)
- `meta`: copy Tristan's `meta` and change: `class: "Shaman"`, `latest_build_seen: "1.60.1.70938 (omaforge clients on TUF, 2026-11-14)"`,
  `talent_calc_version: "70938-3ee47080"`, `talent_calc_note` (Icy Veins build links use 70755-d1899b7d and 70888-a4ca5259; all three trees
  are in research/talents_shaman*.json), `checked: "2026-11-14"`. Keep `toc_interface: 16001`, `max_level: 60`.
- `sources`: `{ short_key: url }` for every page used.
- `spells_by_level`: `[{ name, wowhead_base_spell_id?, rank_learn_levels: [..], rank_spell_ids?: [...] (only if sourced, same length),
  school: "Nature"|"Fire"|"Frost"|"Physical"|null, category: "damage"|"heal"|"shock"|"totem"|"imbue"|"shield"|"buff"|"utility"|"cc"|"defense"|"resurrect"|"cooldown"|"movement",
  element?: "Earth"|"Fire"|"Water"|"Air" (totems only), talent_tree?: "Elemental"|"Enhancement"|"Restoration" (talent-taught spells: name them
  `"<Name> (talent)"`, e.g. `"Stormstrike (talent)"`), quest?: "Call of Earth" (if the spell/totem comes from a class quest),
  reagent?: "Fish Oil"|"Ankh"|... (only if sourced), notes?, id_source?, unconfirmed?, flag?, source_url, checked }]`.
  Every Shaman trainer spell 1-60 for Forever. Primary source for levels: the Icy Veins leveling pages (enhancement/elemental/restoration-shaman-leveling)
  + class overview + Wowhead abilities/leveling pages. Include at least: Lightning Bolt, Healing Wave, Earth Shock, Rockbiter Weapon, Lightning Shield,
  Earthbind Totem, Stoneskin Totem, Stoneclaw Totem, Flame Shock, Searing Totem, Strength of Earth Totem, Fire Nova (new baseline spell), Lesser Healing Wave,
  Purge, Ancestral Spirit, Flametongue Weapon, Ghost Wolf, Frost Shock, Healing Stream Totem, Mana Spring Totem, Poison/Disease Cleansing Totem,
  Cure Poison/Cure Disease, Frostbrand Weapon, resistance totems, Magma Totem, Water Breathing, Water Walking, Astral Recall, Far Sight, Reincarnation,
  Chain Lightning, Chain Heal, Windfury Weapon, Windfury Totem, Flametongue Totem, Grace of Air Totem, Grounding Totem, Windwall Totem, Sentry Totem,
  Tremor Totem, Frost/Fire/Nature Resistance Totems, Call of the Elements (20), Call of the Spirits (30), Call of the Ancestors (40), Totemic Recall (20),
  Totemic Call (22), and the talent spells Stormstrike, Water Shield, Mana Tide Totem, Nature's Swiftness, Riptide, Lightning Mastery,
  Rage of the Farseer (as `(talent)`). Only include what a source lists; anything else is a gap.
- `talent_and_other_spell_ids`: `[{ name, spell_id, tree?, kind: "talent"|"buff"|"debuff"|"racial"|"proc", max_rank?, required_points?, notes?, source_url, checked }]`
  for every talent in `research/talents_shaman.json` (tree names: map "Elemental Combat" -> "Elemental"), plus auras the addon reads
  (Maelstrom Weapon buff, Clearcasting/Elemental Focus, Flurry, Stormstrike debuff/buff, Lightning Mastery, Nature's Swiftness, Water Shield, Lightning Shield,
  Berserking ...). IDs only if sourced; `spell_id: null` otherwise.
- `milestones`: `{ items: [{level, what}], talent_milestones, trainer_costs, respec, source_url, checked }` (levels 1-60, include 4 Call of Earth, 10 Call of Fire + talents,
  20 Ghost Wolf/Call of the Elements/Call of Water, 30 Call of Air/Windfury, 40 dual spec/riding ...).
- `talent_changes`: `[{ tree: "Elemental"|"Enhancement"|"Restoration"|"Baseline"|"Totems", stage: "deep dive (2026-10-..)"|"launch notes (2026-11-02)"|"hotfix 2026-11-09"|"hotfix 2026-11-10/11"|"hotfix 2026-11-13", change, source_url, checked }]`.
- `builds`: `[{ spec, purpose: "Leveling"|"Dungeon"|"Raid"|"PvP"|<page label>, talent_calc_url, notes?, unconfirmed?, flag?, source_url, checked }]`:
  every build link on the Icy Veins pages (`data-talentcalculator-pointsurl="#tc-...~VERSION"`; full URL =
  `https://www.icy-veins.com/wow-forever/shaman-talent-calculator#tc-...~VERSION`). Keep fragments exactly. Use the page's own label for purpose
  (look at the heading/text around each link in the HTML). `python3 tools/ivcalc.py` decodes them; all 8 currently decode to 51 points.
  If a build page predates the Nov 10/11 Enhancement hotfix, say so in `notes`.
- `rotations`: `{ elemental, enhancement, restoration, mana, imbues: "<imbue rule as sourced, Nov 10/11 hotfix first>", totems: "<totem rule>", source_url, checked }`
  (short sourced summaries; mention spell names exactly).
- `stat_priority`: `[{ spec: "Elemental"|"Enhancement"|"Restoration"|"Leveling", priority: "A > B > C", notes?, source_url, checked }]`. Tokens must be from:
  `Weapon DPS`, `Hit`, `Spell hit`, `Expertise`, `Spell power`, `Healing`, `Intellect`, `Crit`, `Spell crit`, `Strength`, `Attack power`, `Agility`, `Stamina`,
  `Spirit`, `MP5`, `Defense`, `Armor`, `Block`, `Block value`, `Dodge`, `Parry` (parentheses allowed for notes). Haste is not a token (keep it in notes).
  If a spec has no published priority, add a gap instead of inventing one. Note in `notes` whether the page predates the Nov 10/11 hotfix.
- `quests`: `[{ type: "class"|"breadcrumb"|"mount", level, races: "Orc/Troll"|"Tauren"|"Dwarf"|"Skyborne"|"All", faction: "Alliance"|"Horde"|"Both",
  name, quest_id?, zone?, start_npc?, coords?, steps?: [..], reward?, reward_spell?, reward_item_id?, reward_items?: [{name,item_id}], notes?, unconfirmed?, flag?,
  source_url, checked }]`: Horde Orc & Troll chain from Icy Veins shaman-class-quests (Call of Earth 1516, Call of Fire 1522, Call of Water (63 per IV link),
  Call of Air 1531, The Tempest's Weapons 79442) + the Tauren/Dwarf/Skyborne versions only if the page lists them (they are filtered out for Tazu).
  Post-30 classic quests -> gap. Mount quests only as unconfirmed rows if sourced.
- `class_trainers`: `{ trainers: ["Name (City/Zone)", ...], respec_note, note, source_url, checked }` (only sourced names; else gap).
- `racials`: Troll racials (Berserking 20554, Rapid Regeneration 1260270, Beast Slaying 20557, Regeneration 20555) plus Orc/Tauren/Dwarf Shaman races' racials only if sourced.
- `race_notes`: `{ text, source_url, checked }` (Forever Shaman races).
- `changes_log`: `[{ date, change, source_url, checked }]` Shaman-relevant dated changes (deep dive, dev notes, Nov 2 launch, Nov 9/10/11/13 hotfixes).
- **Shaman additions** (feed the Shaman bar and Learn tab):
  - `totems`: `[{ name, element: "Earth"|"Fire"|"Water"|"Air", level?, duration?: "5 min"|..., buff?: "party"|"raid"|"self"|null, what, solo?: bool, group?: bool,
     notes?, unconfirmed?, flag?, source_url, checked }]` one per totem (no Fire Nova Totem / Tranquil Air Totem).
  - `totem_rules`: `{ text, persistent_duration: "5 minutes", gcd: "1.0 s", tracking_ui, call_of_the_elements, totemic_recall, totemic_call, fire_nova, removed: [..], source_url, checked }`.
  - `totem_advice`: `{ Enhancement: { solo: {Earth, Fire, Water, Air}, dungeon: {...}, raid: {...} }, Elemental: {...}, Restoration: {...}, notes, source_url, checked }`
     Each element value is the exact totem spell name or null; only what a guide recommends (an unsourced slot is null + gap). Mark pre-hotfix advice.
  - `imbues`: `[{ name: "Rockbiter Weapon"|"Flametongue Weapon"|"Frostbrand Weapon"|"Windfury Weapon", level?, duration: "60 minutes", what, notes?, source_url, checked }]`.
  - `imbue_advice`: `[{ spec, context: "leveling"|"solo"|"dungeon"|"raid", before_level?: N, from_level?: N, imbue, why, stale?: bool, source_url, checked }]`
     ordered by preference (hotfix-first: Windfury Weapon from 30 for Enhancement; Rockbiter as the pre-30 leveling fallback; Flametongue for casters if sourced).
  - `shields`: `[{ name, level?, talent?: bool, charges?: N|null, what, notes?, source_url, checked }]` (Lightning Shield, Water Shield).
  - `reagents`: `[{ name, item_id?, for_spell, confirmed: bool, notes?, source_url, checked }]` (Fish Oil 17058 for Water Walking? Ankh for Reincarnation? only if a page states it).
- `conflicts`: `[{ topic, detail, source_url, checked }]`, `gaps`: `[{ gap, source_url, checked }]`.

## Gear/world part (`research/parts/gear.json`)
- `gear_by_bracket`: `[{ bracket: "level 10"|"level 20"|...|"level 60 pre-raid", spec?: "Elemental"|"Enhancement"|"Restoration"|null, name, item_id, slot?, source,
  level?, faction?, notes?, source_url, checked }]` from the Icy Veins leveling + BiS pages and Wowhead BiS pages. Item IDs only from links in the raw HTML
  (`item=NNN` / `/item/NNN`). Include the Tempest's Weapons rewards with the hotfixed Rage of the Storm stats (16 Strength, 3.6 speed).
- `other_weapons`: `{ note, source_url, checked }` (slow two-handers 3.3-3.8 for Enhancement; Windfury direction); `bis`: `{ status, flag, source_url, checked }`.
- `consumables_enchants`: `[{ type, bracket?, spec?, name, item_id?, notes?, source_url, checked }]` (Wowhead enchants-consumables pages; Icy Veins ones were not found).
- `professions`: `{ leveling, raiding, alternatives: [...], note (Tazu already has Herbalism; do not tell him to drop it), source_url, checked }`.
- `riding`, `mounts`, `zones_by_level`, `new_zones`, `dungeons`, `raids`, `raid_rules`, `roadmap`, `addons`, `addon_dev`: copy from the Priest/Mage/Paladin data.json
  (race-independent facts keep the original source_url/checked). `mounts`: a Troll/Horde row only if sourced (raptors, Darkspear trainer); else a gap.
- `change_sources`: copy Tristan's list (feeds are game-wide) and add Shaman pages worth watching.

## Merge
`python3 research/merge.py` merges `parts/core.json` + `parts/gear.json` into `data.json`
(keys from both; `gaps`/`conflicts`/`sources` concatenated/merged).
