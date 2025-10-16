-- ================================================================= --
--                        CLIENT.LUA MEJORADO                      --
--         SISTEMA AVANZADO DE HIGIENE Y NECESIDADES              --
-- ================================================================= --

local ESX = nil
local PlayerData = {}
local isNearObject = false 
local currentZone = nil     
local ActionTimestamps = {} 
local isActionInProgress = false
local ptfxHandle = 0
local needsUpdateTimer = 0
local playerNeeds = {
    bladder = 0,    -- Vejiga (0-100)
    bowel = 0,      -- Intestinos (0-100)
    lastUpdate = GetGameTimer()
}

-- [[ INICIALIZACIÓN MEJORADA ]] -------------------------------------
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end

    while PlayerData.job == nil do
        Citizen.Wait(10)
        PlayerData = ESX.GetPlayerData()
    end
    
    -- Iniciar sistema de necesidades
    StartNeedsSystem()
    print('[ESX_BATHROOM] Cliente mejorado inicializado - Sistema de necesidades activo')
end)

-- [[ SISTEMA DE NECESIDADES FISIOLÓGICAS ]] ------------------------
function StartNeedsSystem()
    Citizen.CreateThread(function()
        while true do
            local currentTime = GetGameTimer()
            
            -- Actualizar necesidades cada 30 segundos
            if currentTime - needsUpdateTimer >= Config.NeedsSystem.updateInterval then
                UpdatePlayerNeeds()
                needsUpdateTimer = currentTime
            end
            
            -- Verificar efectos de necesidades urgentes
            CheckNeedsEffects()
            
            Citizen.Wait(5000) -- Revisar cada 5 segundos
        end
    end)
end

function UpdatePlayerNeeds()
    if not Config.NeedsSystem.enabled then return end
    
    -- Aumentar necesidades naturales
    playerNeeds.bladder = math.min(100, playerNeeds.bladder + Config.NeedsSystem.bladderIncrease)
    playerNeeds.bowel = math.min(100, playerNeeds.bowel + Config.NeedsSystem.bowelIncrease)
    playerNeeds.lastUpdate = GetGameTimer()
    
    -- Debug
    if Config.Debug then
        print(string.format('[NECESIDADES] Vejiga: %d%%, Intestinos: %d%%', playerNeeds.bladder, playerNeeds.bowel))
    end
end

function CheckNeedsEffects()
    -- Verificar efectos de vejiga
    for threshold, effect in pairs(Config.NeedsSystem.effects.bladder) do
        if playerNeeds.bladder >= threshold then
            ESX.ShowNotification(effect.message)
            -- Aquí podrías agregar efectos de estrés al ESX status
            break
        end
    end
    
    -- Verificar efectos de intestinos
    for threshold, effect in pairs(Config.NeedsSystem.effects.bowel) do
        if playerNeeds.bowel >= threshold then
            ESX.ShowNotification(effect.message)
            break
        end
    end
end

function ResetNeeds(needType)
    if needType == 'bladder' or needType == 'both' then
        playerNeeds.bladder = 0
    end
    if needType == 'bowel' or needType == 'both' then
        playerNeeds.bowel = 0
    end
end

-- [[ SISTEMA DE DETECCIÓN OPTIMIZADO ]] ----------------------------
Citizen.CreateThread(function()
    while true do
        local waitTime = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        local closestZone = nil
        local closestDist = Config.DrawDistance + 1.0

        -- Buscar zona más cercana
        for i = 1, #Config.Locations do
            local zone = Config.Locations[i]
            local dist = #(playerCoords - zone.coords)
            
            if dist < closestDist then
                closestDist = dist
                closestZone = zone
            end
        end

        -- Mostrar interfaz si está cerca y no hay acción en progreso
        if closestZone and closestDist <= Config.DrawDistance and not isActionInProgress then
            waitTime = 5
            local actionConfig = Config.Actions[closestZone.type]
            
            -- Dibujar texto 3D mejorado
            DrawText3DImproved(closestZone.coords, actionConfig.text)
            
            if not isNearObject then
                isNearObject = true
                currentZone = closestZone
            end

            -- Manejar interacción
            if IsControlJustReleased(0, Config.InteractKey) and not IsPedInAnyVehicle(playerPed, false) then
                if not IsActionOnCooldown(currentZone.type) then
                    OpenInteractionMenu(currentZone)
                else
                    local remaining = GetCooldownRemaining(currentZone.type)
                    ESX.ShowNotification('⏰ Espera ' .. remaining .. ' segundos')
                end
            end
        else
            if isNearObject then
                isNearObject = false
                currentZone = nil
            end
        end

        Citizen.Wait(waitTime)
    end
end)

-- [[ TEXTO 3D MEJORADO ]] ------------------------------------------
function DrawText3DImproved(coords, text)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
    
    if onScreen then
        local dist = GetDistanceBetweenCoords(GetGameplayCamCoords(), coords.x, coords.y, coords.z, true)
        local scale = (1 / dist) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov
        
        SetTextScale(0.0, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(screenX, screenY)
        
        -- Dibujar instrucción de tecla
        local keyText = "Presiona ~b~[E]~w~ para interactuar"
        SetTextScale(0.0, 0.25 * scale)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(keyText)
        DrawText(screenX, screenY + 0.02)
    end
end

-- [[ MENÚ DE INTERACCIÓN MEJORADO ]] --------------------------------
function OpenInteractionMenu(zoneData)
    local elements = {}
    local actionConfig = Config.Actions[zoneData.type]
    
    -- Información de necesidades actuales
    if Config.NeedsSystem.enabled then
        table.insert(elements, {
            label = '💧 Vejiga: ' .. playerNeeds.bladder .. '% | 💩 Intestinos: ' .. playerNeeds.bowel .. '%',
            value = 'info',
            disabled = true
        })
        table.insert(elements, {label = '─', value = 'separator', disabled = true})
    end

    -- Acción principal
    table.insert(elements, {
        label = actionConfig.text,
        value = zoneData.type,
        desc = GetActionDescription(zoneData.type)
    })

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'bathroom_interaction_menu',
        {
            title    = '🚽 Sistema de Higiene',
            align    = 'right',
            elements = elements,
        },
        function(data, menu)
            if data.current.value ~= 'info' and data.current.value ~= 'separator' then
                menu.close()
                StartActionSequence(data.current.value, zoneData)
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end

function GetActionDescription(actionType)
    local effects = Config.Effects[actionType]
    local desc = ""
    
    if effects.cleanliness_gain > 0 then
        desc = desc .. "🛁 +" .. effects.cleanliness_gain .. "% Limpieza\n"
    end
    if effects.bladder_relief then
        desc = desc .. "💧 Alivio de vejiga\n"
    end
    if effects.bowel_relief then
        desc = desc .. "💩 Alivio intestinal\n"
    end
    if effects.stress_relief > 0 then
        desc = desc .. "😌 -" .. effects.stress_relief .. "% Estrés\n"
    end
    
    return desc
end

-- [[ SECUENCIA DE ACCIÓN MEJORADA ]] --------------------------------
function StartActionSequence(actionType, zoneData)
    local actionConfig = Config.Actions[actionType]
    local playerPed = PlayerPedId()
    
    isActionInProgress = true

    -- Congelar y posicionar jugador
    SetEntityCoords(playerPed, zoneData.coords.x, zoneData.coords.y, zoneData.coords.z)
    SetEntityHeading(playerPed, zoneData.heading)
    FreezeEntityPosition(playerPed, true)
    
    -- Notificación de inicio
    ESX.ShowNotification('🔄 ' .. actionConfig.text .. '...')

    -- Sonido de inicio
    if actionConfig.sound and actionConfig.sound.startName then
        PlaySoundFrontend(-1, actionConfig.sound.startName, actionConfig.sound.startSet, true)
    end
    
    -- Efectos de partículas
    if actionConfig.ptfx then
        StartParticleEffect(actionConfig.ptfx, zoneData.coords)
    end

    -- Animación o escenario
    if actionConfig.scenario then
        TaskStartScenarioInPlace(playerPed, actionConfig.scenario, 0, true)
    elseif actionConfig.animDict and actionConfig.animName then
        ESX.Streaming.RequestAnimDict(actionConfig.animDict, function()
            TaskPlayAnim(playerPed, actionConfig.animDict, actionConfig.animName, 8.0, -8.0, actionConfig.duration, 1, 0, false, false, false)
        end)
    end
    
    -- Barra de progreso visual
    ShowProgressBar(actionConfig.text, actionConfig.duration)

    -- Esperar duración de la acción
    Citizen.Wait(actionConfig.duration)

    -- Limpieza final
    CleanupAction(actionConfig)
    
    -- Enviar al servidor
    TriggerServerEvent('esx_bathroom:finishAction', actionType)
    
    isActionInProgress = false
    
    -- Resetear necesidades locales
    if actionType == 'toilet' then
        ResetNeeds('both')
    elseif actionType == 'urinal' then
        ResetNeeds('bladder')
    end
end

-- [[ EFECTOS DE PARTÍCULAS MEJORADOS ]] ----------------------------
function StartParticleEffect(ptfxConfig, coords)
    ESX.Streaming.RequestPtfxAsset(ptfxConfig.dict, function()
        UseParticleFxAssetNextCall(ptfxConfig.dict)
        
        ptfxHandle = StartParticleFxLoopedAtCoord(
            ptfxConfig.name,
            coords.x + ptfxConfig.offset.x,
            coords.y + ptfxConfig.offset.y, 
            coords.z + ptfxConfig.offset.z,
            0.0, 0.0, 0.0,
            ptfxConfig.scale or 1.0,
            false, false, false, false
        )
        
        SetParticleFxLoopedColour(ptfxHandle, 1.0, 1.0, 1.0, 0)
    end)
end

-- [[ BARRA DE PROGRESO VISUAL ]] -----------------------------------
function ShowProgressBar(text, duration)
    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + duration
        
        while GetGameTimer() < endTime do
            local currentTime = GetGameTimer()
            local progress = (currentTime - startTime) / duration
            local percent = math.floor(progress * 100)
            
            ESX.UI.Menu.CloseAll()
            
            -- Dibujar texto de progreso
            SetTextComponentFormat('STRING')
            AddTextComponentString('🔄 ' .. text .. ' (' .. percent .. '%)')
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            
            Citizen.Wait(0)
        end
    end)
end

-- [[ LIMPIEZA DE ACCIÓN ]] -----------------------------------------
function CleanupAction(actionConfig)
    local playerPed = PlayerPedId()
    
    -- Detener partículas
    if ptfxHandle ~= 0 then
        StopParticleFxLooped(ptfxHandle, false)
        ptfxHandle = 0
    end
    
    -- Sonido de finalización
    if actionConfig.sound and actionConfig.sound.stopName then
        PlaySoundFrontend(-1, actionConfig.sound.stopName, actionConfig.sound.stopSet, true)
    end
    
    -- Limpiar animaciones
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)
    
    -- Limpiar UI
    ESX.UI.Menu.CloseAll()
end

-- [[ SISTEMA DE COOLDOWNS MEJORADO ]] ------------------------------
function IsActionOnCooldown(actionType)
    local endTimestamp = ActionTimestamps[actionType]
    if endTimestamp then
        return GetGameTimer() < endTimestamp
    end
    return false
end

function GetCooldownRemaining(actionType)
    local endTimestamp = ActionTimestamps[actionType]
    if endTimestamp then
        local remaining = math.ceil((endTimestamp - GetGameTimer()) / 1000)
        return remaining
    end
    return 0
end

RegisterNetEvent('esx_bathroom:setCooldownClient')
AddEventHandler('esx_bathroom:setCooldownClient', function(actionType, cooldownEndTimestamp)
    ActionTimestamps[actionType] = cooldownEndTimestamp
end)

-- [[ COMANDOS DE DEBUG ]] ------------------------------------------
if Config.Debug then
    RegisterCommand('bathroom_debug', function()
        print('=== BATHROOM DEBUG ===')
        print('Necesidades - Vejiga: ' .. playerNeeds.bladder .. '%, Intestinos: ' .. playerNeeds.bowel .. '%')
        print('Cercano a objeto: ' .. tostring(isNearObject))
        print('Acción en progreso: ' .. tostring(isActionInProgress))
        print('Cooldowns activos: ' .. json.encode(ActionTimestamps))
        print('======================')
    end, false)
end

-- [[ EVENTOS DE LIMPIEZA ]] ----------------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Limpiar partículas
        if ptfxHandle ~= 0 then
            StopParticleFxLooped(ptfxHandle, false)
        end
        
        -- Limpiar estado
        ActionTimestamps = {}
        isActionInProgress = false
        
        -- Limpiar animaciones
        ClearPedTasksImmediately(PlayerPedId())
        FreezeEntityPosition(PlayerPedId(), false)
    end
end)

print('[ESX_BATHROOM] Cliente mejorado completamente cargado')