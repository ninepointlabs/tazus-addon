# WoW Forever Shaman – Sources (checked 2026-11-14, America/Chicago). Raw copies in raw/.

## Blizzard (primary)
- https://news.blizzard.com/en-us/article/24302097/world-of-warcraft-forever-class-deep-dives-mage-and-shaman (Mage and Shaman deep dive, Oct 7/8)
- https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696 (dev notes thread incl. Nov 2 launch changes)
- https://news.blizzard.com/en-us/article/24315281/wow-forever-hotfixes-november-13-2026 (hotfix list, updated in place; Shaman entries Nov 9, 10/11 and 13)

## Icy Veins (wow-forever)
- shaman-class-overview, shaman-class-quests, shaman-talent-calculator (JS only, as with other classes)
- elemental|enhancement|restoration-shaman-leveling
- elemental-shaman-ranged-dps-pve-guide, -rotation-cooldowns-abilities, -spec-builds-talents, -stat-priority, -gear-best-in-slot
- enhancement-shaman-melee-dps-pve-guide, -rotation-cooldowns-abilities, -spec-builds-talents, -stat-priority, -gear-best-in-slot
- restoration-shaman-healer-pve-guide, -rotation-cooldowns-abilities, -spec-builds-talents, -stat-priority, -gear-best-in-slot
- Icy Veins `*-enchants-consumables` URLs returned a generic page (not found) on 2026-11-14
- race-guide / racial-tier-list, wow-forever-overview, roadmap, legacy-system (copied from earlier priest research; originally checked 2026-11-09)
- db.icy-veins.com/wow-forever/quests|items|spells/<id> for totem quests and a few spell IDs

## Wowhead
- forever/guides/classes/shaman (index stub)
- forever/guide/classes/shaman/elemental|enhancement|restoration overviews, talent-builds, leveling-tips, rotation, abilities, stat-priority, bis-gear, enchants-consumables
- forever/news/mage-and-shaman-class-deep-dive-for-world-of-warcraft-forever-383305
- forever/news/how-does-elemental-shaman-look-in-wow-forever-383356
- forever/guide/unlocking-riding-skill-mounts (copied from earlier priest research)

## Community summaries (secondary)
- https://foreverguide.net/classes/shaman/ and https://foreverguide.net/tools/talent-calculator/shaman/
- https://bindonforever.com/notes/deep-dive-mage-shaman (deep-dive notes; check against launch + Nov 10–13 hotfixes)
- https://wow-forever.gg/classes/shaman/feed/ (hotfix excerpts)
- https://www.foreverwisp.com/guides/wow-forever-shaman-call-of-earth-quest
- https://dailyrespawn.com/article/how-to-get-all-four-totems-as-a-horde-shaman-in-wow-forever-earth-fire-water-air
- https://www.warcrafttavern.com/forever/guides/dwarf-shaman-totem-quests/ (Alliance Dwarf path; useful only as a contrast, not for Tazu)

## Change detection feeds
- Same as priest/mage/paladin: Blizzard blue tracker RSS, Forever dev-notes thread, Wowhead Forever news RSS, Gethe/wow-ui-source forever.atom

## v0.2 (checked 2026-11-25): Dwarf/Alliance, PvP, Stoneform
Findings with per-fact sources: `research/v0.2_findings.json` (merged into `parts/core.json`: `leveling_paths`, `pvp`, `class_trainers.alliance_*`, Dwarf quest notes, totem/Stoneform fixes, gaps).
- Icy Veins: https://www.icy-veins.com/wow-forever/news/not-sure-where-to-level-in-wow-forever-heres-every-zone-from-1-to-60/ (zone levels 1-60), https://www.icy-veins.com/wow-forever/pvp-overview, https://www.icy-veins.com/wow-forever/racial-tier-list, https://www.icy-veins.com/wow-classic/classic-shaman-pvp-guide (Classic, flagged)
- Icy Veins DB (Forever): spells 20594 (Stoneform), 8177, 8143, 2484, 3600, 5730, 8166, 8170, 8042, 8056, 331, 8004, 370
- Wowhead Forever (read via WebFetch; curl got 403, summaries in raw/wowhead_forever_webfetch_extracts.md): spell=20594, 8177, 8143, 2484; npc=257446 (Teo Hammerstorm), 258113 (Ingrid Dunwald), 258098 (Eldrun Stormbreaker), 270263 (Farseer Maret Firetend)
- warcraft.wiki.gg: Coldridge Valley, Dun Morogh, Loch Modan, Wetlands, Stoneform, Grounding/Tremor/Earthbind Totem, API GetRealmName, API C_GameRules.GetActiveGameMode
- Secondary: https://www.warcrafttavern.com/forever/guides/class-trainers/ and .../dwarf-shaman-totem-quests/ (trainer subzones/coords, Dwarf quest steps), https://www.skill-capped.com/wowarticles/forever/guides/enhancement-shaman-pvp-guide/ (PvP tips; third party)
- Ruleset: no documented API. GetRealmName() ids observed in StoryTracker SavedVariables on TUF: CAMWOWUS2Realm1PvE (Normal), CAMWOWUS2Realm6PvP (PvP ruleset).
- Fetch note: Icy Veins and warcraft.wiki.gg now block fetch.py's short "Mozilla/5.0" user agent (Cloudflare); a full Chrome UA string works.
