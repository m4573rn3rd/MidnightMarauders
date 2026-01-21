local addonName, addonTable = ...
addonTable.Tracker = {}

local isTracking = false
local combatData = {}
local startTime = 0

local function MPrint(msg)
    print("|cFF00FF00[MidnightMarauders]|r: " .. msg)
end

function addonTable.Tracker:Initialize()
    MPrint("Damage Tracker Initialized.")
end

function addonTable.Tracker:ResetData()
    combatData = {}
    MPrint("Combat data reset.")
end

function addonTable.Tracker:StartTimer()
    startTime = GetTime()
end

function addonTable.Tracker:SetTracking(tracking)
    isTracking = tracking
    if isTracking then
        MPrint("Tracking enabled.")
    else
        MPrint("Tracking disabled.")
    end
end

function addonTable.Tracker:IsTracking()
    return isTracking
end

function addonTable.Tracker:LogGroupDamage(source, dest, amount)
    if not combatData[source] then
        combatData[source] = {
            name = source,
            damage = 0,
            dps = 0
        }
    end
    combatData[source].damage = combatData[source].damage + amount
end

function addonTable.Tracker:GetRankedStats()
    local duration = GetTime() - startTime
    local rankedStats = {}
    for _, data in pairs(combatData) do
        data.dps = math.floor(data.damage / duration)
        table.insert(rankedStats, data)
    end
    table.sort(rankedStats, function(a, b) return a.dps > b.dps end)
    return rankedStats, 0, duration
end

function addonTable.Tracker:AutoReport()
    local stats, _, duration = self:GetRankedStats()
    if #stats == 0 then return end

    local channel = "SAY"
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then channel = "INSTANCE_CHAT"
    elseif IsInRaid() then channel = "RAID"
    elseif IsInGroup() then channel = "PARTY" end

    SendChatMessage(string.format("--- Boss Victory! Duration: %.1fs ---", duration), channel)
    
    for i = 1, math.min(5, #stats) do
        local data = stats[i]
        SendChatMessage(string.format("%d. %s: %d DPS", i, data.name, data.dps), channel)
    end
end

function addonTable.Tracker:TargetChanged()
    local targetName = UnitName("target")
    if targetName then
        local classification = UnitClassification("target")
        if classification == "worldboss" or classification == "elite" then
            MPrint("TARGET ACQUIRED: |cFFFF0000" .. targetName .. " (ELITE)|r")
        else
            MPrint("Now Targeting: |cFFFFFF00" .. targetName .. "|r")
        end
    end
end

function addonTable.Tracker:LootMessage(...)
    local msg = ...
    local itemLink = string.match(msg, "|Hitem:.-|h%[.-%]|h")
    if itemLink and Auctionator and Auctionator.API then
        local price = Auctionator.API.v1.GetAuctionPriceByItemLink(addonName, itemLink)
        if price and price > 10000 then 
            MPrint("Market Alert: " .. itemLink .. " is worth " .. GetCoinTextureString(price))
        end
    end

    if msg:find("Fish") or msg:find("Fishing") then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local position = C_Map.GetPlayerMapPosition(mapID, "player")
            if position then
                local x, y = position:GetXY()
                MPrint(string.format("Fishing Spot Logged: %.2f, %.2f (Map %d)", x*100, y*100, mapID))
            end
        end
    end
end

function addonTable.Tracker:CombatLog(...)
    local _, subevent, _, _, sourceName, sourceFlags, _, _, destName, _, _, amount = CombatLogGetCurrentEventInfo()
    
    local MASK_GROUP = COMBATLOG_OBJECT_AFFILIATION_MINE + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_RAID
    
    if bit.band(sourceFlags, MASK_GROUP) ~= 0 then
        if subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
            local damage = (subevent == "SWING_DAMAGE") and amount or select(15, CombatLogGetCurrentEventInfo())
            if damage and sourceName and destName then
                self:LogGroupDamage(sourceName, destName, damage)
            end
        end
    end
end

-- Slash Commands
SLASH_MSTART1 = "/mstart"
SlashCmdList["MSTART"] = function()
    addonTable.Tracker:SetTracking(true)
end

SLASH_MSTOP1 = "/mstop"
SlashCmdList["MSTOP"] = function()
    addonTable.Tracker:SetTracking(false)
end
