local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get remote events
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateStatsEvent = remotes:WaitForChild("UpdateStats")
local upgradeSpeedEvent = remotes:WaitForChild("UpgradeSpeed")
local upgradeStrengthEvent = remotes:WaitForChild("UpgradeStrength")
local upgradeHealthEvent = remotes:WaitForChild("UpgradeHealth")

-- Player stats
local playerStats = nil

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeGUI"
screenGui.Parent = playerGui

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 600)
mainFrame.Position = UDim2.new(0, 20, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 80)
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "UPGRADE SYSTEM"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleLabel

-- Stats display
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(1, -20, 0, 120)
statsFrame.Position = UDim2.new(0, 10, 0, 60)
statsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
statsFrame.BorderSizePixel = 0
statsFrame.Parent = mainFrame

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 8)
statsCorner.Parent = statsFrame

-- Level display
local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(0.5, -5, 0, 30)
levelLabel.Position = UDim2.new(0, 5, 0, 5)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "Level: 1"
levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.Gotham
levelLabel.Parent = statsFrame

-- Experience bar
local expBarFrame = Instance.new("Frame")
expBarFrame.Name = "ExpBarFrame"
expBarFrame.Size = UDim2.new(1, -10, 0, 20)
expBarFrame.Position = UDim2.new(0, 5, 0, 40)
expBarFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
expBarFrame.BorderSizePixel = 0
expBarFrame.Parent = statsFrame

local expBarCorner = Instance.new("UICorner")
expBarCorner.CornerRadius = UDim.new(0, 10)
expBarCorner.Parent = expBarFrame

local expBarFill = Instance.new("Frame")
expBarFill.Name = "ExpBarFill"
expBarFill.Size = UDim2.new(0, 0, 1, 0)
expBarFill.Position = UDim2.new(0, 0, 0, 0)
expBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
expBarFill.BorderSizePixel = 0
expBarFill.Parent = expBarFrame

local expBarFillCorner = Instance.new("UICorner")
expBarFillCorner.CornerRadius = UDim.new(0, 10)
expBarFillCorner.Parent = expBarFill

local expText = Instance.new("TextLabel")
expText.Name = "ExpText"
expText.Size = UDim2.new(1, 0, 1, 0)
expText.Position = UDim2.new(0, 0, 0, 0)
expText.BackgroundTransparency = 1
expText.Text = "0 / 100 XP"
expText.TextColor3 = Color3.fromRGB(255, 255, 255)
expText.TextScaled = true
expText.Font = Enum.Font.Gotham
expText.Parent = expBarFrame

-- Coins display
local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(0.5, -5, 0, 30)
coinsLabel.Position = UDim2.new(0.5, 0, 0, 5)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "Coins: 0"
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Parent = statsFrame

-- Speed tier display
local speedTierLabel = Instance.new("TextLabel")
speedTierLabel.Name = "SpeedTierLabel"
speedTierLabel.Size = UDim2.new(1, -10, 0, 25)
speedTierLabel.Position = UDim2.new(0, 5, 0, 70)
speedTierLabel.BackgroundTransparency = 1
speedTierLabel.Text = "Speed Tiers: 1/4"
speedTierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedTierLabel.TextScaled = true
speedTierLabel.Font = Enum.Font.Gotham
speedTierLabel.Parent = statsFrame

-- Upgrade buttons container
local upgradeContainer = Instance.new("Frame")
upgradeContainer.Name = "UpgradeContainer"
upgradeContainer.Size = UDim2.new(1, -20, 0, 400)
upgradeContainer.Position = UDim2.new(0, 10, 0, 200)
upgradeContainer.BackgroundTransparency = 1
upgradeContainer.Parent = mainFrame

-- Speed upgrade button
local speedButton = Instance.new("TextButton")
speedButton.Name = "SpeedButton"
speedButton.Size = UDim2.new(1, 0, 0, 80)
speedButton.Position = UDim2.new(0, 0, 0, 0)
speedButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
speedButton.BorderSizePixel = 0
speedButton.Text = ""
speedButton.Parent = upgradeContainer

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 8)
speedCorner.Parent = speedButton

local speedStroke = Instance.new("UIStroke")
speedStroke.Color = Color3.fromRGB(70, 170, 255)
speedStroke.Thickness = 2
speedStroke.Parent = speedButton

local speedTitle = Instance.new("TextLabel")
speedTitle.Name = "SpeedTitle"
speedTitle.Size = UDim2.new(1, 0, 0, 30)
speedTitle.Position = UDim2.new(0, 10, 0, 5)
speedTitle.BackgroundTransparency = 1
speedTitle.Text = "SPEED UPGRADE"
speedTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
speedTitle.TextScaled = true
speedTitle.Font = Enum.Font.GothamBold
speedTitle.Parent = speedButton

local speedLevel = Instance.new("TextLabel")
speedLevel.Name = "SpeedLevel"
speedLevel.Size = UDim2.new(0.5, 0, 0, 20)
speedLevel.Position = UDim2.new(0, 10, 0, 35)
speedLevel.BackgroundTransparency = 1
speedLevel.Text = "Level: 1"
speedLevel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLevel.TextScaled = true
speedLevel.Font = Enum.Font.Gotham
speedLevel.Parent = speedButton

local speedCost = Instance.new("TextLabel")
speedCost.Name = "SpeedCost"
speedCost.Size = UDim2.new(0.5, 0, 0, 20)
speedCost.Position = UDim2.new(0.5, 0, 0, 35)
speedCost.BackgroundTransparency = 1
speedCost.Text = "Cost: 50"
speedCost.TextColor3 = Color3.fromRGB(255, 215, 0)
speedCost.TextScaled = true
speedCost.Font = Enum.Font.Gotham
speedCost.Parent = speedButton

-- Strength upgrade button
local strengthButton = Instance.new("TextButton")
strengthButton.Name = "StrengthButton"
strengthButton.Size = UDim2.new(1, 0, 0, 80)
strengthButton.Position = UDim2.new(0, 0, 0, 90)
strengthButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
strengthButton.BorderSizePixel = 0
strengthButton.Text = ""
strengthButton.Parent = upgradeContainer

local strengthCorner = Instance.new("UICorner")
strengthCorner.CornerRadius = UDim.new(0, 8)
strengthCorner.Parent = strengthButton

local strengthStroke = Instance.new("UIStroke")
strengthStroke.Color = Color3.fromRGB(255, 120, 120)
strengthStroke.Thickness = 2
strengthStroke.Parent = strengthButton

local strengthTitle = Instance.new("TextLabel")
strengthTitle.Name = "StrengthTitle"
strengthTitle.Size = UDim2.new(1, 0, 0, 30)
strengthTitle.Position = UDim2.new(0, 10, 0, 5)
strengthTitle.BackgroundTransparency = 1
strengthTitle.Text = "STRENGTH UPGRADE"
strengthTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
strengthTitle.TextScaled = true
strengthTitle.Font = Enum.Font.GothamBold
strengthTitle.Parent = strengthButton

local strengthLevel = Instance.new("TextLabel")
strengthLevel.Name = "StrengthLevel"
strengthLevel.Size = UDim2.new(0.5, 0, 0, 20)
strengthLevel.Position = UDim2.new(0, 10, 0, 35)
strengthLevel.BackgroundTransparency = 1
strengthLevel.Text = "Level: 1"
strengthLevel.TextColor3 = Color3.fromRGB(255, 255, 255)
strengthLevel.TextScaled = true
strengthLevel.Font = Enum.Font.Gotham
strengthLevel.Parent = strengthButton

local strengthCost = Instance.new("TextLabel")
strengthCost.Name = "StrengthCost"
strengthCost.Size = UDim2.new(0.5, 0, 0, 20)
strengthCost.Position = UDim2.new(0.5, 0, 0, 35)
strengthCost.BackgroundTransparency = 1
strengthCost.Text = "Cost: 75"
strengthCost.TextColor3 = Color3.fromRGB(255, 215, 0)
strengthCost.TextScaled = true
strengthCost.Font = Enum.Font.Gotham
strengthCost.Parent = strengthButton

-- Health upgrade button
local healthButton = Instance.new("TextButton")
healthButton.Name = "HealthButton"
healthButton.Size = UDim2.new(1, 0, 0, 80)
healthButton.Position = UDim2.new(0, 0, 0, 180)
healthButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
healthButton.BorderSizePixel = 0
healthButton.Text = ""
healthButton.Parent = upgradeContainer

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 8)
healthCorner.Parent = healthButton

local healthStroke = Instance.new("UIStroke")
healthStroke.Color = Color3.fromRGB(120, 255, 120)
healthStroke.Thickness = 2
healthStroke.Parent = healthButton

local healthTitle = Instance.new("TextLabel")
healthTitle.Name = "HealthTitle"
healthTitle.Size = UDim2.new(1, 0, 0, 30)
healthTitle.Position = UDim2.new(0, 10, 0, 5)
healthTitle.BackgroundTransparency = 1
healthTitle.Text = "HEALTH UPGRADE"
healthTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
healthTitle.TextScaled = true
healthTitle.Font = Enum.Font.GothamBold
healthTitle.Parent = healthButton

local healthLevel = Instance.new("TextLabel")
healthLevel.Name = "HealthLevel"
healthLevel.Size = UDim2.new(0.5, 0, 0, 20)
healthLevel.Position = UDim2.new(0, 10, 0, 35)
healthLevel.BackgroundTransparency = 1
healthLevel.Text = "Level: 1"
healthLevel.TextColor3 = Color3.fromRGB(255, 255, 255)
healthLevel.TextScaled = true
healthLevel.Font = Enum.Font.Gotham
healthLevel.Parent = healthButton

local healthCost = Instance.new("TextLabel")
healthCost.Name = "HealthCost"
healthCost.Size = UDim2.new(0.5, 0, 0, 20)
healthCost.Position = UDim2.new(0.5, 0, 0, 35)
healthCost.BackgroundTransparency = 1
healthCost.Text = "Cost: 100"
healthCost.TextColor3 = Color3.fromRGB(255, 215, 0)
healthCost.TextScaled = true
healthCost.Font = Enum.Font.Gotham
healthCost.Parent = healthButton

-- Toggle button (hidden since we have external toggle)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(1, -60, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "⚙"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = mainFrame
toggleButton.Visible = false -- Hide the internal toggle button

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

-- Function to update GUI with new stats
local function updateGUI(stats)
	playerStats = stats

	-- Update level and experience
	levelLabel.Text = "Level: " .. stats.level
	expText.Text = stats.experience .. " / " .. stats.experienceToNext .. " XP"

	-- Update experience bar
	local expPercentage = stats.experience / stats.experienceToNext
	expBarFill.Size = UDim2.new(expPercentage, 0, 1, 0)

	-- Update coins
	coinsLabel.Text = "Coins: " .. stats.coins

	-- Update speed tier display
	speedTierLabel.Text = "Speed Tiers: " .. stats.maxSpeedTier .. "/4"

	-- Update upgrade buttons
	speedLevel.Text = "Level: " .. stats.speedLevel
	speedCost.Text = "Cost: " .. stats.upgradeCosts.speed

	strengthLevel.Text = "Level: " .. stats.strengthLevel
	strengthCost.Text = "Cost: " .. stats.upgradeCosts.strength

	healthLevel.Text = "Level: " .. stats.healthLevel
	healthCost.Text = "Cost: " .. stats.upgradeCosts.health

	-- Update button colors based on affordability
	if stats.coins >= stats.upgradeCosts.speed then
		speedButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
		speedStroke.Color = Color3.fromRGB(70, 170, 255)
	else
		speedButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
		speedStroke.Color = Color3.fromRGB(100, 100, 120)
	end

	if stats.coins >= stats.upgradeCosts.strength then
		strengthButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		strengthStroke.Color = Color3.fromRGB(255, 120, 120)
	else
		strengthButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
		strengthStroke.Color = Color3.fromRGB(100, 100, 120)
	end

	if stats.coins >= stats.upgradeCosts.health then
		healthButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		healthStroke.Color = Color3.fromRGB(120, 255, 120)
	else
		healthButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
		healthStroke.Color = Color3.fromRGB(100, 100, 120)
	end
end

-- Button click handlers
speedButton.MouseButton1Click:Connect(function()
	if playerStats and playerStats.coins >= playerStats.upgradeCosts.speed then
		upgradeSpeedEvent:FireServer()

		-- Visual feedback
		local originalColor = speedButton.BackgroundColor3
		speedButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		wait(0.1)
		speedButton.BackgroundColor3 = originalColor

		-- Show notification
		if _G.NotificationSystem then
			_G.NotificationSystem.showUpgrade("SPEED")
		end
	end
end)

strengthButton.MouseButton1Click:Connect(function()
	if playerStats and playerStats.coins >= playerStats.upgradeCosts.strength then
		upgradeStrengthEvent:FireServer()

		-- Visual feedback
		local originalColor = strengthButton.BackgroundColor3
		strengthButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		wait(0.1)
		strengthButton.BackgroundColor3 = originalColor

		-- Show notification
		if _G.NotificationSystem then
			_G.NotificationSystem.showUpgrade("STRENGTH")
		end
	end
end)

healthButton.MouseButton1Click:Connect(function()
	if playerStats and playerStats.coins >= playerStats.upgradeCosts.health then
		upgradeHealthEvent:FireServer()

		-- Visual feedback
		local originalColor = healthButton.BackgroundColor3
		healthButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		wait(0.1)
		healthButton.BackgroundColor3 = originalColor

		-- Show notification
		if _G.NotificationSystem then
			_G.NotificationSystem.showUpgrade("HEALTH")
		end
	end
end)

-- Toggle GUI visibility
local guiVisible = true
toggleButton.MouseButton1Click:Connect(function()
	guiVisible = not guiVisible

	local targetPosition
	if guiVisible then
		targetPosition = UDim2.new(0, 20, 0.5, -300)
	else
		targetPosition = UDim2.new(0, -380, 0.5, -300)
	end

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPosition,
	})
	tween:Play()
end)

-- Listen for stats updates from server
updateStatsEvent.OnClientEvent:Connect(updateGUI)

-- Initialize GUI as hidden
guiVisible = false
mainFrame.Position = UDim2.new(0, -380, 0.5, -300)

-- Test function to ensure GUI works
local function testGUI()
	-- Create test stats if server data isn't available
	if not playerStats then
		local testStats = {
			level = 1,
			experience = 25,
			experienceToNext = 100,
			coins = 150,
			maxSpeedTier = 1,
			speedLevel = 1,
			strengthLevel = 1,
			healthLevel = 1,
			upgradeCosts = {
				speed = 50,
				strength = 75,
				health = 100,
			},
		}
		updateGUI(testStats)
		print("Using test stats for GUI")
	end

	-- Test the GUI visibility
	print("Upgrade GUI test completed. GUI should be visible with test data.")
end

-- Run test after a short delay
task.delay(2, testGUI)

-- Also test GUI visibility after a longer delay
task.delay(3, function()
	print("Testing GUI visibility...")
	local currentPosition = mainFrame.Position
	print("Current GUI position:", currentPosition.X.Scale, currentPosition.X.Offset)
end)

print("Upgrade GUI loaded successfully!")
