-- PlayerStats module for managing player statistics

local PlayerStats = {}

-- Default player stats
local DEFAULT_STATS = {
	level = 1,
	experience = 0,
	experienceToNext = 100,

	-- Speed upgrades
	speedLevel = 1,
	maxSpeedTier = 1, -- How many times they can boost (starts at 1)
	speedMultiplier = 1.0,
}

-- Experience required for each level (exponential growth)
local function getExperienceForLevel(level)
	return math.floor(100 * (1.5 ^ (level - 1)))
end

-- Speed tier unlock requirements
local function getMaxSpeedTierForLevel(level)
	if level >= 4 then
		return 3 -- Max speed tier
	else
		return 2 -- Fast flight accessible from level 1
	end
end

-- Speed multiplier calculation
local function getSpeedMultiplierForLevel(level)
	return 1.0 + (level - 1) * 0.2 -- 20% increase per level
end

function PlayerStats.new()
	local stats = table.clone(DEFAULT_STATS)

	-- Calculate initial values
	stats.maxSpeedTier = getMaxSpeedTierForLevel(stats.level)
	stats.speedMultiplier = getSpeedMultiplierForLevel(stats.speedLevel)

	return stats
end

function PlayerStats.addExperience(stats, amount)
	stats.experience = stats.experience + amount

	-- Check for level up
	while stats.experience >= stats.experienceToNext do
		stats.experience = stats.experience - stats.experienceToNext
		stats.level = stats.level + 1
		stats.experienceToNext = getExperienceForLevel(stats.level)

		-- Update max speed tier based on new level
		stats.maxSpeedTier = getMaxSpeedTierForLevel(stats.level)

		print("Level up! New level:", stats.level)
	end
end

function PlayerStats.upgradeSpeed(stats)
	stats.speedLevel = stats.speedLevel + 1
	stats.speedMultiplier = getSpeedMultiplierForLevel(stats.speedLevel)
	return true
end

function PlayerStats.getSpeedTiers(stats)
	local baseSpeed = 35
	local tiers = {}

	for i = 1, stats.maxSpeedTier do
		tiers[i] = math.floor(baseSpeed * stats.speedMultiplier * (1.5 ^ (i - 1)))
	end

	return tiers
end

-- Helper functions for server
function PlayerStats.getMaxSpeedTierForLevel(level)
	return getMaxSpeedTierForLevel(level)
end

function PlayerStats.getSpeedMultiplierForLevel(level)
	return getSpeedMultiplierForLevel(level)
end

return PlayerStats
