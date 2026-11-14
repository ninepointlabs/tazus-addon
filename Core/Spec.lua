-- Spec definitions: names, roles, palette, icons.
local _, ns = ...

ns.SPEC_ORDER = { "Elemental", "Enhancement", "Restoration" }

-- Palette (brief): lightning blue/teal for Elemental, earthy orange/red for
-- Enhancement, sea green/blue for Restoration, plus a muted totem-earth accent
-- on the totem screens. Icons are the standard Shaman spec icons (the same art
-- Blizzard's icon CDN serves).
ns.Specs = {
    Elemental = {
        key = "Elemental", role = "Damage",
        icon = "Interface\\Icons\\Spell_Nature_Lightning",
        accent = { 0.275, 0.737, 0.875 }, accent2 = { 0.533, 0.882, 0.890 },
        tree = "Elemental Combat", weights = "Elemental",
        blurb = "Lightning Bolt and Chain Lightning from range, Flame Shock and Fire Nova, Lightning Mastery as a burst window. A solid caster leveler too.",
    },
    Enhancement = {
        key = "Enhancement", role = "Damage",
        icon = "Interface\\Icons\\Spell_Nature_LightningShield",
        accent = { 0.886, 0.494, 0.231 }, accent2 = { 0.800, 0.302, 0.243 },
        tree = "Enhancement", weights = "Enhancement",
        blurb = "A slow two-hander with Windfury, Stormstrike on cooldown, shocks and instant Lightning Bolts from Maelstrom Weapon. The recommended leveling spec.",
    },
    Restoration = {
        key = "Restoration", role = "Healer",
        icon = "Interface\\Icons\\Spell_Nature_MagicImmunity",
        accent = { 0.239, 0.725, 0.580 }, accent2 = { 0.290, 0.553, 0.820 },
        tree = "Restoration", weights = "Restoration",
        blurb = "Water Shield, Chain Heal and Healing Wave, Riptide at 31 points, Mana Tide for the group. For dungeons and raids, not for solo leveling.",
    },
}

-- Brief default (Tim may change): level as Enhancement; at 40 make dual spec
-- Enhancement (A) + Restoration (B) for groups.
ns.RECOMMENDED_LEVELING_SPEC = "Enhancement"
ns.RECOMMENDED_DUAL_SPEC = { A = "Enhancement", B = "Restoration" }

-- Neutral palette used before a spec is picked (shaman blue).
ns.NeutralAccent = { 0.0, 0.439, 0.871 }
ns.NEUTRAL_ICON = "Interface\\Icons\\Spell_Nature_BloodLust"

-- Muted totem-earth accent, used on the totem screens.
ns.TotemAccent = { 0.659, 0.533, 0.373 }

function ns.SpecAccent(spec)
    local s = ns.Specs[spec or (ns.DB and ns.DB.char and ns.DB.ActiveSpec())]
    return s and s.accent or ns.NeutralAccent
end

function ns.IsHealer(spec)
    spec = spec or (ns.DB and ns.DB.char and ns.DB.ActiveSpec())
    return spec == "Restoration"
end

function ns.IsCaster(spec)
    spec = spec or (ns.DB and ns.DB.char and ns.DB.ActiveSpec())
    return spec == "Elemental" or spec == "Restoration"
end
