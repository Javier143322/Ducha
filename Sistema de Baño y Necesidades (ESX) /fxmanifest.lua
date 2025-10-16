-- ================================================================= --
--                      FXMANIFEST.LUA MEJORADO                    --
-- ================================================================= --

fx_version 'cerulean'
game 'gta5'

-- Información del recurso
name 'esx_bathroom_system'
description 'Sistema avanzado de higiene y necesidades fisiológicas para ESX'
author 'Tu Nombre'
version '2.0.0'

-- Dependencias
dependencies {
    'es_extended'
}

-- Archivos compartidos
shared_scripts {
    'config.lua'
}

-- Archivos del cliente
client_scripts {
    '@es_extended/client/common.lua',
    'client.lua'
}

-- Archivos del servidor  
server_scripts {
    '@es_extended/server/common.lua',
    'server.lua'
}

-- Compatibilidad
lua54 'yes'

-- Metadatos
description [[
Sistema avanzado de higiene y necesidades con:

🚽 SISTEMA DE NECESIDADES FISIOLÓGICAS
• Vejiga e intestinos realistas
• Efectos de estrés por necesidades urgentes
• Alertas y consecuencias por no usar baño

🛁 SISTEMA DE HIGIENE AVANZADO
• Decaída natural de limpieza
• Efectos sociales por mala higiene
• Consecuencias en la salud

💊 SISTEMA DE ENFERMEDADES
• Enfermedades realistas por mala higiene
• Prevención mediante buena higiene
• Efectos temporales en el jugador

🎯 CARACTERÍSTICAS TÉCNICAS
• Optimizado para rendimiento
• Integración completa con ESX
• Sistema de metadata persistente
• Efectos visuales y de sonido
]]

-- UI personalizada (futuras actualizaciones)
-- ui_page 'html/ui.html'
-- files { 'html/**/*' }