# Speed Leaderboard Stats Installation Guide

## Overview
This script creates a "Speed" leaderstat that appears in the top right of the leaderboard, showing each player's total calculated speed including all multipliers and progression.

## Installation

### 1. Place the Script
- Copy `SpeedLeaderboardStats.server.luau` to your `ServerScriptService` folder
- The script will automatically start working when the server runs

### 2. What It Does
- **Creates a "Speed" leaderstat** for each player in the top right of the leaderboard
- **Calculates total speed** including:
  - Base progression speed (from flight time)
  - Speed shop multipliers (purchased upgrades)
  - Tier 3 speed boost multiplier (2x boost)
  - Physics safety compression (matches FlightSystem)
- **Updates automatically** when:
  - Players join/leave
  - Speed multipliers are purchased
  - Player progression increases
  - Every 1 second (periodic updates)

### 3. How It Works
The script:
1. **Requires the PlayerData module** from your existing server setup
2. **Listens for speed multiplier updates** via the `UpdateMaxSpeedMultiplier` remote event
3. **Calculates total speed** using the same formula as your FlightSystem
4. **Positions the stat** in the top right by making it the last child in the leaderstats folder

### 4. Configuration
You can modify these settings at the top of the script:
```lua
local LEADERSTAT_NAME = "Speed"  -- Name shown in leaderboard
local UPDATE_INTERVAL = 1        -- Update frequency in seconds
```

### 5. Expected Behavior
- **New players**: Will see "Speed: 35" initially (base speed)
- **After progression**: Speed increases based on flight time
- **After purchases**: Speed updates immediately when multipliers are bought
- **Position**: Appears on the right side of the leaderboard

### 6. Troubleshooting
- **Script not working**: Check that PlayerData module is in the same folder
- **Speed not updating**: Verify the `UpdateMaxSpeedMultiplier` remote event exists
- **Wrong position**: The stat appears on the right side by default (last in leaderstats folder)

## Integration
This script integrates seamlessly with your existing:
- PlayerData system
- Speed multiplier purchase system
- Flight progression system
- Leaderboard display

No additional setup required - just place the script and it will work automatically!
