-- Shaman state: totems you have down, your weapon imbue and shield, and which
-- ones the research recommends right now. Read-only advice. Every read can come
-- back nil ("can't tell", e.g. a secret value in combat); callers show "hidden"
-- instead of guessing.
--
-- Blizzard's own totem tracking UI (active totems + time left, right-click to
-- dismiss) and the Call of the Elements totem bar stay the way to see and drop
-- totems. Nothing here replaces or covers them: we only say which totem fits and
-- nudge when one is missing or has run out.
local _, ns = ...

local Shaman = {}
ns.Shaman = Shaman

Shaman.ELEMENTS = { "Earth", "Fire", "Water", "Air" }
-- Totem slots as Blizzard numbers them (FIRE_TOTEM_SLOT = 1, EARTH_TOTEM_SLOT = 2,
-- WATER_TOTEM_SLOT = 3, AIR_TOTEM_SLOT = 4). The globals win when the client has them.
Shaman.SLOT = {
    Fire = FIRE_TOTEM_SLOT or 1, Earth = EARTH_TOTEM_SLOT or 2,
    Water = WATER_TOTEM_SLOT or 3, Air = AIR_TOTEM_SLOT or 4,
}
Shaman.ELEMENT_ICON = {
    Earth = "Interface\\Icons\\Spell_Nature_EarthBindTotem",
    Fire = "Interface\\Icons\\Spell_Fire_SearingTotem",
    Water = "Interface\\Icons\\Spell_Nature_ManaRegenTotem",
    Air = "Interface\\Icons\\Spell_Nature_Windfury",
}
-- Weapon imbues (Rockbiter, Flametongue, Frostbrand, Windfury). Main hand only:
-- dual wield is removed in Forever, Enhancement is a two-hander spec.
Shaman.IMBUES = { "Windfury Weapon", "Flametongue Weapon", "Rockbiter Weapon", "Frostbrand Weapon" }
Shaman.SHIELDS = { "Lightning Shield", "Water Shield" }
-- Addon assumption (shown in About the data): below this mana % a Shaman who knows
-- Water Shield is nudged toward it outside Restoration.
Shaman.WATER_SHIELD_MANA = 35
Shaman.MAELSTROM = "Maelstrom Weapon"

local function knows(name) return ns.Progress.Knows(name) end
local function secret(v) return ns.Auras.IsSecret(v) end
local function localName(name)
    return ns.Auras.SpellName(ns.Rotation.SpellId(name)) or name
end
Shaman.LocalName = localName

-- ---------------------------------------------------------------------------
-- Totems

-- Your totem in one element: { name, left } | false (none down) | nil (can't tell).
function Shaman.Totem(element, now)
    local slot = Shaman.SLOT[element]
    if not slot or not GetTotemInfo then return nil end
    local ok, have, name, start, duration = pcall(GetTotemInfo, slot)
    if not ok or secret(have) or secret(name) then return nil end
    if not have or not name or name == "" then return false end
    local left
    if start and duration and not secret(start) and not secret(duration) and duration > 0 then
        left = math.max(0, start + duration - (now or GetTime()))
    end
    return { name = name, left = left }
end

function Shaman.KnowsAnyTotem(known)
    known = known or knows
    for _, t in ipairs(ns.Data.Totems or {}) do
        if known(t.name) then return true end
    end
    return false
end

function Shaman.TotemRecord(name)
    for _, t in ipairs(ns.Data.Totems or {}) do
        if t.name == name then return t end
    end
    return nil
end

-- Known totems of one element.
function Shaman.KnownTotems(element, known)
    known = known or knows
    local out = {}
    for _, t in ipairs(ns.Data.Totems or {}) do
        if t.element == element and known(t.name) then table.insert(out, t.name) end
    end
    return out
end

-- Elements you have unlocked: a totem of that element is known (the class quests
-- give the element totems at 4/10/20/30).
function Shaman.UnlockedElements(known)
    local out = {}
    for _, e in ipairs(Shaman.ELEMENTS) do
        if #Shaman.KnownTotems(e, known) > 0 then table.insert(out, e) end
    end
    return out
end

-- Recommended totem per element for spec + context, from the research's
-- totem_advice, limited to totems you know. { Earth = name|nil, ... }, notes.
function Shaman.RecommendedTotems(spec, context, known)
    known = known or knows
    local adv = ns.Data.TotemAdvice or {}
    local bySpec = spec and adv[spec]
    local set = bySpec and (bySpec[context or "solo"] or bySpec.solo) or {}
    local out = {}
    for _, e in ipairs(Shaman.ELEMENTS) do
        local want = set[e]
        if type(want) == "table" then
            for _, n in ipairs(want) do if known(n) then out[e] = n break end end
        elseif type(want) == "string" and known(want) then
            out[e] = want
        end
    end
    return out, set.note or adv.notes
end

-- Your active totem set: PvE (the guide's pick for spec + Solo/Dungeon/Raid) or,
-- in PvP mode, the PvP set (the research's PvP picks). Your saved choices per
-- element (Settings > Shaman bar > Totem sets) win when you know that totem.
-- Returns { Earth = name|nil, ... }, setKey ("pve"|"pvp"), saved (element -> true).
function Shaman.ActiveTotemSet(spec, context, known, profile)
    known = known or knows
    profile = profile or ns.DB.Profile()
    local setKey = context == "pvp" and "pvp" or "pve"
    local base
    if setKey == "pvp" then
        -- PvP guide picks (Earthbind, Grounding) over your Solo picks for the rest.
        base = Shaman.RecommendedTotems(spec, "solo", known)
        local def = ns.PvP.DefaultSet()
        for _, e in ipairs(Shaman.ELEMENTS) do
            local want = def[e]
            if type(want) == "table" then
                for _, n in ipairs(want) do if known(n) then base[e] = n break end end
            elseif type(want) == "string" and known(want) then
                base[e] = want
            end
        end
    else
        base = Shaman.RecommendedTotems(spec, context, known)
    end
    local saved = profile and profile.totemSets and profile.totemSets[setKey] or {}
    local out, mine = {}, {}
    for _, e in ipairs(Shaman.ELEMENTS) do
        local pick = saved[e]
        if pick and known(pick) then
            out[e], mine[e] = pick, true
        else
            out[e] = base[e]
        end
    end
    return out, setKey, mine
end

-- Save one element of a totem set (nil = back to the guide pick).
function Shaman.SetTotemPick(setKey, element, name, profile)
    profile = profile or ns.DB.Profile()
    profile.totemSets = profile.totemSets or { pve = {}, pvp = {} }
    profile.totemSets[setKey] = profile.totemSets[setKey] or {}
    profile.totemSets[setKey][element] = name
    ns.Fire("TOTEM_SET_CHANGED", setKey)
end

-- Totem nudges: elements with a recommended totem that's not down, or has
-- under `soon` seconds left. Only in combat or with a target, since dropping
-- totems with nothing to fight wastes mana (addon choice).
-- Returns list of { element, want, have, why } and whether anything was unreadable.
function Shaman.TotemNudges(spec, context, known, now, soon)
    local rec = Shaman.ActiveTotemSet(spec, context, known)
    local out, hidden = {}, false
    for _, e in ipairs(Shaman.ELEMENTS) do
        local want = rec[e]
        if want then
            local have = Shaman.Totem(e, now)
            if have == nil then
                hidden = true
            elseif have == false then
                table.insert(out, { element = e, want = want, why = "none down" })
            elseif have.left and have.left < (soon or 10) then
                table.insert(out, { element = e, want = want, have = have.name, why = "running out" })
            end
        end
    end
    return out, hidden
end

-- Fire Nova erupts at your current Fire totem (Fire Nova Totem is removed).
-- true = known and a Fire totem is down; false = not; nil = can't tell.
function Shaman.FireNovaReady(known)
    known = known or knows
    if not known("Fire Nova") then return false end
    local fire = Shaman.Totem("Fire")
    if fire == nil then return nil end
    return fire and true or false
end

-- ---------------------------------------------------------------------------
-- Weapon imbue

-- Which imbue is on the main hand, from its tooltip's green line ("Windfury 3
-- (60 min)" style). Returns imbue spell name or nil.
local IMBUE_WORD = { ["Windfury Weapon"] = "Windfury", ["Flametongue Weapon"] = "Flametongue",
    ["Rockbiter Weapon"] = "Rockbiter", ["Frostbrand Weapon"] = "Frostbrand" }
Shaman.IMBUE_WORD = IMBUE_WORD
function Shaman.ImbueFromLines(lines)
    for _, text in ipairs(lines or {}) do
        if type(text) == "string" and not secret(text) then
            for spell, word in pairs(IMBUE_WORD) do
                if text:find("^" .. word) then return spell end
            end
        end
    end
    return nil
end

local function mainHandLines()
    if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then return nil end
    local ok, info = pcall(C_TooltipInfo.GetInventoryItem, "player", 16)
    if not ok or type(info) ~= "table" or secret(info) then return nil end
    local out = {}
    for _, line in ipairs(info.lines or {}) do
        if line.leftText then table.insert(out, line.leftText) end
    end
    return out
end

-- Your main-hand imbue: { name = spell|nil (an enchant we can't name), left = seconds|nil }
-- | false (none) | nil (can't tell). Forever lets imbues sit next to stones and
-- oils; the tooltip names the imbue, GetWeaponEnchantInfo only says "something".
function Shaman.Imbue()
    local name = Shaman.ImbueFromLines(mainHandLines())
    local has, expires
    if GetWeaponEnchantInfo then
        local ok, h, e = pcall(GetWeaponEnchantInfo)
        if ok and not secret(h) then has, expires = h, (not secret(e)) and e or nil end
    end
    if name then
        return { name = name, left = (has and expires) and expires / 1000 or nil }
    end
    if has == nil then return nil end
    if has then return { name = nil, left = expires and expires / 1000 or nil } end
    return false
end

-- Recommended imbue. ctx = { spec, context, level }. Research imbue_advice rows
-- are in preference order; stale (pre-Nov 10 hotfix) rows are skipped.
function Shaman.RecommendedImbue(ctx, known)
    known = known or knows
    ctx = ctx or {}
    local level = ctx.level or 1
    local context = ctx.context or "solo"
    for _, a in ipairs(ns.Data.ImbueAdvice or {}) do
        local specOk = (a.spec == nil or a.spec == "any" or a.spec == ctx.spec)
        local ctxOk = (a.context == nil or a.context == context
            or (a.context == "leveling" and context == "solo" and level < 60)
            or (a.context == "solo" and context == "leveling"))
        local lvlOk = (not a.before_level or level < a.before_level) and (not a.from_level or level >= a.from_level)
        if specOk and ctxOk and lvlOk and not a.stale and known(a.imbue) then
            return a.imbue, a.why, a
        end
    end
    -- No sourced row matched: the best one you know, Windfury first (Blizzard's
    -- Nov 10/11 intent for Enhancement), then Flametongue, Rockbiter, Frostbrand.
    for _, n in ipairs(Shaman.IMBUES) do
        if known(n) then return n, "the best imbue you know (no guide row for this case)" end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Shields

-- Your shield: { name, charges|nil, left|nil } | false | nil (can't tell).
function Shaman.Shield()
    local unknown = false
    for _, n in ipairs(Shaman.SHIELDS) do
        local data = ns.Auras.FindMine("player", localName(n), "HELPFUL")
        if data then
            local c = data.applications or data.charges
            if c ~= nil and (secret(c) or c == 0) then c = nil end
            return { name = n, charges = c, left = ns.Auras.TimeLeft(data) }
        end
        if data == nil then unknown = true end
    end
    if unknown then return nil end
    return false
end

-- Lightning Shield by default; Water Shield for Restoration, and for anyone who
-- knows it when mana runs low (Icy Veins: useful for Elemental/Enhancement mana).
function Shaman.RecommendedShield(ctx, known)
    known = known or knows
    ctx = ctx or {}
    if known("Water Shield") then
        if ctx.spec == "Restoration" then return "Water Shield", "Restoration: mana back when you're hit or crit-heal" end
        if ctx.manaPct and ctx.manaPct < Shaman.WATER_SHIELD_MANA then return "Water Shield", "low on mana" end
    end
    if known("Lightning Shield") then return "Lightning Shield", nil end
    return nil
end

-- ---------------------------------------------------------------------------
-- Melee, weapon, Maelstrom

function Shaman.WeaponSpeed()
    if not UnitAttackSpeed then return nil end
    local ok, mh = pcall(UnitAttackSpeed, "player")
    if ok and type(mh) == "number" and not secret(mh) then return mh end
    return nil
end

-- Target within melee reach? true/false/nil.
function Shaman.InMelee()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return false end
    if knows("Stormstrike") and C_Spell and C_Spell.IsSpellInRange then
        local ok, r = pcall(C_Spell.IsSpellInRange, ns.Rotation.SpellId("Stormstrike") or "Stormstrike", "target")
        if ok and r ~= nil and not secret(r) then return r and true or false end
    end
    if CheckInteractDistance then
        local ok, r = pcall(CheckInteractDistance, "target", 3)
        if ok and not secret(r) then return r and true or false end
    end
    return nil
end

-- Maelstrom Weapon stacks (0-5) from your own aura. nil = hidden/unknown.
function Shaman.MaelstromStacks()
    if not knows("Maelstrom Weapon") then return nil end
    local data = ns.Auras.Find("player", localName(Shaman.MAELSTROM), "HELPFUL")
    if data == nil then return nil end
    if data == false then return 0 end
    local c = data.applications or data.charges or data.count
    if c == nil or secret(c) then return nil end
    return math.max(1, c)
end

-- ---------------------------------------------------------------------------
-- Stoneform (Dwarf racial): immune to Poisons, Bleeds and Diseases (research:
-- Icy Veins race guide). Nudge only from a positive read of your own debuffs.

Shaman.STONEFORM = "Stoneform"
Shaman.STONEFORM_TYPES = { Poison = true, Disease = true, Bleed = true }

-- Debuff types on you that Stoneform answers. Returns a list of type names
-- ({} = none), or nil when your debuffs can't be read (secret, no API): then
-- the addon says nothing. Bleeds count only when the client labels a debuff
-- "Bleed"; nothing is inferred from names or icons.
function Shaman.StoneformTypes()
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return nil end
    local found, seen = {}, {}
    for i = 1, 40 do
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HARMFUL")
        if not ok or secret(data) then return nil end
        if not data then break end
        local kind = data.dispelName
        if secret(kind) then return nil end
        if kind and Shaman.STONEFORM_TYPES[kind] and not seen[kind] then
            seen[kind] = true
            table.insert(found, kind)
        end
    end
    return found
end

-- Should a Dwarf press Stoneform now? true + types | false | nil (can't tell / not a Dwarf).
function Shaman.StoneformNudge(race, known)
    known = known or knows
    if race ~= "Dwarf" or not known(Shaman.STONEFORM) then return false end
    local types = Shaman.StoneformTypes()
    if types == nil then return nil end
    if #types == 0 then return false end
    return true, types
end

-- Everything the bar, Home and reminders want to know, in one table.
function Shaman.State()
    local spec = ns.DB.ActiveSpec()
    local profile = ns.DB.Profile()
    local context = ns.DB.Context()
    local level = UnitLevel("player") or 1
    local mana = ns.Auras.PowerPct("player")
    -- World PvP is mostly while questing: imbue advice follows Solo there.
    local imbueCtx = context == "pvp" and "solo" or context
    local recImbue, imbueWhy = Shaman.RecommendedImbue({ spec = spec, context = imbueCtx, level = level })
    local recShield, shieldWhy = Shaman.RecommendedShield({ spec = spec, manaPct = mana })
    return {
        spec = spec, context = context, level = level, manaPct = mana,
        inGroup = IsInGroup and IsInGroup() or false,
        imbue = Shaman.Imbue(), recImbue = recImbue, imbueWhy = imbueWhy,
        shield = Shaman.Shield(), recShield = recShield, shieldWhy = shieldWhy,
        totems = Shaman.ActiveTotemSet(spec, context),
        pvp = context == "pvp",
        fireNova = Shaman.FireNovaReady(),
        inMelee = Shaman.InMelee(),
    }
end
