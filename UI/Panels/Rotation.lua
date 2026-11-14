local _, ns = ...
local UI = ns.UI

local WHEN_TEXT = {
    always = "", buff_missing = "if the buff is missing", debuff_missing = "if your debuff is missing on the target",
    ready = "when off cooldown", out_of_combat = "out of combat", in_combat = "in combat",
    manual = "when the situation calls for it", usable = "when it lights up",
    in_melee = "in melee range", imbue_missing = "if your weapon has no imbue (or it's running out)",
    shield_missing = "if your shield is gone", fire_totem_out = "while a Fire totem is down",
    no_fire_totem = "if no Fire totem is down",
}
local function whenText(w)
    if not w then return "" end
    if WHEN_TEXT[w] then return WHEN_TEXT[w] end
    local k, v = w:match("^([%w_]+):(.+)$")
    if k == "mana_above" then return "while mana is above " .. v .. "%" end
    if k == "mana_below" then return "when mana is below " .. v .. "%" end
    if k == "target_hp_below" then return "when the target is below " .. v .. "% health" end
    if k == "proc" then return "when " .. v .. " procs" end
    if k == "target_debuff_missing" then return "if " .. v .. " isn't on the target" end
    if k == "totem_missing" then return "if you have no " .. v .. " totem down" end
    if k == "stacks_below" or k == "stacks_at_least" then
        local aura, n = v:match("^(.-):(%d+)$")
        if aura then return (k == "stacks_below" and "until %s has %s stacks" or "at %s %s+ stacks"):format(aura, n) end
    end
    return w
end
ns.Rotation.WhenText = whenText

local view -- nil = the profile's context; "totems" | "cooldowns" | "mana"

local function stateText(v)
    if v == nil then return UI.Hex(UI.C.dim) .. "hidden|r" end
    return v and (UI.Hex(UI.C.good) .. v .. "|r") or (UI.Hex(UI.C.warn) .. "none|r")
end

-- Content entries for one topic (mechanics with that topic, or a whole section
-- such as content.totems), with flags and sources.
local function topicEntries(L, topic, asRows)
    local content = ns.Learn.Content()
    local any = false
    local list = {}
    for _, e in ipairs(content and content.mechanics or {}) do if e.topic == topic then table.insert(list, e) end end
    for _, e in ipairs(content and content[topic] or {}) do table.insert(list, e) end
    for _, e in ipairs(list) do
        do
            any = true
            local flag = e.unconfirmed and ("\n" .. UI.FLAG_ICON .. " " .. UI.Hex(UI.C.warn) .. ((e.flag and e.flag ~= "") and e.flag or "Unconfirmed") .. "|r") or ""
            if asRows then
                L:Row({ title = e.title or "", sub = (e.body or "") .. flag })
            else
                L:Text((e.title and (UI.Hex(UI.Accent()) .. e.title .. "|r\n") or "") .. (e.body or "") .. flag, { size = 12 })
            end
            for _, src in ipairs(e.sources or {}) do L:Source({ source_url = src }) end
        end
    end
    return any
end

local function renderTotems(L, c)
    local st = ns.Shaman.State()
    L:Columns({ 0.5, 0.5 })
    L:Label("Right now")
    local im = st.imbue
    local imText = im == nil and nil or (im and ((im.name or "an imbue") .. (im.left and (" · " .. ns.Imbue.FormatLeft(im.left)) or "")) or false)
    L:Row({ icon = ns.Rotation.Icon(st.recImbue or "Rockbiter Weapon"), title = "Weapon imbue: " .. stateText(imText),
        sub = st.recImbue and ("Suggested: " .. st.recImbue .. (st.imbueWhy and (" (" .. st.imbueWhy .. ")") or "")) or "You don't know a weapon imbue yet (Rockbiter Weapon is the first)." })
    local sh = st.shield
    local shText = sh == nil and nil or (sh and (sh.name .. (sh.charges and (" · " .. sh.charges .. " orbs") or "")) or false)
    L:Row({ icon = ns.Rotation.Icon(st.recShield or "Lightning Shield"), title = "Shield: " .. stateText(shText),
        sub = st.recShield and ("Suggested: " .. st.recShield .. (st.shieldWhy and (" (" .. st.shieldWhy .. ")") or "")) or "You don't know a shield yet." })
    L:Label("Totems for " .. (ns.Rotation.CONTEXT_LABELS[st.context] or "Solo"))
    local anyRec = false
    for _, e in ipairs(ns.Shaman.ELEMENTS) do
        local want = st.totems[e]
        local have = ns.Shaman.Totem(e)
        local unlocked = #ns.Shaman.KnownTotems(e) > 0
        if want or unlocked then
            anyRec = anyRec or want ~= nil
            local haveText = have == nil and (UI.Hex(UI.C.dim) .. "hidden|r") or (have and (UI.Hex(UI.C.good) .. have.name .. "|r") or (UI.Hex(UI.C.dim) .. "none down|r"))
            L:Row({ icon = want and ns.Rotation.Icon(want) or ns.Shaman.ELEMENT_ICON[e], title = e .. ": " .. (want or (UI.Hex(UI.C.dim) .. "no guide pick|r")),
                sub = "Down now: " .. haveText, accent = ns.TotemAccent })
        end
    end
    if not anyRec then
        local q = ns.Progress.NextClassQuest and ns.Progress.NextClassQuest(c.race, c.faction, c.level)
        L:Text(UI.Hex(UI.C.dim) .. "No totems yet. Your first Earth totem comes from the Call of Earth class quest at level 4" .. (q and (" (next: " .. q.name .. ")") or "") .. ".|r", { size = 12 })
    end
    L:Text(UI.Hex(UI.C.dim) .. "Blizzard's totem tracker shows what's down and for how long (right-click one to dismiss it); Call of the Elements drops a preset set. This screen only advises.|r", { size = 12 })
    L:Check("Show the imbue button on the Shaman bar", ns.db.char.imbue.enabled, function(v)
        if InCombatLockdown() then ns.Print("Out of combat only.") return end
        ns.db.char.imbue.enabled = v ns.Imbue.Refresh() UI.Refresh() end)
    L:Check("Show the Fire Nova button", ns.db.char.fireNova.enabled, function(v)
        if InCombatLockdown() then ns.Print("Out of combat only.") return end
        ns.db.char.fireNova.enabled = v ns.FireNova.Refresh() UI.Refresh() end)
    L:Check("Show the Shield hint", ns.db.char.shieldHint.enabled, function(v) ns.db.char.shieldHint.enabled = v ns.Hints.Refresh() UI.Refresh() end)
    L:Check("Show the Totems hint", ns.db.char.totemHint.enabled, function(v) ns.db.char.totemHint.enabled = v ns.Hints.Refresh() UI.Refresh() end)
    L:NextColumn()
    L:Label("How totems, imbues and shields work in Forever")
    local any = topicEntries(L, "totems", false)
    local rot = ns.Data.Rotations or {}
    if rot.totems then L:Text(rot.totems, { size = 12 }) end
    if rot.imbues then L:Text(rot.imbues, { size = 12 }) end
    if rot.totems or rot.imbues then L:Source(ns.Data.Rotations) end
    local adv = ns.Data.TotemAdvice
    if adv and adv.source_url then L:Source(adv) end
    for _, a in ipairs(ns.Data.ImbueAdvice or {}) do
        if a.stale then L:Note("Stale guide advice skipped: " .. a.spec .. " " .. (a.context or "") .. ": " .. a.imbue .. " (" .. (a.why or "") .. ")") end
    end
    if not any and not rot.totems then L:Text("Buff totems last 5 minutes in Forever, and weapon imbues 60 minutes.", { size = 12 }) end
    L:EndColumns()
end

local function renderCooldowns(L, c)
    L:Text(UI.Hex(UI.C.dim) .. "Your own procs and cooldowns, read from the game when Forever allows it. Anything unreadable shows 'hidden'. Blizzard's Cooldown Manager (/cdm, Options > Gameplay Enhancement) tracks these too, including Maelstrom Weapon since Nov 10.|r", { size = 12 })
    L:Columns({ 0.5, 0.5 })
    L:Label("Procs")
    local procs = ns.Cooldowns.Procs()
    for _, p in ipairs(procs) do
        local status
        if p.up == nil then status = UI.Hex(UI.C.dim) .. "hidden|r"
        elseif p.up then status = UI.Hex(UI.C.good) .. (p.max and ((p.stacks or 0) .. "/" .. p.max) or "up") .. "|r"
        else status = UI.Hex(UI.C.dim) .. (p.max and ("0/" .. p.max) or "down") .. "|r" end
        L:Row({ icon = ns.Rotation.Icon(p.aura), title = p.aura, right = status })
    end
    if #procs == 0 then L:Text(UI.Hex(UI.C.dim) .. "None yet: Maelstrom Weapon, Flurry and Clearcasting come from talents.|r", { size = 12 }) end
    L:NextColumn()
    L:Label("Cooldowns")
    local list = ns.Cooldowns.List()
    for _, e in ipairs(list) do
        local right
        if e.left == nil then right = UI.Hex(UI.C.dim) .. "hidden|r"
        elseif e.left <= 0.1 then right = UI.Hex(UI.C.good) .. "ready|r"
        else right = UI.Hex(UI.C.warn) .. ns.Imbue.FormatLeft(e.left) .. "|r" end
        L:Row({ icon = ns.Rotation.Icon(e.spell), title = e.spell, right = right })
    end
    if #list == 0 then L:Text(UI.Hex(UI.C.dim) .. "No tracked cooldowns known yet.|r", { size = 12 }) end
    L:EndColumns()
end

local function renderMana(L, c)
    local content = ns.Learn.Content()
    L:Text(UI.Hex(UI.C.dim) .. "How to stay out of the drink-after-every-pull loop. Facts from the research; anything unconfirmed is marked.|r", { size = 12 })
    local any = false
    for _, e in ipairs(content and content.mechanics or {}) do
        if e.topic == "mana" then
            any = true
            local flag = e.unconfirmed and ("\n" .. UI.FLAG_ICON .. " " .. UI.Hex(UI.C.warn) .. ((e.flag and e.flag ~= "") and e.flag or "Unconfirmed") .. "|r") or ""
            L:Row({ title = e.title or "", sub = (e.body or "") .. flag })
            for _, src in ipairs(e.sources or {}) do L:Source({ source_url = src }) end
        end
    end
    local mana = ns.Data.Rotations and ns.Data.Rotations.mana
    if mana then
        L:Label("Regen")
        L:Text(mana, { size = 12 })
        L:Source(ns.Data.Rotations)
    end
    if not any and not mana then L:Text("No mana content in the research yet.") end
end

UI.RegisterPanel({
    key = "rotation", label = "Rotation",
    setSub = function(sub)
        local key = sub and sub:lower()
        if key == "totems & imbues" or key == "totems" then view = "totems"
        elseif key == "cooldowns" then view = "cooldowns"
        elseif key == "mana" then view = "mana"
        elseif key and ns.Rotation.CONTEXT_LABELS[key] then ns.DB.Profile().rotationContext = key view = nil end
    end,
    render = function(L, c)
        L:Title("Rotation", c.spec and (c.spec .. " · only spells you can use at level " .. c.level) or nil)
        if not c.spec then L:Text("Pick a spec first (spec pill at the top).") return end
        local p = c.profile
        local current = p.rotationContext or "solo"
        local tabs = {}
        for _, key in ipairs(ns.Rotation.CONTEXTS) do
            table.insert(tabs, { label = ns.Rotation.CONTEXT_LABELS[key], active = view == nil and key == current, onClick = function()
                p.rotationContext = key
                view = nil
                ns.Fire("ROTATION_CONTEXT", key)
                UI.Refresh()
            end })
        end
        table.insert(tabs, { label = "Totems & imbues", active = view == "totems", onClick = function() view = "totems" UI.Refresh() end })
        table.insert(tabs, { label = "Cooldowns", active = view == "cooldowns", onClick = function() view = "cooldowns" UI.Refresh() end })
        table.insert(tabs, { label = "Mana", active = view == "mana", onClick = function() view = "mana" UI.Refresh() end })
        L:Tabs(tabs)
        if view == "totems" then renderTotems(L, c) return end
        if view == "cooldowns" then renderCooldowns(L, c) return end
        if view == "mana" then renderMana(L, c) return end

        local ctxData = ns.Rotation.Context(c.spec, current)
        if not ctxData then
            L:Flag("No rotation content for this spec and situation yet.")
            return
        end
        if ctxData.unconfirmed then L:Note(c.spec .. " " .. current .. ": " .. ((ctxData.flag ~= "" and ctxData.flag) or "unconfirmed")) end
        for _, s in ipairs(ctxData.sources or {}) do L:Source({ source_url = s }) end

        L:Columns({ 0.6, 0.4 })
        L:Text(UI.Hex(UI.C.dim) .. "Top of the list wins. The on-screen helper lights up the next one. Advice only: you press the buttons.|r", { size = 12 })
        local n, hidden = 0, 0
        for _, step in ipairs(ctxData.priority or {}) do
            local avail = ns.Rotation.Availability(step.spell, c.level, c.race, c.faction)
            if avail then
                n = n + 1
                local sub = whenText(step.when)
                if step.note and step.note ~= "" then sub = (sub ~= "" and (sub .. " - ") or "") .. step.note end
                local chip
                if avail == "trainable" then chip = { text = "Train it", kind = "warn" } end
                L:Spell(ns.Rotation.SpellId(step.spell), ("%d. %s"):format(n, (step.spell:gsub(" %(talent%)", ""))), sub, nil,
                    ns.Rotation.Icon(step.spell), chip and { chip = chip } or nil)
            else
                hidden = hidden + 1
            end
        end
        if n == 0 then L:Text(UI.Hex(UI.C.dim) .. "Nothing in this list is available at your level yet.|r") end
        if hidden > 0 then
            L:Text(UI.Hex(UI.C.dim) .. hidden .. " more step" .. (hidden == 1 and "" or "s") .. " unlock with levels or talents; they'll appear here when you can use them.|r", { size = 12 })
        end

        L:NextColumn()
        local hud = ns.db.char.rotation
        L:Row({ title = "On-screen helper", sub = hud.showInCombatOnly and "Shows in combat only" or "Next-spell icon near your character",
            button = { label = hud.enabled and "On" or "Off", onClick = function()
                hud.enabled = not hud.enabled
                ns.Fire("HUD_TOGGLE")
                UI.Refresh()
            end } })
        if ctxData.summary then
            L:Label("The plan")
            L:Text(ctxData.summary, { size = 12 })
        end
        if ctxData.tips and #ctxData.tips > 0 then
            L:Label("Tips")
            for _, t in ipairs(ctxData.tips) do L:Text("- " .. t, { size = 12 }) end
        end
        L:Label("Last fight")
        local last = ns.Summary.last
        if last then
            L:Text(("%ds · mana %s -> %s"):format(last.duration, last.manaStart and ("%.0f%%"):format(last.manaStart) or "?", last.manaEnd and ("%.0f%%"):format(last.manaEnd) or "?"), { size = 12 })
            L:Text(UI.Hex(UI.C.dim) .. ns.Summary.Text(last) .. "|r", { size = 12 })
            for _, t in ipairs(last.tips or {}) do L:Text("- " .. t, { size = 12 }) end
        else
            L:Text(UI.Hex(UI.C.dim) .. "After each fight: casts used, mana spent and a tip.|r", { size = 12 })
        end
        L:Buttons({ { label = "Mana tips", onClick = function() view = "mana" UI.Refresh() end },
            { label = "Totems & imbues", onClick = function() view = "totems" UI.Refresh() end } })
        L:EndColumns()
    end,
})
