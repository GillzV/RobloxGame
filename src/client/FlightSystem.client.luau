local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- Animation setup
local animator = humanoid:WaitForChild("Animator")
local idleFlightAnimation = Instance.new("Animation")
idleFlightAnimation.AnimationId = "rbxassetid://507766388" -- Replace with your idle flight animation ID
local fastFlightAnimation = Instance.new("Animation")
fastFlightAnimation.AnimationId = "rbxassetid://507766951" -- Replace with your fast flight animation ID
local hyperFlightAnimation = Instance.new("Animation")
hyperFlightAnimation.AnimationId = "rbxassetid://507767176" -- Replace with your hyper flight animation ID

local idleTrack = animator:LoadAnimation(idleFlightAnimation)
local fastTrack = animator:LoadAnimation(fastFlightAnimation)
local hyperTrack = animator:LoadAnimation(hyperFlightAnimation)

-- Flight system variables
local isFlying = false
local flySpeed = 50
local currentAnimTrack = nil
local moveDirection = Vector3.new()

-- Trail effect setup
local trailAttachment1 = Instance.new("Attachment")
trailAttachment1.Position = Vector3.new(-0.5, 0, 0)
trailAttachment1.Parent = rootPart

local trailAttachment2 = Instance.new("Attachment")
trailAttachment2.Position = Vector3.new(0.5, 0, 0)
trailAttachment2.Parent = rootPart

local trail = Instance.new("Trail")
trail.Attachment0 = trailAttachment1
trail.Attachment1 = trailAttachment2
trail.Lifetime = 0.5
trail.MinLength = 0.1
trail.Enabled = false
trail.Parent = rootPart

-- Function to update animations based on speed
local function updateAnimation()
	if not isFlying then
		if currentAnimTrack then
			currentAnimTrack:Stop()
			currentAnimTrack = nil
		end
		return
	end

	local newTrack
	if flySpeed < 100 then
		newTrack = idleTrack
	elseif flySpeed <= 300 then
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

	-- Update trail visibility based on speed
	trail.Enabled = flySpeed > 300
end

-- Function to handle flying
local function updateFlight()
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
		moveDirection = moveDirection.Unit * flySpeed

		-- Smoothly rotate character to face movement direction
		local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDirection)
		rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, 0.1)
	else
		moveDirection = Vector3.new(0, 0, 0)
	end

	-- Apply velocity with some dampening to prevent sudden stops
	rootPart.Velocity = moveDirection
	rootPart.RotVelocity = Vector3.new(0, 0, 0) -- Prevent spinning
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
			updateAnimation()
		else
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.PlatformStand = false
			rootPart.Velocity = Vector3.new(0, 0, 0)
			rootPart.RotVelocity = Vector3.new(0, 0, 0)
			trail.Enabled = false
		end
	elseif input.KeyCode == Enum.KeyCode.Q and isFlying then
		flySpeed = flySpeed + 25
		updateAnimation()
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
	flySpeed = 50
	currentAnimTrack = nil
	moveDirection = Vector3.new()

	-- Recreate trail attachments
	trailAttachment1 = Instance.new("Attachment")
	trailAttachment1.Position = Vector3.new(-0.5, 0, 0)
	trailAttachment1.Parent = rootPart

	trailAttachment2 = Instance.new("Attachment")
	trailAttachment2.Position = Vector3.new(0.5, 0, 0)
	trailAttachment2.Parent = rootPart

	trail = Instance.new("Trail")
	trail.Attachment0 = trailAttachment1
	trail.Attachment1 = trailAttachment2
	trail.Lifetime = 0.5
	trail.MinLength = 0.1
	trail.Enabled = false
	trail.Parent = rootPart
end)

-- Main flight update loop
RunService.Heartbeat:Connect(updateFlight)
