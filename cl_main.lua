local ESX = nil
local QBCore = nil

if GetResourceState('es_extended') == 'started' then
    ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Optimized native function caching for better performance
local PlayerPedId = PlayerPedId
local Wait = Wait
local DisableControlAction = DisableControlAction
local GetEntityCoords = GetEntityCoords
local GetEntityModel = GetEntityModel
local DoesEntityExist = DoesEntityExist
local IsPedAPlayer = IsPedAPlayer
local DeleteEntity = DeleteEntity
local RemoveAllPedWeapons = RemoveAllPedWeapons
local SetPedCanSwitchWeapon = SetPedCanSwitchWeapon
local GetGamePool = GetGamePool
local CancelCurrentPoliceReport = CancelCurrentPoliceReport
local IsPedInCover = IsPedInCover
local IsPedAimingFromCover = IsPedAimingFromCover
local IsPedArmed = IsPedArmed
local IsControlPressed = IsControlPressed
local ClearPedTasksImmediately = ClearPedTasksImmediately
local SetParkedVehicleDensityMultiplierThisFrame = SetParkedVehicleDensityMultiplierThisFrame
local SetVehicleDensityMultiplierThisFrame = SetVehicleDensityMultiplierThisFrame
local SetPedDensityMultiplierThisFrame = SetPedDensityMultiplierThisFrame
local SetScenarioPedDensityMultiplierThisFrame = SetScenarioPedDensityMultiplierThisFrame

-- Check if SetAnimalDensityMultiplierThisFrame is available
local SetAnimalDensityMultiplierThisFrame = SetAnimalDensityMultiplierThisFrame or function() end

-- Cached local variables for performance optimization
local playerPed = PlayerPedId()
local playerCoords = vector3(0,0,0)

-- Precached animal model hashes for efficient entity type checking
local animalHashes = {
    [`a_c_boar`] = true, [`a_c_cat`] = true, [`a_c_chickenhawk`] = true,
    [`a_c_chimp`] = true, [`a_c_coyote`] = true, [`a_c_deer`] = true,
    [`a_c_fish`] = true, [`a_c_hen`] = true, [`a_c_mtlion`] = true,
    [`a_c_pig`] = true, [`a_c_pigeon`] = true, [`a_c_rat`] = true,
    [`a_c_seagull`] = true, [`a_c_crow`] = true
}

-- Player position and entity cache update system
-- Updates every second to minimize native calls while maintaining accuracy
CreateThread(function()
    while true do
        Wait(1000)
        playerPed = PlayerPedId()
        playerCoords = GetEntityCoords(playerPed)
    end
end)

-- Population density control system
-- Manages NPC, vehicle and animal spawn rates based on config settings
CreateThread(function()
    while true do
        if Config.DensityMultipliers.enabled then
            SetParkedVehicleDensityMultiplierThisFrame(Config.DensityMultipliers.parkedVehicles)
            SetVehicleDensityMultiplierThisFrame(Config.DensityMultipliers.vehicles)
            SetPedDensityMultiplierThisFrame(Config.DensityMultipliers.peds)
            SetScenarioPedDensityMultiplierThisFrame(Config.DensityMultipliers.scenarios, Config.DensityMultipliers.scenarios)
            SetAnimalDensityMultiplierThisFrame(Config.DensityMultipliers.animals)
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- Zone-based entity management system
-- Handles clearing of NPCs and animals in specified zones based on individual zone settings
CreateThread(function()
    while true do
        if Config.ClearZones.enabled then
            local sleep = 2000
            local isInZone = false

            for _, zone in pairs(Config.ClearZones.zones) do
                local distance = #(playerCoords - zone.coords)
                
                if distance <= zone.radius then
                    isInZone = true
                    local peds = GetGamePool('CPed')
                    
                    for _, ped in ipairs(peds) do
                        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
                            local model = GetEntityModel(ped)
                            if (zone.clearAnimals and animalHashes[model]) or
                               (zone.clearNPCs and not animalHashes[model]) then
                                DeleteEntity(ped)
                            end
                        end
                    end
                    
                    sleep = 1500
                    break
                end
            end

            if not isInZone then
                sleep = 3000
            end

            Wait(sleep)
        else
            Wait(5000)
        end
    end
end)

-- Global NPC weapon management system
-- Removes weapons from NPCs when enabled in config
CreateThread(function()
    while true do
        if Config.DisableArmedPeds then
            local peds = GetGamePool('CPed')
            for _, ped in ipairs(peds) do
                if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not animalHashes[GetEntityModel(ped)] then
                    RemoveAllPedWeapons(ped, true)
                    SetPedCanSwitchWeapon(ped, false)
                end
            end
            Wait(2000)
        else
            Wait(5000)
        end
    end
end)

-- Blind fire prevention system
-- Prevents shooting while in cover without proper aiming
CreateThread(function()
    while true do
        if Config.DisableBlindFire then
            if IsPedInCover(playerPed) and not IsPedAimingFromCover(playerPed) then
                DisableControlAction(0, 24, true)  -- Disable attack
                DisableControlAction(0, 142, true) -- Disable melee attack
                DisableControlAction(0, 257, true) -- Disable attack 2
                Wait(0)
            else
                Wait(250)
            end
        else
            Wait(1000)
        end
    end
end)

-- Pistol whip prevention system
-- Prevents melee attacks with weapons equipped
CreateThread(function()
    while true do
        if Config.DisablePistolWhip then
            if IsPedArmed(playerPed, 6) then
                DisableControlAction(0, 24, true)  -- Disable attack
                DisableControlAction(0, 140, true) -- Disable melee attack 1
                DisableControlAction(0, 141, true) -- Disable melee attack 2
                DisableControlAction(0, 142, true) -- Disable melee attack 3
                
                if IsControlPressed(0, 24) or IsControlPressed(0, 140) or 
                   IsControlPressed(0, 141) or IsControlPressed(0, 142) then
                    ClearPedTasksImmediately(playerPed)
                end
                Wait(0)
            else
                Wait(1000)
            end
        else
            Wait(1000)
        end
    end
end)

-- NPC emergency services prevention system
-- Prevents automatic spawning of NPC emergency services
CreateThread(function()
    while true do
        if Config.DisableNPCAmbulance then
            CancelCurrentPoliceReport()
            Wait(1000)
        else
            Wait(5000)
        end
    end
end)

-- Notification helper function for tow truck system
local function ShowNotification(msg)
    if not Config.TowTruck.notifications.enabled then return end
    
    if Config.TowTruck.notifications.type == 'chat' then
        TriggerEvent('chat:addMessage', { args = { msg } })
    elseif Config.TowTruck.notifications.type == 'esx' and ESX then
        ESX.ShowNotification(msg)
    elseif Config.TowTruck.notifications.type == 'qb' and QBCore then
        QBCore.Functions.Notify(msg, 'inform')
    end
end

-- Vehicle occupation check helper
-- Returns true if any seat is occupied
local function IsVehicleOccupied(vehicle)
    for i = -1, 2 do
        if GetPedInVehicleSeat(vehicle, i) ~= 0 then
            return true
        end
    end
    return false
end

-- Automated tow truck system
-- Manages periodic removal of abandoned vehicles with notifications
CreateThread(function()
    local timer = 0
    local nextCleanup = 0
    local notificationTimes = Config.TowTruck.notifications.times
    local notificationsSent = {}
    
    while true do
        if Config.TowTruck.enabled then
            local currentTime = GetGameTimer()
            
            if nextCleanup == 0 then
                nextCleanup = currentTime + (Config.TowTruck.interval * 60 * 1000)
                notificationsSent = {}
            end
            
            local timeUntilCleanup = (nextCleanup - currentTime) / 1000 / 60
            
            for _, time in ipairs(notificationTimes) do
                if timeUntilCleanup <= time and not notificationsSent[time] then
                    ShowNotification(string.format(Config.TowTruck.notifications.messages.announce, time))
                    notificationsSent[time] = true
                end
            end
            
            if currentTime >= nextCleanup then
                local vehiclesRemoved = 0
                ShowNotification(Config.TowTruck.notifications.messages.cleaning)
                
                local vehicles = GetGamePool('CVehicle')
                for _, vehicle in ipairs(vehicles) do
                    if DoesEntityExist(vehicle) then
                        local model = GetEntityModel(vehicle)
                        local modelName = GetDisplayNameFromVehicleModel(model):lower()
                        
                        local isExcluded = false
                        for _, excludedModel in ipairs(Config.TowTruck.excludeVehicles) do
                            if string.find(modelName, excludedModel:lower()) then
                                isExcluded = true
                                break
                            end
                        end

                        if not isExcluded and not IsVehicleOccupied(vehicle) then
                            DeleteEntity(vehicle)
                            vehiclesRemoved = vehiclesRemoved + 1
                        end
                    end
                end
                
                ShowNotification(string.format(Config.TowTruck.notifications.messages.removed, vehiclesRemoved))
                nextCleanup = currentTime + (Config.TowTruck.interval * 60 * 1000)
                notificationsSent = {}
            end
            
            Wait(1000)
        else
            Wait(5000)
        end
    end
end)

-- HUD hiding system
-- Hides specified HUD components based on config settings
CreateThread(function()
    while true do
        if Config.HideHUD.enabled then
            for _, component in ipairs(Config.HideHUD.components) do
                HideHudComponentThisFrame(component)
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- Reticle disabling system
CreateThread(function()
    while true do
        if Config.DisableReticle then
            HideHudComponentThisFrame(14) -- Hide reticle
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- Force first-person view when aiming
if Config.Aiming.ForceFirstPerson then
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerPed = PlayerPedId()
            local _, weapon = GetCurrentPedWeapon(playerPed)
            local unarmed = `WEAPON_UNARMED`
            if weapon ~= unarmed then
                sleep = 1
                if IsPlayerFreeAiming(PlayerId()) then
                    SetFollowPedCamViewMode(4) -- Set to first-person view
                else
                    SetFollowPedCamViewMode(0) -- Set to third-person view
                end
            end
            Wait(sleep)
        end
    end)
end

-- Force first-person view when aiming in a vehicle
if Config.Aiming.ForceFirstPersonInVehicle then
    CreateThread(function()
        local previousViewMode = nil
        while true do
            local sleep = 1000
            local playerPed = PlayerPedId()
            local _, weapon = GetCurrentPedWeapon(playerPed)
            local unarmed = `WEAPON_UNARMED`
            if IsPedInAnyVehicle(playerPed, false) and weapon ~= unarmed then
                sleep = 1
                if IsControlPressed(0, 25) then -- Right mouse button (aim)
                    if previousViewMode == nil then
                        previousViewMode = GetFollowVehicleCamViewMode()
                    end
                    SetFollowVehicleCamViewMode(4) -- Set to first-person view
                    TaskAimGunScripted(playerPed, GetHashKey("SCRIPTED_GUN_TASK_PLANE_WING"), true, true)
                elseif IsControlJustReleased(0, 25) then
                    if previousViewMode ~= nil then
                        SetFollowVehicleCamViewMode(previousViewMode) -- Restore previous view mode
                        previousViewMode = nil
                        ClearPedTasks(playerPed)
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

-- Force first-person view when aiming on a bike
if Config.Aiming.ForceFirstPersonOnBike then
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerPed = PlayerPedId()
            local _, weapon = GetCurrentPedWeapon(playerPed)
            local unarmed = `WEAPON_UNARMED`
            if IsPedOnAnyBike(playerPed) and weapon ~= unarmed then
                sleep = 1
                if IsControlPressed(0, 25) then -- Right mouse button (aim)
                    SetCamViewModeForContext(2, 4) -- Set to first-person view
                elseif IsControlJustReleased(0, 25) then
                    SetCamViewModeForContext(2, 0) -- Set to third-person view
                end
            end
            Wait(sleep)
        end
    end)
end

-- Voice restart command
if Config.VoiceRestart.enabled then
    RegisterCommand(Config.VoiceRestart.command, function()
        NetworkClearVoiceChannel()
        NetworkSessionVoiceLeave()
        Wait(50)
        NetworkSetVoiceActive(false)
        MumbleClearVoiceTarget(2)
        Wait(1000)
        MumbleSetVoiceTarget(2)
        NetworkSetVoiceActive(true)
        
        -- Notification using ESX or QBCore
        if ESX then
            ESX.ShowAdvancedNotification(Config.VoiceRestart.notification.title, Config.VoiceRestart.notification.message, '', Config.VoiceRestart.notification.icon, Config.VoiceRestart.notification.iconType, Config.VoiceRestart.notification.duration)
        elseif QBCore then
            QBCore.Functions.Notify(Config.VoiceRestart.notification.message, 'success')
        end
    end, false)
end