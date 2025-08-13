local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create PlayerStats module in ReplicatedStorage
local PlayerStats = {}

-- Default player stats
local DEFAULT_STATS = {
	level = 1,
	experience = 0,
	experienceToNext = 100,

	-- Speed upgrades
	speedLevel = 1,
	maxSpeedTier = 1, -- How many times they can boost (starts at 1)
	speedMultiplier = 1.0,

	-- Strength upgrades
	strengthLevel = 1,
	damageMultiplier = 1.0,

	-- Health upgrades
	healthLevel = 1,
	maxHealth = 100,
	healthRegenRate = 1.0,

	-- Currency
	coins = 0,

	-- Upgrade costs (increases with level)
	upgradeCosts = {
		speed = 50,
		strength = 75,
		health = 100,
	},
}

-- Experience required for each level (exponential growth)
local function getExperienceForLevel(level)
	return math.floor(100 * (1.5 ^ (level - 1)))
end

-- Speed tier unlock requirements
local function getMaxSpeedTierForLevel(level)
	if level >= 10 then
		return 4 -- Max speed tier
	elseif level >= 7 then
		return 3
	elseif level >= 4 then
		return 2
	else
		return 1
	end
end

-- Speed multiplier calculation
local function getSpeedMultiplierForLevel(level)
	return 1.0 + (level - 1) * 0.2 -- 20% increase per level
end

-- Damage multiplier calculation
local function getDamageMultiplierForLevel(level)
	return 1.0 + (level - 1) * 0.15 -- 15% increase per level
end

-- Health calculation
local function getMaxHealthForLevel(level)
	return 100 + (level - 1) * 25 -- 25 health per level
end

-- Health regen calculation
local function getHealthRegenForLevel(level)
	return 1.0 + (level - 1) * 0.1 -- 10% regen increase per level
end

-- Upgrade cost calculation
local function getUpgradeCost(baseCost, currentLevel)
	return math.floor(baseCost * (1.3 ^ (currentLevel - 1)))
end

function PlayerStats.new()
	local stats = {}

	-- Copy default stats
	for key, value in pairs(DEFAULT_STATS) do
		stats[key] = value
	end

	-- Calculate initial values
	stats.maxSpeedTier = getMaxSpeedTierForLevel(stats.level)
	stats.speedMultiplier = getSpeedMultiplierForLevel(stats.speedLevel)
	stats.damageMultiplier = getDamageMultiplierForLevel(stats.strengthLevel)
	stats.maxHealth = getMaxHealthForLevel(stats.healthLevel)
	stats.healthRegenRate = getHealthRegenForLevel(stats.healthLevel)

	return stats
end

function PlayerStats.addExperience(stats, amount)
	stats.experience = stats.experience + amount

	-- Check for level up
	while stats.experience >= stats.experienceToNext do
		stats.experience = stats.experience - stats.experienceToNext
		stats.level = stats.level + 1
		stats.experienceToNext = getExperienceForLevel(stats.level)

		-- Update max speed tier based on new level
		stats.maxSpeedTier = getMaxSpeedTierForLevel(stats.level)

		-- Give coins for leveling up
		stats.coins = stats.coins + (stats.level * 10)

		print("Level up! New level:", stats.level)
	end
end

function PlayerStats.canUpgradeSpeed(stats)
	return stats.coins >= stats.upgradeCosts.speed
end

function PlayerStats.upgradeSpeed(stats)
	if PlayerStats.canUpgradeSpeed(stats) then
		stats.coins = stats.coins - stats.upgradeCosts.speed
		stats.speedLevel = stats.speedLevel + 1
		stats.speedMultiplier = getSpeedMultiplierForLevel(stats.speedLevel)
		stats.upgradeCosts.speed = getUpgradeCost(50, stats.speedLevel)
		return true
	end
	return false
end

function PlayerStats.canUpgradeStrength(stats)
	return stats.coins >= stats.upgradeCosts.strength
end

function PlayerStats.upgradeStrength(stats)
	if PlayerStats.canUpgradeStrength(stats) then
		stats.coins = stats.coins - stats.upgradeCosts.strength
		stats.strengthLevel = stats.strengthLevel + 1
		stats.damageMultiplier = getDamageMultiplierForLevel(stats.strengthLevel)
		stats.upgradeCosts.strength = getUpgradeCost(75, stats.strengthLevel)
		return true
	end
	return false
end

function PlayerStats.canUpgradeHealth(stats)
	return stats.coins >= stats.upgradeCosts.health
end

function PlayerStats.upgradeHealth(stats)
	if PlayerStats.canUpgradeHealth(stats) then
		stats.coins = stats.coins - stats.upgradeCosts.health
		stats.healthLevel = stats.healthLevel + 1
		stats.maxHealth = getMaxHealthForLevel(stats.healthLevel)
		stats.healthRegenRate = getHealthRegenForLevel(stats.healthLevel)
		stats.upgradeCosts.health = getUpgradeCost(100, stats.healthLevel)
		return true
	end
	return false
end

function PlayerStats.addCoins(stats, amount)
	stats.coins = stats.coins + amount
end

function PlayerStats.getSpeedTiers(stats)
	local baseSpeed = 35
	local tiers = {}

	for i = 1, stats.maxSpeedTier do
		tiers[i] = math.floor(baseSpeed * stats.speedMultiplier * (1.5 ^ (i - 1)))
	end

	return tiers
end

-- Helper functions for server
function PlayerStats.getMaxSpeedTierForLevel(level)
	return getMaxSpeedTierForLevel(level)
end

function PlayerStats.getSpeedMultiplierForLevel(level)
	return getSpeedMultiplierForLevel(level)
end

function PlayerStats.getDamageMultiplierForLevel(level)
	return getDamageMultiplierForLevel(level)
end

function PlayerStats.getMaxHealthForLevel(level)
	return getMaxHealthForLevel(level)
end

function PlayerStats.getHealthRegenForLevel(level)
	return getHealthRegenForLevel(level)
end

local PlayerData = {}

-- Data store for player data persistence
local playerDataStore = DataStoreService:GetDataStore("PlayerStats")

-- Remote events for client-server communication
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local updateStatsEvent = Instance.new("RemoteEvent")
updateStatsEvent.Name = "UpdateStats"
updateStatsEvent.Parent = remotes

local upgradeSpeedEvent = Instance.new("RemoteEvent")
upgradeSpeedEvent.Name = "UpgradeSpeed"
upgradeSpeedEvent.Parent = remotes

local upgradeStrengthEvent = Instance.new("RemoteEvent")
upgradeStrengthEvent.Name = "UpgradeStrength"
upgradeStrengthEvent.Parent = remotes

local upgradeHealthEvent = Instance.new("RemoteEvent")
upgradeHealthEvent.Name = "UpgradeHealth"
upgradeHealthEvent.Parent = remotes

local addExperienceEvent = Instance.new("RemoteEvent")
addExperienceEvent.Name = "AddExperience"
addExperienceEvent.Parent = remotes

local addCoinsEvent = Instance.new("RemoteEvent")
addCoinsEvent.Name = "AddCoins"
addCoinsEvent.Parent = remotes

-- Player data cache
local playerStats = {}

-- Load player data from DataStore
local function loadPlayerData(player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		-- Validate and merge with default stats
		local defaultStats = PlayerStats.new()
		for key, value in pairs(defaultStats) do
			if data[key] == nil then
				data[key] = value
			end
		end

		-- Recalculate derived values
		data.maxSpeedTier = PlayerStats.getMaxSpeedTierForLevel(data.level)
		data.speedMultiplier = PlayerStats.getSpeedMultiplierForLevel(data.speedLevel)
		data.damageMultiplier = PlayerStats.getDamageMultiplierForLevel(data.strengthLevel)
		data.maxHealth = PlayerStats.getMaxHealthForLevel(data.healthLevel)
		data.healthRegenRate = PlayerStats.getHealthRegenForLevel(data.healthLevel)

		playerStats[player.UserId] = data
		print("Loaded data for player:", player.Name)
		return data
	else
		-- Create new player data
		local newStats = PlayerStats.new()
		playerStats[player.UserId] = newStats
		print("Created new data for player:", player.Name)
		return newStats
	end
end

-- Save player data to DataStore
local function savePlayerData(player)
	local data = playerStats[player.UserId]
	if data then
		local success, err = pcall(function()
			playerDataStore:SetAsync(player.UserId, data)
		end)

		if success then
			print("Saved data for player:", player.Name)
		else
			warn("Failed to save data for player:", player.Name, "Error:", err)
		end
	end
end

-- Update client with current stats
local function updateClientStats(player)
	local data = playerStats[player.UserId]
	if data then
		updateStatsEvent:FireClient(player, data)
	end
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	-- Load player data
	loadPlayerData(player)

	-- Wait for character to spawn
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local data = playerStats[player.UserId]

		if data then
			-- Apply health upgrades
			humanoid.MaxHealth = data.maxHealth
			humanoid.Health = data.maxHealth

			-- Apply health regeneration
			spawn(function()
				while humanoid and humanoid.Parent and humanoid.Health > 0 do
					if humanoid.Health < humanoid.MaxHealth then
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + data.healthRegenRate)
					end
					wait(1)
				end
			end)
		end

		-- Update client stats
		updateClientStats(player)
	end)

	-- Update client stats immediately
	updateClientStats(player)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	playerStats[player.UserId] = nil
end)

-- Auto-save data periodically
spawn(function()
	while true do
		wait(60) -- Save every minute
		for _, player in pairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
	end
end)

-- Handle upgrade requests from client
upgradeSpeedEvent.OnServerEvent:Connect(function(player)
	local data = playerStats[player.UserId]
	if data and PlayerStats.upgradeSpeed(data) then
		updateClientStats(player)
		print(player.Name, "upgraded speed to level", data.speedLevel)
	else
		print(player.Name, "failed to upgrade speed - insufficient coins")
	end
end)

upgradeStrengthEvent.OnServerEvent:Connect(function(player)
	local data = playerStats[player.UserId]
	if data and PlayerStats.upgradeStrength(data) then
		updateClientStats(player)
		print(player.Name, "upgraded strength to level", data.strengthLevel)
	else
		print(player.Name, "failed to upgrade strength - insufficient coins")
	end
end)

upgradeHealthEvent.OnServerEvent:Connect(function(player)
	local data = playerStats[player.UserId]
	if data and PlayerStats.upgradeHealth(data) then
		-- Update character health if they have one
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.MaxHealth = data.maxHealth
			player.Character.Humanoid.Health = data.maxHealth
		end

		updateClientStats(player)
		print(player.Name, "upgraded health to level", data.healthLevel)
	else
		print(player.Name, "failed to upgrade health - insufficient coins")
	end
end)

-- Handle experience gain
addExperienceEvent.OnServerEvent:Connect(function(player, amount)
	local data = playerStats[player.UserId]
	if data then
		PlayerStats.addExperience(data, amount)
		updateClientStats(player)
		print(player.Name, "gained", amount, "experience")
	end
end)

-- Handle coin gain
addCoinsEvent.OnServerEvent:Connect(function(player, amount)
	local data = playerStats[player.UserId]
	if data then
		PlayerStats.addCoins(data, amount)
		updateClientStats(player)
		print(player.Name, "gained", amount, "coins")
	end
end)

-- Function to get player stats (for other server scripts)
function PlayerData.getPlayerStats(player)
	return playerStats[player.UserId]
end

-- Function to add experience (for other server scripts)
function PlayerData.addExperience(player, amount)
	local data = playerStats[player.UserId]
	if data then
		PlayerStats.addExperience(data, amount)
		updateClientStats(player)
		return true
	end
	return false
end

-- Function to add coins (for other server scripts)
function PlayerData.addCoins(player, amount)
	local data = playerStats[player.UserId]
	if data then
		PlayerStats.addCoins(data, amount)
		updateClientStats(player)
		return true
	end
	return false
end

return PlayerData
