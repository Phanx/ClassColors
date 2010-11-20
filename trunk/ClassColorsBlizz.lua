--[[--------------------------------------------------------------------
	!ClassColors
	Provides a non-tainting method for changing raid class colors.
	by Phanx < addons@phanx.net >
	Copyright � 2009�2010 Phanx.
	See accompanying README for license terms and API details.
	http://www.wowinterface.com/downloads/info12513-ClassColors.html
	http://wow.curse.com/downloads/wow-addons/details/classcolors.aspx
----------------------------------------------------------------------]]

local addonFuncs = { }

local PLAYER_LEVEL = PLAYER_LEVEL:replace("|c%s", "|cff%02x%02x%02x")
local PLAYER_LEVEL_NO_SPEC = PLAYER_LEVEL_NO_SPEC:replace("|c%s", "|cff%02x%02x%02x")

-- ChatConfigFrame.xml

do
	local colorChatConfig = function()
		for i, class in ipairs(CLASS_SORT_ORDER) do
			local color = CUSTOM_CLASS_COLORS[class]
			if color then
				ChatConfigChatSettingsClassColorLegend.classStrings[i]:SetFormattedText("|cff%02x%02x%02x%s|r\n", color.r * 255, color.g * 255, color.b * 255, LOCALIZED_CLASS_NAMES_MALE[class])
				ChatConfigChannelSettingsClassColorLegend.classStrings[i]:SetFormattedText("|cff%02x%02x%02x%s|r\n", color.r * 255, color.g * 255, color.b * 255, LOCALIZED_CLASS_NAMES_MALE[class])
			end
		end
	end

	CUSTOM_CLASS_COLORS:RegisterCallback(colorChatConfig)
	colorChatConfig()
end

-- ChatFrame.lua

do
	local colorMap = { }

	local function populateColorMap()
		for class, c1 in pairs(RAID_CLASS_COLORS) do
			local c2 = CUSTOM_CLASS_COLORS[class]
			colorMap[("|cff%02x%02x%02x"):format(c1.r * 255, c1.g * 255, c1.b * 255)] = ("|cff%02x%02x%02x"):format(c2.r * 255, c2.g * 255, c2.b * 255)
		end
	end

	CUSTOM_CLASS_COLORS:RegisterCallback(populateColorMap)
	populateColorMap()

	local hooks = { }

	local function recolorNames(self, message, ...)
		if type(message) == "string" and message:match("|cff") then
			for old, new in pairs(colorMap) do
				message = message:replace(old, new)
			end
		end
		return hooks[self](self, message, ...)
	end

	for i = 1, NUM_CHAT_WINDOWS do
		local f = _G["ChatFrame" .. i]
		if f and f ~= COMBATLOG then
			hooks[f] = f.AddMessage
			f.AddMessage = recolorNames
		end
	end

	local orig = FCF_OpenTemporaryWindow
	function FCF_OpenTemporaryWindow(...)
		local f = orig(...)
		if not hooks[f] then
			hooks[f] = f.AddMessage
			f.AddMessage = recolorNames
		end
		return f
	end
end

-- CompactUnitFrame.lua

hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
	-- print("CompactUnitFrame_UpdateHealthColor", frame.unit or "NONE")
	if frame.optionTable.useClassColors and UnitIsConnected(frame.unit) then
		local _, class = UnitClass(frame.unit)
		local color = CUSTOM_CLASS_COLORS[class]
		if color then
			frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
		end
	end
end)

-- FriendsFrame.lua

hooksecurefunc("WhoList_Update", function()
	-- print("WhoListUpdate")
	local offset = FauxScrollFrame_GetOffset(WhoListScrollFrame)
	for i = 1, WHOS_TO_DISPLAY do
		local _, _, _, _, _, _, class = GetWhoInfo(i + offset)
		if class then
			local color = CUSTOM_CLASS_COLORS[classFileName]
			if color then
				_G["WhoFrameButton" .. i .. "Class"]:SetTextColor(color.r, color.g, color.b)
			end
		end
	end
end)

-- LFDFrame.lua

hooksecurefunc("LFDQueueFrameRandomCooldownFrame_Update", function()
	-- print("LFDQueueFrameRandomCooldownFrame_Update")
	for i = 1, GetNumPartyMembers() do
		local _, class = UnitClass("party"..i)
		if class then
			local color = CUSTOM_CLASS_COLORS[class]
			if color then
				_G["LFDQueueFrameCooldownFrameName"..i]:SetFormattedText("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, UnitName("party"..i))
			end
		end
	end
end)

-- LFRFrame.lua

hooksecurefunc("LFRBrowseFrameListButton_SetData", function(button, i)
	-- print("LFRBrowseFrameListButton_SetData")
	local _, _, _, _, _, _, _, class = SearchLFGGetResults(i)
	if class then
		local color = CURSOR_CLASS_COLORS[class]
		if color then
			button.class:SetTextColor(color.r, color.g, color.b)
		end
	end
end)

-- PaperDollFrame.lua

hooksecurefunc("PaperDollFrame_SetLevel", function()
	-- print("PaperDollFrame_SetLevel")
	local className, class = UnitClass("player")
	local color = CUSTOM_CLASS_COLORS[class]
	if color then
		local specName, _
		local primaryTalentTree = GetPrimaryTalentTree()
		if primaryTalentTree then
			_, specName = GetTalentTabInfo(primaryTalentTree)
		end
		if specName and specName ~= "" then
			CharacterLevelText:SetFormattedText(PLAYER_LEVEL, UnitLevel("player"), color.r * 255, color.g * 255, color.b * 255, specName, className)
		else
			CharacterLevelText:SetFormattedText(PLAYER_LEVEL_NO_SPEC, UnitLevel("player"), color.r * 255, color.g * 255, color.b * 255, className)
		end
	end
end)

------------------------------------------------------------------------

addonFuncs["Blizzard_Calendar"] = function()
	hooksecurefunc("CalendarViewEventInviteListScrollFrame_Update", function()
		-- print("CalendarViewEventInviteListScrollFrame_Update")
		local buttons = CalendarViewEventInviteListScrollFrame.buttons
		local offset = HybridScrollFrame_GetOffset(CalendarViewEventInviteListScrollFrame)
		for i = 1, #buttons do
			local name, _, _, class = CalendarEventGetInvite(i + offset)
			if name and class then
				local color = CUSTOM_CLASS_COLORS[class]
				if color then
					local button = buttons[i]:GetName()
					_G[button .. "Name"]:SetTextColor(color.r, color.g, color.b)
					_G[button .. "Class"]:SetTextColor(color.r, color.g, color.b)
				end
			end
		end
	end)

	hooksecurefunc("CalendarCreateEventInviteListScrollFrame_Update", function()
		-- print("CalendarCreateEventInviteListScrollFrame_Update")
		local buttons = CalendarCreateEventInviteListScrollFrame.buttons
		local offset = HybridScrollFrame_GetOffset(CalendarCreateEventInviteListScrollFrame)
		for i = 1, #buttons do
			local name, _, _, class = CalendarEventGetInvite(i + offset)
			if name and class then
				local color = CUSTOM_CLASS_COLORS[class]
				if color then
					local button = buttons[i]:GetName()
					_G[button .. "Name"]:SetTextColor(color.r, color.g, color.b)
					_G[button .. "Class"]:SetTextColor(color.r, color.g, color.b)
				end
			end
		end
	end)
end

------------------------------------------------------------------------

addonFuncs["Blizzard_GuildUI"] = function()
	hooksecurefunc("GuildRosterButton_SetStringText", function(buttonString, text, online, class)
		-- print("GuildRosterButton_SetStringText")
		if online and class then
			local color = CUSTOM_CLASS_COLORS[class]
			if color then
				buttonString:SetTextColor(color.r, color.g, color.b)
			end
		end
	end)
end

------------------------------------------------------------------------

addonFuncs["Blizzard_InspectUI"] = function()
	hooksecurefunc("InspectPaperDollFrame_SetLevel", function()
		-- print("InspectPaperDollFrame_SetLevel")
		local unit = InspectFrame.unit

		local level = UnitLevel(InspectFrame.unit)
		if level == -1 then
			level = "??"
		end

		local className, class = UnitClass(InspectFrame.unit)
		local color = CUSTOM_CLASS_COLORS[class]

		local specName, _
		local primaryTalentTree = GetPrimaryTalentTree(true)
		if primaryTalentTree then
			_, specName = GetTalentTabInfo(primaryTalentTree, true)
		end

		if specName and specName ~= "" then
			InspectLevelText:SetFormattedText(PLAYER_LEVEL, level, color.r * 255, color.g * 255, color.b * 255, specName, className)
		else
			InspectLevelText:SetFormattedText(PLAYER_LEVEL_NO_SPEC, level, color.r * 255, color.g * 255, color.b * 255, className)
		end
	end)
end

------------------------------------------------------------------------

addonFuncs["Blizzard_RaidUI"] = function()
	hooksecurefunc("RaidGroupFrame_Update", function()
		-- print("RaidGroupFrame_Update")
		local numRaidMembers = GetNumRaidMembers()
		for i = 1, MAX_RAID_MEMBERS do
			if i <= numRaidMembers then
				local _, _, group, _, _, class, _, online, isDead = GetRaidRosterInfo(i)
				if _G["RaidGroup" .. group].nextIndex <= MEMBERS_PER_RAID_GROUP then
					if online and not isDead then
						local color = RAID_CLASS_COLORS[fileName]
						if color then
							local subframes = _G["RaidGroupButton" .. i].subframes
							subframes.name:SetTextColor(color.r, color.g, color.b)
							subframes.class:SetTextColor(color.r, color.g, color.b)
							subframes.level:SetTextColor(color.r, color.g, color.b)
						end
					end
				end
			end
		end
	end)

	hooksecurefunc("RaidGroupFrame_UpdateHealth", function(i)
		-- print("RaidGroupFrame_UpdateHealth", i)
		local _, _, _, _, _, class, _, online, isDead = GetRaidRosterInfo(i)
		if online and not isDead then
			local color = RAID_CLASS_COLORS[fileName]
			if color then
				_G["RaidGroupButton" .. i .. "Name"]:SetTextColor(color.r, color.g, color.b)
				_G["RaidGroupButton" .. i .. "Class"]:SetTextColor(color.r, color.g, color.b)
				_G["RaidGroupButton" .. i .. "Level"]:SetTextColor(color.r, color.g, color.b)
			end
		end
	end)

	hooksecurefunc("RaidPullout_UpdateTarget", function(pullOutFrame, pullOutButton, unit, which)
		-- print("RaidPullout_UpdateTarget", pullOutFrame, unit)
		local pullOutFrame = _G[pullOutFrame]
		if not pullOutFrame.showTarget then
			pullOutFrame.showTargetTarget = nil
		end
		if pullOutFrame["show" .. which] then
			local name = UnitName(unit)
			if name and name ~= UNKNOWNOBJECT then
				local _, class = UnitClass(unit)
				if class and UnitCanCooperate("player", unit) then
					local color = CUSTOM_CLASS_COLORS[class]
					if color then
						_G[pullOutButton .. which .. "Name"]:SetVertexColor(color.r, color.g, color.b)
					end
				end
			end
		end
	end)

	hooksecurefunc("RaidPulloutButton_UpdateDead", function(button, dead, class)
		-- print("RaidPulloutButton_UpdateDead", button.unit)
		if not dead then
			if class == "PETS" then
				class = UnitClass(gsub(button.unit, "raidpet", "raid"))
			end
			local color = CUSTOM_CLASS_COLORS[class]
			if color then
				button.nameLabel:SetVertexColor(color.r, color.g, color.b)
			end
		end
	end)
end

------------------------------------------------------------------------

local numAddons = 0

for addon, func in pairs(addonFuncs) do
	if IsAddOnLoaded(addon) then
		addonFuncs[addon] = nil
		func()
	else
		numAddons = numAddons + 1
	end
end

if numAddons > 0 then
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_LOADED")
	f:SetScript("OnEvent", function(self, event, addon)
		local func = addonFuncs[addon]
		if func then
			addonFuncs[addon] = nil
			numAddons = numAddons - 1
			func()
		end
		if numAddons == 0 then
			self:UnregisterEvent("ADDON_LOADED")
			self:SetScript("OnEvent", nil)
		end
	end)
end