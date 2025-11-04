# Loading Screen Documentation

## Overview
The loading screen provides visual feedback during scene transitions in Battle Castles.

## Files
- **Scene**: `/client/scenes/ui/loading_screen.tscn`
- **Script**: `/client/scripts/ui/loading_screen.gd`

## Features

### 1. Animated Spinner
- Rotating square spinner with hollow center
- Color: Blue (`Color(0.3, 0.6, 0.9, 1)`)
- Rotation speed: 3 radians/second
- Creates visual feedback for loading

### 2. Progress Bar
- Range: 0.0 to 1.0 (0% to 100%)
- Styled with rounded corners
- Background: Dark gray
- Fill: Blue (matches spinner)
- Automatically updates via SceneManager signals

### 3. Loading Text
- Font size: 24px
- Shows percentage (e.g., "Loading... 45%")
- Center aligned

### 4. Random Loading Tips
- 10 gameplay tips rotate randomly
- Font size: 16px
- Lighter gray color for subtlety
- Word wrap enabled for long tips
- Educates players during load times

### 5. Dark Theme Background
- Matches main menu and settings
- Color: `Color(0.05, 0.05, 0.08, 1)`
- Prevents eye strain during transitions

## Integration with SceneManager

### Automatic Loading
```gdscript
# SceneManager automatically loads the scene at startup
if ResourceLoader.exists("res://scenes/ui/loading_screen.tscn"):
    loading_screen_scene = load("res://scenes/ui/loading_screen.tscn")
```

### Display Lifecycle
1. **Show**: When loading large scenes (e.g., battle scenes)
   - Instantiated via `loading_screen_scene.instantiate()`
   - Added to root with `z_index = 999`
   - Automatically connects to `scene_load_progress` signal

2. **Update**: During loading
   - Receives progress updates from SceneManager
   - Updates progress bar and percentage text
   - Spinner continuously rotates

3. **Hide**: After scene loaded
   - Removed via `queue_free()`
   - Memory cleaned up automatically

## Scene Structure
```
LoadingScreen (Control)
├── Background (ColorRect) - Dark background
└── CenterContainer (CenterContainer)
    └── VBoxContainer (VBoxContainer)
        ├── SpinnerContainer (CenterContainer)
        │   └── Spinner (ColorRect) - Animated square
        │       ├── InnerCircle (ColorRect) - Hollow center
        │       └── TopRightCorner (ColorRect) - Visual detail
        ├── LoadingLabel (Label) - "Loading... X%"
        ├── ProgressBar (ProgressBar) - Progress indicator
        └── TipLabel (Label) - Random gameplay tips
```

## API Reference

### Public Methods

#### `set_progress(value: float)`
Update the progress bar value (0.0 to 1.0)
```gdscript
loading_screen.set_progress(0.5)  # 50%
```

#### `set_loading_text(text: String)`
Set custom loading text
```gdscript
loading_screen.set_loading_text("Loading assets...")
```

#### `show_tip(tip: String)`
Display a specific loading tip
```gdscript
loading_screen.show_tip("Tip: Use elixir wisely!")
```

#### `hide_tip()`
Hide the loading tip
```gdscript
loading_screen.hide_tip()
```

#### `reset()`
Reset to initial state
```gdscript
loading_screen.reset()
```

## Design Choices

### Why ColorRect for Spinner?
- Lightweight and fast to render
- No external assets required
- Rotation animation is smooth
- Easy to customize colors

### Why Random Tips?
- Educates new players
- Makes loading feel purposeful
- Reduces perceived wait time
- Adds personality to the game

### Why Progress Bar + Spinner?
- Progress bar: Concrete feedback (how much left)
- Spinner: Indicates activity (still loading)
- Together: Complete loading experience

### Why z_index = 999?
- Ensures loading screen is always on top
- Prevents rendering issues during transitions
- Set by SceneManager, not hardcoded

## Responsive Design
- Uses anchor presets for full screen coverage
- CenterContainer keeps content centered at all resolutions
- Custom minimum sizes prevent layout issues
- Works on all target platforms (PC, Mac, Raspberry Pi 5)

## Performance
- Minimal overhead (< 1ms per frame)
- No texture loading required
- Fast instantiation
- Proper cleanup with queue_free()

## Future Enhancements (Optional)
- [ ] Add particle effects
- [ ] Animated background
- [ ] Sound effects
- [ ] Multiple spinner designs
- [ ] Dynamic tips based on player progress
- [ ] Actual asset loading status

## Testing
The loading screen can be tested by:
1. Running the game
2. Navigating to battle scene (triggers loading)
3. Checking console for "SceneManager initialized"
4. Verifying smooth animations
5. Confirming proper cleanup

---
**Created**: November 4, 2025
**Last Updated**: November 4, 2025
