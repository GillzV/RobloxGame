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

-- Create animations
local takeoffAnimation = Instance.new("Animation")
takeoffAnimation.AnimationId = "rbxassetid://74631654906693" -- Custom takeoff animation

local flyingAnimation = Instance.new("Animation")
flyingAnimation.AnimationId = "rbxassetid://71254946516017" -- Custom flying animation

-- Load animations and print status
local function loadAnimation(animation, name)
	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if success and track then
		print(name .. " animation loaded successfully")
		return track
	else
		warn(name .. " animation failed to load")
		return nil
	end
end

local takeoffTrack = loadAnimation(takeoffAnimation, "Takeoff")
local flyingTrack = loadAnimation(flyingAnimation, "Flying")

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

-- Function to update animations based on movement
local function updateAnimation()
	if not isFlying then
		if flyingTrack.IsPlaying then
			flyingTrack:Stop()
		end
		return
	end

	-- Check if we're moving
	if moveDirection.Magnitude > 0 then
		-- If we're moving and animation isn't playing, start it
		if not flyingTrack.IsPlaying then
			flyingTrack:Play()
		end
		-- Adjust animation speed based on speed tier
		local speedMultiplier = 1 + (speedTier * 0.5) -- 1.0x, 1.5x, 2.0x, 2.5x speed
		flyingTrack:AdjustSpeed(speedMultiplier)
	else
		-- If we're not moving, stop the animation
		if flyingTrack.IsPlaying then
			flyingTrack:Stop()
		end
	end
end

-- Function to play takeoff animation
local function playTakeoffAnimation()
	print("Attempting to play takeoff animation...")
	if takeoffTrack then
		print("Found takeoff track, playing animation...")
		local success, err = pcall(function()
			takeoffTrack:Play()
		end)
		if success then
			print("Successfully started takeoff animation!")
			-- Wait for takeoff animation to finish
			task.delay(takeoffTrack.Length, function()
				print("Takeoff animation finished")
				takeoffTrack:Stop()
			end)
		else
			warn("Failed to play takeoff animation:", err)
		end
	else
		warn("No takeoff track available!")
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

		-- Smoothly rotate character to face movement direction
		local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDirection)
		rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, deltaTime * 10)

		-- Apply velocity
		rootPart.Velocity = moveDirection
	else
		-- When not moving, stop completely
		rootPart.Velocity = Vector3.new(0, 0, 0)
	end

	-- Keep character from rotating randomly
	rootPart.RotVelocity = Vector3.new(0, 0, 0)

	-- Update animations based on movement
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
			playTakeoffAnimation()
			createSonicBoom()
		else
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.PlatformStand = false
			speedTier = 0
			if flyingTrack.IsPlaying then
				flyingTrack:Stop()
			end
			rootPart.Velocity = Vector3.new(0, 0, 0)
			rootPart.RotVelocity = Vector3.new(0, 0, 0)
			trail.Enabled = false
		end
	elseif input.KeyCode == Enum.KeyCode.Q and isFlying then
		-- Increment speed tier and create sonic boom effect
		if speedTier < 3 then
			speedTier = speedTier + 1
			createSonicBoom()
			-- Only update animation if we're moving
			if moveDirection.Magnitude > 0 then
				updateAnimation()
			end
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
	takeoffTrack = loadAnimation(takeoffAnimation, "Takeoff")
	flyingTrack = loadAnimation(flyingAnimation, "Flying")

	-- Reset flight state
	isFlying = false
	speedTier = 0
	moveDirection = Vector3.new()

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
