# Creating Flight Animations in Roblox Studio

## Basic Hovering Animation Tutorial

1. **Open Animation Editor**
   - Open Roblox Studio
   - Click View → Animation Editor
   - Click "Create New Animation"
   - Select R15 as the rig type

2. **Set Up Timeline**
   - Set animation length to 2 seconds
   - Enable "Loop" animation
   - Set keyframe interval to 0.1 seconds

3. **Create Hovering Animation**
   ```
   Frame 0:
   - UpperTorso: Position Y = 0
   - RightUpperArm: Rotation = (0, 30, 15)
   - LeftUpperArm: Rotation = (0, -30, -15)
   
   Frame 1:
   - UpperTorso: Position Y = 0.2
   - RightUpperArm: Rotation = (0, 35, 20)
   - LeftUpperArm: Rotation = (0, -35, -20)
   
   Frame 2:
   - UpperTorso: Position Y = 0
   - RightUpperArm: Rotation = (0, 30, 15)
   - LeftUpperArm: Rotation = (0, -30, -15)
   ```

4. **Save Animation**
   - Click "Save to Roblox"
   - Give it a name like "HoverFlight"
   - Copy the animation ID for use in your script

## Superman-Style Flight Animation

1. **Create New Animation**
   - Same initial setup as above
   - Set length to 1.5 seconds

2. **Key Poses**
   ```
   Frame 0:
   - UpperTorso: Rotation X = 15
   - RightUpperArm: Rotation = (0, 0, -90)
   - LeftUpperArm: Rotation = (0, 0, 90)
   - RightLowerArm: Rotation = (0, 0, 0)
   - LeftLowerArm: Rotation = (0, 0, 0)
   - RightUpperLeg: Rotation = (-15, 0, 0)
   - LeftUpperLeg: Rotation = (-15, 0, 0)
   
   Frame 0.75:
   - Subtle variations in arm positions
   
   Frame 1.5:
   - Return to Frame 0 positions
   ```

## Hyper Flight Animation

1. **Create New Animation**
   - Set length to 1 second
   - Enable faster keyframe rate (0.05 seconds)

2. **Key Poses**
   ```
   Frame 0:
   - UpperTorso: Rotation X = 30
   - Arms: Fully extended forward
   - Legs: Straight back
   - Add slight shake to entire body
   
   Frame 0.5:
   - Add intensity shake
   - Keep core pose the same
   
   Frame 1:
   - Return to Frame 0 pose
   ```

## Tips for All Animations

1. **Smooth Transitions**
   - Use "Ease In" for start of animations
   - Use "Ease Out" for end of animations
   - Enable "Loop" for continuous play

2. **Testing**
   - Use "Test" button in Animation Editor
   - Check animation from all angles
   - Ensure smooth looping

3. **Common Properties to Animate**
   - Torso rotation for flight angle
   - Arm positions for flying pose
   - Leg positions for aerodynamic look
   - Subtle body movement for "floating" effect

4. **After Saving**
   - Replace the animation IDs in your script:
   ```lua
   idleFlightAnimation.AnimationId = "rbxassetid://YOUR_HOVER_ID"
   fastFlightAnimation.AnimationId = "rbxassetid://YOUR_FAST_ID"
   hyperFlightAnimation.AnimationId = "rbxassetid://YOUR_HYPER_ID"
   ```

Remember to save each animation and copy its ID for use in your script. The IDs will be different for each animation you create. 