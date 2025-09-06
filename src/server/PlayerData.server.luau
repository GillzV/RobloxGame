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
}

-- Experience required for each level (exponential growth)
local function getExperienceForLevel(level)
	return math.floor(100 * (1.5 ^ (level - 1)))
end

-- Speed tier unlock requirements
local function getMaxSpeedTierForLevel(level)
	if level >= 4 then
		return 3 -- Max speed tier
	else
		return 2 -- Fast flight accessible from level 1
	end
end

-- Speed multiplier calculation
local function getSpeedMultiplierForLevel(level)
	return 1.0 + (level - 1) * 0.2 -- 20% increase per level
end

function PlayerStats.new()
	local stats = table.clone(DEFAULT_STATS)

	-- Calculate initial values
	stats.maxSpeedTier = getMaxSpeedTierForLevel(stats.level)
	stats.speedMultiplier = getSpeedMultiplierForLevel(stats.speedLevel)

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

		print("Level up! New level:", stats.level)
	end
end

function PlayerStats.upgradeSpeed(stats)
	stats.speedLevel = stats.speedLevel + 1
	stats.speedMultiplier = getSpeedMultiplierForLevel(stats.speedLevel)
	return true
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

local addExperienceEvent = Instance.new("RemoteEvent")
addExperienceEvent.Name = "AddExperience"
addExperienceEvent.Parent = remotes

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
	player.CharacterAdded:Connect(function()
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
		print(player.Name, "failed to upgrade speed")
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

return PlayerData
