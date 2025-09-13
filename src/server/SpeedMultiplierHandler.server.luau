-- Speed Multiplier Handler (Server-side)
-- Handles permanent max speed upgrades from Robux purchases

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Wait for PlayerStats module
local PlayerStats = require(script.Parent.Parent.shared.PlayerStats)

-- Create remote events for client-server communication
local updateMaxSpeedMultiplierEvent = Instance.new("RemoteEvent")
updateMaxSpeedMultiplierEvent.Name = "UpdateMaxSpeedMultiplier"
updateMaxSpeedMultiplierEvent.Parent = ReplicatedStorage

-- Store player speed multipliers (server-side)
local playerSpeedMultipliers = {}

-- Product IDs for Robux purchases (must match client-side)
local PRODUCT_IDS = {
	[1] = 123456789, -- Replace with your actual product ID for 2x speed
	[2] = 123456790, -- Replace with your actual product ID for 50x speed
	[3] = 123456791, -- Replace with your actual product ID for 100x speed
	[4] = 123456792, -- Replace with your actual product ID for 500x speed
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
	print("Updated speed multiplier for", player.Name, "to", multiplier .. "x")

	-- Update the player's max speed in their stats
	-- This will affect their base max speed calculation
	_G.playerSpeedMultiplier = multiplier
end

-- Handle client requests to update max speed multiplier
updateMaxSpeedMultiplierEvent.OnServerEvent:Connect(function(player, multiplier)
	-- Verify the multiplier is valid
	if type(multiplier) == "number" and multiplier >= 1 then
		updatePlayerSpeedMultiplier(player, multiplier)
	else
		warn("Invalid speed multiplier received from", player.Name, ":", multiplier)
	end
end)

-- Handle successful Robux purchases
local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left, but we should still grant the purchase
		print("Player left before purchase could be processed:", receiptInfo.PlayerId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local currentMultiplier = getPlayerSpeedMultiplier(player)

	-- Find which multiplier this product ID corresponds to
	for i, id in pairs(PRODUCT_IDS) do
		if id == productId then
			local newMultiplier = currentMultiplier * MULTIPLIERS[i]
			updatePlayerSpeedMultiplier(player, newMultiplier)

			print("Granted", MULTIPLIERS[i] .. "x speed boost to", player.Name)
			print("New total multiplier:", newMultiplier .. "x")

			-- Notify client of successful purchase
			updateMaxSpeedMultiplierEvent:FireClient(player, newMultiplier)

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	warn("Unknown product ID:", productId, "for player:", player.Name)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Set up the receipt processor
MarketplaceService.ProcessReceipt = processReceipt

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerSpeedMultipliers[player.UserId] = nil
end)

-- Export functions for other scripts to use
_G.getPlayerSpeedMultiplier = getPlayerSpeedMultiplier
_G.updatePlayerSpeedMultiplier = updatePlayerSpeedMultiplier

print("Speed Multiplier Handler initialized")
