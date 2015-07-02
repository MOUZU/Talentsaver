TALENTSAVER_VERSION = 1.4

	-- INIT some vars, which are needed for the loading process
    local vars = {
            isLoading = false,
            firstCall = true,
            
            Name = nil,     -- current Build Name to load
            tab = 1,        -- current Tree
            int = 1,        -- current Talent in this Tree
            lastLoad = 0,   -- the time when the last point was spent in the loading process
    }
local Save, Delete, Init, StaticPopup, Increment, ResetVars, SendMSG
function SendMSG(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end

function Init()
	if TALENTS_SAVED == nil then
		TALENTS_SAVED = {
			VERSION = TALENTSAVER_VERSION,
            CURRENTBUILD = "",
			DELAY = -1,
			["LIST"] = {},
			["BUILDS"] = {},
			["INFO"] = {},
		}
	else
        -- ====== UPDATE VARIABLES ====== --
        
		if TALENTS_SAVED.VERSION < TALENTSAVER_VERSION then -- new version loaded now
            if TALENTS_SAVED.VERSION < 1.2 then
				-- we're formating it from 1.0 or 1.1 to 1.2
				for i=1,table.getn(TALENTS_SAVED["LIST"]) do
					local name = TALENTS_SAVED["LIST"][i]
				-- formatting the build info
					local oldstring = TALENTS_SAVED["INFO"][name]
					local first = string.find(oldstring,"/")
					local tab1 = tonumber(string.sub(oldstring,1,first-1))
					oldstring = string.sub(oldstring,first+1)
					local second = string.find(oldstring,"/")
					local tab2 = tonumber(string.sub(oldstring,1,second-1))
					oldstring = string.sub(oldstring,second+1)
					local tab3 = tonumber(oldstring)
					local overall = tab1 + tab2 + tab3
					TALENTS_SAVED["INFO"][name] = {tab1, tab2, tab3, overall}
					if name ~= "" then
						local newbuild = {[1] = {},[2] = {},[3] = {},}
						local template = TALENTS_SAVED["BUILDS"][name]
						for line=1,table.getn(template) do
							local treeNR = tonumber(string.sub(tostring(template[line]),1,1));
							local talentNR = tonumber(string.sub(tostring(template[line]),2));
							newbuild[treeNR][table.getn(newbuild[treeNR])+1] = talentNR
						end
						TALENTS_SAVED["BUILDS"][name] = newbuild
					end
				end
			end
			if TALENTS_SAVED.VERSION < 1.3 then
				-- we're formating it from 1.2 to 1.3
				for i=1,table.getn(TALENTS_SAVED["LIST"]) do
					local name = TALENTS_SAVED["LIST"][i]					
					if name ~= "" then
						local newbuild = {[1] = {},[2] = {},[3] = {},}
						local template = TALENTS_SAVED["BUILDS"][name]
						for tree=1,3 do
							for x=1,GetNumTalents(tree) do
								local points = 0
								for pt=1,table.getn(template[tree]) do
									if template[tree][pt] == x then
										points = points + 1
									end
								end
								newbuild[tree][x] = points
							end
						end
						TALENTS_SAVED["BUILDS"][name] = newbuild
					end
				end
			end
            if TALENTS_SAVED.VERSION < 1.4 then
                TALENTS_SAVED.CURRENTBUILD = ""
            end
			TALENTS_SAVED.VERSION = TALENTSAVER_VERSION
		end
	end
end

	-- ====== CORE FUNCTIONS ====== --
function TALENTSAVER_SAVE(name)
    -- check if a build with that name already exists
    if TALENTS_SAVED["BUILDS"][name] then
        SendMSG("|cff3be7ed[Talentsaver]|r - Template couldn't be saved. There is already a template named '"..name.."'")
        return
    end
    
    -- check if there aren't any points spent
    local first, second, third = GetTalentPointsSpent()
    if first == 0 and second == 0 and third == 0 then 
        SendMSG("|cff3be7ed[Talentsaver]|r - Template couldn't be saved. You haven't spent any Talent Points.")
        return 
    end
    
    Save(name)
end
function Save(name)
	local template = {[1] = {},[2] = {},[3] = {},}
	for i=1,3 do
		for t=1,GetNumTalents(i) do
            if GetTalentInfo(i,t) ~= nil then
                local _, _, _, _, spent = GetTalentInfo(i,t)
                template[i][t] = spent;
            end
		end
	end
    local first, second, third = GetTalentPointsSpent()
    local points = first + second + third
	local saved = false
    for n=1,table.getn(TALENTS_SAVED["LIST"]) do
        if TALENTS_SAVED["LIST"][n] == "" and not saved then
	       TALENTS_SAVED["LIST"][n] = name
	       saved = true
		end
	end
	if not saved then TALENTS_SAVED["LIST"][table.getn(TALENTS_SAVED["LIST"])+1] = name end
	TALENTS_SAVED["BUILDS"][name] = template
	TALENTS_SAVED["INFO"][name] = {first,second,third,points}
    TALENTS_SAVED.CURRENTBUILD = name
    TalentsaverFu:UpdateText()
    
	SendMSG("|cff3be7ed[Talentsaver]|r - Template '"..name.."' has been saved.")
end

function TALENTSAVER_DELETE(name)    
    -- check if 'name' is a saved template or if there is a typo
    local listed = false
    for i=1, table.getn(TALENTS_SAVED["LIST"]) do
        if TALENTS_SAVED["LIST"][i] == name then
            listed = true
        end
    end
    if not listed or TALENTS_SAVED["BUILDS"][name] == nil or TALENTS_SAVED["INFO"][name] == nil then 
        SendMSG("|cff3be7ed[Talentsaver]|r - No template named '"..name.."' was found.")
        return 
    end
    
    -- start the delete confirmation process
    StaticPopup(name)
end
function Delete(name)
    -- delete the build and its information
    TALENTS_SAVED["BUILDS"][name] = nil
    TALENTS_SAVED["INFO"][name] = nil
    
    -- clean up the list
	local maxList = table.getn(TALENTS_SAVED["LIST"])
	for i=1,maxList do
		if TALENTS_SAVED["LIST"][i] == name then
            -- we've found the entry to delete
			if TALENTS_SAVED["LIST"][i] == maxList then
				TALENTS_SAVED["LIST"][i] = ""
			else
                -- seems like the entry was not the last one and we want the list sorted so that deleted entries are last
				for b=i,maxList do
					if TALENTS_SAVED["LIST"][b+1] ~= nil or TALENTS_SAVED["LIST"][b+1] ~= "" then
						TALENTS_SAVED["LIST"][b] = TALENTS_SAVED["LIST"][b+1]
						TALENTS_SAVED["LIST"][b+1] = ""
					end
				end
			end
		end
	end
    
	SendMSG("|cff3be7ed[Talentsaver]|r - Template named '"..name.."' was deleted.")
end

function TALENTSAVER_LOAD(name)
    if vars.isLoading and vars.Name then
        SendMSG("|cff3be7ed[Talentsaver]|r - Template '"..vars.Name.."' is already loading.")
    else
        if TALENTS_SAVED["BUILDS"][name] == nil or TALENTS_SAVED["INFO"][name] == nil then
            SendMSG("|cff3be7ed[Talentsaver]|r - No template named '"..name.."' was found.")
            return
        end
        if GetUnspentTalentPoints() >= TALENTS_SAVED["INFO"][name][4] then
            vars.isLoading = true
            vars.firstCall = true
            vars.Name = name
        else -- there have been points spent already, gotta check if those points are fitting the template
            local diff = TALENTS_SAVED["INFO"][name][4] - GetUnspentTalentPoints()
			for i=1,3 do
				for talent=1, GetNumTalents(i) do
					local _, _, _, _, spent = GetTalentInfo(i,talent)
					if spent > TALENTS_SAVED["BUILDS"][name][i][talent] then
						SendMSG("|cff3be7ed[Talentsaver]|r - Couldn't load template '"..name.."' because you're missing "..diff.." free Talentpoints and/or the Points spent atm aren't matching the template.")
						return
					end
				end
			end
            vars.isLoading = true
            vars.firstCall = true
            vars.Name = name
        end
    end
end
function DoubleCheck(name)
    -- this function is returning true if everything is alright and false if we need to restart the loading process from its current state
    if GetUnspentTalentPoints() == 0 then return true end
    
    for tree = 1,3 do
        for talent = 1, GetNumTalents(tree) do
            local _, _, _, _, spent = GetTalentInfo(tree,talent)
            if spent > TALENTS_SAVED["BUILDS"][name][tree][talent] then
                -- we found too many points in a talent, the process will be terminated
                SendMSG("|cff3be7ed[Talentsaver]|r - An error occured while loading '"..name.."' please make sure that you don't intervene the loading process.")
                ResetVars()
                return false
            elseif spent < TALENTS_SAVED["BUILDS"][name][tree][talent] then
                -- we found missing points in a talent
                vars.isLoading = true
                vars.tab = tree
                vars.int = talent
                return false
            end
        end
    end
end
function Increment()
	if vars.int < GetNumTalents(vars.tab) then 
		vars.int = vars.int + 1 
	else 
		vars.int = 1
		vars.tab = vars.tab + 1 
	end
end
function ResetVars()
    vars.isLoading = false
    vars.int = 1
	vars.tab = 1
	vars.Name = nil
	vars.lastLoad = 0
end
function TALENTSAVER_IsLoading() return vars.isLoading end
function StaticPopup(name)
    StaticPopupDialogs["DELETE_BUILD"] = {
        text = "Do you really want to delete |cff3be7ed"..name.."|r("..TALENTS_SAVED["INFO"][name][1].."/"..TALENTS_SAVED["INFO"][name][2].."/"..TALENTS_SAVED["INFO"][name][3]..") ",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function()
            Delete(name)
        end,
        OnHide = function() end,
        OnCancel = function() end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
    };

    StaticPopup_Show("DELETE_BUILD")
end

    -- ====== OnEvent & OnUpdate ====== --
CreateFrame("Frame","Talentsaver",UIParent)
Talentsaver:SetScript('OnUpdate', function()
	if vars.isLoading and vars.Name then
            -- ====== DELAY CODE ====== --
		local _, _, latency = GetNetStats()
		local delay = (latency/50*0.4)
		if TALENTS_SAVED.DELAY ~= -1 then delay = TALENTS_SAVED.DELAY/1000 end
		if vars.firstCall then
			vars.firstCall = false
			local first, second, third = GetTalentPointsSpent()
			-- calculate and format the estimated loading time
			local pointsleft = TALENTS_SAVED["INFO"][vars.Name][4] - first - second - third
			local estimate = ""
			local timeleft = pointsleft * delay
			if timeleft > 60 then
				local minutes = math.floor(timeleft/60)
				local seconds = math.floor(timeleft - (minutes*60))
				estimate = minutes.."min "..seconds.."s"
			else
				estimate = math.floor(timeleft).."s"
			end
            TALENTS_SAVED.CURRENTBUILD = vars.Name
            TalentsaverFu:UpdateText()
			SendMSG("|cff3be7ed[Talentsaver]|r - Template '"..vars.Name.."' started loading. (Est. loading time: "..estimate.." )")
		end
            -- ====== LOADING ====== --
		if ((vars.lastLoad+delay) <= GetTime()) then
			local _, _, _, _, spent = GetTalentInfo(vars.tab,vars.int)
			if spent < TALENTS_SAVED["BUILDS"][vars.Name][vars.tab][vars.int] then
				LearnTalent(vars.tab,vars.int)
				if spent == TALENTS_SAVED["BUILDS"][vars.Name][vars.tab][vars.int] then
					Increment()
				end
				vars.lastLoad = GetTime()
			else
				Increment()
				vars.lastLoad = GetTime()-(delay+1)
			end
			if vars.tab == 3 and vars.int == GetNumTalents(vars.tab) then
                if DoubleCheck(vars.Name) then
                    -- The process seems to be finished
				    SendMSG("|cff3be7ed[Talentsaver]|r - Template '"..vars.Name.."' has been loaded.")
				    ResetVars()
                end
			end
		end
	end
end)
    Talentsaver:RegisterEvent("PLAYER_ENTERING_WORLD")
    Talentsaver:RegisterEvent("CHARACTER_POINTS_CHANGED")
Talentsaver:SetScript('OnEvent', function()
	if event == "PLAYER_ENTERING_WORLD" then
		Init()
		Talentsaver:UnregisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "CHARACTER_POINTS_CHANGED" then
        TalentsaverFu:UpdateText()
	end
end)

    -- ====== CHAT COMMANDS ====== --
SLASH_TALENTSAVER1 = "/talentsaver";
SLASH_TALENTSAVER2 = "/talents";
SLASH_TALENTSAVER3 = "/ts";
SlashCmdList["TALENTSAVER"] = function(msg)
	if string.find(msg,"load") or string.find(msg,"Load") or string.find(msg,"LOAD") then
		msg = string.sub(msg,6)
		TALENTSAVER_LOAD(msg)
	elseif string.find(msg,"save") or string.find(msg,"Save") or string.find(msg,"SAVE") then
		msg = string.sub(msg,6)
        TALENTSAVER_SAVE(msg)
	elseif string.find(msg,"delete") or string.find(msg,"Delete") or string.find(msg,"DELETE") then
		msg = string.sub(msg,8)
		TALENTSAVER_DELETE(msg)
	elseif string.find(msg,"list") or string.find(msg,"List") or string.find(msg,"LIST") then
		msg = string.sub(msg,6)
		SendMSG("|cff3be7ed[Talentsaver]|r - the following Specs are saved on this character:")
		for i=1,table.getn(TALENTS_SAVED["LIST"]) do
			local name = TALENTS_SAVED["LIST"][i]
			if name ~= "" then
				local spec = TALENTS_SAVED["INFO"][name][1].." /"..TALENTS_SAVED["INFO"][name][2].." /"..TALENTS_SAVED["INFO"][name][3]
				SendMSG(i..". Talent template - '"..name.."' ("..spec..")")
			end
		end
	elseif string.find(msg,"delay") or string.find(msg,"Delay") or string.find(msg,"DELAY") then
		msg = string.sub(msg,7)
		msg = tonumber(msg)
		if msg >= -1 then
			TALENTS_SAVED.DELAY = msg
			SendMSG("|cff3be7ed[Talentsaver]|r - The Delay has been set to "..msg.."s")
		else
			SendMSG("|cff3be7ed[Talentsaver]|r - The Delay has to be higher than 0, or if you want the default latency delay set it to -1.")
		end
	elseif string.find(msg,"stop") or string.find(msg,"Stop") or string.find(msg,"STOP") then
		if vars.isLoading and vars.Name then
			SendMSG("|cff3be7ed[Talentsaver]|r - Stopped loading template '"..vars.Name.."'.")
			ResetVars()
		else
			SendMSG("|cff3be7ed[Talentsaver]|r - There is no template loading atm.")
		end
	else
		-- TALENTSAVER COMMAND OVERVIEW
		SendMSG("|cff3be7ed[Talentsaver]|r version "..TALENTSAVER_VERSION.." - possible config:")
		SendMSG("> save |cff1fff1fname|r - eg. 'save fury'")
		SendMSG("> load |cff1fff1fname|r - eg. 'load fury'")
		SendMSG("> delete |cff1fff1fname|r - eg. 'delete fury'")
		SendMSG("> delay |cff1fff1f"..TALENTS_SAVED.DELAY.."|r - eg. 'delay 400' for 400ms delay. (Default value is -1 which calculates the delay latency dependent)")
		SendMSG("> list - displays a list of your saved Talent templates.")
		SendMSG("> stop - will stop if a template is being loaded right now.")
	end
end