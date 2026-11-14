# WoW Forever Shaman – research notes for Tazu's Addon (checked 2026-11-14, America/Chicago)

Raw copies of every page are in `raw/` (HTML + extracted .md). These notes are a starting summary, NOT a finished data.json.
Claude should build `research/data.json` (same shape as the priest/mage/paladin research: meta, spells, quests, builds, gear brackets,
consumables, reagents, riding, gaps, change_sources), every fact with `source_url` + `checked`, from these raw pages.

## Who: Tazu (facts from TUF, 2026-11-14)

Tazu is **not** in `~/Projects/my-azeroth-life-shows/characters/` and is not named in the My Azeroth Life blog. Tim's Forever Characters note (2026-10-17) only lists "Troll - Shaman" as a candidate, with no character name.

Game SavedVariables on TUF (`StoryTracker.lua`, WTF folder `_forever_/WTF/Account/980903219#1/91/Tazu-Ganj/`, session this morning):

- **Tazu**, **Troll Shaman**, **Horde**. Realm display name **Ganj**, internal id `CAMWOWUS2Realm1PvE` (same Normal/PvE realm as Andric and Parzelle, not Tristan Ludlowe's PvP realm).
- Character folder and first StoryTracker session: created **2026-11-14 around 7:04 AM CT**. One session of about 34 minutes; login level 1 in Durotar, logout level 4 still in Durotar (Valley of Trials / The Den). About 9–10 quests turned in. Gender is not recorded in the SavedVariables we read.
- First quests include "Your Place in the World" (quest 4641) and "Cutting Teeth" (788). He also accepted "Wayward Weapons" (97279, Forever-specific; not researched further here).
- Profession started this session: **Herbalism** (Herb Gathering, Find Herbs, Gardening / spell IDs in StoryTracker). Icy Veins recommends Leatherworking + Skinning for Shaman; do not tell him to drop Herbalism — just note the research recommendation.
- Pawn last class = SHAMAN; `EJLootClass` 7.

## WoW Forever now (Nov 14, 2026)

- Launched Nov 4, 2026. Level cap 60. Raids open Dec 9 (from earlier priest/mage research).
- `omaforge clients` on TUF, 2026-11-14: **Forever 1.60.1.70938, Interface 16001** (build is newer than the 70888 recorded in the paladin brief; interface is unchanged). WOW_PROJECT_ID 18 (`WOW_PROJECT_CAMELOT`).
- Addon API limits are the same as Andric's / Parzelle's / Tristan's: no combat log for addons; other units' health/casts/aura contents can be secret in combat; secure buttons use `type=macro` + `/cast` macrotext; no `/click`; no Bindings.xml; re-aim out of combat. See the paladin NOTES for the full list.

## Races and Troll racials

- Horde Shamans: Orc, Tauren, Troll, and Windshaper Skyborne. Alliance: Dwarf (new in Forever). (foreverguide, official race tables.)
- Troll racials in Forever (Icy Veins race-guide, 2026-11-09 copy in raw/):
  - **Berserking** (20554): +10% melee, ranged and spell haste for 12 s, 3 min cooldown.
  - **Rapid Regeneration** (1260270, new active): regenerate 50% of maximum health over time, 3 min cooldown.
  - **Beast Slaying** (20557): +5% damage to Beasts.
  - **Regeneration** (20555): 20% of total health regeneration continues in combat.
- Hide Alliance-only (Dwarf) quest text for a Horde character. Skyborne Shaman quests are a different path; Tazu is a Troll.

## Baseline Shaman in Forever (Blizzard deep dive + Nov 2 launch notes + later hotfixes)

### Totems (the class signature)

- All totems: **1.0 s GCD** (was 1.5). Persistent-buff totems last **5 minutes** (was 2). Shorter totems unchanged.
- Blizzard added a **built-in totem tracking UI** (active totems + remaining time; right-click dismisses one). **Do not fight this UI**, the same way Paladin addons must not fight the Aura flyout.
- **Call of the Elements** (level 20) unlocks the totem bar: preset four totems (one per element) and drop them all with a **3 s cast**. **Call of the Spirits** (30) and **Call of the Ancestors** (40) add a second and third preset.
- **Totemic Recall** (new, level 20): destroys your totems and refunds 25% of their mana. A beta bug (refund missing) was noted; verify in-game.
- **Totemic Call** (new, level 22; called Totemic Projection in the deep dive / beta): teleports your totems to you. **CD CONFLICT:** foreverguide launch notes say **30 s**; Wowhead Restoration overview says **1 minute**. Do not hard-code the cooldown; flag and verify.
- Resistance totems now affect the whole raid.
- **Fire Nova Totem is removed.** New baseline **Fire Nova** spell erupts at your current Fire totem, and can be triggered repeatedly.
- **Tranquil Air Totem is removed.**
- Windfury Totem and Flametongue Totem are now **party-wide buffs**, not weapon enchants. Deep dive said a Shaman with the matching weapon imbue could not benefit, and that Windfury Totem does not stack with Grace of Air or Flametongue Totem for the party.
- **HOTFIX Nov 10/11 (live Nov 11 ~12:45 PM CT / 19:45 CET):** "Weapon imbues and Weapon totems can now be used at the same time." Developer note: a Shaman can benefit from **Windfury Weapon and Windfury Totem at the same time**. This **overrides** the deep-dive "cannot benefit" rule. The party-totem exclusivity (Windfury vs Grace of Air vs Flametongue Totem) was not clearly restated — verify.
- **HOTFIX Nov 13:** Windfury Totem is now correctly activated by all melee abilities even if they don't involve the main-hand weapon. Off-hand-only strikes (examples given: Whirlwind, Mutilate) still do not proc it; the main-hand strike from those abilities does.
- **HOTFIX Nov 11:** Flametongue Totem Rank 2 works again.

### Weapon imbues

- Frostbrand, Flametongue, Rockbiter and Windfury Weapon last **60 minutes** (was 5) and can be active at the same time as temporary enchants (sharpening stones, weightstones, wizard oil).
- Icy Veins Enhancement leveling still says: Rockbiter when solo, Flametongue in groups, "Windfury Weapon always" once known (level 30). That advice may predate the Nov 10/11 hotfix, which Blizzard said was meant to put **Windfury back at the heart** of Enhancement and walk the spec off a spell-power/Intellect gear path. **Treat imbue choice as a conflict; prefer the hotfix intent and verify in-game / against post-hotfix guides.**

### Other baseline

- Lightning Bolt ranks 4+ and Chain Lightning had cast-time changes in the deep dive; Nov 2 launch notes then changed them again (LB damage up at every rank; CL 2.5 s and hits harder; Shock damage back to Classic Era). Use **launch notes + later hotfixes**, not the deep dive alone, for numbers.
- Training costs evened across classes (~206–207 g for all ranks 1–60) (foreverguide summary of Blizzard notes).
- Talents from 10; gold medals at 11 / 16 / 21 / 31; respec at a class trainer in a major city; **Dual Spec at 40**.
- **No dual wield** for Enhancement. The skill is removed; Enhancement is a **two-handed** spec. Two-Handed Axes and Maces, Enhancing Totems, Weapon Mastery and Improved Weapon Totems are baseline (foreverguide). Shield Specialization is removed.
- There is **no group Bloodlust / Heroism**. Rage of the Farseer is a **personal** 30% attack-speed cooldown (25 s, 3 min), "inspired by Heroism and Bloodlust" but explicitly not raid/party-wide (Blizzard deep dive).
- Blizzard's stated weakness: lack of effective crowd control.
- Ghost Wolf at 20 (Icy Veins; spell 2645). Water Walking (546) needs Fish Oil (17058).

## Talents (launch, then check Nov 10–13)

### Elemental Combat

- **Lightning Mastery** (31-pt gold medal, formerly Elemental Mastery): 15 s, Lightning Bolt 0.5 s faster, Chain Lightning has no cooldown.
- **Call of Thunder** (21-pt gold medal): +5% crit for Lightning Bolt and Chain Lightning. **Replaced Lava Burst, which was removed before launch.** Do not import Lava Burst.
- **Lightning Overload**: 10/20/30% chance LB/CL recast a free half-damage copy. Nov 9 hotfix: overload now deals the correct damage for Lightning Bolt. Nov 9: Lightning Mastery visual updated.
- **Earthbound** (new 16-pt gold medal): Earthbind Totem roots nearby enemies for 5 s on drop.
- **Elemental Alacrity** (row 2): up to 0.5 s off LB and CL. Eye of the Storm now always protects LB/CL from pushback.

### Enhancement

- **Shamanistic Focus** (11-pt gold medal): cheaper Shocks and Lightning Shield.
- **Stormstrike**: foreverguide says it moved to the **16-pt gold medal**. Icy Veins Enhancement leveling says it can be reached at **level 25**, with Improved Stormstrike later. Icy Veins DB (spell 17364, fetched 2026-11-14) currently shows **100% weapon damage, 8 s cooldown**, +20% damage on the next LB/CL/Earth Shock for 12 s, and a **level 40** requirement — that level field conflicts with the "reachable at 25" talent claim. **Do not hard-code the trainable/talent level; validate from Forever's talent tree JSON.**
- **Nov 10/11 hotfix (live Nov 11):** Stormstrike damage **100%** weapon damage (was 150%), cooldown **8 s** (was 6 s). Mental Dexterity Int-to-AP **33/66/100%** (was 50/100/150%).
- **Maelstrom Weapon** (new): melee attacks build charges that shorten Lightning Bolt (up to instant). **Nov 10/11 hotfix:** 20% reduced cast time and mana cost **per stack at all ranks** (was 4/8/12/16/20% by rank); proc rate now **6/7/8/9/10 times per minute by rank** (was 20/min regardless of rank). Tooltip shows % chance from main-hand weapon speed (example: 5/5 and 3.6 speed ≈ 60%; 2.0 speed ≈ 33%). Can be tracked in the Cooldown Manager (Nov 10).
- Blizzard's reason for the Nov 10 Enhancement pass: beta + Elemental-oriented Shock/LB changes pushed Enhancement onto spell-power/Intellect gear and away from Windfury. They want this fixed **before raids open Dec 9**. Any pre-Nov 10 gear or rotation guide that favors Flametongue/spell power over Windfury is **stale**.
- **Rage of the Farseer** (31-pt gold medal): personal 30% attack speed, 25 s, 3 min.
- Spirit Weapons (formerly Parry, 21 pts): threat down normally, up with Rockbiter (off-tank small groups). Improved Ghost Wolf: rank 1 works indoors and casts faster; rank 2 instant. Nov 9 hotfix: Improved Ghost Wolf holds the Night Watchman's Torch in its mouth correctly.
- Mental Quickness: Intellect as spell power. Improved Stormstrike: mana regen and cooldown resets.

### Restoration

- **Water Shield** (11-pt gold medal): mana when hit or on a critical heal. Icy Veins: also a strong default shield in end-game for Resto, and useful for Elemental/Enhance mana.
- **Mana Tide Totem** moves to the 16-pt gold medal.
- **Mindfulness** (new): 17/33/50% of mana regen continues while casting. Early enough that Elemental can dip for it.
- **Riptide** is the 31-pt gold medal. **CONFLICT — do not pick a number, flag it:**
  - Nov 2 launch notes (via foreverguide): costs ~40% less mana, **12 s cooldown, no initial heal**.
  - Icy Veins / Wowhead / foreverguide's own Restoration talent blurb: instant heal + 15 s HoT, Chain Heal +25% on that target, **6 s cooldown**.
- Healing Way is now a baseline percent buff to Healing Wave (no longer a 3-stack). Restorative Totems doubles the Healing Stream bonus. Nature's Guidance is removed. Natural Grace lowers threat from all spells.

## Class quests (Horde Orc & Troll — Tazu's path)

Icy Veins shaman-class-quests (Wordup / Seksixeny). IDs below are from that page's db.icy-veins links; confirm ranks/rewards in-game. Post-30 classic-style quests are explicitly **not yet documented** by Icy Veins (beta was capped at 30).

- **Level 4 – Call of Earth** (quest **1516**), Canaga Earthcaller, Valley of Trials. Two Felstalker Hooves from the Burning Blade Cave; Earth Sapta (6635); hidden path starts at **44, 76**; drink at the Spirit Rock; return Rough Quartz. Rewards **Earth Totem** (5175) and **Stoneskin Totem** (IV links spell 10408 — that looks like a high rank; do not assume it is rank 1). **Tazu is level 4 today, so this quest is immediately relevant.**
- **Level 10 – Call of Fire** (1522), any trainer → Kranal Fiss in the Barrens → Telf Joolan, hidden path on the southern edge of Durotar starting at **36, 56**. Reagent Pouch from Burning Blade Cultists north of Razor Hill; Fire Tar from Razormane Thornweavers; Fire Sapta (6636); defeat the Fire Elemental, use the brazier, return to Kranal. Rewards **Fire Totem** (5176), **Totem of Charged Flames** (263412), and **Searing Totem** (IV links 10438 — again, verify rank).
- **Level 20 – Call of Water** (IV links quest **63**). Icy Veins says: don't rush; none of the water totems are huge. Path: Ratchet → Brine in the Southern Barrens → fetch trips (nearby, then Tarren Mill, then Ashenvale, back to Brine each time) → Silverpine to defeat the Manifestation of Water → Brine again. Rewards **Water Totem** (5177) and **Healing Stream Totem** (IV links 10463). A Nov 2026 quest bug-fix list mentioned the Call of Water chain; assume the current live path and verify steps.
- **Level 30 – Call of Air** (1531), any trainer → Prate Cloudseer, Thousand Needles. Short. Rewards **Air Totem** (5178). Unlocks the follow-up.
- **Level 30 – The Tempest's Weapons** (79442). Icy Veins: realistic later (35–40) or with a group. Prate → Rau Cliffrunner at Freewind Post → Razorfen Kraul (Tattered Note from Charlga) → four sets of five Twisted Totems (Desolace / Swamp of Sorrows / Badlands / Dustwallow) → gauntlet at the hot springs under Darkcloud Pinnacle (some elites **immune to Nature**) → Eye of the Tempest (212792) → Bath'rah the Windwatcher in the Alterac Mountains. Rewards **Elementalist's Guard** (280696) and a weapon choice: Lightning's Grasp (280607) / Tidebringer's Claw (280605) / **Rage of the Storm** (280604).
- **HOTFIX (listed under Nov 10 notes on the Nov 13 hotfix article):** Rage of the Storm now has **16 Strength** (was 16 Intellect) and **3.6** weapon speed (was 3.2). That matches the "Windfury-friendly" Enhancement pass.

Hide the Dwarf and Skyborne versions of these chains from Tazu.

## Leveling and rotation (advice only; known spells at current level)

- First-run spec picker must handle **level 1–9, no talents**. Default recommendation from this research: **Enhancement for leveling** (Stormstrike / Windfury spikes; Ghost Wolf at 20), with a note that Elemental is also a solid caster leveler and Restoration is for groups, not solo. Dual spec at 40: **Enhancement (A) + Restoration (B)** unless Tim says otherwise.
- Horde zone path (Icy Veins Enhancement leveling): start Durotar / Valley of Trials, then Barrens, etc. Dungeons: Ragefire Chasm, Ruins of Lordaeron, Wailing Caverns, Shadowfang Keep, Blackfathom Deeps, later RFK (needed for Tempest's Weapons), and so on. Late-level dungeon recs are still TBD on Icy Veins.
- Enhancement leveling rotation (Icy Veins, pre- or mid-hotfix — re-check numbers): keep a weapon imbue up; shocks on cooldown; Fire Nova when a Fire totem is down; Lightning Bolt with Maelstrom stacks later; Ghost Wolf between fights.
- Elemental: Flame Shock, Lightning Bolt filler, Chain Lightning and Fire Nova for AoE, Lightning Mastery as a burst window (Icy Veins).
- Restoration: not recommended for solo leveling. In groups: Water Shield, Riptide (once known), Chain Heal / Healing Wave, help with Fire Nova / Lightning Bolt when healing is quiet.

## Gear and stats

- Phase 1 raid BiS is still a placeholder until raids open Dec 9. Use "For my level / Best overall / By bracket" like the sister addons, and hook later lists.
- Post-Nov 10 Enhancement: Blizzard wants **Windfury-friendly gearing** (weapon DPS / slow 2H around 3.3–3.8 plus Strength/AP), not a pure spell-power Intellect set. Icy Veins still mentions slow 2H 3.3–3.8 as the first priority while leveling.
- Icy Veins `*-enchants-consumables` pages were **not found** on 2026-11-14. Wowhead enchants-consumables pages were fetched; treat numbers carefully.

## Data warnings / gaps

- Never invent spell, item, quest or currency IDs. Several Icy Veins "ability learned" links point at high ranks (10408, 10438, 10463).
- Do not import **Lava Burst**, **Fire Nova Totem**, **Tranquil Air Totem**, or **dual wield**.
- Do not import group **Bloodlust / Heroism**.
- Riptide numbers conflict (see above).
- Totemic Call cooldown conflicts (30 s vs 1 min).
- Stormstrike talent row / required level conflicts with Icy Veins DB "level 40".
- Weapon imbue vs totem stacking: use the **Nov 10/11 hotfix**, not the deep dive.
- Pre-Nov 10 Enhancement guides (spell-power / Flametongue meta, Stormstrike 150% / 6 s, Maelstrom 20 PPM) are stale.
- Icy Veins has not listed post-30 class quests yet (other than Tempest's Weapons).
- Mount / riding quests at 40 and 60: reuse priest/mage riding research where race-independent; Troll / Horde vendor and trainer — research or flag as a gap.
- Talent calculator page on Icy Veins is JS-only (830 chars in raw). Build `research/talents_shaman.json` the same way as priest/mage/paladin, from the calculator data / client trees. Validate 51-point level-60 builds.
- Reagent: Fish Oil for Water Walking; Ankh for Reincarnation — verify they exist and their IDs in Forever before showing counts.

## Change detection

Same feeds as the other class addons. The official hotfix article is updated in place (current title Nov 13, 2026). The poller should filter Shaman, totem, weapon-imbue, Maelstrom, Stormstrike and related PvE changes.
