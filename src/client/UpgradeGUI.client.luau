local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Speed display GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedDisplay"
screenGui.Parent = playerGui

-- Main speed frame (positioned at bottom center)
local speedFrame = Instance.new("Frame")
speedFrame.Name = "SpeedFrame"
speedFrame.Size = UDim2.new(0, 200, 0, 60)
speedFrame.Position = UDim2.new(0.5, -100, 1, -80)
speedFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
speedFrame.BorderSizePixel = 0
speedFrame.Parent = screenGui

-- Corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = speedFrame

-- Stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(50, 50, 70)
stroke.Thickness = 2
stroke.Parent = speedFrame

-- Speed label
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(1, -10, 0, 25)
speedLabel.Position = UDim2.new(0, 5, 0, 5)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "CURRENT SPEED"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Parent = speedFrame

-- Speed value
local speedValue = Instance.new("TextLabel")
speedValue.Name = "SpeedValue"
speedValue.Size = UDim2.new(1, -10, 0, 25)
speedValue.Position = UDim2.new(0, 5, 0, 30)
speedValue.BackgroundTransparency = 1
speedValue.Text = "35 studs/s"
speedValue.TextColor3 = Color3.fromRGB(0, 200, 255)
speedValue.TextScaled = true
speedValue.Font = Enum.Font.Gotham
speedValue.Parent = speedFrame

-- Speed calculation variables
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local lastPosition = rootPart.Position
local lastTime = tick()

-- Speed tiers from FlightSystem
local SPEED_TIERS = {
	35, -- Base flight speed (Tier 1)
	150, -- Fast flight speed (Tier 2)
	600, -- Super flight speed (Tier 3)
}

-- Function to update current speed display
local function updateCurrentSpeedDisplay()
	local currentTime = tick()
	local deltaTime = currentTime - lastTime

	if deltaTime > 0 then
		local currentPosition = rootPart.Position
		local distance = (currentPosition - lastPosition).Magnitude
		local speed = distance / deltaTime

		-- Update speed display
		speedValue.Text = math.floor(speed) .. " studs/s"

		-- Update color based on speed tier
		if speed >= SPEED_TIERS[3] then
			speedValue.TextColor3 = Color3.fromRGB(255, 100, 0) -- Orange for super speed (Tier 3)
		elseif speed >= SPEED_TIERS[2] then
			speedValue.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow for fast speed (Tier 2)
		elseif speed >= SPEED_TIERS[1] then
			speedValue.TextColor3 = Color3.fromRGB(0, 200, 255) -- Blue for base speed (Tier 1)
		else
			speedValue.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray for walking
		end

		lastPosition = currentPosition
		lastTime = currentTime
	end
end

-- Character respawn handling
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	rootPart = character:WaitForChild("HumanoidRootPart")
	lastPosition = rootPart.Position
	lastTime = tick()
end)

-- Update current speed display every frame
RunService.Heartbeat:Connect(updateCurrentSpeedDisplay)

print("Current Speed Display GUI loaded successfully!")
