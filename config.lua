Config = {}

Config.DensityMultipliers = { -- You can change these values to increase or decrease the density of each type of entity
    enabled = false,           
    parkedVehicles = 0.3,    -- 0.0 to 1.0 (0 = none, 1 = maximum)
    vehicles = 0.3,          -- Moving vehicle density
    peds = 0.3,              -- Pedestrian density
    scenarios = 0.3,         -- Scenario density (NPCs on benches, etc)
    animals = 0.3            -- Animal density
}

Config.ClearZones = {
    enabled = false,    -- Master switch for the entire ClearZones system
    zones = {           -- Move zones within a subtable
        {
            coords = vector3(-1037.75, -2738.35, 13.85),
            radius = 100.0,
            clearNPCs = false,    
            clearAnimals = true   
        }
    }
}

Config.TowTruck = { -- System for the deletion of driverless vehicles from time to time 
    enabled = false,                -- Enable/disable tow truck system
    interval = 30,                  -- Minutes between each cleanup
    notifications = {
        enabled = true,             -- Enable/disable notifications
        type = 'chat',              -- Notification type: 'chat', 'esx', 'custom'
        times = {10, 5, 3, 1},      -- Minutes before to notify (in descending order)
        messages = {
            announce = "⚠️ The municipal tow truck will pass in %d minutes",
            cleaning = "🚛 The tow truck is removing abandoned vehicles",
            removed = "✅ %d abandoned vehicles have been removed"
        }
    },
    excludeVehicles = {             -- Vehicles that will not be removed
        'police',
        'ambulance',
        'taxi'
    }
}

Config.DisableArmedPeds = true -- Disable armed NPCs like gang members
Config.DisableNPCAmbulance = true -- Disable NPC ambulances to avoid that NPCs EMS go to deads NPCs
Config.DisableBlindFire = true    -- Disable blind fire
Config.DisablePistolWhip = true   -- Disable pistol whip
Config.DisableReticle = true -- Disable the aiming reticle (crosshair)

Config.Aiming = {
    ForceFirstPerson = true, -- Force first-person view when aiming outside of vehicles
    ForceFirstPersonInVehicle = true, -- Force first-person view when aiming in a vehicle
    ForceFirstPersonOnBike = true -- Force first-person view when aiming on a bike
}

Config.HideHUD = { -- Configuration for hiding native FiveM HUD components
    enabled = false, -- Enable/disable hiding HUD components
    components = {1, 2, 3, 4, 7, 9, 13} -- List of HUD component IDs to hide. Check: https://docs.fivem.net/natives/?_0x6806C51AD12B83B8
}

Config.VoiceRestart = {
    enabled = true, -- Enable/disable the voice restart feature
    command = 'restartvoice', -- Command to restart voice system
    notification = {
        title = 'Voice',
        message = 'The voice system has been restarted',
        icon = 'CHAR_DEFAULT',
        iconType = 1,
        duration = 5000
    }
}