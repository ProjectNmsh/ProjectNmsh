------------------------------

fx_version 'adamant'
games { 'gta5' }

author 'TrevorBarns w/ credits see GitHub'
description 'A siren / emergency lights controller for FiveM.'

prerelease 'false'
version '3.2.8'	
compatible '3.2.2'

------------------------------

experimental 'true'		-- Mute unstable version warning in server console.
debug_mode 'false' 		-- More verbose printing on client console.

------------------------------

ui_page('/UI/html/index.html')
	
dependencies {
    'RageUI'
}

files({
    'UI/html/index.html',
    'UI/html/lvc.js',
    'UI/html/style.css',
	'UI/sounds/*.ogg',
	'UI/sounds/**/*.ogg',
	'UI/textures/**/*.png',
	'UI/textures/**/*.gif',
	'PLUGINS/**/*.json'
})


shared_script {
	'SETTINGS.lua',
}

client_scripts {
	---------------RAGE-UI---------------
    '@RageUI/RMenu.lua',
    '@RageUI/menu/RageUI.lua',
    '@RageUI/menu/Menu.lua',
    '@RageUI/menu/MenuController.lua',
    '@RageUI/components/Audio.lua',
    '@RageUI/components/Enum.lua',
    '@RageUI/components/Keys.lua',
    '@RageUI/components/Rectangle.lua',
    '@RageUI/components/Sprite.lua',
    '@RageUI/components/Text.lua',
    '@RageUI/components/Visual.lua',
    '@RageUI/menu/elements/ItemsBadge.lua',
    '@RageUI/menu/elements/ItemsColour.lua',
    '@RageUI/menu/elements/PanelColour.lua',
    '@RageUI/menu/items/UIButton.lua',
    '@RageUI/menu/items/UICheckBox.lua',
    '@RageUI/menu/items/UIList.lua',
    '@RageUI/menu/items/UISeparator.lua',
    '@RageUI/menu/items/UISlider.lua',
    '@RageUI/menu/items/UISliderHeritage.lua',
    '@RageUI/menu/items/UISliderProgress.lua',
    '@RageUI/menu/panels/UIColourPanel.lua',
    '@RageUI/menu/panels/UIGridPanel.lua',
    '@RageUI/menu/panels/UIPercentagePanel.lua',
    '@RageUI/menu/panels/UIStatisticsPanel.lua',
    '@RageUI/menu/windows/UIHeritage.lua',
	-------------------------------------
	'SIRENS.lua',
	'/UTIL/cl_*.lua',
	'/UI/cl_*.lua',
	'/PLUGINS/cl_plugins.lua',
	'/PLUGINS/**/SETTINGS.lua',
	'/PLUGINS/**/cl_*.lua',
}

server_script {
	'/UTIL/sv_lvc.lua',
	'/PLUGINS/**/sv_*.lua'
}
------------------------------