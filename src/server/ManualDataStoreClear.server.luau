-- Manual DataStore Clear Script
-- Run this to manually clear all your player data

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

print("=== MANUAL DATASTORE CLEAR SCRIPT ===")

-- Get all the DataStores that might contain your data
local dataStores = {
	"PlayerStats",
	"PurchaseHistory_v1",
	"IndividualPurchases_v1",
	"PermanentT3Max_v1",
	"BoostStore",
}

-- Function to clear all DataStores for current player
local function clearAllDataStores()
	local player = Players:GetPlayers()[1] -- Get first player (you)
	if not player then
		warn("No player found!")
		return
	end

	print("Clearing DataStores for player:", player.Name, "UserID:", player.UserId)

	for _, storeName in pairs(dataStores) do
		local success, dataStore = pcall(function()
			return DataStoreService:GetDataStore(storeName)
		end)

		if success then
			-- Try to delete the player's data
			local deleteSuccess = pcall(function()
				dataStore:RemoveAsync(player.UserId)
			end)

			if deleteSuccess then
				print("✅ Cleared DataStore:", storeName)
			else
				print("⚠️ Failed to clear DataStore:", storeName)
			end
		else
			print("⚠️ DataStore doesn't exist:", storeName)
		end
	end

	print("=== DATASTORE CLEAR COMPLETE ===")
end

-- Export function globally
_G.clearAllDataStores = clearAllDataStores

print("Manual DataStore Clear Script loaded!")
print("Run: _G.clearAllDataStores() to clear all your data")
