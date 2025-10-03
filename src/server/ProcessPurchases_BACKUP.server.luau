-- BACKUP of your original ProcessPurchases.server.lua
-- This is your original script saved as backup

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

-- === YOUR Developer Product IDs ===
local PROD_T3_2X = 3402098428
local PROD_T3_50X = 3402098905
local PROD_T3_100X = 3402099389
local PROD_T3_500X = 3402099684

-- Map product -> target Tier-3 max multiplier
local PRODUCT_TO_T3_MAX_MULT = {
	[PROD_T3_2X] = 2,
	[PROD_T3_50X] = 50,
	[PROD_T3_100X] = 100,
	[PROD_T3_500X] = 500,
}

-- DataStores
local PurchaseHistory = DataStoreService:GetDataStore("PurchaseHistory_v1") -- idempotency only
local BoostStore = DataStoreService:GetDataStore("PermanentT3Max_v1") -- saves the best T3 max

local function loadT3Max(userId: number): number
	local key = ("u:%d:t3max"):format(userId)
	local ok, val = pcall(BoostStore.GetAsync, BoostStore, key)
	if ok and typeof(val) == "number" then
		return val
	end
	return 1
end

local function saveT3Max(userId: number, mult: number)
	local key = ("u:%d:t3max"):format(userId)
	pcall(BoostStore.SetAsync, BoostStore, key, mult)
end

-- Keep attribute available for your speed code
Players.PlayerAdded:Connect(function(plr)
	plr:SetAttribute("Tier3PermanentMaxMult", loadT3Max(plr.UserId))
end)

Players.PlayerRemoving:Connect(function(plr)
	saveT3Max(plr.UserId, plr:GetAttribute("Tier3PermanentMaxMult") or 1)
end)

-- REQUIRED for Developer Products
local function processReceipt(receipt)
	-- Idempotency: "PlayerId_PurchaseId"
	local phKey = ("%d_%s"):format(receipt.PlayerId, receipt.PurchaseId)
	local okGet, done = pcall(PurchaseHistory.GetAsync, PurchaseHistory, phKey)
	if not okGet then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if done then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local newMax = PRODUCT_TO_T3_MAX_MULT[receipt.ProductId]
	if not newMax then
		warn(("[Purchases] Unmapped product id: %d"):format(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Keep the BEST (highest) permanent Tier-3 max ever bought
	local current = player:GetAttribute("Tier3PermanentMaxMult") or loadT3Max(player.UserId)
	if newMax > current then
		player:SetAttribute("Tier3PermanentMaxMult", newMax)
		saveT3Max(player.UserId, newMax)
	end

	-- Mark processed
	local okSet = pcall(PurchaseHistory.SetAsync, PurchaseHistory, phKey, true)
	if not okSet then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt

print("BACKUP: Original ProcessPurchases script (non-stacking version)")
