-- Smart Shock and Smart Heal: two secure buttons on the Shaman bar. Each press is
-- one cast, chosen by plain macro conditionals in the button's own "/cast" line
-- (no /click, no player macros, nothing decided by addon code at press time):
--
--   Smart Shock  /cast [mod:shift] Frost Shock; Earth Shock
--                Earth Shock by default, Frost Shock with the modifier (Shift,
--                Ctrl or Alt; Settings > Shaman bar). Frost Shock is only in the
--                line once you know it.
--   Smart Heal   /cast [mod:alt,@target,help,nodead][mod:alt,@player] Lesser Healing Wave;
--                      [@target,help,nodead][@player] Healing Wave
--                A friendly living target gets the heal, otherwise you do. Alt
--                casts Lesser Healing Wave once you know it.
--
-- Spells are named without a rank, so the game casts your highest known rank:
-- no downranking. Like the other secure buttons, the line is rebuilt only out of
-- combat (when you learn a spell or change the modifier), keys are unbound by
-- default and set as per-character override bindings (never Super/Meta).
local _, ns = ...
local UI = ns.UI

local Smart = {}
ns.Smart = Smart

Smart.MODS = { "shift", "ctrl", "alt" }
Smart.MOD_LABEL = { shift = "Shift", ctrl = "Ctrl", alt = "Alt" }

local function knows(name) return ns.Progress.Knows(name) end

-- Pure macro builders (tests call them). known = function(name) -> bool.
function Smart.ShockText(known, mod)
    known = known or knows
    mod = Smart.MOD_LABEL[mod or "shift"] and (mod or "shift") or "shift"
    local earth, frost = known("Earth Shock"), known("Frost Shock")
    if earth and frost then return ("/cast [mod:%s] Frost Shock; Earth Shock"):format(mod) end
    if earth then return "/cast Earth Shock" end
    if frost then return "/cast Frost Shock" end
    return nil
end

function Smart.HealText(known)
    known = known or knows
    if not known("Healing Wave") then return nil end
    local main = "[@target,help,nodead][@player] Healing Wave"
    if known("Lesser Healing Wave") then
        return "/cast [mod:alt,@target,help,nodead][mod:alt,@player] Lesser Healing Wave; " .. main
    end
    return "/cast " .. main
end

-- ---------------------------------------------------------------------------
-- One factory for both buttons.

local function newButton(def)
    local B = { def = def }
    local btn, cell, ticker

    function B.Cfg() return ns.db and ns.db.char[def.db] end
    function B.Key() local c = B.Cfg() return c and c.key end
    function B.Button() return btn end

    function B.Build()
        if btn then return btn end
        cell = ns.ShamanBar.Cell(def.cell, def.order)
        btn = CreateFrame("Button", def.name, cell, "SecureActionButtonTemplate, BackdropTemplate")
        ns.ShamanBar.Decorate(btn, cell, def.icon)
        btn:RegisterForClicks("AnyUp", "AnyDown")
        btn:SetAttribute("useOnKeyDown", false)
        btn:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            GameTooltip:SetText(def.title, 1, 0.82, 0)
            for _, l in ipairs(def.lines()) do GameTooltip:AddLine(l, 0.85, 0.85, 0.85, true) end
            GameTooltip:AddLine("Click or press " .. (B.Key() or "your key (Settings > Shaman bar)") .. ": one cast per press, highest rank you know.", 0.6, 0.6, 0.6, true)
            if InCombatLockdown() then GameTooltip:AddLine("What it casts only changes out of combat.", 1, 0.5, 0.3, true) end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return btn
    end

    function B.ShouldShow()
        local cfg = B.Cfg()
        return cfg and cfg.enabled and def.text() ~= nil and true or false
    end

    function B.Update()
        if not btn then return end
        local v = def.view()
        btn.status:SetText(v.status or "")
        btn.stock:SetText(UI.Hex(UI.C.dim) .. (v.sub or "") .. "|r")
        ns.ShamanBar.SetLook(btn, v.active ~= false)
        local left = def.cooldownSpell and ns.Auras.CooldownLeft(ns.Rotation.SpellId(def.cooldownSpell) or def.cooldownSpell)
        local key = B.Key()
        btn.hotkey:SetText(left and left > 0.1 and ("%d"):format(math.ceil(left)) or ((key and GetBindingText and GetBindingText(key, true)) or key or ""))
    end

    function B.Refresh()
        if InCombatLockdown() then return end -- secure attributes and show/hide: out of combat only
        B.Build()
        local text = def.text()
        local show = B.ShouldShow()
        cell.want = show
        if show then
            btn:SetAttribute("type", "macro")
            btn:SetAttribute("macrotext", text)
            btn.icon:SetTexture(ns.Rotation.Icon(def.iconSpell))
        else
            btn:SetAttribute("type", nil)
            btn:SetAttribute("macrotext", nil)
        end
        ns.ShamanBar.Layout()
        if show and not ticker then
            ticker = C_Timer.NewTicker(0.5, function() pcall(B.Update) end)
        elseif not show and ticker then
            ticker:Cancel()
            ticker = nil
        end
        B.ApplyKey()
        if show then B.Update() end
    end

    function B.ApplyKey()
        if not btn then return end
        ns.ShamanBar.ApplyKey(btn, def.name, B.Key())
    end

    function B.SetKey(key)
        if InCombatLockdown() then ns.Print("Can't change key bindings in combat.") return end
        B.Build()
        B.Cfg().key = key
        B.ApplyKey()
        ns.Print(key and (def.title .. " bound to " .. key .. ".") or (def.title .. " key cleared."))
        ns.Fire("KEY_CHANGED")
    end

    function B.StartKeyCapture()
        ns.ShamanBar.CaptureKey(def.title:lower(), B.SetKey)
    end

    function B.Toggle()
        if InCombatLockdown() then ns.Print("Can't show or hide the " .. def.title .. " button in combat.") return end
        local cfg = B.Cfg()
        cfg.enabled = not cfg.enabled
        B.Refresh()
        ns.Print(def.title .. " button " .. (cfg.enabled and "shown" or "hidden") .. ".")
    end
    return B
end

-- Smart Shock ---------------------------------------------------------------
local Shock
Shock = newButton({
    db = "shock", cell = "shock", order = 2, name = "TazusShockButton", title = "Smart Shock",
    icon = "Interface\\Icons\\Spell_Nature_EarthShock", iconSpell = "Earth Shock", cooldownSpell = "Earth Shock",
    text = function() return Smart.ShockText(nil, Shock.Cfg() and Shock.Cfg().mod) end,
    view = function()
        local mod = Smart.MOD_LABEL[(Shock.Cfg() or {}).mod or "shift"] or "Shift"
        local v = { status = UI.Hex(UI.C.good) .. "Earth|r" }
        if knows("Frost Shock") then v.sub = mod .. ": Frost" end
        if not knows("Earth Shock") then v.status = UI.Hex(UI.C.good) .. "Frost|r" v.sub = nil end
        return v
    end,
    lines = function()
        local mod = Smart.MOD_LABEL[(Shock.Cfg() or {}).mod or "shift"] or "Shift"
        local out = { "Earth Shock: instant damage that also interrupts a cast." }
        if knows("Frost Shock") then
            table.insert(out, "Hold " .. mod .. ": Frost Shock, to slow a runner or kite a melee.")
        else
            table.insert(out, "Frost Shock joins this button (on " .. mod .. ") once you learn it.")
        end
        return out
    end,
})
ns.Shock = Shock

function Shock.SetMod(mod)
    if InCombatLockdown() then ns.Print("Out of combat only.") return end
    if not Smart.MOD_LABEL[mod] then return end
    Shock.Cfg().mod = mod
    Shock.Refresh()
end

-- Smart Heal ----------------------------------------------------------------
local Heal
Heal = newButton({
    db = "heal", cell = "heal", order = 3, name = "TazusHealButton", title = "Smart Heal",
    icon = "Interface\\Icons\\Spell_Nature_MagicImmunity", iconSpell = "Healing Wave",
    text = function() return Smart.HealText() end,
    view = function()
        local friendly = false
        if UnitExists("target") and UnitCanAssist then
            local ok, can = pcall(UnitCanAssist, "player", "target")
            friendly = ok and not ns.Auras.IsSecret(can) and can and not UnitIsDead("target") or false
        end
        return { status = UI.Hex(UI.C.good) .. (friendly and "target" or "you") .. "|r",
            sub = knows("Lesser Healing Wave") and "Alt: Lesser" or nil }
    end,
    lines = function()
        local out = { "Healing Wave on your friendly target, or on you when you have none (or an enemy targeted)." }
        if knows("Lesser Healing Wave") then
            table.insert(out, "Hold Alt: Lesser Healing Wave, the faster heal, on the same target.")
        else
            table.insert(out, "Lesser Healing Wave joins this button (on Alt) once you learn it.")
        end
        table.insert(out, "Always your highest rank; the addon doesn't downrank.")
        return out
    end,
})
ns.Heal = Heal

function Smart.Refresh()
    pcall(Shock.Refresh)
    pcall(Heal.Refresh)
end
