-- Settings › About the data: client info, research gaps, conflicts, assumptions, sources.
local _, ns = ...
local UI = ns.UI

UI.SettingsSections = UI.SettingsSections or {}

UI.SettingsSections["About the data"] = function(L, c)
    local meta = ns.Data.Meta
    L:Label("Client")
    L:Row({ title = ("Built for %s · Interface %s · project %s"):format(meta.game, tostring(meta.toc_interface), meta.wow_project_id),
        sub = ("Research build %s\nYour client %s (WOW_PROJECT_ID %s)"):format(meta.latest_build_seen,
            table.concat({ GetBuildInfo() }, " / "), tostring(WOW_PROJECT_ID)) })
    L:Note(meta.api_note)

    L:Label("Research gaps (the addon doesn't guess these)")
    for _, g in ipairs(ns.Data.Gaps) do
        L:Row({ chip = { text = "Gap", kind = "warn" }, title = g.gap })
        L:Source(g)
    end
    L:Label("Conflicts between sources")
    for _, cf in ipairs(ns.Data.Conflicts or {}) do
        L:Row({ chip = { text = "Conflict", kind = "info" }, title = cf.topic or "?", sub = cf.detail })
        L:Source(cf)
    end
    L:Label("Addon assumptions")
    L:Row({ title = "Gear scores use rank-derived weights from each spec's stat priority, not simulations." })
    L:Row({ title = "Hit/crit/dodge/parry/block % and weapon DPS are scaled by " .. ns.db.global.percentScale .. " points per 1% or per 1 DPS (Tooltips & bags tab)." })
    L:Row({ title = "Spell damage counts Nature plus all-school damage (Fire/Frost-only lines are left out); healing power counts healing plus 'damage and healing' lines." })
    L:Row({ title = "Mail counts as wearable from level " .. ns.Stats.MAIL_LEVEL .. " (the Classic rule; not confirmed for Forever). Off-hand weapons never count: dual wield is removed." })
    L:Row({ title = "Shield hint: Water Shield (once talented) for Restoration, or for anyone under " .. ns.Shaman.WATER_SHIELD_MANA .. "% mana; Lightning Shield otherwise. The cut-off is an addon choice." })
    L:Row({ title = "Imbue button: when no guide row fits your spec/situation it offers the best imbue you know, Windfury first (Blizzard's Nov 10/11 intent for Enhancement)." })
    L:Row({ title = "Totem nudges only show in combat or with an enemy targeted, and 'running out' means under 10 seconds left." })
    L:Row({ title = "Imbue detection reads your main-hand tooltip for the imbue's name (Windfury, Flametongue, Rockbiter, Frostbrand); otherwise it only knows 'some temporary enchant'." })
    L:Row({ title = "Totem slots use Blizzard's numbering (Fire 1, Earth 2, Water 3, Air 4) via GetTotemInfo; not yet checked on Forever." })
    L:Row({ title = "Tooltip stat parsing reads English item text." })
    L:Row({ title = "PvP ruleset: no documented API, so a realm id (GetRealmName) ending in \"PvP\" counts as the PvP ruleset and only triggers a one-time suggestion; otherwise PvP mode is a manual switch." })
    L:Row({ title = "PvP totem picks vs a class are an addon grouping: Tremor vs Warlocks, Grounding vs Mages, Warlocks and Priests, Earthbind vs the plate and leather melee classes you kite (the list is in the research, pvp.totem_picks). The PvP set's Fire and Water follow your Solo picks." })
    L:Row({ title = "Stoneform hint: counts a debuff only when the client labels it Poison, Disease or Bleed; nothing is guessed from names, and unreadable debuffs mean no hint." })
    L:Row({ title = "Smart Heal heals a friendly living target, else you ([@target,help,nodead][@player]); spells are named without a rank, so the game picks your highest." })

    L:Label("Sources")
    local keys = {}
    for k in pairs(ns.Data.Sources) do table.insert(keys, k) end
    table.sort(keys)
    for _, k in ipairs(keys) do L:Link(k, ns.Data.Sources[k]) end
end
