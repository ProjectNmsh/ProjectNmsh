--[[FX INFO]]
fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

--[[RESOURCE INFO]]
name 'uniq-deathscreen'
author 'uniq team'
description 'Death Screen'
version '1.0.1'
 
--[[FX DEPENDENCIES]]
dependencies {
	'/server:5848',
    '/onesync',
}

--[[FX FILES]]
ui_page 'web/index.html'

files {
    'web/index.html',
    'web/**/*',
}

shared_script {
    'shared/*.lua',
}

client_scripts {
    'client/bridge.lua',
    'client/*.lua',
}

server_script {
    'server/bridge.lua',
    'server/*.lua'
}
