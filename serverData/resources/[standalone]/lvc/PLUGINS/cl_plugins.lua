--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_plugins.lua
PURPOSE: Builds RageUI Plugin Menu based on plugins 
settings. Handles Plugin -> LVC event communication
---------------------------------------------------
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
---------------------------------------------------
]]
-- RAGE UI
--	Draws specific button with callback to plugins menu if the plugin is found and enabled. (controlled in plugins settings file)
Citizen.CreateThread(function()
    while plugins_installed do
	    RageUI.IsVisible(RMenu:Get('lvc', 'plugins'), function()
			-----------------------------------------------------------------------------------------------------------------
			if smart_siren_masterswitch then
				RageUI.Button('Smart Siren Settings', 'Open smart siren settings menu. (smart_sirens)', {RightLabel = '→→→'}, true, {
				  onSelected = function()
				  end,
				}, RMenu:Get('lvc', 'smartsiren'))	
			end
			-----------------------------------------------------------------------------------------------------------------
			if tkd_masterswitch then
				RageUI.Button('Takedown Settings', 'Open takedown lights menu. (takedowns)', {RightLabel = '→→→'}, true, {
				  onSelected = function()
				  end,
				}, RMenu:Get('lvc', 'tkdsettings'))	
			end
			-----------------------------------------------------------------------------------------------------------------
			if ei_masterswitch then
				RageUI.Button('Extra Integration Settings', 'Open extra integration menu. (extra_integration)', {RightLabel = '→→→'}, true, {
				  onSelected = function()
				  end,
				}, RMenu:Get('lvc', 'extrasettings'))	
			end		
			-----------------------------------------------------------------------------------------------------------------
			if ta_masterswitch then
				RageUI.Button('Traffic Advisor Settings', 'Open traffic advisor menu. (traffic_advisor)', {RightLabel = '→→→'}, true, {
				  onSelected = function()
				  end,
				}, RMenu:Get('lvc', 'tasettings'))	
			end		
			-----------------------------------------------------------------------------------------------------------------
			if trailer_masterswitch then
				RageUI.Button('Trailer Support Settings', 'Open trailer support settings menu. (trailer_support)', {RightLabel = '→→→'}, true, {
				  onSelected = function()
				  end,
				}, RMenu:Get('lvc', 'trailersettings'))	
			end		
			-----------------------------------------------------------------------------------------------------------------
			if ec_masterswitch then
				RageUI.Button('Extra Controls Settings', 'Open extra controls settings menu. (extra_controls)', {RightLabel = '→→→'}, true, {
				  onSelected = function()
				  end,
				}, RMenu:Get('lvc', 'extracontrols'))	
			end		
			-----------------------------------------------------------------------------------------------------------------
		end)
        Citizen.Wait(0)
	end
end)

-- FUNCTIONS
--	IsPluginMenuOpen is called inside IsMenuOpen (LVC/UI/cl_ragemenu.lua) to separate them, this is useful for plugin updates separate of main LVC updates.
function IsPluginMenuOpen()
	return 	RageUI.Visible(RMenu:Get('lvc', 'smartsiren')) or 
			RageUI.Visible(RMenu:Get('lvc', 'tkdsettings')) or 
			RageUI.Visible(RMenu:Get('lvc', 'extrasettings')) or
			RageUI.Visible(RMenu:Get('lvc', 'tasettings')) or
			RageUI.Visible(RMenu:Get('lvc', 'trailersettings')) or
			RageUI.Visible(RMenu:Get('lvc', 'trailerextras')) or
			RageUI.Visible(RMenu:Get('lvc', 'trailerdoors')) or
			RageUI.Visible(RMenu:Get('lvc', 'extracontrols')) 
end