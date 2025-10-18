# Roblox Flight Game

A 3D flight game with building destruction, leveling system, and upgrade mechanics.

## Features

### Flight System
- Press `F` to toggle flight mode
- Use `WASD` to move horizontally
- Use `Space` to ascend, `Left Shift` to descend
- Press `Q` to boost speed (limited by your level)

### Leveling System
- **Experience**: Gain XP by flying and destroying buildings
- **Leveling**: Each level unlocks more speed tiers and gives coins
- **Speed Tiers**: 
  - Level 1-3: 1 boost
  - Level 4-6: 2 boosts  
  - Level 7-9: 3 boosts
  - Level 10+: 4 boosts (max)

### Upgrade System
- **Speed Upgrade**: Increases flight speed multiplier (20% per level)
- **Strength Upgrade**: Increases damage multiplier (15% per level)
- **Health Upgrade**: Increases max health and regeneration (25 HP per level)

### Currency System
- **Coins**: Earned by flying, destroying buildings, and leveling up
- **Upgrade Costs**: Increase exponentially with each level
- **Rewards**: 
  - Flying: 1-5 XP per frame, occasional coins
  - Building Destruction: 50 XP + 25 coins

### GUI Features
- Modern upgrade interface with smooth animations
- Real-time stats display (level, XP, coins, speed tiers)
- Toggle button to show/hide the upgrade panel
- Visual feedback for affordable vs unaffordable upgrades

## Controls
- `F`: Toggle flight mode
- `WASD`: Move horizontally
- `Space`: Ascend
- `Left Shift`: Descend  
- `Q`: Boost speed (when flying)
- Click the gear icon (⚙) to toggle upgrade GUI

## Technical Details

### File Structure
```
src/
├── client/
│   ├── FlightSystem.client.luau    # Main flight mechanics
│   └── UpgradeGUI.client.luau      # Upgrade interface
├── server/
│   ├── init.server.luau            # Server initialization
│   ├── PlayerData.server.luau      # Player data management
│   ├── BuildingCollapse.server.luau # Building destruction
│   
└── shared/
    └── PlayerStats.luau            # Stats calculation module
```

### Data Persistence
- Player stats are saved to DataStore
- Automatic saving every minute
- Data includes: level, experience, coins, upgrade levels

### Performance
- Efficient building collision detection
- Optimized GUI updates
- Smooth animations and visual effects

## Getting Started
1. Join the game
2. Press `F` to start flying
3. Destroy buildings to earn XP and coins
4. Use the upgrade GUI to improve your character
5. Level up to unlock more speed tiers!

## Development Notes
- Built with Luau scripting language
- Uses Roblox's built-in services (DataStore, TweenService, etc.)
- Modular design for easy maintenance and expansion