--==========================================================
-- EUI context hosts interface settings and tooltip server
-- Written by bc1 using Notepad++
--==========================================================

local collectgarbage = collectgarbage
local pairs = pairs
local print = print
local tostring = tostring
local insert = table.insert

local ContentManager = ContentManager
local ContentTypeGAMEPLAY = ContentType.GAMEPLAY
local Locale = Locale
local Modding = Modding

-- Print game DLC and MOD configuration for debug
local t= { "DLC/MOD configuration" }
for _, v in pairs( ContentManager.GetAllPackageIDs() ) do
	insert( t, (ContentManager.IsActive(v, ContentTypeGAMEPLAY) and "Active DLC:  \t" or "Disabled DLC:\t")..tostring(v).."\t"..Locale.Lookup(ContentManager.GetPackageDescription(v)) )
end
for _, v in pairs( Modding.GetActivatedMods() ) do
	insert( t, "Active MOD:  \t".. tostring(v.ID) .. "\t" .. tostring( Modding.GetModProperty(v.ID, v.Version, "Name") ) .. " v"..tostring(v.Version) )
	if v.ID == "34fb6c19-10dd-4b65-b143-fd00b2c0826f" then
		IsNewWorldDeluxeScenario = true
	end
end
print( table.concat( t,"\n\t" ) )

if Game then
	include "GameInfoActualCache" -- warning! booleans are true, not 1, and use iterator ONLY with table field conditions, NOT string SQL query
	MapModData.EUI_GameInfoCache = GameInfoCache
	print "Loaded EUI game info cache"
	include "UserInterfaceSettingCache"
	MapModData.EUI_UserInterfaceSettings = UserInterfaceSettings
	print "Loaded EUI settings cache"
	include "EUI_tooltip_server"
end
