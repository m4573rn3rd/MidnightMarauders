local addonName, addonTable = ...
addonTable.TrackerGUI = {}

function addonTable.TrackerGUI:Create()
    if self.frame then return end

    local f = CreateFrame("Frame", "MidnightMaraudersTrackerGUI", UIParent, "BackdropTemplate")
    f:SetSize(200, 100)
    f:SetPoint("CENTER", -200, 200)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile = "Interface\ChatFrame\ChatFrameBackground",
        edgeFile = "Interface\Tooltips\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.8)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("MidnightMarauders Tracker")

    f.dpsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.dpsLabel:SetPoint("CENTER", 0, 10)
    f.dpsLabel:SetText("Group DPS: 0")

    f.startButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.startButton:SetSize(80, 25)
    f.startButton:SetPoint("BOTTOMLEFT", 10, 10)
    f.startButton:SetText("Start")
    f.startButton:SetScript("OnClick", function()
        addonTable.Tracker:SetTracking(true)
    end)
    
    f.stopButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.stopButton:SetSize(80, 25)
    f.stopButton:SetPoint("BOTTOMRIGHT", -10, 10)
    f.stopButton:SetText("Stop")
    f.stopButton:SetScript("OnClick", function()
        addonTable.Tracker:SetTracking(false)
    end)
    
    self.frame = f
    self:Update()
end

function addonTable.TrackerGUI:Update()
    if not self.frame or not self.frame:IsShown() then return end
    
    local groupDPS = 0
    if addonTable.Tracker and addonTable.Tracker.IsTracking() then
        local stats = addonTable.Tracker:GetRankedStats()
        for _, player in ipairs(stats) do
            groupDPS = groupDPS + player.dps
        end
    end
    self.frame.dpsLabel:SetText(string.format("Group DPS: %d", groupDPS))
end

local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    if addonTable.TrackerGUI then
        addonTable.TrackerGUI:Update()
    end
end)
