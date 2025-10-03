-- NEW Stacking Version of ProcessPurchases.server.lua
-- This version supports stacking multipliers instead of only keeping the highest

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
local IndividualPurchases = DataStoreService:GetDataStore("IndividualPurchases_v1") -- tracks individual purchases for stacking

local function loadIndividualPurchases(userId: number): { number }
	local key = ("u:%d:purchases"):format(userId)
	local ok, val = pcall(IndividualPurchases.GetAsync, IndividualPurchases, key)
	if ok and typeof(val) == "table" then
		return val
	end
	return {}
end

local function saveIndividualPurchases(userId: number, purchases: { number })
	local key = ("u:%d:purchases"):format(userId)
	pcall(IndividualPurchases.SetAsync, IndividualPurchases, key, purchases)
end

-- Calculate stacked multiplier from individual purchases
local function calculateStackedMultiplier(purchases: { number }): number
	local stacked = 1
	for _, purchase in pairs(purchases) do
		stacked = stacked * purchase
	end
	return stacked
end

-- Keep individual purchases available for stacking
Players.PlayerAdded:Connect(function(plr)
	local individualPurchases = loadIndividualPurchases(plr.UserId)
	local stackedMultiplier = calculateStackedMultiplier(individualPurchases)

	-- Set the stacked multiplier as the attribute
	plr:SetAttribute("Tier3PermanentMaxMult", stackedMultiplier)

	print("ProcessPurchasesStacking: Loaded purchases for", plr.Name)
	print("  Individual purchases:", table.concat(individualPurchases, ", "))
	print("  Stacked multiplier:", stackedMultiplier .. "x")
end)

Players.PlayerRemoving:Connect(function(plr)
	local individualPurchases = loadIndividualPurchases(plr.UserId)
	saveIndividualPurchases(plr.UserId, individualPurchases)
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

	local newPurchase = PRODUCT_TO_T3_MAX_MULT[receipt.ProductId]
	if not newPurchase then
		warn(("[Purchases] Unmapped product id: %d"):format(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Get current individual purchases
	local individualPurchases = loadIndividualPurchases(player.UserId)

	-- Check if this purchase was already made
	local alreadyPurchased = false
	for _, purchase in pairs(individualPurchases) do
		if purchase == newPurchase then
			alreadyPurchased = true
			break
		end
	end

	-- If not already purchased, add it to the list
	if not alreadyPurchased then
		table.insert(individualPurchases, newPurchase)
		saveIndividualPurchases(player.UserId, individualPurchases)

		-- Calculate new stacked multiplier
		local newStackedMultiplier = calculateStackedMultiplier(individualPurchases)

		-- Update the attribute with the new stacked multiplier
		player:SetAttribute("Tier3PermanentMaxMult", newStackedMultiplier)

		print("ProcessPurchasesStacking: New purchase for", player.Name)
		print("  New purchase:", newPurchase .. "x")
		print("  All purchases:", table.concat(individualPurchases, "x, ") .. "x")
		print("  New stacked multiplier:", newStackedMultiplier .. "x")
	else
		print("ProcessPurchasesStacking: Purchase already made for", player.Name, ":", newPurchase .. "x")
	end

	-- Mark processed
	local okSet = pcall(PurchaseHistory.SetAsync, PurchaseHistory, phKey, true)
	if not okSet then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt

print("ProcessPurchasesStacking: NEW STACKING VERSION LOADED!")
print("This version supports stacking all purchases instead of only keeping the highest")
print("Ready to handle stacking purchases!")
