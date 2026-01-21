local addonName, addonTable = ...
local coreFrame = CreateFrame("Frame")

local function MPrint(msg)
    print("|cFF00FF00[MidnightMarauders]|r: " .. msg)
end

coreFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        if addonTable.Tracker and addonTable.Tracker.Initialize then
            addonTable.Tracker:Initialize()
        end
        if addonTable.GuildTracker and addonTable.GuildTracker.Initialize then
            addonTable.GuildTracker:Initialize()
        end
        if addonTable.QuestLog and addonTable.QuestLog.Initialize then
            addonTable.QuestLog:Initialize()
            addonTable.QuestLog:CreateHUD()
        end
        if addonTable.TrackerGUI and addonTable.TrackerGUI.Create then
            addonTable.TrackerGUI:Create()
        end
        MPrint("Systems Online: Boss Auto-Tracker, Guild Auditor, & Quest HUD active.")
    elseif event == "ENCOUNTER_START" then
        if addonTable.Tracker and addonTable.Tracker.ResetData then
            addonTable.Tracker:ResetData()
            addonTable.Tracker:StartTimer()
            addonTable.Tracker:SetTracking(true)
        end
    elseif event == "ENCOUNTER_END" then
        if addonTable.Tracker and addonTable.Tracker.SetTracking then
            addonTable.Tracker:SetTracking(false)
            local encounterName, _, _, _, success = ...
            if success == 1 then
                MPrint("Victory! Recording achievement and reporting stats...")
                Screenshot() 
                if addonTable.Tracker.AutoReport then
                    addonTable.Tracker:AutoReport()
                end
                
                local stats, _, duration = addonTable.Tracker:GetRankedStats()
                if #stats > 0 then
                    local encounterData = {
                        encounterName = encounterName,
                        duration = duration,
                        players = stats
                    }
                    table.insert(MidnightMaraudersDB.combatHistory, encounterData)
                end
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if addonTable.Tracker and addonTable.Tracker.TargetChanged then
            addonTable.Tracker:TargetChanged()
        end
    elseif event == "CHAT_MSG_LOOT" then
        if addonTable.Tracker and addonTable.Tracker.LootMessage then
            addonTable.Tracker:LootMessage(...)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if addonTable.Tracker and addonTable.Tracker.IsTracking() then
            addonTable.Tracker:CombatLog(...)
        end
    end
end)

coreFrame:RegisterEvent("ADDON_LOADED")
coreFrame:RegisterEvent("ENCOUNTER_START")
coreFrame:RegisterEvent("ENCOUNTER_END")
coreFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
coreFrame:RegisterEvent("CHAT_MSG_LOOT")
coreFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
