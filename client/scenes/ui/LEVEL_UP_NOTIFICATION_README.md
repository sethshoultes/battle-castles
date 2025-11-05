# Level-Up Notification System

## Overview
The Level-Up Notification System provides a celebratory visual and audio experience when players gain enough experience to level up. The system automatically listens to the PlayerProfile's `level_up` signal and displays an animated popup showing the new level and rewards earned.

## Features
- **Automatic Signal Handling**: Automatically connects to GameManager.player_profile.level_up signal
- **Celebratory Animations**:
  - Bouncing panel entrance with elastic easing
  - Pulsing "LEVEL UP!" text
  - Rotating and scaling level badge
  - Staggered reward item animations
  - Particle effects (confetti, sparkles, glow)
- **Reward Display**:
  - Gold rewards with gold coin icon
  - Gem rewards with gem icon (shown when > 0)
  - Special chests (Golden, Giant, Magical, Super Magical, Legendary)
- **Audio Feedback**:
  - Level-up sound effect
  - Reward reveal sound effect
- **User Interaction**:
  - Continue button to dismiss
  - ESC key to close
  - Click outside panel to close

## Files Created

### Scripts
1. **`/scripts/ui/level_up_notification.gd`**
   - Main notification controller
   - Handles animations, particle effects, and user input
   - Automatically connects to PlayerProfile signals

2. **`/scripts/ui/notification_manager.gd`**
   - Global autoload manager for notifications
   - Manages the level-up notification instance
   - Ensures notifications appear on top of all UI (layer 100)

3. **`/scripts/ui/level_up_test.gd`**
   - Test UI for triggering level-up notifications
   - Provides buttons to add XP or force level-up

### Scenes
1. **`/scenes/ui/level_up_notification.tscn`**
   - Complete UI layout for the notification
   - Styled panel with golden border
   - Reward containers with icons and labels
   - Continue button

2. **`/scenes/tests/level_up_test.tscn`**
   - Test scene for demonstration
   - Shows current level and XP
   - Buttons to trigger level-up

## Integration

### Autoload Setup
The `NotificationManager` has been added to the project autoloads in `project.godot`:

```ini
[autoload]
NotificationManager="*res://scripts/ui/notification_manager.gd"
```

### Signal Connection
The notification automatically connects to the PlayerProfile's level_up signal:

```gdscript
# In level_up_notification.gd
func _connect_to_player_profile() -> void:
    if GameManager and GameManager.player_profile:
        GameManager.player_profile.level_up.connect(_on_level_up)
```

### How It Works

1. **Player gains XP** → `PlayerProfile.add_experience(amount)` is called
2. **Level threshold reached** → PlayerProfile emits `level_up` signal with parameters:
   - `new_level: int` - The level just reached
   - `rewards: Dictionary` - Rewards earned for leveling up
3. **Notification receives signal** → `_on_level_up()` is triggered
4. **Animation sequence plays**:
   - Background overlay fades in
   - Panel bounces into view
   - "LEVEL UP!" text pulses
   - Confetti particles emit
   - Level badge animates with rotation
   - Rewards appear with stagger effect
   - Continue button fades in
5. **User dismisses** → Notification fades out and becomes hidden

## Reward Structure

The rewards dictionary from PlayerProfile follows this structure:

```gdscript
{
    "gold": 200,           # Base gold: level * 100
    "gems": 10,            # Every 5 levels: level * 2
    "chest_type": "golden" # Special chests at milestone levels
}
```

### Milestone Rewards
- **Level 10**: Golden Chest
- **Level 20**: Giant Chest
- **Level 30**: Magical Chest
- **Level 40**: Super Magical Chest
- **Level 50**: Legendary Chest + 500 Gems

## Usage Examples

### Triggering Level-Up Programmatically
```gdscript
# Add enough XP to level up
GameManager.player_profile.add_experience(500)

# The notification will automatically appear when level threshold is reached
```

### Direct Notification (Testing Only)
```gdscript
# For testing purposes, you can show the notification directly
NotificationManager.show_level_up(5, {
    "gold": 500,
    "gems": 10,
    "chest_type": "golden"
})
```

### Listening to Notification Close
```gdscript
# Connect to the notification_closed signal if needed
if NotificationManager and NotificationManager.level_up_notification:
    NotificationManager.level_up_notification.notification_closed.connect(_on_notification_closed)

func _on_notification_closed() -> void:
    print("Player dismissed the level-up notification")
    # Resume gameplay or perform other actions
```

## Testing

### Using the Test Scene
1. Open `res://scenes/tests/level_up_test.tscn`
2. Run the scene
3. Click "Trigger Level Up" to see the notification
4. Click "Add 50 XP" to gradually level up

### In Battle Results Screen
The notification can be triggered after battles by calling:
```gdscript
# After battle ends
var xp_earned = calculate_battle_xp()
GameManager.player_profile.add_experience(xp_earned)
# Notification appears automatically if player levels up
```

## Customization

### Adjusting Animation Speed
Edit the tween durations in `level_up_notification.gd`:
```gdscript
# Example: Speed up the entrance animation
tween.tween_property(notification_panel, "scale", Vector2(1.1, 1.1), 0.2)  # Was 0.4
```

### Changing Colors
Modify the color values in `_setup_ui()`:
```gdscript
level_up_label.modulate = Color(1.0, 0.9, 0.2, 1.0)  # Gold color
level_badge.modulate = Color(1.0, 0.8, 0.0, 1.0)      # Badge color
```

### Particle Effects
Particle effects are created using the `ParticleEffects` class:
- Confetti: `ParticleEffects.create_victory_confetti()`
- Sparkles: `ParticleEffects.create_from_preset("sparkle", {...})`
- Glow: Custom configuration with glow texture

### Audio
Replace the placeholder audio files:
- `res://audio/sfx/level_up.ogg` - Plays when notification appears
- `res://audio/sfx/reward.ogg` - Plays when rewards are revealed

## Architecture

### Component Hierarchy
```
NotificationManager (CanvasLayer - Autoload)
└── LevelUpNotification (Control)
    ├── BackgroundOverlay (ColorRect)
    ├── NotificationPanel (Panel)
    │   ├── VBoxContainer
    │   │   ├── LevelUpLabel
    │   │   ├── NewLevelContainer
    │   │   │   └── LevelBadge (Panel)
    │   │   │       └── LevelNumber (Label)
    │   │   ├── RewardsContainer (VBoxContainer)
    │   │   │   ├── RewardsTitle
    │   │   │   ├── GoldReward (HBoxContainer)
    │   │   │   ├── GemsReward (HBoxContainer)
    │   │   │   └── ChestReward (HBoxContainer)
    │   │   └── ContinueButton
    │   ├── SparkleParticles (GPUParticles2D)
    │   └── GlowParticles (GPUParticles2D)
    ├── ConfettiParticles (GPUParticles2D)
    ├── AnimationPlayer
    ├── LevelUpSound (AudioStreamPlayer)
    └── RewardSound (AudioStreamPlayer)
```

### Signal Flow
```
PlayerProfile.add_experience()
    ↓
PlayerProfile.level_up (signal)
    ↓
LevelUpNotification._on_level_up()
    ↓
LevelUpNotification.show_notification()
    ↓
[Animation Sequence]
    ↓
User clicks Continue/ESC/Outside
    ↓
LevelUpNotification.hide_notification()
    ↓
LevelUpNotification.notification_closed (signal)
```

## Performance Considerations

- **Particle Systems**: Uses GPUParticles2D for efficient rendering
- **Tweens**: All animations use Godot's Tween system (no update loop)
- **One-shot Particles**: Confetti is set to one_shot to avoid continuous emission
- **Deferred Signal Connection**: Connects to PlayerProfile after scene is ready
- **Layer Isolation**: Runs on CanvasLayer 100 to avoid z-index conflicts

## Known Limitations

1. **Audio Placeholders**: Audio files reference placeholder UIDs - replace with actual sound files
2. **Single Instance**: Only one level-up notification can be shown at a time
3. **No Queue**: Multiple level-ups in quick succession will only show the latest
4. **Modal Behavior**: Blocks input to underlying UI (by design)

## Future Enhancements

Potential improvements for future iterations:
- [ ] Add skip animation option for players who want faster feedback
- [ ] Queue multiple level-ups if player gains many levels at once
- [ ] Add level-specific themes or colors for milestone levels
- [ ] Integrate with achievement system for combo notifications
- [ ] Add screenshot/share functionality
- [ ] Animate the level badge with a shine/shimmer effect
- [ ] Add voice-over for "LEVEL UP!" announcement

## Troubleshooting

### Notification doesn't appear
- Check that NotificationManager is properly loaded as autoload
- Verify GameManager.player_profile exists and is initialized
- Ensure PlayerProfile is emitting the level_up signal
- Check console for connection messages

### Particles don't show
- Verify ParticleEffects class is available
- Check that particle nodes are properly created
- Ensure particle emitting is set to true

### Audio doesn't play
- Replace placeholder audio file references
- Check AudioManager volume settings
- Verify audio files exist at specified paths

## Credits

- **Design Pattern**: Modal notification with celebration theme
- **Animation Style**: Elastic/bounce with staggered reveals
- **Particle Effects**: Using Battle Castles VFX system
- **Integration**: Leverages existing PlayerProfile progression system
