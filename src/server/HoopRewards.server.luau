local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Prefer server signal to avoid ModuleScript require issues
local function resolveAddFlightSignal(timeout: number?): BindableEvent?
	local waitTime = timeout or 0
	local folder = ServerScriptService:FindFirstChild("ServerSignals")
		or (waitTime > 0 and ServerScriptService:WaitForChild("ServerSignals", waitTime) or nil)
	if not folder then
		return nil
	end
	local evt = folder:FindFirstChild("AddFlightTimeServer")
		or (waitTime > 0 and folder:WaitForChild("AddFlightTimeServer", waitTime) or nil)
	return evt :: BindableEvent?
end

local addFlightTimeServer: BindableEvent? = resolveAddFlightSignal(0)

-- If the signal is created later (race at startup), pick it up
ServerScriptService.ChildAdded:Connect(function(child)
	if child.Name == "ServerSignals" then
		addFlightTimeServer = resolveAddFlightSignal(10)
		if addFlightTimeServer then
			print("HoopRewards: Bound to AddFlightTimeServer (late)")
		end
	end
end)

-- CONFIG
local HOOP_TAGS = { "Hoop", "SpeedHoop", "HoopTrigger" }
local HOOPS_FOLDER_NAME = "Hoops" -- optional: put all hoop parts here
local REWARD_SECONDS = 10
local TOUCH_COOLDOWN_SEC = 10.0 -- per player, per hoop

-- Track per-hoop debounces to prevent multiple awards while inside the hoop
local hoopToPlayerCooldowns: { [Instance]: { [number]: number } } = {}

local function ensureCooldownTable(hoop: Instance)
	if not hoopToPlayerCooldowns[hoop] then
		hoopToPlayerCooldowns[hoop] = {}
		-- Clean up when hoop is removed
		hoop.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				hoopToPlayerCooldowns[hoop] = nil
			end
		end)
	end
end

local function onHoopTouched(hoop: BasePart, other: BasePart)
	-- Only handle valid player character touches
	if not other or not other.Parent then
		return
	end
	local character = other.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	-- Per-hoop, per-player cooldown
	ensureCooldownTable(hoop)
	local playerCooldowns = hoopToPlayerCooldowns[hoop]
	local now = os.clock()
	local last = playerCooldowns[player.UserId]
	if last and (now - last) < TOUCH_COOLDOWN_SEC then
		return
	end
	playerCooldowns[player.UserId] = now

	-- Resolve on-demand in case it was created after startup
	if not addFlightTimeServer then
		addFlightTimeServer = resolveAddFlightSignal(0)
	end

	-- Award flight time (server-authoritative) via server signal
	if addFlightTimeServer and REWARD_SECONDS > 0 then
		addFlightTimeServer:Fire(player, REWARD_SECONDS)
		print(string.format("HoopRewards: Granted +%ds to %s", REWARD_SECONDS, player.Name))
	else
		if not addFlightTimeServer then
			warn("HoopRewards: AddFlightTimeServer signal missing; ensure PlayerData.server.luau created it")
		end
		if REWARD_SECONDS <= 0 then
			warn("HoopRewards: REWARD_SECONDS is 0; no reward granted")
		end
	end
end

local function connectHoop(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	-- Avoid double-connecting
	if part:GetAttribute("_HoopRewardsConnected") then
		return
	end
	part:SetAttribute("_HoopRewardsConnected", true)
	if part.CanTouch == false then
		-- Ensure touch events can fire
		part.CanTouch = true
	end
	if part.CanQuery == false then
		part.CanQuery = true
	end
	print("HoopRewards: Connected touch on", part:GetFullName())
	part.Touched:Connect(function(other)
		onHoopTouched(part, other)
	end)

	-- Fallback: spatial overlap check (works even if collision groups block Touched)
	RunService.Heartbeat:Connect(function()
		local ok, touching = pcall(function()
			return workspace:GetPartsInPart(part)
		end)
		if ok and touching then
			for _, other in ipairs(touching) do
				onHoopTouched(part, other)
			end
		end
	end)
end

local function connectAllPartsIn(container: Instance)
	if container:IsA("BasePart") then
		connectHoop(container)
	end
	for _, desc in ipairs(container:GetDescendants()) do
		if desc:IsA("BasePart") then
			connectHoop(desc)
		end
	end
end

-- Register hoops by tags
for _, tag in ipairs(HOOP_TAGS) do
	for _, inst in ipairs(CollectionService:GetTagged(tag)) do
		connectAllPartsIn(inst)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
		connectAllPartsIn(inst)
		inst.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				connectHoop(desc)
			end
		end)
	end)
end

-- Also register all BaseParts under optional workspace.Hoops folder
local hoopsFolder = workspace:FindFirstChild(HOOPS_FOLDER_NAME)
if hoopsFolder then
	local function visit(container: Instance)
		for _, child in ipairs(container:GetDescendants()) do
			if child:IsA("BasePart") then
				connectHoop(child)
			end
		end
	end
	visit(hoopsFolder)
	hoopsFolder.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") then
			connectHoop(desc)
		end
	end)
end

print("HoopRewards: Initialized (tags: Hoop/SpeedHoop/HoopTrigger, folder: Hoops)")
