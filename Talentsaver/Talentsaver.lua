-- Talentsaver AddOn by LYQ(Virose) created for ViroUI
TALENTSAVER_VERSION = 1.3

	-- INIT some vars, which are needed for the loading process in OnUpdate
	local TALENTS_LOADING = false
	local TALENTS_LOADING_STARTED = true
	local TALENTS_INT = 1
	local TALENTS_TAB = 1
	local TALENTS_NAME = "none"
	local TALENTS_LASTLOAD = 0

function TALENTSAVER_INIT()
	if TALENTS_SAVED == nil then
		TALENTS_SAVED = {
			VERSION = TALENTSAVER_VERSION,
			DELAY = -1,
			["LIST"] = {},
			["BUILDS"] = {},
			["INFO"] = {},
		}
	else
		if TALENTS_SAVED.VERSION < TALENTSAVER_VERSION then
			-- new version loaded now
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
			TALENTS_SAVED.VERSION = TALENTSAVER_VERSION
		end
	end
end

	-- SAVE TALENTS
local function TALENTS_SAVE(name)
	if TALENTS_SAVED == nil then TALENTS_SAVED = {["BUILDS"] = {}} end -- if it's been called the first time on this character
	if TALENTS_SAVED["BUILDS"][name] == nil then
		local template = {[1] = {},[2] = {},[3] = {},}
		for i=1,3 do
			-- the 3 different trees
			for t=1,25 do
				-- all the talents in this tree, idk how many max. can exist in one tree but it must be around 18-25
				if GetTalentInfo(i,t) ~= nil then
					local _, _, _, _, spent = GetTalentInfo(i,t)
					template[i][t] = spent;
				end
			end
		end
		local tab1 = 0 local tab2 = 0 local tab3 = 0
		for i=1,3 do
			local _, _, spent = GetTalentTabInfo(i)
			if i == 1 then 		tab1 = spent
			elseif i == 2 then 	tab2 = spent
			elseif i == 3 then 	tab3 = spent
			end
		end
		local points = tab1+tab2+tab3
		--
		local saved = false
		for n=1,table.getn(TALENTS_SAVED["LIST"]) do
			if TALENTS_SAVED["LIST"][n] == "" and not saved then
				TALENTS_SAVED["LIST"][n] = name
				saved = true
			end
		end
		if not saved then TALENTS_SAVED["LIST"][table.getn(TALENTS_SAVED["LIST"])+1] = name end
		TALENTS_SAVED["BUILDS"][name] = template
		TALENTS_SAVED["INFO"][name] = {tab1,tab2,tab3,points}
		SendMSG("|cff3be7ed[Talentsaver]|r - Template '"..name.."' has been saved.")
	else
		SendMSG("|cff3be7ed[Talentsaver]|r - Template couldn't be saved. There is already a template named '"..name.."'")
	end
end
function TALENTS_INCREMENT()
	if TALENTS_INT < GetNumTalents(TALENTS_TAB) then 
		TALENTS_INT = TALENTS_INT + 1 
	else 
		TALENTS_INT = 1
		TALENTS_TAB = TALENTS_TAB + 1 
	end
end

CreateFrame("Frame","Talentsaver",UIParent)
Talentsaver:RegisterEvent("PLAYER_ENTERING_WORLD")
Talentsaver:SetScript('OnUpdate', function()
	if TALENTS_LOADING and TALENTS_NAME ~= "none" then
		-- delay code
		local _, _, latency = GetNetStats()
		local delay = (latency/50*0.4)
		if TALENTS_SAVED.DELAY ~= -1 then delay = TALENTS_SAVED.DELAY/1000 end
		-- check if it's the first loading call
		if TALENTS_LOADING_STARTED then
			TALENTS_LOADING_STARTED = false
			-- check how many points are left
			local sp1 = 0 local sp2 = 0 local sp3 = 0
			for i=1,3 do
				local _, _, num = GetTalentTabInfo(i)
				if i == 1 then sp1 = num
				elseif i == 2 then sp2 = num
				elseif i == 3 then sp3 = num end
			end
			-- calculate and format the estimated loading time
			local pointsleft = TALENTS_SAVED["INFO"][TALENTS_NAME][4] - sp1 - sp2 - sp3
			local estimate = ""
			local timeleft = pointsleft * delay
			if timeleft > 60 then
				local minutes = math.floor(timeleft/60)
				local seconds = math.floor(timeleft - (minutes*60))
				estimate = minutes.."min "..seconds.."s"
			else
				estimate = math.floor(timeleft).."s"
			end
			SendMSG("|cff3be7ed[Talentsaver]|r - Template '"..TALENTS_NAME.."' started loading. (Est. loading time: "..estimate.." )")
		end
		-- load it now
		if ((TALENTS_LASTLOAD+delay) <= GetTime()) then
			local _, _, _, _, spent = GetTalentInfo(TALENTS_TAB,TALENTS_INT)
			if spent < TALENTS_SAVED["BUILDS"][TALENTS_NAME][TALENTS_TAB][TALENTS_INT] then
				LearnTalent(TALENTS_TAB,TALENTS_INT)
				if spent == TALENTS_SAVED["BUILDS"][TALENTS_NAME][TALENTS_TAB][TALENTS_INT] then
					TALENTS_INCREMENT()
				end
				TALENTS_LASTLOAD = GetTime()
			else
				TALENTS_INCREMENT()
				TALENTS_LASTLOAD = GetTime()-(delay+1)
			end
			if TALENTS_TAB == 3 and TALENTS_INT == GetNumTalents(TALENTS_TAB) then
				-- finished, reset the process
				SendMSG("|cff3be7ed[Talentsaver]|r - Template '"..TALENTS_NAME.."' has been loaded.")
				TALENTS_LOADING = false
				TALENTS_NAME = "none"
				TALENTS_INT = 1
				TALENTS_TAB = 1
			end
		end
	end
end)
Talentsaver:SetScript('OnEvent', function()
	if event == "PLAYER_ENTERING_WORLD" then
		TALENTSAVER_INIT()
		Talentsaver:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end)

function SendMSG(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

SLASH_TALENTSAVER1 = "/talentsaver";
SLASH_TALENTSAVER2 = "/talents";
SLASH_TALENTSAVER3 = "/ts";
SlashCmdList["TALENTSAVER"] = function(msg)
	if string.find(msg,"load") or string.find(msg,"Load") or string.find(msg,"LOAD") then
		msg = string.sub(msg,6)
		if not TALENTS_LOADING then
			local pointsspent = 0
			for i=1,3 do
				local _, _, num = GetTalentTabInfo(i)
				pointsspent = pointsspent + num
			end
			local pointsfree = (UnitLevel("player") - 9) - pointsspent 
			if TALENTS_SAVED["BUILDS"][msg] ~= nil then
				if pointsfree >= TALENTS_SAVED["INFO"][msg][4] then
					TALENTS_LOADING = true
					TALENTS_LOADING_STARTED = true
					TALENTS_NAME = msg
				else
					-- there have been points spent already, gotta check if those points are fitting the template
					local diff = TALENTS_SAVED["INFO"][msg][4] - pointsfree
					for i=1,3 do
						local wrongspec = false
						for talent=1,GetNumTalents(i) do
							local _, _, _, _, spent = GetTalentInfo(i,talent)
							if spent > TALENTS_SAVED["BUILDS"][msg][i][talent] then 
								SendMSG("|cff3be7ed[Talentsaver]|r - Couldn't load template '"..msg.."' because you're missing "..diff.." free Talentpoints and the Points spent atm aren't matching the template.")
								return
							end
						end
						if i == 3 then
							TALENTS_LOADING = true
							TALENTS_LOADING_STARTED = true
							TALENTS_NAME = msg
						end
					end
				end
			else SendMSG("|cff3be7ed[Talentsaver]|r - No template named '"..msg.."' was found.")
			end
		else
			SendMSG("|cff3be7ed[Talentsaver]|r - Template '"..TALENTS_NAME.."' is already loading.")
		end
	elseif string.find(msg,"save") or string.find(msg,"Save") or string.find(msg,"SAVE") then
		msg = string.sub(msg,6)
		if TALENTS_SAVED["BUILDS"][msg] ~= nil then
			SendMSG("|cff3be7ed[Talentsaver]|r - A saved Talent Spec is already named like that, you'd have to delete the old one first to overwrite it.")
		else
			TALENTS_SAVE(msg)
		end
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
	elseif string.find(msg,"delete") or string.find(msg,"Delete") or string.find(msg,"DELETE") then
		msg = string.sub(msg,8)
		if TALENTS_SAVED["BUILDS"][msg] ~= nil and TALENTS_SAVED["INFO"][msg] ~= nil then
			if TALENTS_DELETE_CONFIRM == nil then
				TALENTS_DELETE_CONFIRM = true
				SendMSG("|cff3be7ed[Talentsaver]|r - If you really want to delete the template named '"..msg.."', repeat the command.")
			else
				TALENTS_DELETE_CONFIRM = nil
				TALENTS_SAVED["BUILDS"][msg] = nil
				TALENTS_SAVED["INFO"][msg] = nil
				local maxList = table.getn(TALENTS_SAVED["LIST"])
				for i=1,maxList do
					if TALENTS_SAVED["LIST"][i] == msg then
						if TALENTS_SAVED["LIST"][i] == maxList then
							TALENTS_SAVED["LIST"][i] = ""
						else
							for b=i,maxList do
								if TALENTS_SAVED["LIST"][b+1] ~= nil or TALENTS_SAVED["LIST"][b+1] ~= "" then
									TALENTS_SAVED["LIST"][b] = TALENTS_SAVED["LIST"][b+1]
								end
							end
						end
					end
				end
				SendMSG("|cff3be7ed[Talentsaver]|r - Template named '"..msg.."' was deleted.")
			end
		else SendMSG("|cff3be7ed[Talentsaver]|r - No template named '"..msg.."' was found.")
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
		if TALENTS_LOADING then
			SendMSG("|cff3be7ed[Talentsaver]|r - Stopped loading template '"..TALENTS_NAME.."'.")
			TALENTS_LOADING = false
			TALENTS_INT = 1
			TALENTS_TAB = 1
			TALENTS_NAME = "none"
			TALENTS_LASTLOAD = 0
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