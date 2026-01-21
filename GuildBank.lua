local addonName, addonTable = ...
addonTable.GuildTracker = {}

-- 1. Initialize Database
function addonTable.GuildTracker:Initialize()
    if not MidnightMaraudersDB then MidnightMaraudersDB = {} end
    if not MidnightMaraudersDB.guildContributions then
        MidnightMaraudersDB.guildContributions = { totalGold = 0, history = {} }
    end
end

-- 2. Log the Deposit
function addonTable.GuildTracker:LogDeposit(amount)
    if not amount or amount <= 0 then return end
    local contribution = {
        date = date("%Y-%m-%d %H:%M"),
        amount = amount,
        zone = GetRealZoneText()
    }
    MidnightMaraudersDB.guildContributions.totalGold = (MidnightMaraudersDB.guildContributions.totalGold or 0) + amount
    table.insert(MidnightMaraudersDB.guildContributions.history, contribution)
    
    print("|cFF00FF00[MidnightMarauders]|r: Logged deposit: " .. GetCoinTextureString(amount))
    
    if self.frame and self.frame:IsShown() then 
        self:UpdateUI() 
    end
end

-- 3. Tab Logic
local function Tab_OnClick(self)
    local f = self:GetParent()
    PanelTemplates_SetTab(f, self:GetID())
    
    -- Hide all panels
    f.guildPanel:Hide()
    f.historyPanel:Hide()
    f.questPanel:Hide()

    -- Show selected panel
    if self:GetID() == 1 then
        f.guildPanel:Show()
    elseif self:GetID() == 2 then
        f.historyPanel:Show()
    elseif self:GetID() == 3 then
        f.questPanel:Show()
    end
end

-- 4. Create the Main Window with Tabs
function addonTable.GuildTracker:CreateUI()
    if self.frame then return end

    -- Main Frame
    local f = CreateFrame("Frame", "MidnightMaraudersMainUI", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(400, 420)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 0, 0)
    f.title:SetText("MidnightMarauders")

    -- GUILD PANEL (Tab 1)
    f.guildPanel = CreateFrame("Frame", nil, f)
    f.guildPanel:SetAllPoints()
    f.guildPanel.total = f.guildPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.guildPanel.total:SetPoint("TOP", f, "TOP", 0, -40)
    
    f.guildPanel.scroll = CreateFrame("ScrollFrame", nil, f.guildPanel, "UIPanelScrollFrameTemplate")
    f.guildPanel.scroll:SetPoint("TOPLEFT", 10, -70)
    f.guildPanel.scroll:SetPoint("BOTTOMRIGHT", -30, 40)
    
    f.guildPanel.content = CreateFrame("Frame", nil, f.guildPanel.scroll)
    f.guildPanel.content:SetSize(360, 1)
    f.guildPanel.scroll:SetScrollChild(f.guildPanel.content)
    
    f.guildPanel.text = f.guildPanel.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.guildPanel.text:SetPoint("TOPLEFT", 5, -5)
    f.guildPanel.text:SetJustifyH("LEFT")
    f.guildPanel.text:SetWidth(350)

    -- PERFORMANCE PANEL (Tab 2)
    f.historyPanel = CreateFrame("Frame", nil, f)
    f.historyPanel:SetAllPoints()
    f.historyPanel.title = f.historyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.historyPanel.title:SetPoint("TOP", f, "TOP", 0, -40)
    f.historyPanel.title:SetText("Combat Performance")
    f.historyPanel.text = f.historyPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.historyPanel.text:SetPoint("TOP", 0, -100)
    f.historyPanel.text:SetText("Detailed combat logs will appear here.")
    f.historyPanel:Hide()

    -- QUEST PANEL (Tab 3)
    f.questPanel = CreateFrame("Frame", nil, f)
    f.questPanel:SetAllPoints()
    f.questPanel.title = f.questPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.questPanel.title:SetPoint("TOP", f, "TOP", 0, -40)
    f.questPanel.title:SetText("Quest Telemetry")
    f.questPanel.text = f.questPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.questPanel.text:SetPoint("TOP", 0, -100)
    f.questPanel.text:SetText("Quest progress tracking active.")
    f.questPanel:Hide()

    -- TAB SYSTEM
    f.tab1 = CreateFrame("Button", "$parentTab1", f, "CharacterFrameTabButtonTemplate")
    f.tab1:SetID(1)
    f.tab1:SetText("Guild")
    f.tab1:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, -30)
    f.tab1:SetScript("OnClick", Tab_OnClick)

    f.tab2 = CreateFrame("Button", "$parentTab2", f, "CharacterFrameTabButtonTemplate")
    f.tab2:SetID(2)
    f.tab2:SetText("History")
    f.tab2:SetPoint("LEFT", f.tab1, "RIGHT", -15, 0)
    f.tab2:SetScript("OnClick", Tab_OnClick)

    f.tab3 = CreateFrame("Button", "$parentTab3", f, "CharacterFrameTabButtonTemplate")
    f.tab3:SetID(3)
    f.tab3:SetText("Quests")
    f.tab3:SetPoint("LEFT", f.tab2, "RIGHT", -15, 0)
    f.tab3:SetScript("OnClick", Tab_OnClick)

    PanelTemplates_SetNumTabs(f, 3)
    PanelTemplates_SetTab(f, 1)

    self.frame = f
end

-- 5. Update UI Content
function addonTable.GuildTracker:UpdateUI()
    if not self.frame then return end
    
    -- Update Guild Data
    local data = MidnightMaraudersDB.guildContributions
    self.frame.guildPanel.total:SetText("Total Contributed: " .. GetCoinTextureString(data.totalGold or 0))
    local historyStr = ""
    if #data.history == 0 then
        historyStr = "No deposits found."
    else
        for i = #data.history, 1, -1 do
            local entry = data.history[i]
            historyStr = historyStr .. string.format("[%s] %s\n(%s)\n\n", entry.date, GetCoinTextureString(entry.amount), entry.zone)
        end
    end
    self.frame.guildPanel.text:SetText(historyStr)
    
    -- Update Quest Data (If QuestLog exists)
    if addonTable.QuestLog and addonTable.QuestLog.UpdateHUD then
        local qData = MidnightMaraudersDB.questData
        if qData then
            self.frame.questPanel.text:SetText(string.format(
                "Quests Today: %d\nTotal Quests Done: %d", 
                qData.completedToday, qData.totalCompleted
            ))
        end
    end
end

-- 6. Slash Command Setup
SLASH_MGUILD1 = "/mguild"
SlashCmdList["MGUILD"] = function()
    addonTable.GuildTracker:CreateUI()
    if addonTable.GuildTracker.frame:IsShown() then
        addonTable.GuildTracker.frame:Hide()
    else
        addonTable.GuildTracker:UpdateUI()
        addonTable.GuildTracker.frame:Show()
    end
end

-- 7. Hooking Logic for Guild Bank
local eFrame = CreateFrame("Frame")
eFrame:RegisterEvent("ADDON_LOADED")
eFrame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == "Blizzard_GuildBankUI" then
        C_Timer.After(1, function()
            if GuildBankFrameDepositButton_OnClick then
                hooksecurefunc("GuildBankFrameDepositButton_OnClick", function()
                    if GuildBankMoneyDepositValue then
                        local money = MoneyInputFrame_GetCopper(GuildBankMoneyDepositValue)
                        if money and money > 0 then
                            addonTable.GuildTracker:LogDeposit(money)
                        end
                    end
                end)
            end
        end)
    end
end)