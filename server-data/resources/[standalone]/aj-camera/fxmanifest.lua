fx_version 'bodacious'
game 'gta5'

client_script {
    '/client/client.lua',
    'config.lua',
    'locale.lua',
    '/locales/*.lua'
}

server_script {
    '/server/server.lua',
    'config.lua'
}

ui_page 'html/index.html'

files {
	'html/index.html',
	'html/reset.css',
	'html/style.css',
	'html/script.js'
}