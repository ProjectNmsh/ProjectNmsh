fx_version 'cerulean'
games { 'rdr3', 'gta5' }
author 'KnownScripts'
description 'Driftschool by KnownScripts'

dependencies {
    "PolyZone"
}
server_script 'server.lua'

ui_page 'html/html/index.html'

files {
    'html/html/index.html',
    'html/html/script.js',
}

client_scripts {
    "@PolyZone/client.lua",
    'client.lua'
}


lua54 'yes'
