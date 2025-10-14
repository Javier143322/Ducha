-- ================================================================= --
--                             SERVER.LUA                            --
--         LÓGICA DEL LADO DEL SERVIDOR (Efectos y Limpieza Persistente) --
-- ================================================================= --

local ESX = nil
local PlayerCooldowns = {} 
local CLEANLINESS_KEY = 'cleanliness' -- Clave usada en la metadata del jugador

-- [[ 1. INICIALIZACIÓN Y ESX ]] ----------------------------------------
ESX = exports['es_extended']:getSharedObject()


-- [[ 2. SISTEMA DE LIMPIEZA PERSISTENTE (Metadata) ]] --------------------

-- Inicializa el estado de limpieza al conectarse
AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Intenta obtener la limpieza de la metadata (DB), si no existe, la inicializa.
    local currentCleanliness = xPlayer.getMetadata(CLEANLINESS_KEY)
    
    if currentCleanliness == nil then
        xPlayer.setMetadata(CLEANLINESS_KEY, Config.InitialCleanliness)
        currentCleanliness = Config.InitialCleanliness
    end
    
    -- Opcional: Notificar al jugador su nivel inicial de limpieza
    TriggerClientEvent('esx:showNotification', source, 'Tu nivel de limpieza actual es: ' .. math.floor(currentCleanliness) .. '%')
end)

-- Función para obtener la limpieza actual del jugador
local function getCleanliness(xPlayer)
    -- Si la metadata no existe por alguna razón, devuelve el valor inicial.
    return xPlayer.getMetadata(CLEANLINESS_KEY) or Config.InitialCleanliness
end

-- Función para actualizar la limpieza del jugador y guardarla
local function setCleanliness(xPlayer, amount)
    local newCleanliness = math.min(100, math.max(0, amount)) -- Limitar entre 0 y 100
    
    xPlayer.setMetadata(CLEANLINESS_KEY, newCleanliness)
    
    -- Es crucial forzar el guardado si se usa un sistema de guardado asíncrono.
    -- La función SavePlayer se usa en bases ESX antiguas o para forzar el guardado.
    -- ESX.SavePlayer(xPlayer) 

    return newCleanliness
end


-- [[ 3. EVENTO: APLICAR EFECTOS AL FINALIZAR LA ACCIÓN ]] ---------------

RegisterServerEvent('esx_bathroom:finishAction')
AddEventHandler('esx_bathroom:finishAction', function(actionType)
    local xPlayer = ESX.GetPlayerFromId(source)
    local effects = Config.Effects[actionType]
    local cooldownTime = Config.ActionCooldown * 1000 
    local now = GetGameTimer()

    -- === 3.1. VERIFICACIÓN DE COOLDOWN ===
    local cooldowns = PlayerCooldowns[source] or {}

    if cooldowns[actionType] and now < cooldowns[actionType] then
        local remaining = math.ceil((cooldowns[actionType] - now) / 1000)
        TriggerClientEvent('esx:showNotification', source, 'Debes esperar ' .. remaining .. ' segundos antes de volver a usar ' .. Config.Actions[actionType].text .. '.')
        return
    end

    -- === 3.2. APLICACIÓN DE EFECTOS ===
    if effects and xPlayer then
        
        -- 1. Reducción de Hambre/Sed
        if effects.hunger_reduction > 0 then
            local currentHunger = xPlayer.getHunger()
            local newHunger = math.max(0, currentHunger - effects.hunger_reduction)
            xPlayer.setHunger(newHunger)
            TriggerClientEvent('esx:showNotification', source, 'Sientes un alivio. Hambre reducida.')
        end

        if effects.thirst_reduction > 0 then
            local currentThirst = xPlayer.getThirst()
            local newThirst = math.max(0, currentThirst - effects.thirst_reduction)
            xPlayer.setThirst(newThirst)
            TriggerClientEvent('esx:showNotification', source, 'Sientes menos sed.')
        end

        -- 2. Ganancia de Limpieza
        if effects.cleanliness_gain > 0 then
            local currentCleanliness = getCleanliness(xPlayer)
            local newCleanliness = setCleanliness(xPlayer, currentCleanliness + effects.cleanliness_gain)
            
            TriggerClientEvent('esx:showNotification', source, '¡Te sientes mucho más limpio! (Limpieza: ' .. math.floor(newCleanliness) .. '%)')
        end

        -- === 3.3. ESTABLECER COOLDOWN ===
        cooldowns[actionType] = now + cooldownTime
        PlayerCooldowns[source] = cooldowns
        
        TriggerClientEvent('esx_bathroom:setCooldownClient', source, actionType, cooldowns[actionType])
    end
end)


-- [[ 4. LÓGICA DE DESCONEXIÓN (Limpiar Cooldowns) ]] --------------------
AddEventHandler('esx:playerDropped', function(playerId)
    PlayerCooldowns[playerId] = nil
end)
