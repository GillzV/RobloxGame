-- Quick Reset Handler (Server-side)
-- Handles requests to reset all player data

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== QUICK RESET HANDLER LOADING ===")

-- Create or find the reset event
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local resetEvent = remotes:FindFirstChild("ResetPlayerData")
if not resetEvent then
	resetEvent = Instance.new("RemoteEvent")
	resetEvent.Name = "ResetPlayerData"
	resetEvent.Parent = remotes
	print("QuickResetHandler: Created ResetPlayerData RemoteEvent")
end

-- Function to reset all player data
local function resetPlayerData(player)
	print("=== RESETTING DATA FOR PLAYER:", player.Name, "===")

	-- Reset Tier3PermanentMaxMult attribute
	player:SetAttribute("Tier3PermanentMaxMult", 1)
	print("Reset Tier3PermanentMaxMult to 1")

	-- Reset any server-side speed multiplier tracking
	if _G.playerSpeedMultipliers then
		_G.playerSpeedMultipliers[player.UserId] = 1
		print("Reset _G.playerSpeedMultipliers to 1")
	end

	if _G.playerIndividualPurchases then
		_G.playerIndividualPurchases[player.UserId] = {}
		print("Reset _G.playerIndividualPurchases to empty")
	end

	-- Reset player stats in PlayerData if accessible
	local success, PlayerData = pcall(function()
		return require(script.Parent.PlayerData)
	end)

	if success and PlayerData then
		-- Reset speed shop multiplier
		PlayerData.updateSpeedShopMultiplier(player, 1, {})
		print("Reset speed shop multiplier via PlayerData")

		-- Reset player stats to default
		local defaultStats = PlayerData.getDefaultStats()
		if defaultStats then
			PlayerData.updatePlayerStats(player, defaultStats)
			print("Reset player stats to default via PlayerData")
		end
	end

	print("=== RESET COMPLETE FOR:", player.Name, "===")
end

-- Handle reset requests from client
resetEvent.OnServerEvent:Connect(function(player)
	print("QuickResetHandler: Received reset request from:", player.Name)
	resetPlayerData(player)
end)

print("=== QUICK RESET HANDLER INITIALIZED ===")
print("Ready to handle player data reset requests!")
