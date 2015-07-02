local GetCurrentBuild, StaticPopup
TalentsaverFu = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "FuBarPlugin-2.0");
local Tablet = AceLibrary("Tablet-2.0");
TalentsaverFu:RegisterDB("TalentsaverFuDB");
TalentsaverFu.hasIcon = "Interface\\AddOns\\Talentsaver\\icons\\default"
TalentsaverFu.clickableTooltip = true

function TalentsaverFu:OnTextUpdate()
	if (self:IsTextShown()) then
		self:ShowText();
        local name, icon = GetCurrentTalentSpec()
        self:SetIcon(icon)
        if GetCurrentBuild() then
            self:SetText("|cff3be7edTalentsaver|r ("..GetCurrentBuild()..")");
        else
            self:SetText("|cff3be7edTalentsaver|r ("..name..")");
        end
	else
		self:HideText();
	end
end

function TalentsaverFu:OnTooltipUpdate()
    Tablet:SetHint("You can delete builds by using |cffeda55f/ts delete <name>|r")
    -- new build
    cat = Tablet:AddCategory(
        'columns', 1,
		'child_textR', 1,
		'child_textG', 1,
		'child_textB', 1
    )
    cat:AddLine()
    cat:AddLine('text', "|cffeda55f< save current Build >|r", 'func', function() StaticPopup() end, 'justify', "CENTER")
    
    -- saved builds
    cat = Tablet:AddCategory(
		'columns', 3,
		'child_textR', 1,
		'child_textG', 1,
		'child_textB', 1
	)
    cat:AddLine()
    cat:AddLine()
    if table.getn(TALENTS_SAVED["LIST"]) == 0 then
        cat:AddLine('text2', "NO SAVED BUILDS FOUND")
    else
        if GetUnspentTalentPoints() == 0 or TALENTSAVER_IsLoading() then
            for b=1, table.getn(TALENTS_SAVED["LIST"]) do
                if TALENTS_SAVED["LIST"][b] == "" then return end
                local name = TALENTS_SAVED["LIST"][b];
                local buildinfo = TALENTS_SAVED["INFO"][name][1].."/"..TALENTS_SAVED["INFO"][name][2].."/"..TALENTS_SAVED["INFO"][name][3];
                if name == GetCurrentBuild() then
                    cat:AddLine(
                        'text', "|cff3be7ed"..b..".|r",
                        'text2', "|cff3be7ed"..buildinfo.."|r",
                        'text3', "|cff3be7ed"..name.."|r"
                    )
                else
                    cat:AddLine(
                        'text', b..".",
                        'text2', buildinfo,
                        'text3', name,
                        'text2R', 1,'text2G', 1,'text2B', 1,
                        'text3R', 1,'text3G', 1,'text3B', 1
                    )
                end
            end
        else -- there are unspent points
            for b=1, table.getn(TALENTS_SAVED["LIST"]) do
                if TALENTS_SAVED["LIST"][b] == "" then return end
                local name = TALENTS_SAVED["LIST"][b];
                local buildinfo = TALENTS_SAVED["INFO"][name][1].."/"..TALENTS_SAVED["INFO"][name][2].."/"..TALENTS_SAVED["INFO"][name][3];
                cat:AddLine(
                    'text', b..".",
                    'text2', buildinfo,
                    'text3', name,
                    'text2R', 1,'text2G', 1,'text2B', 1,
                    'text3R', 1,'text3G', 1,'text3B', 1,
                    'func', function() TALENTSAVER_LOAD(name) end
                )
            end
        end
    end
end

function StaticPopup()
    local first, second, third = GetTalentPointsSpent()
    local spec = GetCurrentTalentSpec()
    StaticPopupDialogs["SAVE_BUILD"] = {
        text = "|cff3be7edName|r of the Build: ("..first.."/"..second.."/"..third..") ",
        button1 = "Save",
        button2 = "Cancel",
        hasEditBox = 1,
        OnShow = function()
            StaticPopup1EditBox:SetText(spec)
        end,
        OnAccept = function()
            TALENTSAVER_SAVE(StaticPopup1EditBox:GetText())
        end,
        OnHide = function() end,
        OnCancel = function() end,
        EditBoxOnEscapePressed = function() this:GetParent():Hide(); end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
    };

    StaticPopup_Show("SAVE_BUILD")
end

function TalentsaverFu:OnClick()
    
end

    -- ====== API ====== --
function GetCurrentBuild()
    local build
    if TALENTS_SAVED.CURRENTBUILD ~= "" then
        local first, second, third = GetTalentPointsSpent()
        if first ~= TALENTS_SAVED["INFO"][TALENTS_SAVED.CURRENTBUILD][1] 
            or second ~= TALENTS_SAVED["INFO"][TALENTS_SAVED.CURRENTBUILD][2] 
            or third ~= TALENTS_SAVED["INFO"][TALENTS_SAVED.CURRENTBUILD][3] then
            -- seems like the player has a build which was not loaded via the addon
            build = GetCurrentTalentSpec()
        else
            build = TALENTS_SAVED.CURRENTBUILD
        end
    else
        -- if no build is selected display the current spec
        build = GetCurrentTalentSpec()
    end
    return build
end
function GetCurrentTalentSpec()
    local name = ""
    local icon = ""
    local points = {}
    for i=1,3 do
        local _, _, spent = GetTalentTabInfo(i)
        points[i] = spent;
    end
    local specInit = {
        ["Warrior"] = {"Arms","Fury","Protection"},
        ["Paladin"] = {"Holy","Protection","Retribution"},
        ["Rogue"] = {"Assassination","Combat","Subtlety"},
        ["Druid"] = {"Balance","Feral","Restoration"},
        ["Shaman"] = {"Elemental","Enhancement","Restoration"},
        ["Priest"] = {"Disci","Holy","Shadow"},
        ["Warlock"] = {"Affliction","Demonology","Destruction"},
        ["Mage"] = {"Arcane","Fire","Frost"},
        ["Hunter"] = {"Beastmaster","Marksmanship","Survival"},
    }
    if points[1] == 0 and points[2] == 0 and points[3] == 0 then
        return "unskilled", "Interface\\AddOns\\Talentsaver\\icons\\default"
    elseif points[1] >= points[2] and points[1] >= points[3] then
        name = specInit[UnitClass('player')][1]
    elseif points[2] >= points[1] and points[2] >= points[3] then
        name = specInit[UnitClass('player')][2]
    elseif points[3] >= points[1] and points[3] >= points[2] then
        name = specInit[UnitClass('player')][3]
    end
    
    icon = GetTalentSpecIcon(UnitClass('player'),name)
    return name, icon
end
function GetTalentSpecIcon(class,spec)
    local iconpath = "Interface\\AddOns\\Talentsaver\\icons\\";
    if class == "Shaman" then
        if spec == "Restoration" then
            return iconpath.."restoShamy";
        else
            return iconpath..spec;
        end
    elseif class == "Druid" then
        if spec == "Restoration" then
            return iconpath.."restoDruid";
        else
            return iconpath..spec;
        end
    elseif class == "Paladin" then
        if spec == "Protection" then
            return iconpath.."protPally";
        else
            return iconpath..spec;
        end
    elseif class == "Hunter" then
        if spec == "Marksmanship" then
            return iconpath.."default";
        else
            return iconpath..spec;
        end
    elseif class == "Warrior" then
        if spec == "Protection" then
            return iconpath.."protWarr";
        else
            return iconpath..spec;
        end
    else
        return iconpath..spec;
    end
end
function GetTalentPointsSpent()
    local points = {}
    for i=1,3 do
        local _, _, spent = GetTalentTabInfo(i)
        points[i] = spent;
    end
    return points[1], points[2], points[3] 
end
function GetUnspentTalentPoints()
    local first, second, third = GetTalentPointsSpent()
    local unspent = (UnitLevel("player")-9) - (first + second + third)
    return unspent
end