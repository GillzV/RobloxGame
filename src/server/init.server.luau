local CityGenerator = require(script.Parent.CityGenerator)
local BuildingCollapse = require(script.Parent.BuildingCollapse)
local PlayerData = require(script.Parent.PlayerData)

-- Generate the city when the game starts
CityGenerator.generateCity()

-- Initialize building collapse system
BuildingCollapse.registerAllBuildings()

-- Initialize player data system
print("Player data system initialized!")
