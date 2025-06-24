local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- Animation setup
local animator = humanoid:WaitForChild("Animator")
local idleFlightAnimation = Instance.new("Animation")
idleFlightAnimation.AnimationId = "rbxassetid://13771876798" -- Hovering animation
local fastFlightAnimation = Instance.new("Animation")
fastFlightAnimation.AnimationId = "rbxassetid://13771890359" -- Superman-style flight
local hyperFlightAnimation = Instance.new("Animation")
hyperFlightAnimation.AnimationId = "rbxassetid://13771901375" -- Intense flight pose

local idleTrack = animator:LoadAnimation(idleFlightAnimation)
local fastTrack = animator:LoadAnimation(fastFlightAnimation)
local hyperTrack = animator:LoadAnimation(hyperFlightAnimation)

-- Flight system variables
local isFlying = false
local speedTier = 0 -- 0: Base, 1: Fast, 2: Super, 3: Hyper
local SPEED_TIERS = {
	100, -- Base flight speed
	300, -- Fast flight speed
	600, -- Super flight speed
	1000, -- Hyper flight speed
}
local currentSpeed = SPEED_TIERS[1]
local currentAnimTrack = nil
local moveDirection = Vector3.new()
local lastMoveDirection = Vector3.new()

-- Visual effects
local function createSonicBoom()
	local boom = Instance.new("Part")
	boom.Shape = Enum.PartType.Ball
	boom.Size = Vector3.new(1, 1, 1)
	boom.Material = Enum.Material.Neon
	boom.Color = Color3.new(1, 1, 1)
	boom.Transparency = 0.5
	boom.CanCollide = false
	boom.CFrame = rootPart.CFrame
	boom.Parent = workspace

	local tween = TweenService:Create(boom, TweenInfo.new(0.3), {
		Size = Vector3.new(20, 20, 20),
		Transparency = 1,
	})
	tween:Play()

	game.Debris:AddItem(boom, 0.3)
end

-- Trail setup with better visuals
local trailAttachment1 = Instance.new("Attachment")
trailAttachment1.Position = Vector3.new(-0.5, 0, 0)
trailAttachment1.Parent = rootPart

local trailAttachment2 = Instance.new("Attachment")
trailAttachment2.Position = Vector3.new(0.5, 0, 0)
trailAttachment2.Parent = rootPart

local trail = Instance.new("Trail")
trail.Attachment0 = trailAttachment1
trail.Attachment1 = trailAttachment2
trail.Lifetime = 0.2
trail.MinLength = 0.1
trail.MaxLength = 20
trail.WidthScale = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0),
})
trail.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 1),
})
trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
trail.Enabled = false
trail.Parent = rootPart

-- Function to update animations based on speed tier
local function updateAnimation()
	if not isFlying then
		if currentAnimTrack then
			currentAnimTrack:Stop()
			currentAnimTrack = nil
		end
		return
	end

	local newTrack
	if speedTier == 0 then
		newTrack = idleTrack
	elseif speedTier == 1 then
		newTrack = fastTrack
	else
		newTrack = hyperTrack
	end

	if currentAnimTrack ~= newTrack then
		if currentAnimTrack then
			currentAnimTrack:Stop()
		end
		newTrack:Play()
		currentAnimTrack = newTrack
	end

	-- Update trail based on speed tier
	trail.Enabled = speedTier > 0
	if speedTier > 0 then
		local speedRatio = speedTier / 3
		trail.MaxLength = 5 + (speedRatio * 15)
		trail.Lifetime = 0.1 + (speedRatio * 0.3)
	end
end

-- Function to handle flying
local function updateFlight(deltaTime)
	if not isFlying then
		return
	end

	-- Get camera direction
	local lookVector = camera.CFrame.LookVector
	local rightVector = camera.CFrame.RightVector
	local upVector = camera.CFrame.UpVector

	-- Calculate movement direction based on input
	moveDirection = Vector3.new()

	-- Forward/Backward
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDirection = moveDirection + lookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDirection = moveDirection - lookVector
	end

	-- Left/Right
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveDirection = moveDirection - rightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveDirection = moveDirection + rightVector
	end

	-- Up/Down
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		moveDirection = moveDirection + upVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		moveDirection = moveDirection - upVector
	end

	-- Normalize and apply speed
	if moveDirection.Magnitude > 0 then
		moveDirection = moveDirection.Unit * SPEED_TIERS[speedTier + 1]
		lastMoveDirection = moveDirection

		-- Smoothly rotate character to face movement direction
		local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDirection)
		rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, deltaTime * 10)
	else
		moveDirection = lastMoveDirection.Unit * SPEED_TIERS[speedTier + 1] * 0.98 -- Slight deceleration when not pressing keys
	end

	-- Apply velocity with some dampening
	rootPart.Velocity = moveDirection
	rootPart.RotVelocity = Vector3.new(0, 0, 0)

	-- Update animations and effects
	updateAnimation()
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.F then
		isFlying = not isFlying

		if isFlying then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			humanoid.PlatformStand = true
			speedTier = 0
			createSonicBoom()
			updateAnimation()
		else
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.PlatformStand = false
			speedTier = 0
			rootPart.Velocity = Vector3.new(0, 0, 0)
			rootPart.RotVelocity = Vector3.new(0, 0, 0)
			trail.Enabled = false
		end
	elseif input.KeyCode == Enum.KeyCode.Q and isFlying then
		-- Increment speed tier and create sonic boom effect
		if speedTier < 3 then
			speedTier = speedTier + 1
			createSonicBoom()
			updateAnimation()
		end
	end
end)

-- Character respawn handling
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	animator = humanoid:WaitForChild("Animator")

	-- Reload animations
	idleTrack = animator:LoadAnimation(idleFlightAnimation)
	fastTrack = animator:LoadAnimation(fastFlightAnimation)
	hyperTrack = animator:LoadAnimation(hyperFlightAnimation)

	-- Reset flight state
	isFlying = false
	speedTier = 0
	currentAnimTrack = nil
	moveDirection = Vector3.new()
	lastMoveDirection = Vector3.new()

	-- Recreate trail
	trailAttachment1 = Instance.new("Attachment")
	trailAttachment1.Position = Vector3.new(-0.5, 0, 0)
	trailAttachment1.Parent = rootPart

	trailAttachment2 = Instance.new("Attachment")
	trailAttachment2.Position = Vector3.new(0.5, 0, 0)
	trailAttachment2.Parent = rootPart

	trail = Instance.new("Trail")
	trail.Attachment0 = trailAttachment1
	trail.Attachment1 = trailAttachment2
	trail.Lifetime = 0.2
	trail.MinLength = 0.1
	trail.MaxLength = 20
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
	trail.Enabled = false
	trail.Parent = rootPart
end)

-- Main flight update loop
RunService.Heartbeat:Connect(function(deltaTime)
	updateFlight(deltaTime)
end)
