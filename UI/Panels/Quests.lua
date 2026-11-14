-- Leveling › Class quests
local _, ns = ...
local UI = ns.UI

UI.LevelingSections = UI.LevelingSections or {}

UI.LevelingSections["Class quests"] = function(L, c)
    L:Text(UI.Hex(UI.C.dim) .. "The totem quests for " .. (c.race or "your race") .. " Shamans: Call of Earth at 4, Call of Fire at 10, Call of Water at 20 (no rush), Call of Air at 30, then The Tempest's Weapons (with a group, or later). Other races' and the other faction's versions stay hidden.|r", { size = 12 })
    local list = ns.Progress.ClassQuests(c.race, c.faction)
    if #list == 0 then L:Text("No class quests in the research for you yet.") end
    for _, q in ipairs(list) do
        local done = ns.Progress.IsQuestDone(q.quest_id)
        local chip
        if done then chip = { text = "Done", kind = "good" }
        elseif q.missing and c.level >= (q.level or 0) then chip = { text = "Ready · ID unknown", kind = "warn" }
        elseif q.missing then chip = { text = "Level " .. (q.level or "?") .. " · ID unknown", kind = "neutral" }
        elseif c.level >= (q.level or 0) then chip = { text = "Ready", kind = "info" }
        else chip = { text = "Level " .. (q.level or "?"), kind = "neutral" } end
        local sub = {}
        if q.start_npc then table.insert(sub, "From " .. q.start_npc) end
        if q.zone then table.insert(sub, q.zone) end
        if q.reward_spell then table.insert(sub, "Teaches " .. q.reward_spell) end
        if q.reward then table.insert(sub, "Reward: " .. q.reward) end
        if q.unconfirmed then table.insert(sub, UI.FLAG_ICON .. " " .. UI.Hex(UI.C.warn) .. (q.flag or "unconfirmed") .. "|r") end
        if q.notes then table.insert(sub, q.notes) end
        if q.coords then table.insert(sub, "Path starts at " .. tostring(q.coords)) end
        if q.missing then L:Note(q.name .. ": quest ID not captured in the research, so completion can't be checked.") end
        L:Row({
            chip = chip, title = q.name, sub = table.concat(sub, " · "),
            right = "level " .. (q.level or "?") .. (q.quest_id and (" · #" .. q.quest_id) or ""),
            onEnter = q.reward_item_id and function(s)
                GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(q.reward_item_id)
                GameTooltip:Show()
            end or nil,
        })
        if q.steps and #q.steps > 0 and not done and c.level >= (q.level or 0) - 2 then
            for i, step in ipairs(q.steps) do L:Text(UI.Hex(UI.C.dim) .. i .. ".|r " .. step, { size = 12, indent = 30 }) end
        end
        L:Source(q)
    end
    local gap = false
    for _, g in ipairs(ns.Data.Gaps or {}) do if (g.gap or ""):find("post%-30") or (g.gap or ""):find("after 30") then gap = true end end
    if gap then L:Note("Class quests after 30 (other than The Tempest's Weapons) aren't listed by Icy Veins yet.") end
    local t = ns.Data.ClassTrainers
    if t and t.trainers then
        L:Label("Shaman trainers")
        L:Text(table.concat(t.trainers, " · "), { size = 12 })
        L:Source(t)
    end
end
