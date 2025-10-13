local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== EASY POSITION/SIZE TWEAKS =====
-- Edit these values to move/resize the panel without digging into code
local UI_CONFIG = {
	AnchorPoint = Vector2.new(1, 0.5), -- e.g., (0,0)=top-left, (1,0.5)=right-center
	Position = UDim2.new(1, -10, 0.5, -60), -- screen corner-relative position
	Size = UDim2.new(0, 220, 0, 120), -- width/height
}
-- =====================================

-- Globals used by FlightSystem (kept for compatibility with existing code)
_G.speedControlEnabled = _G.speedControlEnabled or false
_G.desiredSpeed = _G.desiredSpeed or nil

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedControlGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = UI_CONFIG.AnchorPoint
panel.Size = UI_CONFIG.Size
panel.Position = UI_CONFIG.Position
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 80)
stroke.Thickness = 2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.BorderSizePixel = 0
title.Text = "Speed Control"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local input = Instance.new("TextBox")
input.Name = "SpeedInput"
input.PlaceholderText = "Set Speed..."
input.Text = _G.desiredSpeed and tostring(_G.desiredSpeed) or ""
input.ClearTextOnFocus = false
input.Size = UDim2.new(1, -20, 0, 30)
input.Position = UDim2.new(0, 10, 0, 40)
input.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.TextScaled = true
input.Font = Enum.Font.Gotham
input.Parent = panel

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = input

local applyBtn = Instance.new("TextButton")
applyBtn.Name = "ApplyButton"
applyBtn.Text = "Set"
applyBtn.Size = UDim2.new(0.5, -15, 0, 30)
applyBtn.Position = UDim2.new(0, 10, 0, 80)
applyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
applyBtn.TextScaled = true
applyBtn.Font = Enum.Font.GothamBold
applyBtn.Parent = panel

local applyCorner = Instance.new("UICorner")
applyCorner.CornerRadius = UDim.new(0, 6)
applyCorner.Parent = applyBtn

local disableBtn = Instance.new("TextButton")
disableBtn.Name = "DisableButton"
disableBtn.Text = _G.speedControlEnabled and "On" or "Off"
disableBtn.Size = UDim2.new(0.5, -15, 0, 30)
disableBtn.Position = UDim2.new(0.5, 5, 0, 80)
disableBtn.BackgroundColor3 = _G.speedControlEnabled and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(80, 80, 90)
disableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
disableBtn.TextScaled = true
disableBtn.Font = Enum.Font.GothamBold
disableBtn.Parent = panel

local disableCorner = Instance.new("UICorner")
disableCorner.CornerRadius = UDim.new(0, 6)
disableCorner.Parent = disableBtn

local function parseNumber(text: string): number?
	local n = tonumber((text:gsub(",", "")))
	if n and n > 0 then
		return n
	end
	return nil
end

local function applyDesiredSpeed()
	local n = parseNumber(input.Text)
	if n then
		_G.desiredSpeed = n
		_G.speedControlEnabled = true
		disableBtn.Text = "On"
		disableBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	end
end

applyBtn.MouseButton1Click:Connect(applyDesiredSpeed)
input.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		applyDesiredSpeed()
	end
end)

disableBtn.MouseButton1Click:Connect(function()
	_G.speedControlEnabled = not _G.speedControlEnabled
	disableBtn.Text = _G.speedControlEnabled and "On" or "Off"
	disableBtn.BackgroundColor3 = _G.speedControlEnabled and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(80, 80, 90)
end)

print("SpeedControlGUI loaded")
