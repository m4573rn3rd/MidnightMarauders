local addonName, addonTable = ...
addonTable.QuestLog = {}

-- 1. Initialize Quest Database
function addonTable.QuestLog:Initialize()
    if not MidnightMaraudersDB.questData then
        MidnightMaraudersDB.questData = {
            completedToday = 0,
            totalCompleted = 0,
            lastReset = date("%Y-%m-%d")
        }
    end

    -- Daily Reset Check
    local today = date("%Y-%m-%d")
    if MidnightMaraudersDB.questData.lastReset ~= today then
        MidnightMaraudersDB.questData.completedToday = 0
        MidnightMaraudersDB.questData.lastReset = today
    end
end

-- 2. Create a Small Quest HUD
function addonTable.QuestLog:CreateHUD()
    if self.hud then return end

    local f = CreateFrame("Frame", "MidnightMaraudersQuestHUD", UIParent, "BackdropTemplate")
    f:SetSize(180, 60)
    f:SetPoint("TOPRIGHT", -200, -100) -- Positioned near the default tracker
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- Styling
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.6)

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetPoint("CENTER", 0, 0)
    f.text:SetJustifyH("LEFT")
    
    self.hud = f
    self:UpdateHUD()
end

-- 3. Update the HUD Text
function addonTable.QuestLog:UpdateHUD()
    if not self.hud then return end
    local data = MidnightMaraudersDB.questData
    local activeQuests = C_QuestLog.GetNumQuestLogEntries()
    
    self.hud.text:SetText(string.format(
        "|cFF00FF00Quests Today:|r %d\n|cFFFFFF00Active:|r %d\n|cFF00FFFFTotal Done:|r %d",
        data.completedToday, activeQuests, data.totalCompleted
    ))
end

-- 4. Event: Quest Turned In
local qFrame = CreateFrame("Frame")
qFrame:RegisterEvent("QUEST_TURNED_IN")
qFrame:SetScript("OnEvent", function(self, event, questID, xpReward, moneyReward)
    MidnightMaraudersDB.questData.completedToday = MidnightMaraudersDB.questData.completedToday + 1
    MidnightMaraudersDB.questData.totalCompleted = MidnightMaraudersDB.questData.totalCompleted + 1
    
    print("|cFF00FF00[MidnightMarauders]|r: Quest Complete! Rewards: " .. GetCoinTextureString(moneyReward))
    addonTable.QuestLog:UpdateHUD()
end)

-- 5. Slash Command
SLASH_MHUD1 = "/mhud"
SlashCmdList["MHUD"] = function()
    if addonTable.QuestLog.hud and addonTable.QuestLog.hud:IsShown() then
        addonTable.QuestLog.hud:Hide()
    elseif addonTable.QuestLog.hud then
        addonTable.QuestLog.hud:Show()
    end
end
