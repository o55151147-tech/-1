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

-- qb-inventory مو مدرج هنا لأن اسمه يختلف من سيرفر لسيرفر (مثلاً Arth-inventory)
-- والكود يتعامل مع الأصناف عبر qb-core نفسه (Player.Functions) بغض النظر عن اسم مورد الإنفنتوري
dependencies {
    'qb-core',
    'qb-target'
}
