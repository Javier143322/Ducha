fx_version 'cerulean'
game 'gta5'

-- Información básica del recurso
name 'esx_bathroom_system'
description 'Sistema interactivo de baño y necesidades para ESX'
author 'Tu Nombre/Comunidad'
version '1.0.0'

-- Dependencias: Aseguramos que ESX esté cargado.
-- (Puede variar si usas una base diferente a 'esx_core')
dependencies {
    'es_extended'
}

-- Archivos de configuración y lógica

-- Archivo de Configuración (Debe cargarse primero)
client_scripts {
    'config.lua'
}

-- Archivos de Lado del Cliente (Lógica de detección, UI, animaciones)
client_scripts {
    '@es_extended/client/lua.lua', -- Incluir ESX client (para funciones como el menú o notificaciones)
    'client.lua'
}

-- Archivos de Lado del Servidor (Lógica de efectos, limpieza, guardado)
server_scripts {
    '@es_extended/server/lua.lua', -- Incluir ESX server
    'server.lua'
}

-- Archivos NUI (Opcional, si se usa una NUI personalizada en el futuro)
-- ui_page 'html/ui.html'

-- files {
--     'html/ui.html',
--     'html/style.css',
--     'html/script.js',
-- }


