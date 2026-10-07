fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Hannover RP"
description "Garage / Fuhrpark app for LB Phone (JG Advanced Garages, ESX & Qbox)"
version "1.2.0"

dependencies {
    "oxmysql",
    "ox_lib",
    "lb-phone",
    "jg-advancedgarages",
}

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua",
}

client_scripts {
    "client.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "bridge/server.lua",
    "server.lua",
}

files {
    "ui/**",
}
