-- Fix Purchase Stacking - This will override your current ProcessPurchases system
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

print("=== FIXING PURCHASE STACKING ===")

-- Your product IDs
local PRODUCT_TO_MULT = {
	[3402098428] = 2, -- 2x speed
	[3402098905] = 50, -- 50x speed
	[3402099389] = 100, -- 100x speed
	[3402099684] = 500, -- 500x speed
}

-- DataStores
local PurchaseHistory = DataStoreService:GetDataStore("PurchaseHistory_v1")
local IndividualPurchases = DataStoreService:GetDataStore("IndividualPurchases_v1")

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

local function calculateStackedMultiplier(purchases: { number }): number
	local stacked = 1
	for _, purchase in pairs(purchases) do
		stacked = stacked * purchase
	end
	return stacked
end

-- Load existing purchases when player joins
Players.PlayerAdded:Connect(function(plr)
	local individualPurchases = loadIndividualPurchases(plr.UserId)
	local stackedMultiplier = calculateStackedMultiplier(individualPurchases)

	plr:SetAttribute("Tier3PermanentMaxMult", stackedMultiplier)

	print("FIXED: Loaded purchases for", plr.Name)
	print("  Individual purchases:", table.concat(individualPurchases, ", "))
	print("  Stacked multiplier:", stackedMultiplier .. "x")
end)

Players.PlayerRemoving:Connect(function(plr)
	local individualPurchases = loadIndividualPurchases(plr.UserId)
	saveIndividualPurchases(plr.UserId, individualPurchases)
end)

-- Override ProcessReceipt to support stacking
local function processReceipt(receipt)
	print("=== PROCESS RECEIPT CALLED (FIXED VERSION) ===")
	print("Receipt Info:", receipt)

	-- Idempotency check
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

	local newPurchase = PRODUCT_TO_MULT[receipt.ProductId]
	if not newPurchase then
		warn("Unknown product ID:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Get current purchases and add the new one
	local individualPurchases = loadIndividualPurchases(player.UserId)
	table.insert(individualPurchases, newPurchase)
	saveIndividualPurchases(player.UserId, individualPurchases)

	-- Calculate new stacked multiplier
	local newStackedMultiplier = calculateStackedMultiplier(individualPurchases)

	-- Update the attribute
	player:SetAttribute("Tier3PermanentMaxMult", newStackedMultiplier)

	print("FIXED: NEW PURCHASE for", player.Name)
	print("  New purchase:", newPurchase .. "x")
	print("  All purchases:", table.concat(individualPurchases, "x, ") .. "x")
	print("  New stacked multiplier:", newStackedMultiplier .. "x")

	-- Mark as processed
	local okSet = pcall(PurchaseHistory.SetAsync, PurchaseHistory, phKey, true)
	if not okSet then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- OVERRIDE the ProcessReceipt function
MarketplaceService.ProcessReceipt = processReceipt

print("=== PURCHASE STACKING FIXED ===")
print("ProcessReceipt has been overridden to support stacking!")
print("Now when you purchase boosts, they will stack multiplicatively!")

-- Test function to simulate a purchase
local function testStackingPurchase(player)
	if not player then
		player = Players:GetPlayers()[1]
		if not player then
			warn("No players found for test")
			return
		end
	end

	print("=== TESTING STACKING PURCHASE ===")
	local currentValue = player:GetAttribute("Tier3PermanentMaxMult") or 1
	print("Current multiplier:", currentValue .. "x")

	-- Simulate a 2x purchase
	local fakeReceipt = {
		PlayerId = player.UserId,
		ProductId = 3402098428, -- 2x speed product
		PlaceIdWherePurchased = game.PlaceId,
		PurchaseId = "test_" .. tick(),
	}

	print("Simulating 2x purchase...")
	local result = processReceipt(fakeReceipt)
	print("Purchase result:", result)

	local newValue = player:GetAttribute("Tier3PermanentMaxMult")
	print("New multiplier:", newValue .. "x")
	print("=== TEST COMPLETE ===")
end

_G.testStackingPurchase = testStackingPurchase

print("Test with: _G.testStackingPurchase()")
