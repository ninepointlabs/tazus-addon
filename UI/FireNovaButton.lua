-- Fire Nova button. In Forever, Fire Nova Totem is gone: Fire Nova is a baseline
-- spell that erupts at your current Fire totem and can be cast again and again.
-- So the button is only offered (lit, "ready") while one of your Fire totems is
-- down; with no Fire totem it dims and says "no Fire totem".
--
-- Secure-frame rules: the cell can only be shown or hidden out of combat, and
-- totems usually go down mid-fight, so the button stays on the bar whenever you
-- know Fire Nova (and it's enabled) and only its look follows your Fire totem.
-- Pressing it without a Fire totem just gets the game's own error. One press =
-- one cast; "/cast Fire Nova" macrotext (type=spell failed on Forever).
local _, ns = ...
local UI = ns.UI

local FN = {}
ns.FireNova = FN

FN.NAME = "TazusFireNovaButton"
FN.CLICK = FN.NAME
FN.SPELL = "Fire Nova"
FN.ICON = "Interface\\Icons\\Spell_Fire_SealOfFire"

local btn, cell

local function knows(name) return ns.Progress.Knows(name) end

-- Pure view model. ready = ns.Shaman.FireNovaReady() (true/false/nil), totem = ns.Shaman.Totem("Fire").
function FN.View(ready, totem)
    local v = { lines = {} }
    if ready == nil then
        v.status, v.active = UI.Hex(UI.C.dim) .. "hidden|r", true
        table.insert(v.lines, "Can't read your totems right now.")
    elseif ready then
        v.status, v.active = UI.Hex(UI.C.good) .. "ready|r", true
        v.sub = totem and totem.name and (totem.name:gsub(" Totem$", "")) or nil
        table.insert(v.lines, "Erupts at " .. (totem and totem.name or "your Fire totem") .. ".")
    else
        v.status, v.active = UI.Hex(UI.C.dim) .. "no Fire totem|r", false
        table.insert(v.lines, "Drop a Fire totem first (Searing Totem, Magma Totem...): Fire Nova erupts at it.")
    end
    return v
end

function FN.Update()
    if not btn then return end
    local totem = ns.Shaman.Totem("Fire")
    local v = FN.View(ns.Shaman.FireNovaReady(), totem)
    btn.status:SetText(v.status or "")
    btn.stock:SetText(UI.Hex(UI.C.dim) .. (v.sub or "") .. "|r")
    btn.lines = v.lines
    ns.ShamanBar.SetLook(btn, v.active)
    local left = ns.Auras.CooldownLeft(ns.Rotation.SpellId(FN.SPELL) or FN.SPELL)
    btn.hotkey:SetText(left and left > 0.1 and ("%d"):format(math.ceil(left)) or ((FN.Key() and GetBindingText and GetBindingText(FN.Key(), true)) or FN.Key() or ""))
end

function FN.ShouldShow()
    local cfg = ns.db and ns.db.char.fireNova
    return cfg and cfg.enabled and knows(FN.SPELL) and true or false
end

function FN.Build()
    if btn then return btn end
    cell = ns.ShamanBar.Cell("firenova", 4)
    btn = CreateFrame("Button", FN.NAME, cell, "SecureActionButtonTemplate, BackdropTemplate")
    ns.ShamanBar.Decorate(btn, cell, FN.ICON)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("useOnKeyDown", false)
    btn:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:SetText("Fire Nova", 1, 0.82, 0)
        for _, l in ipairs(s.lines or {}) do GameTooltip:AddLine(l, 0.85, 0.85, 0.85, true) end
        GameTooltip:AddLine("Click or press " .. (FN.Key() or "your key (Settings > Shaman bar)") .. ": one cast per press.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return btn
end

local ticker
function FN.Refresh()
    if InCombatLockdown() then return end
    FN.Build()
    local show = FN.ShouldShow()
    cell.want = show
    if show then
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", ns.ShamanBar.CastText(FN.SPELL))
        btn.icon:SetTexture(ns.Rotation.Icon(FN.SPELL))
    else
        btn:SetAttribute("type", nil)
        btn:SetAttribute("macrotext", nil)
    end
    ns.ShamanBar.Layout()
    if show and not ticker then
        ticker = C_Timer.NewTicker(0.5, function() pcall(FN.Update) end)
    elseif not show and ticker then
        ticker:Cancel()
        ticker = nil
    end
    FN.ApplyKey()
    if show then FN.Update() end
end

function FN.Key() return ns.db and ns.db.char.fireNova.key end

function FN.ApplyKey()
    if not btn then return end
    ns.ShamanBar.ApplyKey(btn, FN.CLICK, FN.Key())
end

function FN.SetKey(key)
    if InCombatLockdown() then ns.Print("Can't change key bindings in combat.") return end
    FN.Build()
    ns.db.char.fireNova.key = key
    FN.ApplyKey()
    ns.Print(key and ("Fire Nova button bound to " .. key .. ".") or "Fire Nova button key cleared.")
    ns.Fire("KEY_CHANGED")
end

function FN.StartKeyCapture()
    ns.ShamanBar.CaptureKey("Fire Nova button", FN.SetKey)
end
