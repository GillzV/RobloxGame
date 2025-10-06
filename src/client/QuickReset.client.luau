-- Quick Reset Script - Resets all speed multipliers and stats
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

print("=== QUICK RESET SCRIPT LOADED ===")

-- Function to reset all speed data
local function resetAllSpeedData()
	print("=== RESETTING ALL SPEED DATA ===")

	-- Reset client-side globals
	_G.speedMultiplier = 1
	_G.purchasedMultipliers = {}
	_G.playerSpeedMultiplier = 1
	_G.playerPurchasedMultipliers = {}
	_G.speedControlEnabled = false
	_G.desiredSpeed = nil
	_G.currentActualSpeed = 0

	print("Reset client-side globals:")
	print("  _G.speedMultiplier = 1")
	print("  _G.purchasedMultipliers = {}")
	print("  _G.speedControlEnabled = false")

	-- Request server-side reset
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local resetEvent = remotes:FindFirstChild("ResetPlayerData")

	if not resetEvent then
		resetEvent = Instance.new("RemoteEvent")
		resetEvent.Name = "ResetPlayerData"
		resetEvent.Parent = remotes
		print("Created ResetPlayerData RemoteEvent")
	end

	-- Fire reset request to server
	resetEvent:FireServer()
	print("Sent reset request to server")

	-- Reset Tier3PermanentMaxMult attribute (if we can access it)
	if player:GetAttribute("Tier3PermanentMaxMult") then
		player:SetAttribute("Tier3PermanentMaxMult", 1)
		print("Reset Tier3PermanentMaxMult attribute to 1")
	end

	print("=== RESET COMPLETE ===")
	print("All speed multipliers and stats have been reset to default values")
end

-- Export the function globally for easy access
_G.resetAllSpeedData = resetAllSpeedData

-- Auto-reset on script load
resetAllSpeedData()

print("Quick Reset Script ready!")
print("Run: _G.resetAllSpeedData() to reset again")
