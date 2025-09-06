local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get remote events
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateStatsEvent = remotes:WaitForChild("UpdateStats")

-- Player stats
local playerStats = nil

-- Create HUD GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerHUD"
screenGui.Parent = playerGui

-- Main HUD frame
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUDFrame"
hudFrame.Size = UDim2.new(0, 300, 0, 120)
hudFrame.Position = UDim2.new(0, 10, 0, 10)
hudFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hudFrame.BorderSizePixel = 0
hudFrame.Parent = screenGui

-- Corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = hudFrame

-- Stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 80)
stroke.Thickness = 2
stroke.Parent = hudFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "PLAYER STATS"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = hudFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleLabel

-- Level display
local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(0.5, -5, 0, 25)
levelLabel.Position = UDim2.new(0, 5, 0, 30)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "Level: 1"
levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.GothamBold
levelLabel.Parent = hudFrame

-- Experience display
local expLabel = Instance.new("TextLabel")
expLabel.Name = "ExpLabel"
expLabel.Size = UDim2.new(1, -10, 0, 20)
expLabel.Position = UDim2.new(0, 5, 0, 60)
expLabel.BackgroundTransparency = 1
expLabel.Text = "XP: 0 / 100"
expLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
expLabel.TextScaled = true
expLabel.Font = Enum.Font.Gotham
expLabel.Parent = hudFrame

-- Speed tier display
local speedTierLabel = Instance.new("TextLabel")
speedTierLabel.Name = "SpeedTierLabel"
speedTierLabel.Size = UDim2.new(0.5, -5, 0, 20)
speedTierLabel.Position = UDim2.new(0, 5, 0, 85)
speedTierLabel.BackgroundTransparency = 1
speedTierLabel.Text = "Speed Tiers: 1/3"
speedTierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedTierLabel.TextScaled = true
speedTierLabel.Font = Enum.Font.Gotham
speedTierLabel.Parent = hudFrame

-- Max speed display
local maxSpeedLabel = Instance.new("TextLabel")
maxSpeedLabel.Name = "MaxSpeedLabel"
maxSpeedLabel.Size = UDim2.new(0.5, -5, 0, 20)
maxSpeedLabel.Position = UDim2.new(0.5, 0, 0, 85)
maxSpeedLabel.BackgroundTransparency = 1
maxSpeedLabel.Text = "Max Speed: 35"
maxSpeedLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
maxSpeedLabel.TextScaled = true
maxSpeedLabel.Font = Enum.Font.Gotham
maxSpeedLabel.Parent = hudFrame

-- Speed tiers from FlightSystem (base speeds)
local BASE_SPEED_TIERS = {
	35, -- Base flight speed (Tier 1)
	150, -- Fast flight speed (Tier 2)
	600, -- Super flight speed (Tier 3)
}

-- Function to calculate max speed based on player stats
local function calculateMaxSpeed(stats)
	if not stats then
		return BASE_SPEED_TIERS[1] -- Default to base speed
	end

	-- Get the highest speed tier available
	local maxTier = stats.maxSpeedTier or 1
	local speedMultiplier = stats.speedMultiplier or 1.0

	-- Calculate max speed using the highest available tier
	local baseSpeed = BASE_SPEED_TIERS[maxTier] or BASE_SPEED_TIERS[1]
	local maxSpeed = math.floor(baseSpeed * speedMultiplier)

	return maxSpeed
end

-- Function to update HUD with new stats
local function updateHUD(stats)
	playerStats = stats

	-- Update level
	levelLabel.Text = "Level: " .. stats.level

	-- Update experience
	expLabel.Text = "XP: " .. stats.experience .. " / " .. stats.experienceToNext

	-- Update speed tier display
	speedTierLabel.Text = "Speed Tiers: " .. stats.maxSpeedTier .. "/3"

	-- Update max speed display
	local maxSpeed = calculateMaxSpeed(stats)
	maxSpeedLabel.Text = "Max Speed: " .. maxSpeed
end

-- Listen for stats updates from server
updateStatsEvent.OnClientEvent:Connect(updateHUD)

-- Test function to ensure HUD works
local function testHUD()
	-- Create test stats if server data isn't available
	if not playerStats then
		local testStats = {
			level = 1,
			experience = 25,
			experienceToNext = 100,
			maxSpeedTier = 1,
			speedMultiplier = 1.0,
		}
		updateHUD(testStats)
		print("Using test stats for HUD")
	end
end

-- Run test after a short delay
task.delay(1, testHUD)

print("Player HUD loaded successfully!")
