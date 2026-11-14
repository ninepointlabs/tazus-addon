-- Settings › Reminders: live status + what to remind about.
local _, ns = ...
local UI = ns.UI

UI.SettingsSections = UI.SettingsSections or {}

UI.SettingsSections.Reminders = function(L, c)
    local cfg = ns.db.char.reminders
    L:Columns({ 0.5, 0.5 })
    L:Label("Right now")
    local list = ns.Reminders.Evaluate()
    if #list == 0 then L:Text(UI.Hex(UI.C.dim) .. "Nothing to check yet at your level.|r") end
    for _, r in ipairs(list) do
        local chip = r.ok and { text = "OK", kind = "good" } or { text = (r.id == "classQuest" or r.id == "ghostWolf") and "Open" or "Missing", kind = "warn" }
        L:Row({ chip = chip, title = r.label, sub = r.detail })
    end
    L:Text(UI.Hex(UI.C.dim) .. "Checked out of combat; missing items pop up on screen (also /tazu remind).|r", { size = 12 })
    L:NextColumn()
    L:Label("Remind me about")
    local function check(label, key)
        L:Check(label, cfg[key], function(v) cfg[key] = v ns.Fire("REMINDERS_CHANGED") UI.Refresh() end)
    end
    check("Reminders on", "enabled")
    check("A weapon imbue on my weapon", "imbue")
    check("My shield (Lightning or Water Shield)", "shield")
    check("Totems down when I have an enemy targeted", "totems")
    check("Element class quests (Earth 4, Fire 10, Water 20, Air 30)", "classQuests")
    check("Ghost Wolf from level 20", "ghostWolf")
    check("Reagents (only ones confirmed for Forever)", "reagents")
    local confirmed = {}
    for _, r in ipairs(ns.Data.Reagents or {}) do if r.confirmed and r.item_id then table.insert(confirmed, r.name) end end
    if #confirmed == 0 then
        L:Note("No Shaman reagent (Fish Oil, Ankh) is confirmed for Forever in the research, so there's no reagent count yet.")
    else
        L:Text(UI.Hex(UI.C.dim) .. "Reagents checked: " .. table.concat(confirmed, ", ") .. ".|r", { size = 12 })
    end
    L:Text(UI.Hex(UI.C.dim) .. "Trainer visits show on Home (Do next) and Leveling > Trainer.|r", { size = 12 })
    L:EndColumns()
end
