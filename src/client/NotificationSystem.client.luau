local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create notification GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationSystem"
screenGui.Parent = playerGui

-- Function to create a notification
local function createNotification(message, color, duration)
	duration = duration or 3

	-- Create notification frame
	local notification = Instance.new("Frame")
	notification.Size = UDim2.new(0, 300, 0, 50)
	notification.Position = UDim2.new(0.5, -150, 0, -60)
	notification.BackgroundColor3 = color or Color3.fromRGB(40, 40, 60)
	notification.BorderSizePixel = 0
	notification.Parent = screenGui

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification

	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 100)
	stroke.Thickness = 2
	stroke.Parent = notification

	-- Text label
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -20, 1, 0)
	textLabel.Position = UDim2.new(0, 10, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = notification

	-- Animate in
	local tweenIn =
		TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -150, 0, 20),
		})
	tweenIn:Play()

	-- Animate out after duration
	task.delay(duration, function()
		local tweenOut =
			TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -150, 0, -60),
			})
		tweenOut:Play()

		-- Remove after animation
		tweenOut.Completed:Connect(function()
			notification:Destroy()
		end)
	end)
end

-- Function to show XP gain notification
local function showXPNotification(amount)
	createNotification("+" .. amount .. " XP", Color3.fromRGB(0, 200, 255), 2)
end

-- Function to show coin gain notification
local function showCoinNotification(amount)
	createNotification("+" .. amount .. " Coins", Color3.fromRGB(255, 215, 0), 2)
end

-- Function to show level up notification
local function showLevelUpNotification(level)
	createNotification("LEVEL UP! Level " .. level, Color3.fromRGB(255, 100, 255), 4)
end

-- Function to show upgrade notification
local function showUpgradeNotification(upgradeType)
	createNotification(upgradeType .. " UPGRADED!", Color3.fromRGB(100, 255, 100), 3)
end

-- Export functions for other scripts to use
local NotificationSystem = {
	showXP = showXPNotification,
	showCoins = showCoinNotification,
	showLevelUp = showLevelUpNotification,
	showUpgrade = showUpgradeNotification,
	showNotification = createNotification,
}

-- Make it globally accessible
_G.NotificationSystem = NotificationSystem

print("Notification system loaded successfully!")
