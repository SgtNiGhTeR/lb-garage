local locations = { garages = {}, impounds = {} }

-- columns the app reads from the vehicles table (the JG Advanced Garages ones are added by that resource)
local jgColumns = {
    "plate", "in_garage", "garage_id", "impound", "impound_retrievable", "impound_data",
    "job_vehicle", "gang_vehicle", "nickname", "fuel", "engine", "body",
}

---Prints every column the app needs but the vehicles table does not have.
local function checkColumns()
    local rows = MySQL.query.await(
        "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?",
        { Bridge.vehiclesTable }
    ) or {}

    if #rows == 0 then
        print(("^1[lb-garageapp]^7 Table %s was not found in the database"):format(Bridge.vehiclesTable))

        return
    end

    local existing = {}

    for _, row in ipairs(rows) do
        existing[row.COLUMN_NAME:lower()] = true
    end

    local missing = {}

    for _, column in ipairs(Bridge.requiredColumns) do
        if not existing[column] then
            missing[#missing + 1] = column
        end
    end

    for _, column in ipairs(jgColumns) do
        if not existing[column] then
            missing[#missing + 1] = column
        end
    end

    if #missing > 0 then
        print(("^1[lb-garageapp]^7 Table %s is missing columns: %s"):format(Bridge.vehiclesTable, table.concat(missing, ", ")))
    end
end

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `lb_garageapp_favorites` (
            `identifier` VARCHAR(80) NOT NULL,
            `plate` VARCHAR(12) NOT NULL,
            PRIMARY KEY (`identifier`, `plate`)
        )
    ]])

    if Bridge.framework then
        checkColumns()
    end
end)

---Reads the garage and impound locations from the config of the garage resource.
---The config is plain Lua, so it is evaluated in a sandbox to get the coordinates.
local function loadLocations()
    local source = LoadResourceFile(Config.GarageResource, "config/config.lua")

    if not source then
        print(("^1[lb-garageapp]^7 Could not read config/config.lua of %s"):format(Config.GarageResource))
        return
    end

    local env = setmetatable({}, { __index = _G })
    local chunk, loadError = load(source, "@garage-config", "t", env)

    if not chunk then
        print("^1[lb-garageapp]^7 Could not parse the garage config: " .. tostring(loadError))
        return
    end

    local ok, runError = pcall(chunk)

    if not ok or type(env.Config) ~= "table" then
        print("^1[lb-garageapp]^7 Could not evaluate the garage config: " .. tostring(runError))
        return
    end

    local function collect(target, list)
        for name, data in pairs(list or {}) do
            local coords = data.coords

            if coords then
                target[name] = { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
            end
        end
    end

    collect(locations.garages, env.Config.GarageLocations)
    collect(locations.impounds, env.Config.ImpoundLocations)
end

CreateThread(function()
    Wait(1000)
    loadLocations()
end)

---@param value any
---@return table
local function decodeJson(value)
    if type(value) ~= "string" or value == "" then
        return {}
    end

    local ok, result = pcall(json.decode, value)

    return ok and type(result) == "table" and result or {}
end

---@param value any
---@param divisor number
---@return number
local function percent(value, divisor)
    local number = tonumber(value) or 0

    return math.max(0, math.min(100, math.floor(number / divisor + 0.5)))
end

lib.callback.register("lb-garageapp:getVehicles", function(source)
    local identifier = Bridge.framework and Bridge.GetIdentifier(source)

    if not identifier then
        return {}
    end

    local rows = MySQL.query.await(([[
        SELECT plate, %s AS model, in_garage, garage_id, impound, impound_retrievable, impound_data, nickname, fuel, engine, body
        FROM `%s`
        WHERE `%s` = ? AND job_vehicle = 0 AND gang_vehicle = 0
    ]]):format(Bridge.modelColumn, Bridge.vehiclesTable, Bridge.ownerColumn), { identifier }) or {}

    local favorites = {}

    for _, row in ipairs(MySQL.query.await("SELECT plate FROM lb_garageapp_favorites WHERE identifier = ?", { identifier }) or {}) do
        favorites[row.plate] = true
    end

    local privateGarages = {}

    for _, garage in ipairs(MySQL.query.await("SELECT name, x, y, z FROM player_priv_garages WHERE owners LIKE ?", { "%" .. identifier .. "%" }) or {}) do
        privateGarages[garage.name] = { x = garage.x + 0.0, y = garage.y + 0.0, z = garage.z + 0.0 }
    end

    local vehicles = {}

    for _, row in ipairs(rows) do
        local status = "outside"

        if tonumber(row.impound) == 1 then
            status = "impound"
        elseif tonumber(row.in_garage) == 1 then
            status = "garage"
        end

        local location

        if status == "impound" then
            location = locations.impounds[row.garage_id] or locations.garages[row.garage_id]
        else
            location = locations.garages[row.garage_id] or privateGarages[row.garage_id]
        end

        local impound

        if status == "impound" then
            local data = decodeJson(row.impound_data)
            local availableAt = tonumber(data.availableAt or data.available_at or data.releaseTime or data.expires)

            if availableAt and availableAt > 1e12 then
                availableAt = availableAt / 1000
            end

            impound = {
                reason = data.reason,
                by = data.impoundedBy or data.impounded_by or data.by or data.officer or data.impounder,
                cost = tonumber(data.cost or data.price or data.fee),
                availableAt = availableAt and availableAt > 1e9 and math.floor(availableAt) or nil,
                retrievable = tonumber(row.impound_retrievable) == 1,
            }
        end

        vehicles[#vehicles + 1] = {
            plate = row.plate,
            model = tonumber(row.model) or row.model,
            label = Bridge.GetVehicleLabel(row.model),
            nickname = row.nickname ~= "" and row.nickname or nil,
            status = status,
            garage = row.garage_id,
            location = location,
            fuel = percent(row.fuel, 1),
            engine = percent(row.engine, 10),
            body = percent(row.body, 10),
            favorite = favorites[row.plate] == true,
            impound = impound,
        }
    end

    return vehicles
end)

lib.callback.register("lb-garageapp:toggleFavorite", function(source, plate)
    local identifier = Bridge.framework and Bridge.GetIdentifier(source)

    if not identifier or type(plate) ~= "string" or #plate == 0 or #plate > 12 then
        return nil
    end

    -- only the owner may favorite a vehicle
    local owned = MySQL.scalar.await(("SELECT 1 FROM `%s` WHERE `%s` = ? AND plate = ? LIMIT 1"):format(Bridge.vehiclesTable, Bridge.ownerColumn), { identifier, plate })

    if not owned then
        return nil
    end

    local isFavorite = MySQL.scalar.await("SELECT 1 FROM lb_garageapp_favorites WHERE identifier = ? AND plate = ?", { identifier, plate })

    if isFavorite then
        MySQL.query.await("DELETE FROM lb_garageapp_favorites WHERE identifier = ? AND plate = ?", { identifier, plate })

        return false
    end

    MySQL.insert.await("INSERT INTO lb_garageapp_favorites (identifier, plate) VALUES (?, ?)", { identifier, plate })

    return true
end)
