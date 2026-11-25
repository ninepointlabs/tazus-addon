-- PvP mode: per-profile switch for world PvP. It swaps the rotation list to the
-- World PvP one, the Totems hint to your PvP totem set, and adds PvP tips.
--
-- Ruleset detection: no documented Lua API names the ruleset. On Forever,
-- GetRealmName() returns the realm's internal id, and those ids end in the
-- ruleset: "CAMWOWUS2Realm1PvE" (Normal, Tazu's realm) and
-- "CAMWOWUS2Realm6PvP" (a PvP-ruleset realm), as recorded by StoryTracker's
-- GetRealmName() keys on TUF (research/parts/core.json pvp.realm_detection). So a realm
-- id ending in "PvP" counts as the PvP ruleset; anything else is "can't tell"
-- and PvP mode stays a manual switch. Detection only *suggests* PvP mode (once
-- per realm); it never turns it on by itself.
local _, ns = ...

local PvP = {}
ns.PvP = PvP

-- "pvp" | "pve" | nil (can't tell). Pure on its input for tests.
function PvP.RulesetFromRealm(realm)
    if type(realm) ~= "string" or ns.Auras.IsSecret(realm) or realm == "" then return nil end
    local compact = realm:gsub("%s+", "")
    if compact:find("PvP$") then return "pvp" end
    if compact:find("PvE$") then return "pve" end
    return nil
end

function PvP.Realm()
    if not GetRealmName then return nil end
    local ok, r = pcall(GetRealmName)
    if not ok or ns.Auras.IsSecret(r) then return nil end
    return r
end

function PvP.Ruleset()
    return PvP.RulesetFromRealm(PvP.Realm())
end

function PvP.On()
    return ns.DB.PvP()
end

function PvP.Set(on)
    if ns.DB.SetPvP(on) then
        ns.Print("PvP mode " .. (on and "on" or "off") .. " for profile " .. ns.DB.ActiveId() .. ".")
    end
end

function PvP.Toggle()
    PvP.Set(not PvP.On())
end

-- On login: on a PvP-ruleset realm with PvP mode off, suggest it once per realm.
-- Returns true when it suggested.
function PvP.MaybeSuggest()
    local realm = PvP.Realm()
    if PvP.RulesetFromRealm(realm) ~= "pvp" or PvP.On() then return false end
    if ns.db.char.pvpSuggested == realm then return false end
    ns.db.char.pvpSuggested = realm
    ns.Print("You're on a PvP-ruleset realm. Turn on PvP mode for the World PvP rotation, your PvP totem set and PvP tips: /tazu pvp (or Settings > General).")
    ns.Fire("TOAST", "PvP realm", "Turn on PvP mode? /tazu pvp", "Interface\\Icons\\Spell_Nature_GroundingTotem")
    return true
end

-- ---------------------------------------------------------------------------
-- Data helpers (Data/PvP.lua, generated from research/data.json "pvp").

function PvP.Data()
    return ns.Data.PvP or {}
end

-- The PvP totem set's guide picks per element (sourced uses; see research).
function PvP.DefaultSet()
    return PvP.Data().totem_set or {}
end

-- Situational totem picks: { name, element, pvp_use, vs = "casters"|"fear"|"kiting"|... }.
function PvP.TotemPicks(known)
    known = known or ns.Progress.Knows
    local out = {}
    for _, t in ipairs(PvP.Data().totem_picks or {}) do
        if known(t.name) then table.insert(out, t) end
    end
    return out
end

-- Picks that fit an enemy player's class (classFile, e.g. "WARLOCK"), from the
-- research's per-pick class lists. nil class (unreadable) -> {}.
function PvP.PicksVs(classFile, known)
    if not classFile or ns.Auras.IsSecret(classFile) then return {} end
    local out = {}
    for _, t in ipairs(PvP.TotemPicks(known)) do
        for _, c in ipairs(t.vs_classes or {}) do
            if c == classFile then table.insert(out, t) break end
        end
    end
    return out
end

-- Your target, if it's an enemy player whose class the client will tell us.
function PvP.EnemyPlayerClass()
    if not UnitExists("target") or not UnitIsPlayer or not UnitCanAttack("player", "target") then return nil end
    local okP, isPlayer = pcall(UnitIsPlayer, "target")
    if not okP or ns.Auras.IsSecret(isPlayer) or not isPlayer then return nil end
    local ok, _, classFile = pcall(UnitClass, "target")
    if not ok or ns.Auras.IsSecret(classFile) then return nil end
    return classFile
end

function PvP.Tips(race, faction)
    local out = {}
    for _, t in ipairs(PvP.Data().tips or {}) do
        local ok = (not t.faction or not faction or t.faction == faction)
            and (not t.races or not race or ns.Progress.RaceMatches(t.races, race))
        if ok then table.insert(out, t) end
    end
    return out
end
