local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create toggle button GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeToggle"
screenGui.Parent = playerGui

-- Toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 60, 0, 60)
toggleButton.Position = UDim2.new(0, 20, 1, -80)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "⚙"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = screenGui

-- Corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toggleButton

-- Stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 170, 255)
stroke.Thickness = 2
stroke.Parent = toggleButton

-- Tooltip
local tooltip = Instance.new("TextLabel")
tooltip.Name = "Tooltip"
tooltip.Size = UDim2.new(0, 120, 0, 30)
tooltip.Position = UDim2.new(0, 70, 0, 15)
tooltip.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
tooltip.BorderSizePixel = 0
tooltip.Text = "Upgrade Menu"
tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
tooltip.TextScaled = true
tooltip.Font = Enum.Font.Gotham
tooltip.Parent = toggleButton
tooltip.Visible = false

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, 5)
tooltipCorner.Parent = tooltip

-- Function to toggle upgrade GUI
local function toggleUpgradeGUI()
	local upgradeGUI = playerGui:FindFirstChild("UpgradeGUI")
	if upgradeGUI then
		local mainFrame = upgradeGUI:FindFirstChild("MainFrame")
		if mainFrame then
			-- Directly control the GUI visibility
			local currentPosition = mainFrame.Position
			local isVisible = currentPosition.X.Offset > -200 -- Better visibility check

			local targetPosition
			if isVisible then
				-- Hide the GUI
				targetPosition = UDim2.new(0, -380, 0.5, -300)
				print("Hiding upgrade GUI")
			else
				-- Show the GUI
				targetPosition = UDim2.new(0, 20, 0.5, -300)
				print("Showing upgrade GUI")
			end

			local tween =
				TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = targetPosition,
				})
			tween:Play()

			print(
				"Toggled upgrade GUI. Current position:",
				currentPosition.X.Offset,
				"Target:",
				targetPosition.X.Offset
			)
		else
			print("MainFrame not found in UpgradeGUI")
		end
	else
		print("UpgradeGUI not found")
	end
end

-- Button click handler
toggleButton.MouseButton1Click:Connect(function()
	print("Upgrade toggle button clicked!")
	toggleUpgradeGUI()
end)

-- Show tooltip on hover
toggleButton.MouseEnter:Connect(function()
	tooltip.Visible = true
end)

toggleButton.MouseLeave:Connect(function()
	tooltip.Visible = false
end)

-- Add hover effect
toggleButton.MouseEnter:Connect(function()
	local tween = TweenService:Create(toggleButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromRGB(70, 170, 255),
	})
	tween:Play()
end)

toggleButton.MouseLeave:Connect(function()
	local tween = TweenService:Create(toggleButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromRGB(50, 150, 255),
	})
	tween:Play()
end)

-- Wait a moment for other GUIs to load, then verify everything is working
task.delay(2, function()
	local upgradeGUI = playerGui:FindFirstChild("UpgradeGUI")
	if upgradeGUI then
		print("✓ UpgradeGUI found and ready")
	else
		print("✗ UpgradeGUI not found - check if UpgradeGUI.client.luau is running")
	end
end)

print("Upgrade toggle button created in bottom left!")
