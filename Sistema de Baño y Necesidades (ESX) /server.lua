-- ================================================================= --
--                        SERVER.LUA MEJORADO                      --
--         SISTEMA AVANZADO DE HIGIENE Y NECESIDADES              --
-- ================================================================= --

local ESX = nil
local PlayerData = {
    Cooldowns = {},
    Hygiene = {},
    Needs = {},
    Diseases = {}
}

-- [[ INICIALIZACIÓN MEJORADA ]] -------------------------------------
ESX = exports['es_extended']:getSharedObject()

-- Iniciar sistemas
Citizen.CreateThread(function()
    StartHygieneDecaySystem()
    StartDiseaseCheckSystem()
    print('[ESX_BATHROOM] Servidor mejorado inicializado - Sistemas activos')
end)

-- [[ SISTEMA DE METADATA MEJORADO ]] --------------------------------
local METADATA_KEYS = {
    HYGIENE = 'bathroom_cleanliness',
    BLADDER = 'bathroom_bladder', 
    BOWEL = 'bathroom_bowel',
    DISEASES = 'bathroom_diseases'
}

-- Inicializar jugador
AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    InitializePlayerData(xPlayer)
    
    -- Enviar datos iniciales al cliente
    TriggerClientEvent('esx_bathroom:client:initializeNeeds', source, {
        bladder = PlayerData.Needs[source].bladder,
        bowel = PlayerData.Needs[source].bowel
    })
end)

function InitializePlayerData(xPlayer)
    local source = xPlayer.source
    
    -- Higiene
    local currentHygiene = xPlayer.getMetadata(METADATA_KEYS.HYGIENE)
    if currentHygiene == nil then
        currentHygiene = Config.HygieneSystem.initialCleanliness
        xPlayer.setMetadata(METADATA_KEYS.HYGIENE, currentHygiene)
    end
    PlayerData.Hygiene[source] = currentHygiene
    
    -- Necesidades
    PlayerData.Needs[source] = {
        bladder = xPlayer.getMetadata(METADATA_KEYS.BLADDER) or 0,
        bowel = xPlayer.getMetadata(METADATA_KEYS.BOWEL) or 0,
        lastUpdate = GetGameTimer()
    }
    
    -- Enfermedades
    local diseasesData = xPlayer.getMetadata(METADATA_KEYS.DISEASES)
    PlayerData.Diseases[source] = diseasesData or {}
    
    -- Cooldowns
    PlayerData.Cooldowns[source] = {}
    
    if Config.Debug then
        print(string.format('[INIT] Jugador %s - Higiene: %d%%, Vejiga: %d%%, Intestinos: %d%%', 
            GetPlayerName(source), currentHygiene, PlayerData.Needs[source].bladder, PlayerData.Needs[source].bowel))
    end
end

-- [[ SISTEMA DE DECAÍDA DE HIGIENE ]] ------------------------------
function StartHygieneDecaySystem()
    if not Config.HygieneSystem.naturalDecay.enabled then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.HygieneSystem.naturalDecay.interval)
            
            for source, xPlayer in pairs(ESX.GetPlayers()) do
                local playerData = ESX.GetPlayerFromId(source)
                if playerData then
                    ApplyNaturalHygieneDecay(playerData)
                end
            end
        end
    end)
end

function ApplyNaturalHygieneDecay(xPlayer)
    local source = xPlayer.source
    local currentHygiene = PlayerData.Hygiene[source] or Config.HygieneSystem.initialCleanliness
    
    if currentHygiene > 0 then
        local newHygiene = math.max(Config.HygieneSystem.minCleanliness, 
            currentHygiene - Config.HygieneSystem.naturalDecay.rate)
        
        if newHygiene ~= currentHygiene then
            PlayerData.Hygiene[source] = newHygiene
            xPlayer.setMetadata(METADATA_KEYS.HYGIENE, newHygiene)
            
            -- Verificar efectos de baja higiene
            CheckLowHygieneEffects(xPlayer, newHygiene)
            
            if Config.Debug then
                print(string.format('[HIGIENE] %s - Nueva higiene: %d%%', GetPlayerName(source), newHygiene))
            end
        end
    end
end

-- [[ EFECTOS DE BAJA HIGIENE ]] ------------------------------------
function CheckLowHygieneEffects(xPlayer, hygieneLevel)
    for threshold, effect in pairs(Config.HygieneSystem.lowHygieneEffects) do
        if hygieneLevel <= threshold then
            -- Notificar al jugador solo una vez por threshold
            if not PlayerData.Hygiene[xPlayer.source].notifiedThresholds then
                PlayerData.Hygiene[xPlayer.source].notifiedThresholds = {}
            end
            
            if not PlayerData.Hygiene[xPlayer.source].notifiedThresholds[threshold] then
                TriggerClientEvent('esx:showNotification', xPlayer.source, effect.message)
                PlayerData.Hygiene[xPlayer.source].notifiedThresholds[threshold] = true
                
                -- Aplicar efectos de salud si existen
                if effect.healthEffect then
                    -- Aquí podrías integrar con esx_status para afectar salud
                    if Config.Debug then
                        print(string.format('[SALUD] %s - Efecto de salud: %d', GetPlayerName(xPlayer.source), effect.healthEffect))
                    end
                end
                
                -- Verificar enfermedades
                if effect.diseaseChance then
                    CheckDiseaseRisk(xPlayer, effect.diseaseChance)
                end
            end
            break
        end
    end
end

-- [[ SISTEMA DE ENFERMEDADES ]] ------------------------------------
function StartDiseaseCheckSystem()
    if not Config.DiseaseSystem.enabled then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(300000) -- Revisar cada 5 minutos
            
            for source, xPlayer in pairs(ESX.GetPlayers()) do
                local playerData = ESX.GetPlayerFromId(source)
                if playerData and PlayerData.Hygiene[source] then
                    CheckDiseaseRisk(playerData, 0.05) -- 5% base cada 5 minutos si higiene baja
                end
            end
        end
    end)
end

function CheckDiseaseRisk(xPlayer, baseChance)
    local hygiene = PlayerData.Hygiene[xPlayer.source] or 100
    local diseaseChance = baseChance
    
    -- Aumentar chance si higiene es muy baja
    if hygiene < 20 then
        diseaseChance = diseaseChance * 2
    end
    if hygiene < 10 then
        diseaseChance = diseaseChance * 3
    end
    
    if math.random() < diseaseChance then
        AssignRandomDisease(xPlayer)
    end
end

function AssignRandomDisease(xPlayer)
    local source = xPlayer.source
    
    for diseaseName, diseaseConfig in pairs(Config.DiseaseSystem.diseases) do
        if math.random() < diseaseConfig.chance then
            -- Agregar enfermedad al jugador
            if not PlayerData.Diseases[source] then
                PlayerData.Diseases[source] = {}
            end
            
            local diseaseEndTime = GetGameTimer() + diseaseConfig.duration
            PlayerData.Diseases[source][diseaseName] = diseaseEndTime
            
            -- Guardar en metadata
            xPlayer.setMetadata(METADATA_KEYS.DISEASES, PlayerData.Diseases[source])
            
            -- Notificar al jugador
            local diseaseMessages = {
                diarrhea = '🤢 ¡Has contraído diarrea! Busca un baño rápido.',
                infection = '🤕 Tienes una infección. Mejora tu higiene.'
            }
            
            TriggerClientEvent('esx:showNotification', source, diseaseMessages[diseaseName] or '💊 Has contraído una enfermedad.')
            
            -- Aplicar efectos inmediatos
            ApplyDiseaseEffects(xPlayer, diseaseName)
            
            if Config.Debug then
                print(string.format('[ENFERMEDAD] %s - Contrajo: %s', GetPlayerName(source), diseaseName))
            end
            break
        end
    end
end

function ApplyDiseaseEffects(xPlayer, diseaseName)
    local diseaseConfig = Config.DiseaseSystem.diseases[diseaseName]
    if not diseaseConfig then return end
    
    local source = xPlayer.source
    
    -- Aplicar efectos de salud
    if diseaseConfig.effects.health then
        -- Integrar con esx_status para reducir salud
        TriggerClientEvent('esx_bathroom:client:applyDiseaseEffect', source, diseaseConfig.effects)
    end
    
    -- Programar curación
    Citizen.SetTimeout(diseaseConfig.duration, function()
        if PlayerData.Diseases[source] and PlayerData.Diseases[source][diseaseName] then
            PlayerData.Diseases[source][diseaseName] = nil
            xPlayer.setMetadata(METADATA_KEYS.DISEASES, PlayerData.Diseases[source])
            
            TriggerClientEvent('esx:showNotification', source, '✅ Te has recuperado de ' .. diseaseName)
            TriggerClientEvent('esx_bathroom:client:removeDiseaseEffect', source, diseaseName)
        end
    end)
end

-- [[ EVENTO PRINCIPAL MEJORADO ]] ----------------------------------
RegisterServerEvent('esx_bathroom:finishAction')
AddEventHandler('esx_bathroom:finishAction', function(actionType)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end

    local effects = Config.Effects[actionType]
    local cooldownTime = (Config.Cooldowns[actionType] or Config.ActionCooldown) * 1000
    local now = GetGameTimer()

    -- Verificar cooldown
    if not CheckCooldown(source, actionType, now) then
        return
    end

    -- Aplicar efectos mejorados
    ApplyActionEffects(xPlayer, actionType, effects)
    
    -- Establecer cooldown
    SetCooldown(source, actionType, now + cooldownTime)
    
    -- Log para administradores
    if Config.Debug then
        print(string.format('[ACCIÓN] %s - %s completado', GetPlayerName(source), actionType))
    end
end)

-- [[ APLICACIÓN DE EFECTOS MEJORADA ]] -----------------------------
function ApplyActionEffects(xPlayer, actionType, effects)
    local source = xPlayer.source
    
    -- 1. EFECTOS BÁSICOS (Hambre/Sed)
    if effects.hunger_reduction > 0 then
        local currentHunger = xPlayer.getHunger()
        local newHunger = math.max(0, currentHunger - effects.hunger_reduction)
        xPlayer.setHunger(newHunger)
    end

    if effects.thirst_reduction > 0 then
        local currentThirst = xPlayer.getThirst()
        local newThirst = math.max(0, currentThirst - effects.thirst_reduction)
        xPlayer.setThirst(newThirst)
    end

    -- 2. HIGIENE MEJORADA
    if effects.cleanliness_gain > 0 then
        local currentHygiene = PlayerData.Hygiene[source] or Config.HygieneSystem.initialCleanliness
        local newHygiene = math.min(Config.HygieneSystem.maxCleanliness, currentHygiene + effects.cleanliness_gain)
        
        PlayerData.Hygiene[source] = newHygiene
        xPlayer.setMetadata(METADATA_KEYS.HYGIENE, newHygiene)
        
        -- Limpiar notificaciones de thresholds si la higiene mejora
        if PlayerData.Hygiene[source].notifiedThresholds then
            PlayerData.Hygiene[source].notifiedThresholds = {}
        end
        
        TriggerClientEvent('esx:showNotification', source, 
            '🛁 ¡Te sientes más limpio! Higiene: ' .. math.floor(newHygiene) .. '%')
    end

    -- 3. PREVENCIÓN DE ENFERMEDADES
    if effects.disease_prevention then
        ClearDiseases(xPlayer)
        TriggerClientEvent('esx:showNotification', source, '✅ Baño completo - Enfermedades prevenidas')
    end

    -- 4. ALIVIO DE ESTRÉS (Integración con esx_status)
    if effects.stress_relief > 0 then
        -- Aquí integrarías con tu sistema de estrés
        TriggerClientEvent('esx:showNotification', source, '😌 Sientes alivio y relax')
    end

    -- 5. NOTIFICACIÓN FINAL MEJORADA
    local message = GetSuccessMessage(actionType, effects)
    TriggerClientEvent('esx:showNotification', source, message)
end

function GetSuccessMessage(actionType, effects)
    local messages = {
        toilet = '🚽 Necesidades satisfechas - Te sientes aliviado',
        urinal = '🚹 Alivio rápido - Listo para continuar',
        shower = '🚿 ¡Impecable! Higiene al máximo', 
        sink = '🚰 Manos limpias - Listo para lo que venga'
    }
    
    return messages[actionType] or '✅ Acción completada satisfactoriamente'
end

-- [[ SISTEMA DE COOLDOWNS MEJORADO ]] ------------------------------
function CheckCooldown(source, actionType, currentTime)
    local cooldowns = PlayerData.Cooldowns[source] or {}
    
    if cooldowns[actionType] and currentTime < cooldowns[actionType] then
        local remaining = math.ceil((cooldowns[actionType] - currentTime) / 1000)
        TriggerClientEvent('esx:showNotification', source, 
            '⏰ Espera ' .. remaining .. ' segundos antes de usar ' .. actionType .. ' nuevamente')
        return false
    end
    
    return true
end

function SetCooldown(source, actionType, cooldownEndTime)
    if not PlayerData.Cooldowns[source] then
        PlayerData.Cooldowns[source] = {}
    end
    
    PlayerData.Cooldowns[source][actionType] = cooldownEndTime
    TriggerClientEvent('esx_bathroom:setCooldownClient', source, actionType, cooldownEndTime)
end

-- [[ LIMPIEZA DE ENFERMEDADES ]] -----------------------------------
function ClearDiseases(xPlayer)
    local source = xPlayer.source
    
    if PlayerData.Diseases[source] then
        for diseaseName, _ in pairs(PlayerData.Diseases[source]) do
            TriggerClientEvent('esx_bathroom:client:removeDiseaseEffect', source, diseaseName)
        end
        
        PlayerData.Diseases[source] = {}
        xPlayer.setMetadata(METADATA_KEYS.DISEASES, {})
        
        TriggerClientEvent('esx:showNotification', source, '💊 Enfermedades eliminadas - Buena higiene')
    end
end

-- [[ EVENTOS DE DESCONEXIÓN ]] -------------------------------------
AddEventHandler('esx:playerDropped', function(source)
    PlayerData.Cooldowns[source] = nil
    PlayerData.Hygiene[source] = nil
    PlayerData.Needs[source] = nil
    PlayerData.Diseases[source] = nil
end)

-- [[ COMANDOS DE ADMINISTRACIÓN ]] ---------------------------------
RegisterCommand('bathroom_admin', function(source, args)
    if source == 0 or IsPlayerAceAllowed(source, 'command.bathroom_admin') then
        print('=== ESX_BATHROOM ADMIN ===')
        print('Jugadores conectados: ' .. #GetPlayers())
        
        local totalHygiene = 0
        local playerCount = 0
        
        for src, _ in pairs(PlayerData.Hygiene) do
            if PlayerData.Hygiene[src] then
                totalHygiene = totalHygiene + PlayerData.Hygiene[src]
                playerCount = playerCount + 1
                
                print(string.format('  %s: %d%% higiene', GetPlayerName(src), PlayerData.Hygiene[src]))
            end
        end
        
        if playerCount > 0 then
            print('Higiene promedio: ' .. math.floor(totalHygiene / playerCount) .. '%')
        end
        print('==========================')
    end
end, false)

-- [[ FUNCIONES AUXILIARES ]] ---------------------------------------
function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

print('[ESX_BATHROOM] Servidor mejorado completamente cargado')