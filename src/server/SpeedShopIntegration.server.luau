-- Speed Shop Integration (Server-side)
-- Simple integration with your existing ProcessPurchases.server.lua
-- This script only handles the RemoteEvent and listens for attribute changes

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== SPEED SHOP INTEGRATION LOADING ===")
print("Script location:", script:GetFullName())

-- Create remote events for client-server communication
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateMaxSpeedMultiplierEvent = Instance.new("RemoteEvent")
updateMaxSpeedMultiplierEvent.Name = "UpdateMaxSpeedMultiplier"
updateMaxSpeedMultiplierEvent.Parent = remotes

print("SpeedShopIntegration: Created UpdateMaxSpeedMultiplier RemoteEvent")

-- Store player speed multipliers (server-side)
local playerSpeedMultipliers = {}
-- Store individual purchases for true stacking
local playerIndividualPurchases = {}

-- Get player's current speed multiplier
local function getPlayerSpeedMultiplier(player)
	return playerSpeedMultipliers[player.UserId] or 1
end

-- Update player's speed multiplier (true stacking system)
local function updatePlayerSpeedMultiplier(player, newMultiplier)
	-- Initialize individual purchases if not exists
	if not playerIndividualPurchases[player.UserId] then
		playerIndividualPurchases[player.UserId] = {}
	end

	-- Get current stacked multiplier
	local currentStackedMultiplier = playerSpeedMultipliers[player.UserId] or 1
	local individualPurchases = playerIndividualPurchases[player.UserId]

	-- ALWAYS add the purchase (allow repetitive purchasing)
	table.insert(individualPurchases, newMultiplier)

	-- Calculate new stacked multiplier by multiplying all individual purchases
	local newStackedMultiplier = 1
	for _, purchase in pairs(individualPurchases) do
		newStackedMultiplier = newStackedMultiplier * purchase
	end

	print("SpeedShopIntegration: NEW PURCHASE DETECTED!")
	print("  New purchase value:", newMultiplier .. "x")
	print("  Previous stacked:", currentStackedMultiplier .. "x")
	print("  Individual purchases:", table.concat(individualPurchases, "x, ") .. "x")
	print("  New stacked multiplier:", newStackedMultiplier .. "x")

	playerSpeedMultipliers[player.UserId] = newStackedMultiplier
	_G.playerSpeedMultiplier = newStackedMultiplier

	-- Fire the RemoteEvent to update the client
	print("SpeedShopIntegration: *** FIRING REMOTEEVENT TO CLIENT ***")
	print("SpeedShopIntegration: Player:", player.Name, "Multiplier:", newStackedMultiplier .. "x")
	updateMaxSpeedMultiplierEvent:FireClient(player, newStackedMultiplier)
	print("SpeedShopIntegration: *** REMOTEEVENT SENT ***")
end

-- Listen for purchases from your existing purchase system
Players.PlayerAdded:Connect(function(player)
	print("SpeedShopIntegration: Player joined -", player.Name, "UserID:", player.UserId)
	print("SpeedShopIntegration: Initial Tier3PermanentMaxMult:", player:GetAttribute("Tier3PermanentMaxMult") or 1)

	-- Listen for changes to the Tier3PermanentMaxMult attribute from your purchase system
	player:GetAttributeChangedSignal("Tier3PermanentMaxMult"):Connect(function()
		local tier3Multiplier = player:GetAttribute("Tier3PermanentMaxMult") or 1
		print("SpeedShopIntegration: *** TIER3 ATTRIBUTE CHANGED *** for", player.Name, ":", tier3Multiplier .. "x")

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

			print("SpeedShopIntegration: Stacked multiplier for", player.Name)
			print("  Previous stacked:", currentStackedMultiplier .. "x")
			print("  New purchase:", newPurchaseMultiplier .. "x")
			print("  Difference:", multiplierDifference .. "x")
			print("  Final stacked:", newStackedMultiplier .. "x")

			-- Update client
			print("SpeedShopIntegration: *** FIRING REMOTEEVENT TO CLIENT ***")
			print("SpeedShopIntegration: Player:", player.Name, "Multiplier:", newStackedMultiplier .. "x")
			updateMaxSpeedMultiplierEvent:FireClient(player, newStackedMultiplier)
			print("SpeedShopIntegration: *** REMOTEEVENT SENT ***")
		end
	end)

	-- Set initial multiplier when player joins
	local initialMultiplier = player:GetAttribute("Tier3PermanentMaxMult") or 1
	if initialMultiplier > 1 then
		print(
			"SpeedShopIntegration: Loading existing Tier3PermanentMaxMult for",
			player.Name,
			":",
			initialMultiplier .. "x"
		)
		playerSpeedMultipliers[player.UserId] = initialMultiplier
		_G.playerSpeedMultiplier = initialMultiplier
		updateMaxSpeedMultiplierEvent:FireClient(player, initialMultiplier)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerSpeedMultipliers[player.UserId] = nil
	playerIndividualPurchases[player.UserId] = nil
end)

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

-- Test command to simulate multiple purchases for stacking
local function testStackingPurchases(player)
	print("=== TESTING STACKING PURCHASES ===")
	if not player then
		player = Players:GetPlayers()[1]
		if not player then
			warn("No players found for test")
			return
		end
	end

	print("Testing stacking with player:", player.Name)

	-- Simulate multiple purchases
	local purchases = { 2, 50, 100, 500 }
	for i, multiplier in ipairs(purchases) do
		print("Purchase", i, ":", multiplier .. "x")
		player:SetAttribute("Tier3PermanentMaxMult", multiplier)
		wait(1) -- Wait between purchases
	end

	print("=== STACKING TEST COMPLETE ===")
end

-- Export functions for testing
_G.testPurchaseAttribute = testPurchaseAttribute
_G.testStackingPurchases = testStackingPurchases

print("=== SPEED SHOP INTEGRATION INITIALIZED ===")
print("RemoteEvent created: UpdateMaxSpeedMultiplier")
print("Listening for Tier3PermanentMaxMult attribute changes")
print("Ready to integrate with your ProcessPurchases.server.lua!")
print("Test with: _G.testPurchaseAttribute()")
