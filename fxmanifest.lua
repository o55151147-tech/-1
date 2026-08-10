fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Custom'
description 'Crafting: search vehicles for scrap, craft tools via HTML UI'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/arth-logo.png'
}

dependencies {
    'qb-core',
    'qb-inventory',
    'qb-target'
}
