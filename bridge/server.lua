---Framework bridge: hides the differences between ESX Legacy and Qbox.
---Everything framework-specific (player lookup, vehicle table, owner column,
---how the model is stored) lives here so server.lua stays framework-agnostic.

Bridge = {}

local frameworks = {
    esx = {
        resource = "es_extended",
        vehiclesTable = "owned_vehicles",
        ownerColumn = "owner",
        -- ESX stores the vehicle properties as JSON; the model hash sits inside it
        modelColumn = "JSON_VALUE(vehicle, '$.model')",
    },
    qbx = {
        resource = "qbx_core",
        vehiclesTable = "player_vehicles",
        ownerColumn = "citizenid",
        -- Qbox stores the spawn name (e.g. "sultan") directly in the vehicle column
        modelColumn = "vehicle",
    },
}

---@return string|nil
local function detectFramework()
    local wanted = Config.Framework

    if wanted and wanted ~= "auto" then
        if not frameworks[wanted] then
            print(("^1[lb-garageapp]^7 Unknown Config.Framework \"%s\" (use \"auto\", \"esx\" or \"qbx\")"):format(wanted))
            return nil
        end

        return wanted
    end

    -- Check Qbox first: qbx_core also "provides" qb-core, so never test for qb-core here
    if GetResourceState("qbx_core") ~= "missing" then
        return "qbx"
    end

    if GetResourceState("es_extended") ~= "missing" then
        return "esx"
    end

    return nil
end

Bridge.name = detectFramework()

if not Bridge.name then
    print("^1[lb-garageapp]^7 No supported framework found (es_extended or qbx_core). The app will not return any vehicles.")
    return
end

local fw = frameworks[Bridge.name]

Bridge.vehiclesTable = Config.VehiclesTable or fw.vehiclesTable
Bridge.ownerColumn = fw.ownerColumn
Bridge.modelColumn = fw.modelColumn

local ESX

if Bridge.name == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
end

---Returns the identifier the vehicles table uses as owner for this player.
---ESX: xPlayer.identifier / Qbox: citizenid
---@param source number
---@return string|nil
function Bridge.GetIdentifier(source)
    if Bridge.name == "esx" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    end

    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

local qbxVehicles

---Returns a display name for the model from the framework's shared vehicle list,
---or nil so the client falls back to the GTA label. Only Qbox has such a list.
---@param model any
---@return string|nil
function Bridge.GetVehicleLabel(model)
    if Bridge.name ~= "qbx" or type(model) ~= "string" then
        return nil
    end

    if qbxVehicles == nil then
        local ok, result = pcall(function()
            return exports.qbx_core:GetVehiclesByName()
        end)

        qbxVehicles = ok and type(result) == "table" and result or false
    end

    local data = qbxVehicles and qbxVehicles[model]

    return data and data.name or nil
end

print(("^2[lb-garageapp]^7 Using framework: %s (table `%s`)"):format(Bridge.name, Bridge.vehiclesTable))
