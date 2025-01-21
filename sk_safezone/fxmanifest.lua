fx_version 'cerulean'
games { 'gta5' }
author 'Snooppikoira'
lua54 'yes'

shared_scripts {'config.lua', '@ox_lib/init.lua', '@es_extended/imports.lua'}
client_scripts {'client/*.lua'}
server_scripts {'server/*.lua'}

files {'web/index.html'}
ui_page 'web/index.html'
