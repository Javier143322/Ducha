-- ================================================================= --
--                             CONFIG.LUA                              --
--           CONFIGURACIÓN GLOBAL DEL SISTEMA DE BAÑO Y NECESIDADES  --
-- ================================================================= --

Config = {}

-- [[ CONFIGURACIÓN GENERAL ]] ----------------------------------------

-- Radio de detección (en metros) para interactuar con los objetos.
Config.DrawDistance = 2.0

-- Tecla para interactuar (por defecto, 'E'). Se usa para el texto de ayuda.
Config.InteractKey = 'E' -- Puedes cambiarlo si usas otra librería para la UI.

-- Cooldown general (en segundos) para evitar spam de acciones.
-- Se aplicará por acción (ej. no puedes ducharte de nuevo hasta que pase este tiempo).
Config.ActionCooldown = 180 -- 3 minutos

-- [[ EFECTOS DE LAS ACCIONES ]] --------------------------------------
-- Valores que se aplicarán al personaje después de la acción.

Config.Effects = {
    -- Efectos al usar el inodoro/orinal ('hacer necesidades')
    toilet = {
        hunger_reduction = 10,  -- Reducción en el nivel de hambre (0-100)
        thirst_reduction = 5,   -- Reducción en el nivel de sed (0-100)
        cleanliness_gain = 5    -- Aumento en el nivel de limpieza (0-100, para futura implementación)
    },
    -- Efectos al usar la ducha ('bañarse')
    shower = {
        cleanliness_gain = 40,  -- Aumento significativo de limpieza
        hunger_reduction = 0,   -- No afecta directamente al hambre
        thirst_reduction = 0    -- No afecta directamente a la sed
    },
    -- Efectos al usar el lavabo ('lavarse las manos/cara')
    sink = {
        cleanliness_gain = 10,  -- Aumento leve de limpieza
        hunger_reduction = 0,
        thirst_reduction = 0
    }
}

-- [[ ANIMACIONES Y TIEMPOS ]] -----------------------------------------

Config.Actions = {
    -- Inodoro (Sentarse)
    toilet = {
        scenario = 'PROP_HUMAN_SEAT_TOILET', -- Escenario de asiento
        animDict = 'missfbi3_interior',      -- Diccionario de animación (alternativa)
        animName = 'sit_toilet_male',        -- Nombre de animación (alternativa)
        duration = 8000,                     -- Duración de la animación en milisegundos (8s)
        text = 'Usar el Inodoro (Necesidades Mayores)'
    },
    -- Orinal (Solo hombres)
    urinal = {
        animDict = 'missbigscore2ig_10',
        animName = 'wash_hands_right',       -- Se puede usar esta para simular 'orinar' (de pie)
        duration = 5000,                     -- Duración de la animación en milisegundos (5s)
        text = 'Usar el Orinal (Necesidades Menores)'
    },
    -- Ducha
    shower = {
        animDict = 'switch@franklin@ig_6',
        animName = 'switch_to_shower',
        duration = 15000,                    -- Larga duración (15s) para simular un baño completo
        text = 'Ducharse y Aumentar Limpieza'
    },
    -- Lavabo
    sink = {
        animDict = 'amb@world_human_leaning@male@wall@hand_up@idle_a',
        animName = 'idle_a',                 -- Animación simple de 'estar en el lavabo'
        duration = 6000,                     -- Duración de la animación en milisegundos (6s)
        text = 'Lavarse las Manos/Cara'
    }
}


-- [[ UBICACIONES INTERACTIVAS ]] ---------------------------------------
-- Lista de todas las zonas interactivas en el mapa.
-- NOTA: Las coordenadas son ejemplos. DEBEN ser ajustadas a tu mapa.

Config.Locations = {
    -- 1. Baño Público de Vespucci Beach
    {
        coords = vector3(-1261.21, -1438.30, 4.40), -- Coordenada para el Inodoro 1
        heading = 24.0,                            -- Orientación del jugador al empezar
        type = 'toilet'                            -- Tipo de acción (usa la clave de Config.Actions)
    },
    {
        coords = vector3(-1262.50, -1438.90, 4.40), -- Coordenada para el Orinal 1
        heading = 24.0,
        type = 'urinal'
    },
    -- 2. Apartamento de Michael (Ejemplo de Ducha)
    {
        coords = vector3(-1147.20, -685.20, 35.70), -- Coordenada para la Ducha 1
        heading = 330.0,
        type = 'shower'
    },
    -- 3. Gasolinera 24/7 (Ejemplo de Lavabo)
    {
        coords = vector3(264.80, -1004.80, -100.00), -- Coordenada para el Lavabo 1
        heading = 30.0,
        type = 'sink'
    },
    -- Puedes añadir más ubicaciones aquí...
    -- {
    --     coords = vector3(X, Y, Z),
    --     heading = H,
    --     type = 'toilet' / 'urinal' / 'shower' / 'sink'
    -- }
}
