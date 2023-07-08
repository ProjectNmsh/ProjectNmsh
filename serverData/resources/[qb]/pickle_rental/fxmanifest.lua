fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name         'pickle_rental'
version      '1.1.0'
description  'A fully immersive rental system for vehicles.'
author       'Pickle Mods'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'core/shared.lua',
    "locales/locale.lua",
    "locales/translations/*.lua",
    'modules/**/shared.lua',
}

server_scripts {
    'bridge/**/server.lua',
    'modules/**/server.lua',
}

client_scripts {
    'core/client.lua',
    'bridge/**/client.lua',
    'modules/**/client.lua',
}
