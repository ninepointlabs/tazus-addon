-- Weapon imbue button: one press (out of combat) casts the recommended weapon
-- imbue for your spec and context, at your highest known rank. Ported from the
-- sister addons' buff buttons (same rules, same look).
--
--   * Which imbue: research imbue_advice in preference order (Blizzard's
--     Nov 10/11 hotfix puts Windfury Weapon at the heart of Enhancement;
--     Rockbiter Weapon is the pre-30 leveling fallback). Rows a guide marks as
--     stale are skipped and shown in Sources & notes. You can pin another one in
--     Settings > Shaman bar.
--   * Main hand only: dual wield is removed in Forever.
--   * Imbues last 60 minutes and sit next to sharpening stones, weightstones and
--     oils (Forever); since the Nov 10/11 hotfix they also stack with weapon totems.
--
-- Blizzard rules this follows:
--   * A secure action button does the cast; every cast needs your click / key
--     press. The addon never casts by itself.
--   * The button's spell only changes out of combat; in combat it keeps the last one.
--   * It casts through the button's own "/cast <Imbue>" line (type=spell failed
--     on Forever; Andric's v0.1.5 fix). No /click, no player macros.
local _, ns = ...
local UI = ns.UI

local Imb = {}
ns.Imbue = Imb

Imb.NAME = "TazusImbueButton"
Imb.CLICK = Imb.NAME
Imb.ICON = "Interface\\Icons\\Spell_Nature_Cyclone"
Imb.SOON = 5 * 60 -- "refresh soon" under 5 minutes left (addon choice)

local btn, cell, current

local function knows(name) return ns.Progress.Knows(name) end

function Imb.KnowsAny()
    for _, n in ipairs(ns.Shaman.IMBUES) do if knows(n) then return true end end
    return false
end

-- The imbue to put on the button: your pinned one (if known) or the recommendation.
function Imb.Choice(st, known)
    known = known or knows
    local pin = ns.db.char.imbue.override
    if pin and known(pin) then return pin, "your pick (Settings > Shaman bar)" end
    return st.recImbue, st.imbueWhy
end

local function fmtLeft(left)
    if not left then return nil end
    if left >= 60 then return ("%dm"):format(math.floor(left / 60)) end
    return ("%ds"):format(math.floor(left))
end
Imb.FormatLeft = fmtLeft

-- Pure view model (tests call it). st = ns.Shaman.State(); want = spell.
function Imb.View(st, want)
    local v = { spell = want, lines = {} }
    local im = st.imbue
    if not want then
        v.status, v.active = UI.Hex(UI.C.dim) .. "none known|r", false
        return v
    end
    v.sub = want:gsub(" Weapon$", "")
    if im == nil then
        v.status, v.active = UI.Hex(UI.C.dim) .. "hidden|r", true
        table.insert(v.lines, "Can't read your weapon right now.")
    elseif im == false then
        v.status, v.active = UI.Hex(UI.C.warn) .. "no imbue|r", true
    elseif im.name and im.name ~= want then
        v.status, v.active = UI.Hex(UI.C.warn) .. (im.name:gsub(" Weapon$", "")) .. "|r", true
        table.insert(v.lines, "On your weapon: " .. im.name .. ". Suggested: " .. want .. ".")
    else
        local left = fmtLeft(im.left)
        local soon = im.left and im.left < Imb.SOON
        v.status = UI.Hex(soon and UI.C.warn or UI.C.good) .. (left or "on") .. "|r"
        v.active = soon and true or false
        v.ok = not soon
        if not im.name then table.insert(v.lines, "Your weapon has a temporary enchant; the addon can't tell which imbue it is.") end
    end
    return v
end

function Imb.MacroText(spell)
    return ns.ShamanBar.CastText(spell)
end

-- Re-aim the secure button (out of combat only).
function Imb.Update()
    if not btn then return end
    local st = ns.Shaman.State()
    local want, why = Imb.Choice(st)
    local v = Imb.View(st, InCombatLockdown() and (current or want) or want)
    btn.status:SetText(v.status or "")
    btn.stock:SetText(UI.Hex(UI.C.dim) .. (v.sub or "") .. "|r")
    btn.lines, btn.why = v.lines, why
    if InCombatLockdown() then
        ns.ShamanBar.SetLook(btn, v.active)
        return
    end
    current = want
    if want then
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", Imb.MacroText(want))
        btn.icon:SetTexture(ns.Rotation.Icon(want))
    else
        btn:SetAttribute("type", nil)
        btn:SetAttribute("macrotext", nil)
        btn.icon:SetTexture(Imb.ICON)
    end
    ns.ShamanBar.SetLook(btn, want ~= nil and v.active)
    if GameTooltip:IsShown() and GameTooltip:GetOwner() == btn then btn:GetScript("OnEnter")(btn) end
end

function Imb.ShouldShow()
    local cfg = ns.db and ns.db.char.imbue
    return cfg and cfg.enabled and Imb.KnowsAny() and true or false
end

function Imb.Build()
    if btn then return btn end
    cell = ns.ShamanBar.Cell("imbue", 1)
    btn = CreateFrame("Button", Imb.NAME, cell, "SecureActionButtonTemplate, BackdropTemplate")
    ns.ShamanBar.Decorate(btn, cell, Imb.ICON)
    -- Mouse and key binding act on release (see SecureActionButton_OnClick).
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("useOnKeyDown", false)
    btn:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:SetText("Weapon imbue: " .. (current or "none known"), 1, 0.82, 0)
        if s.why then GameTooltip:AddLine("Why: " .. s.why, 1, 1, 1, true) end
        for _, l in ipairs(s.lines or {}) do GameTooltip:AddLine(l, 0.85, 0.85, 0.85, true) end
        GameTooltip:AddLine("Click or press " .. (Imb.Key() or "your key (Settings > Shaman bar)") .. ": one cast per press, highest rank you know.", 0.6, 0.6, 0.6, true)
        GameTooltip:AddLine("Imbues last 60 minutes, sit next to stones and oils, and stack with weapon totems since the Nov 10/11 hotfix.", 0.6, 0.6, 0.6, true)
        if InCombatLockdown() then GameTooltip:AddLine("In combat the button keeps its imbue until combat ends.", 1, 0.5, 0.3, true) end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:HookScript("PostClick", function(_, _, down)
        if down then return end
        C_Timer.After(0.5, function() pcall(Imb.Update) end)
    end)
    return btn
end

local ticker
function Imb.Refresh()
    if InCombatLockdown() then return end -- show/hide of secure frames is blocked in combat
    Imb.Build()
    local show = Imb.ShouldShow()
    cell.want = show
    ns.ShamanBar.Layout()
    if show and not ticker then
        ticker = C_Timer.NewTicker(1, function() pcall(Imb.Update) end)
    elseif not show and ticker then
        ticker:Cancel()
        ticker = nil
    end
    if show then Imb.Update() end
    Imb.ApplyKey()
end

-- /tazu imbue debug
function Imb.Debug()
    Imb.Build()
    local function a(n) return tostring(btn:GetAttribute(n)) end
    local st = ns.Shaman.State()
    ns.Print("Imbue button debug:")
    print(("  shown=%s combat=%s knowsAny=%s enabled=%s pin=%s"):format(tostring(cell:IsShown()), tostring(InCombatLockdown()),
        tostring(Imb.KnowsAny()), tostring(ns.db.char.imbue.enabled), tostring(ns.db.char.imbue.override)))
    print(("  type=%s macrotext=%s"):format(a("type"), a("macrotext"):gsub("\n", " | ")))
    local im = st.imbue
    print(("  suggested=%s (%s) on weapon=%s left=%s"):format(tostring(st.recImbue), tostring(st.imbueWhy),
        im == nil and "hidden" or (im == false and "none" or tostring(im.name or "unnamed enchant")), tostring(im and im.left)))
    print("  key: " .. tostring(Imb.Key()))
end

-- Key binding: override binding that clicks the button, per character, out of
-- combat. None by default; Super/Meta combos are refused.
function Imb.Key()
    return ns.db and ns.db.char.imbue.key
end

function Imb.ApplyKey()
    if not btn then return end
    ns.ShamanBar.ApplyKey(btn, Imb.CLICK, Imb.Key())
end

function Imb.SetKey(key)
    if InCombatLockdown() then ns.Print("Can't change key bindings in combat.") return end
    Imb.Build()
    ns.db.char.imbue.key = key
    Imb.ApplyKey()
    ns.Print(key and ("Imbue button bound to " .. key .. ".") or "Imbue button key cleared.")
    ns.Fire("KEY_CHANGED")
end

function Imb.StartKeyCapture()
    ns.ShamanBar.CaptureKey("imbue button", Imb.SetKey)
end
