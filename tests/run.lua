-- Headless tests. Run from the repo root:  lua5.1 tests/run.lua
package.path = "./tests/?.lua;" .. package.path
local M = require("wow_mock")
M.Install()
local S = M.state

local passed, failed = 0, 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1 else
        failed = failed + 1
        io.stderr:write("FAIL " .. name .. ": " .. tostring(err) .. "\n")
        -- Don't let one failure leave combat/secret state on for the next tests.
        S.combat, S.secretOwnAuras, S.secretCooldowns = false, false, false
        S.mainHandLines, S.weaponEnchant, S.totems = nil, nil, nil
        M.RemoveSecrets()
    end
end
local function eq(a, b, msg) if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end end
local function near(a, b, msg) if math.abs(a - b) > 1e-6 then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end end
local function truthy(v, msg) if not v then error(msg or "expected truthy", 2) end end
local function textHas(pattern)
    for _, t in ipairs(M.texts) do if t:find(pattern, 1, true) then return true end end
    return false
end

local ns = M.LoadAddon("TazusAddon_Forever.toc", ".")

-- Mark a spell as known by name (by research ID when there is one, else by name).
local function know(name)
    local id = ns.Rotation.SpellId(name)
    if id then S.known[id] = true end
    S.knownNames[name] = true
end
local function forget()
    S.known, S.knownNames = {}, {}
end

local function renderAll(label)
    for _, key in ipairs(ns.PanelOrder) do
        M.texts = {}
        ns.UI.Open(key)
        for _, t in ipairs(M.texts) do
            if t:find("This panel hit an error", 1, true) then error(label .. "/" .. key .. ": " .. t) end
        end
    end
end

local SUBS = {
    leveling = { "Path", "Zones & dungeons", "Trainer", "Class quests", "Riding & gold" },
    gear = { "For my level", "Best overall", "By bracket", "Consumables", "Weights" },
    settings = { "General", "Shaman bar", "Tooltips & bags", "Reminders", "About the data", "About" },
    learn = { "Lessons", "Spells", "Talents", "How the class works", "Totems & imbues", "In a group", "PvP", "Leveling", "Common mistakes" },
    rotation = { "Solo", "Dungeon", "Raid", "World PvP", "Totems & imbues", "Cooldowns", "Mana" },
}
local function renderSubs(label)
    for key, list in pairs(SUBS) do
        for _, sub in ipairs(list) do
            M.texts = {}
            ns.UI.Open(key, sub)
            for _, t in ipairs(M.texts) do
                if t:find("This panel hit an error", 1, true) then error(label .. "/" .. key .. "/" .. sub .. ": " .. t) end
            end
        end
    end
    ns.UI.Open("rotation", "Solo")
end


test("toc files match between plain and _Forever", function()
    local a, b = io.open("TazusAddon.toc"):read("*a"), io.open("TazusAddon_Forever.toc"):read("*a")
    eq(a, b)
    truthy(a:find("## Interface: 16001", 1, true), "interface")
    truthy(a:find("## X-Website: https://github.com/ninepointlabs/tazus-addon", 1, true), "website")
    truthy(a:find("## Title: Tazu's Addon", 1, true), "title")
    truthy(a:find("## SavedVariables: TazusAddonDB", 1, true), "saved variables")
    truthy(a:find("## SavedVariablesPerCharacter: TazusAddonCharDB", 1, true), "per-character saved variables")
    -- every listed file exists; no Bindings.xml
    for line in a:gmatch("[^\n]+") do
        if not line:match("^##") and line:match("%S") then truthy(io.open((line:gsub("\\", "/"))), "missing " .. line) end
    end
    eq(io.open("Bindings.xml"), nil, "no Bindings.xml")
end)

test("no leftover Andric/Parzelle/Tristan/Paladin globals or code", function()
    local toc = io.open("TazusAddon.toc"):read("*a")
    for line in toc:gmatch("[^\n]+") do
        if not line:match("^##") and line:match("%S") then
            local f = line:gsub("\\", "/")
            -- Data/*.lua is generated from sourced research text (it may mention a Paladin's
            -- Judgement of Wisdom); only hand-written code is checked here.
            local s = f:match("^Data/") and "" or io.open(f):read("*a")
            for _, bad in ipairs({ "Parzelle", "Tristan", "Paladin", "isMage", "Blessing of", "Seal of", "PvPBar", "Forbearance" }) do
                -- About links to the sister addons are the only allowed mention.
                if not (f == "UI/Panels/Options.lua" and (bad == "Parzelle" or bad == "Tristan" or bad == "Paladin")) then
                    truthy(not s:find(bad, 1, true), f .. " mentions " .. bad)
                end
            end
            if f ~= "UI/Panels/Options.lua" and f ~= "UI/ShamanBar.lua" and f ~= "UI/ImbueButton.lua" then
                truthy(not s:find("Andric", 1, true), f .. " mentions Andric")
            end
        end
    end
end)

test("generated data present", function()
    truthy(#ns.Data.Spells >= 40, "spells")
    for _, spec in ipairs(ns.SPEC_ORDER) do
        truthy(ns.Data.Learn and ns.Data.Learn.rotation and ns.Data.Learn.rotation[spec] and ns.Data.Learn.rotation[spec].solo, "learn rotation " .. spec)
        truthy(ns.Data.StatPriority[spec], "stat priority " .. spec)
    end
    eq(ns.Data.Meta.toc_interface, 16001)
    eq(ns.Data.Meta.class, "Shaman")
    truthy(ns.Rotation.AnyId("Lightning Bolt"), "Lightning Bolt id")
    truthy(ns.Rotation.SpellRecord("Rockbiter Weapon"), "Rockbiter Weapon")
    truthy(ns.Rotation.SpellRecord("Fire Nova"), "Fire Nova (baseline spell)")
    truthy(#ns.Data.Totems >= 8, "totems")
    truthy(#ns.Data.ImbueAdvice >= 2, "imbue advice")
    truthy(ns.Data.TotemAdvice.Enhancement, "totem advice")
    truthy(ns.Data.PvP and #ns.Data.PvP.totem_picks >= 3, "PvP totem picks (v0.2)")
    truthy(#ns.Data.PvP.tips >= 5, "PvP tips")
    for _, spec in ipairs(ns.SPEC_ORDER) do truthy(ns.Data.Learn.rotation[spec].pvp, "World PvP rotation " .. spec) end
    -- removed spells and group Bloodlust never appear as spells or totems
    local function clean(list, field)
        for _, s in ipairs(list) do
            for _, bad in ipairs({ "Lava Burst", "Fire Nova Totem", "Tranquil Air Totem", "Dual Wield", "Bloodlust", "Heroism" }) do
                truthy(not s[field]:find(bad, 1, true), "removed spell imported: " .. s[field])
            end
        end
    end
    clean(ns.Data.Spells, "name")
    clean(ns.Data.Totems, "name")
end)

-- Login: Tazu, level 1, no talents, no spec.
S.level = 1
M.Fire("ADDON_LOADED", "TazusAddon")
M.Fire("PLAYER_LOGIN")
M.RunTimers()

test("login creates profile A/B with no spec", function()
    truthy(ns.db and ns.db.char.profiles.A and ns.db.char.profiles.B)
    eq(ns.DB.ActiveSpec(), nil)
    truthy(SlashCmdList.TAZUSADDON, "slash")
    eq(SLASH_TAZUSADDON1, "/tazu")
    eq(SLASH_TAZUSADDON2, "/shaman")
    eq(ns.isShaman, true)
    eq(ns.Progress.PlayerRace(), "Troll")
    eq(ns.RECOMMENDED_LEVELING_SPEC, "Enhancement")
end)

test("level 1, no talents, no spec: every screen renders and the picker recommends Enhancement", function()
    S.level = 1
    renderAll("no spec")
    renderSubs("no spec")
    M.texts = {}
    ns.UI.ShowPicker()
    truthy(textHas("talents start at 10"), "picker explains no talents yet")
    truthy(textHas("recommended for leveling"), "recommended badge")
    truthy(textHas("level as Enhancement"), "Enhancement for leveling")
    truthy(textHas("Enhancement (A) + Restoration (B)"), "dual spec plan")
    M.texts = {}
    ns.UI.Open("home")
    truthy(textHas("No talents yet"), "home nudge")
    M.texts = {}
    ns.UI.Open("talents")
    truthy(textHas("Pick a spec first"))
end)

test("DB.Init keeps saved values and fills defaults", function()
    local acc, ch = ns.DB.Init({ percentScale = 14 }, { active = "B", profiles = { B = { spec = "Restoration" } } })
    eq(acc.percentScale, 14)
    eq(ch.active, "B")
    eq(ch.profiles.B.spec, "Restoration")
    eq(ch.profiles.A.rotationContext, "solo")
    eq(ch.imbue.key, nil, "no imbue key bound by default")
    eq(ch.fireNova.key, nil, "no Fire Nova key bound by default")
    eq(ch.pvp, nil, "no PvP settings")
    ns.DB.Init(TazusAddonDB, TazusAddonCharDB)
end)

test("stat parsing: melee, caster and tank lines", function()
    local raw = ns.Stats.ParseLines({
        "Hammer of Testing", "+12 Strength", "+5 Agility", "+7 Intellect", "+5 Spirit", "+9 Stamina", "512 Armor", "24 Block",
        "Equip: Improves your chance to hit by 1%.", "Equip: Improves your chance to get a critical strike by 2%.",
        "Equip: +28 Attack Power.", "Equip: Increased Defense +7.", "Equip: Increases your chance to dodge an attack by 1%.",
        "Equip: Increases your chance to block attacks with a shield by 2%.", "Equip: Increases the block value of your shield by 10.",
        "Equip: Increases damage and healing done by magical spells and effects by up to 12.",
        "Equip: Increases damage done by Nature spells and effects by up to 6.",
        "Equip: Increases healing done by magical spells and effects by up to 20.",
        "Equip: Improves your chance to get a critical strike with spells by 1%.",
        "Equip: Restores 3 mana per 5 sec.", "(42.5 damage per second)",
        "(2) Set: +10 Strength", "Use: Restores 375 mana.",
    })
    eq(raw.STR, 12); eq(raw.AGI, 5); eq(raw.INT, 7); eq(raw.STA, 9); eq(raw.ARMOR, 512); eq(raw.BLOCK_VALUE, 34)
    eq(raw.HIT, 1); eq(raw.CRIT, 2); eq(raw.AP, 28); eq(raw.DEFENSE, 7); eq(raw.DODGE, 1); eq(raw.BLOCK, 2)
    eq(raw.SPELL_POWER, 12); eq(raw.NATURE_DAMAGE, 6); eq(raw.HEALING, 20); eq(raw.SPELL_CRIT, 1); eq(raw.MP5, 3); eq(raw.WEAPON_DPS, 42.5)
    local d = ns.Stats.Derive(raw, "Elemental")
    eq(d.DAMAGE, 18, "spell power + Nature damage"); eq(d.HEALING, 32, "healing + damage-and-healing")
end)

-- Item fixtures
local NEW, OLD, RING1, RING2, SWORD, MACE2H, PLATE = "item:1001", "item:1002", "item:1003", "item:1004", "item:1005", "item:1007", "item:1008"
local OFFHAND, MAIL = "item:1009", "item:1010"
S.itemInfo[1001] = { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 2 }
S.itemInfo[1002] = { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 2 }
S.itemInfo[1003] = { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0 }
S.itemInfo[1004] = { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0 }
S.itemInfo[1005] = { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7 }
S.itemInfo[1009] = { equipLoc = "INVTYPE_WEAPONOFFHAND", classID = 2, subclassID = 0 }
S.itemInfo[1010] = { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3 }
S.itemLines[OFFHAND] = { "Offhand Axe", "+9 Strength" }
S.itemLines[MAIL] = { "Mail", "+20 Strength" }
S.itemInfo[1007] = { equipLoc = "INVTYPE_2HWEAPON", classID = 2, subclassID = 5 }
S.itemInfo[1008] = { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 4 }
S.itemLines[NEW] = { "New", "+10 Strength", "+6 Stamina" }
S.itemLines[OLD] = { "Old", "+4 Strength" }
S.itemLines[RING1] = { "R1", "+3 Strength" }
S.itemLines[RING2] = { "R2", "+8 Strength" }
S.itemLines[SWORD] = { "Sword", "+5 Strength" }
S.itemLines[MACE2H] = { "Mace", "+15 Strength", "(30.0 damage per second)" }
S.itemLines[PLATE] = { "Plate", "+20 Stamina" }
S.equipped[5] = OLD
S.equipped[11] = RING1
S.equipped[12] = RING2

test("compare: Shamans use leather, mail from 40, maces and two-handers; no swords, plate or off-hands", function()
    ns.Stats.ClearCache()
    local res = ns.Stats.Compare(NEW, "Enhancement", 30, {}, 10)
    truthy(res.delta > 0, "strength leather chest is an Enhancement upgrade")
    eq(ns.Stats.Compare(SWORD, "Enhancement", 30, {}, 10).unusable, true, "no swords")
    eq(ns.Stats.Compare(PLATE, "Enhancement", 60, {}, 10).unusable, true, "no plate")
    eq(ns.Stats.Compare(OFFHAND, "Enhancement", 60, {}, 10).unusable, true, "no dual wield")
    eq(ns.Stats.Compare(MAIL, "Enhancement", 30, {}, 10).unusable, true, "mail not before 40")
    ns.Stats.ClearCache()
    truthy(not ns.Stats.Compare(MAIL, "Enhancement", 40, {}, 10).unusable, "mail at 40")
    truthy(not ns.Stats.Compare(MACE2H, "Enhancement", 30, {}, 10).unusable, "two-handed maces")
    eq(ns.Stats.Compare(MACE2H, "Enhancement", 30, {}, 10).isWeapon, true)
end)

test("tooltip lines", function()
    ns.Stats.ClearCache()
    local all = table.concat(ns.Tooltip.LinesFor(NEW, "Enhancement", {}, 30, 10), "\n")
    truthy(all:find("Strength", 1, true), all)
    truthy(all:find("addon assumption", 1, true))
    truthy(M.tooltipHook, "tooltip hook installed via TooltipDataProcessor")
    all = table.concat(ns.Tooltip.LinesFor(SWORD, "Enhancement", {}, 30, 10), "\n")
    truthy(all:find("Shamans can't use this", 1, true))
end)

test("training: faction and talent filtering", function()
    for lvl = 1, 60 do
        for _, e in ipairs(ns.Training.At(lvl, "Enhancement", "Horde")) do
            truthy(e.spell.faction ~= "Alliance", "no Alliance spell for Horde: " .. e.spell.name)
            if e.spell.talent then eq(e.spell.talent_tree, "Enhancement", "only Enhancement talent spells: " .. e.spell.name) end
        end
    end
    truthy(ns.Training.NextLevel(1, "Enhancement"), "a next trainer level after 1")
    eq(ns.Training.NextLevel(60, "Enhancement"), nil)
end)

test("quests: Troll Horde shaman sees the Orc & Troll totem quests, never Dwarf or Skyborne ones", function()
    local list = ns.Progress.ClassQuests("Troll", "Horde")
    local byName = {}
    for _, q in ipairs(list) do
        byName[q.name] = q
        truthy(q.faction ~= "Alliance", "no Alliance quest: " .. q.name)
        truthy(not (q.races or ""):find("Skyborne", 1, true), "no Skyborne quest: " .. q.name)
    end
    truthy(byName["Call of Earth"], "Call of Earth listed")
    eq(byName["Call of Earth"].level, 4)
    eq(byName["Call of Earth"].quest_id, 1516)
    truthy(byName["Call of Fire"] and byName["Call of Fire"].level == 10, "Call of Fire at 10")
    truthy(byName["Call of Water"] and byName["Call of Water"].level == 20, "Call of Water at 20")
    truthy(byName["Call of Air"] and byName["Call of Air"].level == 30, "Call of Air at 30")
    truthy(byName["The Tempest's Weapons"], "The Tempest's Weapons")
    local q = ns.Progress.NextClassQuest("Troll", "Horde", 4)
    eq(q and q.name, "Call of Earth", "next quest at level 4 is Call of Earth")
    -- other paths exist in the data but stay hidden
    M.texts = {}
    ns.UI.Open("leveling", "Class quests")
    for _, dq in ipairs(ns.Data.Quests) do
        if (dq.faction == "Alliance" or (dq.races or ""):find("Skyborne", 1, true)) and not byName[dq.name] then
            truthy(not textHas(dq.name), "other-path quest hidden: " .. dq.name)
        end
    end
end)

test("gold goals from research", function()
    local g = ns.Progress.GoldGoals()
    eq(g[1].level, 40)
    truthy(g[1].gold > 0)
end)

-- Rotation engine with a fake state
local function fakeState(o)
    return {
        inCombat = function() return o.combat or false end,
        hasTarget = function() return o.target ~= false end,
        spellName = function(n) return n end,
        playerBuff = function(n) return o.buffs and o.buffs[n] or false end,
        playerDebuff = function(n) return o.debuffs and o.debuffs[n] or false end,
        playerStacks = function(n) return o.stacks and o.stacks[n] or 0 end,
        targetDebuff = function(n) return o.tdebuffs and o.tdebuffs[n] or false end,
        cooldown = function(n) return o.cds and o.cds[n] or 0 end,
        manaPct = function() return o.mana or 100 end,
        targetHpPct = function() return o.hp or 100 end,
        known = function(n) return o.known == nil or o.known[n] == true end,
        usable = function(n) return o.usable and o.usable[n] or false end,
        inMelee = function() return o.melee ~= false end,
        imbue = function() if o.imbue == nil then return false end return o.imbue end,
        shield = function() if o.shield == nil then return false end return o.shield end,
        totem = function(e) return o.totems and o.totems[e] or false end,
    }
end

test("rotation: every step uses a supported condition and a researched spell", function()
    for spec, ctxs in pairs(ns.Data.Learn.rotation) do
        for ctxName, ctx in pairs(ctxs) do
            truthy(#ctx.priority > 0, spec .. "/" .. ctxName .. " empty")
            for _, step in ipairs(ctx.priority) do
                local r = ns.Rotation.Check(step, fakeState({}))
                truthy(r ~= nil, ("%s/%s: condition %s unsupported"):format(spec, ctxName, tostring(step.when)))
                truthy(ns.Rotation.IsKnownName(step.spell), ("%s/%s: unknown spell %s"):format(spec, ctxName, step.spell))
            end
        end
    end
end)

test("rotation: shaman conditions", function()
    local C = ns.Rotation.Check
    eq(C({ spell = "Rockbiter Weapon", when = "imbue_missing" }, fakeState({})), true)
    eq(C({ spell = "Rockbiter Weapon", when = "imbue_missing" }, fakeState({ imbue = { name = "Rockbiter Weapon", left = 1800 } })), false)
    eq(C({ spell = "Rockbiter Weapon", when = "imbue_missing" }, fakeState({ imbue = { name = "Rockbiter Weapon", left = 20 } })), true, "running out")
    eq(C({ spell = "Lightning Shield", when = "shield_missing" }, fakeState({})), true)
    eq(C({ spell = "Lightning Shield", when = "shield_missing" }, fakeState({ shield = { name = "Lightning Shield" } })), false)
    eq(C({ spell = "Fire Nova", when = "fire_totem_out" }, fakeState({})), false, "no Fire totem -> no Fire Nova")
    eq(C({ spell = "Fire Nova", when = "fire_totem_out" }, fakeState({ totems = { Fire = { name = "Searing Totem" } } })), true)
    eq(C({ spell = "Searing Totem", when = "no_fire_totem" }, fakeState({})), true)
    eq(C({ spell = "Stoneskin Totem", when = "totem_missing:Earth" }, fakeState({})), true)
    eq(C({ spell = "Stoneskin Totem", when = "totem_missing:Earth" }, fakeState({ totems = { Earth = { name = "Stoneskin Totem" } } })), false)
    eq(C({ spell = "Lightning Bolt", when = "stacks_at_least:Maelstrom Weapon:5" }, fakeState({ stacks = { ["Maelstrom Weapon"] = 5 } })), true)
    eq(C({ spell = "Lightning Bolt", when = "stacks_at_least:Maelstrom Weapon:5" }, fakeState({ stacks = { ["Maelstrom Weapon"] = 2 } })), false)
    eq(C({ spell = "Flame Shock", when = "target_debuff_missing:Flame Shock" }, fakeState({})), true)
    eq(C({ spell = "Flame Shock", when = "target_debuff_missing:Flame Shock" }, fakeState({ tdebuffs = { ["Flame Shock"] = true } })), false)
    eq(C({ spell = "Chain Lightning", when = "mana_above:40" }, fakeState({ mana = 30 })), false)
    eq(C({ spell = "Purge", when = "manual" }, fakeState({})), false)
    eq(C({ spell = "Stormstrike", when = "ready" }, fakeState({ cds = { Stormstrike = 4 } })), false)
end)

test("rotation shows only spells usable at your level (level 4 Troll, Valley of Trials)", function()
    local savedLevel = S.level
    S.level = 4
    forget()
    know("Lightning Bolt"); know("Rockbiter Weapon"); know("Healing Wave")
    eq(ns.Rotation.Availability("Lightning Bolt", 4, "Troll", "Horde"), "known")
    local es = ns.Rotation.SpellRecord("Earth Shock")
    truthy(es and es.rank_learn_levels[1], "Earth Shock has a level")
    eq(ns.Rotation.Availability("Earth Shock", es.rank_learn_levels[1] - 1, "Troll", "Horde"), nil, "Earth Shock not before its level")
    eq(ns.Rotation.Availability("Earth Shock", es.rank_learn_levels[1], "Troll", "Horde"), "trainable", "Train it")
    eq(ns.Rotation.Availability("Stormstrike", 30, "Troll", "Horde"), nil, "talent not taken")
    for _, sp in ipairs(ns.Data.Spells) do
        if sp.faction == "Alliance" then eq(ns.Rotation.Availability(sp.name, 60, "Troll", "Horde"), nil, sp.name) end
    end
    ns.DB.SetSpec("Enhancement")
    ns.DB.Profile().rotationContext = "solo"
    M.texts = {}
    ns.UI.Open("rotation", "Solo")
    truthy(not textHas(". Stormstrike"), "Stormstrike hidden at 4")
    truthy(textHas("unlock with levels or talents"))
    forget()
    S.level = savedLevel
end)

test("level 4 Troll in the Valley of Trials, no talents: Home, Leveling and Rotation make sense", function()
    S.level = 4
    forget()
    know("Lightning Bolt"); know("Rockbiter Weapon"); know("Healing Wave"); know("Earth Shock")
    ns.DB.SetSpec("Enhancement")
    renderAll("troll4")
    renderSubs("troll4")
    M.texts = {}
    ns.UI.Open("home")
    truthy(textHas("Call of Earth"), "Home: next totem class quest is Call of Earth")
    M.texts = {}
    ns.UI.Open("leveling", "Path")
    truthy(textHas("Valley of Trials"), "Leveling: Valley of Trials")
    M.texts = {}
    ns.UI.Open("rotation", "Totems & imbues")
    truthy(textHas("Call of Earth"), "no totems yet -> Call of Earth")
    forget()
    S.level = 24
end)

test("shaman state: imbue, shield and totem recommendations", function()
    local Sh = ns.Shaman
    local all = function() return true end
    local only = function(...) local set = {} for _, n in ipairs({ ... }) do set[n] = true end return function(n) return set[n] == true end end
    -- Imbue: Windfury at the heart of Enhancement (Nov 10/11 hotfix); Rockbiter as the pre-30 fallback.
    eq(Sh.RecommendedImbue({ spec = "Enhancement", context = "solo", level = 40 }, all), "Windfury Weapon", "Enhancement 40: Windfury")
    eq(Sh.RecommendedImbue({ spec = "Enhancement", context = "dungeon", level = 40 }, all), "Windfury Weapon", "Enhancement dungeon: Windfury")
    eq(Sh.RecommendedImbue({ spec = "Enhancement", context = "solo", level = 12 }, only("Rockbiter Weapon")), "Rockbiter Weapon", "level 12: Rockbiter")
    eq(Sh.RecommendedImbue({ spec = "Enhancement", context = "solo", level = 4 }, only("Rockbiter Weapon")), "Rockbiter Weapon", "level 4: Rockbiter")
    eq(Sh.RecommendedImbue({ spec = "Enhancement", level = 1 }, function() return false end), nil, "nothing known")
    for _, a in ipairs(ns.Data.ImbueAdvice) do
        truthy(Sh.IMBUE_WORD[a.imbue], "imbue advice names a real imbue: " .. tostring(a.imbue))
    end
    -- Shield
    eq(Sh.RecommendedShield({ spec = "Enhancement" }, only("Lightning Shield")), "Lightning Shield")
    eq(Sh.RecommendedShield({ spec = "Restoration" }, all), "Water Shield")
    eq(Sh.RecommendedShield({ spec = "Elemental", manaPct = 80 }, all), "Lightning Shield")
    eq(Sh.RecommendedShield({ spec = "Elemental", manaPct = 10 }, all), "Water Shield", "low mana")
    -- Totems: advice limited to what you know; nothing at level 1.
    local rec = Sh.RecommendedTotems("Enhancement", "solo", function() return false end)
    eq(next(rec), nil, "no totems known -> no advice")
    rec = Sh.RecommendedTotems("Enhancement", "dungeon", all)
    truthy(next(rec), "dungeon advice when everything is known")
    for _, spec in ipairs(ns.SPEC_ORDER) do
        for _, ctx in ipairs(ns.Rotation.CONTEXTS) do
            for e, name in pairs(Sh.RecommendedTotems(spec, ctx, all)) do
                local t = Sh.TotemRecord(name)
                truthy(t, spec .. "/" .. ctx .. ": advised totem in the research: " .. name)
                eq(t.element, e, name .. " element")
            end
        end
    end
    -- Imbue reading from the main-hand tooltip
    eq(Sh.ImbueFromLines({ "Big Axe", "Windfury 3 (60 min)" }), "Windfury Weapon")
    eq(Sh.ImbueFromLines({ "Big Axe", "+5 Strength" }), nil)
    S.mainHandLines = { "Axe", "Rockbiter 1 (58 min)" }
    S.weaponEnchant = { ms = 3480000 }
    local im = Sh.Imbue()
    eq(im.name, "Rockbiter Weapon"); eq(im.left, 3480)
    S.mainHandLines, S.weaponEnchant = nil, nil
    eq(Sh.Imbue(), false, "no imbue")
    S.weaponEnchant = { ms = 600000 }
    im = Sh.Imbue()
    eq(im.name, nil, "some enchant we can't name (stone or oil)")
    S.weaponEnchant = nil
    -- Totems from GetTotemInfo
    S.totems = { [1] = { name = "Searing Totem", start = 990, duration = 30 } }
    eq(Sh.Totem("Fire").name, "Searing Totem")
    eq(Sh.Totem("Fire").left, 20)
    eq(Sh.Totem("Earth"), false)
    S.totems = nil
end)

test("imbue button: secure /cast macrotext, highest rank, combat freeze, keys", function()
    forget()
    eq(ns.Imbue.ShouldShow(), false, "hidden until you know an imbue")
    know("Rockbiter Weapon")
    S.level = 12
    ns.DB.SetSpec("Enhancement")
    ns.DB.Profile().rotationContext = "solo"
    ns.Imbue.Refresh()
    local b = _G.TazusImbueButton
    truthy(b, "button exists")
    eq(b:GetAttribute("type"), "macro")
    eq(b:GetAttribute("macrotext"), "/cast Rockbiter Weapon", "rank-less /cast picks your highest rank")
    truthy(b:GetAttribute("useOnKeyDown") ~= true, "acts on release")
    truthy(ns.ShamanBar.Shown().imbue, "on the Shaman bar")
    truthy(b.status:GetText():find("no imbue", 1, true), "no imbue yet")
    S.mainHandLines = { "Axe", "Rockbiter 1 (60 min)" }
    S.weaponEnchant = { ms = 3600000 }
    ns.Imbue.Update()
    truthy(b.status:GetText():find("60m", 1, true), "time left shown: " .. tostring(b.status:GetText()))
    -- Already on with time to spare: the button must not cast.
    eq(b:GetAttribute("type"), nil, "Rockbiter already on -> disarmed")
    eq(b:GetAttribute("macrotext"), nil, "no macrotext while already on")
    -- Running out: armed again to refresh.
    S.weaponEnchant = { ms = 200000 }
    ns.Imbue.Update()
    eq(b:GetAttribute("macrotext"), "/cast Rockbiter Weapon", "re-armed under 5 minutes")
    -- An enchant we can't name (stone/oil): still armed.
    S.mainHandLines, S.weaponEnchant = { "Axe" }, { ms = 3600000 }
    ns.Imbue.Update()
    eq(b:GetAttribute("macrotext"), "/cast Rockbiter Weapon", "unnamed enchant -> still casts")
    S.mainHandLines, S.weaponEnchant = { "Axe", "Rockbiter 1 (60 min)" }, { ms = 3600000 }
    ns.Imbue.Update()
    eq(b:GetAttribute("type"), nil, "disarmed again")
    -- Windfury once known (level 30+), and frozen in combat
    know("Windfury Weapon")
    S.level = 32
    S.combat = true
    ns.Imbue.Update()
    eq(b:GetAttribute("macrotext"), nil, "doesn't change in combat (stays disarmed: Rockbiter is on)")
    S.combat = false
    ns.Imbue.Update()
    eq(b:GetAttribute("macrotext"), "/cast Windfury Weapon", "Windfury out of combat")
    truthy(b.status:GetText():find("Rockbiter", 1, true), "wrong imbue flagged")
    -- pin
    ns.db.char.imbue.override = "Rockbiter Weapon"
    ns.Imbue.Update()
    eq(b:GetAttribute("type"), nil, "pinned Rockbiter is already on -> doesn't cast")
    S.mainHandLines, S.weaponEnchant = nil, nil
    ns.Imbue.Update()
    eq(b:GetAttribute("macrotext"), "/cast Rockbiter Weapon", "pinned imbue")
    ns.db.char.imbue.override = nil
    -- keys: none by default, Super refused, override click
    eq(ns.db.char.imbue.key, nil)
    S.meta = true
    eq(ns.ShamanBar.KeyString("F"), nil, "Super/Meta combos refused (Omarchy)")
    S.meta = false
    ns.Imbue.SetKey("ALT-W")
    eq(M.overrides["ALT-W"], "TazusImbueButton:LeftButton")
    ns.Imbue.SetKey(nil)
    S.combat = true
    ns.Imbue.SetKey("G")
    eq(ns.db.char.imbue.key, nil, "can't rebind in combat")
    S.combat = false
    ns.Imbue.StartKeyCapture()
    local cap = _G.TazusKeyCapture
    cap.__scripts.OnKeyDown(cap, "G")
    eq(ns.db.char.imbue.key, "G", "captured key saved")
    ns.Imbue.SetKey(nil)
    ns.Imbue.Debug()
    for _, m in ipairs(M.macros) do error("no macros may be created: " .. m.name) end
    S.mainHandLines, S.weaponEnchant = nil, nil
    forget()
    S.level = 24
end)

test("Fire Nova button: only lit with a Fire totem down, secure /cast", function()
    forget()
    ns.FireNova.Refresh()
    eq(ns.ShamanBar.Shown().firenova, nil, "hidden until Fire Nova is known")
    know("Fire Nova")
    ns.FireNova.Refresh()
    local b = _G.TazusFireNovaButton
    eq(b:GetAttribute("type"), "macro")
    eq(b:GetAttribute("macrotext"), "/cast Fire Nova")
    truthy(ns.ShamanBar.Shown().firenova, "on the bar")
    ns.FireNova.Update()
    truthy(b.status:GetText():find("no Fire totem", 1, true), "dim without a Fire totem")
    eq(ns.Shaman.FireNovaReady(), false)
    S.totems = { [1] = { name = "Searing Totem", start = 1000, duration = 30 } }
    ns.FireNova.Update()
    truthy(b.status:GetText():find("ready", 1, true), "lit with a Fire totem")
    eq(ns.Shaman.FireNovaReady(), true)
    S.totems = { [2] = { name = "Stoneskin Totem" } }
    eq(ns.Shaman.FireNovaReady(), false, "an Earth totem doesn't count")
    S.totems = nil
    ns.FireNova.SetKey("SHIFT-F")
    eq(M.overrides["SHIFT-F"], "TazusFireNovaButton:LeftButton")
    ns.FireNova.SetKey(nil)
    for _, m in ipairs(M.macros) do error("no macros may be created: " .. m.name) end
    forget()
    ns.FireNova.Refresh()
end)

test("shield and totem hint cells: hints, not secure buttons", function()
    local st = { recShield = "Lightning Shield", shield = false, spec = "Enhancement", context = "solo" }
    local sv = ns.Hints.ShieldView(st)
    eq(sv.active, true, "no shield -> refresh me")
    truthy(sv.status:find("refresh me", 1, true))
    st.shield = { name = "Lightning Shield", charges = 3 }
    sv = ns.Hints.ShieldView(st)
    eq(sv.ok, true)
    truthy(sv.status:find("3 orbs", 1, true), "orbs shown")
    st.shield = nil
    truthy(ns.Hints.ShieldView(st).status:find("hidden", 1, true), "hidden shield state")
    local rec = { Earth = "Stoneskin Totem", Fire = "Searing Totem" }
    local tv = ns.Hints.TotemView(st, { { element = "Fire", want = "Searing Totem", why = "none down" } }, false, rec)
    eq(tv.active, true)
    truthy(tv.status:find("Fire missing", 1, true), tv.status)
    tv = ns.Hints.TotemView(st, {}, false, rec)
    eq(tv.ok, true, "all down")
    tv = ns.Hints.TotemView(st, nil, false, rec)
    truthy(tv.status:find("advice", 1, true), "between pulls: advice only")
    eq(ns.Hints.TotemView(st, {}, false, {}), nil, "no totems known -> no cell")
    forget()
    know("Lightning Shield")
    ns.DB.SetSpec("Enhancement")
    ns.Hints.Refresh()
    truthy(ns.ShamanBar.Shown().shield, "shield cell on the bar")
    forget()
end)

test("cooldowns and procs (own spells only)", function()
    forget()
    know("Stormstrike"); know("Fire Nova"); know("Maelstrom Weapon")
    S.cooldowns = { Stormstrike = 5 }
    local byName = {}
    for _, e in ipairs(ns.Cooldowns.List()) do byName[e.spell] = e end
    truthy(byName.Stormstrike, "Stormstrike listed")
    truthy(not byName["Rage of the Farseer"], "untaken talent not listed")
    S.auras = { ["Maelstrom Weapon"] = { applications = 5 } }
    truthy(ns.Cooldowns.HudLine():find("5/5", 1, true), ns.Cooldowns.HudLine())
    S.auras = {}
    truthy(ns.Cooldowns.HudLine():find("0/5", 1, true))
    S.cooldowns = {}
    forget()
end)

test("level 34 Enhancement after the Nov 10/11 hotfix, secret values mocked: everything renders, hidden not guessed", function()
    S.level = 34
    forget()
    for _, n in ipairs({ "Lightning Bolt", "Earth Shock", "Flame Shock", "Rockbiter Weapon", "Flametongue Weapon", "Windfury Weapon", "Lightning Shield",
        "Stoneskin Totem", "Strength of Earth Totem", "Searing Totem", "Fire Nova", "Healing Stream Totem", "Mana Spring Totem", "Windfury Totem",
        "Stormstrike", "Ghost Wolf", "Healing Wave", "Purge", "Maelstrom Weapon" }) do know(n) end
    ns.DB.SetSpec("Enhancement")
    S.combat = true
    S.totems = { [1] = { name = "Searing Totem" } }
    M.InstallSecrets()
    S.secretMode, S.secretCooldowns = true, true
    eq(ns.Auras.HealthPct("target"), nil, "target health secret -> unknown")
    eq(ns.Auras.CooldownLeft("Stormstrike"), nil, "cooldown secret -> unknown")
    local _, blocked = ns.Rotation.Suggest("Enhancement", "solo", nil, 3)
    truthy(blocked, "suggestion flags hidden info")
    renderAll("enh34-secret")
    renderSubs("enh34-secret")
    M.texts = {}
    ns.UI.Open("rotation", "Cooldowns")
    truthy(textHas("hidden"), "cooldowns show hidden")
    ns.Hud.Refresh()
    ns.Hud.Update()
    -- own auras, totems and weapon secret too
    S.secretOwnAuras = true
    eq(ns.Shaman.Totem("Fire"), nil, "totem secret -> unknown")
    eq(ns.Shaman.Imbue(), nil, "imbue secret -> unknown")
    eq(ns.Shaman.Shield(), nil, "shield secret -> unknown")
    eq(ns.Shaman.FireNovaReady(), nil)
    truthy(ns.Cooldowns.HudLine():find("hidden", 1, true), "Maelstrom hidden")
    ns.Hints.Update()
    ns.Imbue.Update()
    ns.FireNova.Update()
    renderAll("enh34-secret-own")
    renderSubs("enh34-secret-own")
    S.secretOwnAuras = false
    M.RemoveSecrets()
    S.secretCooldowns = false
    S.combat = false
    S.totems = nil
    forget()
    S.level = 24
end)

test("summary tips", function()
    local knows = function() return true end
    local f = { duration = 20, manaStart = 90, manaEnd = 60, casts = { ["Lightning Bolt"] = 1 }, order = {}, hidden = 0 }
    local tips = table.concat(ns.Summary.Tips(f, "Enhancement", "solo", knows), "\n")
    truthy(tips:find("Stormstrike", 1, true), tips)
    f = { duration = 20, manaStart = 90, manaEnd = 10, casts = { ["Healing Wave"] = 5 }, order = {}, hidden = 2 }
    tips = table.concat(ns.Summary.Tips(f, "Restoration", "dungeon", knows), "\n")
    truthy(tips:find("Water Shield", 1, true)); truthy(tips:find("hidden", 1, true))
    f = { duration = 20, manaStart = 90, manaEnd = 60, casts = { ["Lightning Bolt"] = 6 }, order = {}, hidden = 0 }
    tips = table.concat(ns.Summary.Tips(f, "Elemental", "solo", knows), "\n")
    truthy(tips:find("Flame Shock", 1, true), tips)
    ns.Summary.Start(0, 90)
    eq(ns.Summary.Finish(2, 90), nil, "too short")
end)

test("learn: lessons unlock by level, Call of Earth at 4, totem articles, hints after first scan", function()
    local unlocked, upcoming = ns.Learn.Lessons(24, "Enhancement")
    truthy(#unlocked > 0 and #upcoming > 0)
    local four = false
    for _, l in ipairs(unlocked) do
        if l.level == 4 and (l.title or ""):find("Call of Earth", 1, true) then four = true end
        truthy(l.faction ~= "Alliance", "no Alliance lesson for Tazu: " .. l.title)
        truthy(not l.races or ns.Progress.RaceMatches(l.races, "Troll"), "no other-race lesson for Tazu: " .. l.title)
    end
    for _, l in ipairs(upcoming) do truthy(l.faction ~= "Alliance", "no upcoming Alliance lesson for Tazu: " .. l.title) end
    truthy(four, "a level-4 Call of Earth lesson")
    truthy(#(ns.Data.Learn.totems or {}) >= 4, "totem/imbue/shield articles")
    forget()
    ns.db.char.learn.seenSpells = { ["Healing Wave"] = true }
    know("Lightning Bolt")
    ns.Learn.ScanSpells(false)
    truthy(ns.db.char.learn.seenSpells["Lightning Bolt"], "marks new spell seen")
    forget()
end)

test("reminders: imbue, shield, totems with a target, class quest at 4, Ghost Wolf at 20", function()
    forget()
    know("Rockbiter Weapon"); know("Lightning Shield")
    ns.DB.SetSpec("Enhancement")
    S.auras = {}
    S.level = 4
    S.target = true
    local ids = {}
    for _, r in ipairs(ns.Reminders.Missing()) do ids[r.id] = r end
    truthy(ids.imbue, "imbue missing")
    truthy(ids.shield, "shield missing")
    truthy(ids.classQuest and ids.classQuest.label:find("Call of Earth", 1, true), "Call of Earth open at 4")
    S.mainHandLines, S.weaponEnchant = { "Axe", "Rockbiter 1 (60 min)" }, { ms = 3600000 }
    S.auras = { ["Lightning Shield"] = { applications = 3 } }
    S.questsDone[1516] = true
    ids = {}
    for _, r in ipairs(ns.Reminders.Missing()) do ids[r.id] = r end
    truthy(not ids.imbue and not ids.shield, "imbue and shield up")
    truthy(not (ids.classQuest and ids.classQuest.label:find("Call of Earth", 1, true)), "Call of Earth done")
    -- totems with an enemy targeted
    know("Stoneskin Totem"); know("Searing Totem"); know("Strength of Earth Totem")
    S.level = 22
    ids = {}
    for _, r in ipairs(ns.Reminders.Missing()) do ids[r.id] = r end
    truthy(ids.ghostWolf, "Ghost Wolf from 20")
    truthy(ids.classQuest, "Call of Fire / Water open")
    S.questsDone, S.auras, S.mainHandLines, S.weaponEnchant = {}, {}, nil, nil
    S.level = 24
    forget()
end)

test("every panel and sub-tab renders for every spec (levels 1, 24, 30, 60)", function()
    for _, lvl in ipairs({ 1, 24, 30, 60 }) do
        S.level = lvl
        for _, spec in ipairs(ns.SPEC_ORDER) do
            ns.DB.SetSpec(spec)
            renderAll(spec .. "@" .. lvl)
            renderSubs(spec .. "@" .. lvl)
        end
    end
    S.level = 24
    eq(#ns.PanelOrder, 8, "8 screens")
    for _, old in ipairs({ "overview", "training", "quests", "mounts", "reminders", "sources", "options", "changes", "mana", "totems", "imbues", "cooldowns", "imbue", "bar" }) do
        ns.UI.Open(old)
    end
    truthy(#ns.UI.Search("lightning") > 0, "search finds Lightning spells")
    truthy(#ns.UI.Search("searing") > 0, "search finds totems")
    eq(#ns.UI.Search("s"), 0, "search needs 2+ characters")
end)

test("window groups: Home · Play · Progress · Learn · More, no Battle", function()
    local titles = {}
    for _, g in ipairs(ns.UI.NAV) do if g.title then table.insert(titles, g.title) end end
    eq(table.concat(titles, ","), "Play,Progress,Learn,More")
    eq(ns.Panels.battle, nil)
end)

test("no Priest, Mage, Paladin, Andric, Parzelle or Tristan text in the window (except the About links)", function()
    local bad = {}
    for _, spec in ipairs(ns.SPEC_ORDER) do
        ns.DB.SetSpec(spec)
        for key, list in pairs(SUBS) do
            for _, sub in ipairs(list) do
                ns.UI.Open(key, sub)
                M.texts = {}
                ns.UI.Refresh()
                for _, t in ipairs(M.texts) do
                    local about = (key == "settings" and sub == "About")
                    if t:find("Andric", 1, true) and not about then bad[#bad + 1] = key .. "/" .. sub .. ": " .. t end
                    if t:find("Parzelle", 1, true) and not about then bad[#bad + 1] = key .. "/" .. sub .. ": " .. t end
                    if t:find("Tristan", 1, true) and not about then bad[#bad + 1] = key .. "/" .. sub .. ": " .. t end
                    -- Sourced consumable notes may name other classes' buffs ("exclusive with Blessing of Wisdom").
                    if (t:find("Blessing of", 1, true) or t:find("Seal of", 1, true) or t:find("Battleground", 1, true)) and not (key == "gear" and sub == "Consumables") then bad[#bad + 1] = key .. "/" .. sub .. ": " .. t end
                    if (t:find("Conjure", 1, true) or t:find("Arcane Intellect", 1, true)) and not (key == "gear" and sub == "Consumables") then bad[#bad + 1] = key .. "/" .. sub .. ": " .. t end
                end
            end
        end
    end
    eq(#bad, 0, table.concat(bad, "\n"))
end)

test("Alliance content hidden for Horde (quests, gear)", function()
    eq(ns.GearOtherFaction({ faction = "Alliance" }), true, "Horde player, Alliance-only item")
    eq(ns.GearOtherFaction({ faction = "Horde" }), false)
    eq(ns.GearOtherFaction({}), false)
end)

test("bags: highlight + one-time announcement", function()
    ns.DB.SetSpec("Enhancement")
    S.level = 30
    S.bagSlots = { [0] = { NEW, SWORD } }
    S.bagStacks = {}
    ns.Bags.Reset()
    local printed = 0
    local realPrint = ns.Print
    ns.Print = function(m) if tostring(m):find("Upgrade in your bags", 1, true) then printed = printed + 1 end end
    local found = ns.Bags.Scan(false)
    eq(#found, 1, "chest is an upgrade, sword is not")
    ns.Bags.Scan(false)
    eq(printed, 1, "announced once")
    ns.Print = realPrint
    ns.Bags.RefreshAll()
    S.bagSlots = {}
end)

test("About names Tazu and links the sister addons", function()
    M.texts = {}
    SlashCmdList.TAZUSADDON("about")
    truthy(textHas("Tazu"), "About tab shows Tazu's full name")
    truthy(textHas("tazus-addon.myazerothlife.com"), "website link")
    truthy(textHas("Troll Shaman of the Horde"), "Tazu's race and faction")
    truthy(textHas("Andric's Addon"), "sister addon")
    truthy(textHas("Parzelle's Addon"), "sister addon")
    truthy(textHas("Tristan's Addon"), "sister addon")
    truthy(textHas("myazerothlife.com"), "My Azeroth Life")
end)

test("slash commands", function()
    SlashCmdList.TAZUSADDON("spec resto")
    eq(ns.DB.ActiveSpec(), "Restoration")
    SlashCmdList.TAZUSADDON("spec ele")
    eq(ns.DB.ActiveSpec(), "Elemental")
    SlashCmdList.TAZUSADDON("spec enh")
    eq(ns.DB.ActiveSpec(), "Enhancement")
    SlashCmdList.TAZUSADDON("profile")
    eq(ns.DB.ActiveId(), "B")
    SlashCmdList.TAZUSADDON("profile A")
    for _, cmd in ipairs({ "gear", "totems", "cooldowns", "mana", "imbue debug", "imbue", "imbue", "nova", "nova", "bar", "remind", "bogus", "" }) do SlashCmdList.TAZUSADDON(cmd) end
end)

test("events: level up, combat, casts, zones, totems, weapon", function()
    S.level = 26
    M.Fire("PLAYER_LEVEL_UP", 26)
    S.combat = true
    M.Fire("PLAYER_REGEN_DISABLED")
    M.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", ns.Rotation.SpellId("Lightning Bolt"))
    S.time = 1030
    S.combat = false
    M.Fire("PLAYER_REGEN_ENABLED")
    M.Fire("SPELLS_CHANGED")
    M.Fire("UNIT_AURA", "player")
    M.Fire("UNIT_AURA", "target")
    M.Fire("PLAYER_TARGET_CHANGED")
    M.Fire("PLAYER_EQUIPMENT_CHANGED")
    M.Fire("BAG_UPDATE_DELAYED")
    M.Fire("GROUP_ROSTER_UPDATE")
    M.Fire("ZONE_CHANGED_NEW_AREA")
    M.Fire("PLAYER_ENTERING_WORLD")
    M.Fire("PLAYER_TOTEM_UPDATE", 1)
    M.Fire("UNIT_INVENTORY_CHANGED", "player")
    M.RunTimers()
    S.time = nil
end)

test("dual-spec ready profiles", function()
    ns.DB.SwitchProfile("A")
    ns.db.char.profiles.A.spec, ns.db.char.profiles.B.spec = nil, nil
    local fired = 0
    ns.On("SPEC_CHANGED", function() fired = fired + 1 end)
    ns.DB.SetSpec("Enhancement")
    ns.DB.SetSpec("Restoration", "B")
    eq(ns.DB.ActiveSpec(), "Enhancement")
    truthy(ns.DB.SwitchProfile("B"))
    eq(ns.DB.ActiveSpec(), "Restoration")
    eq(ns.DB.SwitchProfile("B"), false)
    ns.DB.SwitchProfile("A")
    eq(fired, 3, "SPEC_CHANGED fires on active changes only")
    truthy(M.events.ACTIVE_TALENT_GROUP_CHANGED, "dual-spec event registered")
    eq(ns.db.char.autoSwitch, true)
    S.numSpecGroups, S.specGroup = 2, 2
    eq(ns.DualSpec.HasDualSpec(), true)
    M.Fire("ACTIVE_TALENT_GROUP_CHANGED", 2, 1)
    eq(ns.DB.ActiveId(), "B")
    eq(ns.DB.ActiveSpec(), "Restoration")
    S.specGroup = 1
    M.Fire("ACTIVE_TALENT_GROUP_CHANGED", 1, 2)
    eq(ns.DB.ActiveId(), "A")
    ns.db.char.autoSwitch = false
    M.Fire("ACTIVE_TALENT_GROUP_CHANGED", 2, 1)
    eq(ns.DB.ActiveId(), "A", "no switch when disabled")
    ns.db.char.autoSwitch = true
    S.specGroup = 2
    truthy(ns.DualSpec.Sync(), "sync to active group")
    eq(ns.DB.ActiveId(), "B")
    S.specGroup = 1
    ns.DualSpec.Sync()
    S.numSpecGroups = 1
end)

test("weights derive from priority order", function()
    for _, spec in ipairs(ns.SPEC_ORDER) do
        local prio = ns.Data.StatPriority[spec]
        local w = ns.Stats.Weights(spec, 10)
        local n = #prio.keys
        for r, k in ipairs(prio.keys) do
            local expect = (n - r + 1) / n
            if ns.Stats.PERCENT_KEYS[k] then expect = expect * 10 end
            near(w[k], expect, spec .. " " .. k)
        end
        eq(ns.Stats.WeightSetName(spec, 30, {}), spec)
    end
end)

test("compare: rings replace the weaker ring", function()
    eq(ns.Stats.Compare(OLD, "Enhancement", 30, {}, 10).isEquipped, true)
    S.itemInfo[1006] = { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0 }
    S.itemLines["item:1006"] = { "R3", "+5 Strength" }
    local res = ns.Stats.Compare("item:1006", "Enhancement", 30, {}, 10)
    eq(res.against.slot, 11, "compares to weaker ring")
    truthy(res.delta > 0)
end)

test("changes: research baseline unread, mark read", function()
    local n = ns.Changes.UnreadCount()
    truthy(n >= 3, "research changes")
    ns.Changes.MarkRead(ns.Changes.All()[1])
    eq(ns.Changes.UnreadCount(), n - 1)
    ns.Changes.MarkAllRead()
    eq(ns.Changes.UnreadCount(), 0)
end)

test("talent builds decode onto Forever's trees", function()
    eq(#ns.Data.TalentTrees, 3, "three trees")
    local valid, valid60 = 0, 0
    for _, b in ipairs(ns.Data.DecodedBuilds) do
        if b.valid then
            valid = valid + 1
            for ti, tree in ipairs(ns.Data.TalentTrees) do
                eq(#b.trees[ti].points, #tree.talents, "points per talent")
                for i, t in ipairs(tree.talents) do truthy(b.trees[ti].points[i] <= t.max_rank) end
            end
            if b.level == 60 then valid60 = valid60 + 1 eq(b.total, 51) end
            truthy(b.total <= 51)
        else
            truthy(b.reason and b.reason ~= "", "invalid builds say why")
        end
    end
    truthy(valid > 0, "at least one build draws")
    for _, spec in ipairs(ns.SPEC_ORDER) do
        ns.DB.SetSpec(spec)
        M.texts = {}
        ns.UI.Open("talents")
        truthy(textHas("points (level"), spec .. " build summary line")
    end
end)

test("gear: my-level view vs best overall", function()
    S.level = 24
    ns.Data.GearBrackets["level 20"] = ns.Data.GearBrackets["level 20"] or {}
    table.insert(ns.Data.GearBrackets["level 20"], { name = "Testing Robe Low", item_id = 8801, source = "Test Dungeon" })
    table.insert(ns.Data.GearBrackets["level 20"], { name = "Testing Robe High", item_id = 8802, source = "Test Dungeon" })
    S.itemInfo[8801] = { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 2, minLevel = 18 }
    S.itemInfo[8802] = { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 2, minLevel = 31 }
    S.itemLines["item:8801"] = { "Chest", "+6 Strength" }
    S.itemLines["item:8802"] = { "Chest", "+40 Strength" }
    ns.Stats.ClearCache()
    ns.DB.SetSpec("Enhancement")
    ns.UI.SetGearView("mine")
    M.texts = {}
    ns.UI.Open("gear")
    truthy(not textHas("Testing Robe High"), "level-31 item hidden at 24")
    ns.UI.SetGearView("best")
    M.texts = {}
    ns.UI.Refresh()
    truthy(textHas("Testing Robe High"), "best overall includes higher-level items")
    ns.UI.SetGearView("mine")
end)

test("map pin helpers", function()
    local e = ns.Map.FindDungeonEntrance("Wailing Caverns")
    truthy(e, "entrance from client map data")
    M.waypoints = {}
    truthy(ns.Map.SetWaypoint(e.mapID, e.x, e.y, "WC"))
    eq(M.waypoints[1].mapID, 10); eq(M.superTracked, true)
end)

-- ---------------------------------------------------------------------------
-- v0.2: Smart Shock, Smart Heal, PvP mode, totem sets, Stoneform, Dwarf/Alliance.

local function noMacros() for _, m in ipairs(M.macros) do error("no macros may be created: " .. m.name) end end

test("Smart Shock: secure /cast with [mod:] conditionals, Frost Shock once known, modifier configurable, unbound", function()
    forget()
    ns.Shock.Refresh()
    eq(ns.ShamanBar.Shown().shock, nil, "hidden until a Shock is known")
    eq(ns.Smart.ShockText(function() return false end), nil)
    know("Earth Shock")
    ns.Shock.Refresh()
    local b = _G.TazusShockButton
    eq(b:GetAttribute("type"), "macro")
    eq(b:GetAttribute("macrotext"), "/cast Earth Shock", "Earth Shock only, rank-less (highest rank)")
    truthy(ns.ShamanBar.Shown().shock, "on the Shaman bar")
    eq(ns.db.char.shock.key, nil, "unbound by default")
    know("Frost Shock")
    ns.Shock.Refresh()
    eq(b:GetAttribute("macrotext"), "/cast [mod:shift] Frost Shock; Earth Shock", "Shift for Frost Shock by default")
    ns.Shock.SetMod("ctrl")
    eq(b:GetAttribute("macrotext"), "/cast [mod:ctrl] Frost Shock; Earth Shock", "modifier configurable")
    SlashCmdList.TAZUSADDON("shock alt")
    eq(b:GetAttribute("macrotext"), "/cast [mod:alt] Frost Shock; Earth Shock", "/tazu shock alt")
    ns.Shock.SetMod("bogus")
    eq(ns.db.char.shock.mod, "alt", "unknown modifier ignored")
    -- frozen in combat
    S.combat = true
    ns.Shock.SetMod("shift")
    eq(b:GetAttribute("macrotext"), "/cast [mod:alt] Frost Shock; Earth Shock", "no change in combat")
    S.combat = false
    ns.Shock.SetMod("shift")
    ns.Shock.SetKey("ALT-Q")
    eq(M.overrides["ALT-Q"], "TazusShockButton:LeftButton", "override click binding")
    ns.Shock.SetKey(nil)
    noMacros()
    forget()
    ns.Shock.Refresh()
end)

test("Smart Heal: friendly target else you, Alt for Lesser Healing Wave once known, no ranks", function()
    forget()
    ns.Heal.Refresh()
    eq(ns.ShamanBar.Shown().heal, nil, "hidden until Healing Wave is known")
    know("Healing Wave")
    ns.Heal.Refresh()
    local b = _G.TazusHealButton
    eq(b:GetAttribute("type"), "macro")
    eq(b:GetAttribute("macrotext"), "/cast [@target,help,nodead][@player] Healing Wave")
    know("Lesser Healing Wave")
    ns.Heal.Refresh()
    eq(b:GetAttribute("macrotext"), "/cast [mod:alt,@target,help,nodead][mod:alt,@player] Lesser Healing Wave; [@target,help,nodead][@player] Healing Wave")
    truthy(not b:GetAttribute("macrotext"):find("Rank", 1, true), "never downranks")
    eq(ns.db.char.heal.key, nil, "unbound by default")
    S.units.target = { friend = true }
    ns.Heal.Update()
    truthy(b.status:GetText():find("target", 1, true), "friendly target")
    S.units.target = nil
    ns.Heal.Update()
    truthy(b.status:GetText():find("you", 1, true), "enemy target -> you")
    ns.Heal.SetKey("SHIFT-E")
    eq(M.overrides["SHIFT-E"], "TazusHealButton:LeftButton")
    ns.Heal.SetKey(nil)
    SlashCmdList.TAZUSADDON("heal")
    eq(ns.db.char.heal.enabled, false, "/tazu heal hides it")
    SlashCmdList.TAZUSADDON("heal")
    noMacros()
    forget()
    ns.Heal.Refresh()
end)

test("PvP mode: per profile, realm-id detection only suggests (once), World PvP context everywhere", function()
    eq(ns.PvP.RulesetFromRealm("CAMWOWUS2Realm6PvP"), "pvp")
    eq(ns.PvP.RulesetFromRealm("CAMWOWUS2Realm1PvE"), "pve")
    eq(ns.PvP.RulesetFromRealm("Ganj"), nil, "can't tell -> manual")
    eq(ns.PvP.RulesetFromRealm(nil), nil)
    ns.DB.SwitchProfile("A")
    ns.DB.SetSpec("Enhancement")
    ns.DB.SetPvP(false)
    ns.db.char.pvpSuggested = nil
    S.realm = "CAMWOWUS2Realm1PvE"
    eq(ns.PvP.MaybeSuggest(), false, "Normal realm: no suggestion")
    S.realm = "CAMWOWUS2Realm6PvP"
    eq(ns.PvP.MaybeSuggest(), true, "PvP realm: suggest")
    eq(ns.DB.PvP(), false, "suggesting never turns it on")
    eq(ns.PvP.MaybeSuggest(), false, "only once per realm")
    S.realm = nil
    eq(ns.DB.Context(), ns.DB.Profile().rotationContext or "solo")
    SlashCmdList.TAZUSADDON("pvp")
    eq(ns.DB.PvP(), true, "/tazu pvp toggles on")
    eq(ns.DB.Context(), "pvp")
    eq(ns.DB.PvP("B"), false, "per profile: B unchanged")
    eq(ns.Shaman.State().context, "pvp")
    ns.Hud.Refresh()
    M.texts = {}
    ns.UI.Open("rotation", "World PvP")
    truthy(textHas("PvP mode is on"), "Rotation shows World PvP")
    truthy(textHas("PVP TOTEM PICKS"), "PvP totem picks listed")
    M.texts = {}
    ns.UI.Open("learn", "PvP")
    truthy(textHas("Grounding Totem") and textHas("Tremor Totem") and textHas("Earthbind Totem"), "Learn > PvP")
    truthy(not textHas("Stoneform vs melee"), "Dwarf-only tip hidden for a Troll")
    ns.UI.Open("rotation", "Solo")
    eq(ns.DB.PvP(), false, "picking a PvE tab turns PvP mode off")
    ns.UI.Open("rotation", "World PvP")
    eq(ns.DB.PvP(), true, "World PvP tab turns it on")
    SlashCmdList.TAZUSADDON("pvp off")
    eq(ns.DB.PvP(), false)
end)

test("totem sets: PvE guide picks, PvP set (Earthbind/Grounding), saved picks win, hint follows PvP mode", function()
    forget()
    for _, n in ipairs({ "Stoneskin Totem", "Strength of Earth Totem", "Earthbind Totem", "Tremor Totem", "Searing Totem",
        "Healing Stream Totem", "Mana Spring Totem", "Windfury Totem", "Grounding Totem" }) do know(n) end
    S.level = 32
    ns.DB.SetSpec("Enhancement")
    ns.DB.Profile().rotationContext = "solo"
    ns.DB.Profile().totemSets = { pve = {}, pvp = {} }
    local pve, key = ns.Shaman.ActiveTotemSet("Enhancement", "solo")
    eq(key, "pve")
    eq(pve.Earth, "Strength of Earth Totem", "guide pick")
    eq(pve.Air, "Windfury Totem")
    local pvp, key2 = ns.Shaman.ActiveTotemSet("Enhancement", "pvp")
    eq(key2, "pvp")
    eq(pvp.Earth, "Earthbind Totem", "PvP set: Earthbind")
    eq(pvp.Air, "Grounding Totem", "PvP set: Grounding")
    eq(pvp.Fire, pve.Fire, "PvP set falls back to the Solo pick")
    ns.Shaman.SetTotemPick("pvp", "Earth", "Tremor Totem")
    eq(ns.Shaman.ActiveTotemSet("Enhancement", "pvp").Earth, "Tremor Totem", "saved pick wins")
    eq(ns.Shaman.ActiveTotemSet("Enhancement", "solo").Earth, "Strength of Earth Totem", "PvE set untouched")
    ns.Shaman.SetTotemPick("pve", "Water", "Magma Totem")
    eq(ns.Shaman.ActiveTotemSet("Enhancement", "solo").Water, "Mana Spring Totem", "unknown saved pick ignored")
    ns.DB.SetPvP(true)
    local st = ns.Shaman.State()
    eq(st.totems.Earth, "Tremor Totem", "state follows PvP mode")
    local tv = ns.Hints.TotemView(st, nil, false, st.totems)
    truthy(tv.lines[1]:find("PvP set", 1, true), "hint names the PvP set")
    -- vs an enemy Warlock: Tremor
    local vs = ns.PvP.PicksVs("WARLOCK")
    local names = {}
    for _, t in ipairs(vs) do names[t.name] = true end
    truthy(names["Tremor Totem"] and names["Grounding Totem"], "Warlock: Tremor + Grounding")
    eq(#ns.PvP.PicksVs(nil), 0, "unreadable class -> no pick")
    tv = ns.Hints.TotemView(st, nil, false, st.totems, ns.PvP.PicksVs("ROGUE"))
    truthy(tv.status:find("Earthbind", 1, true), "vs a Rogue: Earthbind")
    S.targetIsPlayer, S.units.target = true, { class = "MAGE", player = true }
    eq(ns.PvP.EnemyPlayerClass(), "MAGE")
    S.targetIsPlayer, S.units.target = nil, nil
    M.texts = {}
    ns.UI.Open("settings", "Shaman bar")
    truthy(textHas("Totem sets") or textHas("TOTEM SETS (PROFILE A)"), "totem set editor")
    ns.DB.SetPvP(false)
    ns.DB.Profile().totemSets = { pve = {}, pvp = {} }
    forget()
    S.level = 24
end)

test("Stoneform hint: Dwarves only, from readable debuffs only, silent otherwise", function()
    forget()
    know("Stoneform")
    eq(ns.Shaman.StoneformNudge("Troll"), false, "not a Dwarf")
    S.debuffs = {}
    eq(ns.Shaman.StoneformNudge("Dwarf"), false, "nothing on you")
    S.debuffs = { { name = "Curse of X", dispelName = "Curse" }, { name = "Deadly Poison", dispelName = "Poison" } }
    local need, types = ns.Shaman.StoneformNudge("Dwarf")
    eq(need, true)
    eq(types[1], "Poison")
    S.debuffs = { { name = "Rend", dispelName = "Bleed" } }
    eq((ns.Shaman.StoneformNudge("Dwarf")), true, "a debuff the client labels Bleed")
    S.debuffs = { { name = "Rend" } }
    eq((ns.Shaman.StoneformNudge("Dwarf")), false, "no guessing from names")
    S.debuffs = { { name = "Deadly Poison", dispelName = "Poison" } }
    M.InstallSecrets()
    S.secretMode, S.secretOwnAuras = true, true
    eq(ns.Shaman.StoneformNudge("Dwarf"), nil, "secret debuffs -> can't tell")
    local v = ns.Hints.StoneformView(nil)
    eq(v.active, false)
    eq(v.status, "", "says nothing")
    S.secretOwnAuras = false
    M.RemoveSecrets()
    v = ns.Hints.StoneformView(true, { "Poison" }, 0)
    eq(v.active, true)
    truthy(v.status:find("press it", 1, true))
    v = ns.Hints.StoneformView(true, { "Poison" }, 90)
    eq(v.active, false, "on cooldown: dim")
    -- the cell exists only for Dwarves
    ns.Hints.Refresh()
    eq(ns.ShamanBar.Shown().stoneform, nil, "no Stoneform cell for a Troll")
    S.debuffs = nil
    forget()
end)

test("Bramm: Dwarf Shaman of the Alliance sees the Dwarf path, trainers, quests and lessons", function()
    local race, faction = S.race, S.faction
    S.race, S.faction = "Dwarf", "Alliance"
    forget()
    know("Stoneform")
    S.level = 3
    ns.DB.SetSpec("Enhancement")
    local list = ns.Progress.ClassQuests("Dwarf", "Alliance")
    local byName = {}
    for _, q in ipairs(list) do
        byName[q.name] = q
        eq(q.faction, "Alliance", "only Alliance quests: " .. q.name)
        eq(q.races, "Dwarf", "only Dwarf versions: " .. q.name)
    end
    for _, n in ipairs({ "Call of Earth", "Call of Fire", "Call of Water", "Call of Air", "The Tempest's Weapons" }) do truthy(byName[n], n) end
    eq(byName["Call of Earth"].level, 4)
    -- the quest-id conflict: any of the ids counts
    eq(ns.Progress.ClassQuestDone(byName["Call of Earth"]), false)
    S.questsDone[94375] = true
    eq(ns.Progress.ClassQuestDone(byName["Call of Earth"]), true, "alt quest id counts as done")
    S.questsDone[94375] = nil
    M.texts = {}
    ns.UI.Open("leveling", "Path")
    truthy(textHas("Coldridge Valley"), "Coldridge Valley path card at level 3")
    truthy(not textHas("Valley of Trials"), "no Troll start zone")
    M.texts = {}
    ns.UI.Open("leveling", "Class quests")
    truthy(textHas("Teo Hammerstorm"), "Alliance trainers / Dwarf quest giver")
    truthy(textHas("Eldrun Stormbreaker"), "Ironforge trainer")
    truthy(not textHas("Searn Firewarder"), "no Horde trainer")
    truthy(not textHas("Canaga"), "no Troll quest text")
    S.level = 12
    M.texts = {}
    ns.UI.Open("leveling", "Path")
    truthy(textHas("Loch Modan"), "Loch Modan at 12")
    local unlocked = ns.Learn.Lessons(30, "Enhancement")
    local ids = {}
    for _, l in ipairs(unlocked) do ids[l.id] = true end
    truthy(ids["call-of-earth-dwarf"] and ids["dwarf"] and ids["loch-modan"], "Dwarf lessons")
    truthy(not ids["call-of-earth"] and not ids["troll"] and not ids["barrens"], "no Troll/Horde lessons")
    local q = ns.Progress.NextClassQuest("Dwarf", "Alliance", 4)
    eq(q and q.quest_id, 96243, "next quest: Dwarf Call of Earth")
    ns.Hints.Refresh()
    truthy(ns.ShamanBar.Shown().stoneform, "Stoneform cell for a Dwarf who knows it")
    S.debuffs = { { name = "Deadly Poison", dispelName = "Poison" } }
    local _, _, fv = ns.Hints.Update()
    truthy(fv and fv.active, "Stoneform lit with a poison on you")
    S.debuffs = nil
    M.texts = {}
    ns.UI.Open("learn", "PvP")
    truthy(textHas("Stoneform vs melee"), "Dwarf PvP tip shown")
    for _, lvl in ipairs({ 1, 24, 60 }) do
        S.level = lvl
        renderAll("dwarf@" .. lvl)
        renderSubs("dwarf@" .. lvl)
    end
    -- the window never shows the Troll path to Bramm
    M.texts = {}
    ns.UI.Open("learn", "Leveling")
    truthy(textHas("Alliance Dwarf path") and not textHas("Horde Troll path"), "Learn > Leveling path by race")
    S.race, S.faction = race, faction
    S.level = 24
    forget()
    ns.Hints.Refresh()
end)


print(("%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
