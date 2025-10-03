-- Purchase Debugger - Check if ProcessPurchases.server.lua is working
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

print("=== PURCHASE DEBUGGER LOADED ===")

-- Check if ProcessReceipt is set
print("MarketplaceService.ProcessReceipt:", MarketplaceService.ProcessReceipt)
print("ProcessReceipt type:", type(MarketplaceService.ProcessReceipt))

-- Monitor ProcessReceipt calls
local originalProcessReceipt = MarketplaceService.ProcessReceipt
if originalProcessReceipt then
	print("ProcessReceipt is set - monitoring calls...")

	-- Create a wrapper to monitor calls
	local function monitoredProcessReceipt(receiptInfo)
		print("=== PROCESS RECEIPT CALLED ===")
		print("Receipt Info:", receiptInfo)
		print("Player ID:", receiptInfo.PlayerId)
		print("Product ID:", receiptInfo.ProductId)

		-- Call the original ProcessReceipt
		local result = originalProcessReceipt(receiptInfo)
		print("ProcessReceipt result:", result)
		print("=== PROCESS RECEIPT COMPLETE ===")

		return result
	end

	-- Set our monitored version
	MarketplaceService.ProcessReceipt = monitoredProcessReceipt
	print("ProcessReceipt monitoring enabled!")
else
	print("WARNING: ProcessReceipt is NOT set!")
	print("Your ProcessPurchases.server.lua might not be running!")
end

-- Monitor player attributes
Players.PlayerAdded:Connect(function(player)
	print("Player joined -", player.Name, "UserID:", player.UserId)
	print("Initial Tier3PermanentMaxMult:", player:GetAttribute("Tier3PermanentMaxMult") or 1)

	-- Listen for attribute changes
	player:GetAttributeChangedSignal("Tier3PermanentMaxMult"):Connect(function()
		local newValue = player:GetAttribute("Tier3PermanentMaxMult")
		print("*** TIER3 ATTRIBUTE CHANGED ***")
		print("Player:", player.Name)
		print("New value:", newValue)
	end)
end)

-- Test function to simulate a purchase
local function simulatePurchase(player)
	print("=== SIMULATING PURCHASE ===")
	if not player then
		player = Players:GetPlayers()[1]
		if not player then
			warn("No players found for test")
			return
		end
	end

	print("Simulating purchase for:", player.Name)
	print("Current Tier3PermanentMaxMult:", player:GetAttribute("Tier3PermanentMaxMult") or 1)

	-- Set attribute to simulate purchase
	player:SetAttribute("Tier3PermanentMaxMult", 2)

	print("New Tier3PermanentMaxMult:", player:GetAttribute("Tier3PermanentMaxMult"))
	print("=== SIMULATION COMPLETE ===")
end

-- Export test function
_G.simulatePurchase = simulatePurchase

print("=== PURCHASE DEBUGGER READY ===")
print("Test with: _G.simulatePurchase()")
