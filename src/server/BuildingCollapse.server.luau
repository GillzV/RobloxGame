local BuildingCollapse = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local buildings = {}
local destroyedBuildings = {}

-- Function to register a building for collision detection
function BuildingCollapse.registerBuilding(building)
	if building and building:IsA("Model") then
		-- Find the main structure part
		local mainStructure = building:FindFirstChild("MainStructure")
		if not mainStructure then
			-- Look for any part in the building
			for _, child in pairs(building:GetChildren()) do
				if child:IsA("BasePart") then
					mainStructure = child
					break
				end
			end
		end

		if mainStructure then
			-- Add collision detection
			mainStructure.Touched:Connect(function(hit)
				BuildingCollapse.handleCollision(building, hit)
			end)

			-- Store building reference
			buildings[building] = mainStructure
		end
	end
end

-- Function to handle collision with buildings
function BuildingCollapse.handleCollision(building, hit)
	-- Check if it's a player's character
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if player and not destroyedBuildings[building] then
		-- Check if player is flying (has high velocity)
		local humanoid = character:FindFirstChild("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")

		if humanoid and rootPart and rootPart.Velocity.Magnitude > 50 then
			BuildingCollapse.destroyBuilding(building, player)
		end
	end
end

-- Function to destroy a building
function BuildingCollapse.destroyBuilding(building, player)
	if destroyedBuildings[building] then
		return
	end

	destroyedBuildings[building] = true

	-- Create explosion effect
	local explosion = Instance.new("Explosion")
	explosion.Position = building:GetPrimaryPartCFrame().Position
	explosion.BlastRadius = 20
	explosion.BlastPressure = 0 -- No damage, just visual
	explosion.Parent = workspace

	-- Create multiple debris particles
	for _ = 1, 10 do
		local debris = Instance.new("Part")
		debris.Size = Vector3.new(math.random(1, 3), math.random(1, 3), math.random(1, 3))
		debris.Position = building:GetPrimaryPartCFrame().Position
			+ Vector3.new(math.random(-10, 10), math.random(0, 5), math.random(-10, 10))
		debris.Material = Enum.Material.Concrete
		debris.Color = Color3.fromRGB(100, 100, 100)
		debris.Anchored = false
		debris.CanCollide = true
		debris.Parent = workspace

		-- Apply random velocity to debris
		debris.Velocity = Vector3.new(math.random(-100, 100), math.random(30, 80), math.random(-100, 100))

		-- Remove debris after 10 seconds
		game.Debris:AddItem(debris, 10)
	end

	-- Animate building collapse
	for _, part in pairs(building:GetChildren()) do
		if part:IsA("BasePart") then
			-- Create falling animation
			local tween = TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = part.Position + Vector3.new(0, -part.Size.Y, 0),
				Rotation = Vector3.new(math.random(-30, 30), math.random(-30, 30), math.random(-30, 30)),
			})
			tween:Play()

			-- Remove part after animation
			game.Debris:AddItem(part, 2.5)
		end
	end

	-- Remove building model after delay
	game.Debris:AddItem(building, 3)

	-- Award experience to the player
	if player then
		-- Get remote events for awarding experience
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local addExperienceEvent = remotes:WaitForChild("AddExperience")

		-- Award experience for destroying building
		addExperienceEvent:FireClient(player, 50)

		print("Building destroyed by player collision! Awarded 50 XP to", player.Name)
	else
		print("Building destroyed by player collision!")
	end
end

-- Function to register all existing buildings
function BuildingCollapse.registerAllBuildings()
	local city = workspace:FindFirstChild("City")
	if city then
		for _, building in pairs(city:GetChildren()) do
			if building.Name == "Building" then
				BuildingCollapse.registerBuilding(building)
			end
		end
	end
end

-- Handle remote events from clients
local buildingDestroyEvent = ReplicatedStorage:WaitForChild("BuildingDestroyEvent")
buildingDestroyEvent.OnServerEvent:Connect(function(player, building)
	if building and building:IsA("Model") and building.Name == "Building" then
		BuildingCollapse.destroyBuilding(building, player)
	end
end)

-- Initialize building collapse system
RunService.Heartbeat:Connect(function()
	-- Register any new buildings that haven't been registered yet
	BuildingCollapse.registerAllBuildings()
end)

return BuildingCollapse
