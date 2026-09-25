fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Hannover RP"
description "Garage / Fuhrpark app for LB Phone (JG Advanced Garages)"
version "1.1.0"

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
    "server.lua",
}

files {
    "ui/**",
}
