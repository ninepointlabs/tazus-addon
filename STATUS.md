# STATUS: Tazu's Addon (2026-11-14)

**What it is:** the WoW Forever-only, do-everything Shaman companion for **Tazu** (Troll Shaman, Horde, realm Ganj = `CAMWOWUS2Realm1PvE`, Normal/PvE). It follows the structure, window and website style of Andric's, Parzelle's and Tristan's addons (newest pattern where they differ), without Tristan's PvP section.

**Repo:** https://github.com/ninepointlabs/tazus-addon (public), local `/home/tim/Projects/tazus-addon`, `origin` set. Commits use `Nine Point Labs <179739321+ninepointlabs@users.noreply.github.com>`.
- **PR:** https://github.com/ninepointlabs/tazus-addon/pull/1, `feature/initial-addon` → `main`. **Merged 2026-11-14 on Tim's request** with a merge commit, `1c1b3a8`. CI passed on the PR's last commit (run 43609429691).
- Before the merge, `main` held only a base commit (LICENSE + .gitignore), pushed when the repo was created because a PR needs a base branch. Everything else came in through PR #1.
- **Repo topics:** `wow-addon` and `world-of-warcraft` were added 2026-11-14 at Tim's request, matching the sister repos. `omaforge search -c forever tazu` now finds `github:ninepointlabs/tazus-addon`. Since the v0.1.0 release it installs from the release zip.
- **Released:** **v0.1.0** on 2026-11-14 at Tim's request: https://github.com/ninepointlabs/tazus-addon/releases/tag/v0.1.0. The annotated tag `v0.1.0` points at `b840895` on `main`. Before tagging, `omaforge clients` reported Forever 1.60.1.70938 / Interface 16001, matching both TOCs, so no bump was needed. The Release workflow passed (run 43609658936). Assets are `TazusAddon-v0.1.0.zip` (62 files; TOC `## Version: v0.1.0`, Interface 16001; no docs/research/tests/tools) and `release.json` (flavor `forever`, interface 16001). The packager first generated release notes from commit messages; at Tim's request they were rewritten on 2026-11-14 as a short feature summary (highlights, install steps, fan-project notice). Only the release text changed, not the tag or the files. autonomix-cli isn't listed because the release ships no Linux executables. I haven't run `omaforge install` against the live AddOns folder.
- **Not done (not authorized):** no CurseForge/Wago, no Pages setting, no DNS, no email or social posts.
- **v0.1.0** is on `main` and released. In the repo the TOC says `@project-version@`; the packager filled in `v0.1.0` in the release zip.

## Decisions (brief defaults, all still Tim's to change)

1. **Leveling spec:** level as Enhancement; at 40 make dual spec Enhancement (A) + Restoration (B) for groups. The picker marks Enhancement "recommended for leveling" and explains the plan at levels 1–9 with no talents. It also says Elemental is a solid caster leveler and Restoration is for groups.
2. **Names:** `/tazu` + `/shaman`; `TazusAddon` / `TazusAddonDB` / `TazusAddonCharDB`; repo `tazus-addon`; site `tazus-addon.myazerothlife.com` (`docs/CNAME`, file only). `## X-Website` uses the GitHub URL until the site is live.
3. **Shaman bar:** it complements Blizzard's totem tracker and the Call of the Elements bar and doesn't replace them. It has two secure buttons (imbue, Fire Nova) and two hint cells (Shield, Totems). There is no second totem bar. Totemic Recall and Totemic Call are reminders in the Totems hint, not buttons, to keep the bar small.

## What works (verified headlessly, 2026-11-14)

| Check | Result |
|---|---|
| `lua5.1 tests/run.lua` | **40/40 pass** |
| `python3 tools/shaman-changes-poller/tests/test_poller.py` | 5/5 pass (one new test: curly quotes are escaped) |
| `python3 tools/build_data.py --check` | up to date |
| `python3 tools/ivcalc.py` | 9 build links decode; **all 9 are exactly 51 points** on Forever's trees |
| Lua syntax | every `.lua` loads |
| `tools/install-dev.sh <dir>` | copies only the TOCs, Core, Data, Modules, UI and LICENSE |
| Website | `docs/index.html` parses; `node --check` passes for `docs/app.js` and `docs/demo.js`. The site agent rendered it in headless Chromium; I haven't viewed it in a browser myself. |
| CI on the PR | pass (run 43603959958) |

The strict WoW mock treats undefined globals as errors. It loads every TOC file and renders every screen and sub-tab for Elemental, Enhancement and Restoration at levels 1, 24, 30 and 60. It also covers:
- **a level-1 character with no talents and no spec:** the picker, the Home nudge, and Talents saying "pick a spec";
- **a level-4 Troll in the Valley of Trials with no talents:** Home says the next class quest is Call of Earth, Leveling's path card shows the Valley of Trials, and the Totems tab points to Call of Earth. Stormstrike is hidden and Earth Shock shows "Train it" at its level;
- **a level-34 Enhancement after the Nov 10/11 numbers, with secret values mocked:** target health, cooldowns and then your own auras, totems and weapon are all secret. Everything renders, unreadable values show "hidden", the rotation says "some info hidden", and the Maelstrom line says "hidden".

Tests also cover:
- A/B profiles and dual-spec auto-switch.
- Stat parsing, including Nature damage. Equipment rules: leather, mail from 40, two-handed maces and axes are allowed; swords, plate and off-hand weapons are not.
- Troll/Horde quest filtering, so Dwarf and Skyborne quests stay hidden.
- Every rotation step's condition and spell, plus the new conditions (`imbue_missing`, `shield_missing`, `fire_totem_out`, `no_fire_totem`, `totem_missing:<Element>`).
- Imbue choice: Windfury from 30, Rockbiter before; stale pre-hotfix rows are skipped. Shield choice. Totem advice uses only totems you know, in the right element.
- Imbue reading from the main-hand tooltip, and `GetTotemInfo` reads.
- The imbue button: secure `/cast` macrotext, combat freeze, pinning, keys (none by default, Super/Meta refused, override click), and the debug command.
- The Fire Nova button: lit only with a Fire totem down.
- The hint cells, cooldowns and procs.
- Reminders: imbue, shield, the Call of Earth quest at 4, Ghost Wolf at 20.
- Learn: the level-4 Call of Earth lesson and new-spell hints.
- About: Tazu plus links to all three sister addons and myazerothlife.com.
- Slash commands and events. No macros are created, and no Paladin, Mage, Priest, PvP or other leftover text appears in the window or code.

## Features (v0.1.0)

- **Window:** Home · *Play:* Rotation, Gear · *Progress:* Leveling, Talents · *Learn:* Learn the Shaman · What's new · Settings. It keeps the sister addons' search box, "Sources & notes" popups and spec pill with the A/B profile.
  - Rotation sub-tabs: Solo · Dungeon · Raid · **Totems & imbues** · **Cooldowns** · Mana.
  - Leveling: Path · Zones & dungeons · Trainer · Class quests · Riding & gold.
  - Settings: General · **Shaman bar** · Tooltips & bags · Reminders · About the data · About.
  - Learn adds a **Totems & imbues** section.
- **Shaman bar** (`UI/ShamanBar.lua`, `UI/ImbueButton.lua`, `UI/FireNovaButton.lua`, `UI/Hints.lua`):
  - **Imbue button:** `type=macro` + `/cast <Imbue>` (no rank, so you get your highest). Re-aimed only out of combat. Shows time left and flags a different imbue. You can pin another imbue in Settings.
  - **Fire Nova button:** `/cast Fire Nova`. Always on the bar once known, because secure frames can't be shown mid-fight; it's lit only while one of your Fire totems is down.
  - **Shield hint** and **Totems hint:** plain frames that never cast. Totem nudges appear only in combat or with an enemy targeted.
- **Keys:** all optional and unbound by default. Set per character with `SetOverrideBindingClick`, out of combat only; Super/Meta refused. No `Bindings.xml`, no player macros, no `/click`.
- **Data:**
  - 56 trainer/talent spells, 66 talent/aura/racial records, 9 builds, 14 class quests (5 on Tazu's path; the 9 others stay hidden).
  - 21 totems with per-spec Solo/Dungeon/Raid totem advice, 4 imbues, 10 imbue-advice rows (2 stale rows kept for Sources & notes), 2 shields, 7 reagent rows.
  - 233 gear rows, with Icy Veins DB sources for 79 of 144 items.
  - 29 conflicts and 28 gaps, all listed in game.
- **Teaching content:** 56 spells, 50 talents, 23 mechanics, 11 totem/imbue articles, 9 group-role entries, 55 lessons, 15 common mistakes.
- **What's new:** 31 items from the poller's first run (2026-11-14), including the Nov 10–13 Enhancement and totem hotfixes and the "missing totems" server issue.

## Install / test on TUF

```sh
cd ~/Projects/tazus-addon && git checkout main && git pull
tools/install-dev.sh            # copies to …/_forever_/Interface/AddOns/TazusAddon
python3 research/merge.py       # only after editing research/parts/*.json
python3 tools/build_data.py     # regenerate Data/*.lua (--check fails if stale)
lua5.1 tests/run.lua
```

In game: `/reload`, then `/tazu`. Check the client with `/run print(GetBuildInfo()) print(WOW_PROJECT_ID)`.

## Client check

| | Value |
|---|---|
| `omaforge clients` on TUF (2026-11-14) | Forever `1.60.1.70938`, Interface `16001` |
| `.toc` Interface used | `16001` (matches), in `TazusAddon_Forever.toc` and the identical `TazusAddon.toc` |
| Runtime guard | runs only when `WOW_PROJECT_ID == 18` (`WOW_PROJECT_CAMELOT`); prints a message otherwise |

Before any future tag, re-run `omaforge clients` and bump `## Interface` in both TOCs if it changed.

## Research

- The box research was extracted to `research/` (renamed from `shaman-forever/`).
- `research/data.json` is built from `research/parts/core.json` (spells, talents, builds, rotations, quests, totems, imbues, shields, reagents) and `parts/gear.json` (gear, consumables, riding, mounts, world, change sources); see `research/SCHEMA.md`.
- Talent trees come from Icy Veins' calculator data in three versions: 70938 (current), 70888 and 70755, which older build links use.
- Pages fetched beyond the box, all archived in `research/raw/` (gitignored like the sister addons):
  - the three calculator JSON files;
  - the endgametools Shaman spell list, used for later rank levels and flagged unconfirmed;
  - the Wowhead Restoration enchants & consumables page;
  - Icy Veins DB item and quest pages, through `tools/fetch_item_sources.py`.
- Never imported: Lava Burst, Fire Nova Totem, Tranquil Air Totem, dual wield, group Bloodlust/Heroism.

### Conflicts (29; all shown in Settings › About the data, none silently decided)

- **Riptide:** 6 s with an initial heal (deep dive, Icy Veins, Wowhead) vs 12 s HoT-only (Nov 2 launch notes). Not picked. Its spell IDs also differ, so it's matched by name.
- **Totemic Call cooldown:** 30 s (launch notes, foreverguide, endgametools) vs 1 min (deep dive, Wowhead). Not hard-coded anywhere.
- **Stormstrike level:** a row-4, 15-point talent (reachable at 25) vs Icy Veins DB's "level 40". The talent tree is used. Its numbers follow the Nov 10/11 hotfix: 100%, 8 s.
- **Maelstrom Weapon, Mental Dexterity, Enhancement stat priority and gear/imbue meta:** pre-hotfix values vs the Nov 10/11 hotfix. The hotfix is used; Wowhead's Flametongue/spell-power advice is marked stale.
- **Imbue + weapon-totem stacking:** the deep dive said no; the Nov 10/11 hotfix says yes, and the hotfix is used. Grace of Air vs Windfury Totem exclusivity is not restated; verify in game.
- Call of the Spirits / Ancestors levels (30/40 vs 40/30), Strength of Earth Totem's first level (4 vs 10), Berserking's duration (12 vs 15 s), Ghost Wolf's cast time, Tremor Totem's pulse, Purge's effect count.
- Spell IDs for Lightning Mastery and Mana Tide Totem; the Call of Water chain; The Tempest's Weapons level (30 vs 40); where Rage of the Storm, Lightning's Grasp and Tidebringer's Claw come from; the Enhancement hotfix date (Nov 10 vs 12).

### Gaps (28; never guessed)

- Later rank levels for most spells come only from endgametools (flagged). First-rank levels for 14 spells come only from there too.
- Per-rank spell IDs aren't sourced, and some page IDs are high ranks. **The addon detects spells by name**, using IDs only for icons and tooltips.
- Buff IDs and names for Maelstrom Weapon, Flurry, Elemental Devastation and the Improved Stormstrike regen buff. The addon reads auras by name.
- Post-30 class quests other than The Tempest's Weapons. Call of Water's middle quest IDs and its Horde start NPC.
- Totem advice: no raid Water totem and no solo Air totem for Elemental/Restoration. No caster imbue advice for level-60 dungeons or raids.
- The Elemental/Restoration Icy Veins pages predate the hotfix.
- Gear:
  - No Enhancement pre-raid list and no raid BiS (raids open Dec 9).
  - Elemental/Restoration leveling gear stops at 30; Enhancement armor stops around 35.
  - Rage of the Storm's DPS and type, and Elementalist's Guard's slot and stats, aren't sourced.
- Icy Veins' Shaman enchants pages return 404.
- Training costs per rank, the dual spec cost, Lightning Shield's charges and duration, and the Totemic Recall refund (verify in game).
- Trainer names other than Searn Firewarder come from one fan site.

### Addon assumptions (shown in About the data)

- Gear weights come from the order of each priority list; percent stats are scaled by 10 points per 1%.
- Spell damage counts Nature damage plus all-school damage.
- Mail is allowed from 40, the Classic rule (not confirmed for Forever).
- Water Shield is suggested under 35% mana for non-Restoration specs. Totem nudges appear only in combat or with an enemy targeted, and "running out" means under 10 s.
- The imbue is read from the main-hand tooltip's text. Totem slots use Blizzard's numbering through `GetTotemInfo` (Fire 1, Earth 2, Water 3, Air 4).
- If no guide row fits your situation, the imbue button suggests the best imbue you know, Windfury first.

## Decisions and notes

- **Base:** Tristan's Addon code was copied and renamed.
  - Removed: the PvP pieces (Battle screen, PvP bar, PvP module and data, burst coach, Forbearance, world-PvP notices, PvP weights) and the Paladin pieces (Blessing button, Aura/Seal hints, Paladin module).
  - New: `Modules/Shaman.lua`, the imbue and Fire Nova buttons, the shield/totem hints, Rotation › Totems & imbues and Cooldowns, and the Shaman reminders.
  - The only mentions of Andric, Parzelle or Tristan are the sister-addon links (About, README, site) and source comments crediting Andric's v0.1.5 `/cast` fix.
- **The PR is the first delivery.** Parzelle's first delivery had actually landed on `main` with no PR, so I used the minimal base commit described above.
- **Spell detection by name:** I changed `Progress.Knows` to check every sourced ID and then the spellbook by name, so no high-rank ID is ever treated as rank 1.
- **Learn sources:**
  - Talent `tree` values use spec names ("Elemental", not the calculator's "Elemental Combat"); the Learn and Talents screens match that.
  - Generated data may cite other classes where a source does (for example "A Paladin's Judgement of Wisdom" in the mana summary). The leftover-text test exempts `Data/` and gear consumable notes.
- **Poller fix:** curly quotes were turned into `"` after escaping, which produced invalid Lua. Fixed, with a regression test.
- **Sister-addon fixes (2026-11-14, at Tim's request, committed straight to `main` and pushed):**
  - The same poller quote fix and regression test, in Andric's (`d3a46b9`), Parzelle's (`f6df84f`) and Tristan's (`118c686`) pollers. None of their committed `Data/Changes.lua` files was broken yet. Poller tests (5/5 each) and addon tests (Andric's 34/34, Parzelle's 38/38, Tristan's 44/44) passed locally. Tristan's CI passed.
  - Andric's and Parzelle's `test.yml` now also run on pushes to `main`, not only on PRs: Andric's `6e29239`, Parzelle's `088e84f`. The first push-triggered runs passed (43609120325, 43609122044) and also covered the poller fix. This matches Tristan's setup.
- **Reagents:** Fish Oil (Water Walking), Shiny Fish Scales (Water Breathing) and Ankh (Reincarnation) are confirmed by Icy Veins. The reagent reminder only counts these for spells you know. The element totem items (5175–5178) are recorded but not reminded.
- **Professions:** Leveling notes say Tazu has Herbalism and should keep it; Icy Veins' Leatherworking + Skinning pick is shown as the research recommendation.
- **Website flavour:** the site uses the sister sites' playful quest-log rewards ("Codex of Next Steps" etc.). One invented NPC name, an innkeeper, was replaced with "the innkeeper".
- **CI:** `test.yml` runs on push to `main` and on PRs. `release.yml` (BigWigs packager) runs only on `v*` tags; `v0.1.0` is the only one so far.
- **autonomix-cli:** not listed, because the addon ships no Linux executables.

## Commits (PR #1, now on `main`)

- `c19636b` Initial commit: MIT licence and .gitignore (also on `main`)
- `c123568` Tazu's Addon v0.1.0: spec-aware Shaman companion for WoW Forever
- `4134b3c` STATUS: first delivery on PR #1, checks, client, gaps and conflicts, in-game checklist
- `ef34fd7` STATUS: record commit hashes
- `4ece6a5` STATUS: sister-addon poller fixes and CI push triggers
- `eca505d` STATUS: wow-addon topics set
- `1c1b3a8` Merge pull request #1 (on `main`)
- `b840895` STATUS, README: PR #1 merged to main (tagged `v0.1.0`)
- `d80ce8a` STATUS, README: v0.1.0 released
- the STATUS commit noting the rewritten release notes (see `git log`)

## Still to check in game

1. Slash commands: are `/tazu` and `/shaman` free (not a Blizzard command or emote)? If one clashes, keep `/tazu` and drop the other.
2. **Imbue button:** casts the right imbue at the highest rank with `/cast <Imbue>` (no rank). Does the main-hand tooltip show the imbue as "Rockbiter N (60 min)"-style text so the addon can name it? How does it look next to a sharpening stone or oil?
3. **Totems:**
   - `GetTotemInfo` slot numbers and readability in combat on Forever.
   - The Fire Nova button lights with Searing or Magma Totem down.
   - The bar doesn't overlap Blizzard's totem tracker or the Call of the Elements bar.
4. **Shield:** Lightning Shield and Water Shield aura names; whether orb counts (`applications`/`charges`) are readable.
5. **Maelstrom Weapon:** aura name and stacks are readable (HUD line); Cooldown Manager (`/cdm`) tracking.
6. **Conflicts:**
   - The Totemic Call cooldown and the Riptide numbers, from tooltips.
   - Call of the Spirits/Ancestors levels.
   - Strength of Earth Totem's first level.
   - Grace of Air vs Windfury Totem exclusivity.
   - Whether the Totemic Recall refund works.
7. **Quests:** Call of Earth (1516) shows for Tazu at 4 and is marked done once turned in. Call of Water's start NPC and steps.
8. **Spell detection by name:** spells known and "Train it" correct at levels 4–10, and talents appear once taken.
9. Stat parsing against real Forever tooltips (Nature damage lines), the gear upgrade glow, map pins. Is mail really locked until 40?
10. Dual spec at 40 (Enhancement A + Restoration B auto-switch), the window layout, the bar position, Lua errors (`/console scriptErrors 1`).
11. Website: open `docs/index.html` in a browser; add screenshots (other players' names pixelated) once Tim provides them.
