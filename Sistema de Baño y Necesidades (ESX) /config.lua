-- ================================================================= --
--                          CONFIG.LUA MEJORADO                     --
--           SISTEMA AVANZADO DE HIGIENE Y NECESIDADES             --
-- ================================================================= --

Config = {}

-- [[ CONFIGURACIÓN GENERAL MEJORADA ]] --------------------------------
Config.Debug = false
Config.EnableAdvancedFeatures = true
Config.DrawDistance = 2.0
Config.InteractKey = 38 -- Tecla E

-- [[ SISTEMA DE NECESIDADES FISIOLÓGICAS ]] --------------------------
Config.NeedsSystem = {
    enabled = true,
    updateInterval = 30000, -- 30 segundos
    bladderIncrease = 2,    -- Aumento de vejiga por intervalo
    bowelIncrease = 1,      -- Aumento de intestinos por intervalo
    
    -- Efectos por necesidades no satisfechas
    effects = {
        bladder = {
            [80] = { stress = 10, message = "💦 Necesitas encontrar un baño pronto" },
            [95] = { stress = 25, message = "🚨 ¡URGENTE! Necesitas un baño YA" }
        },
        bowel = {
            [75] = { stress = 15, message = "💩 Sientes presión en el vientre" },
            [90] = { stress = 30, message = "🚨 ¡URGENTE! Necesitas un inodoro" }
        }
    }
}

-- [[ SISTEMA DE HIGIENE MEJORADO ]] ----------------------------------
Config.HygieneSystem = {
    initialCleanliness = 80,
    maxCleanliness = 100,
    minCleanliness = 0,
    
    -- Pérdida natural de limpieza
    naturalDecay = {
        enabled = true,
        rate = 0.5, -- Por minuto
        interval = 60000 -- 1 minuto
    },
    
    -- Efectos por baja higiene
    lowHygieneEffects = {
        [40] = { 
            message = "🤢 Te estás poniendo sucio...",
            socialPenalty = 0.1 -- 10% menos interacciones sociales
        },
        [20] = { 
            message = "🤮 ¡Hueles mal! La gente se aleja de ti",
            socialPenalty = 0.3, -- 30% menos interacciones
            healthEffect = -5 -- Pequeña reducción de salud máxima
        },
        [10] = { 
            message = "💀 ¡HIGIENE CRÍTICA! Riesgo de enfermedades",
            socialPenalty = 0.5, -- 50% menos interacciones
            healthEffect = -10,
            diseaseChance = 0.1 -- 10% de chance de enfermedad
        }
    }
}

-- [[ EFECTOS DE ACCIONES MEJORADOS ]] --------------------------------
Config.Effects = {
    toilet = {
        hunger_reduction = 10,
        thirst_reduction = 5,
        cleanliness_gain = 5,
        bladder_relief = 100, -- Alivio completo de vejiga
        bowel_relief = 100,   -- Alivio completo de intestinos
        stress_relief = 20
    },
    urinal = {
        hunger_reduction = 5,
        thirst_reduction = 3,
        cleanliness_gain = 2,
        bladder_relief = 100,
        stress_relief = 15
    },
    shower = {
        cleanliness_gain = 40,
        hunger_reduction = 0,
        thirst_reduction = 0,
        stress_relief = 30,
        disease_prevention = true
    },
    sink = {
        cleanliness_gain = 15,
        hunger_reduction = 0,
        thirst_reduction = 0,
        stress_relief = 5,
        hand_hygiene = true
    }
}

-- [[ ANIMACIONES, SONIDOS Y EFECTOS VISUALES MEJORADOS ]] ------------
Config.Actions = {
    toilet = {
        scenario = 'PROP_HUMAN_SEAT_TOILET', 
        duration = 12000, 
        text = '🚽 Usar Inodoro (Necesidades Mayores)',
        sound = {
            startName = 'FLUSH_WATER_SOUND',
            startSet = 'MP_AIRCRAFT_MISC_SOUNDS',
            stopName = 'TOILET_FLUSH',
            stopSet = 'MP_AIRCRAFT_MISC_SOUNDS'
        },
        ptfx = {
            dict = 'core',
            name = 'ent_amb_tap_water_drip',
            offset = vector3(0.0, 0.0, 0.5)
        }
    },
    urinal = {
        animDict = 'missbigscore2ig_10',
        animName = 'wash_hands_right',
        duration = 8000,
        text = '🚹 Usar Orinal (Necesidades Menores)',
        sound = {
            startName = 'WATER_TAP_ON',
            startSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET',
            stopName = 'WATER_SHUT_OFF',
            stopSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET'
        }
    },
    shower = {
        animDict = 'switch@franklin@ig_6',
        animName = 'switch_to_shower',
        duration = 20000, 
        text = '🚿 Ducharse (Limpieza Completa)',
        sound = {
            startName = 'FM_CUT_MICHAEL_SHOWER_START',
            startSet = 'MP_FM_CUTSCENES',
            stopName = 'WATER_SHUT_OFF',
            stopSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET'
        },
        ptfx = {
            dict = 'core',
            name = 'ent_amb_shower_steam',
            offset = vector3(0.0, 0.0, 1.2),
            scale = 1.5
        }
    },
    sink = {
        animDict = 'amb@prop_human_toilet@male@four@base',
        animName = '4_wash_hands',
        duration = 8000,
        text = '🚰 Lavarse Manos/Cara (Higiene Básica)',
        sound = {
            startName = 'WATER_TAP_ON',
            startSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET',
            stopName = 'WATER_SHUT_OFF',
            stopSet = 'PI_PLANS_HEIST_PLANS_SOUNDSET'
        },
        ptfx = {
            dict = 'core',
            name = 'ent_amb_sink_tap_water_drip',
            offset = vector3(0.0, 0.0, 0.3)
        }
    }
}

-- [[ SISTEMA DE ENFERMEDADES ]] --------------------------------------
Config.DiseaseSystem = {
    enabled = true,
    diseases = {
        diarrhea = {
            chance = 0.15, -- 15% chance si higiene < 10
            duration = 300000, -- 5 minutos
            effects = { health = -20, stamina = -30 }
        },
        infection = {
            chance = 0.10, -- 10% chance si higiene < 20
            duration = 600000, -- 10 minutos
            effects = { health = -15, stress = 25 }
        }
    }
}

-- [[ UBICACIONES INTERACTIVAS EXPANDIDAS ]] --------------------------
Config.Locations = {
    -- Baños Públicos (Varios en la ciudad)
    {
        coords = vector3(-1261.21, -1438.30, 4.40), 
        heading = 24.0,                            
        type = 'toilet',
        objectModel = GetHashKey('prop_toilet_01'),
        isPublic = true
    },
    {
        coords = vector3(-1262.50, -1438.90, 4.40), 
        heading = 24.0,
        type = 'urinal',
        objectModel = GetHashKey('prop_urinal_01'),
        isPublic = true
    },
    {
        coords = vector3(1832.15, 3690.25, 34.27), -- Sandy Shores
        heading = 210.0,
        type = 'toilet',
        objectModel = GetHashKey('prop_toilet_01'),
        isPublic = true
    },
    
    -- Duchas (Gimnasios, casas)
    {
        coords = vector3(-1147.20, -685.20, 35.70), 
        heading = 330.0,
        type = 'shower',
        objectModel = GetHashKey('prop_shower_01'),
        isPublic = false
    },
    {
        coords = vector3(-1197.45, -774.68, 17.32), -- Gimnasio
        heading = 300.0,
        type = 'shower',
        objectModel = GetHashKey('prop_shower_01'),
        isPublic = true
    },
    
    -- Lavabos (Múltiples ubicaciones)
    {
        coords = vector3(264.80, -1004.80, -100.00), 
        heading = 30.0,
        type = 'sink',
        objectModel = GetHashKey('prop_sink_01'),
        isPublic = false
    },
    {
        coords = vector3(431.29, -807.33, 29.49), -- Comisaría
        heading = 0.0,
        type = 'sink', 
        objectModel = GetHashKey('prop_sink_02'),
        isPublic = true
    }
}

-- [[ CONFIGURACIÓN DE COOLDOWNS MEJORADA ]] --------------------------
Config.Cooldowns = {
    toilet = 180, -- 3 minutos
    urinal = 120, -- 2 minutos
    shower = 300, -- 5 minutos
    sink = 60     -- 1 minuto
}

print('[ESX_BATHROOM] Configuración mejorada cargada - Sistema avanzado de higiene')