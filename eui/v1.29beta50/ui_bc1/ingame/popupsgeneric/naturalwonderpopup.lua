-- Natural Wonder Popup
-- Modified by bc1 from 1.0.3.276 code using Notepad++

if PopupLayouts then
	local GameInfo = GameInfoCache or GameInfo
	PopupLayouts[ButtonPopupTypes.BUTTONPOPUP_NATURAL_WONDER_REWARD or -1] = function( popupInfo )
		SetTopImage( "NaturalWonderPopupTop300.dds", -22 )
		local plot = Map.GetPlot( popupInfo.Data1, popupInfo.Data2 )
		local info = plot and GameInfo.Features[ plot:GetFeatureType() ]
		if info then
			SetTopIcon( 128, info.PortraitIndex, info.IconAtlas, 20 )
			SetPopupTitle( L( info.Description ) )

			local yieldString = L( "TXT_KEY_POP_NATURAL_WONDER_FOUND_TT", info.Description )
			local numYields = 0
			for row in GameInfo.Feature_YieldChanges{ FeatureType = info.Type } do
				if row.Yield > 0 then
					numYields = numYields + 1
					yieldString = yieldString .. " " .. tostring(row.Yield) .. " "
					yieldString = yieldString .. GameInfo.Yields[row.YieldType].IconString .. " "
				end
			end	
			if (info.Culture or 0) > 0 then	
				yieldString = yieldString .. " " .. info.Culture .. " [ICON_CULTURE]"
			elseif numYields == 0 then
				yieldString = yieldString .. " " .. L"TXT_KEY_PEDIA_NO_YIELD"
			end
			if (info.InBorderHappiness or 0 ) > 0 then
				yieldString = yieldString .. L("TXT_KEY_POP_NATURAL_WONDER_FOUND_HAPPY", info.InBorderHappiness)
			end
			if info.AdjacentUnitFreePromotion then
				local thisPromotion = GameInfo.UnitPromotions[info.AdjacentUnitFreePromotion]
				yieldString = yieldString .. L( "TXT_KEY_POP_NATURAL_WONDER_FOUND_PROMOTE", thisPromotion.Description )
			end
			local iFinderGold = popupInfo.Data3
			if iFinderGold > 0 then
				if popupInfo.Option1 then -- first finder
					yieldString = yieldString .. L("TXT_KEY_POP_NATURAL_WONDER_FIRST_FOUND_GOLD", iFinderGold)
				else
					yieldString = yieldString .. L("TXT_KEY_POP_NATURAL_WONDER_SUBSEQUENT_FOUND_GOLD", iFinderGold)
				end
			end
			SetPopupText( yieldString )
		end
		AddButton( L"TXT_KEY_OK_BUTTON" ) --TXT_KEY_CLOSE
	end
end