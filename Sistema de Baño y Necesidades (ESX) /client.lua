-- ================================================================= --
--                             CLIENT.LUA                            --
--         LÓGICA DEL LADO DEL CLIENTE (Detección, Animaciones)      --
-- ================================================================= --

local ESX = nil
local PlayerData = {}
local isNearObject = false -- Bandera para saber si ya estamos en un rango de interacción
local currentZone = nil     -- Almacena la zona activa (para el menú y la interacción)
local ActionTimestamps = {} -- { type = timestamp_fin } para cooldown en cliente

-- [[ 1. INICIALIZACIÓN Y ESX ]] ----------------------------------------
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end

    -- Obtener datos del jugador
    while PlayerData.job == nil do
        Citizen.Wait(10)
        PlayerData = ESX.GetPlayerData()
    end
end)


-- [[ 2. BUCLE DE DETECCIÓN DE ZONA ]] ----------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Espera mínima para no sobrecargar la CPU

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local closestDist = Config.DrawDistance + 1.0 -- Inicializamos una distancia mayor a la de detección
        local closestZone = nil

        -- Iterar sobre todas las ubicaciones de la configuración
        for i=1, #Config.Locations, 1 do
            local v = Config.Locations[i]
            local dist = #(playerCoords - v.coords)

            if dist < closestDist and dist <= Config.DrawDistance then
                closestDist = dist
                closestZone = v
            end
        end

        -- Si encontramos la zona más cercana dentro del rango:
        if closestZone ~= nil then
            -- Mostrar texto de ayuda
            if not isNearObject then
                ESX.ShowHelpNotification(string.format(_U('press_key_to_interact'), Config.InteractKey))
                isNearObject = true
                currentZone = closestZone
            end

            -- Manejar la interacción (Tecla 'E' por defecto)
            -- Se añade la verificación de menú abierto y cooldown antes de disparar el evento
            if IsControlJustReleased(0, 38) and not IsPedInAnyVehicle(playerPed, false) and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'bathroom_interaction_menu') then -- 38 es la tecla 'E'
                if not IsActionOnCooldown(currentZone.type) then
                    TriggerEvent('esx_bathroom:openMenu', currentZone)
                else
                    ESX.ShowNotification(_U('wait_cooldown'))
                end
            end

            -- Si no estamos cerca de NADA:
        else
            if isNearObject then
                ESX.HideHelpNotification() -- Ocultar notificación si salimos del rango
                isNearObject = false
                currentZone = nil
            end
            -- Si no estamos cerca de nada, podemos esperar más para ahorrar recursos
            Citizen.Wait(500)
        end
    end
end)


-- [[ 3. LÓGICA DE MENÚ (Menú Interactivo de ESX) ]] ---------------------

RegisterNetEvent('esx_bathroom:openMenu')
AddEventHandler('esx_bathroom:openMenu', function(zoneData)
    
    local elements = {}
    local actionConfig = Config.Actions[zoneData.type]

    -- Solo debe haber una opción en la mayoría de los casos (ducha, inodoro, etc.)
    table.insert(elements, {
        label = actionConfig.text, 
        value = zoneData.type      
    })

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'bathroom_interaction_menu',
        {
            title    = string.upper(zoneData.type), -- Título: TOILET, SHOWER, SINK
            elements = elements,
        },
        function(data, menu)
            -- Cuando el jugador selecciona la acción
            menu.close()
            
            -- Disparar la acción con las coordenadas y heading de la zona
            TriggerEvent('esx_bathroom:startAction', data.current.value, zoneData.coords, zoneData.heading)
        end,
        function(data, menu)
            -- Al cerrar el menú
            menu.close()
        end
    )
end)


-- [[ 4. LÓGICA DE LA ACCIÓN (Animaciones) ]] ----------------------------

RegisterNetEvent('esx_bathroom:startAction')
AddEventHandler('esx_bathroom:startAction', function(actionType, coords, heading)
    local actionConfig = Config.Actions[actionType]
    local playerPed = PlayerPedId()

    -- Congelar/Bloquear al jugador
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    SetEntityHeading(playerPed, heading)
    FreezeEntityPosition(playerPed, true)
    
    -- Lógica de las Animaciones
    -- 1. Intentar con un Escenario (más estable y con colisión)
    if actionConfig.scenario then
        TaskStartScenarioInPlace(playerPed, actionConfig.scenario, 0, true)
    
    -- 2. Si no hay escenario, usar animación por diccionario
    elseif actionConfig.animDict and actionConfig.animName then
        ESX.Streaming.RequestAnimDict(actionConfig.animDict, function()
            TaskPlayAnim(playerPed, actionConfig.animDict, actionConfig.animName, 8.0, -8.0, actionConfig.duration, 1, 0, false, false, false)
        end)
    end
    
    -- Esperar la duración de la acción
    Citizen.Wait(actionConfig.duration)

    -- Finalizar la animación/escenario y descongelar
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)

    -- Disparar los efectos al servidor.
    TriggerServerEvent('esx_bathroom:finishAction', actionType)
end)


-- [[ 5. GESTIÓN DE COOLDOWNS (Lado Cliente) ]] --------------------------

-- Recibe la señal del servidor para establecer el cooldown
RegisterNetEvent('esx_bathroom:setCooldownClient')
AddEventHandler('esx_bathroom:setCooldownClient', function(actionType, cooldownEndTimestamp)
    ActionTimestamps[actionType] = cooldownEndTimestamp
end)

-- Comprueba si la acción está en cooldown
function IsActionOnCooldown(actionType)
    local endTimestamp = ActionTimestamps[actionType]
    if endTimestamp then
        local now = GetGameTimer()
        return now < endTimestamp
    end
    return false
end

-- Limpiar el timestamp cuando el jugador se desconecta (aunque el servidor ya lo hace)
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

-- Función ESX para obtener traducción
if GetConvar('esx:use_custom_ui', 'false') ~= 'false' then
    function _U(key, ...)
        if Translations[key] ~= nil then
            return Translations[key]:format(...)
        else
            return 'TEXT_NOT_FOUND'
        end
    end
end
