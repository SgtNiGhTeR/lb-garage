local resourceName = GetCurrentResourceName()

local function registerApp()
    while GetResourceState("lb-phone") ~= "started" do
        Wait(500)
    end

    -- lb-phone needs a moment before its exports exist
    Wait(500)

    local success, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = Config.Identifier,
        name = Config.AppName,
        description = Config.Locale == "en" and Config.DescriptionEn or Config.Description,
        developer = Config.Developer,
        defaultApp = false,
        size = 512,
        ui = resourceName .. "/ui/index.html",
        icon = ("https://cfx-nui-%s/ui/icon.png"):format(resourceName),
        fixBlur = true,
    })

    if not success then
        print(("^1[lb-garageapp]^7 Could not add the app: %s"):format(tostring(errorMessage)))
    end
end

CreateThread(registerApp)

AddEventHandler("onClientResourceStart", function(name)
    if name == "lb-phone" then
        CreateThread(registerApp)
    end
end)

AddEventHandler("onResourceStop", function(name)
    if name == resourceName and GetResourceState("lb-phone") == "started" then
        exports["lb-phone"]:RemoveCustomApp(Config.Identifier)
    end
end)

---@param model number|string|nil
---@param plate string
---@return string
local function getVehicleLabel(model, plate)
    local hash = tonumber(model) or (type(model) == "string" and joaat(model)) or 0
    local displayName = GetDisplayNameFromVehicleModel(hash)

    if not displayName or displayName == "" or displayName == "CARNOTFOUND" then
        return plate
    end

    local label = GetLabelText(displayName)

    if not label or label == "NULL" or label == "" then
        return displayName
    end

    return label
end

RegisterNUICallback("getConfig", function(_, cb)
    cb({ locale = Config.Locale })
end)

RegisterNUICallback("getVehicles", function(_, cb)
    local vehicles = lib.callback.await("lb-garageapp:getVehicles", false) or {}

    for i = 1, #vehicles do
        -- Qbox sends a label from its shared vehicle list; otherwise use the GTA label
        vehicles[i].label = vehicles[i].label or getVehicleLabel(vehicles[i].model, vehicles[i].plate)
    end

    cb(vehicles)
end)

RegisterNUICallback("toggleFavorite", function(data, cb)
    cb(lib.callback.await("lb-garageapp:toggleFavorite", false, data and data.plate))
end)

RegisterNUICallback("setWaypoint", function(data, cb)
    if data and tonumber(data.x) and tonumber(data.y) then
        SetNewWaypoint(tonumber(data.x) + 0.0, tonumber(data.y) + 0.0)
        cb(true)
    else
        cb(false)
    end
end)
