# Tazu's Addon

The do-everything Shaman companion for **World of Warcraft: Forever**. Spec-aware for Elemental, Enhancement and
Restoration, with dual spec from day one. Named for **Tazu**, Troll Shaman of the Horde, who started out in the Valley of
Trials on 14 November 2026 and would like his first Earth totem now, please.

It's the fourth sibling of [Andric's Addon](https://andricsaddon.myazerothlife.com) (Priest),
[Parzelle's Addon](https://parzelles-addon.myazerothlife.com) (Mage) and
[Tristan's Addon](https://tristans-addon.myazerothlife.com) (Paladin), from the makers of [My Azeroth Life](https://myazerothlife.com).

> **Status:** [v0.1.0](https://github.com/ninepointlabs/tazus-addon/releases/tag/v0.1.0) is out. Screenshots come once Tazu has logged a few hours.

- Website: https://tazus-addon.myazerothlife.com (files in `docs/`; the domain isn't live yet)
- WoW Forever only (`WOW_PROJECT_ID 18`), Interface `16001`. No Ace3; Blizzard API only. MIT.

## Contents

- [Install](#install)
- [Getting started](#getting-started)
- [Features](#features)
- [The Shaman bar](#the-shaman-bar)
- [What it can't do (and why)](#what-it-cant-do-and-why)
- [Slash commands](#slash-commands)
- [Where the information comes from](#where-the-information-comes-from)
- [For developers](#for-developers)
- [License and credits](#license-and-credits)

## Install

### With OmaForge (Linux)

Search for "tazu" in OmaForge, or:

```sh
omaforge install -c forever github:ninepointlabs/tazus-addon
omaforge update -c forever          # later versions
```

### By hand (any OS)

Download the zip from [GitHub Releases](https://github.com/ninepointlabs/tazus-addon/releases) and unzip it so the folder is
`World of Warcraft/_forever_/Interface/AddOns/TazusAddon`. From a checkout, `tools/install-dev.sh` copies only the files WoW needs.

## Getting started

1. Log in and type `/tazu` (or `/shaman`).
2. Pick a spec. Under level 10 there are no talents yet, so pick what you plan to level as. The plan: **level as Enhancement**, then at 40 make dual spec **Enhancement (A) + Restoration (B)** for groups. Elemental is also a solid caster leveler; Restoration is for groups, not solo. Each profile keeps its own spec and follows your talent spec automatically.
3. Drag the **Shaman bar** (imbue button, Fire Nova button, Shield and Totems hints) somewhere handy. Keys are optional and unbound by default.

## Features

The window has grouped screens: **Home** · *Play:* Rotation, Gear · *Progress:* Leveling, Talents · *Learn:* Learn the Shaman · What's new · Settings. Sub-tabs, a search box, "Sources & notes" on every screen, and a spec pill with the A/B profile in the header.

- **Home:** trainer now/next, riding savings, the **next totem class quest** (Call of Earth at 4); *Needs attention* (no weapon imbue, no Lightning/Water Shield, totems not down when there's a fight, open class quest, Ghost Wolf to train, unread news, new lessons); your weapon/shield at a glance; your rotation; the latest changes.
- **Rotation:** Solo / Dungeon / Raid priority lists per spec, known spells only ("Train it" when trainable, talents once taken), a small next-spell helper with **Maelstrom Weapon** stacks, a post-fight summary with mana tips, and sub-tabs **Totems & imbues**, **Cooldowns** (your own procs and cooldowns: Maelstrom, Stormstrike, Fire Nova, Lightning Mastery, Rage of the Farseer, Nature's Swiftness, Mana Tide, Berserking; "hidden" when Forever won't say) and **Mana**.
- **Gear:** *For my level*, *Best overall*, *By bracket*, "How to get it", Mark on map, tooltip upgrade lines with per-spec weights, bag upgrade glow and a toast. Enhancement notes follow the Nov 10/11 hotfix (slow two-handers, weapon DPS, Strength/AP, Windfury); Rage of the Storm carries its hotfixed stats.
- **Leveling:** a Horde Troll path (Valley of Trials, Durotar, the Barrens …), zones and dungeons, trainer, class quests (Call of Earth 4, Call of Fire 10, Call of Water 20, Call of Air 30, The Tempest's Weapons; the Dwarf and Skyborne versions stay hidden), riding & gold.
- **Talents:** builds drawn on Forever's own Shaman trees, each decoded and validated (every level-60 build is exactly 51 points), with notes on what changed between the deep dive, the Nov 2 launch notes and the Nov 10–13 hotfixes.
- **Learn the Shaman:** every spell and talent, totems in Forever, weapon imbues, shields and Maelstrom Weapon, group role and etiquette, leveling tips, common mistakes and level-gated lessons (do Call of Earth at 4).
- **Reminders, What's new** (from `tools/shaman-changes-poller`), **Settings** (with About, named for Tazu).

## The Shaman bar

- **Weapon imbue button:** one press, out of combat, puts the recommended imbue for your spec and situation on your weapon at the highest rank you know. Windfury Weapon is at the heart of Enhancement after Blizzard's Nov 10/11 hotfix; Rockbiter Weapon is the leveling fallback before 30. It shows how long is left, flags a different imbue, and you can pin another one. Imbues last 60 minutes and now stack with weapon totems.
- **Fire Nova button:** Fire Nova Totem is gone in Forever; Fire Nova erupts at your current Fire totem. The button lights up only while one of your Fire totems is down.
- **Shield hint:** Lightning Shield, or Water Shield for Restoration (and for anyone who has it when mana runs low); orbs left when readable; "refresh me" when it's gone.
- **Totems hint:** which Earth / Fire / Water / Air totem fits your spec for Solo, Dungeon or Raid, and a nudge in a fight when one is missing or running out. It mentions Totemic Recall and Totemic Call once you know them.

The bar **complements Blizzard's own totem tracker and Call of the Elements bar**; it never replaces or covers them. Hints don't cast. The two buttons are secure buttons with `/cast` lines: one press = one cast.

## What it can't do (and why)

Forever runs Blizzard's newer addon restrictions: **no combat log for addons**, and other units' health, casts and aura contents are **secret values** in combat. Your own auras, totems and cooldowns may be hidden in combat too; when they are, the addon says "hidden" instead of guessing. Everything here is **advice only**: one key press = one cast, and nothing casts by itself. There is no group Bloodlust/Heroism in Forever (Rage of the Farseer is personal), so there's no Bloodlust caller.

## Slash commands

| Command | What it does |
|---|---|
| `/tazu` (or `/shaman`) | Open or close the window |
| `/tazu spec ele\|enh\|resto` | Set the active profile's spec |
| `/tazu profile [A\|B]` | Switch profile |
| `/tazu rotation` · `totems` · `cooldowns` · `mana` · `gear` · `leveling` · `talents` · `learn` · `news` · `settings` · `about` | Open a screen |
| `/tazu imbue [key\|debug]` | Toggle the imbue button, set its key, or print diagnostics |
| `/tazu nova [key]` | Toggle the Fire Nova button or set its key |
| `/tazu bar` | Move the Shaman bar back to its default spot |
| `/tazu hud` · `reset-hud` · `remind` | Rotation helper on/off, reset its position, check reminders now |

Keys: Settings › Shaman bar. None are bound by default, Super/Meta combos are refused (they belong to the desktop on Omarchy), and bindings only change out of combat. No `Bindings.xml`, no macros, no `/click`.

## Where the information comes from

Every fact in `research/data.json` carries its `source_url` and the date it was checked; the addon cites them under "Sources & notes" and Settings › About the data. Primary sources are Blizzard's posts (Mage & Shaman class deep dive, development notes, hotfixes through Nov 13). Icy Veins and Wowhead Forever guides come next. Facts from a single fan site are marked **unconfirmed** in game. Conflicts (Riptide's numbers, Totemic Call's cooldown, pre-hotfix Enhancement advice) are shown, not decided. Gaps are listed, not guessed.

## For developers

```
Core/        Init, Spec, DB (SavedVariables TazusAddonDB / TazusAddonCharDB), DualSpec, Boot (events, slash)
Data/        GENERATED by tools/build_data.py (Changes.lua by the poller)
Modules/     Auras, Stats, Training, Progress, Shaman, Cooldowns, Reminders, Rotation, Summary, Changes, Learn, Tooltip, Map
UI/          Widgets, Main, Panels/*, Hud, Bags, ShamanBar, ImbueButton, FireNovaButton, Hints, Minimap
research/    data.json (+ parts/), talents_shaman*.json, item_sources.json, NOTES.md, sources.md, SCHEMA.md (raw/ is local only)
content/     learn.json (teaching + rotation text)
tests/       run.lua + wow_mock.lua (strict headless WoW mock)
tools/       build_data.py, ivcalc.py, fetch_talents.py, fetch_item_sources.py, install-dev.sh, shaman-changes-poller/
docs/        the website (excluded from the zip)
```

```sh
python3 research/merge.py                       # parts/*.json -> research/data.json
python3 tools/build_data.py                     # regenerate Data/*.lua (--check fails if stale)
python3 tools/ivcalc.py                         # decode and validate every talent build link
lua5.1 tests/run.lua                            # headless tests
python3 tools/shaman-changes-poller/tests/test_poller.py
tools/install-dev.sh                            # copy into …/_forever_/Interface/AddOns/TazusAddon
```

Releases are built by `.github/workflows/release.yml` (BigWigs packager) on a `v*` tag. Tags and releases happen only with Tim's explicit OK; before any tag, re-run `omaforge clients` and update `## Interface` in both `.toc` files if it changed.

## License and credits

MIT © Nine Point Labs. Game information from Blizzard, Icy Veins and Wowhead, credited per fact.
Tazu's Addon is an unofficial fan project, not affiliated with or endorsed by Blizzard Entertainment.
World of Warcraft and Warcraft are trademarks of Blizzard Entertainment, Inc.
