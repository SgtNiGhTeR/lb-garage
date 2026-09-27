Config = {}

-- Unique identifier of the app inside LB Phone (not shown to players)
Config.Identifier = "garageapp"

-- Language of the app: "auto" (follows the phone language, falls back to "de"), "de" or "en"
Config.Locale = "de"

-- Shown in the app store and on the home screen: "Garage" or "Fuhrpark"
Config.AppName = "Garage"
Config.Description = "Sieh, wo deine Fahrzeuge stehen, markiere Favoriten und prüfe den Abschlepphof."
Config.DescriptionEn = "See where your vehicles are parked, mark favorites and check the impound lot."
Config.Developer = "SgtNiGhTeR"

-- Framework: "auto" (detects qbx_core or es_extended), "esx" or "qbx"
Config.Framework = "auto"

-- Resource that provides the garages (its config is read to get garage and impound locations)
Config.GarageResource = "jg-advancedgarages"

-- Database table with the player vehicles.
-- nil = framework default ("owned_vehicles" for ESX, "player_vehicles" for Qbox)
Config.VehiclesTable = nil
