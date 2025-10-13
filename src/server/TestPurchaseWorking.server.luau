-- Test to verify purchase system is working
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

print("=== PURCHASE SYSTEM TEST ===")

-- Wait a moment for other scripts to load
wait(2)

-- Check if ProcessReceipt is set
local hasProcessReceipt = MarketplaceService.ProcessReceipt ~= nil
print("ProcessReceipt is set:", hasProcessReceipt)

if hasProcessReceipt then
	print("✅ Purchase system is ready!")

	-- Test function for single purchase
	local function testPurchase()
		local player = Players:GetPlayers()[1]
		if not player then
			warn("No player found for test")
			return
		end

		print("=== TESTING SINGLE PURCHASE ===")
		print("Player:", player.Name)

		-- Create fake receipt
		local fakeReceipt = {
			PlayerId = player.UserId,
			ProductId = 3402098428, -- 2x speed
			PurchaseId = "test_" .. tick(),
			CurrencySpent = 100,
			CurrencyType = Enum.CurrencyType.Robux,
		}

		print("Testing with product ID:", fakeReceipt.ProductId)

		-- Call ProcessReceipt
		local result = MarketplaceService.ProcessReceipt(fakeReceipt)
		print("ProcessReceipt result:", result)

		-- Check attribute
		local attribute = player:GetAttribute("Tier3PermanentMaxMult")
		print("Tier3PermanentMaxMult:", attribute)

		-- Check global variable
		print("_G.playerSpeedMultiplier:", _G.playerSpeedMultiplier)

		print("=== SINGLE PURCHASE TEST COMPLETE ===")
	end

	-- Test function for multiple purchases (stacking)
	local function testStacking()
		local player = Players:GetPlayers()[1]
		if not player then
			warn("No player found for test")
			return
		end

		print("=== TESTING STACKING PURCHASES ===")
		print("Player:", player.Name)

		-- Test multiple 2x purchases
		for i = 1, 4 do
			print("\n--- Purchase", i, "---")

			local fakeReceipt = {
				PlayerId = player.UserId,
				ProductId = 3402098428, -- 2x speed
				PurchaseId = "test_" .. i .. "_" .. tick(),
				CurrencySpent = 100,
				CurrencyType = Enum.CurrencyType.Robux,
			}

			print("Making purchase", i, "with product ID:", fakeReceipt.ProductId)

			-- Call ProcessReceipt
			local result = MarketplaceService.ProcessReceipt(fakeReceipt)
			print("ProcessReceipt result:", result)

			-- Check attribute
			local attribute = player:GetAttribute("Tier3PermanentMaxMult")
			print("Tier3PermanentMaxMult after purchase", i .. ":", attribute)

			-- Expected values: 2x, 4x, 8x, 16x
			local expected = math.pow(2, i)
			print("Expected:", expected .. "x")
			print("Actual:", attribute)
			print("Match:", attribute == expected and "✅" or "❌")
		end

		print("\n=== STACKING TEST COMPLETE ===")
	end

	-- Test function to clear all data
	local function clearData()
		local player = Players:GetPlayers()[1]
		if not player then
			warn("No player found for test")
			return
		end

		print("=== CLEARING ALL DATA ===")

		-- Clear attribute
		player:SetAttribute("Tier3PermanentMaxMult", 1)
		print("Cleared Tier3PermanentMaxMult attribute")

		-- Clear global variable
		_G.playerSpeedMultiplier = 1
		print("Cleared _G.playerSpeedMultiplier")

		-- Clear DataStore (if possible)
		local DataStoreService = game:GetService("DataStoreService")
		local IndividualPurchases = DataStoreService:GetDataStore("IndividualPurchases_v1")
		local key = ("u:%d:purchases"):format(player.UserId)
		pcall(IndividualPurchases.SetAsync, IndividualPurchases, key, {})
		print("Cleared DataStore purchases")

		print("=== DATA CLEARED ===")
	end

	-- Export test functions
	_G.testPurchase = testPurchase
	_G.testStacking = testStacking
	_G.clearData = clearData

	print("=== TEST FUNCTIONS AVAILABLE ===")
	print("_G.testPurchase() - Test single purchase")
	print("_G.testStacking() - Test multiple purchases (stacking)")
	print("_G.clearData() - Clear all purchase data")
	print("=== READY FOR TESTING ===")
else
	print("❌ Purchase system is NOT ready!")
	print("ProcessReceipt is nil")
end
