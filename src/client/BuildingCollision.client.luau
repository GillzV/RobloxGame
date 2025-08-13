local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Remote event for building destruction
local buildingDestroyEvent = Instance.new("RemoteEvent")
buildingDestroyEvent.Name = "BuildingDestroyEvent"
buildingDestroyEvent.Parent = ReplicatedStorage

-- Function to handle building collisions
local function onBuildingCollision(building)
	if building and building.Name == "Building" then
		-- Check if we're flying (high velocity)
		if rootPart.Velocity.Magnitude > 50 then
			-- Fire the remote event to destroy the building
			buildingDestroyEvent:FireServer(building)
		end
	end
end

-- Connect to character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	rootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Set up collision detection for all buildings
local function setupBuildingCollisions()
	local city = workspace:FindFirstChild("City")
	if city then
		for _, building in pairs(city:GetChildren()) do
			if building.Name == "Building" then
				local mainStructure = building:FindFirstChild("MainStructure")
				if mainStructure then
					mainStructure.Touched:Connect(function(hit)
						if hit.Parent == character then
							onBuildingCollision(building)
						end
					end)
				end
			end
		end
	end
end

-- Initialize building collisions
setupBuildingCollisions()

-- Set up collision detection for new buildings
workspace.ChildAdded:Connect(function(child)
	if child.Name == "City" then
		child.ChildAdded:Connect(function(building)
			if building.Name == "Building" then
				local mainStructure = building:FindFirstChild("MainStructure")
				if mainStructure then
					mainStructure.Touched:Connect(function(hit)
						if hit.Parent == character then
							onBuildingCollision(building)
						end
					end)
				end
			end
		end)
	end
end)
