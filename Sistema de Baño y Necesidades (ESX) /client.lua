-- ================================================================= --
--                             CLIENT.LUA                            --
--         LÓGICA DEL LADO DEL CLIENTE (Detección, Animaciones, Sonidos, PTFX) --
-- ================================================================= --

local ESX = nil
local PlayerData = {}
local isNearObject = false 
local currentZone = nil     
local ActionTimestamps = {} 
local isActionInProgress = false -- Bloqueo de acciones
local ptfxHandle = 0             -- Handle para la partícula de PTFX

-- [[ FUNCIONES DE DIBUJO 3D ]] -----------------------------------------

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local dist = GetDistanceBetweenCoords(GetGameplayCamCoords(), x, y, z, 1)
    local scale = 1 / dist * 2
    local fov = (1 / GetGameplayCamFov()) * 10
    local scale = scale * fov
    
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

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


-- [[ 2. BUCLE DE DETECCIÓN Y DIBUJO 3D ]] ----------------------------------
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

        if closestZone ~= nil and not isActionInProgress then
            local actionConfig = Config.Actions[closestZone.type]
            
            -- DIBUJAR TEXTO 3D
            DrawText3D(closestZone.coords.x, closestZone.coords.y, closestZone.coords.z + 1.0, 
                string.format("~b~[%s]~w~ %s", GetKeyName(Config.InteractKey), actionConfig.text))

            if not isNearObject then
                isNearObject = true
                currentZone = closestZone
            end

            -- Manejar la interacción (Tecla 'E')
            if IsControlJustReleased(0, Config.InteractKey) and not IsPedInAnyVehicle(playerPed, false) and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'bathroom_interaction_menu') then 
                if not IsActionOnCooldown(currentZone.type) then
                    TriggerEvent('esx_bathroom:openMenu', currentZone)
                else
                    ESX.ShowNotification(_U('wait_cooldown'))
                end
            end
        else
            if isNearObject then
                isNearObject = false
                currentZone = nil
            end
            Citizen.Wait(500)
        end
    end
end)


-- [[ 3. LÓGICA DE MENÚ ]] -------------------------------------

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


-- [[ 4. LÓGICA DE LA ACCIÓN (Animaciones, Sonidos y PTFX) ]] ----------------------------

RegisterNetEvent('esx_bathroom:startAction')
AddEventHandler('esx_bathroom:startAction', function(actionType, coords, heading)
    local actionConfig = Config.Actions[actionType]
    local playerPed = PlayerPedId()
    
    isActionInProgress = true

    -- Congelar/Bloquear al jugador y posicionar
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    SetEntityHeading(playerPed, heading)
    FreezeEntityPosition(playerPed, true)
    
    -- Iniciar Sonido
    if actionConfig.sound and actionConfig.sound.startName then
        PlaySoundFrontend(-1, actionConfig.sound.startName, actionConfig.sound.startSet, true)
    end
    
    -- Iniciar Partícula (PTFX)
    if actionConfig.ptfx then
        ESX.Streaming.RequestPtfxAsset(actionConfig.ptfx.dict, function()
            local boneIndex = GetEntityBoneIndexByName(playerPed, 'skel_head') -- Se puede usar un hueso o la posición
            ptfxHandle = StartParticleFxLoopedAtCoord(
                actionConfig.ptfx.name, 
                coords.x + actionConfig.ptfx.offset.x, 
                coords.y + actionConfig.ptfx.offset.y, 
                coords.z + actionConfig.ptfx.offset.z, 
                0.0, 0.0, 0.0, 
                1.0, false, false, false, false
            )
        end)
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

    -- Detener Partícula (PTFX)
    if ptfxHandle ~= 0 then
        StopParticleFxLooped(ptfxHandle, 0)
        ptfxHandle = 0
    end
    
    -- Detener Sonido de Cierre
    if actionConfig.sound and actionConfig.sound.stopName then
        PlaySoundFrontend(-1, actionConfig.sound.stopName, actionConfig.sound.stopSet, true)
    end
    
    -- Finalizar la animación/escenario y descongelar
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)

    isActionInProgress = false
    
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
-- Función GetKeyName para obtener el nombre legible de la tecla (para DrawText3D)
function GetKeyName(control)
    return GetControlInstructionalButton(2, control, true)
end

local Translations = {
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
