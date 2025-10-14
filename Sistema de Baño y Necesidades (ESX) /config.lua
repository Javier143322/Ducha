-- ================================================================= --
--                             CONFIG.LUA                              --
--           CONFIGURACIÓN GLOBAL DEL SISTEMA DE BAÑO Y NECESIDADES  --
-- ================================================================= --

Config = {}

-- [[ CONFIGURACIÓN GENERAL ]] ----------------------------------------

-- Radio de detección (en metros) para interactuar con los objetos.
Config.DrawDistance = 2.0

-- Tecla para interactuar (por defecto, 'E'). Ya no se usa para el texto de ayuda directo.
Config.InteractKey = 38 -- Código de tecla 'E'

-- Cooldown general (en segundos) para evitar spam de acciones.
Config.ActionCooldown = 180 -- 3 minutos

-- Nivel de Limpieza inicial del jugador (0 = Sucio, 100 = Limpio)
Config.InitialCleanliness = 80 

-- [[ EFECTOS DE LAS ACCIONES ]] --------------------------------------

Config.Effects = {
    -- Efectos al usar el inodoro/orinal ('hacer necesidades')
    toilet = {
        hunger_reduction = 10,
        thirst_reduction = 5,
        cleanliness_gain = 5
    },
    -- Efectos al usar la ducha ('bañarse')
    shower = {
        cleanliness_gain = 40,
        hunger_reduction = 0,
        thirst_reduction = 0
    },
    -- Efectos al usar el lavabo ('lavarse las manos/cara')
    sink = {
        cleanliness_gain = 10,
        hunger_reduction = 0,
        thirst_reduction = 0
    }
}

-- [[ ANIMACIONES, TIEMPOS, SONIDOS Y PARTÍCULAS (PTFX) ]] -----------------------------------------

Config.Actions = {
    -- Inodoro (Sentarse)
    toilet = {
        scenario = 'PROP_HUMAN_SEAT_TOILET', 
        duration = 8000, 
        text = 'Usar el Inodoro (Necesidades Mayores)',
        sound = {
            startName = 'FLUSH_WATER_SOUND',
            startSet = 'MP_AIRCRAFT_MISC_SOUNDS'
        }
    },
    -- Orinal (Solo hombres)
    urinal = {
        animDict = 'missbigscore2ig_10',
        animName = 'wash_hands_right',
        duration = 5000,
        text = 'Usar el Orinal (Necesidades Menores)',
        sound = {
            startName = 'FLUSH_WATER_SOUND',
            startSet = 'MP_AIRCRAFT_MISC_SOUNDS'
        }
    },
    -- Ducha
    shower = {
        animDict = 'switch@franklin@ig_6',
        animName = 'switch_to_shower',
        duration = 15000, 
        text = 'Ducharse y Aumentar Limpieza',
        sound = {
            startName = 'FM_CUT_MICHAEL_SHOWER_START',
            startSet = 'MP_FM_CUTSCENES',
            stopName = 'WATER_SHUT_OFF',
            stopSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET'
        },
        ptfx = {
            dict = 'core',
            name = 'ent_amb_shower_steam',
            offset = vector3(0.0, 0.0, 1.0) -- Ajustar si es necesario
        }
    },
    -- Lavabo
    sink = {
        animDict = 'amb@prop_human_toilet@male@four@base', -- Mejor animación para lavarse las manos
        animName = '4_wash_hands',
        duration = 6000,
        text = 'Lavarse las Manos/Cara',
        sound = {
            startName = 'WATER_TAP_ON',
            startSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET',
            stopName = 'WATER_SHUT_OFF',
            stopSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET'
        },
        ptfx = {
            dict = 'core',
            name = 'ent_amb_sink_tap_water_drip',
            offset = vector3(0.0, 0.0, 0.0)
        }
    }
}


-- [[ UBICACIONES INTERACTIVAS ]] ---------------------------------------
-- Lista de todas las zonas interactivas en el mapa.
-- El objectModel es CRÍTICO para que el DrawText 3D funcione correctamente.
Config.Locations = {
    -- 1. Inodoro Público (Ejemplo de Objeto)
    {
        coords = vector3(-1261.21, -1438.30, 4.40), 
        heading = 24.0,                            
        type = 'toilet',
        objectModel = GetHashKey('prop_toilet_01') -- Modelo de inodoro común (DEBE VERIFICARSE EN SU MAPA)
    },
    -- 2. Orinal Público
    {
        coords = vector3(-1262.50, -1438.90, 4.40), 
        heading = 24.0,
        type = 'urinal',
        objectModel = GetHashKey('prop_urinal_01') -- Modelo de orinal común
    },
    -- 3. Ducha (Ejemplo de objeto "ducha" en un apartamento)
    {
        coords = vector3(-1147.20, -685.20, 35.70), 
        heading = 330.0,
        type = 'shower',
        objectModel = GetHashKey('prop_shower_01') -- O un modelo de bañera cercano
    },
    -- 4. Lavabo (Ejemplo de lavabo de gasolinera)
    {
        coords = vector3(264.80, -1004.80, -100.00), 
        heading = 30.0,
        type = 'sink',
        objectModel = GetHashKey('prop_sink_01') -- Modelo de lavabo
    },
}
