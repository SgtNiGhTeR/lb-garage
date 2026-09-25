Config = {}

-- Unique identifier of the app inside LB Phone (not shown to players)
Config.Identifier = "garageapp"

-- Language of the app: "auto" (follows the phone language, falls back to "de"), "de" or "en"
Config.Locale = "de"

-- Shown in the app store and on the home screen: "Garage" or "Fuhrpark"
Config.AppName = "Garage"
Config.Description = "Sieh, wo deine Fahrzeuge stehen, markiere Favoriten und prüfe den Abschlepphof."
Config.DescriptionEn = "See where your vehicles are parked, mark favorites and check the impound lot."
Config.Developer = "Hannover RP"

-- Resource that provides the garages (its config is read to get garage and impound locations)
Config.GarageResource = "jg-advancedgarages"

-- Database table with the player vehicles (ESX Legacy default)
Config.VehiclesTable = "owned_vehicles"
