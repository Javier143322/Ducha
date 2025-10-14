-- ================================================================= --
--                             SERVER.LUA                            --
--         LÓGICA DEL LADO DEL SERVIDOR (Efectos y Limpieza)         --
-- ================================================================= --

local ESX = nil
local PlayerCooldowns = {} 

-- [[ 1. INICIALIZACIÓN Y ESX ]] ----------------------------------------
ESX = exports['es_extended']:getSharedObject()


-- [[ 2. SISTEMA DE LIMPIEZA BASE ]] ------------------------------------

-- Inicializa el estado de limpieza al conectarse
AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Intentar obtener el dato de limpieza de la sesión o inicializarlo.
    -- NOTA: Esto solo persiste la limpieza durante la sesión.
    if xPlayer.getSessionData('cleanliness') == nil then
        xPlayer.setSessionData('cleanliness', Config.InitialCleanliness)
    end
    
    -- Puedes disparar un evento al cliente para mostrar el estado de limpieza si es necesario.
    -- TriggerClientEvent('esx_bathroom:updateCleanliness', source, xPlayer.getSessionData('cleanliness'))
end)


-- Función para obtener la limpieza actual del jugador
local function getCleanliness(xPlayer)
    -- Intenta obtener de la sesión. Si no existe (raro), usa 0.
    return xPlayer.getSessionData('cleanliness') or 0
end

-- Función para actualizar la limpieza del jugador
local function setCleanliness(xPlayer, amount)
    local newCleanliness = math.min(100, math.max(0, amount)) -- Limitar entre 0 y 100
    xPlayer.setSessionData('cleanliness', newCleanliness)
    
    -- Notificar al cliente (ejemplo: para una NUI o efecto visual)
    -- TriggerClientEvent('esx_bathroom:updateCleanliness', xPlayer.source, newCleanliness)
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
        
        -- 1. Reducción de Hambre
        if effects.hunger_reduction > 0 then
            local currentHunger = xPlayer.getHunger()
            local newHunger = math.max(0, currentHunger - effects.hunger_reduction)
            xPlayer.setHunger(newHunger)
            TriggerClientEvent('esx:showNotification', source, 'Sientes un alivio. Hambre reducida.')
        end

        -- 2. Reducción de Sed
        if effects.thirst_reduction > 0 then
            local currentThirst = xPlayer.getThirst()
            local newThirst = math.max(0, currentThirst - effects.thirst_reduction)
            xPlayer.setThirst(newThirst)
            TriggerClientEvent('esx:showNotification', source, 'Sientes menos sed.')
        end

        -- 3. Ganancia de Limpieza
        if effects.cleanliness_gain > 0 then
            local currentCleanliness = getCleanliness(xPlayer)
            local newCleanliness = setCleanliness(xPlayer, currentCleanliness + effects.cleanliness_gain)
            
            TriggerClientEvent('esx:showNotification', source, '¡Te sientes mucho más limpio! (Limpieza: ' .. newCleanliness .. '%)')
        end

        -- === 3.3. ESTABLECER COOLDOWN ===
        cooldowns[actionType] = now + cooldownTime
        PlayerCooldowns[source] = cooldowns
        
        -- ENVIAR EL COOLDOWN AL CLIENTE para la UX
        TriggerClientEvent('esx_bathroom:setCooldownClient', source, actionType, cooldowns[actionType])
    end
end)


-- [[ 4. LÓGICA DE DESCONEXIÓN (Limpiar Cooldowns) ]] --------------------
AddEventHandler('esx:playerDropped', function(playerId)
    PlayerCooldowns[playerId] = nil
end)
