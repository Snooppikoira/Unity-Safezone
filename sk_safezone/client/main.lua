if not lib then print("^1[ERROR] Overextended (ox_lib) is not loaded! Make sure it is installed and referenced in fxmanifest.lua.^0") return end

local Config = require('config')

---@param entity number The entity handle (e.g., a vehicle or a ped)
---@param center vector3 The center coordinates of the safe zone
---@param radius number The radius of the safe zone
local function IsEntityInZone(entity, center, radius)
    local coords = GetEntityCoords(entity)
    return #(coords - center) <= radius
end

---@param ent1 number Entity 1
---@param ent2 number Entity 2
local function DisableCollisionsThisFrame(ent1, ent2)
    if DoesEntityExist(ent1) and DoesEntityExist(ent2) then
        SetEntityNoCollisionEntity(ent1, ent2, true)
        SetEntityNoCollisionEntity(ent2, ent1, true)
    end
end

---@param entity number The entity to modify
---@param alpha number The alpha value (0-255)
local function SetEntityAlphaSafely(entity, alpha)
    if DoesEntityExist(entity) then
        SetEntityAlpha(entity, alpha, false)
    end
end

local inSafeZone = {}

CreateThread(function()
    for zoneName, zoneData in pairs(Config.Zones) do
        inSafeZone[zoneName] = false
    end

    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)

        for zoneName, zoneData in pairs(Config.Zones) do
            local distance = #(playerPos - zoneData.coords)
            local isInside = distance <= zoneData.radius

            if isInside and not inSafeZone[zoneName] then
                inSafeZone[zoneName] = true
                PlaySoundFrontend(-1, "FLIGHT_SCHOOL_LESSON_PASSED", "HUD_AWARDS", true)
                SendNUIMessage({
                    type = "nui",
                    localization = Config.MiniUi.protected_text,
                    positioning = Config.MiniUi.dpositioning,
                    show = true
                })
            elseif isInside and inSafeZone[zoneName] then
                sleep = 0

                DrawMarker(
                    Config.Settings.markerType,
                    zoneData.coords.x, zoneData.coords.y, zoneData.coords.z - 10.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    zoneData.radius * 2, zoneData.radius * 2, Config.Settings.markerHeight,
                    Config.Settings.markerColor[1], Config.Settings.markerColor[2], Config.Settings.markerColor[3], Config.Settings.markerColor[4],
                    false, false, 2, false, nil, nil, false
                )

                DisablePlayerFiring(playerPed, true)
                SetEntityInvincible(playerPed, true)

                local vehiclePool = GetGamePool('CVehicle')
                local pedPool = GetGamePool('CPed')

                for _, ped in ipairs(pedPool) do
                    if ped ~= playerPed and IsEntityInZone(ped, zoneData.coords, zoneData.radius) then
                        DisableCollisionsThisFrame(playerPed, ped)
                        SetEntityAlphaSafely(ped, 200)
                    end
                end

                for _, vehicle in ipairs(vehiclePool) do
                    if IsEntityInZone(vehicle, zoneData.coords, zoneData.radius) then
                        DisableCollisionsThisFrame(playerPed, vehicle)
                        SetEntityAlphaSafely(vehicle, 200)
                    end
                end

                for i, vehicle1 in ipairs(vehiclePool) do
                    if IsEntityInZone(vehicle1, zoneData.coords, zoneData.radius) then
                        for j, vehicle2 in ipairs(vehiclePool) do
                            if i ~= j and IsEntityInZone(vehicle2, zoneData.coords, zoneData.radius) then
                                DisableCollisionsThisFrame(vehicle1, vehicle2)
                                SetEntityAlphaSafely(vehicle2, 200)
                            end
                        end
                    end
                end
            elseif not isInside and inSafeZone[zoneName] then
                inSafeZone[zoneName] = false
                PlaySoundFrontend(-1, "COLLECTED", "HUD_AWARDS", true)

                DisablePlayerFiring(playerPed, false)
                SetEntityInvincible(playerPed, false)

                local vehiclePool = GetGamePool('CVehicle')
                for _, vehicle in ipairs(vehiclePool) do
                    SetEntityAlphaSafely(vehicle, 255)
                end

                local pedPool = GetGamePool('CPed')
                for _, ped in ipairs(pedPool) do
                    SetEntityAlphaSafely(ped, 255)
                end

                SendNUIMessage({
                    type = "nui",
                    localization = Config.MiniUi.protected_text,
                    positioning = Config.MiniUi.dpositioning,
                    show = false
                })
            end
        end

        Wait(sleep)
    end
end)
