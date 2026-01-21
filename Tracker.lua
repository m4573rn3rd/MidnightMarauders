local addonName, addonTable = ...
local frame = CreateFrame("Frame")
local isTracking = false

local function MPrint(msg)
    print("|cFF00FF00[MidnightMarauders]|r: " .. msg)
end

-- Helper: Broadcasts ranked results with the clean header
local function AutoReport()
    if not addonTable.Tracker or not addonTable.Tracker.GetRankedStats then return end
    
    local stats, totalDamage, duration = addonTable.Tracker:GetRankedStats()
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

-- Slash Commands
SLASH_MSTART1 = "/mstart"
SlashCmdList["MSTART"] = function()
    isTracking = true
    MPrint("Manual Tracking |cFF00FF00ENABLED|r.")
end

SLASH_MSTOP1 = "/mstop"
SlashCmdList["MSTOP"] = function()
    isTracking = false
    MPrint("Manual Tracking |cFFFF0000STOPPED|r.")
end

-- Unified Event Handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- Initialize Damage Tracker
        if addonTable.Tracker and addonTable.Tracker.Initialize then
            addonTable.Tracker:Initialize()
        end
        
        -- Initialize Guild Auditor
        if addonTable.GuildTracker and addonTable.GuildTracker.Initialize then
            addonTable.GuildTracker:Initialize()
        end

        -- Initialize Quest Telemetry
        if addonTable.QuestLog and addonTable.QuestLog.Initialize then
            addonTable.QuestLog:Initialize()
            addonTable.QuestLog:CreateHUD()
        end
        
        MPrint("Systems Online: Boss Auto-Tracker, Guild Auditor, & Quest HUD active.")

    elseif event == "ENCOUNTER_START" then
        local _, encounterName = ...
        if addonTable.Tracker then
            addonTable.Tracker:ResetData()
            addonTable.Tracker:StartTimer()
        end
        isTracking = true
        MPrint("Boss Engaged: |cFFFFFF00" .. encounterName .. "|r. Tracking started.")

    elseif event == "ENCOUNTER_END" then
        local _, encounterName, _, _, success = ...
        isTracking = false
        if success == 1 then
            MPrint("Victory! Recording achievement and reporting stats...")
            Screenshot() -- Automatic Boss Kill Capture
            AutoReport()
        end

    elseif event == "PLAYER_TARGET_CHANGED" then
        local targetName = UnitName("target")
        if targetName then
            local classification = UnitClassification("target")
            if classification == "worldboss" or classification == "elite" then
                MPrint("TARGET ACQUIRED: |cFFFF0000" .. targetName .. " (ELITE)|r")
            else
                MPrint("Now Targeting: |cFFFFFF00" .. targetName .. "|r")
            end
        end

    elseif event == "CHAT_MSG_LOOT" then
        local msg, _, _, _, playerName = ...
        -- Market Telemetry: If Auctionator is present, check item value
        local itemLink = string.match(msg, "|Hitem:.-|h%[.-%]|h")
        if itemLink and Auctionator and Auctionator.API then
            local price = Auctionator.API.v1.GetAuctionPriceByItemLink(addonName, itemLink)
            if price and price > 10000 then 
                MPrint("Market Alert: " .. itemLink .. " is worth " .. GetCoinTextureString(price))
            end
        end

        -- Fishing Telemetry: Log coordinates if loot is a fish
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

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and isTracking then
        local _, subevent, _, _, sourceName, sourceFlags, _, _, destName, _, _, amount = CombatLogGetCurrentEventInfo()
        
        -- Bitwise constants for group affiliation
        local MASK_GROUP = COMBATLOG_OBJECT_AFFILIATION_MINE + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_RAID
        
        -- Use the stable bit.band library for Retail
        if bit.band(sourceFlags, MASK_GROUP) ~= 0 then
            if subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
                local damage = (subevent == "SWING_DAMAGE") and amount or select(15, CombatLogGetCurrentEventInfo())
                if damage and sourceName and destName and addonTable.Tracker then
                    addonTable.Tracker:LogGroupDamage(sourceName, destName, damage)
                end
            end
        end
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")