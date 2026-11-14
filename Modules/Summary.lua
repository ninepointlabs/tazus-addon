-- Post-fight summary: what you cast and mana tips.
-- Uses UNIT_SPELLCAST_SUCCEEDED for the player only (no combat log). If the
-- client hides spell ids as secret values in combat, those casts are counted as
-- "hidden" and the summary says so instead of guessing.
local _, ns = ...

local Summary = {}
ns.Summary = Summary

local fight

function Summary.Start(now, manaPct)
    fight = { start = now, manaStart = manaPct, casts = {}, order = {}, hidden = 0 }
end

function Summary.OnCast(spellID, name)
    if not fight then return end
    if spellID == nil or ns.Auras.IsSecret(spellID) then
        fight.hidden = fight.hidden + 1
        return
    end
    name = name or ns.Auras.SpellName(spellID) or tostring(spellID)
    if not fight.casts[name] then
        fight.casts[name] = 0
        table.insert(fight.order, name)
    end
    fight.casts[name] = fight.casts[name] + 1
end

-- Rule-based tips. Each tip references a mechanic in content/learn.json.
-- knows(name) is injectable for tests.
function Summary.Tips(f, spec, context, knows)
    knows = knows or function(name) return ns.Progress.Knows(name) end
    local tips = {}
    local dur = f.duration or 0
    local used = f.manaStart and f.manaEnd and (f.manaStart - f.manaEnd) or nil
    local c = f.casts
    local function n(name) return c[name] or 0 end
    if spec == "Enhancement" and dur >= 12 and n("Stormstrike") == 0 and knows("Stormstrike") then
        table.insert(tips, "No Stormstrike this fight. It's on an 8-second cooldown since the Nov 10/11 hotfix: press it every time it's ready.")
    end
    if spec == "Elemental" and dur >= 15 and n("Flame Shock") == 0 and knows("Flame Shock") then
        table.insert(tips, "No Flame Shock. On anything that lives a while, start with it, then Lightning Bolt.")
    end
    local shields = n("Lightning Shield") + n("Water Shield")
    if dur > 0 and dur < 30 and shields >= 3 then
        table.insert(tips, "Shield cast " .. shields .. " times in a short fight. Refresh it when the orbs are gone, not before.")
    end
    if f.manaEnd and f.manaEnd < 20 then
        if spec == "Restoration" then
            table.insert(tips, "Mana ended under 20%. Keep Water Shield up, drop Mana Tide Totem when you have it, and use lower Healing Wave ranks on light damage.")
        elseif knows("Water Shield") then
            table.insert(tips, "Mana ended under 20%. Swap to Water Shield for a pull or two, and melee the last bit instead of casting.")
        else
            table.insert(tips, "Mana ended under 20%. Melee the last bit instead of casting, and let the five-second rule work between pulls.")
        end
    elseif spec == "Enhancement" and f.manaEnd and f.manaEnd > 70 and context == "solo" and knows("Healing Wave") then
        table.insert(tips, "Lots of mana left: heal yourself up with Healing Wave between pulls instead of eating.")
    end
    if used and used > 0 and dur > 0 and #tips == 0 then
        table.insert(tips, ("Mana used: %.0f%% over %ds. Nice and tidy."):format(used, dur))
    end
    if f.hidden > 0 then
        table.insert(tips, ("%d cast(s) were hidden by the client's addon restrictions and aren't counted."):format(f.hidden))
    end
    return tips
end

function Summary.Finish(now, manaPct)
    if not fight then return nil end
    local f = fight
    fight = nil
    f.duration = math.floor((now - f.start) + 0.5)
    f.manaEnd = manaPct
    local total = 0
    for _, v in pairs(f.casts) do total = total + v end
    if f.duration < 4 or (total == 0 and f.hidden == 0) then return nil end
    local spec = ns.DB.ActiveSpec()
    f.tips = Summary.Tips(f, spec, ns.DB.Profile().rotationContext, nil)
    Summary.last = f
    return f
end

function Summary.Text(f)
    local parts = {}
    table.sort(f.order, function(a, b) return f.casts[a] > f.casts[b] end)
    for _, name in ipairs(f.order) do table.insert(parts, name .. " x" .. f.casts[name]) end
    return table.concat(parts, ", ")
end
