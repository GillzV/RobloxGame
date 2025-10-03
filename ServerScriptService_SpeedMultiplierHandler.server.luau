-- CRITICAL: This script MUST be in ServerScriptService for ProcessReceipt to work!
-- Copy this file to ServerScriptService in Roblox Studio

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

print("=== SERVERSERVICE SPEED MULTIPLIER HANDLER ===")
print("Script location:", script:GetFullName())
print("This script MUST be in ServerScriptService for ProcessReceipt to work!")

-- Wait for the main handler to load
local mainHandler = require(script.Parent.Parent.src.server.SpeedMultiplierHandler)

print("Main handler loaded successfully!")
print("ProcessReceipt is now properly set up in ServerScriptService")
