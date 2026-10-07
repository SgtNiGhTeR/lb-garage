-- Framework bridge: hides the differences between ESX Legacy and Qbox (qbx_core)

Bridge = {}

local settings = {
    esx = {
        vehiclesTable = "owned_vehicles",
        ownerColumn = "owner",
        modelColumn = "JSON_VALUE(vehicle, '$.model')",
        requiredColumns = { "owner", "vehicle" },
    },
    qbx = {
        vehiclesTable = "player_vehicles",
        ownerColumn = "citizenid",
        modelColumn = "vehicle",
        requiredColumns = { "citizenid", "vehicle" },
    },
}

---@param name string
---@return boolean
local function isResourcePresent(name)
    local state = GetResourceState(name)

    return state ~= "missing" and state ~= "unknown"
end

---qbx_core is checked first: the qb-core compatibility bridge of Qbox makes a check for qb-core unreliable.
---@return string?
local function detectFramework()
    local configured = type(Config.Framework) == "string" and Config.Framework:lower() or "auto"

    if configured == "esx" or configured == "qbx" then
        return configured
    end

    if isResourcePresent("qbx_core") then
        return "qbx"
    end

    if isResourcePresent("es_extended") then
        return "esx"
    end

    return nil
end

Bridge.framework = detectFramework()

if not Bridge.framework then
    print("^1[lb-garageapp]^7 No supported framework found (qbx_core or es_extended). The app will not work.")

    return
end

local framework = settings[Bridge.framework]

Bridge.vehiclesTable = Config.VehiclesTable or framework.vehiclesTable
Bridge.ownerColumn = framework.ownerColumn
Bridge.modelColumn = framework.modelColumn
Bridge.requiredColumns = framework.requiredColumns

print(("^2[lb-garageapp]^7 Using framework: %s (table %s)"):format(Bridge.framework, Bridge.vehiclesTable))

local ESX

if Bridge.framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
end

---@param source number
---@return string?
function Bridge.GetIdentifier(source)
    if Bridge.framework == "qbx" then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(source)
        end)

        return ok and player and player.PlayerData and player.PlayerData.citizenid or nil
    end

    local xPlayer = ESX.GetPlayerFromId(source)

    return xPlayer and xPlayer.identifier or nil
end

local qbxVehicles

---Vehicle name from the shared vehicle list of qbx_core (better names for add-on vehicles).
---Returns nil on ESX so the client keeps its own label lookup.
---@param model number|string|nil
---@return string?
function Bridge.GetVehicleLabel(model)
    if Bridge.framework ~= "qbx" or model == nil then
        return nil
    end

    if not qbxVehicles then
        local ok, result = pcall(function()
            return exports.qbx_core:GetVehiclesByName()
        end)

        if not ok or type(result) ~= "table" then
            return nil
        end

        qbxVehicles = result
    end

    local vehicle = qbxVehicles[tostring(model):lower()]

    return vehicle and vehicle.name or nil
end
