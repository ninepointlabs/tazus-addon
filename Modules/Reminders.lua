-- Out-of-combat reminders: a weapon imbue, your shield, totems down when there's
-- something to fight, the element class quests (Call of Earth at 4, Fire at 10,
-- Water at 20, Air at 30), Ghost Wolf after 20, trainer visits, and reagents
-- (Fish Oil for Water Walking, Ankh for Reincarnation) only when the research
-- confirms them for Forever.
local _, ns = ...

local Reminders = {}
ns.Reminders = Reminders

local function itemCount(id)
    if C_Item and C_Item.GetItemCount then
        local ok, n = pcall(C_Item.GetItemCount, id)
        if ok then return n or 0 end
    end
    return 0
end
Reminders.ItemCount = itemCount

-- The element class quest that's open for this character at this level:
-- the earliest one at or below your level that isn't done.
function Reminders.ElementQuest(level, race, faction)
    for _, q in ipairs(ns.Progress.ClassQuests(race, faction)) do
        if q.type == "class" and q.level <= (level or 1) and (q.missing or not ns.Progress.ClassQuestDone(q)) then
            return q
        end
    end
    return nil
end

-- Reagents the research confirms (confirmed = true, with an item id) for spells you know.
function Reminders.Reagents(knows)
    knows = knows or function(n) return ns.Progress.Knows(n) end
    local out = {}
    for _, r in ipairs(ns.Data.Reagents or {}) do
        if r.confirmed and r.item_id and r.for_spell and knows(r.for_spell) then
            table.insert(out, { reagent = r, count = itemCount(r.item_id) })
        end
    end
    return out
end

-- Returns { {id, label, ok, detail, icon} ... } for the active spec.
function Reminders.Evaluate()
    local cfg = ns.db.char.reminders
    local S = ns.Shaman
    local st = S.State()
    local out = {}
    local function add(id, enabled, applies, label, ok, detail, icon)
        if enabled and applies then
            table.insert(out, { id = id, label = label, ok = ok, detail = detail, icon = icon })
        end
    end

    local im = st.imbue
    add("imbue", cfg.imbue, st.recImbue ~= nil, "Weapon imbue", im ~= false and not (im and im.left and im.left < 60),
        im == nil and "can't read your weapon right now"
            or ("Press the imbue button on the Shaman bar: " .. tostring(st.recImbue) .. (st.imbueWhy and (" (" .. st.imbueWhy .. ")") or "") .. ". Lasts 60 minutes."),
        ns.Rotation.Icon(st.recImbue or "Rockbiter Weapon"))

    add("shield", cfg.shield, st.recShield ~= nil, st.recShield or "Shield", st.shield ~= false,
        st.shield == nil and "can't read auras right now" or ("Cast " .. tostring(st.recShield) .. (st.shieldWhy and (" (" .. st.shieldWhy .. ")") or "") .. "."),
        ns.Rotation.Icon(st.recShield or "Lightning Shield"))

    -- Totems: only with an enemy targeted (dropping them with nothing to fight wastes mana).
    if ns.Hints and ns.Hints.TotemsMatter and ns.Hints.TotemsMatter() then
        local nudges, hidden = S.TotemNudges(st.spec, st.context)
        local names = {}
        for _, n in ipairs(nudges) do table.insert(names, n.want) end
        add("totems", cfg.totems, next(st.totems) ~= nil and not hidden, "Totems", #nudges == 0,
            #names > 0 and ("Drop " .. table.concat(names, ", ") .. " (or use Call of the Elements).") or "",
            ns.Rotation.Icon(nudges[1] and nudges[1].want or "Stoneskin Totem"))
    end

    local level = UnitLevel("player") or 1
    local q = Reminders.ElementQuest(level, ns.Progress.PlayerRace(), UnitFactionGroup("player"))
    add("classQuest", cfg.classQuests, q ~= nil, "Class quest: " .. (q and q.name or ""), false,
        q and ("Level " .. q.level .. (q.reward and (": rewards " .. q.reward) or "") .. (q.zone and (" · " .. q.zone) or "")) or "",
        ns.Shaman.ELEMENT_ICON.Earth)

    add("ghostWolf", cfg.ghostWolf, level >= 20 and not ns.Progress.Knows("Ghost Wolf") and ns.Rotation.SpellRecord("Ghost Wolf") ~= nil,
        "Ghost Wolf", false, "Train Ghost Wolf at your class trainer: faster travel between pulls.", ns.Rotation.Icon("Ghost Wolf"))

    for _, r in ipairs(Reminders.Reagents()) do
        add("reagent:" .. r.reagent.name, cfg.reagents, true, r.reagent.name, r.count > 0,
            "You have none (for " .. r.reagent.for_spell .. ").", "Interface\\Icons\\INV_Misc_Bag_10")
    end
    return out
end

-- Consumables recommended for the player's bracket.
function Reminders.Consumables(level)
    local out = {}
    for _, c in ipairs(ns.Data.Consumables or {}) do
        if c.type == "consumable" then
            local lvl = tonumber((c.bracket or ""):match("(%d+)"))
            table.insert(out, { item = c, count = c.item_id and itemCount(c.item_id) or 0, current = lvl and level >= lvl - 8 and level <= lvl + 9 })
        end
    end
    return out
end

function Reminders.Missing()
    if not ns.db.char.reminders.enabled or InCombatLockdown() then return {} end
    local miss = {}
    for _, r in ipairs(Reminders.Evaluate()) do
        if not r.ok then table.insert(miss, r) end
    end
    return miss
end
