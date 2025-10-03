-- Speed Multiplier GUI
-- Allows permanent max speed upgrades via GUI buttons (Robux purchases)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local _UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Speed multiplier values (these would be your Robux product IDs)
local MULTIPLIERS = {
	[1] = 2, -- 2x speed
	[2] = 50, -- 50x speed
	[3] = 100, -- 100x speed
	[4] = 500, -- 500x speed
}

local BUTTON_LABELS = {
	[1] = "2x Speed",
	[2] = "50x Speed",
	[3] = "100x Speed",
	[4] = "500x Speed",
}

-- Product IDs for Robux purchases (replace with your actual product IDs from Roblox Studio)
-- IMPORTANT: You must create these products in Roblox Studio under Game Settings > Monetization > Developer Products
local PRODUCT_IDS = {
	[1] = 3402098428, -- Replace with your actual product ID for 2x speed
	[2] = 3402098905, -- Replace with your actual product ID for 50x speed
	[3] = 3402099389, -- Replace with your actual product ID for 100x speed
	[4] = 3402099684, -- Replace with your actual product ID for 500x speed
}

-- GUI variables
local totalSpeedMultiplier = 1
local purchasedMultipliers = {} -- Track all purchased multipliers

-- Test mode toggle (set to true to enable test mode even on live servers)
local TEST_MODE = false -- Set to true to enable test purchases on live servers

-- Forward declare functions
local activateSpeedMultiplier
local updateGUI
local createStudioPurchaseDialog
local onStudioPurchaseSuccess

-- Activate speed multiplier (purchase/stack multiplier)
activateSpeedMultiplier = function(multiplierIndex)
	print("=== CLIENT: PURCHASE BUTTON CLICKED ===")
	print("Multiplier index:", multiplierIndex)
	local multiplier = MULTIPLIERS[multiplierIndex]
	print("Multiplier value:", multiplier)
	print("Current speed multiplier:", _G.speedMultiplier or "nil")
	print("Is Studio mode:", game:GetService("RunService"):IsStudio())
	print("Is Server mode:", game:GetService("RunService"):IsServer())
	print("TEST_MODE:", TEST_MODE)
	print("Players count:", #game:GetService("Players"):GetPlayers())

	-- Only use fake GUI in test mode (not in Studio server mode)
	if TEST_MODE then
		print("Test mode: Creating simulated purchase prompt for", multiplier .. "x speed boost")
		print("Note: Using test simulation instead of real purchase")

		-- Create a simulated purchase dialog
		createStudioPurchaseDialog(multiplierIndex, multiplier)
		return
	end

	-- Live server: Prompt real Robux purchase
	local productId = PRODUCT_IDS[multiplierIndex]
	print("Product ID for index", multiplierIndex, ":", productId)

	if productId and productId > 0 then
		print("=== CLIENT: STARTING REAL PURCHASE ===")
		print("Prompting purchase for", multiplier .. "x speed boost")
		print("Product ID:", productId)
		print("Player:", player.Name, "UserID:", player.UserId)
		print("MarketplaceService available:", MarketplaceService ~= nil)

		-- Trigger the Robux purchase flow
		print("Calling MarketplaceService:PromptProductPurchase...")
		local success, error = pcall(function()
			MarketplaceService:PromptProductPurchase(player, productId)
		end)

		if success then
			print("✅ Purchase prompt sent successfully!")
			print("⏳ Waiting for ProcessReceipt to be called on server...")
			print("📝 If you don't see server messages, the ProcessReceipt isn't working")
		else
			warn("❌ Failed to prompt purchase:", error)
		end
	else
		warn("❌ No valid product ID found for multiplier index:", multiplierIndex, "Product ID:", productId)
		print("Available PRODUCT_IDS:")
		for i, id in pairs(PRODUCT_IDS) do
			print("  [" .. i .. "] = " .. id)
		end
		print("Please create a Developer Product in Studio and update the PRODUCT_IDS table with the real product ID")
	end
end

-- Update GUI appearance and status
updateGUI = function()
	if not _G.SpeedMultiplierGUI then
		return
	end

	local screenGui = _G.SpeedMultiplierGUI
	local frame = screenGui:FindFirstChild("MainFrame")
	if not frame then
		return
	end

	local buttons = {}
	for i = 1, 4 do
		buttons[i] = frame:FindFirstChild("Button" .. i)
	end
	local statusLabel = frame:FindFirstChild("StatusLabel")

	-- Update button colors and text based on purchased state
	for i = 1, 4 do
		local button = buttons[i]
		if button then
			local purchaseCount = purchasedMultipliers[i] or 0
			if purchaseCount > 0 then
				-- Purchased button (green) - show purchase count
				button.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
				button.TextColor3 = Color3.new(0, 0, 0)
				button.Text = BUTTON_LABELS[i] .. " (x" .. purchaseCount .. ")"
			else
				-- Not purchased button
				button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
				button.TextColor3 = Color3.new(1, 1, 1)
				button.Text = BUTTON_LABELS[i]
			end
		end
	end

	-- Update status text
	if statusLabel then
		if totalSpeedMultiplier > 1 then
			statusLabel.Text = "Total: " .. totalSpeedMultiplier .. "x Speed"
			statusLabel.TextColor3 = Color3.new(0.2, 0.8, 0.2)
		else
			statusLabel.Text = "Click to Purchase with Robux"
			statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		end
	end
end

-- Create main GUI
local function createGUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpeedMultiplierGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 200, 0, 220)
	frame.Position = UDim2.new(1, -210, 1, -230) -- Bottom right
	frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0.3, 0.3, 0.3)
	stroke.Thickness = 2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Speed Shop"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Create buttons
	local buttons = {}
	for i = 1, 4 do
		local button = Instance.new("TextButton")
		button.Name = "Button" .. i
		button.Size = UDim2.new(1, -20, 0, 35)
		button.Position = UDim2.new(0, 10, 0, 40 + (i - 1) * 40)
		button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		button.Text = BUTTON_LABELS[i]
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.Gotham
		button.Parent = frame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = button

		local buttonStroke = Instance.new("UIStroke")
		buttonStroke.Color = Color3.new(0.4, 0.4, 0.4)
		buttonStroke.Thickness = 1
		buttonStroke.Parent = button

		-- Button hover effects
		button.MouseEnter:Connect(function()
			if not purchasedMultipliers[i] then
				local tween = TweenService:Create(button, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
				})
				tween:Play()
			end
		end)

		button.MouseLeave:Connect(function()
			if not purchasedMultipliers[i] then
				local tween = TweenService:Create(button, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.new(0.2, 0.2, 0.2),
				})
				tween:Play()
			end
		end)

		-- Button click
		button.MouseButton1Click:Connect(function()
			print("Button clicked for multiplier index:", i)
			activateSpeedMultiplier(i)
		end)

		buttons[i] = button
	end

	-- Status display
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -20, 0, 25)
	statusLabel.Position = UDim2.new(0, 10, 0, 190)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Purchase Speed Boosts (Stack Multipliers)"
	statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = frame

	return screenGui, buttons, statusLabel
end

-- Create simulated purchase dialog for Studio testing
createStudioPurchaseDialog = function(multiplierIndex, multiplier)
	local productId = PRODUCT_IDS[multiplierIndex]
	print("Studio: Creating purchase dialog for Product ID:", productId)

	-- Create a simulated purchase dialog
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StudioPurchaseDialog"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = game:GetService("Players").LocalPlayer.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 400, 0, 250)
	frame.Position = UDim2.new(0.5, -200, 0.5, -125)
	frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0.3, 0.3, 0.3)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	title.BorderSizePixel = 0
	title.Text = "Buy Item"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = title

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -20, 0, 60)
	desc.Position = UDim2.new(0, 10, 0, 50)
	desc.BackgroundTransparency = 1
	desc.Text = "Would you like to buy '" .. multiplier .. "x Speed Boost'?\n\n(This is a test purchase)"
	desc.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	desc.TextScaled = true
	desc.Font = Enum.Font.Gotham
	desc.Parent = frame

	-- Cancel button
	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0, 120, 0, 40)
	cancelButton.Position = UDim2.new(0, 20, 1, -60)
	cancelButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "Cancel"
	cancelButton.TextColor3 = Color3.new(1, 1, 1)
	cancelButton.TextScaled = true
	cancelButton.Font = Enum.Font.Gotham
	cancelButton.Parent = frame

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 6)
	cancelCorner.Parent = cancelButton

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 120, 0, 40)
	buyButton.Position = UDim2.new(1, -140, 1, -60)
	buyButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
	buyButton.BorderSizePixel = 0
	buyButton.Text = "Buy (Test)"
	buyButton.TextColor3 = Color3.new(0, 0, 0)
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = frame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyButton

	-- Button events
	cancelButton.MouseButton1Click:Connect(function()
		print("Studio: Purchase cancelled")
		screenGui:Destroy()
	end)

	buyButton.MouseButton1Click:Connect(function()
		print("Studio: Purchase confirmed")
		screenGui:Destroy()

		-- Simulate purchase processing delay
		spawn(function()
			wait(0.5) -- Simulate processing time
			onStudioPurchaseSuccess(multiplierIndex)
		end)
	end)
end

-- Handle Studio purchase simulation
onStudioPurchaseSuccess = function(multiplierIndex)
	local multiplier = MULTIPLIERS[multiplierIndex]
	print("Studio: Processing successful purchase for", multiplier .. "x speed boost")

	-- Add this multiplier to purchased list
	if not purchasedMultipliers[multiplierIndex] then
		purchasedMultipliers[multiplierIndex] = 0
	end
	purchasedMultipliers[multiplierIndex] = purchasedMultipliers[multiplierIndex] + 1

	-- Calculate total multiplier
	totalSpeedMultiplier = 1
	for index, count in pairs(purchasedMultipliers) do
		for _ = 1, count do
			-- For the 2x boost (index 1), we want to double the current multiplier
			-- For other boosts, we multiply by the boost value
			if index == 1 then
				totalSpeedMultiplier = totalSpeedMultiplier * 2
			else
				totalSpeedMultiplier = totalSpeedMultiplier * MULTIPLIERS[index]
			end
		end
	end

	-- Set global speed multiplier
	_G.speedMultiplier = totalSpeedMultiplier

	print("Studio: Speed multiplier activated:", multiplier .. "x")
	print("Studio: Total speed multiplier:", totalSpeedMultiplier .. "x")

	-- Update GUI
	updateGUI()

	-- Notify the server to update the player's max speed
	local updateEvent = game:GetService("ReplicatedStorage"):WaitForChild("UpdateMaxSpeedMultiplier")
	updateEvent:FireServer(totalSpeedMultiplier)

	print("Studio: Notified server of speed multiplier:", totalSpeedMultiplier .. "x")
end

-- Handle real purchase success (from server confirmation)
local function onRealPurchaseSuccess(stackedMultiplier)
	print("=== CLIENT: PURCHASE SUCCESS RECEIVED ===")
	print("Total stacked multiplier from server:", stackedMultiplier .. "x")
	print("Previous multiplier:", _G.speedMultiplier or "nil")

	-- Update our local multiplier with the total stacked value
	_G.speedMultiplier = stackedMultiplier
	totalSpeedMultiplier = stackedMultiplier

	print("Updated local multiplier to:", stackedMultiplier .. "x")

	-- Update GUI
	updateGUI()
	print("GUI updated with new multiplier")
end

-- Handle server sending loaded speed shop data
local function onServerLoadSpeedShopData(newMultiplier)
	print("Server loaded speed shop data - multiplier:", newMultiplier .. "x")

	-- Update our local multiplier
	_G.speedMultiplier = newMultiplier
	totalSpeedMultiplier = newMultiplier

	-- Update GUI
	updateGUI()
end

-- Initialize GUI
local function initialize()
	local screenGui, _buttons, _statusLabel = createGUI()

	-- Store reference globally
	_G.SpeedMultiplierGUI = screenGui
	_G.speedMultiplier = 1
	_G.purchasedMultipliers = purchasedMultipliers

	-- Listen for server purchase confirmations and loaded data
	local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
	local updateEvent = remotes:WaitForChild("UpdateMaxSpeedMultiplier")
	updateEvent.OnClientEvent:Connect(function(newMultiplier)
		-- This handles both new purchases and loaded data from DataStore
		print("Received speed multiplier update from server:", newMultiplier .. "x")
		onRealPurchaseSuccess(newMultiplier)
	end)

	-- Start update loop
	game:GetService("RunService").Heartbeat:Connect(function()
		updateGUI()
	end)

	print("Speed Multiplier GUI initialized")
end

-- Re-enabled for testing - you can disable this when you create your custom GUI

-- Initialize when player spawns
if player.Character and player.Character:FindFirstChild("Humanoid") then
	initialize()
else
	player.CharacterAdded:Connect(function()
		initialize()
	end)
end

print("SpeedMultiplierGUI: ENABLED - You can test speed shop purchases now")
