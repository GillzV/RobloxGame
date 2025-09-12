-- PlayerStats module for managing player statistics

local PlayerStats = {}

-- ===== CONFIGURABLE SPEED PROGRESSION SETTINGS =====
local SPEED_CONFIG = {
	BASE_SPEED = 35, -- Starting max speed
	SPEED_INCREASE = 1, -- Speed gained per interval (1 studs/s every 1 second)
	TIME_INTERVAL = 1, -- Time interval in seconds for speed gain
	MAX_SPEED_CAP = 1000, -- Maximum possible speed
}
-- ===================================================

-- Default player stats
local DEFAULT_STATS = {
	-- Progressive speed system
	maxSpeed = SPEED_CONFIG.BASE_SPEED, -- Current maximum speed (starts at base speed)
	flightTime = 0, -- Total time spent flying (for speed progression)
}

-- Progressive speed calculation
local function calculateMaxSpeed(flightTime)
	-- Uses configurable settings for speed progression
	local baseSpeed = SPEED_CONFIG.BASE_SPEED
	-- Calculate gradual increase: speed increases by SPEED_INCREASE every TIME_INTERVAL seconds
	local speedIncrease = (flightTime / SPEED_CONFIG.TIME_INTERVAL) * SPEED_CONFIG.SPEED_INCREASE
	local maxSpeed = baseSpeed + speedIncrease

	-- Cap at configured maximum speed
	return math.min(maxSpeed, SPEED_CONFIG.MAX_SPEED_CAP)
end

function PlayerStats.new()
	local stats = table.clone(DEFAULT_STATS)

	-- Calculate initial max speed
	stats.maxSpeed = calculateMaxSpeed(stats.flightTime)

	return stats
end

function PlayerStats.addFlightTime(stats, deltaTime)
	stats.flightTime = stats.flightTime + deltaTime

	-- Update max speed based on new flight time
	local newMaxSpeed = calculateMaxSpeed(stats.flightTime)
	if newMaxSpeed > stats.maxSpeed then
		stats.maxSpeed = newMaxSpeed
		print("Speed increased! New max speed:", stats.maxSpeed)
	end
end

function PlayerStats.getMaxSpeed(stats)
	local maxSpeed = stats.maxSpeed or SPEED_CONFIG.BASE_SPEED
	-- Ensure it doesn't exceed the cap
	return math.min(maxSpeed, SPEED_CONFIG.MAX_SPEED_CAP)
end

function PlayerStats.getFlightTime(stats)
	return stats.flightTime or 0
end

return PlayerStats
