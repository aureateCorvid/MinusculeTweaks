-- Minuscule Tweaks for WoW 3.3.5a
-- Four small UI improvements, each toggleable from the AddOns Interface Options tab.
-- All features default to on.

local addonName = "MinusculeTweaks"

local defaults = {
    chatEdit     = true,
    classColors  = true,
    statusText   = true,
    specTooltip  = true,
}

local db

local function InitDB()
    MinusculeTweaksDB = MinusculeTweaksDB or {}
    for k, v in pairs(defaults) do
        if MinusculeTweaksDB[k] == nil then
            MinusculeTweaksDB[k] = v
        end
    end
    db = MinusculeTweaksDB
end

---------------------------------------------------------------------
-- Options panel
---------------------------------------------------------------------
local panel = CreateFrame("Frame", "MinusculeTweaksOptionsPanel", UIParent)
panel.name = "Minuscule Tweaks"

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Minuscule Tweaks")

-- Subtitle / description
local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
subtitle:SetText("Small UI improvements. Changes take effect after a reload.")
subtitle:SetWidth(500)
subtitle:SetJustifyH("LEFT")

local function CreateCheckbox(parent, name, label, tooltip, key, y)
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    local text = _G[cb:GetName() .. "Text"]
    text:SetText(label)
    text:SetTextColor(1, 1, 1)
    cb.tooltipText = tooltip
    cb.key = key
    cb:SetScript("OnClick", function(self)
        db[self.key] = self:GetChecked() and true or false
        if self.key == "chatEdit" then
            ApplyChatEditMode()
        end
        if self.key == "classColors" then
            if not db.classColors then
                -- best-effort restore; full reverse is limited
                if ClassColorPlayerBG then ClassColorPlayerBG:Hide() end
            else
                if ClassColorPlayerBG then ClassColorPlayerBG:Show() end
            end
        end
    end)
    return cb
end

local checkboxes = {}

panel.refresh = function()
    for _, cb in ipairs(checkboxes) do
        cb:SetChecked(db[cb.key])
    end
end

panel.default = function()
    for k, v in pairs(defaults) do
        db[k] = v
    end
    panel.refresh()
    ApplyChatEditMode()
end

-- Reload UI button
local reloadBtn = CreateFrame("Button", "MinusculeTweaksReloadButton", panel, "UIPanelButtonTemplate")
reloadBtn:SetSize(120, 22)
reloadBtn:SetPoint("BOTTOMLEFT", 16, 16)
reloadBtn:SetText("Reload UI")
reloadBtn:SetScript("OnClick", function()
    ReloadUI()
end)

InterfaceOptions_AddCategory(panel)

---------------------------------------------------------------------
-- 1. Chat Edit Fix
---------------------------------------------------------------------
local function EnableNormalArrows(editBox)
    if not editBox then return end
    editBox:SetAltArrowKeyMode(not db.chatEdit)
end

local function FindWordBoundary(text, pos, direction)
    if direction > 0 then
        local start = text:find("%s*%S", pos + 1)
        if start then return start - 1 else return #text end
    else
        local sub = text:sub(1, pos)
        local last = sub:match(".*%s%S")
        if last then return #last else return 0 end
    end
end

local function OnKeyDown(self, key)
    if not db.chatEdit then return end
    if not IsControlKeyDown() then return end

    local text = self:GetText() or ""
    local pos = self:GetCursorPosition()

    if key == "LEFT" then
        local newPos = FindWordBoundary(text, pos, -1)
        if IsShiftKeyDown() then
            local start, finish = self:GetTextHighlight() or pos, pos
            self:HighlightText(math.min(start, newPos), math.max(finish, newPos))
        else
            self:HighlightText(0, 0)
        end
        self:SetCursorPosition(newPos)
    elseif key == "RIGHT" then
        local newPos = FindWordBoundary(text, pos, 1)
        if IsShiftKeyDown() then
            local start, finish = self:GetTextHighlight() or pos, pos
            self:HighlightText(math.min(start, newPos), math.max(finish, newPos))
        else
            self:HighlightText(0, 0)
        end
        self:SetCursorPosition(newPos)
    end
end

local function SetupEditBox(editBox)
    if not editBox or editBox._MinusculeChat then return end
    editBox._MinusculeChat = true
    EnableNormalArrows(editBox)
    editBox:HookScript("OnKeyDown", OnKeyDown)
end

function ApplyChatEditMode()
    for i = 1, NUM_CHAT_WINDOWS do
        local eb = _G["ChatFrame" .. i .. "EditBox"]
        if eb then
            EnableNormalArrows(eb)
        end
    end
end

---------------------------------------------------------------------
-- 2. Class Color Frames
---------------------------------------------------------------------
local GRAY = { r = 0.5, g = 0.5, b = 0.5 }

local function GetUnitClassColor(unit)
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        return (class and RAID_CLASS_COLORS[class]) or GRAY
    end
end

local ClassColorPlayerBG = PlayerFrame:CreateTexture("MinusculeClassColorPlayerBG", "BORDER")
ClassColorPlayerBG:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
ClassColorPlayerBG:SetWidth(119)
ClassColorPlayerBG:SetHeight(19)
ClassColorPlayerBG:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 106, -22)

local function UpdatePlayer()
    if not db.classColors then
        ClassColorPlayerBG:Hide()
        return
    end
    ClassColorPlayerBG:Show()
    local c = GetUnitClassColor("player") or GRAY
    ClassColorPlayerBG:SetVertexColor(c.r, c.g, c.b, 1)
end

hooksecurefunc("TargetFrame_CheckFaction", function(self)
    if not db.classColors then return end
    local c = GetUnitClassColor(self.unit)
    if c and self.nameBackground then
        self.nameBackground:SetVertexColor(c.r, c.g, c.b, 1)
    end
end)

local function UpdateToT()
    if not db.classColors then return end
    local totName = _G["TargetFrameToTTextureFrameName"]
    if totName then
        local c = GetUnitClassColor("targettarget") or GRAY
        totName:SetTextColor(c.r, c.g, c.b)
    end
    local fotName = _G["FocusFrameToTTextureFrameName"]
    if fotName then
        local c = GetUnitClassColor("focustarget") or GRAY
        fotName:SetTextColor(c.r, c.g, c.b)
    end
end

local function UpdateParty()
    if not db.classColors then return end
    for i = 1, MAX_PARTY_MEMBERS do
        local name = _G["PartyMemberFrame" .. i .. "Name"]
        if name then
            local c = GetUnitClassColor("party" .. i) or GRAY
            name:SetTextColor(c.r, c.g, c.b)
        end
    end
end

hooksecurefunc("PartyMemberFrame_UpdateMember", UpdateParty)

local classColorFrame = CreateFrame("Frame")
classColorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
classColorFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
classColorFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
classColorFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
classColorFrame:RegisterEvent("UNIT_TARGET")
classColorFrame:SetScript("OnEvent", function()
    UpdatePlayer()
    UpdateParty()
    UpdateToT()
    if db.classColors then
        if UnitExists("target") then TargetFrame_CheckFaction(TargetFrame) end
        if UnitExists("focus") and FocusFrame then TargetFrame_CheckFaction(FocusFrame) end
    end
end)

---------------------------------------------------------------------
-- 3. Custom Status Text
---------------------------------------------------------------------
local currentPercentBars = {
    PlayerFrameHealthBar = true,
    PlayerFrameManaBar = true,
    TargetFrameHealthBar = true,
    TargetFrameManaBar = true,
}

local percentOnlyBars = {
    PetFrameHealthBar = true,
    PetFrameManaBar = true,
    FocusFrameHealthBar = true,
    FocusFrameManaBar = true,
}

for i = 1, 4 do
    percentOnlyBars["PartyMemberFrame" .. i .. "HealthBar"] = true
    percentOnlyBars["PartyMemberFrame" .. i .. "ManaBar"] = true
end

local function ShouldShowPrefix(statusBar)
    if not statusBar.prefix then return false end
    if statusBar.alwaysPrefix then return true end
    if statusBar.cvar and GetCVar(statusBar.cvar) == "1" and statusBar.textLockable then return false end
    return true
end

local function FormatValue(value, statusBar)
    if statusBar.capNumericDisplay then
        return TextStatusBar_CapDisplayOfNumericValue(value)
    end
    return tostring(value)
end

local function GetUnitForBar(statusBar)
    local name = statusBar:GetName()
    if name == "TargetFrameHealthBar" or name == "TargetFrameManaBar" then return "target"
    elseif name == "PlayerFrameHealthBar" or name == "PlayerFrameManaBar" then return "player"
    elseif name == "PetFrameHealthBar" or name == "PetFrameManaBar" then return "pet"
    elseif name == "FocusFrameHealthBar" or name == "FocusFrameManaBar" then return "focus"
    else
        local partyIndex = name:match("PartyMemberFrame(%d)")
        if partyIndex then return "party" .. partyIndex end
    end
    return nil
end

local function ScaleFocusHealth(textString)
    if not textString then return end
    local font, size, flags = textString:GetFont()
    if not textString.cstOriginalSize then
        textString.cstOriginalSize = size or 10
    end
    textString:SetFont(font, textString.cstOriginalSize * 0.75, flags)
end

hooksecurefunc("TextStatusBar_UpdateTextString", function(statusBar)
    if not db.statusText then return end
    if not statusBar then return end

    local barName = statusBar:GetName()
    local isCurrentPercent = currentPercentBars[barName]
    local isPercentOnly = percentOnlyBars[barName]
    if not isCurrentPercent and not isPercentOnly then return end

    local textString = statusBar.TextString
    if not textString then return end

    local unit = GetUnitForBar(statusBar)
    local isTargetHealth = (barName == "TargetFrameHealthBar")
    local isTargetPower  = (barName == "TargetFrameManaBar")
    local isPlayerHealth = (barName == "PlayerFrameHealthBar")
    local isPlayerPower  = (barName == "PlayerFrameManaBar")
    local isFocusHealth  = (barName == "FocusFrameHealthBar")
    local isPartyHealth  = barName:match("^PartyMemberFrame%d+HealthBar") ~= nil
    local isPetHealth    = (barName == "PetFrameHealthBar")

    local isDead = unit and UnitExists(unit) and UnitIsDead(unit)
    local isGhost = unit and UnitExists(unit) and UnitIsGhost(unit)
    local isDeadOrGhost = isDead or isGhost

    if isFocusHealth then
        ScaleFocusHealth(textString)
    end

    if isPetHealth and isDead then
        textString:SetText("Dead")
        textString:Show()
        return
    end

    if isFocusHealth and isDead then
        textString:SetText("")
        textString:Hide()
        return
    end

    if isTargetHealth and isDead then
        textString:SetText("")
        textString:Hide()
        return
    end

    if (isTargetHealth or isPartyHealth or isFocusHealth or isPlayerHealth) and isGhost then
        textString:SetText("Ghost")
        textString:Show()
        return
    end

    if isTargetPower and isDeadOrGhost then
        local _, valueMax = statusBar:GetMinMaxValues()
        if valueMax and valueMax > 0 and textString:IsShown() then
            local text = ShouldShowPrefix(statusBar) and (statusBar.prefix .. " 0%") or "0%"
            textString:SetText(text)
        else
            textString:SetText("")
        end
        return
    end

    if isPlayerPower and isGhost then
        local _, valueMax = statusBar:GetMinMaxValues()
        if valueMax and valueMax > 0 then
            local text = ShouldShowPrefix(statusBar) and (statusBar.prefix .. " 0%") or "0%"
            textString:SetText(text)
            textString:Show()
        end
        return
    end

    if not textString:IsShown() then return end
    if statusBar.isZero and statusBar.zeroText and textString:GetText() == statusBar.zeroText then return end

    local value = statusBar:GetValue()
    local _, valueMax = statusBar:GetMinMaxValues()
    if not value or not valueMax or valueMax <= 0 then return end

    local percent = math.ceil((value / valueMax) * 100)
    local text
    if isPercentOnly then
        text = ShouldShowPrefix(statusBar) and (statusBar.prefix .. " " .. percent .. "%") or (percent .. "%")
    else
        local displayValue = FormatValue(value, statusBar)
        text = ShouldShowPrefix(statusBar)
            and (statusBar.prefix .. " " .. displayValue .. " (" .. percent .. "%)")
            or (displayValue .. " (" .. percent .. "%)")
    end
    textString:SetText(text)
end)

local statusFrame = CreateFrame("Frame")
statusFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
statusFrame:SetScript("OnEvent", function()
    if not db.statusText then return end
    local function updateBar(barName)
        local bar = _G[barName]
        if bar then TextStatusBar_UpdateTextString(bar) end
    end
    for barName in pairs(currentPercentBars) do updateBar(barName) end
    for barName in pairs(percentOnlyBars) do updateBar(barName) end
end)

---------------------------------------------------------------------
-- 4. Spec Tooltip
---------------------------------------------------------------------
local specCache = {}
local specCurrent = {}
local CACHE_SIZE = 25
local specAddon = CreateFrame("Frame", "MinusculeSpecTooltip")

local function GetSpecString(isInspect)
    local group = GetActiveTalentGroup(isInspect)
    local maxPoints = 0
    local trees = {}
    for i = 1, 3 do
        local name, _, points = GetTalentTabInfo(i, isInspect, nil, group)
        trees[i] = { name = name or "?", points = points or 0 }
        if points and points > maxPoints then maxPoints = points end
    end
    if maxPoints == 0 then return "No Spec" end
    local tied = {}
    for i = 1, 3 do
        if trees[i].points == maxPoints then
            tied[#tied + 1] = trees[i].name
        end
    end
    return #tied == 1 and tied[1] or table.concat(tied, "/")
end

local function UpdatePlayerInfoLine(tooltip, unit, spec)
    if not tooltip or not unit or not spec then return end
    local level = UnitLevel(unit)
    local levelStr = (level == -1) and "??" or tostring(level)
    local race = UnitRace(unit) or ""
    local class = UnitClass(unit) or ""
    local newText = string.format("%s %s %s %s %s (%s)",
        LEVEL or "Level", levelStr, race, spec, class, PLAYER or "Player")
    for i = 2, tooltip:NumLines() do
        local left = _G["GameTooltipTextLeft" .. i]
        if left then
            local text = left:GetText() or ""
            if text:find("^" .. (LEVEL or "Level") .. " ") and text:find("%(" .. (PLAYER or "Player") .. "%)") then
                left:SetText(newText)
                if not tooltip.fadeOut then tooltip:Show() end
                return true
            end
        end
    end
    return false
end

local function GatherAndUpdate(isInspect)
    local spec = GetSpecString(isInspect)
    specCurrent.spec = spec
    local _, unit = GameTooltip:GetUnit()
    if not unit then
        local focus = GetMouseFocus()
        if focus and focus.unit then unit = focus.unit end
    end
    if unit and UnitName(unit) == specCurrent.name then
        UpdatePlayerInfoLine(GameTooltip, unit, spec)
    end
    for i = #specCache, 1, -1 do
        if specCache[i].name == specCurrent.name then
            table.remove(specCache, i)
            break
        end
    end
    if #specCache >= CACHE_SIZE then table.remove(specCache, 1) end
    if CACHE_SIZE > 0 then
        specCache[#specCache + 1] = { name = specCurrent.name, spec = spec }
    end
end

specAddon:SetScript("OnEvent", function(self)
    self:UnregisterEvent("INSPECT_TALENT_READY")
    if db.specTooltip and specCurrent.name and GameTooltip:GetUnit() == specCurrent.name then
        GatherAndUpdate(true)
    end
end)

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    if not db.specTooltip then return end
    local _, unit = self:GetUnit()
    if not unit then
        local focus = GetMouseFocus()
        if focus and focus.unit then unit = focus.unit end
    end
    if not unit or not UnitIsPlayer(unit) then return end
    local level = UnitLevel(unit)
    if level ~= -1 and level <= 9 then return end
    if not CanInspect(unit) then return end

    wipe(specCurrent)
    specCurrent.name = UnitName(unit)
    specCurrent.unit = unit

    if UnitIsUnit(unit, "player") then
        GatherAndUpdate(false)
        return
    end

    for _, entry in ipairs(specCache) do
        if entry.name == specCurrent.name then
            UpdatePlayerInfoLine(self, unit, entry.spec)
            specCurrent.spec = entry.spec
            return
        end
    end

    local allowInspect = (not InspectFrame or not InspectFrame:IsShown()) and (not Examiner or not Examiner:IsShown())
    if allowInspect then
        specAddon:RegisterEvent("INSPECT_TALENT_READY")
        NotifyInspect(unit)
        UpdatePlayerInfoLine(self, unit, "...")
    end
end)

---------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" and arg == addonName then
        InitDB()
        -- build checkboxes after db exists
        checkboxes[1] = CreateCheckbox(panel, "MinusculeTweaksChatEdit", "Chat Edit Fix",
            "Normal arrow-key cursor movement, selection, and word jumping in the chat input box. Remembers the last message sent.",
            "chatEdit", -72)
        checkboxes[2] = CreateCheckbox(panel, "MinusculeTweaksClassColors", "Class Color Frames",
            "Colors name backgrounds / text by class on player, target, focus, party, and target-of-target frames.",
            "classColors", -104)
        checkboxes[3] = CreateCheckbox(panel, "MinusculeTweaksStatusText", "Custom Status Text",
            "Player & Target show Current (Percentage). Party, Pet & Focus show percentage only. Shows \"Ghost\" on ghost units.",
            "statusText", -136)
        checkboxes[4] = CreateCheckbox(panel, "MinusculeTweaksSpecTooltip", "Spec Tooltip",
            "Inserts primary talent spec into player tooltips (Level Race Spec Class).",
            "specTooltip", -168)
        panel.refresh()
    elseif event == "PLAYER_LOGIN" then
        -- Apply chat edit mode and set up edit boxes
        for i = 1, NUM_CHAT_WINDOWS do
            local eb = _G["ChatFrame" .. i .. "EditBox"]
            if eb then SetupEditBox(eb) end
        end
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            for i = 1, NUM_CHAT_WINDOWS do
                local eb = _G["ChatFrame" .. i .. "EditBox"]
                if eb then SetupEditBox(eb) end
            end
        end)
        ApplyChatEditMode()
    end
end)
