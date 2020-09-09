-------------------------------------------------
-- Advanced Settings Screen
-------------------------------------------------

include( "IconSupport" )
include( "UniqueBonuses" )
include( "InstanceManager" )

local ipairs = ipairs
local pairs = pairs
local print = print

local min = math.min
local floor = math.floor
local sort = table.sort
local insert = table.insert

local Controls = Controls
local InstanceManager = InstanceManager
local SlotStatus = SlotStatus
local PreGame = PreGame
local Query = DB.Query
local Locale = Locale
local eLClick = Mouse.eLClick
local GameInfo = GameInfo
local GameDefines = GameDefines
local IconHookup = IconHookup
local Path = Path
local UI = UI
local Modding = Modding
local UIManager = UIManager
local ContextPtr = ContextPtr
local Events = Events
local KeyDown = KeyEvents.KeyDown
local VK_ESCAPE = Keys.VK_ESCAPE
local SystemUpdateUITypeScreenResize = SystemUpdateUIType.ScreenResize

-------------------------------------------------
-- "Globals"
-------------------------------------------------
local g_SlotInstances = {}	-- Container for all player slots
local g_GameOptionsManager = InstanceManager:new("GameOptionInstance", "GameOptionRoot", Controls.GameOptionsStack)
local g_DropDownOptionsManager = InstanceManager:new("DropDownOptionInstance", "DropDownOptionRoot", Controls.DropDownOptionsStack)
local g_VictoryCondtionsManager = InstanceManager:new("GameOptionInstance", "GameOptionRoot", Controls.VictoryConditionsStack)
local g_IsModding

local g_AIdefaultHandicapID = GameInfo.HandicapInfos.HANDICAP_AI_DEFAULT.ID

local g_SlotStatusInfo = {
	[ SlotStatus.SS_OPEN ] = { "TXT_KEY_SLOTTYPE_OPEN", "TXT_KEY_SLOTTYPE_OPEN_TT" },
	[ SlotStatus.SS_COMPUTER ] = { "TXT_KEY_SLOTTYPE_AI", "TXT_KEY_SLOTTYPE_AI_TT" },
	[ SlotStatus.SS_CLOSED ] = { "TXT_KEY_SLOTTYPE_CLOSED", "TXT_KEY_SLOTTYPE_CLOSED_TT" },
	[ SlotStatus.SS_TAKEN ] = { "TXT_KEY_PLAYER_TYPE_HUMAN", "TXT_KEY_SLOTTYPE_HUMAN_TT" },
	[ SlotStatus.SS_OBSERVER ] = { "TXT_KEY_SLOTTYPE_OBSERVER", "TXT_KEY_SLOTTYPE_OBSERVER_TT" },
}

local g_RandomMap = {
	Name = "TXT_KEY_RANDOM_MAP_SCRIPT",
	Description = "TXT_KEY_RANDOM_MAP_SCRIPT_HELP",
}

local g_RandomCiv = {
	ID = -1,
	Description = "TXT_KEY_RANDOM_CIV",
	ShortDescription = "TXT_KEY_RANDOM_CIV",
	PortraitIndex = 23,
	IconAtlas = "CIV_COLOR_ATLAS",
	LeaderID = -1,
	LeaderDescription = "TXT_KEY_RANDOM_LEADER",
	LeaderPortraitIndex = 22,
	LeaderIconAtlas = "LEADER_ATLAS",
}

local g_RequestInit = true
local g_GameCivs, g_GameCivList, g_MapCivList, g_MapScriptInfo
local g_MaxMinorCivs = 41

local PerformRefresh

local function LocalizeAndSetTextAndToolTip( control, textKey, tipKey )
	control:LocalizeAndSetText( textKey or "" )
	if tipKey and tipKey~="" then
		control:LocalizeAndSetToolTip( tipKey )
	else
		control:SetToolTipString()
	end
end

local function SortNames( a, b )
	return Locale.Compare( a.Name, b.Name ) == -1
end

local function SortSpeeds( a, b )
	return b.VictoryDelayPercent > a.VictoryDelayPercent
end

local function SortCivs( a, b )
	return Locale.Compare( a.LeaderDescription, b.LeaderDescription ) == -1
end

local function DisplayHandicap( control, handicap )
	return LocalizeAndSetTextAndToolTip( control, handicap.Description, handicap.ID == g_AIdefaultHandicapID and "TXT_KEY_SLOTTYPE_AI_TT" or handicap.Help )
end

local function CancelPlayerDetails( playerID )
	PreGame.SetLeaderName( playerID, "" )
	PreGame.SetCivilizationDescription( playerID, "" )
	PreGame.SetCivilizationShortDescription( playerID, "" )
	PreGame.SetCivilizationAdjective( playerID, "" )
end

local function SetScenarioCivilization( playerID, civID )
	for i = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		if PreGame.GetCivilization( i ) == civID then
			PreGame.SetCivilization( i, PreGame.GetCivilization( playerID ) )
			UI.MoveScenarioPlayerToSlot( i, playerID )
			break
		end
	end
	PreGame.SetCivilization( playerID, civID )
	CancelPlayerDetails( playerID )
	return PerformRefresh()
end

local function SetWorldSizeAndDefaultPlayers( worldSizeID )
	PreGame.SetRandomWorldSize( false )
	PreGame.SetWorldSize( worldSizeID ) -- this also resets player slots ! all players above world size are set to random civ -1, handicap chieftain, slot type SS_OBSERVER
end

local function SetMapScriptAndWB( script, wb )
print( "SetMapScriptAndWB", script )
	g_MapCivList = nil
	g_MapScriptInfo = nil
	PreGame.SetLoadWBScenario( false )
	PreGame.SetRandomMapScript( not script )
	if script then
		PreGame.SetMapScript( script )
		wb = wb or UI.GetMapPreview( script )
		if wb and UI.IsMapScenario( script ) then
print( "SetMapScriptAndWB scenario" )
-- CvWorldBuilderMapLoader::SetupPlayers
			PreGame.SetLoadWBScenario( true )
			PreGame.SetOverrideScenarioHandicap( true )
			PreGame.SetEra( wb.StartEra )
			PreGame.SetGameSpeed( wb.DefaultSpeed )
			PreGame.SetMaxTurns( wb.MaxTurns )
			PreGame.SetNumMinorCivs( wb.CityStateCount )
			SetWorldSizeAndDefaultPlayers( wb.MapSize )

			local victories = {}
			for _, v in ipairs( wb.VictoryTypes ) do
				victories[v] = true
			end
			for row in GameInfo.Victories() do
				PreGame.SetVictory( row.ID, victories[row.Type] )
			end

			local playerList = UI.GetMapPlayers( script )
			if playerList then
				UI.ResetScenarioPlayerSlots()
				g_MapCivList = {}
				local human
				for i, v in ipairs( playerList ) do
print( "SetMapScriptAndWB", i-1, v.CivType )
					PreGame.SetCivilization( i-1, v.CivType )
					PreGame.SetSlotStatus( i-1, i>1 and SlotStatus.SS_COMPUTER or SlotStatus.SS_TAKEN )
					PreGame.SetHandicap( i-1, g_AIdefaultHandicapID )
					if v.Playable then
						insert( g_MapCivList, g_GameCivs[ v.CivType ] )
						human = human or v
					end
				end
				if human then
					SetScenarioCivilization( 0, human.CivType )
					PreGame.SetHandicap( 0, human.DefaultHandicap )
				end
				for playerID = #playerList, GameDefines.MAX_MAJOR_CIVS - 1 do
					PreGame.SetSlotStatus( playerID, SlotStatus.SS_OBSERVER ) -- just like reset slots !)
				end
				sort( g_MapCivList, SortCivs )
			end
		else
print( "SetMapScriptAndWB not a scenario" )
			PreGame.SetNumMinorCivs( GameInfo.Worlds[ PreGame.GetWorldSize() ].DefaultMinorCivs )
		end
	end

	-- Map sizes
	local pullDown = Controls.MapSizePullDown
	pullDown:ClearEntries()
	local map = script and GameInfo.Map_Sizes{ FileName = script }()
	local numMapSizes = 0
	local mapSizes = {}
	if map then
		for row in GameInfo.Map_Sizes{ MapType = map.MapType } do
			mapSizes[ row.WorldSizeType ] = row
			numMapSizes = numMapSizes + 1
		end
	end
	if wb and numMapSizes < 2 or g_MapCivList then
		pullDown:SetDisabled( true )
		PreGame.SetRandomWorldSize( false )
	else
		pullDown:SetDisabled( false )
		local instance = {}
		pullDown:BuildEntry( "InstanceOne", instance )
		LocalizeAndSetTextAndToolTip( instance.Button, "TXT_KEY_RANDOM_MAP_SIZE", "TXT_KEY_RANDOM_MAP_SIZE_HELP" )
		instance.Button:SetVoid1( -1 )
		for row in GameInfo.Worlds() do
			if not wb or mapSizes[ row.Type ] then
				pullDown:BuildEntry( "InstanceOne", instance )
				LocalizeAndSetTextAndToolTip( instance.Button, row.Description, row.Help )
				instance.Button:SetVoid1( row.ID )
			end
		end
	end
	pullDown:CalculateInternals()

	-- Map types
	local button = Controls.MapTypePullDown:GetButton()
	if script then
		local name
		local map = GameInfo.MapScripts{ FileName = script }()
		if not map then
			map = GameInfo.Map_Sizes{ FileName = script }()
			map = map and GameInfo.Maps[ map.MapType ]
		end
		if not map then
			for _, row in pairs( Modding.GetMapFiles() ) do
				if row.File == script then
					local mapData = UI.GetMapPreview( script )
					name = not Locale.IsNilOrWhitespace( row.Name ) and row.Name
							or not Locale.IsNilOrWhitespace( mapData.Name ) and mapData.Name
							or Path.GetFileNameWithoutExtension( row.File )
					map = not Locale.IsNilOrWhitespace( row.Description ) and row or mapData
					break
				end
			end
		end
		if map then
			LocalizeAndSetTextAndToolTip( button, name or map.Name, map.Description )
		end
		PreGame.SetRandomMapScript( not map )
	end
	if PreGame.IsRandomMapScript() then
		LocalizeAndSetTextAndToolTip( button, "TXT_KEY_RANDOM_MAP_SCRIPT", "TXT_KEY_RANDOM_MAP_SCRIPT_HELP" )
		Controls.MapScript:LocalizeAndSetText( "TXT_KEY_RANDOM_MAP_SCRIPT" )
	else
		Controls.MapScript:SetText( Path.GetFileName( script ) )
	end
	-- Civilization
	for playerID, instance in ipairs( g_SlotInstances ) do
		pullDown = instance.CivPullDown
		pullDown:ClearEntries()
		for _, civ in ipairs( g_MapCivList or g_GameCivList ) do
			pullDown:BuildEntry( "InstanceOne", instance )
			instance.Button:SetVoids( playerID, civ.ID )
			instance.Button:LocalizeAndSetText( "TXT_KEY_RANDOM_LEADER_CIV", civ.LeaderDescription, civ.ShortDescription )
			instance.Button:LocalizeAndSetToolTip( civ.Description )
		end
		pullDown:CalculateInternals()
	end
	PreGame.SetSlotStatus( 0, SlotStatus.SS_TAKEN )
end

local function SelectMapScript( mapScript )
	-- If this is an "error" entry (invalid WB file for example), do nothing.
	local script = mapScript.FileName
	if mapScript.MapType then
		local row = GameInfo.Worlds[ PreGame.GetWorldSize() ]
		row = row and GameInfo.Map_Sizes{ MapType = mapScript.MapType, WorldSizeType = row.Type }() or GameInfo.Map_Sizes{ MapType = mapScript.MapType }()
		if row then
			script = row.FileName
			row = GameInfo.Worlds[ row.WorldSizeType ]
		end
		if row then
			SetWorldSizeAndDefaultPlayers( row.ID )
		end
	elseif mapScript.DefaultCityStates then
		PreGame.SetNumMinorCivs( mapScript.DefaultCityStates )
	end
	SetMapScriptAndWB( script, mapScript.WBMapData )
	return PerformRefresh()
end

local function SortOptions( a, b )
	if a.SortPriority == b.SortPriority then
		return Locale.Compare( a.Name, b.Name ) == -1
	else
		return a.SortPriority < b.SortPriority
	end
end

function PerformRefresh()
	local info, pullDown, button
	local instance = {}

	-- Refresh all dynamic drop down game options
	g_DropDownOptionsManager:ResetInstances()

	local mapScript = not PreGame.IsRandomMapScript() and PreGame.GetMapScript() or nil

	local options = {}
	for option in Query( "select * from MapScriptOptions where exists (select 1 from MapScriptOptionPossibleValues where FileName = MapScriptOptions.FileName and OptionID = MapScriptOptions.OptionID) and Hidden = 0 and FileName = ?", mapScript ) do
		options[ option.OptionID ] = {
			ID = option.OptionID,
			Name = option.Name,
			ToolTip = option.Description,
			Disabled = option.ReadOnly == 1,
			DefaultValue = option.DefaultValue,
			SortPriority = option.SortPriority,
			Values = {},
		}
	end

	for possibleValue in Query( "select * from MapScriptOptionPossibleValues where FileName = ? order by SortIndex ASC", mapScript ) do
		if options[ possibleValue.OptionID ] then
			insert(options[possibleValue.OptionID].Values, {
				Name	= possibleValue.Name,
				ToolTip = possibleValue.Description,
				Value	= possibleValue.Value,
			})
		end
	end

	local sortedOptions = {}
	for _,v in pairs(options) do
		insert( sortedOptions, v )
	end
	sort( sortedOptions, SortOptions )

	for _, option in ipairs( sortedOptions ) do
		instance = g_DropDownOptionsManager:GetInstance()
		LocalizeAndSetTextAndToolTip( instance.OptionName, option.Name, option.ToolTip )
		pullDown = instance.OptionDropDown
		pullDown:SetDisabled( option.Disabled )
		pullDown:ClearEntries()
		for _, possibleValue in ipairs( option.Values ) do
			pullDown:BuildEntry( "InstanceOne", instance )
			LocalizeAndSetTextAndToolTip( instance.Button, possibleValue.Name, possibleValue.ToolTip )
			instance.Button:RegisterCallback( eLClick, function()
				PreGame.SetMapOption( option.ID, possibleValue.Value )
				return PerformRefresh()
			end)
		end
		pullDown:CalculateInternals()
		--Assign the currently selected value.
		info = option.Values[ PreGame.GetMapOption( option.ID ) ] or option.Values[ option.DefaultValue ]
		LocalizeAndSetTextAndToolTip( pullDown:GetButton(), info and info.Name, info and info.ToolTip )
		pullDown:SetDisabled( option.Disabled )
	end

	-- Refresh all dynamic checkbox game options
	g_GameOptionsManager:ResetInstances()
	options = {}
	for option in GameInfo.GameOptions{ Visible = 1, SupportsSinglePlayer = 1 } do
		info = PreGame.GetGameOption( option.Type )
		insert( options, {
			TypeOrID = option.Type,
			Name = option.Description,
			ToolTip = option.Help,
			Checked = info == 1 or not info and option.Default == 1,
			Disabled = false,
			SortPriority = 0,
		} )
	end
	for option in Query( "select * from MapScriptOptions where not exists (select 1 from MapScriptOptionPossibleValues where FileName = MapScriptOptions.FileName and OptionID = MapScriptOptions.OptionID) and Hidden = 0 and FileName = ?", PreGame.GetMapScript() ) do
		info = PreGame.GetMapOption( option.OptionID )
		insert( options, {
			TypeOrID = option.OptionID,
			Name = option.Name,
			ToolTip = option.Description,
			Checked = info == 1 or not info and option.DefaultValue == 1,
			Disabled = option.ReadOnly == 1,
			SortPriority = option.SortPriority,
		} )
	end
	sort( options, SortOptions )

	for _, option in ipairs( options ) do
		instance = g_GameOptionsManager:GetInstance().GameOptionRoot
		instance:GetTextButton():LocalizeAndSetText( option.Name )
		instance:LocalizeAndSetToolTip( option.ToolTip )
		instance:SetDisabled( option.Disabled )
		instance:SetCheck( option.Checked )
		option = option.TypeOrID
		instance:RegisterCheckHandler( function( bCheck )
			PreGame.SetGameOption( option, bCheck )
			return PerformRefresh()
		end)
	end

	-- Eras
	info = GameInfo.Eras[ PreGame.GetEra() ]
	LocalizeAndSetTextAndToolTip( Controls.EraPullDown:GetButton(), info and info.Description, info and info.Strategy )

	-- Game speeds
	info = GameInfo.GameSpeeds[ PreGame.GetGameSpeed() ]
	LocalizeAndSetTextAndToolTip( Controls.GameSpeedPullDown:GetButton(), info and info.Description, info and info.Help )

	-- MaxTurns
	local maxTurns = PreGame.GetMaxTurns()
	if maxTurns > 0 then
		Controls.MaxTurnsCheck:SetCheck( true )
	end
	Controls.MaxTurnsEditbox:SetHide( not Controls.MaxTurnsCheck:IsChecked() )
	Controls.MaxTurnsEdit:SetText( maxTurns )

	-- Victory conditions
	g_VictoryCondtionsManager:ResetInstances()
	for row in GameInfo.Victories() do
		instance = g_VictoryCondtionsManager:GetInstance().GameOptionRoot
		instance:GetTextButton():LocalizeAndSetText( row.Description )
		row = row.ID
		instance:SetCheck( PreGame.IsVictory(row) )
		instance:SetDisabled( g_MapCivList )
		instance:RegisterCheckHandler( function(bCheck)
			PreGame.SetVictory( row, bCheck )
			return PerformRefresh()
		end)
	end

	-- Map sizes
	local isRandomWorldSize = PreGame.IsRandomWorldSize()
	if isRandomWorldSize then
		LocalizeAndSetTextAndToolTip( Controls.MapSizePullDown:GetButton(), "TXT_KEY_RANDOM_MAP_SIZE", "TXT_KEY_RANDOM_MAP_SIZE_HELP" )
	else
		info = GameInfo.Worlds[ PreGame.GetWorldSize() ]
		LocalizeAndSetTextAndToolTip( Controls.MapSizePullDown:GetButton(), info and info.Description, info and info.Help )
	end

	-- MinorCivs
	Controls.MinorCivsSlider:SetHide( g_MapCivList or isRandomWorldSize )
	Controls.MinorCivsLabel:SetHide( isRandomWorldSize )
	if not isRandomWorldSize then
		Controls.MinorCivsSlider:SetValue( PreGame.GetNumMinorCivs() / g_MaxMinorCivs )
		Controls.MinorCivsLabel:LocalizeAndSetText( "TXT_KEY_AD_SETUP_CITY_STATES", PreGame.GetNumMinorCivs() )
	end

	-- Civilizations
	local playerCount = 0
	local isNotHotSeat = not PreGame.IsHotSeatGame()
	Controls.ListingScrollPanel:SetHide( isRandomWorldSize )
	Controls.UnknownPlayers:SetHide( not isRandomWorldSize )
	Controls.AddAIButton:SetDisabled( g_MapCivList or isRandomWorldSize )

	for playerID, instance in ipairs( g_SlotInstances ) do

		info = PreGame.GetSlotStatus( playerID )
		if info ~= SlotStatus.SS_COMPUTER and info ~= SlotStatus.SS_TAKEN then
			instance.Root:SetHide( true )
		else
			instance.Root:SetHide( false )
			playerCount = playerCount + 1
			instance.CivNumberIndex:LocalizeAndSetText( "TXT_KEY_NUMBERING_FORMAT", playerCount )
			-- Games must always have at least 2 players
			instance.RemoveButton:SetHide( playerCount < 3 or g_MapCivList )

			-- Handicap
			pullDown = instance.HandicapPullDown
			DisplayHandicap( pullDown:GetButton(), GameInfo.HandicapInfos[ PreGame.GetHandicap( playerID ) ] )
			info = g_SlotStatusInfo[ PreGame.GetSlotStatus( playerID ) ] or {}
			LocalizeAndSetTextAndToolTip( instance.SlotStatus, info[1], info[2] )
			pullDown:SetDisabled( playerID ~= 0 and isNotHotSeat )

			-- Team
			instance.TeamPullDown:GetButton():LocalizeAndSetText( "TXT_KEY_MULTIPLAYER_DEFAULT_TEAM_NAME", PreGame.GetTeam( playerID ) + 1 )
			instance.TeamPullDown:SetHide( g_MapCivList )

			-- Civilization
			local civ = g_GameCivs[ PreGame.GetCivilization( playerID ) ] or g_RandomCiv
			local leaderName = PreGame.GetLeaderName( playerID )
			local civName = PreGame.GetCivilizationShortDescription( playerID )
			local civDesc = PreGame.GetCivilizationDescription( playerID )
			button = instance.CivPullDown:GetButton()
			button:LocalizeAndSetText( "TXT_KEY_RANDOM_LEADER_CIV", leaderName ~= "" and leaderName or civ.LeaderDescription, civName ~= "" and civName or civ.ShortDescription )
			button:LocalizeAndSetToolTip( civDesc~="" and civDesc or civ.Description )
			IconHookup( civ.LeaderPortraitIndex, 64, civ.LeaderIconAtlas, instance.Portrait )
			IconHookup( civ.PortraitIndex, 64, civ.IconAtlas, instance.Icon )
		end
	end
	Controls.CivCount:LocalizeAndSetText( "TXT_KEY_AD_SETUP_CIVILIZATION", playerCount )

	-- Resize stacks & panels
	Controls.VictoryConditionsStack:CalculateSize()
	Controls.VictoryConditionsStack:ReprocessAnchoring()
	Controls.CityStateStack:CalculateSize()
	Controls.CityStateStack:ReprocessAnchoring()
	Controls.DropDownOptionsStack:CalculateSize()
	Controls.DropDownOptionsStack:ReprocessAnchoring()
	Controls.MaxTurnStack:CalculateSize()
	Controls.MaxTurnStack:ReprocessAnchoring()
	Controls.GameOptionsStack:CalculateSize()
	Controls.GameOptionsStack:ReprocessAnchoring()
	Controls.GameOptionsFullStack:CalculateSize()
	Controls.GameOptionsFullStack:ReprocessAnchoring()
	Controls.SlotStack:CalculateSize()
	Controls.SlotStack:ReprocessAnchoring()
	Controls.OptionsScrollPanel:CalculateInternalSize()
	Controls.ListingScrollPanel:CalculateInternalSize()

	-- Validate team setup
	Controls.StartButton:LocalizeAndSetText( PreGame.GetLoadWBScenario() and "TXT_KEY_START_SCENARIO" or "TXT_KEY_START_GAME" )
	local playerTeam = PreGame.GetTeam( 0 )
	for playerID = 1, GameDefines.MAX_MAJOR_CIVS-1 do
		info = PreGame.GetSlotStatus( playerID )
		if info == SlotStatus.SS_COMPUTER or info == SlotStatus.SS_TAKEN then
			if PreGame.GetTeam(playerID) ~= playerTeam then
				Controls.StartButton:SetDisabled( false )
				return Controls.StartButton:SetToolTipString()
			end
		end
	end
	Controls.StartButton:SetDisabled( true )
	Controls.StartButton:LocalizeAndSetToolTip( "TXT_KEY_BAD_TEAMS" )
end

local function PerformInit()

--[[
local function list( n )
	print( n, ("-"):rep(20) )
	for row in GameInfo[n]() do
		local t = {}
		for k, v in pairs(row) do
			insert( t, tostring(k) )
			insert( t, tostring(v) )
		end
		print( table.concat( t, "\t" ) )
	end
end

list( "MapScripts" )
list( "Maps" )
list( "Map_Sizes" )

print"PerformInit start"
--]]
	-- Map types
	local pullDown = Controls.MapTypePullDown
	pullDown:ClearEntries()

	local mapScriptList = { [0] = g_RandomMap }
	for row in GameInfo.MapScripts{ SupportsSinglePlayer = 1, Hidden = 0 } do
		insert( mapScriptList, {
			Name = row.Name,
			FileName = row.FileName,
			Description = row.Description,
			DefaultCityStates = row.DefaultCityStates,
		} )
	end
	for row in GameInfo.Maps() do
		insert( mapScriptList, {
			Name = row.Name,
			Description = row.Description,
			MapType = row.Type,
		} )
	end
	-- Filter out map files that are part of size groups.
	local worldBuilderMapsToFilter = {}
	for row in GameInfo.Map_Sizes() do
		worldBuilderMapsToFilter[ row.FileName ] = true
	end
	for _, map in ipairs( Modding.GetMapFiles() ) do
		if not worldBuilderMapsToFilter[ map.File ] then
			local mapData = UI.GetMapPreview( map.File )
			insert( mapScriptList, {
				Name = not Locale.IsNilOrWhitespace( map.Name ) and map.Name or mapData and not Locale.IsNilOrWhitespace( mapData.Name ) and mapData.Name or Path.GetFileNameWithoutExtension( map.File ),
				Description = mapData and ( not Locale.IsNilOrWhitespace( map.Description ) and map.Description or mapData.Description ),
				FileName = mapData and map.File,
				WBMapData = mapData,
				Error = not mapData,
			} )
		end
	end
	sort( mapScriptList, SortNames )

	local instance = {}
	for _, script in ipairs( mapScriptList ) do
		pullDown:BuildEntry( "InstanceOne", instance )
		instance.Button:LocalizeAndSetToolTip( script.Description or "TXT_KEY_INVALID_MAP_DESC" )
		if script.Error then
			instance.Button:LocalizeAndSetText( "TXT_KEY_INVALID_MAP_TITLE", script.Name )
		else
			instance.Button:LocalizeAndSetText( script.Name )
			instance.Button:RegisterCallback( eLClick, function() SelectMapScript( script ) end )
		end
	end
	pullDown:CalculateInternals()

print"PerformInit Eras"
	-- Eras
	pullDown = Controls.EraPullDown
	pullDown:ClearEntries()
	for info in GameInfo.Eras() do
		pullDown:BuildEntry( "InstanceOne", instance )
		instance.Button:LocalizeAndSetText( info.Description )
		instance.Button:SetVoid1( info.ID )
	end
	pullDown:CalculateInternals()

print"PerformInit Speeds"
	-- GameSpeeds
	pullDown = Controls.GameSpeedPullDown
	pullDown:ClearEntries()
	local gameSpeeds = {}
	for row in GameInfo.GameSpeeds() do
		insert(gameSpeeds, row)
	end
	sort( gameSpeeds, SortSpeeds )
	for _, v in ipairs( gameSpeeds ) do
		pullDown:BuildEntry( "InstanceOne", instance )
		instance.Button:LocalizeAndSetText( v.Description )
		instance.Button:LocalizeAndSetToolTip( v.Help )
		instance.Button:SetVoid1( v.ID )
	end
	pullDown:CalculateInternals()

print"PerformInit Civs"
	-- Civilizations
	g_MaxMinorCivs = min( 41, #GameInfo.MinorCivilizations )
	g_GameCivs = {}
	g_GameCivList = { [0]=g_RandomCiv }
	local leader, playable
	for civ in GameInfo.Civilizations() do
		leader = GameInfo.Civilization_Leaders{ CivilizationType = civ.Type }()
		leader = leader and GameInfo.Leaders[ leader.LeaderheadType ]
		playable = civ.Playable
		if leader then
			civ = {
				ID = civ.ID,
				Type = civ.Type,
				Description = civ.Description,
				ShortDescription = civ.ShortDescription,
				PortraitIndex = civ.PortraitIndex,
				IconAtlas = civ.IconAtlas,
				LeaderID = leader.ID,
				LeaderDescription = leader.Description,
				LeaderPortraitIndex = leader.PortraitIndex,
				LeaderIconAtlas = leader.IconAtlas,
			}
			if playable then
				insert( g_GameCivList, civ )
			end
			g_GameCivs[ civ.ID ] = civ
		end
	end
	sort( g_GameCivList, SortCivs )

print"PerformInit Difficulty"
	-- Difficulty
	for playerID, instance in pairs( g_SlotInstances ) do
		pullDown = instance.HandicapPullDown
		pullDown:ClearEntries()
		for handicap in GameInfo.HandicapInfos() do
--			if playerID ~=0 or handicap.ID ~= g_AIdefaultHandicapID then
				pullDown:BuildEntry( "InstanceOne", instance )
				DisplayHandicap( instance.Button, handicap )
				instance.Button:SetVoids( playerID, handicap.ID )
--			end
		end
		pullDown:CalculateInternals()
	end

print"PerformInit done"
end

----------------------------------------------------------------
-- Handlers
----------------------------------------------------------------
local function ClosePopup()
	UIManager:DequeuePopup( ContextPtr )
end

Controls.BackButton:RegisterCallback( eLClick, ClosePopup )

ContextPtr:SetInputHandler( function( uiMsg, wParam )
	if uiMsg == KeyDown then
		if wParam == VK_ESCAPE then
		    ClosePopup()
			return true
		end
	end
end)

Controls.EditButton:RegisterCallback( eLClick, function()
	UIManager:PushModal( Controls.SetCivNames )
end)

Controls.CancelButton:RegisterCallback( eLClick, function()
	CancelPlayerDetails( 0 )
	return PerformRefresh()
end)

Controls.MinorCivsSlider:RegisterSliderCallback( function( fValue )
	PreGame.SetNumMinorCivs( floor( fValue * g_MaxMinorCivs ) )
	return PerformRefresh()
end)

Controls.AddAIButton:RegisterCallback( eLClick, function()
	for playerID = 1, GameDefines.MAX_MAJOR_CIVS-1 do
		local slotStatus = PreGame.GetSlotStatus( playerID )
		if slotStatus ~= SlotStatus.SS_COMPUTER and slotStatus ~= SlotStatus.SS_TAKEN then
			PreGame.SetSlotStatus( playerID, SlotStatus.SS_COMPUTER )
			PreGame.SetHandicap( playerID, g_AIdefaultHandicapID )
			break
		end
	end
	return PerformRefresh()
end)

Controls.MaxTurnsCheck:RegisterCallback( eLClick, function( isChecked )
	Controls.MaxTurnsEditbox:SetHide( not isChecked )
	if not isChecked then
		PreGame.SetMaxTurns( 0 )
	end
	return PerformRefresh()
end)

Controls.MaxTurnsEdit:RegisterCallback( function()
	PreGame.SetMaxTurns( Controls.MaxTurnsEdit:GetText() )
	return PerformRefresh()
end)

Controls.GameSpeedPullDown:RegisterSelectionCallback( function( speedID )
	PreGame.SetGameSpeed( speedID )
	return PerformRefresh()
end)

Controls.EraPullDown:RegisterSelectionCallback( function( eraID )
	PreGame.SetEra( eraID )
	return PerformRefresh()
end)

Controls.MapSizePullDown:RegisterSelectionCallback( function( worldSizeID )
print( "SelectMapSize", worldSizeID )
	if worldSizeID == -1 then
		PreGame.SetRandomWorldSize( true )
	else
		SetWorldSizeAndDefaultPlayers( worldSizeID )
		local world = GameInfo.Worlds[ worldSizeID ]
		if world then
			PreGame.SetNumMinorCivs( world.DefaultMinorCivs )
			local row = not PreGame.IsRandomMapScript() and GameInfo.Map_Sizes{ FileName = PreGame.GetMapScript() }()
			row = row and GameInfo.Map_Sizes{ MapType = row.MapType, WorldSizeType = world.Type }()
print( "SelectMapSize", row )
			if row then
				SetMapScriptAndWB( row.FileName )
			end
		end
	end
	return PerformRefresh()
end)

Controls.DefaultButton:RegisterCallback( eLClick, function()
	Controls.CancelButton:SetHide( true )

	-- Default civs
	for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
		PreGame.SetCivilization( playerID, -1 )
		PreGame.SetTeam( playerID, playerID )
		CancelPlayerDetails( playerID )
	end

	-- Default Map Size
	local worldSize = GameInfo.Worlds.WORLDSIZE_SMALL or GameInfo.Worlds()() -- Get first world size found.
	SetWorldSizeAndDefaultPlayers( worldSize.ID )
	PreGame.SetNumMinorCivs( worldSize.DefaultMinorCivs )

	-- Default Map Type
	PreGame.SetLoadWBScenario( false )
	local mapScript = GameInfo.MapScripts{ FileName = "Assets\\Maps\\Continents.lua" }()
	PreGame.SetRandomMapScript( not mapScript )
	if mapScript then
		PreGame.SetMapScript( mapScript.FileName )
	end

	-- Default Game Pace
	PreGame.SetGameSpeed( ( GameInfo.GameSpeeds.GAMESPEED_STANDARD or GameInfo.GameSpeeds()() ).ID )

	-- Default Start Era
	PreGame.SetEra( ( GameInfo.Eras.ERA_ANCIENT or GameInfo.Eras()() ).ID )

	--Default Difficulty to Chieftain
	PreGame.SetHandicap( 0, (GameInfo.HandicapInfos.HANDICAP_PRINCE or GameInfo.HandicapInfos()()).ID )

	for row in GameInfo.Victories() do
		PreGame.SetVictory( row.ID, true )
	end

	-- Reset Max Turns
	PreGame.SetMaxTurns( 0 )
	PreGame.ResetSlots()
	PreGame.ResetGameOptions()
	PreGame.ResetMapOptions()
	if not g_IsModding then
		PreGame.LoadPreGameSettings()
	end

	return PerformRefresh()
end)

local function PrintCivs()
	local function FindKey( table, value )
		for k, v in pairs(table) do
			if v == value then
				return k
			end
		end
	end
	for playerID=0, GameDefines.MAX_MAJOR_CIVS-1 do
		print( "playerID", playerID, "civID", PreGame.GetCivilization( playerID ), "teamID", PreGame.GetTeam( playerID ), FindKey( SlotStatus, PreGame.GetSlotStatus( playerID ) ), "handicapID", PreGame.GetHandicap( playerID ) )
	end
	print( "Number of minor civs:", PreGame.GetNumMinorCivs() )
end

Controls.StartButton:RegisterCallback( eLClick, function()
	PreGame.SetPersistSettings( not g_IsModding and not PreGame.IsHotSeatGame() )
	PrintCivs()
	local ss = {}
	for playerID=0, GameDefines.MAX_MAJOR_CIVS-1 do
		ss[ playerID ] = PreGame.GetSlotStatus( playerID )
	end
		
	Events.SerialEventStartGame.Add( function()
		print"Events.SerialEventStartGame"
		PrintCivs()
		for playerID=0, GameDefines.MAX_MAJOR_CIVS-1 do
			PreGame.SetSlotStatus( playerID, ss[ playerID ] )
		end
	end)
	Events.SerialEventStartGame()
	UIManager:SetUICursor( 1 )
end)

----------------------------------------------------------------
-- Visibility Handler
----------------------------------------------------------------
ContextPtr:SetShowHideHandler( function( bIsHide )
	if not bIsHide then
		if g_RequestInit then
			g_RequestInit = false
			PerformInit()
		end
		g_IsModding = #Modding.GetActivatedMods() > 0
		Controls.TitleLabel:LocalizeAndSetText( (g_IsModding and "{TXT_KEY_MODS} " or "")..(PreGame.IsHotSeatGame() and "{TXT_KEY_MULTIPLAYER_HOTSEAT_GAME:upper} " or "{TXT_KEY_AD_SETUP_ADVANCED_OPTIONS}") )
		SetMapScriptAndWB( PreGame.GetMapScript() )
		return PerformRefresh()
	end
end)

-----------------------------------------------------------------
-- Adjust for resolution
-----------------------------------------------------------------
local function AdjustScreenSize()
	local _, screenY = UIManager:GetScreenSizeVal()

	local TOP_COMPENSATION = 52 + ((screenY - 768) * 0.3 )
	local BOTTOM_COMPENSATION = 190
	local LOCAL_SLOT_COMPENSATION = 74

	Controls.MainGrid:SetSizeY( screenY - TOP_COMPENSATION )
	Controls.ListingScrollPanel:SetSizeY( screenY - TOP_COMPENSATION - BOTTOM_COMPENSATION - LOCAL_SLOT_COMPENSATION )
	Controls.OptionsScrollPanel:SetSizeY( screenY - TOP_COMPENSATION - BOTTOM_COMPENSATION )

	Controls.ListingScrollPanel:CalculateInternalSize()
	Controls.OptionsScrollPanel:CalculateInternalSize()
end

Events.SystemUpdateUI.Add( function( id )
	if id == SystemUpdateUITypeScreenResize then
		AdjustScreenSize()
	end
end)
AdjustScreenSize()

-----------------------------------------------------------------
-- When mods affect game state, re-initialzation is required
-----------------------------------------------------------------
local function RequireInit()
	g_RequestInit = true
end
Events.AfterModsActivate.Add( RequireInit )
Events.AfterModsDeactivate.Add( RequireInit )

-----------------------------------------------------------------
-- Create slot instances
-----------------------------------------------------------------
local function RemovePlayer( playerID )
	PreGame.SetSlotStatus( playerID, SlotStatus.SS_CLOSED )
	return PerformRefresh()
end

local function SelectPlayerTeam( playerID, teamID )
	PreGame.SetTeam( playerID, teamID )
	return PerformRefresh()
end

local function SelectHandicap( playerID, handicapID )
	PreGame.SetSlotStatus( playerID, handicapID == g_AIdefaultHandicapID and SlotStatus.SS_COMPUTER or SlotStatus.SS_TAKEN )
	PreGame.SetHandicap( playerID, handicapID )
	return PerformRefresh()
end

local function SelectCivilization( playerID, civID )
	if g_MapCivList then
		SetScenarioCivilization( playerID, civID )
	else
		PreGame.SetCivilization( playerID, civID )
		CancelPlayerDetails( playerID )
	end
	return PerformRefresh()
end

local instance
local pullDown
for playerID = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
	instance = {}
	g_SlotInstances[ playerID ] = instance
	ContextPtr:BuildInstanceForControl( "PlayerSlot", instance, Controls.SlotStack )
	instance.RemoveButton:RegisterCallback( eLClick, RemovePlayer )
	instance.RemoveButton:SetVoid1( playerID )
	pullDown = instance.TeamPullDown
	pullDown:ClearEntries()
	for teamID = 1, GameDefines.MAX_MAJOR_CIVS do
		pullDown:BuildEntry( "InstanceOne", instance )
		instance.Button:LocalizeAndSetText( "TXT_KEY_MULTIPLAYER_DEFAULT_TEAM_NAME", teamID )
		instance.Button:SetVoids( playerID, teamID-1 )
	end
	pullDown:CalculateInternals()
	pullDown:RegisterSelectionCallback( SelectPlayerTeam )
	instance.HandicapPullDown:RegisterSelectionCallback( SelectHandicap )
	instance.CivPullDown:RegisterSelectionCallback( SelectCivilization )
end
g_SlotInstances[0].Root:ChangeParent( Controls.HumanPlayer )
