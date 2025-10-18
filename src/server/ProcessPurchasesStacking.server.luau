-- Stacking Version of ProcessPurchases.server.lua
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

-- Simple DS retry helpers (handles transient failures)
local function getWithRetry(store, key, maxAttempts: number)
	maxAttempts = maxAttempts or 5
	local attempt = 0
	local backoff = 0.5
	while attempt < maxAttempts do
		attempt += 1
		local ok, value = pcall(store.GetAsync, store, key)
		if ok then
			return true, value
		end
		task.wait(backoff)
		backoff = math.min(backoff * 2, 5)
	end
	return false, nil
end

local function setWithRetry(store, key, value, maxAttempts: number)
	maxAttempts = maxAttempts or 5
	local attempt = 0
	local backoff = 0.5
	while attempt < maxAttempts do
		attempt += 1
		local ok = pcall(store.SetAsync, store, key, value)
		if ok then
			return true
		end
		task.wait(backoff)
		backoff = math.min(backoff * 2, 5)
	end
	return false
end

local function loadIndividualPurchases(userId: number): { number }
	local key = ("u:%d:purchases"):format(userId)
	local ok, val = getWithRetry(IndividualPurchases, key, 5)
	if ok and typeof(val) == "table" then
		return val
	end
	if not ok then
		warn("[Purchases] Failed to load purchases after retries for userId:", userId)
	end
	return {}
end

local function saveIndividualPurchases(userId: number, purchases: { number })
	local key = ("u:%d:purchases"):format(userId)
	local ok = setWithRetry(IndividualPurchases, key, purchases, 5)
	if not ok then
		warn("[Purchases] Failed to save purchases after retries for userId:", userId)
	end
end

-- Calculate stacked multiplier from individual purchases
local function calculateStackedMultiplier(purchases: { number }): number
	local stacked = 1
	print("  Calculating stacked multiplier from purchases:", table.concat(purchases, ", "))
	for _, purchase in pairs(purchases) do
		print("    Multiplying", stacked .. "x by", purchase .. "x =", (stacked * purchase) .. "x")
		stacked = stacked * purchase
	end
	print("  Final stacked multiplier:", stacked .. "x")
	return stacked
end

-- Keep individual purchases available for stacking
Players.PlayerAdded:Connect(function(plr)
	-- Attempt to load immediately, then also re-check shortly after join in case of transient DS issues
	local function loadAndApply()
		local purchases = loadIndividualPurchases(plr.UserId)
		local stacked = calculateStackedMultiplier(purchases)
		plr:SetAttribute("Tier3PermanentMaxMult", stacked)
		print("ProcessPurchasesStacking: Loaded purchases for", plr.Name)
		print("  Individual purchases:", #purchases > 0 and table.concat(purchases, ", ") or "<none>")
		print("  Stacked multiplier:", stacked .. "x")
	end

	loadAndApply()
	-- Delayed second attempt to improve reliability when DS is slow
	task.delay(3, function()
		if plr.Parent then
			loadAndApply()
		end
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	local individualPurchases = loadIndividualPurchases(plr.UserId)
	saveIndividualPurchases(plr.UserId, individualPurchases)
end)

-- REQUIRED for Developer Products
local function processReceipt(receipt)
	-- Idempotency: "PlayerId_PurchaseId"
	local phKey = ("%d_%s"):format(receipt.PlayerId, receipt.PurchaseId)
	local okGet, done = getWithRetry(PurchaseHistory, phKey, 5)
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
	print("ProcessPurchasesStacking: BEFORE PURCHASE")
	print("  Current purchases:", table.concat(individualPurchases, ", "))
	print("  New purchase to add:", newPurchase .. "x")

	-- ALWAYS add the purchase (allow repetitive purchasing for stacking)
	table.insert(individualPurchases, newPurchase)
	saveIndividualPurchases(player.UserId, individualPurchases)

	-- Calculate new stacked multiplier
	local newStackedMultiplier = calculateStackedMultiplier(individualPurchases)

	-- Update the attribute with the new stacked multiplier
	player:SetAttribute("Tier3PermanentMaxMult", newStackedMultiplier)

	print("ProcessPurchasesStacking: PURCHASE COMPLETE for", player.Name)
	print("  Added purchase:", newPurchase .. "x")
	print("  All purchases now:", table.concat(individualPurchases, "x, ") .. "x")
	print("  Final stacked multiplier:", newStackedMultiplier .. "x")
	print("  Attribute set to:", player:GetAttribute("Tier3PermanentMaxMult"))

	-- Mark processed
	local okSet = setWithRetry(PurchaseHistory, phKey, true, 5)
	if not okSet then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt

print("ProcessPurchasesStacking: Stacking purchase system loaded!")
print("This version supports stacking all purchases instead of only keeping the highest")
