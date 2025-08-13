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
local flyingAnimation = Instance.new("Animation")
flyingAnimation.AnimationId = "rbxassetid://71254946516017" -- Custom flying animation

local idleFlyingAnimation = Instance.new("Animation")
idleFlyingAnimation.AnimationId = "rbxassetid://138495817843421" -- New idle flying animation for initial speed and idle

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

local flyingTrack = loadAnimation(flyingAnimation, "Flying")
local idleFlyingTrack = loadAnimation(idleFlyingAnimation, "Idle Flying")

-- Debug: Check if idle flying track loaded
if idleFlyingTrack then
	print("Idle flying track loaded successfully")
else
	warn("Idle flying track failed to load!")
end

-- Flight system variables
local isFlying = false
local speedTier = 0 -- 0: Base, 1: Fast, 2: Super, 3: Hyper
local SPEED_TIERS = {
	35, -- Base flight speed
	150, -- Fast flight speed
	600, -- Super flight speed
	1200, -- Hyper flight speed
}
-- Removed unused: currentSpeed/currentAnimTrack
local moveDirection = Vector3.new()
-- Removed unused: lastMoveDirection

-- RbxCharacterSounds control

-- Function to find and control RbxCharacterSounds
local function setupRbxCharacterSounds()
	-- RbxCharacterSounds is a built-in Roblox script that gets added automatically
	-- We'll look for the sounds it creates rather than the script itself
	print("Setting up RbxCharacterSounds control...")

	-- Wait for the script to load and find running sounds
	spawn(function()
		wait(1) -- Give time for the script to initialize

		-- Look for running sounds in the character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				-- The running sounds are typically created by RbxCharacterSounds
				-- We'll control them by monitoring the humanoid state
				humanoid.StateChanged:Connect(function(_, newState)
					if isFlying then
						-- Disable running sounds when flying - check multiple states
						if
							newState == Enum.HumanoidStateType.Running
							or newState == Enum.HumanoidStateType.Climbing
						then
							-- Force the humanoid to not be in running states when flying
							humanoid:ChangeState(Enum.HumanoidStateType.Physics)

							-- Also immediately stop any running sounds
							for _, sound in pairs(character:GetDescendants()) do
								if
									sound:IsA("Sound")
									and (
										sound.Name:lower():find("footstep")
										or sound.Name:lower():find("run")
										or sound.Name:lower():find("walk")
									)
								then
									sound:Stop()
								end
							end
						end
					end
				end)
				print("RbxCharacterSounds control setup complete")
			end
		end
	end)
end

-- Function to disable running sounds
local function disableRunningSounds()
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			-- Force physics state to stop all running sounds immediately
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)

			-- Stop any currently playing running sounds by finding and stopping them
			for _, sound in pairs(character:GetDescendants()) do
				if
					sound:IsA("Sound")
					and (
						sound.Name:lower():find("footstep")
						or sound.Name:lower():find("run")
						or sound.Name:lower():find("walk")
					)
				then
					sound:Stop()
				end
			end

			-- Stop any sounds in the humanoid root part that might be running sounds
			if rootPart then
				for _, sound in pairs(rootPart:GetChildren()) do
					if
						sound:IsA("Sound")
						and (
							sound.Name:lower():find("footstep")
							or sound.Name:lower():find("run")
							or sound.Name:lower():find("walk")
						)
					then
						sound:Stop()
					end
				end
			end
		end
	end
end

-- Function to enable running sounds
local function enableRunningSounds()
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			-- Allow normal running state when touching ground
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

-- Continuous monitoring to prevent running sounds while flying
local runningSoundMonitor = nil
local function startRunningSoundMonitor()
	if runningSoundMonitor then
		runningSoundMonitor:Disconnect()
	end

	runningSoundMonitor = RunService.Heartbeat:Connect(function()
		if isFlying and character then
			-- Continuously force physics state and stop any running sounds
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid.MoveDirection.Magnitude > 0 then
				humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			end

			-- Stop any running sounds that might be playing
			for _, sound in pairs(character:GetDescendants()) do
				if
					sound:IsA("Sound")
					and sound.IsPlaying
					and (
						sound.Name:lower():find("footstep")
						or sound.Name:lower():find("run")
						or sound.Name:lower():find("walk")
					)
				then
					sound:Stop()
				end
			end
		end
	end)
end

local function stopRunningSoundMonitor()
	if runningSoundMonitor then
		runningSoundMonitor:Disconnect()
		runningSoundMonitor = nil
	end
end

-- Player stats integration
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateStatsEvent = remotes:WaitForChild("UpdateStats")
local addExperienceEvent = remotes:WaitForChild("AddExperience")
local addCoinsEvent = remotes:WaitForChild("AddCoins")

local maxSpeedTier = 1 -- Default to 1 boost

-- Listen for stats updates
updateStatsEvent.OnClientEvent:Connect(function(stats)
	maxSpeedTier = stats.maxSpeedTier
	print("Updated max speed tier to:", maxSpeedTier)
end)

-- Wind sound handled via built-in RbxCharacterSounds (FreeFalling) when flying

-- Visual effects
local function createSonicBoom()
	-- Create visual boom effect
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

	-- Create and play sonic boom sound with better error handling
	print("Creating sonic boom sound...")

	local sound = Instance.new("Sound")
	-- Try the original ID first, if it doesn't work we'll try a fallback
	sound.SoundId = "rbxassetid://112171797165153"
	sound.Volume = 1.0
	sound.Parent = rootPart

	-- Also try a fallback sound ID in case the original doesn't work
	local fallbackSound = Instance.new("Sound")
	fallbackSound.SoundId = "rbxassetid://131113322" -- This is a known working sound ID
	fallbackSound.Volume = 1.0
	fallbackSound.Parent = rootPart

	-- Try to play immediately
	local playSuccess, playError = pcall(function()
		sound:Play()
	end)

	if playSuccess then
		print("Sonic boom sound started playing immediately")
	else
		print("Failed to play immediately, trying fallback sound...")
		warn("Play error:", playError)

		-- Try the fallback sound
		local fallbackSuccess, fallbackError = pcall(function()
			fallbackSound:Play()
		end)

		if fallbackSuccess then
			print("Fallback sound started playing immediately")
		else
			print("Both sounds failed, trying to wait for load...")
			warn("Fallback play error:", fallbackError)

			-- If both immediate plays fail, wait for load
			sound.Loaded:Connect(function()
				print("Original sound loaded, attempting to play...")
				local retrySuccess, retryError = pcall(function()
					sound:Play()
				end)
				if retrySuccess then
					print("Original sonic boom sound playing after load!")
				else
					warn("Failed to play original after load:", retryError)
				end
			end)

			fallbackSound.Loaded:Connect(function()
				print("Fallback sound loaded, attempting to play...")
				local retrySuccess, retryError = pcall(function()
					fallbackSound:Play()
				end)
				if retrySuccess then
					print("Fallback sound playing after load!")
				else
					warn("Failed to play fallback after load:", retryError)
				end
			end)
		end
	end

	-- Clean up sounds after they finish
	game.Debris:AddItem(sound, 5)
	game.Debris:AddItem(fallbackSound, 5)
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
		if idleFlyingTrack and idleFlyingTrack.IsPlaying then
			idleFlyingTrack:Stop()
		end
		return
	end

	-- Debug: Print current state
	print(
		"Animation Update - isFlying:",
		isFlying,
		"speedTier:",
		speedTier,
		"moveDirection.Magnitude:",
		moveDirection.Magnitude
	)

	-- Check if we're moving
	if moveDirection.Magnitude > 0 then
		-- If we're moving, check speed tier
		if speedTier == 0 then
			-- At initial speed, use the new idle flying animation
			if not idleFlyingTrack.IsPlaying then
				idleFlyingTrack:Play()
			end
			-- Stop regular flying animation if it's playing
			if flyingTrack.IsPlaying then
				flyingTrack:Stop()
			end
		else
			-- At higher speeds, use the regular flying animation
			if not flyingTrack.IsPlaying then
				flyingTrack:Play()
			end
			-- Stop idle animation if it's playing
			if idleFlyingTrack and idleFlyingTrack.IsPlaying then
				print("Stopping idle flying animation - higher speed tier")
				idleFlyingTrack:Stop()
			end
			-- Adjust animation speed based on speed tier
			local speedMultiplier = 1 + (speedTier * 0.5) -- 1.0x, 1.5x, 2.0x, 2.5x speed
			flyingTrack:AdjustSpeed(speedMultiplier)
		end
	else
		-- If we're not moving, always use the new idle flying animation
		if flyingTrack.IsPlaying then
			flyingTrack:Stop()
		end
		-- Play idle flying animation if not already playing
		if idleFlyingTrack and not idleFlyingTrack.IsPlaying then
			print("Playing idle flying animation (112074359619626)")
			idleFlyingTrack:Play()
		end
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
	-- Removed space key flying up functionality
	-- if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
	--     moveDirection = moveDirection + upVector
	-- end
	-- Removed shift key flying down functionality
	-- if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
	--     moveDirection = moveDirection - upVector
	-- end

	-- Normalize and apply speed
	if moveDirection.Magnitude > 0 then
		moveDirection = moveDirection.Unit * SPEED_TIERS[speedTier + 1]

		-- Check if shift lock is active (camera is locked to character)
		local isShiftLocked = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or camera.CameraType == Enum.CameraType.Scriptable

		if isShiftLocked then
			-- When shift locked: face camera direction (mouse direction)
			local cameraLookVector = camera.CFrame.LookVector
			local targetCFrame = CFrame.new(
				rootPart.Position,
				rootPart.Position + Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z)
			)
			rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, deltaTime * 10)
		else
			-- When NOT shift locked: face movement direction (WASD direction)
			local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDirection)
			rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, deltaTime * 10)
		end

		-- Apply velocity
		rootPart.Velocity = moveDirection
	else
		-- When not moving, hover in place by countering gravity
		rootPart.Velocity = Vector3.new(0, 2, 0) -- Apply upward force to hover
		if speedTier > 0 then
			speedTier = 0
			print("Reset to base speed - stopped moving")
		end
	end

	-- Keep character from rotating randomly
	rootPart.RotVelocity = Vector3.new(0, 0, 0)

	-- Update animations based on movement
	updateAnimation()

	-- Wind handled by RbxCharacterSounds

	-- Award experience and coins for flying
	if isFlying and moveDirection.Magnitude > 0 then
		-- Award experience based on speed tier
		local expGain = 1 + speedTier * 2 -- 1 exp for base, 3 for tier 1, 5 for tier 2, etc.
		addExperienceEvent:FireServer(expGain)

		-- Show XP notification occasionally
		if math.random(1, 100) <= 10 then -- 10% chance per frame
			if _G.NotificationSystem then
				_G.NotificationSystem.showXP(expGain)
			end
		end

		-- Award coins occasionally
		if math.random(1, 100) <= 5 then -- 5% chance per frame
			local coinGain = 1 + speedTier -- More coins for higher speeds
			addCoinsEvent:FireServer(coinGain)

			-- Show coin notification
			if _G.NotificationSystem then
				_G.NotificationSystem.showCoins(coinGain)
			end
		end
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.F then
		isFlying = not isFlying

		if isFlying then
			-- Immediately get airborne by applying upward velocity
			rootPart.Velocity = Vector3.new(0, 50, 0)

			-- Switch to flight mode immediately
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			humanoid.PlatformStand = true

			-- Disable default humanoid animations
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.AutoRotate = false
			humanoid.AutoJumpEnabled = false

			-- Set initial upward velocity to get airborne
			rootPart.Velocity = Vector3.new(0, 20, 0)

			-- Stop all currently playing animations
			for _, track in pairs(animator:GetPlayingAnimationTracks()) do
				track:Stop()
			end

			-- Disable running sounds
			disableRunningSounds()

			-- Start running sound monitor
			startRunningSoundMonitor()

			-- Tell RbxCharacterSounds that we're flying
			if _G.setFlyingState then
				_G.setFlyingState(true)
			end

			-- Wind handled by RbxCharacterSounds
		else
			-- Stop flying - restore normal state
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.PlatformStand = false

			-- Restore default humanoid properties
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			humanoid.AutoJumpEnabled = true

			-- Reset flight variables
			speedTier = 0
			moveDirection = Vector3.new()

			-- Stop all flight animations
			if flyingTrack and flyingTrack.IsPlaying then
				flyingTrack:Stop()
			end
			if idleFlyingTrack and idleFlyingTrack.IsPlaying then
				idleFlyingTrack:Stop()
			end

			-- Reset physics
			rootPart.Velocity = Vector3.new(0, 0, 0)
			rootPart.RotVelocity = Vector3.new(0, 0, 0)

			-- Disable trail
			if trail then
				trail.Enabled = false
			end

			-- Stop running sound monitor
			stopRunningSoundMonitor()

			-- Enable running sounds
			enableRunningSounds()

			-- Tell RbxCharacterSounds that we're not flying
			if _G.setFlyingState then
				_G.setFlyingState(false)
			end

			-- Wind handled by RbxCharacterSounds

			print("Flight mode disabled - returned to normal walking")
		end
	elseif input.KeyCode == Enum.KeyCode.Q and isFlying then
		-- Increment speed tier and create sonic boom effect
		if speedTier < maxSpeedTier - 1 then
			speedTier = speedTier + 1
			print("Q pressed - Speed tier increased to:", speedTier)

			-- Only create sonic boom on speed tiers 2 and 3 (not tier 1)
			if speedTier >= 2 then
				createSonicBoom()
			end

			-- Wind handled by RbxCharacterSounds
			-- Only update animation if we're moving
			if moveDirection.Magnitude > 0 then
				updateAnimation()
			end
		else
			print("Q pressed - Already at max speed tier:", maxSpeedTier)
		end
	end
end)

-- Character respawn handling
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	animator = humanoid:WaitForChild("Animator")

	-- Setup RbxCharacterSounds control
	setupRbxCharacterSounds()

	-- Reload animations
	flyingTrack = loadAnimation(flyingAnimation, "Flying")
	idleFlyingTrack = loadAnimation(idleFlyingAnimation, "Idle Flying")

	-- Debug: Check if idle flying track loaded after respawn
	if idleFlyingTrack then
		print("Idle flying track reloaded successfully after respawn")
	else
		warn("Idle flying track failed to reload after respawn!")
	end

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
	-- Wind handled by RbxCharacterSounds
	updateFlight(deltaTime)
end)
