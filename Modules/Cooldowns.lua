-- Rotation > Cooldowns: your own procs and cooldowns (Maelstrom Weapon stacks,
-- Stormstrike, Fire Nova, Lightning Mastery, Rage of the Farseer, Nature's
-- Swiftness, Mana Tide Totem, Berserking) where Forever lets addons read them.
--
-- Only YOUR spells: cooldowns come from C_Spell.GetSpellCooldown for spells you
-- know and procs from your own auras. Nothing reads enemy health, casts or
-- cooldowns (Forever hides them from addons). Cooldown widgets take secret
-- start/duration values directly, so a swirl still works when the numbers
-- themselves are hidden; text then says "hidden". Blizzard's Cooldown Manager
-- (/cdm) can track the same things, including Maelstrom Weapon since Nov 10.
local _, ns = ...

local CD = {}
ns.Cooldowns = CD

-- Names only; every number shown comes from the game. Cooldown lengths are
-- never hard-coded here (Totemic Call's is disputed, see About the data).
CD.SPELLS = { "Stormstrike", "Fire Nova", "Earth Shock", "Lightning Mastery", "Rage of the Farseer", "Nature's Swiftness",
    "Mana Tide Totem", "Riptide", "Chain Lightning", "Totemic Call", "Reincarnation", "Berserking", "Rapid Regeneration" }
-- Procs/buffs on you worth showing: { aura, maxStacks? }.
CD.PROCS = {
    { aura = "Maelstrom Weapon", max = 5 },
    { aura = "Clearcasting" },
    { aura = "Flurry" },
    { aura = "Lightning Mastery" },
    { aura = "Rage of the Farseer" },
    { aura = "Nature's Swiftness" },
}

-- Known cooldowns: { spell, left (sec|nil hidden), start, duration, readable }.
function CD.List(knows)
    knows = knows or function(n) return ns.Progress.Knows(n) end
    local out = {}
    for _, name in ipairs(CD.SPELLS) do
        if knows(name) then
            local id = ns.Rotation.SpellId(name) or name
            local start, duration, readable = ns.Auras.CooldownRaw(id)
            table.insert(out, { spell = name, left = ns.Auras.CooldownLeft(id), start = start, duration = duration, readable = readable })
        end
    end
    return out
end

-- Your procs: { aura, up = true|false|nil, stacks = n|nil, left = sec|nil, max }.
-- A proc counts as relevant once its talent/spell is known (Clearcasting via
-- Elemental Focus, Flurry via the Flurry talent).
CD.SOURCE = { Clearcasting = "Elemental Focus" }
function CD.Procs(knows, find)
    knows = knows or function(n) return ns.Progress.Knows(n) end
    find = find or function(n) return ns.Auras.Find("player", ns.Shaman.LocalName(n), "HELPFUL") end
    local out = {}
    for _, p in ipairs(CD.PROCS) do
        if knows(CD.SOURCE[p.aura] or p.aura) then
            local data = find(p.aura)
            local e = { aura = p.aura, max = p.max }
            if data == nil then
                e.up = nil
            elseif data == false then
                e.up, e.stacks = false, 0
            else
                e.up = true
                local c = data.applications or data.charges or data.count
                if c ~= nil and not ns.Auras.IsSecret(c) then e.stacks = math.max(1, c) end
                e.left = ns.Auras.TimeLeft(data)
            end
            table.insert(out, e)
        end
    end
    return out
end

-- One short line for the HUD: Maelstrom stacks (Enhancement) or nothing.
function CD.HudLine(knows, find)
    for _, p in ipairs(CD.Procs(knows, find)) do
        if p.aura == "Maelstrom Weapon" then
            if p.up == nil then return "Maelstrom: hidden" end
            local n = p.stacks or 0
            return ("Maelstrom %d/%d%s"):format(n, p.max or 5, n >= (p.max or 5) and "  instant Lightning Bolt" or "")
        end
    end
    return nil
end

function CD.OnCast() end -- kept for the cast event hook; nothing to track yet
