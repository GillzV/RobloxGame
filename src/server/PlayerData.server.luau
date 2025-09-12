local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create PlayerStats module in ReplicatedStorage
local PlayerStats = {}

-- ===== CONFIGURABLE SPEED PROGRESSION SETTINGS =====
local SPEED_CONFIG = {
	BASE_SPEED = 35, -- Starting max speed
	SPEED_INCREASE = 1, -- Speed gained per interval (0.1 studs/s every 5 seconds)
	TIME_INTERVAL = 1, -- Time interval in seconds for speed gain
	MAX_SPEED_CAP = 1000, -- Maximum possible speed
}
-- ===================================================

-- Default player stats
local DEFAULT_STATS = {
	-- Progressive speed system
	maxSpeed = SPEED_CONFIG.BASE_SPEED, -- Current maximum speed (starts at base speed)
	flightTime = 0, -- Total time spent flying (for speed progression)
}

-- Progressive speed calculation
local function calculateMaxSpeed(flightTime)
	-- Uses configurable settings for speed progression
	local baseSpeed = SPEED_CONFIG.BASE_SPEED
	-- Calculate gradual increase: speed increases by SPEED_INCREASE every TIME_INTERVAL seconds
	local speedIncrease = (flightTime / SPEED_CONFIG.TIME_INTERVAL) * SPEED_CONFIG.SPEED_INCREASE
	local maxSpeed = baseSpeed + speedIncrease

	-- Cap at configured maximum speed
	return math.min(maxSpeed, SPEED_CONFIG.MAX_SPEED_CAP)
end

function PlayerStats.new()
	local stats = table.clone(DEFAULT_STATS)

	-- Calculate initial max speed
	stats.maxSpeed = calculateMaxSpeed(stats.flightTime)

	return stats
end

function PlayerStats.addFlightTime(stats, deltaTime)
	stats.flightTime = stats.flightTime + deltaTime

	-- Update max speed based on new flight time
	local newMaxSpeed = calculateMaxSpeed(stats.flightTime)
	if newMaxSpeed > stats.maxSpeed then
		stats.maxSpeed = newMaxSpeed
		print("Speed increased! New max speed:", stats.maxSpeed)
	end
end

function PlayerStats.updateMaxSpeedFromActual(stats, actualSpeed)
	-- Disabled actual speed tracking - only use time-based progression
	-- This function is kept for compatibility but does nothing
	return false
end

function PlayerStats.getMaxSpeed(stats)
	local maxSpeed = stats.maxSpeed or SPEED_CONFIG.BASE_SPEED
	-- Ensure it doesn't exceed the cap
	return math.min(maxSpeed, SPEED_CONFIG.MAX_SPEED_CAP)
end

function PlayerStats.getFlightTime(stats)
	return stats.flightTime or 0
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

local addFlightTimeEvent = Instance.new("RemoteEvent")
addFlightTimeEvent.Name = "AddFlightTime"
addFlightTimeEvent.Parent = remotes

local updateActualSpeedEvent = Instance.new("RemoteEvent")
updateActualSpeedEvent.Name = "UpdateActualSpeed"
updateActualSpeedEvent.Parent = remotes

local toggleFlightEvent = Instance.new("RemoteEvent")
toggleFlightEvent.Name = "ToggleFlight"
toggleFlightEvent.Parent = remotes

-- Player data cache
local playerStats = {}

-- Load player data from DataStore
local function loadPlayerData(player)
	-- Skip DataStore operations in Studio to avoid API access errors
	if game:GetService("RunService"):IsStudio() then
		print("Studio mode: Using default stats for player:", player.Name)
		local newStats = PlayerStats.new()
		playerStats[player.UserId] = newStats
		return newStats
	end

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
		data.maxSpeed = PlayerStats.getMaxSpeed(data)

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
	-- Skip DataStore operations in Studio to avoid API access errors
	if game:GetService("RunService"):IsStudio() then
		print("Studio mode: Skipping DataStore save for player:", player.Name)
		return
	end

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

-- Handle flight time gain
addFlightTimeEvent.OnServerEvent:Connect(function(player, deltaTime)
	local data = playerStats[player.UserId]
	if data then
		PlayerStats.addFlightTime(data, deltaTime)
		updateClientStats(player)
		print(player.Name, "added", deltaTime, "seconds of flight time, max speed:", data.maxSpeed)
	end
end)

-- Handle actual speed updates
updateActualSpeedEvent.OnServerEvent:Connect(function(player, actualSpeed)
	local data = playerStats[player.UserId]
	if data then
		local speedUpdated = PlayerStats.updateMaxSpeedFromActual(data, actualSpeed)
		if speedUpdated then
			updateClientStats(player)
			print(player.Name, "max speed updated to", data.maxSpeed, "from actual speed", actualSpeed)
		end
	end
end)

-- Function to get player stats (for other server scripts)
function PlayerData.getPlayerStats(player)
	return playerStats[player.UserId]
end

-- Function to add flight time (for other server scripts)
function PlayerData.addFlightTime(player, deltaTime)
	local data = playerStats[player.UserId]
	if data then
		PlayerStats.addFlightTime(data, deltaTime)
		updateClientStats(player)
		return true
	end
	return false
end

return PlayerData
