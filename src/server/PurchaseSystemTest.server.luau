-- Test your ProcessPurchases.server.lua system
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

print("=== TESTING PURCHASE SYSTEM ===")

-- Check if your ProcessPurchases.server.lua is working
local function testPurchaseSystem()
	print("=== PURCHASE SYSTEM TEST ===")

	-- Check ProcessReceipt (we can't read it directly, only set it)
	-- Instead, let's check if we can find your ProcessPurchases script
	print("Checking if ProcessPurchases script exists...")

	-- Check if we can find your script
	local serverScriptService = game:GetService("ServerScriptService")

	-- Look for ProcessPurchases script (it might be named differently)
	local processPurchasesScript = serverScriptService:FindFirstChild("ProcessPurchases")
		or serverScriptService:FindFirstChild("ProcessPurchases.server.lua")
		or serverScriptService:FindFirstChild("ProcessPurchases.server")

	if not processPurchasesScript then
		print("❌ ERROR: ProcessPurchases script not found in ServerScriptService!")
		print("Available scripts in ServerScriptService:")
		for _, child in pairs(serverScriptService:GetChildren()) do
			if child:IsA("Script") or child:IsA("LocalScript") then
				print("  -", child.Name, "(" .. child.ClassName .. ")")
			end
		end
		print("Make sure your purchase script is in ServerScriptService and is a Server Script")
		return false
	end

	print("✅ ProcessPurchases script found:", processPurchasesScript.Name)
	print("✅ Script type:", processPurchasesScript.ClassName)

	-- Test with a fake receipt
	local testPlayer = Players:GetPlayers()[1]
	if not testPlayer then
		print("❌ No players found for test")
		return false
	end

	print("Testing with player:", testPlayer.Name)

	-- Create fake receipt
	local testReceipt = {
		PlayerId = testPlayer.UserId,
		ProductId = 3402098428, -- Your 2x speed product ID
		PlaceIdWherePurchased = game.PlaceId,
		PurchaseId = "test_" .. tick(),
	}

	print("Fake receipt:", testReceipt)

	-- Call ProcessReceipt
	print("Calling ProcessReceipt...")
	local result = MarketplaceService.ProcessReceipt(testReceipt)
	print("ProcessReceipt result:", result)

	-- Check if attribute was set
	local newAttribute = testPlayer:GetAttribute("Tier3PermanentMaxMult")
	print("Tier3PermanentMaxMult after test:", newAttribute)

	if newAttribute and newAttribute > 1 then
		print("✅ Purchase system is working!")
		return true
	else
		print("❌ Purchase system failed - attribute not set")
		return false
	end
end

-- Simple test that simulates a purchase to see if your system responds
local function testPurchaseResponse()
	print("=== TESTING PURCHASE RESPONSE ===")

	local testPlayer = Players:GetPlayers()[1]
	if not testPlayer then
		print("❌ No players found for test")
		return
	end

	print("Testing with player:", testPlayer.Name)
	local currentValue = testPlayer:GetAttribute("Tier3PermanentMaxMult") or 1
	print("Current Tier3PermanentMaxMult:", currentValue)

	-- Use a higher value to trigger the attribute change (since SpeedShopIntegration only responds to higher values)
	local newValue = currentValue < 100 and 100 or currentValue * 2
	print("Simulating purchase by setting Tier3PermanentMaxMult to", newValue .. "...")
	testPlayer:SetAttribute("Tier3PermanentMaxMult", newValue)

	print("New Tier3PermanentMaxMult:", testPlayer:GetAttribute("Tier3PermanentMaxMult"))
	print("=== TEST COMPLETE ===")
	print("If your SpeedShopIntegration is working, you should see stacking messages above")
end

-- Export test functions
_G.testPurchaseSystem = testPurchaseSystem
_G.testPurchaseResponse = testPurchaseResponse

print("=== PURCHASE SYSTEM TEST READY ===")
print("Run: _G.testPurchaseSystem() to check script location")
print("Run: _G.testPurchaseResponse() to test purchase response")
