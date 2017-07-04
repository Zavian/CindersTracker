local CindersTracker = _G.CindersTracker
local RC = LibStub("LibRangeCheck-2.0")
local ct = CreateFrame("Frame")
local ctEvents = {}

local w_ct = nil
local doCheck = false
local TRINKET_RANGE = 10
local position_list = nil
local settings = {
    -- TODO : Add options such as when to activate stuff and shit
	--[1] = {
	--	name = "activateRaid",
	--	default = false,
	--	text = "Start tracking when entering a raid.",
	--	sub = false,
	--}
}
local range_radar = nil
local players_found = nil
local players_in_raid = {}


function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


if ctSettings == nil then
	ctSettings = {}
	for i = 1, tablelength(settings) do
        local s = settings[i].name
        local d = settings[i].default
        ctSettings[s] = d
    end

	ctSettings.names = {

	}
end



SLASH_CINDERSTRACKER1 = "/ct"
SLASH_CINDERSTRACKER2 = "/cinderstracker"

function SlashCmdList.CINDERSTRACKER(msg, editbox)
	msg = msg:lower()
	if msg == "test" then
		if IsInRaid() then
			position_list = FindPosition(ctSettings.names)
            CreateRangeRadarFrame()
			CreatePlayersFoundFrame()
			CTWritePlayersInRaid()
			current_post = position_list[index_checker]
			index_checker = 1
			doCheck = not doCheck

		end
	end
	Show_CT()
end


function MakeMovable(frame)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end

function Show_CT()
	if not w_ct then
		w_ct = CreateFrame("Frame", "CindersTracker_Window", UIParent, "ThinBorderTemplate")
	    MakeMovable(w_ct)
	    w_ct:SetSize(350,450)
	    w_ct:SetPoint("CENTER")
	    w_ct:SetFrameStrata("HIGH")

	    -- Close Button
	    w_ct.close = CreateFrame("Button", "CindersTracker_Window_CloseButton", w_ct, "UIPanelCloseButton")
	    w_ct.close:SetPoint("TOPRIGHT", w_ct)
	    w_ct.close:SetSize(34, 34)
	    w_ct.close:SetScript("OnClick", function()
            doCheck = false
            w_ct:Hide()
        end)
	    -- Texture
	    w_ct.bg = w_ct:CreateTexture()
	    w_ct.bg:SetAllPoints(w_ct)
	    w_ct.bg:SetTexture([[Interface\Buttons\WHITE8X8]])
	    w_ct.bg:SetVertexColor(.1,.1,.1,1)
	    w_ct:Show()


	    -- Title
	    w_ct.title = w_ct:CreateFontString("CindersTracker_Window_Title", "OVERLAY", "GameFontHighlight")
	    w_ct.title:SetPoint("TOPLEFT", 10, -10)
	    w_ct.title:SetText("Cinder Tracker")

		-- Text Box
		w_ct.CopyChat = CreateFrame('Frame', 'copyBox', w_ct)
	    w_ct.CopyChat:SetWidth(325)
	    w_ct.CopyChat:SetHeight(325)
	    w_ct.CopyChat:SetPoint('BOTTOMLEFT', w_ct.title, 'BOTTOMLEFT', -2, -w_ct.CopyChat:GetHeight()-20)
	    w_ct.CopyChat:SetFrameStrata('HIGH')
	    --CopyChat:Hide()
	    w_ct.CopyChat:SetBackdrop({
	        bgFile = [[Interface\Buttons\WHITE8x8]],
	        insets = {left = 3, right = 3, top = 4, bottom = 3
	    }})
	    w_ct.CopyChat:SetBackdropColor(0, 0, 0, 0.7)

		w_ct.instructions = w_ct.CopyChat:CreateFontString("CindersTracker_Window_CopyChat_Title", "OVERLAY", "GameFontNormal")
		w_ct.instructions:SetPoint("TOPLEFT", 2, 10)
		w_ct.instructions:SetText("One name per row")

	    --CreateBorder(CopyChat, 12, 1, 1, 1)

	    w_ct.CopyChatBox = CreateFrame('EditBox', 'copyText', w_ct.CopyChat)
	    w_ct.CopyChatBox:SetMultiLine(true)
	    w_ct.CopyChatBox:EnableMouse(true)
	    w_ct.CopyChatBox:SetMaxLetters(99999)
	    w_ct.CopyChatBox:SetFontObject("GameFontNormal")
	    w_ct.CopyChatBox:SetWidth(305)
	    w_ct.CopyChatBox:SetHeight(305)
	    w_ct.CopyChatBox:SetAutoFocus(false)
	    w_ct.CopyChatBox:SetScript('OnEscapePressed', function()
			w_ct.CopyChatBox:EnableKeyboard(false);
			w_ct.CopyChatBox:ClearFocus()
		end)
	    w_ct.CopyChatBox:SetScript("OnMouseDown", function()
			w_ct.CopyChatBox:EnableKeyboard(true)
		end)
		w_ct.CopyChatBox:SetScript("OnEditFocusLost", function()
			ctSettings.names = split(w_ct.CopyChatBox:GetText(), "\n")
			--print(#ctSettings.names)
		end)

	    w_ct.Scroll = CreateFrame('ScrollFrame', 'copyScroll', w_ct.CopyChat, 'UIPanelScrollFrameTemplate')
	    w_ct.Scroll:SetPoint('TOPLEFT', w_ct.CopyChat, 'TOPLEFT', 8, -15)
	    w_ct.Scroll:SetPoint('BOTTOMRIGHT', w_ct.CopyChat, 'BOTTOMRIGHT', -30, 8)
	    w_ct.Scroll:SetScrollChild(w_ct.CopyChatBox)


		if #ctSettings.names > 0 then
			local s = ""
			for i = 1, #ctSettings.names do
				s = s..ctSettings.names[i].."\n"
			end
			w_ct.CopyChatBox:SetText(s)
		end

		-- CheckBoxes
		local y = -w_ct:GetHeight() + (25*#settings)
		for i=1,#settings do
			CreateCheckButton(settings[i], w_ct, y)
			y = y - 20
		end

	else
		if not w_ct:IsShown() then w_ct:Show() end
	end
end

function FindPosition(names)
	local inRaid = IsInRaid()
	if not inRaid then return nil end

	local num = GetNumGroupMembers()
	local returner = {}
	players_in_raid = {}
	for i = 1, num do
		local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
		if online then
			for j = 1, #names do
				if names[j] == name then
					tinsert(returner, i)
					tinsert(players_in_raid, name)
				end
			end
		end
	end
	return returner
end

function CreateCheckButton(check, parent, y)
	local name = check.name
	local sub = check.sub and 50 or 5
	local width = check.sub and 325 or 350
	local text = check.text
	parent[name] = CreateFrame("CheckButton", "chk" .. name, UIConfig, "UICheckButtonTemplate")
	parent[name]:SetChecked(ctSettings[name])
	if not check.f then
		parent[name]:SetScript("OnClick", function()
			local b = parent[name]:GetChecked()
			ctSettings[name] = parent[name]:GetChecked()
			if check.masterOf then ToggleCheckAndText(parent, check.masterOf, b) end
		end
		)
	else parent[name]:SetScript("OnClick", check.f) end
	parent[name]:SetPoint("TOPLEFT", parent, sub, y)
	local chkWidth = parent[name]:GetWidth()

	parent[name].lbl = parent[name]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	parent[name].lbl:SetPoint("LEFT", parent[name], chkWidth, 0, "RIGHT")
	parent[name].lbl:SetWordWrap(true)
	parent[name].lbl:SetWidth(width)
	parent[name].lbl:SetJustifyH("LEFT")
	parent[name].lbl:SetText(text)
	parent[name].lbl:SetFont("Fonts\\FRIZQT__.TTF", 14)
	parent[name].lbl:SetTextColor(253/255, 209/255, 22/255,1)
	if check.slaveOf then ToggleCheckAndText(parent, name, ctSettings[check.slaveOf]) end

	parent[name]:SetParent(parent)
end

function CreateRangeRadarFrame()
	if range_radar == nil then
		range_radar = CreateFrame("Frame", "CindersTracker_RangeRadar", UIParent)
	    MakeMovable(range_radar)
	    range_radar:SetSize(150,150)
	    range_radar:SetPoint("CENTER", -300, -150)
	    range_radar:SetFrameStrata("HIGH")

	    -- Close Button
	    range_radar.close = CreateFrame("Button", "CindersTracker_RangeRadar_CloseButton", range_radar, "UIPanelCloseButton")
	    range_radar.close:SetPoint("TOPRIGHT", range_radar, 0, 20)
	    range_radar.close:SetSize(25, 25)
	    range_radar.close:SetScript("OnClick", function() range_radar:Hide(); doCheck = false; end)

		-- Texture
	    range_radar.bg = range_radar:CreateTexture()
	    range_radar.bg:SetAllPoints(range_radar)
	    range_radar.bg:SetTexture([[Interface\Buttons\WHITE8X8]])
	    range_radar.bg:SetVertexColor(.1,.1,.1,.4)

		-- Title
		range_radar.title = range_radar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		range_radar.title:SetPoint("TOPLEFT", 0, 15)
		range_radar.title:SetText("CT Radar")

		-- Text
		range_radar.text = range_radar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		range_radar.text:SetWidth(range_radar:GetWidth())
		range_radar.text:SetHeight(range_radar:GetHeight())
		range_radar.text:SetJustifyH("CENTER")
		range_radar.text:SetJustifyV("MIDDLE")
		range_radar.text:SetPoint("CENTER")
		range_radar.text:SetFont("Fonts\\FRIZQT__.TTF", 14)

		range_radar:Show()
	elseif not range_radar:IsShown() then range_radar:Show()
	elseif range_radar:IsShown() then range_radar:Hide() end
end

function CreatePlayersFoundFrame()
	if players_found == nil then
		players_found = CreateFrame("Frame", "CindersTracker_PlayersFound", range_radar)
	    --MakeMovable(players_found)
	    players_found:SetSize(150,150)
	    players_found:SetPoint("LEFT", -160, 0)
	    players_found:SetFrameStrata("HIGH")

	    -- Close Button
	    players_found.close = CreateFrame("Button", "CindersTracker_PlayersFound_CloseButton", players_found, "UIPanelCloseButton")
	    players_found.close:SetPoint("TOPRIGHT", players_found, 0, 20)
	    players_found.close:SetSize(25, 25)
	    players_found.close:SetScript("OnClick", function() players_found:Hide() end)

		-- Texture
	    players_found.bg = players_found:CreateTexture()
	    players_found.bg:SetAllPoints(players_found)
	    players_found.bg:SetTexture([[Interface\Buttons\WHITE8X8]])
	    players_found.bg:SetVertexColor(.1,.1,.1,.4)

		-- Title
		players_found.title = players_found:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		players_found.title:SetPoint("TOPLEFT", 0, 15)
		players_found.title:SetText("CT Players in raid")

		-- Text
		players_found.text = players_found:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		players_found.text:SetWidth(players_found:GetWidth())
		players_found.text:SetHeight(players_found:GetHeight())
		players_found.text:SetJustifyH("LEFT")
		players_found.text:SetJustifyV("TOP")
		players_found.text:SetPoint("CENTER")
		players_found.text:SetFont("Fonts\\FRIZQT__.TTF", 14)
		players_found.string = {}

		CTWritePlayersInRaid()

		players_found:Show()
	elseif not players_found:IsShown() then players_found:Show()
	elseif players_found:IsShown() then players_found:Hide() end
end

function CTWritePlayersInRaid()
	local s = ""
	if #players_in_raid > 0 then
		for i = 1, #players_in_raid do
			s = s..players_in_raid[i].."\n"
		end
		players_found.text:SetText(s)
	end
end

local index_checker = 1
local current_pos = nil
function OnUpdate(self, elapsed)
	if doCheck then
        if index_checker > #position_list then index_checker = 1; current_pos = position_list[index_checker] end
        if position_list == nil then FindPosition(ctSetting.names) end
		if current_pos == nil then current_pos = position_list[index_checker] end
		local minRange, _ = RC:GetRange('raid'..current_pos)
		if minRange then
			if minRange <= TRINKET_RANGE then
				if not written(UnitName("raid"..current_pos)) then
					players_found.string[#players_found.string+1] = UnitName("raid"..current_pos)
				end
			else
				tableremove(players_found.string, UnitName("raid"..current_pos))
			end
		end
		Write_CT()
		index_checker = index_checker + 1
		current_pos = position_list[index_checker]
	end
end
ct:SetScript("OnUpdate", OnUpdate)

function written(name)
	for i = 1, #players_found.string do
		if players_found.string[i] == name then return true end
	end
	return false
end

function Write_CT()
	local s = ""
	for i = 1, #players_found.string do
		s = s..players_found.string[i].."\n"
	end
	if s == "" then s = ":(" end
	range_radar.text:SetText(s)
end

function tableremove(t, token)
	for i=1, #t do
		if t[i] == token then
			tremove(t, i)
			return i
		end
	end
end

function ctEvents:GROUP_JOINED(...)
	if IsInRaid() then
		position_list = FindPosition(ctSettings.names)
		CTWritePlayersInRaid()
		index_checker = 1
		current_post = position_list[index_checker]
	end
end

function ctEvents:GROUP_ROSTER_UPDATE(...)
	if IsInRaid() then
		position_list = FindPosition(ctSettings.names)
		CTWritePlayersInRaid()
		index_checker = 1
		current_post = position_list[index_checker]
	end
end

function ctEvents:PLAYER_ENTERING_WORLD(...)
    if IsInRaid() then
		position_list = FindPosition(ctSettings.names)
		CTWritePlayersInRaid()
		index_checker = 1
		current_post = position_list[index_checker]
	end
end

function ctEvents:INSTANCE_ENCOUNTER_ENGAGE_UNIT(...)
	if doCheck then
		doCheck = false
		players_found:Hide()
		range_radar:Hide()
	elseif IsInRaid() then
        index_checker = 1
		current_post = position_list[index_checker]
		doCheck = true

		CreateRangeRadarFrame()
		CreatePlayersFoundFrame()
	end
end

ct:SetScript("OnEvent", function(self, event, ...)
	ctEvents[event](self, ...)
	end)
for k, v in pairs(ctEvents) do
	ct:RegisterEvent(k)
end
