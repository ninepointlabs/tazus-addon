-- Shield and Totems hint cells on the Shaman bar. Plain frames, not secure: they
-- never cast.
--   Shield: Lightning Shield (or Water Shield for Restoration / low mana once
--           talented); orbs left when readable; glows "refresh me" when it's gone.
--   Totems: which Earth/Fire/Water/Air totem fits your spec and Solo / Dungeon /
--           Raid, and a nudge when one is missing or running out. Blizzard's
--           totem tracking UI and Call of the Elements bar stay the way to see and
--           drop totems: this cell doesn't list timers or replace them.
-- Hidden values read "hidden".
local _, ns = ...
local UI = ns.UI

local Hints = {}
ns.Hints = Hints

local cells = {}

local function build(key, order, title, icon)
    if cells[key] then return cells[key] end
    local cell = ns.ShamanBar.Cell(key, order)
    local b = CreateFrame("Frame", nil, cell, "BackdropTemplate")
    ns.ShamanBar.Decorate(b, cell, icon or ns.NEUTRAL_ICON)
    b:EnableMouse(true)
    b.title = title
    b:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:SetText(s.title, 1, 0.82, 0)
        for _, l in ipairs(s.lines or {}) do GameTooltip:AddLine(l, 0.85, 0.85, 0.85, true) end
        GameTooltip:AddLine(key == "totems" and "A hint, not a button: drop totems from your action bar or Call of the Elements bar."
            or "A hint, not a button: cast it from your action bar.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cell.b = b
    cells[key] = cell
    return cell
end

-- Pure view model for the shield cell (tests call it).
function Hints.ShieldView(st)
    if not st.recShield then return nil end
    local v = { icon = ns.Rotation.Icon(st.recShield), lines = {} }
    local sh = st.shield
    v.sub = (st.recShield:gsub(" Shield$", ""))
    if sh == nil then
        v.status, v.active = UI.Hex(UI.C.dim) .. "hidden|r", false
    elseif sh == false then
        v.status, v.active = UI.Hex(UI.C.warn) .. "refresh me|r", true
    elseif sh.name ~= st.recShield then
        v.status, v.active = UI.Hex(UI.C.warn) .. "switch?|r", true
    else
        v.status, v.ok = UI.Hex(UI.C.good) .. (sh.charges and (sh.charges .. " orbs") or "on") .. "|r", true
        v.active = false
    end
    table.insert(v.lines, "Suggested: " .. st.recShield .. (st.shieldWhy and (" (" .. st.shieldWhy .. ")") or ""))
    table.insert(v.lines, "Up now: " .. (sh == nil and "can't tell right now" or (sh and (sh.name .. (sh.charges and (", " .. sh.charges .. " orbs") or "")) or "none")))
    table.insert(v.lines, "One shield at a time. Water Shield is the Restoration 11-point talent; it's also handy for Elemental and Enhancement mana.")
    return v
end

-- Pure view model for the totems cell. nudges = ns.Shaman.TotemNudges(...) or nil between pulls,
-- rec = recommended per element.
function Hints.TotemView(st, nudges, hidden, rec)
    local any = false
    for _ in pairs(rec or {}) do any = true break end
    if not any then return nil end
    local v = { icon = ns.Shaman.ELEMENT_ICON.Earth, lines = {} }
    local ctxLabel = ns.Rotation.CONTEXT_LABELS[st.context or "solo"] or "Solo"
    table.insert(v.lines, "For " .. (st.spec or "your spec") .. " · " .. ctxLabel .. ":")
    for _, e in ipairs(ns.Shaman.ELEMENTS) do
        if rec[e] then table.insert(v.lines, "  " .. e .. ": " .. rec[e]) end
    end
    if nudges == nil then
        -- Between pulls: advice only, no nudge.
        v.status, v.active = UI.Hex(UI.C.dim) .. "advice|r", false
    elseif hidden then
        v.status, v.active = UI.Hex(UI.C.dim) .. "hidden|r", false
    elseif #nudges > 0 then
        local n = nudges[1]
        v.status, v.active = UI.Hex(UI.C.warn) .. (#nudges == 1 and (n.element .. " " .. (n.why == "running out" and "low" or "missing")) or (#nudges .. " missing")) .. "|r", true
        v.icon = ns.Rotation.Icon(n.want)
        for _, x in ipairs(nudges) do
            table.insert(v.lines, ("%s: %s (%s)"):format(x.element, x.want, x.why))
        end
    else
        v.status, v.ok = UI.Hex(UI.C.good) .. "all down|r", true
    end
    v.sub = ctxLabel:gsub(" leveling$", "")
    local rules = ns.Data.TotemRules
    if ns.Progress.Knows("Totemic Recall") then table.insert(v.lines, "Moving on? Totemic Recall picks them up and refunds some mana.") end
    if ns.Progress.Knows("Totemic Call") then table.insert(v.lines, "Totemic Call brings your totems to you (cooldown disputed between sources; see Sources & notes).") end
    if rules and rules.persistent_duration then table.insert(v.lines, "Buff totems last " .. rules.persistent_duration .. ".") end
    return v
end

local function apply(cell, v)
    local b = cell.b
    if not v then return false end
    b.icon:SetTexture(v.icon)
    b.status:SetText(v.status or "")
    b.stock:SetText(UI.Hex(UI.C.dim) .. (v.sub or "") .. "|r")
    b.lines = v.lines
    b.icon:SetDesaturated(v.ok == true)
    b.icon:SetAlpha(v.ok and 0.6 or 1)
    b:SetBackdropBorderColor(unpack(v.active and UI.C.warn or (v.ok and UI.C.border or UI.Accent())))
    return true
end

-- Only nudge about totems in combat or with an enemy targeted: dropping totems
-- with nothing to fight wastes mana (addon choice).
function Hints.TotemsMatter()
    if UnitAffectingCombat and UnitAffectingCombat("player") then return true end
    return UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
end

function Hints.Update()
    if not ns.db then return end
    local st = ns.Shaman.State()
    local shield = build("shield", 3, "Shield", "Interface\\Icons\\Spell_Nature_LightningShield")
    local totems = build("totems", 4, "Totems", ns.Shaman.ELEMENT_ICON.Earth)
    local sv = ns.db.char.shieldHint.enabled and Hints.ShieldView(st) or nil
    local tv
    if ns.db.char.totemHint.enabled then
        local nudges, hidden = nil, false
        if Hints.TotemsMatter() then nudges, hidden = ns.Shaman.TotemNudges(st.spec, st.context) end
        tv = Hints.TotemView(st, nudges, hidden, st.totems)
    end
    apply(shield, sv)
    apply(totems, tv)
    return sv, tv
end

local ticker
-- Which cells exist (out of combat only: the bar holds secure buttons).
function Hints.Refresh()
    if InCombatLockdown() then return end
    local shield = build("shield", 3, "Shield", "Interface\\Icons\\Spell_Nature_LightningShield")
    local totems = build("totems", 4, "Totems", ns.Shaman.ELEMENT_ICON.Earth)
    local st = ns.Shaman.State()
    shield.want = ns.db.char.shieldHint.enabled and st.recShield ~= nil
    local anyTotem = false
    for _ in pairs(st.totems or {}) do anyTotem = true break end
    totems.want = ns.db.char.totemHint.enabled and anyTotem
    ns.ShamanBar.Layout()
    if (shield.want or totems.want) and not ticker then
        ticker = C_Timer.NewTicker(0.5, function() pcall(Hints.Update) end)
    end
    pcall(Hints.Update)
end
