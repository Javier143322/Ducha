-- ================================================================= --
--                             CONFIG.LUA                              --
--           CONFIGURACIÓN GLOBAL DEL SISTEMA DE BAÑO Y NECESIDADES  --
-- ================================================================= --

Config = {}

-- [[ CONFIGURACIÓN GENERAL ]] ----------------------------------------

-- Radio de detección (en metros) para interactuar con los objetos.
Config.DrawDistance = 2.0

-- Tecla para interactuar (por defecto, 'E'). Se usa para el texto de ayuda.
Config.InteractKey = 'E' 

-- Cooldown general (en segundos) para evitar spam de acciones.
-- Se aplicará por acción (ej. no puedes ducharte de nuevo hasta que pase este tiempo).
Config.ActionCooldown = 180 -- 3 minutos

-- Nivel de Limpieza inicial del jugador (0 = Sucio, 100 = Limpio)
Config.InitialCleanliness = 80

-- [[ EFECTOS DE LAS ACCIONES ]] --------------------------------------
-- Valores que se aplicarán al personaje después de la acción.

Config.Effects = {
    -- Efectos al usar el inodoro/orinal ('hacer necesidades')
    toilet = {
        hunger_reduction = 10,  -- Reducción en el nivel de hambre (0-100)
        thirst_reduction = 5,   -- Reducción en el nivel de sed (0-100)
        cleanliness_gain = 5    -- Aumento leve en el nivel de limpieza 
    },
    -- Efectos al usar la ducha ('bañarse')
    shower = {
        cleanliness_gain = 40,  -- Aumento significativo de limpieza
        hunger_reduction = 0,   
        thirst_reduction = 0    
    },
    -- Efectos al usar el lavabo ('lavarse las manos/cara')
    sink = {
        cleanliness_gain = 10,  -- Aumento leve de limpieza
        hunger_reduction = 0,
        thirst_reduction = 0
    }
}

-- [[ ANIMACIONES, TIEMPOS Y SONIDOS ]] -----------------------------------------

Config.Actions = {
    -- Inodoro (Sentarse)
    toilet = {
        scenario = 'PROP_HUMAN_SEAT_TOILET', 
        duration = 8000, 
        text = 'Usar el Inodoro (Necesidades Mayores)',
        sound = {
            name = 'FLUSH_WATER_SOUND',
            set = 'MP_AIRCRAFT_MISC_SOUNDS'
        }
    },
    -- Orinal (Solo hombres)
    urinal = {
        animDict = 'missbigscore2ig_10',
        animName = 'wash_hands_right',
        duration = 5000,
        text = 'Usar el Orinal (Necesidades Menores)',
        sound = {
            name = 'FLUSH_WATER_SOUND',
            set = 'MP_AIRCRAFT_MISC_SOUNDS'
        }
    },
    -- Ducha
    shower = {
        animDict = 'switch@franklin@ig_6',
        animName = 'switch_to_shower',
        duration = 15000, 
        text = 'Ducharse y Aumentar Limpieza',
        sound = {
            name = 'FM_CUT_MICHAEL_SHOWER_START',
            set = 'MP_FM_CUTSCENES'
        }
    },
    -- Lavabo
    sink = {
        animDict = 'amb@world_human_leaning@male@wall@hand_up@idle_a',
        animName = 'idle_a',
        duration = 6000,
        text = 'Lavarse las Manos/Cara',
        sound = {
            name = 'WATER_TAP_ON',
            set = 'PI_PLANS_HEIST_PLANS_SOUNDSET'
        }
    }
}


-- [[ UBICACIONES INTERACTIVAS ]] ---------------------------------------
-- Lista de todas las zonas interactivas en el mapa.

Config.Locations = {
    -- 1. Baño Público de Vespucci Beach
    {
        coords = vector3(-1261.21, -1438.30, 4.40), 
        heading = 24.0,                            
        type = 'toilet'                            
    },
    {
        coords = vector3(-1262.50, -1438.90, 4.40), 
        heading = 24.0,
        type = 'urinal'
    },
    -- 2. Apartamento de Michael (Ejemplo de Ducha)
    {
        coords = vector3(-1147.20, -685.20, 35.70), 
        heading = 330.0,
        type = 'shower'
    },
    -- 3. Gasolinera 24/7 (Ejemplo de Lavabo)
    {
        coords = vector3(264.80, -1004.80, -100.00), 
        heading = 30.0,
        type = 'sink'
    },
    -- ... (más ubicaciones)
}
