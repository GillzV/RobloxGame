local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

	-- Strength upgrades
	strengthLevel = 1,
	damageMultiplier = 1.0,

	-- Health upgrades
	healthLevel = 1,
	maxHealth = 100,
	healthRegenRate = 1.0,

	-- Currency
	coins = 0,

	-- Upgrade costs (increases with level)
	upgradeCosts = {
		speed = 50,
		strength = 75,
		health = 100,
	},
}

-- Experience required for each level (exponential growth)
local function getExperienceForLevel(level)
	return math.floor(100 * (1.5 ^ (level - 1)))
end

-- Speed tier unlock requirements
local function getMaxSpeedTierForLevel(level)
	if level >= 10 then
		return 4 -- Max speed tier
	elseif level >= 7 then
		return 3
	elseif level >= 4 then
		return 2
	else
		return 1
	end
end

-- Speed multiplier calculation
local function getSpeedMultiplierForLevel(level)
	return 1.0 + (level - 1) * 0.2 -- 20% increase per level
end

-- Damage multiplier calculation
local function getDamageMultiplierForLevel(level)
	return 1.0 + (level - 1) * 0.15 -- 15% increase per level
end

-- Health calculation
local function getMaxHealthForLevel(level)
	return 100 + (level - 1) * 25 -- 25 health per level
end

-- Health regen calculation
local function getHealthRegenForLevel(level)
	return 1.0 + (level - 1) * 0.1 -- 10% regen increase per level
end

-- Upgrade cost calculation
local function getUpgradeCost(baseCost, currentLevel)
	return math.floor(baseCost * (1.3 ^ (currentLevel - 1)))
end

function PlayerStats.new()
	local stats = {}

	-- Copy default stats
	for key, value in pairs(DEFAULT_STATS) do
		stats[key] = value
	end

	-- Calculate initial values
	stats.maxSpeedTier = getMaxSpeedTierForLevel(stats.level)
	stats.speedMultiplier = getSpeedMultiplierForLevel(stats.speedLevel)
	stats.damageMultiplier = getDamageMultiplierForLevel(stats.strengthLevel)
	stats.maxHealth = getMaxHealthForLevel(stats.healthLevel)
	stats.healthRegenRate = getHealthRegenForLevel(stats.healthLevel)

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

		-- Give coins for leveling up
		stats.coins = stats.coins + (stats.level * 10)

		print("Level up! New level:", stats.level)
	end
end

function PlayerStats.canUpgradeSpeed(stats)
	return stats.coins >= stats.upgradeCosts.speed
end

function PlayerStats.upgradeSpeed(stats)
	if PlayerStats.canUpgradeSpeed(stats) then
		stats.coins = stats.coins - stats.upgradeCosts.speed
		stats.speedLevel = stats.speedLevel + 1
		stats.speedMultiplier = getSpeedMultiplierForLevel(stats.speedLevel)
		stats.upgradeCosts.speed = getUpgradeCost(50, stats.speedLevel)
		return true
	end
	return false
end

function PlayerStats.canUpgradeStrength(stats)
	return stats.coins >= stats.upgradeCosts.strength
end

function PlayerStats.upgradeStrength(stats)
	if PlayerStats.canUpgradeStrength(stats) then
		stats.coins = stats.coins - stats.upgradeCosts.strength
		stats.strengthLevel = stats.strengthLevel + 1
		stats.damageMultiplier = getDamageMultiplierForLevel(stats.strengthLevel)
		stats.upgradeCosts.strength = getUpgradeCost(75, stats.strengthLevel)
		return true
	end
	return false
end

function PlayerStats.canUpgradeHealth(stats)
	return stats.coins >= stats.upgradeCosts.health
end

function PlayerStats.upgradeHealth(stats)
	if PlayerStats.canUpgradeHealth(stats) then
		stats.coins = stats.coins - stats.upgradeCosts.health
		stats.healthLevel = stats.healthLevel + 1
		stats.maxHealth = getMaxHealthForLevel(stats.healthLevel)
		stats.healthRegenRate = getHealthRegenForLevel(stats.healthLevel)
		stats.upgradeCosts.health = getUpgradeCost(100, stats.healthLevel)
		return true
	end
	return false
end

function PlayerStats.addCoins(stats, amount)
	stats.coins = stats.coins + amount
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

function PlayerStats.getDamageMultiplierForLevel(level)
	return getDamageMultiplierForLevel(level)
end

function PlayerStats.getMaxHealthForLevel(level)
	return getMaxHealthForLevel(level)
end

function PlayerStats.getHealthRegenForLevel(level)
	return getHealthRegenForLevel(level)
end

return PlayerStats
