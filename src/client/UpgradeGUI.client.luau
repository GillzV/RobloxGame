local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- GUI elements (will be created in createSpeedDisplay function)
local screenGui = nil
local speedFrame = nil
local speedValue = nil

-- Speed calculation variables
local character = nil
local rootPart = nil
local lastPosition = Vector3.new()
local lastTime = 0
local smoothedSpeed = 0 -- For smooth speed display
local targetSpeed = 0 -- Target speed for smoothing

-- Function to create the speed display GUI
local function createSpeedDisplay()
	-- Clean up existing GUI if it exists
	if screenGui then
		screenGui:Destroy()
	end

	-- Speed display GUI
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpeedDisplay"
	screenGui.ResetOnSpawn = false -- This prevents GUI from being destroyed on respawn
	screenGui.Parent = playerGui

	-- Main speed frame (positioned at bottom center)
	speedFrame = Instance.new("Frame")
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
	speedValue = Instance.new("TextLabel")
	speedValue.Name = "SpeedValue"
	speedValue.Size = UDim2.new(1, -10, 0, 25)
	speedValue.Position = UDim2.new(0, 5, 0, 30)
	speedValue.BackgroundTransparency = 1
	speedValue.Text = "35 mph"
	speedValue.TextColor3 = Color3.fromRGB(0, 200, 255)
	speedValue.TextScaled = true
	speedValue.Font = Enum.Font.Gotham
	speedValue.Parent = speedFrame

	print("Current Speed Display: GUI created successfully")
end

-- Function to initialize speed tracking for a character
local function initializeSpeedTracking(newCharacter)
	character = newCharacter
	rootPart = character:WaitForChild("HumanoidRootPart")
	lastPosition = rootPart.Position
	lastTime = tick()
	smoothedSpeed = 0
	targetSpeed = 0
	print("Current Speed Display: Speed tracking initialized for new character")
end

-- Create speed display initially
createSpeedDisplay()

-- Initialize speed tracking for current character
if player.Character then
	initializeSpeedTracking(player.Character)
end

-- Speed tiers from FlightSystem
local SPEED_TIERS = {
	35, -- Base flight speed (Tier 1)
	70, -- Fast flight speed (Tier 2)
	85, -- Super flight speed (Tier 3)
}

-- Display smoothing and update cadence
local DISPLAY_UPDATE_INTERVAL = 0.2 -- seconds between label updates (reduces flicker)
local lastDisplayUpdate = 0
local lastDisplayedSpeed = nil

local function ceilToStep(value: number, step: number): number
	if step <= 0 then
		return value
	end
	return math.ceil(value / step) * step
end

-- Reset behavior when stopping
local STOP_THRESHOLD = 8 -- baseline stop threshold (units match computed speed)
local STOP_RESET_DELAY = 0.01 -- seconds below threshold before we reset to actual speed
local lastMovingTime = tick()
local prevIsStopped = false

-- Function to update current speed display
local function updateCurrentSpeedDisplay()
	local currentTime = tick()
	local deltaTime = currentTime - lastTime

	if deltaTime > 0 then
		local currentPosition = rootPart.Position
		local distance = (currentPosition - lastPosition).Magnitude
		local rawSpeed = distance / deltaTime

		-- Smooth the speed to prevent glitching (lower factor = more smoothing)
		targetSpeed = rawSpeed
		local smoothingFactor = 0.08
		smoothedSpeed = smoothedSpeed + (targetSpeed - smoothedSpeed) * smoothingFactor

		-- Track moving vs stopped state (dynamic threshold helps quick stop-start cases)
		local effectiveStopThreshold = math.max(STOP_THRESHOLD, (lastDisplayedSpeed or 0) * 0.4)
		if rawSpeed >= effectiveStopThreshold then
			lastMovingTime = currentTime
		end
		local isStopped = (currentTime - lastMovingTime) >= STOP_RESET_DELAY and rawSpeed < effectiveStopThreshold

		-- On transition to stopped, immediately reflect full reset (0) and then re-round on move
		if isStopped and not prevIsStopped then
			-- snap to 0 and push immediate UI update (bypass throttle)
			smoothedSpeed = 0
			targetSpeed = 0
			local displaySpeed = 0
			if displaySpeed ~= lastDisplayedSpeed then
				lastDisplayedSpeed = displaySpeed
				speedValue.Text = tostring(displaySpeed) .. " mph"
				-- Update color based on smoothed speed tier
				speedValue.TextColor3 = Color3.fromRGB(150, 150, 150)
				lastDisplayUpdate = currentTime
			end
		end

		-- When stopped, snap smoothing down faster to reflect current speed
		if isStopped then
			smoothedSpeed = rawSpeed
		end

		-- Throttle UI updates and quantize to reduce flicker at high speeds
		if currentTime - lastDisplayUpdate >= DISPLAY_UPDATE_INTERVAL then
			lastDisplayUpdate = currentTime

			-- Dynamic rounding step by tier (bigger steps at higher speeds)
			local step
			if smoothedSpeed >= SPEED_TIERS[3] then
				step = 25
			elseif smoothedSpeed >= SPEED_TIERS[2] then
				step = 10
			else
				step = 2
			end

			-- Compute display speed
			local displaySpeed
			if isStopped then
				-- When stopped, keep reset value (0)
				displaySpeed = 0
			else
				-- While moving, round upward and prevent decreases
				displaySpeed = ceilToStep(smoothedSpeed, step)
				if lastDisplayedSpeed and displaySpeed < lastDisplayedSpeed then
					displaySpeed = lastDisplayedSpeed
				end
			end
			if displaySpeed ~= lastDisplayedSpeed then
				lastDisplayedSpeed = displaySpeed
				speedValue.Text = tostring(displaySpeed) .. " mph"
				-- Update color based on smoothed speed tier
				if smoothedSpeed >= SPEED_TIERS[3] then
					speedValue.TextColor3 = Color3.fromRGB(255, 100, 0) -- Orange for super speed (Tier 3)
				elseif smoothedSpeed >= SPEED_TIERS[2] then
					speedValue.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow for fast speed (Tier 2)
				elseif smoothedSpeed >= SPEED_TIERS[1] then
					speedValue.TextColor3 = Color3.fromRGB(0, 200, 255) -- Blue for base speed (Tier 1)
				else
					speedValue.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray for walking
				end
			end
		end

		lastPosition = currentPosition
		lastTime = currentTime
		prevIsStopped = isStopped
	end
end

-- Character respawn handling
player.CharacterAdded:Connect(function(newCharacter)
	initializeSpeedTracking(newCharacter)
end)

-- Update current speed display every frame
RunService.Heartbeat:Connect(updateCurrentSpeedDisplay)

print("Current Speed Display GUI loaded successfully!")
