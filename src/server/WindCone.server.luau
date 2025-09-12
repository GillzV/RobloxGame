-- ServerScriptService/WindCone.server.luau
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local TOGGLE = RS:WaitForChild("ToggleFlight")

-- Tuneables
local NUM_SPOKES = 8 -- how many beams around the cone
local BASE_WIDTH = 2.4 -- cone radius at the start (near back)
local TIP_WIDTH = 0.2 -- cone radius at the end (far tip)
local MIN_LEN, MAX_LEN = 6, 28 -- min/max cone length (studs)
local MIN_SPEED, MAX_SPEED = 8, 120 -- maps character speed to cone length
local BOOM_SPEED = 70 -- crossing this speed triggers ring

-- Per player state
local S = {} -- [player] = { model=Model, backAtt=Attachment, tipAtt=Attachment, beams={}, conn, lastSpeed=0 }

local function mapSpeedToLen(v)
	if v <= MIN_SPEED then
		return MIN_LEN
	end
	if v >= MAX_SPEED then
		return MAX_LEN
	end
	local a = (v - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
	return MIN_LEN + a * (MAX_LEN - MIN_LEN)
end

local function destroy(plr)
	local st = S[plr]
	if not st then
		return
	end
	if st.conn then
		st.conn:Disconnect()
	end
	if st.model then
		st.model:Destroy()
	end
	S[plr] = nil
end

local function makeBoomRing(parentCF, parent)
	-- Quick expanding ring using a Beam between two close attachments
	-- Looks like a shockwave disc.
	local p = Instance.new("Part")
	p.Name = "SonicBoom"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = parentCF
	p.Parent = parent

	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")
	a0.Parent = p
	a1.Parent = p
	a0.Position = Vector3.new(0, 0, 0)
	a1.Position = Vector3.new(0, 0, 0.1)

	local b = Instance.new("Beam")
	b.Parent = p
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.FaceCamera = true
	b.Segments = 12
	b.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.2),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	b.Width0 = 0
	b.Width1 = 0
	-- Optional texture gives a streaky ring; remove if you want a flat ring
	b.Texture = "rbxassetid://446111271" -- radial streak; swap to your art
	b.TextureMode = Enum.TextureMode.Stretch
	b.TextureSpeed = 0
	b.Color = ColorSequence.new(Color3.new(1, 1, 1))

	-- Animate expansion and fade
	local TweenService = game:GetService("TweenService")
	local info = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local t = TweenService:Create(b, info, { Width0 = 18, Width1 = 18 })
	t:Play()
	task.delay(0.38, function()
		local t2 = TweenService:Create(b, TweenInfo.new(0.25), { Transparency = NumberSequence.new(1) })
		t2:Play()
		t2.Completed:Once(function()
			p:Destroy()
		end)
	end)
end

local function start(plr)
	destroy(plr)

	local char = plr.Character
	if not (char and char.Parent) then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- Model to hold cosmetic bits
	local m = Instance.new("Model")
	m.Name = "WindConeRig"
	m.Parent = char

	-- Back attachment (on torso/back)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or root
	local backAtt = Instance.new("Attachment")
	backAtt.Name = "WindBack"
	backAtt.Parent = torso
	backAtt.Position = Vector3.new(0, 0.6, -0.6) -- upper back, slightly behind

	-- Tip anchor part behind the character; we'll move it each Heartbeat
	local tipPart = Instance.new("Part")
	tipPart.Name = "WindTipPart"
	tipPart.Anchored = true
	tipPart.CanCollide = false
	tipPart.CanQuery = false
	tipPart.Transparency = 1
	tipPart.Size = Vector3.new(0.2, 0.2, 0.2)
	tipPart.Parent = m

	local tipAtt = Instance.new("Attachment")
	tipAtt.Name = "WindTip"
	tipAtt.Parent = tipPart

	-- Build radial beams to fake a cone surface
	local beams = {}
	for i = 1, NUM_SPOKES do
		local beam = Instance.new("Beam")
		beam.Attachment0 = backAtt
		beam.Attachment1 = tipAtt
		beam.Parent = m
		beam.Segments = 10
		beam.Width0 = BASE_WIDTH
		beam.Width1 = TIP_WIDTH
		beam.LightInfluence = 0
		beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 0.25),
			NumberSequenceKeypoint.new(0.8, 0.6),
			NumberSequenceKeypoint.new(1.0, 1.0),
		})
		-- Subtle texture helps sell "wind"
		beam.Texture = "rbxassetid://4836602328" -- soft dot; swap to streaky texture if you want
		beam.TextureLength = 4
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureSpeed = 1
		beam.Enabled = true

		-- Slight per-spoke curve using curve size (offset the tip along a ring via attachments?):
		-- Instead, we stagger TextureOffset so spokes don't align perfectly.
		beam.TextureOffset = math.random()

		table.insert(beams, beam)
	end

	-- Heartbeat updater: place tip behind you, scale by speed
	local lastSpeed = 0
	local firedBoom = false
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not root or not root.Parent then
			destroy(plr)
			return
		end

		local vel = root.AssemblyLinearVelocity
		local speed = vel.Magnitude

		-- Aim cone opposite your facing direction (use camera forward if you prefer)
		local look = root.CFrame.LookVector
		local len = mapSpeedToLen(speed)
		local tipPos = backAtt.WorldPosition - look * len

		-- Keep tip behind and roughly aligned with root orientation
		local up = root.CFrame.UpVector
		local cf = CFrame.lookAt(tipPos, tipPos + look, up)
		tipPart.CFrame = cf

		-- Sonic boom ring: trigger when crossing BOOM_SPEED upward
		if (lastSpeed < BOOM_SPEED) and (speed >= BOOM_SPEED) then
			makeBoomRing(root.CFrame * CFrame.new(0, 0, -1), char)
		end
		lastSpeed = speed
	end)

	S[plr] = {
		model = m,
		backAtt = backAtt,
		tipAtt = tipAtt,
		beams = beams,
		conn = conn,
		lastSpeed = 0,
	}

	-- Clean up on death
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Once(function()
			destroy(plr)
		end)
	end
	char.AncestryChanged:Connect(function(_, parent)
		if not parent then
			destroy(plr)
		end
	end)
end

TOGGLE.OnServerEvent:Connect(function(plr, isOn)
	if isOn then
		start(plr)
	else
		destroy(plr)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	destroy(plr)
end)
