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

-- GUI elements (will be created in createHUD function)
local screenGui = nil
local hudFrame = nil
local maxSpeedLabel = nil

-- Function to create the HUD GUI
local function createHUD()
	-- Clean up existing GUI if it exists
	if screenGui then
		screenGui:Destroy()
	end

	-- Create HUD GUI
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PlayerHUD"
	screenGui.ResetOnSpawn = false -- This prevents GUI from being destroyed on respawn
	screenGui.Parent = playerGui

	-- Main HUD frame
	hudFrame = Instance.new("Frame")
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
	maxSpeedLabel = Instance.new("TextLabel")
	maxSpeedLabel.Name = "MaxSpeedLabel"
	maxSpeedLabel.Size = UDim2.new(1, -10, 0, 30)
	maxSpeedLabel.Position = UDim2.new(0, 5, 0, 30)
	maxSpeedLabel.BackgroundTransparency = 1
	maxSpeedLabel.Text = "Max Speed: Loading..."
	maxSpeedLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	maxSpeedLabel.TextScaled = true
	maxSpeedLabel.Font = Enum.Font.GothamBold
	maxSpeedLabel.Parent = hudFrame

	print("PlayerHUD: GUI created successfully")
end

-- Create HUD initially
createHUD()

-- Function to update HUD with new stats
local function updateHUD(stats)
	playerStats = stats

	-- Calculate the actual fastest Tier 3 speed (base max speed + speed boosts + speed shop multiplier)
	-- Remove the cap so it shows your actual current highest possible speed
	local baseMaxSpeed = stats.maxSpeed or HUD_CONFIG.BASE_SPEED

	-- Apply speed shop multiplier if available
	local speedShopMultiplier = _G.speedMultiplier or 1
	local multipliedMaxSpeed = baseMaxSpeed * speedShopMultiplier

	-- Apply Tier 3 speed boost multiplier (this is your actual fastest speed)
	local tier3BoostMultiplier = 1 + HUD_CONFIG.MAX_SPEED_BOOSTS * HUD_CONFIG.SPEED_BOOST_MULTIPLIER
	local fastestTier3Speed = multipliedMaxSpeed * tier3BoostMultiplier

	-- Show your actual current highest possible speed (no cap)
	maxSpeedLabel.Text = "Max Speed: " .. math.floor(fastestTier3Speed) .. " (Tier 3)"
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

-- Function to calculate and display current highest speed
local function calculateAndDisplayCurrentMaxSpeed()
	if not playerStats then
		-- Use default stats if server data isn't available yet
		local defaultStats = {
			maxSpeed = HUD_CONFIG.BASE_SPEED,
			flightTime = 0,
		}
		updateHUD(defaultStats)
	end
end

-- Calculate initial max speed display
calculateAndDisplayCurrentMaxSpeed()

-- Update max speed whenever speed shop multiplier changes
local lastKnownMultiplier = 1
game:GetService("RunService").Heartbeat:Connect(function()
	local currentMultiplier = _G.speedMultiplier or 1
	if currentMultiplier ~= lastKnownMultiplier then
		lastKnownMultiplier = currentMultiplier
		calculateAndDisplayCurrentMaxSpeed()
	end
end)

print("Player HUD loaded successfully!")
