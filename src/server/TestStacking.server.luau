-- Test script to verify stacking is working correctly
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

print("=== TESTING STACKING SYSTEM ===")

-- Get the same DataStores as ProcessPurchases
local IndividualPurchases = DataStoreService:GetDataStore("IndividualPurchases_v1")

-- Function to test stacking
local function testStacking()
	local player = Players:GetPlayers()[1]
	if not player then
		warn("No player found for test")
		return
	end

	print("Testing stacking with player:", player.Name)

	-- Simulate what ProcessPurchases does
	local function loadIndividualPurchases(userId)
		local key = ("u:%d:purchases"):format(userId)
		local ok, val = pcall(IndividualPurchases.GetAsync, IndividualPurchases, key)
		if ok and typeof(val) == "table" then
			return val
		end
		return {}
	end

	local function saveIndividualPurchases(userId, purchases)
		local key = ("u:%d:purchases"):format(userId)
		pcall(IndividualPurchases.SetAsync, IndividualPurchases, key, purchases)
	end

	local function calculateStackedMultiplier(purchases)
		local stacked = 1
		for _, purchase in pairs(purchases) do
			stacked = stacked * purchase
		end
		return stacked
	end

	-- Get current purchases
	local individualPurchases = loadIndividualPurchases(player.UserId)
	print("Current purchases:", table.concat(individualPurchases, "x, ") .. "x")

	-- Add a 2x purchase
	table.insert(individualPurchases, 2)
	saveIndividualPurchases(player.UserId, individualPurchases)

	-- Calculate new stacked multiplier
	local newStackedMultiplier = calculateStackedMultiplier(individualPurchases)

	print("Added 2x purchase")
	print("All purchases:", table.concat(individualPurchases, "x, ") .. "x")
	print("New stacked multiplier:", newStackedMultiplier .. "x")

	-- Set the attribute
	player:SetAttribute("Tier3PermanentMaxMult", newStackedMultiplier)
	print("Set Tier3PermanentMaxMult to:", newStackedMultiplier)

	print("=== TEST COMPLETE ===")
end

-- Function to check current state
local function checkCurrentState()
	local player = Players:GetPlayers()[1]
	if not player then
		warn("No player found for test")
		return
	end

	print("=== CHECKING CURRENT STATE ===")
	print("Player:", player.Name)
	print("Tier3PermanentMaxMult:", player:GetAttribute("Tier3PermanentMaxMult") or 1)
	print("_G.playerSpeedMultiplier:", _G.playerSpeedMultiplier or "nil")

	-- Check DataStore
	local IndividualPurchases = DataStoreService:GetDataStore("IndividualPurchases_v1")
	local key = ("u:%d:purchases"):format(player.UserId)
	local ok, val = pcall(IndividualPurchases.GetAsync, IndividualPurchases, key)
	if ok and typeof(val) == "table" then
		print("DataStore purchases:", table.concat(val, "x, ") .. "x")
	else
		print("DataStore purchases: empty or error")
	end

	print("=== STATE CHECK COMPLETE ===")
end

-- Export functions globally
_G.testStacking = testStacking
_G.checkCurrentState = checkCurrentState

print("Stacking Test Script loaded!")
print("Run: _G.testStacking() to add a 2x purchase")
print("Run: _G.checkCurrentState() to check current state")
