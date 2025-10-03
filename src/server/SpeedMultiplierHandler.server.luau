-- DISABLED - Speed Multiplier Handler (Server-side)
-- Handles permanent max speed upgrades from Robux purchases
-- MUST BE IN SERVERSERVICE FOR PROCESSRECEIPT TO WORK
-- REPLACED BY SpeedShopIntegration.server.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Wait for PlayerStats module
local PlayerStats = require(game.ServerStorage.shared.PlayerStats)
-- Wait for PlayerData module
local PlayerData = require(script.Parent.PlayerData)

print("=== SPEED MULTIPLIER HANDLER LOADING ===")
print("Script location:", script:GetFullName())
print("Is in ServerScriptService:", script.Parent.Name == "ServerScriptService")

-- Create remote events for client-server communication
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateMaxSpeedMultiplierEvent = Instance.new("RemoteEvent")
updateMaxSpeedMultiplierEvent.Name = "UpdateMaxSpeedMultiplier"
updateMaxSpeedMultiplierEvent.Parent = remotes

-- Wait for the stats update event from PlayerData
local updateStatsEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UpdateStats")
print("SpeedMultiplierHandler: Found UpdateStats event")

-- Store player speed multipliers (server-side)
local playerSpeedMultipliers = {}

-- Product IDs for Robux purchases (must match client-side - replace with your actual product IDs)
-- IMPORTANT: You must create these products in Roblox Studio under Game Settings > Monetization > Developer Products
local PRODUCT_IDS = {
	[1] = 3402098428, -- Replace with your actual product ID for 2x speed
	[2] = 3402098905, -- Replace with your actual product ID for 50x speed
	[3] = 3402099389, -- Replace with your actual product ID for 100x speed
	[4] = 3402099684, -- Replace with your actual product ID for 500x speed
}

local MULTIPLIERS = {
	[1] = 2, -- 2x speed
	[2] = 50, -- 50x speed
	[3] = 100, -- 100x speed
	[4] = 500, -- 500x speed
}

-- Get player's current speed multiplier
local function getPlayerSpeedMultiplier(player)
	return playerSpeedMultipliers[player.UserId] or 1
end

-- Update player's speed multiplier (stacking system)
local function updatePlayerSpeedMultiplier(player, newMultiplier)
	-- Get current multiplier (starts at 1)
	local currentMultiplier = playerSpeedMultipliers[player.UserId] or 1

	-- For stacking, we need to calculate the difference and multiply
	-- If the new multiplier is higher than current, multiply by the difference
	local stackedMultiplier
	if newMultiplier > currentMultiplier then
		-- Calculate the multiplier difference and apply it
		local multiplierDifference = newMultiplier / currentMultiplier
		stackedMultiplier = currentMultiplier * multiplierDifference
	else
		-- If it's the same or lower, just use the new value
		stackedMultiplier = newMultiplier
	end

	playerSpeedMultipliers[player.UserId] = stackedMultiplier

	print("SpeedMultiplierHandler: Updated speed multiplier for", player.Name)
	print("  Previous multiplier:", currentMultiplier .. "x")
	print("  New purchase multiplier:", newMultiplier .. "x")
	print("  Total stacked multiplier:", stackedMultiplier .. "x")

	-- Update the global multiplier for the flight system
	_G.playerSpeedMultiplier = stackedMultiplier

	-- Update the player's stats to reflect the new stacked multiplier
	local stats = PlayerData.getPlayerStats(player)
	print("SpeedMultiplierHandler: Retrieved stats for", player.Name, ":", stats)
	if stats then
		local currentMaxSpeed = stats.maxSpeed
		print("SpeedMultiplierHandler: Current base max speed for", player.Name, ":", currentMaxSpeed)
		print("SpeedMultiplierHandler: Total speed shop multiplier:", stackedMultiplier .. "x")

		-- Don't modify the base max speed - keep it as the base speed
		-- The speed shop multiplier will be applied via _G.speedMultiplier

		-- Save the updated stats to PlayerData
		PlayerData.updatePlayerStats(player, stats)

		-- Also save the speed shop multiplier separately for persistence
		PlayerData.updateSpeedShopMultiplier(player, stackedMultiplier, nil)
		print("SpeedMultiplierHandler: Saved updated stats and speed shop data to PlayerData")

		-- Fire the stats update event to update the HUD
		print("SpeedMultiplierHandler: Firing UpdateStats event to client")
		print("SpeedMultiplierHandler: Stats being sent:", stats)
		updateStatsEvent:FireClient(player, stats)
	end
end

-- Handle client requests to update max speed multiplier
updateMaxSpeedMultiplierEvent.OnServerEvent:Connect(function(player, multiplier)
	print("SpeedMultiplierHandler: Received multiplier update request from", player.Name, ":", multiplier)
	-- Verify the multiplier is valid
	if type(multiplier) == "number" and multiplier >= 1 then
		-- In Studio mode, we accept direct multiplier updates from client for testing
		if game:GetService("RunService"):IsStudio() then
			print("Studio mode: Accepting direct multiplier update from client for testing")
		end
		updatePlayerSpeedMultiplier(player, multiplier)
	else
		warn("SpeedMultiplierHandler: Invalid speed multiplier received from", player.Name, ":", multiplier)
	end
end)

-- Store individual purchases for stacking
local playerPurchases = {}

-- Listen for purchases from your existing purchase system
Players.PlayerAdded:Connect(function(player)
	-- Initialize player purchases
	playerPurchases[player.UserId] = {}

	print("SpeedMultiplierHandler: Player joined -", player.Name, "UserID:", player.UserId)
	print("SpeedMultiplierHandler: Initial Tier3PermanentMaxMult:", player:GetAttribute("Tier3PermanentMaxMult") or 1)

	-- Listen for changes to the Tier3PermanentMaxMult attribute from your purchase system
	player:GetAttributeChangedSignal("Tier3PermanentMaxMult"):Connect(function()
		local tier3Multiplier = player:GetAttribute("Tier3PermanentMaxMult") or 1
		print("SpeedMultiplierHandler: *** TIER3 ATTRIBUTE CHANGED *** for", player.Name, ":", tier3Multiplier .. "x")

		-- For stacking, we need to track individual purchases
		-- When a new purchase is made, we'll calculate the difference and stack it
		local currentStackedMultiplier = playerSpeedMultipliers[player.UserId] or 1
		local newPurchaseMultiplier = tier3Multiplier

		-- If this is a new higher multiplier, calculate the difference and stack it
		if newPurchaseMultiplier > currentStackedMultiplier then
			local multiplierDifference = newPurchaseMultiplier / currentStackedMultiplier
			local newStackedMultiplier = currentStackedMultiplier * multiplierDifference

			playerSpeedMultipliers[player.UserId] = newStackedMultiplier
			_G.playerSpeedMultiplier = newStackedMultiplier

			print("SpeedMultiplierHandler: Stacked multiplier for", player.Name)
			print("  Previous stacked:", currentStackedMultiplier .. "x")
			print("  New purchase:", newPurchaseMultiplier .. "x")
			print("  Difference:", multiplierDifference .. "x")
			print("  Final stacked:", newStackedMultiplier .. "x")

			-- Update client
			print("SpeedMultiplierHandler: *** FIRING REMOTEEVENT TO CLIENT ***")
			print("SpeedMultiplierHandler: Player:", player.Name, "Multiplier:", newStackedMultiplier .. "x")
			updateMaxSpeedMultiplierEvent:FireClient(player, newStackedMultiplier)
			print("SpeedMultiplierHandler: *** REMOTEEVENT SENT ***")
		end
	end)

	-- Set initial multiplier when player joins
	local initialMultiplier = player:GetAttribute("Tier3PermanentMaxMult") or 1
	if initialMultiplier > 1 then
		print(
			"SpeedMultiplierHandler: Loading existing Tier3PermanentMaxMult for",
			player.Name,
			":",
			initialMultiplier .. "x"
		)
		playerSpeedMultipliers[player.UserId] = initialMultiplier
		_G.playerSpeedMultiplier = initialMultiplier
		updateMaxSpeedMultiplierEvent:FireClient(player, initialMultiplier)
	end
end)

-- NOTE: We don't handle ProcessReceipt here - that's handled by ProcessPurchases.server.lua
-- This script only listens for the Tier3PermanentMaxMult attribute changes
print("=== SPEED MULTIPLIER HANDLER: INTEGRATED WITH EXISTING PURCHASE SYSTEM ===")
print("ProcessReceipt is handled by ProcessPurchases.server.lua")
print("This script listens for Tier3PermanentMaxMult attribute changes")

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerSpeedMultipliers[player.UserId] = nil
	playerPurchases[player.UserId] = nil
end)

-- Handle player joining - load their speed shop data
Players.PlayerAdded:Connect(function(player)
	-- Wait for player data to load
	spawn(function()
		wait(2) -- Give time for PlayerData to load

		local speedShopData = PlayerData.getSpeedShopData(player)
		if speedShopData then
			local multiplier = speedShopData.multiplier
			local purchasedMultipliers = speedShopData.purchasedMultipliers

			if multiplier and multiplier > 1 then
				print(
					"SpeedMultiplierHandler: Loading saved speed shop data for",
					player.Name,
					"- Multiplier:",
					multiplier .. "x"
				)

				-- Update the player's speed multiplier
				playerSpeedMultipliers[player.UserId] = multiplier

				-- Update purchased multipliers if available
				if purchasedMultipliers then
					-- Store purchased multipliers for client sync
					_G.playerPurchasedMultipliers = _G.playerPurchasedMultipliers or {}
					_G.playerPurchasedMultipliers[player.UserId] = purchasedMultipliers
				end

				-- Notify client of loaded speed shop data
				updateMaxSpeedMultiplierEvent:FireClient(player, multiplier)

				print("SpeedMultiplierHandler: Restored speed shop multiplier for", player.Name)
			end
		end
	end)
end)

-- Debug command for testing
local function debugSpeedShop()
	print("=== DEBUG: SPEED SHOP STATUS ===")
	print("Product IDs:")
	for i, id in pairs(PRODUCT_IDS) do
		print("  [" .. i .. "] = " .. id .. " (" .. MULTIPLIERS[i] .. "x speed)")
	end
	print("Player speed multipliers:")
	for userId, multiplier in pairs(playerSpeedMultipliers) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			print("  " .. player.Name .. " (ID: " .. userId .. ") = " .. multiplier .. "x")
		end
	end
	print("ProcessReceipt function:", MarketplaceService.ProcessReceipt ~= nil)
	print("ProcessReceipt function object:", MarketplaceService.ProcessReceipt)
	print("================================")
end

-- Test command to simulate purchase attribute change
local function testPurchaseAttribute(player)
	print("=== TESTING PURCHASE ATTRIBUTE CHANGE ===")
	if not player then
		player = Players:GetPlayers()[1]
		if not player then
			warn("No players found for test")
			return
		end
	end

	print("Testing with player:", player.Name, "ID:", player.UserId)
	print("Current Tier3PermanentMaxMult:", player:GetAttribute("Tier3PermanentMaxMult") or 1)

	-- Simulate a purchase by setting the attribute (like your ProcessPurchases.server.lua would)
	local newMultiplier = 2
	print("Setting Tier3PermanentMaxMult to:", newMultiplier)
	player:SetAttribute("Tier3PermanentMaxMult", newMultiplier)

	print("New Tier3PermanentMaxMult:", player:GetAttribute("Tier3PermanentMaxMult"))
	print("=== TEST COMPLETE ===")
end

-- Export functions for other scripts to use
_G.getPlayerSpeedMultiplier = getPlayerSpeedMultiplier
_G.updatePlayerSpeedMultiplier = updatePlayerSpeedMultiplier
_G.debugSpeedShop = debugSpeedShop
_G.testPurchaseAttribute = testPurchaseAttribute

print("=== SERVER: SPEED MULTIPLIER HANDLER INITIALIZED ===")
print("Product IDs configured:")
for i, id in pairs(PRODUCT_IDS) do
	print("  [" .. i .. "] = " .. id .. " (" .. MULTIPLIERS[i] .. "x speed)")
end
print("ProcessReceipt function set:", MarketplaceService.ProcessReceipt ~= nil)
print("ProcessReceipt function:", MarketplaceService.ProcessReceipt)
print("Ready to handle purchases!")
print("=== IMPORTANT: USE 'START SERVER' (NOT SINGLE PLAYER) TO TEST ===")

-- No ProcessReceipt monitoring needed - using existing ProcessPurchases.server.lua
