-- ================================================================= --
--                             SERVER.LUA                            --
--         LÓGICA DEL LADO DEL SERVIDOR (Efectos y Sincronización)   --
-- ================================================================= --

local ESX = nil
local PlayerCooldowns = {} -- Almacenamiento temporal de los cooldowns del jugador: { source = { type = timestamp } }

-- [[ 1. INICIALIZACIÓN Y ESX ]] ----------------------------------------
ESX = exports['es_extended']:getSharedObject()


-- [[ 2. EVENTO: APLICAR EFECTOS AL FINALIZAR LA ACCIÓN ]] ---------------

RegisterServerEvent('esx_bathroom:finishAction')
AddEventHandler('esx_bathroom:finishAction', function(actionType)
    local xPlayer = ESX.GetPlayerFromId(source)
    local effects = Config.Effects[actionType]
    local cooldownTime = Config.ActionCooldown * 1000 -- Convertir segundos a milisegundos

    -- === 2.1. VERIFICACIÓN DE COOLDOWN ===
    local cooldowns = PlayerCooldowns[source] or {}
    local now = GetGameTimer()

    if cooldowns[actionType] and now < cooldowns[actionType] then
        -- Jugador en cooldown, no aplicar efectos.
        local remaining = math.ceil((cooldowns[actionType] - now) / 1000)
        TriggerClientEvent('esx:showNotification', source, 'Debes esperar ' .. remaining .. ' segundos antes de volver a usar ' .. Config.Actions[actionType].text .. '.')
        return
    end

    -- === 2.2. APLICACIÓN DE EFECTOS ===
    if effects and xPlayer then
        -- 1. Reducción de Hambre (si aplica, ej. Inodoro)
        if effects.hunger_reduction > 0 then
            local currentHunger = xPlayer.getHunger()
            local newHunger = math.max(0, currentHunger - effects.hunger_reduction)
            xPlayer.setHunger(newHunger)
            TriggerClientEvent('esx:showNotification', source, 'Sientes un alivio inmediato. Hambre reducida.')
        end

        -- 2. Reducción de Sed (si aplica, ej. Inodoro)
        if effects.thirst_reduction > 0 then
            local currentThirst = xPlayer.getThirst()
            local newThirst = math.max(0, currentThirst - effects.thirst_reduction)
            xPlayer.setThirst(newThirst)
            TriggerClientEvent('esx:showNotification', source, 'Sientes menos sed.')
        end

        -- 3. Ganancia de Limpieza (Implementación Base)
        if effects.cleanliness_gain > 0 then
            -- Para una implementación real, aquí iría la función de tu base:
            -- xPlayer.setCleanliness(xPlayer.getCleanliness() + effects.cleanliness_gain)
            
            TriggerClientEvent('esx:showNotification', source, '¡Te sientes mucho más limpio!')
        end

        -- === 2.3. ESTABLECER COOLDOWN ===
        cooldowns[actionType] = now + cooldownTime
        PlayerCooldowns[source] = cooldowns
        
        -- ENVIAR EL COOLDOWN AL CLIENTE para la UX
        TriggerClientEvent('esx_bathroom:setCooldownClient', source, actionType, cooldowns[actionType])
    end
end)


-- [[ 3. LÓGICA DE DESCONEXIÓN (Limpiar Cooldowns) ]] --------------------
-- Esto es crucial para liberar memoria del servidor
AddEventHandler('esx:playerDropped', function(playerId)
    PlayerCooldowns[playerId] = nil
end)
