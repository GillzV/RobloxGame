local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===== CONFIGURABLE FLIGHT SETTINGS =====
local FLIGHT_CONFIG = {
	BASE_SPEED = 35, -- Starting max speed (should match PlayerStats)
	SPEED_INCREASE = 1, -- Speed gained per interval (1 studs/s every 1 second)
	TIME_INTERVAL = 1, -- Time interval for speed gain (should match PlayerStats)
	MAX_SPEED_CAP = 250000, -- Maximum possible speed (should match PlayerStats)
	SPEED_BOOST_MULTIPLIER = 0.5, -- Speed boost per Q press (50% each)
	MAX_SPEED_BOOSTS = 2, -- Maximum number of speed boosts
}
-- =========================================

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

local fastFlyingAnimation = Instance.new("Animation")
fastFlyingAnimation.AnimationId = "rbxassetid://78872108159546" -- Fast and super speed flying animation

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
local fastFlyingTrack = loadAnimation(fastFlyingAnimation, "Fast Flying")

-- Debug: Check if idle flying track loaded
if idleFlyingTrack then
	print("Idle flying track loaded successfully")
else
	warn("Idle flying track failed to load!")
end

-- Debug: Check if fast flying track loaded
if fastFlyingTrack then
	print("Fast flying track loaded successfully")
else
	warn("Fast flying track failed to load!")
end

-- Flight system variables
local isFlying = false
local currentSpeed = FLIGHT_CONFIG.BASE_SPEED -- Current flight speed (starts at base speed)
local speedBoost = 0 -- Speed boost from Q key (0, 1, 2)
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
local addFlightTimeEvent = remotes:WaitForChild("AddFlightTime")
local updateActualSpeedEvent = remotes:WaitForChild("UpdateActualSpeed")
local toggleFlightEvent = remotes:WaitForChild("ToggleFlight")

local playerMaxSpeed = FLIGHT_CONFIG.BASE_SPEED -- Current player's max speed
local flightTimeAccumulator = 0 -- Accumulate flight time before sending to server
local currentActualSpeed = 0 -- Track actual current speed
local lastPosition = rootPart.Position
local lastTime = tick()
local lastSpeedUpdate = 0 -- Track when we last sent speed update
local targetSpeed = 0 -- Target speed for smoothing
local currentSmoothedSpeed = 0 -- Current smoothed speed

-- Listen for stats updates
updateStatsEvent.OnClientEvent:Connect(function(stats)
	print("FlightSystem: Received stats update:", stats)
	playerMaxSpeed = math.min(stats.maxSpeed or FLIGHT_CONFIG.BASE_SPEED, FLIGHT_CONFIG.MAX_SPEED_CAP)
	print("FlightSystem: Updated max speed to:", playerMaxSpeed)
end)

-- Wind sound handled via built-in RbxCharacterSounds (FreeFalling) when flying

-- Visual effects
local function createSonicBoom()
	-- Create VFX particle animation effect from VFX folder
	print("Looking for VFX part in VFX folder...")

	-- Look for VFX folder in ReplicatedStorage
	local vfxFolder = game:GetService("ReplicatedStorage"):FindFirstChild("VFX")
	if not vfxFolder then
		warn("VFX folder not found in ReplicatedStorage")
		return
	end

	-- Look for the VFX part (try common names)
	local vfxPart = vfxFolder:FindFirstChild("SonicBoom")
		or vfxFolder:FindFirstChild("Boom")
		or vfxFolder:FindFirstChild("Explosion")
		or vfxFolder:FindFirstChild("Effect")

	-- If no specific part found, get the first BasePart
	if not vfxPart then
		for _, child in pairs(vfxFolder:GetChildren()) do
			if child:IsA("BasePart") then
				vfxPart = child
				break
			end
		end
	end

	if vfxPart then
		print("Found VFX part:", vfxPart.Name)

		-- Clone the VFX part
		local boomClone = vfxPart:Clone()
		boomClone.CFrame = rootPart.CFrame
		boomClone.Parent = workspace

		-- Clean up after the VFX animation completes
		-- Adjust this delay based on your VFX duration
		game.Debris:AddItem(boomClone, 0.5) -- Half a second cleanup
		print("VFX positioned and cleanup scheduled")
	else
		warn("No VFX part found in VFX folder. Available parts:")
		for _, child in pairs(vfxFolder:GetChildren()) do
			print("- " .. child.ClassName .. ": " .. child.Name)
		end
	end

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
		if fastFlyingTrack and fastFlyingTrack.IsPlaying then
			fastFlyingTrack:Stop()
		end
		return
	end

	-- Debug: Print current state
	print(
		"Animation Update - isFlying:",
		isFlying,
		"speedBoost:",
		speedBoost,
		"moveDirection.Magnitude:",
		moveDirection.Magnitude
	)

	-- Check if we're moving
	if moveDirection.Magnitude > 0 then
		-- If we're moving, check speed boost level
		if speedBoost == 0 then
			-- At base speed, use the idle flying animation
			if not idleFlyingTrack.IsPlaying then
				idleFlyingTrack:Play()
			end
			-- Always ensure idle animation is at slow speed
			idleFlyingTrack:AdjustSpeed(0.3) -- Make idle animation slower (30% speed)
			-- Stop other animations if they're playing
			if flyingTrack.IsPlaying then
				flyingTrack:Stop()
			end
			if fastFlyingTrack and fastFlyingTrack.IsPlaying then
				fastFlyingTrack:Stop()
			end
		else
			-- At boosted speeds, use the fast flying animation
			if not fastFlyingTrack.IsPlaying then
				fastFlyingTrack:Play()
			end
			-- Stop other animations if they're playing
			if idleFlyingTrack and idleFlyingTrack.IsPlaying then
				print("Stopping idle flying animation - speed boost active")
				idleFlyingTrack:Stop()
			end
			if flyingTrack.IsPlaying then
				flyingTrack:Stop()
			end
			-- Adjust animation speed based on speed boost
			local speedMultiplier = 1 + (speedBoost * 0.1) -- 1.0x, 1.1x, 1.2x speed
			fastFlyingTrack:AdjustSpeed(speedMultiplier)
		end
	else
		-- If we're not moving, always use the new idle flying animation
		if flyingTrack.IsPlaying then
			flyingTrack:Stop()
		end
		if fastFlyingTrack and fastFlyingTrack.IsPlaying then
			fastFlyingTrack:Stop()
		end
		-- Play idle flying animation if not already playing
		if idleFlyingTrack and not idleFlyingTrack.IsPlaying then
			print("Playing idle flying animation (112074359619626)")
			idleFlyingTrack:Play()
		end
		-- Always ensure idle animation is at slow speed when hovering
		if idleFlyingTrack and idleFlyingTrack.IsPlaying then
			idleFlyingTrack:AdjustSpeed(0.3) -- Make idle animation slower (30% speed)
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
		-- Apply permanent speed multiplier from GUI purchases to base speed calculation
		local guiMultiplier = _G.speedMultiplier or 1

		-- Debug: Print multiplier info occasionally
		if math.random() < 0.001 then -- 0.1% chance per frame
			print(
				"FlightSystem Debug - guiMultiplier:",
				guiMultiplier,
				"speedBoost:",
				speedBoost,
				"playerMaxSpeed:",
				playerMaxSpeed
			)
		end

		-- Calculate base speed for different tiers
		local baseSpeed = FLIGHT_CONFIG.BASE_SPEED
		if speedBoost >= FLIGHT_CONFIG.MAX_SPEED_BOOSTS then
			-- Tier 3: Use progressed max speed and apply speed shop multiplier
			local tier3BaseSpeed = math.min(playerMaxSpeed, FLIGHT_CONFIG.MAX_SPEED_CAP)
			local speedShopMultiplier = _G.speedMultiplier or 1
			baseSpeed = tier3BaseSpeed * speedShopMultiplier

			-- Debug: Print Tier 3 speed calculation occasionally
			if math.random() < 0.0005 then -- 0.05% chance per frame
				print(
					"Tier 3 Speed - playerMaxSpeed:",
					playerMaxSpeed,
					"speedShopMultiplier:",
					speedShopMultiplier,
					"baseSpeed:",
					baseSpeed
				)
			end
		else
			-- Tier 1 & 2: Use base speed (not affected by speed shop multipliers)
			baseSpeed = FLIGHT_CONFIG.BASE_SPEED
		end

		-- Apply speed boost multiplier
		local boostMultiplier = 1 + speedBoost * FLIGHT_CONFIG.SPEED_BOOST_MULTIPLIER
		local boostedSpeed = baseSpeed * boostMultiplier

		-- Set target speed and smooth the transition
		targetSpeed = math.min(boostedSpeed, FLIGHT_CONFIG.MAX_SPEED_CAP)

		-- Smooth speed transitions to prevent glitching
		local smoothingFactor = 0.1
		currentSmoothedSpeed = currentSmoothedSpeed + (targetSpeed - currentSmoothedSpeed) * smoothingFactor
		currentSpeed = currentSmoothedSpeed

		-- Apply the smoothed speed
		moveDirection = moveDirection.Unit * currentSpeed

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
		if speedBoost > 0 then
			speedBoost = 0
			print("Reset speed boost - stopped moving")
			-- Stop wind sound when dropping back to tier 1
			if _G.windSound then
				print("FlightSystem: Stopping wind sound (tier reset)")
				_G.windSound:Stop()
				_G.windSound:Destroy()
				_G.windSound = nil
			end
		end
	end

	-- Keep character from rotating randomly
	rootPart.RotVelocity = Vector3.new(0, 0, 0)

	-- Update animations based on movement
	updateAnimation()

	-- If wind sound is active, adjust volume based on tier (tier 2 < tier 3)
	if _G.windSound then
		local targetVolume = (speedBoost >= 2) and 0.8 or 0.25
		_G.windSound.Volume = targetVolume
	end

	-- Ensure wind sound only plays on tier 2+
	if _G.windSound then
		if (not isFlying) or speedBoost == 0 then
			print("FlightSystem: Stopping wind sound (guard)")
			_G.windSound:Stop()
			_G.windSound:Destroy()
			_G.windSound = nil
		end
	end

	-- Wind handled by RbxCharacterSounds

	-- Award experience for flying
	if isFlying and moveDirection.Magnitude > 0 then
		-- Track actual current speed
		local currentTime = tick()
		local speedDeltaTime = currentTime - lastTime
		if speedDeltaTime > 0 then
			local currentPosition = rootPart.Position
			local distance = (currentPosition - lastPosition).Magnitude
			currentActualSpeed = distance / speedDeltaTime
			lastPosition = currentPosition
			lastTime = currentTime
		end

		-- Track flight time for progressive speed gain
		flightTimeAccumulator = flightTimeAccumulator + deltaTime

		-- Send flight time to server every configured interval for progression
		if flightTimeAccumulator >= FLIGHT_CONFIG.TIME_INTERVAL then
			addFlightTimeEvent:FireServer(flightTimeAccumulator)
			flightTimeAccumulator = 0
		end

		-- Disabled actual speed tracking - only use time-based progression
		-- if currentTime - lastSpeedUpdate >= 0.1 then
		--     updateActualSpeedEvent:FireServer(currentActualSpeed)
		--     lastSpeedUpdate = currentTime
		-- end

		-- Show speed increase notification occasionally
		if math.random(1, 100) <= 2 then -- 2% chance per frame
			if _G.NotificationSystem and _G.NotificationSystem.showSpeedIncrease then
				_G.NotificationSystem.showSpeedIncrease(playerMaxSpeed)
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
			-- Enable wind cone effect
			toggleFlightEvent:FireServer(true)

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
				print("FlightSystem: Calling _G.setFlyingState(true)")
				_G.setFlyingState(true)
			else
				warn("FlightSystem: _G.setFlyingState function not found! RbxCharacterSounds may not be loaded.")
				-- Try to wait for it to load
				spawn(function()
					for i = 1, 10 do
						wait(0.1)
						if _G.setFlyingState then
							print("FlightSystem: _G.setFlyingState found after delay, calling with true")
							_G.setFlyingState(true)
							break
						end
					end
				end)
			end

			-- Wind sound will be created when reaching tier 2+ (speedBoost >= 1)
			print("FlightSystem: Flight started - wind sound will activate at tier 2+")

			-- Wind handled by RbxCharacterSounds
		else
			-- Disable wind cone effect
			toggleFlightEvent:FireServer(false)

			-- Stop flying - restore normal state
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.PlatformStand = false

			-- Restore default humanoid properties
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			humanoid.AutoJumpEnabled = true

			-- Reset flight variables
			speedBoost = 0
			moveDirection = Vector3.new()

			-- Stop all flight animations
			if flyingTrack and flyingTrack.IsPlaying then
				flyingTrack:Stop()
			end
			if idleFlyingTrack and idleFlyingTrack.IsPlaying then
				idleFlyingTrack:Stop()
			end
			if fastFlyingTrack and fastFlyingTrack.IsPlaying then
				fastFlyingTrack:Stop()
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
				print("FlightSystem: Calling _G.setFlyingState(false)")
				_G.setFlyingState(false)
			else
				warn("FlightSystem: _G.setFlyingState function not found!")
			end

			-- Stop wind sound if it exists
			if _G.windSound then
				print("FlightSystem: Stopping wind sound")
				_G.windSound:Stop()
				_G.windSound:Destroy()
				_G.windSound = nil
			end

			-- Wind handled by RbxCharacterSounds

			print("Flight mode disabled - returned to normal walking")
		end
	elseif input.KeyCode == Enum.KeyCode.Q and isFlying then
		-- Increment speed boost and create sonic boom effect
		if speedBoost < FLIGHT_CONFIG.MAX_SPEED_BOOSTS then
			speedBoost = speedBoost + 1
			print("Q pressed - Speed boost increased to:", speedBoost)

			-- Create wind sound when reaching tier 2+ (speedBoost >= 1)
			if speedBoost >= 1 and not _G.windSound then
				print("FlightSystem: Creating wind sound for tier", speedBoost + 1)
				local windSound = Instance.new("Sound")
				windSound.SoundId = "rbxasset://sounds/action_falling.ogg"
				windSound.Volume = (speedBoost >= 2) and 0.8 or 0.35
				windSound.Looped = true
				windSound.Parent = rootPart

				-- Try to play the sound
				local success, error = pcall(function()
					windSound:Play()
				end)

				if success then
					print("FlightSystem: Wind sound started successfully")
					_G.windSound = windSound
				else
					warn("FlightSystem: Failed to play wind sound:", error)
				end
			elseif speedBoost >= 1 and _G.windSound then
				-- Adjust volume when tier changes between 2 and 3
				_G.windSound.Volume = (speedBoost >= 2) and 0.8 or 0.35
			end

			-- Create sonic boom on max boost level
			if speedBoost >= FLIGHT_CONFIG.MAX_SPEED_BOOSTS then
				createSonicBoom()
			end

			-- Wind handled by RbxCharacterSounds
			-- Only update animation if we're moving
			if moveDirection.Magnitude > 0 then
				updateAnimation()
			end
		else
			print("Q pressed - Already at max speed boost:", speedBoost)
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
	fastFlyingTrack = loadAnimation(fastFlyingAnimation, "Fast Flying")

	-- Debug: Check if idle flying track loaded after respawn
	if idleFlyingTrack then
		print("Idle flying track reloaded successfully after respawn")
	else
		warn("Idle flying track failed to reload after respawn!")
	end

	-- Debug: Check if fast flying track loaded after respawn
	if fastFlyingTrack then
		print("Fast flying track reloaded successfully after respawn")
	else
		warn("Fast flying track failed to reload after respawn!")
	end

	-- Reset flight state
	isFlying = false
	speedBoost = 0
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
