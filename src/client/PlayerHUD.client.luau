local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===== CONFIGURABLE HUD SETTINGS =====
local HUD_CONFIG = {
	BASE_SPEED = 35, -- Starting max speed (should match PlayerStats)
	MAX_SPEED_CAP = 1000, -- Maximum possible speed (should match PlayerStats)
	SPEED_BOOST_MULTIPLIER = 0.5, -- Speed boost per Q press (should match FlightSystem)
	MAX_SPEED_BOOSTS = 2, -- Maximum number of speed boosts (should match FlightSystem)
}
-- =====================================

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
hudFrame.Size = UDim2.new(0, 300, 0, 60)
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

-- Max speed display
local maxSpeedLabel = Instance.new("TextLabel")
maxSpeedLabel.Name = "MaxSpeedLabel"
maxSpeedLabel.Size = UDim2.new(1, -10, 0, 30)
maxSpeedLabel.Position = UDim2.new(0, 5, 0, 30)
maxSpeedLabel.BackgroundTransparency = 1
maxSpeedLabel.Text = "Max Speed: " .. HUD_CONFIG.BASE_SPEED
maxSpeedLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
maxSpeedLabel.TextScaled = true
maxSpeedLabel.Font = Enum.Font.GothamBold
maxSpeedLabel.Parent = hudFrame

-- Function to update HUD with new stats
local function updateHUD(stats)
	playerStats = stats

	-- Calculate the maximum possible tier 3 speed
	local baseMaxSpeed = math.min(stats.maxSpeed or HUD_CONFIG.BASE_SPEED, HUD_CONFIG.MAX_SPEED_CAP)
	local tier3BoostMultiplier = 1 + HUD_CONFIG.MAX_SPEED_BOOSTS * HUD_CONFIG.SPEED_BOOST_MULTIPLIER
	local maxTier3Speed = baseMaxSpeed * tier3BoostMultiplier

	-- Apply speed shop multiplier if available (only affects Tier 3)
	local speedShopMultiplier = _G.speedMultiplier or 1
	maxTier3Speed = maxTier3Speed * speedShopMultiplier

	local cappedTier3Speed = math.min(maxTier3Speed, HUD_CONFIG.MAX_SPEED_CAP)

	maxSpeedLabel.Text = "Max Speed: " .. math.floor(cappedTier3Speed) .. " (Tier 3)"
end

-- Listen for stats updates from server
updateStatsEvent.OnClientEvent:Connect(updateHUD)

-- Listen for speed shop multiplier updates
local function updateHUDFromSpeedShop()
	if playerStats then
		updateHUD(playerStats)
	end
end

-- Monitor for speed shop multiplier changes
game:GetService("RunService").Heartbeat:Connect(function()
	local currentMultiplier = _G.speedMultiplier or 1
	if _G.lastSpeedShopMultiplier ~= currentMultiplier then
		_G.lastSpeedShopMultiplier = currentMultiplier
		updateHUDFromSpeedShop()
	end
end)

-- Test function to ensure HUD works
local function testHUD()
	-- Create test stats if server data isn't available
	if not playerStats then
		local testStats = {
			maxSpeed = HUD_CONFIG.BASE_SPEED,
			flightTime = 0,
		}
		updateHUD(testStats)
		print("Using test stats for HUD")
	end
end

-- Run test after a short delay
task.delay(1, testHUD)

print("Player HUD loaded successfully!")
