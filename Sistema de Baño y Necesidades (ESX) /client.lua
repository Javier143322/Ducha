-- ================================================================= --
--                             CLIENT.LUA                            --
--         LÓGICA DEL LADO DEL CLIENTE (Detección, Animaciones, Sonidos) --
-- ================================================================= --

local ESX = nil
local PlayerData = {}
local isNearObject = false 
local currentZone = nil     
local ActionTimestamps = {} 

-- [[ 1. INICIALIZACIÓN Y ESX ]] ----------------------------------------
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end

    while PlayerData.job == nil do
        Citizen.Wait(10)
        PlayerData = ESX.GetPlayerData()
    end
end)


-- [[ 2. BUCLE DE DETECCIÓN DE ZONA ]] ----------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) 

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local closestDist = Config.DrawDistance + 1.0 
        local closestZone = nil

        for i=1, #Config.Locations, 1 do
            local v = Config.Locations[i]
            local dist = #(playerCoords - v.coords)

            if dist < closestDist and dist <= Config.DrawDistance then
                closestDist = dist
                closestZone = v
            end
        end

        if closestZone ~= nil then
            if not isNearObject then
                ESX.ShowHelpNotification(string.format(_U('press_key_to_interact'), Config.InteractKey))
                isNearObject = true
                currentZone = closestZone
            end

            if IsControlJustReleased(0, 38) and not IsPedInAnyVehicle(playerPed, false) and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'bathroom_interaction_menu') then 
                if not IsActionOnCooldown(currentZone.type) then
                    TriggerEvent('esx_bathroom:openMenu', currentZone)
                else
                    ESX.ShowNotification(_U('wait_cooldown'))
                end
            end
        else
            if isNearObject then
                ESX.HideHelpNotification() 
                isNearObject = false
                currentZone = nil
            end
            Citizen.Wait(500)
        end
    end
end)


-- [[ 3. LÓGICA DE MENÚ (Menú Interactivo de ESX) ]] ---------------------

RegisterNetEvent('esx_bathroom:openMenu')
AddEventHandler('esx_bathroom:openMenu', function(zoneData)
    
    local elements = {}
    local actionConfig = Config.Actions[zoneData.type]

    table.insert(elements, {
        label = actionConfig.text, 
        value = zoneData.type      
    })

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'bathroom_interaction_menu',
        {
            title    = string.upper(zoneData.type),
            elements = elements,
        },
        function(data, menu)
            menu.close()
            TriggerEvent('esx_bathroom:startAction', data.current.value, zoneData.coords, zoneData.heading)
        end,
        function(data, menu)
            menu.close()
        end
    )
end)


-- [[ 4. LÓGICA DE LA ACCIÓN (Animaciones y Sonidos) ]] ----------------------------

RegisterNetEvent('esx_bathroom:startAction')
AddEventHandler('esx_bathroom:startAction', function(actionType, coords, heading)
    local actionConfig = Config.Actions[actionType]
    local playerPed = PlayerPedId()

    -- Congelar/Bloquear al jugador
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    SetEntityHeading(playerPed, heading)
    FreezeEntityPosition(playerPed, true)
    
    -- Iniciar Sonido
    if actionConfig.sound then
        PlaySoundFrontend(-1, actionConfig.sound.name, actionConfig.sound.set, true)
    end
    
    -- Lógica de las Animaciones
    if actionConfig.scenario then
        TaskStartScenarioInPlace(playerPed, actionConfig.scenario, 0, true)
    elseif actionConfig.animDict and actionConfig.animName then
        ESX.Streaming.RequestAnimDict(actionConfig.animDict, function()
            TaskPlayAnim(playerPed, actionConfig.animDict, actionConfig.animName, 8.0, -8.0, actionConfig.duration, 1, 0, false, false, false)
        end)
    end
    
    -- Esperar la duración de la acción
    Citizen.Wait(actionConfig.duration)

    -- Detener Sonido (solo si el sonido no es de evento único como el 'flush')
    if actionConfig.sound and (actionType == 'shower' or actionType == 'sink') then
        -- No hay una función nativa de 'StopSoundFrontend', se asume que el sonido es corto o lo gestiona GTA.
        -- Para sonidos largos como la ducha, el sonido se detendrá al dejar de ejecutar la animación.
    end
    
    -- Finalizar la animación/escenario y descongelar
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)

    -- Disparar los efectos al servidor.
    TriggerServerEvent('esx_bathroom:finishAction', actionType)
end)


-- [[ 5. GESTIÓN DE COOLDOWNS (Lado Cliente) ]] --------------------------

RegisterNetEvent('esx_bathroom:setCooldownClient')
AddEventHandler('esx_bathroom:setCooldownClient', function(actionType, cooldownEndTimestamp)
    ActionTimestamps[actionType] = cooldownEndTimestamp
end)

function IsActionOnCooldown(actionType)
    local endTimestamp = ActionTimestamps[actionType]
    if endTimestamp then
        local now = GetGameTimer()
        return now < endTimestamp
    end
    return false
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ActionTimestamps = {}
    end
end)


-- [[ 6. LOCALIZACIÓN/TEXTOS ]] ------------------------------------------

local Translations = {
    ['press_key_to_interact'] = 'Pulsa [ %s ] para interactuar con la zona.',
    ['wait_cooldown']         = 'Debes esperar un poco antes de volver a usar esto.' 
}

if GetConvar('esx:use_custom_ui', 'false') ~= 'false' then
    function _U(key, ...)
        if Translations[key] ~= nil then
            return Translations[key]:format(...)
        else
            return 'TEXT_NOT_FOUND'
        end
    end
end
