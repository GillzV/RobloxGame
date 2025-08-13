local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Test function to manually trigger GUI updates
local function testGUI()
	print("Testing GUI systems...")

	-- Test notification system
	if _G.NotificationSystem then
		_G.NotificationSystem.showXP(25)
		wait(1)
		_G.NotificationSystem.showCoins(50)
		wait(1)
		_G.NotificationSystem.showLevelUp(2)
		wait(1)
		_G.NotificationSystem.showUpgrade("SPEED")
	else
		print("Notification system not found!")
	end

	-- Test remote events
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local addExperienceEvent = remotes:WaitForChild("AddExperience")
	local addCoinsEvent = remotes:WaitForChild("AddCoins")

	-- Send test data to server
	addExperienceEvent:FireServer(100)
	addCoinsEvent:FireServer(200)

	print("GUI test completed!")
end

-- Test upgrade GUI toggle specifically
local function testUpgradeToggle()
	print("Testing upgrade GUI toggle...")

	local playerGui = player:WaitForChild("PlayerGui")
	local upgradeGUI = playerGui:FindFirstChild("UpgradeGUI")

	if upgradeGUI then
		local mainFrame = upgradeGUI:FindFirstChild("MainFrame")
		if mainFrame then
			print("Current GUI position:", mainFrame.Position.X.Offset)

			-- Test toggle functionality
			local currentPosition = mainFrame.Position
			local isVisible = currentPosition.X.Offset > -200

			local targetPosition
			if isVisible then
				targetPosition = UDim2.new(0, -380, 0.5, -300)
				print("Hiding GUI...")
			else
				targetPosition = UDim2.new(0, 20, 0.5, -300)
				print("Showing GUI...")
			end

			-- Use TweenService to animate
			local TweenService = game:GetService("TweenService")
			local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {
				Position = targetPosition,
			})
			tween:Play()

			print("GUI toggle test completed!")
		else
			print("MainFrame not found!")
		end
	else
		print("UpgradeGUI not found!")
	end
end

-- Bind test to keys
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		testGUI()
	elseif input.KeyCode == Enum.KeyCode.Y then
		testUpgradeToggle()
	end
end)

print("GUI Test script loaded! Press T to test GUI systems, Y to test upgrade toggle.")
