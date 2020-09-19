-------------------------------------------------
-- Main Menu
-- Re-written by bc1 using Notepad++
-------------------------------------------------

print( "IsHotLoad", ContextPtr:IsHotLoad(), "GameStarted", PreGame.GameStarted() )

include "MPGameDefaults"
local ResetMultiplayerOptions = ResetMultiplayerOptions

local ContextPtr = ContextPtr
local Controls = Controls
local Events = Events
local Modding = Modding
local Network = Network
local PopupPriority = PopupPriority
local PreGame = PreGame
local Steam = Steam
local UI = UI
local UIManager = UIManager
local L = Locale.ConvertTextKey

local SystemUpdateUITypeRestoreUI = SystemUpdateUIType.RestoreUI
local GAME_SINGLE_PLAYER = GameTypes.GAME_SINGLE_PLAYER
local GAME_NETWORK_MULTIPLAYER = GameTypes.GAME_NETWORK_MULTIPLAYER
local GAME_HOTSEAT_MULTIPLAYER = GameTypes.GAME_HOTSEAT_MULTIPLAYER
local KeyDown = KeyEvents.KeyDown
local VK_ESCAPE = Keys.VK_ESCAPE
local eLClick = Mouse.eLClick

local insert = table.insert
local concat = table.concat
local pairs = pairs

local SelectedMenu, GameInfo
local MenuContainers = {}
local MenuFuntions = {}

-------------------------------------------------
-- Script Body

local function QueuePopupIfHidden( control, priority )
	if control and control:IsHidden() then
		print( "Queing popup", control:GetID() )
		UIManager:QueuePopup( control, priority )
	else
		print( "Popup nil or not hiddden", control and control:GetID() )
	end
end

local function PreGameReset( mode )
	PreGame.Reset()
	PreGame.SetInternetGame( false )
	PreGame.SetPrivateGame( false )
	PreGame.SetGameType( mode )
	PreGame.ResetSlots()
	PreGame.ResetGameOptions()
	PreGame.ResetMapOptions()
end

local function HotSeatSetup()
	PreGameReset( GAME_HOTSEAT_MULTIPLAYER )
	return QueuePopupIfHidden( Modding.GetActivatedModEntryPoints"Custom"() and Controls.ModsCustom or Controls.AdvancedSetup, PopupPriority.AdvancedSetup )
end

local function SelectMenu( n )
print( "SelectMenu", n )
	if not SelectedMenu then

		Controls.VersionNumber:SetText( UI.GetVersionInfo():match"[%w%.]*" )
		Steam.SetOverlayNotificationPosition( "bottom_left" )
		Controls.TouchHelpButton:RegisterCallback( eLClick, function() Controls.TouchControlsMenu:SetHide( false ) end )
		Controls.TouchHelpButton:SetHide( not UI.IsTouchScreenEnabled() )

		local MenuStack, PlayNowButton, ReconnectButton
		local MenuStackID = 0

		local function SinglePlayerMenu()
print( "SinglePlayerMenu" )
			if not GameInfo then
				include "GameInfoCache"
				GameInfo = GameInfoCache
			end
			PreGameReset( GAME_SINGLE_PLAYER )
			PreGame.LoadPreGameSettings()

			local tips = { L"TXT_KEY_PLAY_NOW_SETTINGS" }
			local tip, info
		  
			local civ = GameInfo.Civilizations[ PreGame.GetCivilization( 0 ) ]
			if civ then
				info = GameInfo.Leaders{ Type = GameInfo.Civilization_Leaders{ CivilizationType = civ.Type }().LeaderheadType }()
				insert( tips, L( "TXT_KEY_RANDOM_LEADER_CIV", info.Description, civ.ShortDescription ) )
			else
				PreGame.SetCivilization( 0, -1 )
				insert( tips, L"TXT_KEY_RANDOM_LEADER" )
			end

			if not PreGame.IsRandomMapScript() then
				local map = PreGame.GetMapScript()
				map = GameInfo.MapScripts{ FileName = map }() or UI.GetMapPreview(map)
				if map then
					tip = map.Name or map.Description
				end
			end
			PreGame.SetRandomMapScript( not tip )
			insert( tips, L"TXT_KEY_MAP_SCRIPT" .. ": " .. L( tip or "TXT_KEY_RANDOM_MAP_SCRIPT" ) )

			info = not PreGame.IsRandomWorldSize() and GameInfo.Worlds[ PreGame.GetWorldSize() ]
			insert( tips, L( "TXT_KEY_MAP_SIZE_FORMAT", info and info.Description or "TXT_KEY_RANDOM_MAP_SIZE" ) )
			PreGame.SetRandomWorldSize( not info )

			info = GameInfo.HandicapInfos[ PreGame.GetHandicap( 0 ) ]
			if info then
				insert( tips, L( "TXT_KEY_AD_HANDICAP_SETTING", info.Description ) )
			end
			
			info = GameInfo.GameSpeeds[ PreGame.GetGameSpeed() ]
			if info then
				insert( tips, L( "TXT_KEY_AD_GAME_SPEED_SETTING", info.Description ) )
			end
			
			PlayNowButton.Button:SetToolTipString( concat(tips, "[NEWLINE]") )
		end

		local function GotoLobby( multiplayerLobbyMode )
print( "GotoLobby", multiplayerLobbyMode )
			UI.SetMultiplayerLobbyMode( multiplayerLobbyMode )
			PreGame.SetInternetGame( multiplayerLobbyMode % 2 == 0 ) --LOBBYMODE_STANDARD_INTERNET = 0, LOBBYMODE_STANDARD_LAN = 1, LOBBYMODE_PITBOSS_INTERNET = 2, LOBBYMODE_PITBOSS_LAN = 3
			PreGame.SetGameType( GAME_NETWORK_MULTIPLAYER )
			PreGame.ResetSlots()
			ResetMultiplayerOptions() -- Apply multiplayer default settings
			QueuePopupIfHidden( Controls.LobbyScreen, PopupPriority.LobbyScreen )
		end

		local function BuildEntry( text, command, data )
			local button = {}
			ContextPtr:BuildInstanceForControl( "MenuButton320", button, MenuStack )
			if type(command)=="function" then
				button.Button:RegisterCallback( eLClick, command )
				button.Button:SetVoid1( data )
			elseif type(command)=="table" then
				button.Button:RegisterCallback( eLClick, function() QueuePopupIfHidden( command, data ) end )
			else
				button.Button:SetDisabled( true )
			end
			button.Button:LocalizeAndSetText( text )
			return button
		end

		local function BuildEntryTT( toolTip, ... )
			local button = BuildEntry( ... )
			button.Button:LocalizeAndSetToolTip( toolTip )
			return button
		end

		local function BuildMenuStack( label, menuFunction )
			local stack = {}
			ContextPtr:BuildInstanceForControl( "Menu", stack, Controls.FadeIn )
			MenuStack = stack.Stack
			stack.Label:LocalizeAndSetText( label )
			MenuContainers[MenuStackID] = stack.Container
			MenuFuntions[MenuStackID] = menuFunction
			MenuStackID = MenuStackID + 1
		end

		-- Main Menu
		BuildMenuStack "TXT_KEY_MODDING_MAINMENU"
		BuildEntryTT( "TXT_KEY_LOAD_GAME_TT", "TXT_KEY_MENU_LOAD_GAME_BUTTON", Controls.LoadGameScreen, PopupPriority.MPLoadGameScreen ).Trim:SetHide( true )
		BuildEntry( "TXT_KEY_MODDING_SINGLE_PLAYER", SelectMenu, 1 )
		BuildEntryTT( "TXT_KEY_MULTIPLAYER_TT", "TXT_KEY_MULTIPLAYER", SelectMenu, 2 )
		BuildEntryTT( "TXT_KEY_MODS_TT", "TXT_KEY_MODS", Controls.ModsBrowser, PopupPriority.ModsBrowserScreen )
		BuildEntry( "TXT_KEY_LOAD_MENU_DLC", Controls.PremiumContentScreen, PopupPriority.OtherMenu )
		BuildEntryTT( "TXT_KEY_OPTIONS_TT", "TXT_KEY_OPTIONS", Controls.OptionsMenu_FrontEnd, PopupPriority.OptionsMenu )
		BuildEntryTT( "TXT_KEY_OTHER_TT", "TXT_KEY_OTHER", SelectMenu, 3 )
		BuildEntryTT( "TXT_KEY_EXIT_TT", "TXT_KEY_EXIT_BUTTON", Events.UserRequestClose.Call )

		-- Single Player
		BuildMenuStack( "TXT_KEY_MODDING_SINGLE_PLAYER", SinglePlayerMenu )
		PlayNowButton = BuildEntryTT( "TXT_KEY_PLAY_NOW_TT", "TXT_KEY_PLAY_NOW", Events.SerialEventStartGame.Call )
		PlayNowButton.Trim:SetHide( true )
		BuildEntryTT( "TXT_KEY_SETUP_GAME_TT", "TXT_KEY_SETUP_GAME", Controls.ModdingGameSetupScreen, PopupPriority.GameSetupScreen )
		BuildEntry( "TXT_KEY_AD_SETUP_ADVANCED_OPTIONS", Controls.AdvancedSetup, PopupPriority.AdvancedSetup )
		BuildEntryTT( "TXT_KEY_LOAD_GAME_TT", "TXT_KEY_MENU_LOAD_GAME_BUTTON", Controls.LoadGameScreen, PopupPriority.MPLoadGameScreen )
		BuildEntry( "TXT_KEY_SCENARIOS", Controls.ScenariosScreen, PopupPriority.GameSetupScreen ).Button:SetDisabled( not Modding.GetInstalledFiraxisScenarios()() )
		BuildEntryTT( "TXT_KEY_TUTORIAL_TT", "TXT_KEY_TUTORIAL", Controls.LoadTutorial, PopupPriority.LoadTutorial )
		BuildEntry( "TXT_KEY_MODDING_MENU_BACK", SelectMenu, 0 ).Button:SetOffsetY(45)

		-- Multi Player
		BuildMenuStack( "TXT_KEY_MULTIPLAYER", function() ReconnectButton.Button:SetDisabled( not Network.HasReconnectCache() ) end )
		BuildEntryTT( "TXT_KEY_MULTIPLAYER_HOTSEAT_GAME_TT", "{TXT_KEY_MULTIPLAYER_HOTSEAT_GAME:upper}", HotSeatSetup ).Trim:SetHide( true )
		local isConnected = Network.IsConnectedToSteam()
		BuildEntryTT( isConnected and "TXT_KEY_MULTIPLAYER_INTERNET_GAME_TT" or "TXT_KEY_STEAM_CONNECTED_NO", "{TXT_KEY_MULTIPLAYER_STANDARD_GAME:upper} {TXT_KEY_MULTIPLAYER_INTERNET_GAME:upper}", GotoLobby, MultiplayerLobbyMode.LOBBYMODE_STANDARD_INTERNET ).Button:SetDisabled( not isConnected )
		BuildEntryTT( "TXT_KEY_MULTIPLAYER_LAN_GAME_TT", "{TXT_KEY_MULTIPLAYER_STANDARD_GAME:upper} {TXT_KEY_MULTIPLAYER_LAN_GAME:upper}", GotoLobby, MultiplayerLobbyMode.LOBBYMODE_STANDARD_LAN )
		BuildEntryTT( isConnected and "TXT_KEY_MULTIPLAYER_PITBOSS_GAME_TT" or "TXT_KEY_STEAM_CONNECTED_NO", "{TXT_KEY_MULTIPLAYER_PITBOSS_GAME:upper} {TXT_KEY_MULTIPLAYER_INTERNET_GAME:upper}", GotoLobby, MultiplayerLobbyMode.LOBBYMODE_PITBOSS_INTERNET ).Button:SetDisabled( not isConnected )
		BuildEntryTT( "TXT_KEY_MULTIPLAYER_PITBOSS_GAME_TT", "{TXT_KEY_MULTIPLAYER_PITBOSS_GAME:upper} {TXT_KEY_MULTIPLAYER_LAN_GAME:upper}", GotoLobby, MultiplayerLobbyMode.LOBBYMODE_PITBOSS_LAN )
		ReconnectButton = BuildEntry( "{TXT_KEY_MULTIPLAYER_RECONNECT:upper}", Network.Reconnect )
		BuildEntry( "TXT_KEY_MODDING_MENU_BACK", SelectMenu, 0 ).Button:SetOffsetY(45)

		-- Other
		BuildMenuStack "TXT_KEY_OTHER"
		BuildEntryTT( "TXT_KEY_LATEST_NEWS_TT", "TXT_KEY_LATEST_NEWS", function() Steam.ActivateGameOverlayToWebPage("http://store.steampowered.com/news/?appids=8930") end ).Trim:SetHide( true )
		BuildEntryTT( "TXT_KEY_CIVILOPEDIA_TOOLTIP", "TXT_KEY_CIVILOPEDIA", Controls.Civilopedia, PopupPriority.Civilopedia )
		BuildEntryTT( "TXT_KEY_HALL_OF_FAME_TT", "TXT_KEY_HALL_OF_FAME", Controls.HallOfFame, PopupPriority.HallOfFame )
		BuildEntryTT( "TXT_KEY_OTHER_MENU_VIEW_REPLAYS_TT", "TXT_KEY_OTHER_MENU_VIEW_REPLAYS", Controls.LoadReplayMenu, PopupPriority.HallOfFame )
		BuildEntryTT( "TXT_KEY_CREDITS_TT", "TXT_KEY_CREDITS", Controls.Credits, PopupPriority.Credits )
		BuildEntryTT( "TXT_KEY_LEADERBOARD_TT", "TXT_KEY_LEADERBOARD", Controls.Leaderboard, PopupPriority.Leaderboard )
		BuildEntry( "TXT_KEY_MODDING_MENU_BACK", SelectMenu, 0 ).Button:SetOffsetY(45)

	end
	for i, stack in pairs( MenuContainers ) do
		stack:SetHide( n~=i )
	end
	local menuFunction = MenuFuntions[n]
	if menuFunction then
		menuFunction()
	end
	SelectedMenu = n
	Controls.MenuContainer:SetHide( false )
	Controls.FadeIn:SetToBeginning()
	Controls.FadeIn:Play()
	UIManager:SetUICursor( 0 )
end

-------------------------------------------------
-- Event Handlers
ContextPtr:SetShowHideHandler( function( isHide, isInit )
--	print( "SetShowHideHandler", "isHide", isHide, "isInit", isInit, "IsHotLoad", ContextPtr:IsHotLoad(), "GameStarted", PreGame.GameStarted() )
	if not isHide and not isInit then
		-- This is a catch all to ensure that mods are not activated at this point in the UI.
		-- Also, since certain maps and settings will only be available in either the modding or multiplayer
		-- screen, we want to ensure that "safe" settings are loaded that can be used for either SP, MP or Mods.
		-- Activating the DLC (there doesn't have to be any) will make sure no mods are active and all the user's
		-- purchased content is available
		if not ContextPtr:IsHotLoad() and not PreGame.GameStarted() then
			UIManager:SetUICursor( 1 )
			print( "Modding.ActivateDLC" )
			Modding.ActivateDLC()
			-- Send out an event to continue on, as the ActivateDLC may have swapped out the UI
			Events.SystemUpdateUI( SystemUpdateUITypeRestoreUI, "MainMenu", SelectedMenu or 0 )
		end
	end
end)

Events.SystemUpdateUI.Add( function( updateUItype, tag, x1, x2, tag2 )
	if updateUItype == SystemUpdateUITypeRestoreUI then
print( "Events.SystemUpdateUI SystemUpdateUIType.RestoreUI", tag, x1, x2, tag2 )
		UIManager:SetUICursor( 0 )
		if tag == "MainMenu" then
			-- Look for any cached invite
			UI:CheckForCommandLineInvitation()
			if Network.IsDedicatedServer() then
				ResetMultiplayerOptions()
				QueuePopupIfHidden( Controls.DedicatedServerScreen, PopupPriority.LobbyScreen )
			else
				SelectMenu( x1 )
			end
		elseif tag == "JoiningRoom" then
			QueuePopupIfHidden( Controls.JoinScreen, PopupPriority.JoiningScreen )
		elseif tag == "StagingRoom" then
			if not UIManager:GetVisibleNamedContext( "StagingRoom" ) then
				UIManager:QueuePopup( Controls.StagingRoomScreen, PopupPriority.StagingScreen )
			end
		elseif tag == "ModsBrowserReset" then
			return QueuePopupIfHidden( Controls.ModsBrowser, PopupPriority.ModsBrowserScreen )
		elseif tag == "LoadGameMenu" then
			QueuePopupIfHidden( Controls.LoadGameScreen, PopupPriority.MPLoadGameScreen )
		elseif tag == "Civilopedia" then
			QueuePopupIfHidden( Controls.Civilopedia, PopupPriority.Civilopedia )
		elseif tag == "GameSetup" then
			QueuePopupIfHidden( Controls.ModdingGameSetupScreen, PopupPriority.GameSetupScreen )
		elseif tag == "ModsMenu" then
			QueuePopupIfHidden( Modding.GetActivatedModEntryPoints"Custom"() and Controls.ModsCustom or Controls.ModdingGameSetupScreen, PopupPriority.ModsMenuScreen )
		elseif tag == "MultiplayerSelect" then
			SelectMenu( 2 )
		elseif tag == "HotSeatSetup" then
			HotSeatSetup()
		elseif tag == "AdvancedSetup" then
			return QueuePopupIfHidden( Controls.AdvancedSetup, PopupPriority.AdvancedSetup )
		elseif tag == "ScenariosScreen" then
			return QueuePopupIfHidden( Controls.ScenariosScreen, PopupPriority.GameSetupScreen )
		elseif tag == "LoadScenario" then
			-- Do not save these settings out for the "Play Now" option.
			PreGame.SetPersistSettings( false )
			local newContext = ContextPtr:LoadNewContext( string.sub(tag2, 1, #tag2 - #Path.GetExtension( tag2 )) )
			if newContext then
				newContext:SetHide( true )
				QueuePopupIfHidden( newContext, PopupPriority.CustomMod )
			end
		elseif tag == "LoadReplay" then
			QueuePopupIfHidden( Controls.LoadReplayMenu, PopupPriority.HallOfFame )
			QueuePopupIfHidden( Controls.ReplayViewer, PopupPriority.eUtmost )
			LuaEvents.ReplayViewer_LoadReplay( tag2 )
		end
	end
end)

ContextPtr:SetInputHandler( function( uiMsg, wParam )
	if uiMsg == KeyDown and wParam == VK_ESCAPE then
		UIManager:SetUICursor( 1 )
		Events.ExitToMainMenu()
		return true
	end
end)
