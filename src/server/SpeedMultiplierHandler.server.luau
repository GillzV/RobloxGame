-- Speed Multiplier Handler (Server-side)
-- Handles permanent max speed upgrades from Robux purchases
-- MUST BE IN SERVERSERVICE FOR PROCESSRECEIPT TO WORK

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Wait for PlayerStats module
local PlayerStats = require(script.Parent.Parent.shared.PlayerStats)
-- Wait for PlayerData module
local PlayerData = require(script.Parent.PlayerData)

print("=== SPEED MULTIPLIER HANDLER LOADING ===")
print("Script location:", script:GetFullName())
print("Is in ServerScriptService:", script.Parent.Name == "ServerScriptService")

-- Create remote events for client-server communication
local updateMaxSpeedMultiplierEvent = Instance.new("RemoteEvent")
updateMaxSpeedMultiplierEvent.Name = "UpdateMaxSpeedMultiplier"
updateMaxSpeedMultiplierEvent.Parent = ReplicatedStorage

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

-- Update player's speed multiplier
local function updatePlayerSpeedMultiplier(player, multiplier)
	playerSpeedMultipliers[player.UserId] = multiplier
	print("SpeedMultiplierHandler: Updated speed multiplier for", player.Name, "to", multiplier .. "x")

	-- Update the player's max speed in their stats
	-- This will affect their base max speed calculation
	_G.playerSpeedMultiplier = multiplier

	-- Update the player's maxSpeed stat to reflect the Tier 3 speed with multiplier
	-- This ensures the HUD shows the multiplied Tier 3 max speed
	local stats = PlayerData.getPlayerStats(player)
	print("SpeedMultiplierHandler: Retrieved stats for", player.Name, ":", stats)
	if stats then
		-- Calculate the base max speed (without any previous multipliers)
		local baseMaxSpeed = PlayerStats.getMaxSpeed(stats)
		print("SpeedMultiplierHandler: Base max speed for", player.Name, ":", baseMaxSpeed)

		-- Calculate what the Tier 3 speed should be with the new multiplier
		-- Tier 3 uses the progressed max speed multiplied by the shop multiplier
		local tier3BaseSpeed = baseMaxSpeed
		local tier3MaxSpeed = tier3BaseSpeed * multiplier

		-- Update the maxSpeed stat to reflect the new Tier 3 speed
		stats.maxSpeed = tier3MaxSpeed
		print(
			"Updated player's Tier 3 maxSpeed from",
			baseMaxSpeed,
			"to",
			tier3MaxSpeed,
			"(multiplier:",
			multiplier .. "x)"
		)

		-- Save the updated stats to PlayerData
		PlayerData.updatePlayerStats(player, stats)

		-- Also save the speed shop multiplier separately for persistence
		PlayerData.updateSpeedShopMultiplier(player, multiplier, nil)
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

-- Handle successful Robux purchases
local function processReceipt(receiptInfo)
	print("=== PROCESS RECEIPT CALLED ===")
	print("Receipt Info:", receiptInfo)
	print("Player ID:", receiptInfo.PlayerId)
	print("Product ID:", receiptInfo.ProductId)

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left, but we should still grant the purchase
		print("Player left before purchase could be processed:", receiptInfo.PlayerId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print("Player found:", player.Name)
	local productId = receiptInfo.ProductId
	local currentMultiplier = getPlayerSpeedMultiplier(player)
	print("Current multiplier for", player.Name, ":", currentMultiplier)

	-- Find which multiplier this product ID corresponds to
	print("Looking for product ID:", productId, "in PRODUCT_IDS table")
	for i, id in pairs(PRODUCT_IDS) do
		print("Checking product", i, ":", id)
		if id == productId then
			print("MATCH FOUND! Product", i, "matches ID", productId)

			-- For the 2x boost (index 1), we want to double the current multiplier
			-- For other boosts, we multiply by the boost value
			local newMultiplier
			if i == 1 then
				-- 2x boost: double the current multiplier
				newMultiplier = currentMultiplier * 2
			else
				-- Other boosts: multiply by the boost value
				newMultiplier = currentMultiplier * MULTIPLIERS[i]
			end

			print("Calculated new multiplier:", newMultiplier)
			updatePlayerSpeedMultiplier(player, newMultiplier)

			print("Granted", MULTIPLIERS[i] .. "x speed boost to", player.Name)
			print("New total multiplier:", newMultiplier .. "x")

			-- Notify client of successful purchase
			updateMaxSpeedMultiplierEvent:FireClient(player, newMultiplier)

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	warn("Unknown product ID:", productId, "for player:", player.Name)
	print("Available product IDs:")
	for i, id in pairs(PRODUCT_IDS) do
		print("  [" .. i .. "] = " .. id)
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- CRITICAL: Set up ProcessReceipt BEFORE any purchases are made
print("=== SETTING UP PROCESS RECEIPT ===")
print("Setting up ProcessReceipt function...")
print("Before setting - ProcessReceipt:", MarketplaceService.ProcessReceipt)

-- Set the ProcessReceipt function
MarketplaceService.ProcessReceipt = processReceipt

print("After setting - ProcessReceipt:", MarketplaceService.ProcessReceipt)
print("ProcessReceipt function set up successfully!")
print("ProcessReceipt is now:", MarketplaceService.ProcessReceipt)
print("=== PROCESS RECEIPT SETUP COMPLETE ===")

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerSpeedMultipliers[player.UserId] = nil
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

-- Test command to simulate ProcessReceipt call
local function testProcessReceipt(player)
	print("=== TESTING PROCESS RECEIPT ===")
	if not player then
		player = Players:GetPlayers()[1]
		if not player then
			warn("No players found for test")
			return
		end
	end

	print("Testing with player:", player.Name, "ID:", player.UserId)

	-- Create a fake receipt for testing
	local testReceipt = {
		PlayerId = player.UserId,
		ProductId = PRODUCT_IDS[1], -- Test with 2x speed boost
		PlaceIdWherePurchased = game.PlaceId,
		PurchaseId = "test_" .. tick(),
	}

	print("Test receipt:", testReceipt)

	-- Call ProcessReceipt manually
	local result = processReceipt(testReceipt)
	print("ProcessReceipt result:", result)
	print("=== TEST COMPLETE ===")
end

-- Export functions for other scripts to use
_G.getPlayerSpeedMultiplier = getPlayerSpeedMultiplier
_G.updatePlayerSpeedMultiplier = updatePlayerSpeedMultiplier
_G.debugSpeedShop = debugSpeedShop
_G.testProcessReceipt = testProcessReceipt

print("=== SERVER: SPEED MULTIPLIER HANDLER INITIALIZED ===")
print("Product IDs configured:")
for i, id in pairs(PRODUCT_IDS) do
	print("  [" .. i .. "] = " .. id .. " (" .. MULTIPLIERS[i] .. "x speed)")
end
print("ProcessReceipt function set:", MarketplaceService.ProcessReceipt ~= nil)
print("ProcessReceipt function:", MarketplaceService.ProcessReceipt)
print("Ready to handle purchases!")
print("=== IMPORTANT: USE 'START SERVER' (NOT SINGLE PLAYER) TO TEST ===")

-- Monitor if ProcessReceipt gets changed
spawn(function()
	while true do
		wait(5) -- Check every 5 seconds
		if MarketplaceService.ProcessReceipt ~= processReceipt then
			warn("⚠️ WARNING: ProcessReceipt was changed by another script!")
			print("Current ProcessReceipt:", MarketplaceService.ProcessReceipt)
			print("Our ProcessReceipt:", processReceipt)
			print("Restoring our ProcessReceipt function...")
			MarketplaceService.ProcessReceipt = processReceipt
			print("ProcessReceipt restored!")
		end
	end
end)
