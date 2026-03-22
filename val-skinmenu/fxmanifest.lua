fx_version 'adamant'

game 'gta5'
version '1.0'
lua54 'yes'

client_script {
  'config/config-export.lua',
  'config/config.lua',
  'config/config_costume.lua',
  'client/client.lua',
}

server_script {
	'config/config-export.lua',
	'config/config.lua',
	'server/server.lua'
}


ui_page 'html/index.html'
files {
	'html/index.html',
	'html/css/*',
	'html/js/*',
	'html/img/*',
	'html/sound/*',
	'html/font/*.ttf'
	
}

export 'ForceSkinMenu'
