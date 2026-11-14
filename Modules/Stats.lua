-- Item stat parsing, spec weights and upgrade comparison.
--
-- Stats come from the item's tooltip text (Forever items use Classic-style
-- "Equip: ..." lines, which C_Item.GetItemStats does not report reliably).
-- enUS client text only; unknown lines are ignored ("some info hidden" is
-- shown when an item's tooltip isn't available yet).
--
-- Weights are DERIVED, not simulated: the research gives each spec an ordered
-- stat priority (Data/Gear.lua -> StatPriority). Rank r of n gets weight
-- (n - r + 1) / n. Percent stats (hit/crit) are multiplied by
-- TazusAddonDB.percentScale (default 10 points per 1%), which is an addon
-- assumption and is flagged as such wherever a score is shown. Users can
-- override any weight per profile.
local _, ns = ...

local Stats = {}
ns.Stats = Stats

Stats.DEFAULT_PERCENT_SCALE = 10
-- Percent stats and weapon DPS are multiplied by the "points per 1%" setting
-- (an addon assumption, flagged wherever a score is shown).
Stats.PERCENT_KEYS = { HIT = true, CRIT = true, SPELL_HIT = true, SPELL_CRIT = true, DODGE = true, PARRY = true, BLOCK = true, WEAPON_DPS = true }

Stats.LABELS = {
    WEAPON_DPS = "Weapon DPS", STR = "Strength", AGI = "Agility", AP = "Attack power",
    HIT = "Hit %", CRIT = "Crit %", EXPERTISE = "Expertise",
    DAMAGE = "Spell damage (Nature + all schools)", HEALING = "Healing power",
    SPELL_HIT = "Spell hit %", SPELL_CRIT = "Spell crit %", INT = "Intellect",
    SPI = "Spirit", STA = "Stamina", MP5 = "Mana per 5",
    DEFENSE = "Defense", ARMOR = "Armor", BLOCK = "Block %", BLOCK_VALUE = "Block value",
    DODGE = "Dodge %", PARRY = "Parry %",
}
-- Display order in tooltips and the Weights tab.
Stats.ORDER = { "WEAPON_DPS", "STR", "AP", "AGI", "HIT", "CRIT", "EXPERTISE", "DAMAGE", "HEALING", "SPELL_HIT", "SPELL_CRIT",
    "INT", "SPI", "MP5", "STA", "DEFENSE", "ARMOR", "BLOCK", "BLOCK_VALUE", "DODGE", "PARRY" }

-- Lower-cased patterns -> raw keys. Order matters: first match wins per line.
-- Classic-style English tooltip text; Forever's exact wording is checked in game.
Stats.PATTERNS = {
    { "^%+(%d+) strength$", "STR" },
    { "^%+(%d+) agility$", "AGI" },
    { "^%+(%d+) intellect$", "INT" },
    { "^%+(%d+) spirit$", "SPI" },
    { "^%+(%d+) stamina$", "STA" },
    { "^(%d+) armor$", "ARMOR" },
    { "^(%d+) block$", "BLOCK_VALUE" },
    { "^equip: %+(%d+) attack power%.?$", "AP" },
    { "^equip: increases attack power by (%d+)%.?$", "AP" },
    { "^%+(%d+) attack power$", "AP" },
    { "^equip: improves your chance to hit with spells by (%d+)%%%.?$", "SPELL_HIT" },
    { "^equip: improves your chance to get a critical strike with spells by (%d+)%%%.?$", "SPELL_CRIT" },
    { "^equip: improves your chance to hit by (%d+)%%%.?$", "HIT" },
    { "^equip: improves your chance to get a critical strike by (%d+)%%%.?$", "CRIT" },
    { "^equip: increases your expertise by (%d+)%.?$", "EXPERTISE" },
    { "^%+(%d+) expertise$", "EXPERTISE" },
    { "^equip: increased defense %+(%d+)%.?$", "DEFENSE" },
    { "^%+(%d+) defense$", "DEFENSE" },
    { "^equip: increases your chance to dodge an attack by (%d+)%%%.?$", "DODGE" },
    { "^equip: increases your chance to parry an attack by (%d+)%%%.?$", "PARRY" },
    { "^equip: increases your chance to block attacks with a shield by (%d+)%%%.?$", "BLOCK" },
    { "^equip: increases the block value of your shield by (%d+)%.?$", "BLOCK_VALUE" },
    { "^equip: increases damage and healing done by magical spells and effects by up to (%d+)%.?$", "SPELL_POWER" },
    { "^%+(%d+) damage and healing spells$", "SPELL_POWER" },
    { "^%+(%d+) spell damage and healing$", "SPELL_POWER" },
    { "^equip: increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects%.?$", "HEALING", "HEALING_DMG" },
    { "^equip: increases healing done by magical spells and effects by up to (%d+)%.?$", "HEALING" }, -- Forever wording
    { "^equip: increases healing done by spells and effects by up to (%d+)%.?$", "HEALING" },
    { "^equip: increases healing done by up to (%d+)%.?$", "HEALING" },
    { "^%+(%d+) healing spells$", "HEALING" },
    { "^%+(%d+) healing$", "HEALING" },
    { "^equip: increases damage done by magical spells and effects by up to (%d+)%.?$", "SPELL_DAMAGE" },
    { "^%+(%d+) spell damage$", "SPELL_DAMAGE" },
    { "^equip: increases damage done by nature spells and effects by up to (%d+)%.?$", "NATURE_DAMAGE" },
    { "^%+(%d+) nature spell damage$", "NATURE_DAMAGE" },
    { "^%+(%d+) nature damage$", "NATURE_DAMAGE" },
    { "^equip: restores (%d+) mana per 5 sec%.?$", "MP5" },
    { "^%+?(%d+) mana every 5 sec%.?$", "MP5" },
    { "^%+?(%d+) mana per 5 sec%.?$", "MP5" },
    { "^%+?(%d+) mana every 5 seconds$", "MP5" },
    { "^%(([%d%.]+) damage per second%)$", "WEAPON_DPS" },
}

local function clean(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return strtrim and strtrim(text):lower() or (text:match("^%s*(.-)%s*$")):lower()
end

-- lines: array of strings. Returns raw stat table.
function Stats.ParseLines(lines)
    local raw = {}
    for _, line in ipairs(lines) do
        if type(line) == "string" and line ~= "" then
            local text = clean(line)
            -- Set bonuses only apply with the set; "Use:" effects are not passive stats.
            if not text:find("^%(%d%) set:") and not text:find("^set:") and not text:find("^use:") then
                for _, p in ipairs(Stats.PATTERNS) do
                    local a, b = text:match(p[1])
                    if a then
                        raw[p[2]] = (raw[p[2]] or 0) + tonumber(a)
                        if p[3] and b then raw[p[3]] = (raw[p[3]] or 0) + tonumber(b) end
                        break
                    end
                end
            end
        end
    end
    return raw
end

-- Combine raw tooltip stats into the keys the research priorities use.
-- DAMAGE = all-school spell damage + Nature damage (Lightning Bolt, Chain
-- Lightning, Earth Shock and Lightning Shield are Nature; Fire and Frost damage
-- lines are left out because only some Shaman spells use them: addon choice).
-- HEALING = healing power + the "damage and healing" lines.
function Stats.Derive(raw, spec)
    local base = (raw.SPELL_POWER or 0) + (raw.SPELL_DAMAGE or 0) + (raw.HEALING_DMG or 0)
    return {
        WEAPON_DPS = raw.WEAPON_DPS or 0,
        STR = raw.STR or 0, AGI = raw.AGI or 0, AP = raw.AP or 0,
        HIT = raw.HIT or 0, CRIT = raw.CRIT or 0, EXPERTISE = raw.EXPERTISE or 0,
        DAMAGE = base + (raw.NATURE_DAMAGE or 0),
        HEALING = (raw.SPELL_POWER or 0) + (raw.HEALING or 0),
        SPELL_HIT = raw.SPELL_HIT or 0,
        SPELL_CRIT = raw.SPELL_CRIT or 0,
        INT = raw.INT or 0,
        SPI = raw.SPI or 0,
        STA = raw.STA or 0,
        MP5 = raw.MP5 or 0,
        DEFENSE = raw.DEFENSE or 0, ARMOR = raw.ARMOR or 0,
        BLOCK = raw.BLOCK or 0, BLOCK_VALUE = raw.BLOCK_VALUE or 0,
        DODGE = raw.DODGE or 0, PARRY = raw.PARRY or 0,
    }
end

-- Which research priority applies to a profile right now.
function Stats.WeightSetName(spec, level, profile)
    if not spec then return "Leveling" end
    local useLeveling = profile and profile.levelingWeights
    if useLeveling == nil then useLeveling = false end
    if not ns.Data.StatPriority.Leveling then useLeveling = false end
    local maxLevel = (ns.Data.Meta and ns.Data.Meta.max_level) or 60
    if useLeveling and level and level < maxLevel then return "Leveling" end
    return ns.Specs[spec].weights
end

function Stats.Weights(setName, percentScale, overrides)
    local prio = ns.Data.StatPriority[setName]
    local weights = {}
    if not prio then return weights end
    local n = #prio.keys
    for r, key in ipairs(prio.keys) do
        local w = (n - r + 1) / n
        if Stats.PERCENT_KEYS[key] then w = w * (percentScale or Stats.DEFAULT_PERCENT_SCALE) end
        weights[key] = w
    end
    if overrides then
        for k, v in pairs(overrides) do
            if type(v) == "number" then weights[k] = v end
        end
    end
    return weights
end

function Stats.Score(derived, weights)
    local s = 0
    for k, w in pairs(weights) do s = s + (derived[k] or 0) * w end
    return s
end

-- Equip location -> inventory slot ids.
Stats.SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_HOLDABLE = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_RANGED = { 18 },
    INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 },
}

-- Shamans: cloth, leather and mail (mail from level 40, the Classic rule; Forever
-- not confirmed, flagged in About the data), shields and totems (relic slot);
-- one- and two-handed axes and maces (two-handers are baseline for Enhancement
-- in Forever), staves, fist weapons and daggers. No dual wield in Forever, so
-- off-hand weapons don't count. No swords, polearms, bows, guns or wands.
local ARMOR, WEAPON = 4, 2
Stats.MAIL_LEVEL = 40
local SHAMAN_ARMOR = { [0] = true, [1] = true, [2] = true, [3] = true, [6] = true, [9] = true }
local SHAMAN_WEAPON = { [0] = true, [1] = true, [4] = true, [5] = true, [10] = true, [13] = true, [15] = true }
Stats.TWO_HANDED = { INVTYPE_2HWEAPON = true }

function Stats.ShamanCanUse(classID, subclassID, equipLoc, level)
    if equipLoc == "INVTYPE_CLOAK" then return true end
    if equipLoc == "INVTYPE_WEAPONOFFHAND" then return false end -- dual wield is removed
    if classID == ARMOR then
        if subclassID == 3 and level and level < Stats.MAIL_LEVEL then return false end
        return SHAMAN_ARMOR[subclassID] == true
    end
    if classID == WEAPON then return SHAMAN_WEAPON[subclassID] == true end
    return false
end

-- Tooltip line provider; replaced in tests.
function Stats.LinesForLink(link)
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
        if ok and data and data.lines then
            local lines = {}
            for i, line in ipairs(data.lines) do lines[i] = line.leftText or "" end
            return lines
        end
    end
    return nil
end

local cache = {}
function Stats.RawForLink(link)
    if not link then return nil end
    if cache[link] then return cache[link] end
    local lines = Stats.LinesForLink(link)
    if not lines or #lines < 2 then return nil end -- item not cached yet
    local raw = Stats.ParseLines(lines)
    cache[link] = raw
    return raw
end

function Stats.ClearCache() cache = {} end

-- Compare an item link against what is equipped. Returns a result table or nil.
-- equippedLink(slot) is injectable for tests.
function Stats.Compare(link, spec, level, profile, percentScale, itemInfo, equippedLink)
    itemInfo = itemInfo or function(l)
        local _, _, _, equipLoc, _, classID, subclassID = C_Item.GetItemInfoInstant(l)
        return equipLoc, classID, subclassID
    end
    equippedLink = equippedLink or function(slot) return GetInventoryItemLink("player", slot) end

    local equipLoc, classID, subclassID = itemInfo(link)
    local slots = equipLoc and Stats.SLOTS[equipLoc]
    if not slots then return nil end
    local result = { equipLoc = equipLoc }
    if not Stats.ShamanCanUse(classID, subclassID, equipLoc, level) then
        result.unusable = true
        return result
    end
    local raw = Stats.RawForLink(link)
    if not raw then result.pending = true return result end

    local setName = Stats.WeightSetName(spec, level, profile)
    local weights = Stats.Weights(setName, percentScale, profile and profile.weights)
    local new = Stats.Derive(raw, spec)
    result.setName, result.weights, result.derived = setName, weights, new
    result.score = Stats.Score(new, weights)
    result.isWeapon = (classID == WEAPON)
    result.weaponDps = raw.WEAPON_DPS

    -- Pick the equipped item this would replace (weakest of a ring/trinket pair).
    local best
    for _, slot in ipairs(slots) do
        local eqLink = equippedLink(slot)
        if eqLink == link then result.isEquipped = true return result end
        local eqRaw = eqLink and Stats.RawForLink(eqLink)
        local eqScore, eqDerived = 0, Stats.Derive(eqRaw or {}, spec)
        if eqRaw then eqScore = Stats.Score(eqDerived, weights) end
        -- A two-hander replaces main hand + off hand.
        if equipLoc == "INVTYPE_2HWEAPON" and slot == 16 then
            local ohLink = equippedLink(17)
            local ohRaw = ohLink and Stats.RawForLink(ohLink)
            if ohRaw then
                local ohDerived = Stats.Derive(ohRaw, spec)
                eqScore = eqScore + Stats.Score(ohDerived, weights)
                for k, v in pairs(ohDerived) do eqDerived[k] = (eqDerived[k] or 0) + v end
            end
        end
        local cand = { slot = slot, link = eqLink, score = eqScore, derived = eqDerived, raw = eqRaw, empty = eqLink == nil }
        if not best or cand.score < best.score then best = cand end
    end
    result.against = best
    result.delta = result.score - best.score
    if best.score > 0 then result.pct = result.delta / best.score * 100 end
    if result.isWeapon and best.raw then result.dpsDelta = (raw.WEAPON_DPS or 0) - (best.raw.WEAPON_DPS or 0) end
    result.statDelta = {}
    for k in pairs(Stats.LABELS) do
        local d = (new[k] or 0) - (best.derived[k] or 0)
        if math.abs(d) > 0.001 then result.statDelta[k] = d end
    end
    if C_Item and C_Item.GetItemInfo then
        local ok, _, _, _, _, minLevel = pcall(C_Item.GetItemInfo, link)
        if ok then result.minLevel = minLevel end
    end
    return result
end

Stats.UPGRADE_MIN_PCT = 1 -- ignore rounding-level gains

-- Is this a real upgrade the player can put on right now?
function Stats.IsUpgrade(res, level)
    if not res or res.unusable or res.pending or res.isEquipped or not res.delta then return false end
    if res.minLevel and level and res.minLevel > level then return false end
    if res.against and res.against.empty then return res.score > 0 end
    if res.delta <= 0.05 then return false end
    return res.pct == nil or res.pct >= Stats.UPGRADE_MIN_PCT
end

-- What a stat change means in practice, from documented conversions only.
function Stats.Effect(key, d)
    local up = d > 0
    local E = {
        WEAPON_DPS = { "harder-hitting swings, Stormstrike and Windfury", "weaker swings" },
        STR = { "more attack power", "less attack power" },
        AP = { "harder melee hits", "weaker melee hits" },
        AGI = { "a little crit, dodge and armor", "less crit, dodge and armor" },
        HIT = { "fewer misses", "more misses" },
        CRIT = { "more melee crits", "fewer melee crits" },
        EXPERTISE = { "fewer dodged and parried attacks", "more dodged and parried attacks" },
        DAMAGE = { "harder-hitting Lightning Bolts, shocks and Chain Lightning", "weaker spells" },
        HEALING = { "bigger heals", "smaller heals" },
        SPELL_HIT = { "fewer resisted spells", "more resisted spells" },
        SPELL_CRIT = { "more spell crits", "fewer spell crits" },
        INT = { "more mana and spell crit", "less mana and spell crit" },
        SPI = { "faster mana regen out of the five-second rule", "slower mana regen" },
        MP5 = { "mana every 5 sec, even while casting", "less mana while casting" },
        STA = { "more health", "less health" },
        DEFENSE = { "fewer crits taken (tanking)", "more crits taken" },
        ARMOR = { "less physical damage taken", "more physical damage taken" },
        BLOCK = { "more blocks", "fewer blocks" },
        BLOCK_VALUE = { "bigger blocks", "smaller blocks" },
        DODGE = { "more dodges", "fewer dodges" },
        PARRY = { "more parries", "fewer parries" },
    }
    local e = E[key]
    if not e then return nil end
    if key == "MP5" then return ("%s%d %s"):format(up and "+" or "-", math.abs(d), e[up and 1 or 2]) end
    return e[up and 1 or 2]
end
