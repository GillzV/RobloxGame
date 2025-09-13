-- Speed Multiplier GUI
-- Allows permanent max speed upgrades via GUI buttons (Robux purchases)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
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

-- Product IDs for Robux purchases (you'll need to set these up in Roblox)
local PRODUCT_IDS = {
	[1] = 3402098428, -- Replace with your actual product ID for 2x speed
	[2] = 3402098905, -- Replace with your actual product ID for 50x speed
	[3] = 3402099389, -- Replace with your actual product ID for 100x speed
	[4] = 3402099684, -- Replace with your actual product ID for 500x speed
}

-- GUI variables
local totalSpeedMultiplier = 1
local purchasedMultipliers = {} -- Track all purchased multipliers

-- Forward declare functions
local activateSpeedMultiplier
local updateGUI

-- Activate speed multiplier (purchase/stack multiplier)
activateSpeedMultiplier = function(multiplierIndex)
	local multiplier = MULTIPLIERS[multiplierIndex]

	-- Check if already purchased
	if purchasedMultipliers[multiplierIndex] then
		print("Speed multiplier already purchased:", multiplier .. "x")
		return
	end

	-- Prompt Robux purchase
	local productId = PRODUCT_IDS[multiplierIndex]
	if productId then
		print("Prompting purchase for", multiplier .. "x speed boost (Product ID:", productId .. ")")
		-- This would trigger the Robux purchase flow
		MarketplaceService:PromptProductPurchase(player, productId)
	else
		-- For testing without Robux integration
		print("TESTING: Simulating purchase of", multiplier .. "x speed boost")
		simulatePurchase(multiplierIndex)
	end
end

-- Simulate purchase for testing (remove this when you have real Robux integration)
local function simulatePurchase(multiplierIndex)
	local multiplier = MULTIPLIERS[multiplierIndex]

	-- Add this multiplier to purchased list (stackable)
	purchasedMultipliers[multiplierIndex] = true

	-- Calculate total multiplier by multiplying all purchased multipliers
	totalSpeedMultiplier = 1
	for index, _ in pairs(purchasedMultipliers) do
		totalSpeedMultiplier = totalSpeedMultiplier * MULTIPLIERS[index]
	end

	-- Set global speed multiplier permanently
	_G.speedMultiplier = totalSpeedMultiplier

	print("Speed multiplier purchased:", multiplier .. "x")
	print("Total speed multiplier:", totalSpeedMultiplier .. "x (stacked)")

	-- Update GUI
	updateGUI()

	-- Notify the server to update the player's max speed
	local updateEvent = game:GetService("ReplicatedStorage"):WaitForChild("UpdateMaxSpeedMultiplier")
	updateEvent:FireServer(totalSpeedMultiplier)
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

	-- Update button colors based on purchased state
	for i = 1, 4 do
		local button = buttons[i]
		if button then
			if purchasedMultipliers[i] then
				-- Purchased button (green)
				button.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
				button.TextColor3 = Color3.new(0, 0, 0)
			else
				-- Not purchased button
				button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
				button.TextColor3 = Color3.new(1, 1, 1)
			end
		end
	end

	-- Update status text
	if statusLabel then
		if totalSpeedMultiplier > 1 then
			statusLabel.Text = "Total: " .. totalSpeedMultiplier .. "x Speed"
			statusLabel.TextColor3 = Color3.new(0.2, 0.8, 0.2)
		else
			statusLabel.Text = "Purchase Speed Boosts"
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
	statusLabel.Text = "Purchase Speed Boosts"
	statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = frame

	return screenGui, buttons, statusLabel
end

-- Handle successful Robux purchases
local function onPurchaseSuccess(receiptInfo)
	print("Purchase successful:", receiptInfo)
	-- You would need to implement server-side verification here
	-- For now, we'll simulate the purchase
	local productId = receiptInfo.ProductId

	-- Find which multiplier this product ID corresponds to
	for i, id in pairs(PRODUCT_IDS) do
		if id == productId then
			simulatePurchase(i)
			break
		end
	end
end

-- Handle failed Robux purchases
local function onPurchaseFailure(errorMessage)
	print("Purchase failed:", errorMessage)
end

-- Initialize GUI
local function initialize()
	local screenGui, buttons, statusLabel = createGUI()

	-- Store reference globally
	_G.SpeedMultiplierGUI = screenGui
	_G.speedMultiplier = 1
	_G.purchasedMultipliers = purchasedMultipliers

	-- Set up purchase callbacks
	MarketplaceService.ProcessReceipt = onPurchaseSuccess

	-- Start update loop
	game:GetService("RunService").Heartbeat:Connect(function()
		updateGUI()
	end)

	print("Speed Multiplier GUI initialized")
end

-- Initialize when player spawns
if player.Character and player.Character:FindFirstChild("Humanoid") then
	initialize()
else
	player.CharacterAdded:Connect(function()
		initialize()
	end)
end
