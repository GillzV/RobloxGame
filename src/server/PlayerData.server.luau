local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create PlayerStats module in ReplicatedStorage
local PlayerStats = {}

-- ===== CONFIGURABLE SPEED PROGRESSION SETTINGS =====
local SPEED_CONFIG = {
	BASE_SPEED = 35, -- Starting max speed
	-- Linear gain baseline (studs per TIME_INTERVAL). Keep at 1 to match your design
	SPEED_INCREASE = 1,
	TIME_INTERVAL = 1, -- Seconds
	-- New progression curve controls
	-- As speed grows, additional gains are scaled down by this curve
	-- Higher DECAY makes late-game slower. TUNE: 0.000002 .. 0.00001
	NONLINEAR_DECAY = 0.000004,
	-- Soften early slowdown with an offset so the first hundreds feel normal
	SLOW_OFFSET = 250, -- studs
	-- Raise cap so endgame is reachable but far away
	MAX_SPEED_CAP = math.huge, -- effectively no cap
}
-- ===================================================

-- Default player stats
local DEFAULT_STATS = {
	-- Progressive speed system
	maxSpeed = SPEED_CONFIG.BASE_SPEED, -- Current maximum speed (starts at base speed)
	flightTime = 0, -- Total time spent flying (for speed progression)

	-- Speed shop system
	speedShopMultiplier = 1, -- Speed shop multiplier (starts at 1x)
	purchasedMultipliers = {}, -- Track purchased speed multipliers
}

-- Progressive speed calculation with speed shop multiplier integration
local function calculateMaxSpeed(flightTime, speedShopMultiplier)
	speedShopMultiplier = speedShopMultiplier or 1
	-- Uses configurable settings for speed progression
	local baseSpeed = SPEED_CONFIG.BASE_SPEED
	-- Baseline linear gain (what you'd get without slowdown)
	local linearGain = (flightTime / SPEED_CONFIG.TIME_INTERVAL) * SPEED_CONFIG.SPEED_INCREASE

	-- Nonlinear slowdown curve: converts linearGain into slower growth at high speeds
	-- We use a logarithmic-like curve: effectiveGain ≈ log(1 + linearGain * decay) / decay
	-- With an offset so early game feels close to linear
	local decay = SPEED_CONFIG.NONLINEAR_DECAY
	local offset = SPEED_CONFIG.SLOW_OFFSET

	local function slowCurve(x)
		-- Ensure numeric stability
		if x <= 0 then
			return 0
		end
		-- ln(1 + decay*(x+offset)) - ln(1 + decay*offset)
		local a = math.log(1 + decay * (x + offset))
		local b = math.log(1 + decay * offset)
		return (a - b) / decay
	end

	local effectiveGain = slowCurve(linearGain)
	local baseMaxSpeed = baseSpeed + effectiveGain

	-- Apply speed shop multiplier as a separate boost
	-- This way the multiplier acts like a permanent speed boost that gets added to your progression
	local speedBoost = baseMaxSpeed * (speedShopMultiplier - 1)
	local finalSpeed = baseMaxSpeed + speedBoost

	-- Cap at configured maximum speed
	return math.min(finalSpeed, SPEED_CONFIG.MAX_SPEED_CAP)
end

function PlayerStats.new()
	local stats = table.clone(DEFAULT_STATS)

	-- Calculate initial max speed with speed shop multiplier
	stats.maxSpeed = calculateMaxSpeed(stats.flightTime, stats.speedShopMultiplier)

	return stats
end

function PlayerStats.addFlightTime(stats, deltaTime)
	stats.flightTime = stats.flightTime + deltaTime

	-- Update max speed based on new flight time with speed shop multiplier
	local newMaxSpeed = calculateMaxSpeed(stats.flightTime, stats.speedShopMultiplier)
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

function PlayerStats.getSpeedShopMultiplier(stats)
	return stats.speedShopMultiplier or 1
end

function PlayerStats.setSpeedShopMultiplier(stats, multiplier)
	stats.speedShopMultiplier = multiplier or 1
	-- Recalculate max speed with new multiplier
	stats.maxSpeed = calculateMaxSpeed(stats.flightTime, stats.speedShopMultiplier)
	print("Speed shop multiplier updated to:", multiplier .. "x, new max speed:", stats.maxSpeed)
end

function PlayerStats.getPurchasedMultipliers(stats)
	return stats.purchasedMultipliers or {}
end

function PlayerStats.setPurchasedMultipliers(stats, purchasedMultipliers)
	stats.purchasedMultipliers = purchasedMultipliers or {}
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

-- Server-only signals for inter-script communication
local ServerScriptService = game:GetService("ServerScriptService")
local serverSignals = ServerScriptService:FindFirstChild("ServerSignals")
if not serverSignals then
	serverSignals = Instance.new("Folder")
	serverSignals.Name = "ServerSignals"
	serverSignals.Parent = ServerScriptService
end

local addFlightTimeServer = serverSignals:FindFirstChild("AddFlightTimeServer")
if not addFlightTimeServer then
	addFlightTimeServer = Instance.new("BindableEvent")
	addFlightTimeServer.Name = "AddFlightTimeServer"
	addFlightTimeServer.Parent = serverSignals
end

-- The event connection is established after playerStats and updateClientStats are defined

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

-- Wire server signal after locals are defined so awards from HoopRewards work
do
	local ServerScriptService = game:GetService("ServerScriptService")
	local serverSignals = ServerScriptService:FindFirstChild("ServerSignals")
	if serverSignals then
		local addFlightTimeServer = serverSignals:FindFirstChild("AddFlightTimeServer")
		if addFlightTimeServer and addFlightTimeServer:IsA("BindableEvent") then
			addFlightTimeServer.Event:Connect(function(player, deltaTime)
				local data = playerStats[player.UserId]
				if data and typeof(deltaTime) == "number" and deltaTime > 0 then
					local beforeTime = PlayerStats.getFlightTime(data)
					PlayerStats.addFlightTime(data, deltaTime)
					local afterTime = PlayerStats.getFlightTime(data)
					updateClientStats(player)
					print(
						"PlayerData: awarded via server signal:",
						player.Name,
						"+" .. deltaTime .. "s, max:",
						data.maxSpeed,
						"flightTime before:",
						beforeTime,
						"after:",
						afterTime
					)
				end
			end)
		else
			warn("PlayerData: AddFlightTimeServer not found; HoopRewards grants will be ignored")
		end
	else
		warn("PlayerData: ServerSignals folder not found; HoopRewards grants will be ignored")
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

-- Export functions for other scripts to use
PlayerData.getPlayerStats = function(player)
	return playerStats[player.UserId]
end

PlayerData.updateClientStats = updateClientStats
PlayerData.setSpeedShopMultiplier = PlayerStats.setSpeedShopMultiplier

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

-- Function to update player stats (for other server scripts)
function PlayerData.updatePlayerStats(player, newStats)
	if newStats then
		playerStats[player.UserId] = newStats
		updateClientStats(player)
		savePlayerData(player)
		return true
	end
	return false
end

-- Function to update speed shop multiplier
function PlayerData.updateSpeedShopMultiplier(player, multiplier, purchasedMultipliers)
	local data = playerStats[player.UserId]
	if data then
		PlayerStats.setSpeedShopMultiplier(data, multiplier)
		if purchasedMultipliers then
			PlayerStats.setPurchasedMultipliers(data, purchasedMultipliers)
		end
		updateClientStats(player)
		savePlayerData(player)
		print("SpeedMultiplierHandler: Saved speed shop data for", player.Name, "- Multiplier:", multiplier .. "x")
		return true
	end
	return false
end

-- Function to get speed shop data
function PlayerData.getSpeedShopData(player)
	local data = playerStats[player.UserId]
	if data then
		return {
			multiplier = PlayerStats.getSpeedShopMultiplier(data),
			purchasedMultipliers = PlayerStats.getPurchasedMultipliers(data),
		}
	end
	return nil
end

return PlayerData
