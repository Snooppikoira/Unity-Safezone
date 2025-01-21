if not lib then print("^1[ERROR] Overextended (ox_lib) is not loaded! Make sure it is installed and referenced in fxmanifest.lua.^0") return end

local Config = require('config')
local inSafeZone = {}

---@param entity1 number
---@param entity2 number
local function DisableCollisionsThisFrame(entity1, entity2)
    SetEntityNoCollisionEntity(entity1, entity2, true)
    SetEntityNoCollisionEntity(entity2, entity1, true)
end

---@param entity number
---@param zoneCoords vector3
---@param zoneRadius number
---@return boolean
local function IsEntityInZone(entity, zoneCoords, zoneRadius)
    local entityCoords = GetEntityCoords(entity)
    local distance = #(zoneCoords - entityCoords)
    return distance < zoneRadius
end

for zoneName, zoneData in pairs(Config.Zones) do
    lib.zones.sphere({
        name   = zoneName,
        coords = zoneData.coords,
        radius = zoneData.radius,
        debug  = false,

        inside = function(self)
            local playerPed = cache.ped

            DrawMarker(
                Config.Settings.markerType,
                self.coords.x,
                self.coords.y,
                self.coords.z - 10.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                self.radius * 2,
                self.radius * 2,
                Config.Settings.markerHeight,
                Config.Settings.markerColor[1],
                Config.Settings.markerColor[2],
                Config.Settings.markerColor[3],
                Config.Settings.markerColor[4],
                false, false, 2, false, nil, nil, false
            )

            local vehiclePool = GetGamePool('CVehicle')
            for i = 1, #vehiclePool do
                local vehicle = vehiclePool[i]
                if IsEntityInZone(vehicle, self.coords, self.radius) then
                    DisableCollisionsThisFrame(playerPed, vehicle)
                    SetEntityAlpha(vehicle, 200, false)
                end
            end

            local playerPool = GetGamePool('CPed')
            for i = 1, #playerPool do
                local ped = playerPool[i]
                if ped ~= playerPed and IsEntityInZone(ped, self.coords, self.radius) then
                    DisableCollisionsThisFrame(playerPed, ped)
                    SetEntityAlpha(ped, 200, false)
                end
            end
        end,

        onEnter = function(self)
            local playerPed = cache.ped
            local zone = self.name

            inSafeZone[zone] = true
            PlaySoundFrontend(-1, "FLIGHT_SCHOOL_LESSON_PASSED", "HUD_AWARDS", true)

            SendNUIMessage({
                type = 'nui',
                localization = Config.Localization.protected_text,
                show = true
            })

            SetPlayerInvincible(PlayerId(), true)
            DisablePlayerFiring(playerPed, true)
        end,

        onExit = function(self)
            local playerPed = cache.ped
            local zone = self.name

            inSafeZone[zone] = false
            PlaySoundFrontend(-1, "COLLECTED", "HUD_AWARDS", true)

            local vehiclePool = GetGamePool('CVehicle')
            for i = 1, #vehiclePool do
                SetEntityAlpha(vehiclePool[i], 255, false)
            end

            local playerPool = GetGamePool('CPed')
            for i = 1, #playerPool do
                SetEntityAlpha(playerPool[i], 255, false)
            end

            SetPlayerInvincible(PlayerId(), false)
            DisablePlayerFiring(playerPed, false)

            SendNUIMessage({
                type = 'nui',
                localization = Config.Localization.protected_text,
                show = false
            })
        end,
    })
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end

    local playerPed = PlayerPedId()
    SetPlayerInvincible(PlayerId(), false)

    local vehiclePool = GetGamePool('CVehicle')
    for i = 1, #vehiclePool do
        local vehicle = vehiclePool[i]
        SetEntityNoCollisionEntity(playerPed, vehicle, false)
        SetEntityNoCollisionEntity(vehicle, playerPed, false)
        SetEntityAlpha(vehicle, 255, false)
    end

    local playerPool = GetGamePool('CPed')
    for i = 1, #playerPool do
        local ped = playerPool[i]
        SetEntityNoCollisionEntity(playerPed, ped, false)
        SetEntityNoCollisionEntity(ped, playerPed, false)
        SetEntityAlpha(ped, 255, false)
    end

    SendNUIMessage({
        type = 'nui',
        localization = Config.Localization.protected_text,
        show = false
    })
end)
