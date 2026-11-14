-- Settings: General · Shaman bar · Tooltips & bags · Reminders · About the data · About.
local _, ns = ...
local UI = ns.UI

UI.SettingsSections = UI.SettingsSections or {}
local S = UI.SettingsSections

local TABS = { "General", "Shaman bar", "Tooltips & bags", "Reminders", "About the data", "About" }
local tab = "General"

S.General = function(L, c)
    local g, ch = ns.db.global, ns.db.char
    L:Label("Specs & dual spec")
    for _, id in ipairs(ns.DB.PROFILE_IDS) do
        local p = ns.DB.Profile(id)
        local items = {}
        for _, spec in ipairs(ns.SPEC_ORDER) do
            table.insert(items, { label = spec, active = p.spec == spec, onClick = function()
                ns.DB.SetSpec(spec, id)
                UI.Refresh()
            end })
        end
        L:Text(("Profile %s · talent spec %s%s"):format(id, id == "A" and "1" or "2", ns.DB.ActiveId() == id and (UI.Hex(UI.C.good) .. "  (active)|r") or ""))
        L:Buttons(items, 110)
    end
    local cb = L:Check("Switch profile automatically with my talent spec", ch.autoSwitch, function(v)
        ch.autoSwitch = v
        if v then ns.DualSpec.Sync() end
        UI.Refresh()
    end, "Swapping talent specs (dual spec, level 40) swaps the addon profile: spec 1 -> A, spec 2 -> B.")
    if not ns.DualSpec.IsAvailable() then
        cb:Disable()
        L:Text(UI.Hex(UI.C.dim) .. "This client doesn't expose the talent-group API.|r", { size = 12, indent = 30 })
    else
        local grp = ns.DualSpec.ActiveGroup()
        L:Text(UI.Hex(UI.C.dim) .. (ns.DualSpec.HasDualSpec() and ("Dual spec learned. Active talent spec: " .. tostring(grp or "?") .. ".")
            or "Dual spec not learned yet (level 40, at your class trainer). The plan: Enhancement on A, Restoration on B for groups.") .. "|r", { size = 12, indent = 30 })
    end

    L:Label("Rotation helper & fight summary")
    L:Check("Show the on-screen rotation helper", ch.rotation.enabled, function(v) ch.rotation.enabled = v ns.Fire("HUD_TOGGLE") end)
    L:Check("Only in combat", ch.rotation.showInCombatOnly, function(v) ch.rotation.showInCombatOnly = v ns.Fire("HUD_TOGGLE") end)
    L:Check("Post-fight summary in chat", ch.summary.enabled, function(v) ch.summary.enabled = v end)
    L:Buttons({ { label = "Reset helper position", onClick = function() ch.rotation.point = nil ns.Fire("HUD_RESET") end } })

    L:Label("Learning & window")
    L:Check("Hint the first time I learn a spell", ch.learn.hints, function(v) ch.learn.hints = v end)
    L:Check("Show minimap button", not g.minimap.hide, function(v) g.minimap.hide = not v ns.Fire("MINIMAP_TOGGLE") end)
    L:Check("Debug messages", g.debug, function(v) g.debug = v end)
    L:Text(UI.Hex(UI.C.dim) .. "Slash: /tazu (or /shaman) · /tazu spec ele|enh|resto · /tazu rotation · /tazu totems · /tazu imbue key · /tazu nova key · /tazu bar|r", { size = 12 })
end

-- Cycle a setting through steps (button label "Keep 20" -> next value).
local function cycle(cfgT, key, steps, after)
    return function()
        local nextV = steps[1]
        for i, v in ipairs(steps) do if v == cfgT[key] then nextV = steps[i + 1] or steps[1] end end
        cfgT[key] = nextV
        if after then after() end
        UI.Refresh()
    end
end

local function keyRow(L, key, what, startCapture, clear)
    L:Row({ title = what .. " key", sub = key and "Pressing it presses the button, even if the key is bound to something else in Blizzard's menu." or "No key set (none by default).",
        right = key and (UI.Hex(UI.C.good) .. key .. "|r") or (UI.Hex(UI.C.dim) .. "none|r") })
    L:Buttons({
        { label = "Set key", onClick = startCapture, tip = "Press any key (Shift/Ctrl/Alt combos work). Esc cancels." },
        { label = "Clear key", onClick = function() clear(nil) UI.Refresh() end },
    })
end

S["Shaman bar"] = function(L, c)
    L:Text("One small bar: the weapon imbue button and the Fire Nova button (they cast, one press = one cast), plus Shield and Totems hints (they only advise). Blizzard's totem tracker and Call of the Elements bar stay the way to see and drop totems. Drag the strip above the bar to move it.", { size = 13 })
    L:Buttons({ { label = "Reset bar position", onClick = function() ns.ShamanBar.ResetPosition() end } })

    local cfg = ns.db.char.imbue
    L:Label("Weapon imbue button")
    L:Text("One press, out of combat, puts the suggested imbue on your weapon at the highest rank you know. It follows Blizzard's Nov 10/11 hotfix (Windfury Weapon at the heart of Enhancement), with Rockbiter Weapon as the leveling fallback before 30.", { size = 12 })
    L:Check("Show the imbue button", cfg.enabled, function(v)
        if InCombatLockdown() then ns.Print("Out of combat only.") return end
        cfg.enabled = v
        ns.Imbue.Refresh()
    end)
    local items = { { label = "Automatic", active = cfg.override == nil, onClick = function()
        if InCombatLockdown() then return end
        cfg.override = nil ns.Imbue.Refresh() UI.Refresh() end } }
    for _, n in ipairs(ns.Shaman.IMBUES) do
        if ns.Progress.Knows(n) then
            table.insert(items, { label = (n:gsub(" Weapon$", "")), active = cfg.override == n, onClick = function()
                if InCombatLockdown() then return end
                cfg.override = n ns.Imbue.Refresh() UI.Refresh() end })
        end
    end
    L:Text(UI.Hex(UI.C.dim) .. "Automatic follows your spec, Solo/Dungeon/Raid and level. Pick one to pin it.|r", { size = 12 })
    L:Buttons(items, 104)
    keyRow(L, cfg.key, "Imbue", ns.Imbue.StartKeyCapture, ns.Imbue.SetKey)

    L:Label("Fire Nova button")
    L:Text("Fire Nova erupts at your current Fire totem (Fire Nova Totem is gone in Forever). The button lights up only while one of your Fire totems is down.", { size = 12 })
    L:Check("Show the Fire Nova button", ns.db.char.fireNova.enabled, function(v)
        if InCombatLockdown() then ns.Print("Out of combat only.") return end
        ns.db.char.fireNova.enabled = v
        ns.FireNova.Refresh()
    end)
    keyRow(L, ns.db.char.fireNova.key, "Fire Nova", ns.FireNova.StartKeyCapture, ns.FireNova.SetKey)

    L:Label("Shield & totem hints")
    L:Check("Show the Shield hint", ns.db.char.shieldHint.enabled, function(v) ns.db.char.shieldHint.enabled = v ns.Hints.Refresh() end)
    L:Check("Show the Totems hint", ns.db.char.totemHint.enabled, function(v) ns.db.char.totemHint.enabled = v ns.Hints.Refresh() end,
        "Which totem per element for your spec and Solo/Dungeon/Raid; nudges only in combat or with an enemy targeted.")

    L:Space(6)
    L:Text(UI.Hex(UI.C.dim) .. "Pick keys your desktop doesn't use (on Omarchy, Super combos belong to the desktop, so they're never offered). No key is bound by default. What the secure buttons cast and their keys only change out of combat (Blizzard rule).|r", { size = 12 })
end

S["Tooltips & bags"] = function(L, c)
    local g = ns.db.global
    L:Check("Upgrade tips on item tooltips", g.tooltip.enabled, function(v) g.tooltip.enabled = v end)
    L:Check("Show what improves (stat changes) in tooltips", g.tooltip.showStats, function(v) g.tooltip.showStats = v end)
    L:Check("Highlight upgrades in my bags", g.bags.highlight, function(v) g.bags.highlight = v ns.Bags.RefreshAll() end,
        "Glow + arrow on bag items that beat what you're wearing for your active spec and that you can equip now.")
    L:Check("Tell me when an upgrade lands in my bags", g.bags.toast, function(v) g.bags.toast = v end)
    L:Space(6)
    L:Row({ title = "Hit/crit value", sub = "How many points of spell power/healing 1% hit or crit is worth. An addon assumption, not from the research.",
        button = { label = g.percentScale .. " per 1%", onClick = function()
            local steps = { 5, 8, 10, 12, 14, 20 }
            local nextV = steps[1]
            for i, v in ipairs(steps) do if v == g.percentScale then nextV = steps[i + 1] or steps[1] end end
            g.percentScale = nextV
            ns.Stats.ClearCache()
            UI.Refresh()
        end } })
end

S.About = function(L, c)
    local version = tostring(ns.VERSION)
    if not version:match("^v") then version = "v" .. version end
    L:Row({ icon = ns.NEUTRAL_ICON, title = ns.TITLE .. " " .. version,
        sub = "The do-everything Shaman companion for World of Warcraft: Forever." })
    L:Label("Named for")
    L:Row({ icon = "Interface\\Icons\\Spell_Nature_LightningShield", title = "Tazu",
        sub = "Troll Shaman of the Horde, on the Ganj realm. This addon was built for him and tested on him." })
    L:Text(UI.Hex(UI.C.dim) .. "If a Troll Shaman drops a totem next to you in the Valley of Trials, say hello.|r", { size = 12 })
    L:Label("Links")
    L:Link("Website", "https://tazus-addon.myazerothlife.com")
    L:Link("Source and issues", "https://github.com/ninepointlabs/tazus-addon")
    L:Label("Sister addons")
    L:Link("Andric's Addon (Priest)", "https://andricsaddon.myazerothlife.com")
    L:Link("Parzelle's Addon (Mage)", "https://parzelles-addon.myazerothlife.com")
    L:Link("Tristan's Addon (Paladin)", "https://tristans-addon.myazerothlife.com")
    L:Link("My Azeroth Life", "https://myazerothlife.com")
    L:Label("Credits")
    L:Row({ title = "Made by Nine Point Labs", sub = "Free and open source, MIT licence." })
    L:Row({ title = "Information from Blizzard, Icy Veins and Wowhead", sub = "Credited per fact: see About the data, or the Sources & notes link on each screen. Single-source fan-site facts are marked unconfirmed." })
    L:Text(UI.Hex(UI.C.dim) .. "Tazu's Addon is an unofficial fan project, not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft and Warcraft are trademarks of Blizzard Entertainment, Inc.|r", { size = 11 })
end

UI.RegisterPanel({
    key = "settings", label = "Settings",
    setSub = function(sub) for _, t in ipairs(TABS) do if t == sub then tab = sub end end end,
    render = function(L, c)
        L:Title("Settings")
        local items = {}
        for _, t in ipairs(TABS) do
            table.insert(items, { label = t, active = tab == t, onClick = function() tab = t UI.Refresh() end })
        end
        L:Tabs(items)
        local fn = S[tab] or S.General
        fn(L, c)
    end,
})
