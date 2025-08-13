local CityGenerator = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants
local CITY_SIZE = 1000 -- Size of the city in studs
local BLOCK_SIZE = 100 -- Size of each city block
local MIN_BUILDING_HEIGHT = 50
local MAX_BUILDING_HEIGHT = 300
local STREET_WIDTH = 20

-- Materials and colors
local BUILDING_MATERIALS = {
	Enum.Material.Concrete,
	Enum.Material.Glass,
	Enum.Material.Metal,
	Enum.Material.Slate,
}

local BUILDING_COLORS = {
	Color3.fromRGB(200, 200, 200), -- Light gray
	Color3.fromRGB(150, 150, 150), -- Medium gray
	Color3.fromRGB(100, 100, 100), -- Dark gray
	Color3.fromRGB(180, 180, 220), -- Blue-tinted
	Color3.fromRGB(220, 220, 180), -- Warm-tinted
}

-- Function to create a building
local function createBuilding(position, size)
	local building = Instance.new("Model")
	building.Name = "Building"

	-- Main structure
	local mainStructure = Instance.new("Part")
	mainStructure.Name = "MainStructure"
	mainStructure.Size = size
	mainStructure.Position = position + Vector3.new(0, size.Y / 2, 0)
	mainStructure.Anchored = true
	mainStructure.Material = BUILDING_MATERIALS[math.random(1, #BUILDING_MATERIALS)]
	mainStructure.Color = BUILDING_COLORS[math.random(1, #BUILDING_COLORS)]
	mainStructure.Parent = building

	-- Windows
	local windowSpacing = 10
	for y = 5, size.Y - 5, windowSpacing do
		for x = -size.X / 2 + 5, size.X / 2 - 5, windowSpacing do
			for z = -size.Z / 2 + 5, size.Z / 2 - 5, windowSpacing do
				-- Only create windows on the sides of the building
				if x == -size.X / 2 + 5 or x >= size.X / 2 - 5 or z == -size.Z / 2 + 5 or z >= size.Z / 2 - 5 then
					local window = Instance.new("Part")
					window.Size = Vector3.new(2, 3, 0.5)
					window.Position = position + Vector3.new(x, y, z)
					window.Anchored = true
					window.Material = Enum.Material.Glass
					window.Color = Color3.fromRGB(50, 200, 255)
					window.Transparency = 0.5
					window.Parent = building
				end
			end
		end
	end

	-- Add a roof detail
	local roof = Instance.new("Part")
	roof.Size = Vector3.new(size.X, 2, size.Z)
	roof.Position = position + Vector3.new(0, size.Y + 1, 0)
	roof.Anchored = true
	roof.Material = Enum.Material.Concrete
	roof.Color = Color3.fromRGB(80, 80, 80)
	roof.Parent = building

	return building
end

-- Function to create a street
local function createStreet(position, size)
	local street = Instance.new("Part")
	street.Size = size
	street.Position = position + Vector3.new(0, 0.5, 0)
	street.Anchored = true
	street.Material = Enum.Material.Asphalt
	street.Color = Color3.fromRGB(50, 50, 50)

	-- Add street lines
	if size.X > size.Z then -- Horizontal street
		local line = Instance.new("Part")
		line.Size = Vector3.new(size.X, 0.1, 1)
		line.Position = position + Vector3.new(0, 1, 0)
		line.Anchored = true
		line.Material = Enum.Material.Neon
		line.Color = Color3.fromRGB(255, 255, 255)
		line.Parent = street
	else -- Vertical street
		local line = Instance.new("Part")
		line.Size = Vector3.new(1, 0.1, size.Z)
		line.Position = position + Vector3.new(0, 1, 0)
		line.Anchored = true
		line.Material = Enum.Material.Neon
		line.Color = Color3.fromRGB(255, 255, 255)
		line.Parent = street
	end

	return street
end

-- Function to generate the city
function CityGenerator.generateCity()
	local cityModel = Instance.new("Model")
	cityModel.Name = "City"

	-- Create ground
	local ground = Instance.new("Part")
	ground.Size = Vector3.new(CITY_SIZE, 1, CITY_SIZE)
	ground.Position = Vector3.new(0, 0, 0)
	ground.Anchored = true
	ground.Material = Enum.Material.Grass
	ground.Color = Color3.fromRGB(70, 120, 70)
	ground.Parent = cityModel

	-- Create buildings and streets
	for x = -CITY_SIZE / 2 + BLOCK_SIZE / 2, CITY_SIZE / 2 - BLOCK_SIZE / 2, BLOCK_SIZE + STREET_WIDTH do
		for z = -CITY_SIZE / 2 + BLOCK_SIZE / 2, CITY_SIZE / 2 - BLOCK_SIZE / 2, BLOCK_SIZE + STREET_WIDTH do
			-- Create building
			local buildingSize = Vector3.new(
				BLOCK_SIZE * (0.6 + math.random() * 0.3),
				MIN_BUILDING_HEIGHT + math.random() * (MAX_BUILDING_HEIGHT - MIN_BUILDING_HEIGHT),
				BLOCK_SIZE * (0.6 + math.random() * 0.3)
			)
			local building = createBuilding(Vector3.new(x, 0, z), buildingSize)
			building.Parent = cityModel

			-- Create horizontal street
			local horizontalStreet = createStreet(
				Vector3.new(x, 0, z + BLOCK_SIZE / 2 + STREET_WIDTH / 2),
				Vector3.new(BLOCK_SIZE + STREET_WIDTH, 1, STREET_WIDTH)
			)
			horizontalStreet.Parent = cityModel

			-- Create vertical street
			local verticalStreet = createStreet(
				Vector3.new(x + BLOCK_SIZE / 2 + STREET_WIDTH / 2, 0, z),
				Vector3.new(STREET_WIDTH, 1, BLOCK_SIZE + STREET_WIDTH)
			)
			verticalStreet.Parent = cityModel
		end
	end

	cityModel.Parent = workspace
	return cityModel
end

return CityGenerator
