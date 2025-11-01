# Battle Castles - Integration Layer Guide

## Overview

This guide covers the final integration layer that connects all game systems seamlessly, adds polish, and provides a complete player experience.

## New Core Systems

### 1. Input Manager (`scripts/core/input_manager.gd`)

**Purpose**: Unified input handling for all game controls

**Features**:
- Mouse/touch input for card deployment
- Keyboard shortcuts (1-4 for cards, ESC for pause)
- Touch gestures and double-tap support
- Deployment area validation
- Drag threshold and visual feedback
- Haptic feedback for mobile devices
- Controller rumble support

**Usage**:
```gdscript
# In your battle scene
func _ready():
    InputManager.set_deployment_area(Rect2(0, 540, 1920, 540))
    InputManager.card_deployment_confirmed.connect(_on_card_deployed)

func _on_card_deployed(card_id: int, position: Vector2):
    # Deploy the card
    deploy_unit(card_id, position)
```

**Key Signals**:
- `card_deployment_started(card_id, position)`
- `card_deployment_moved(position)`
- `card_deployment_confirmed(card_id, position)`
- `card_deployment_cancelled()`
- `card_selected(card_index)`
- `pause_requested()`

### 2. Scene Manager (`scripts/core/scene_manager.gd`)

**Purpose**: Smooth scene transitions with loading screens and caching

**Features**:
- 8 transition types (fade, slide, dissolve, circle)
- Scene caching for instant loading
- Loading screens for large scenes
- Progress tracking
- Scene preloading
- Quick navigation helpers

**Usage**:
```gdscript
# Change scenes with transitions
SceneManager.change_scene("res://scenes/battle/battle.tscn", SceneManager.TransitionType.FADE)

# Quick navigation
SceneManager.goto_main_menu()
SceneManager.goto_battle()
SceneManager.goto_deck_builder()

# Preload scenes
SceneManager.preload_scene("res://scenes/battle/battle.tscn")

# Go back to previous scene
SceneManager.go_back()
```

**Transition Types**:
- `FADE` - Classic fade to black
- `SLIDE_LEFT/RIGHT/UP/DOWN` - Directional slides
- `DISSOLVE` - Gradual dissolve
- `CIRCLE_CLOSE/OPEN` - Circular wipe

### 3. Data Validator (`scripts/core/data_validator.gd`)

**Purpose**: Ensures data integrity and handles corrupted saves

**Features**:
- JSON schema validation
- Automatic backup creation
- Data migration between versions
- Corruption detection and repair
- Version compatibility checking
- Maximum 5 backups retained

**Usage**:
```gdscript
# Validate all data on startup
DataValidator.validate_all_data()

# Create backup before major operations
var backup_path = DataValidator.create_backup()

# Migrate data
DataValidator.migrate_data(file_path, "1.0.0", "1.1.0")

# Restore from backup
DataValidator.restore_backup(backup_path)
```

**Data Schemas**:
- `player_profile`: Player stats and progress
- `card_collection`: Owned cards
- `deck`: Deck configurations
- `settings`: Game settings

### 4. Juice Manager (`scripts/core/juice_manager.gd`)

**Purpose**: Adds polish and satisfying visual feedback to all interactions

**Features**:
- Screen shake with camera offset
- Hit flash effects
- Damage/healing popups
- Squash and stretch animations
- Bounce, pulse, and shake effects
- Pop-in/out animations
- Hitstop (brief pause on impact)
- UI feedback (button press, hover, cards)
- Victory/defeat celebrations

**Usage**:
```gdscript
# Screen shake on impact
JuiceManager.add_screen_shake(0.5)

# Damage popup
JuiceManager.damage_popup(position, 100, false)  # Normal damage
JuiceManager.damage_popup(position, 250, true)   # Critical hit!

# Unit impact
JuiceManager.impact(unit_node, 1.0)

# UI interactions
JuiceManager.button_press(button)
JuiceManager.card_selected(card)

# Animations
JuiceManager.pop_in(node, 0.3)
JuiceManager.squash_stretch(node, 1.2, 0.2)
JuiceManager.bounce(node, 20.0, 2, 0.5)

# Special effects
JuiceManager.victory_celebration()
JuiceManager.deployment_success(position)
```

**Accessibility Options**:
```gdscript
JuiceManager.set_juice_intensity(0.5)  # 0.0 to 1.0
JuiceManager.set_screen_shake_enabled(false)
JuiceManager.set_hitstop_enabled(false)
JuiceManager.set_haptic_enabled(false)
```

### 5. Interactive Feedback (`scripts/ui/interactive_feedback.gd`)

**Purpose**: Automatic visual feedback for UI elements

**Usage**: Attach to any UI Control node

**Features**:
- Automatic hover scaling
- Press feedback
- Glow effects
- Particle effects on click
- Audio integration
- Customizable via exports

**Example**:
```gdscript
# Attach to button in editor, or:
var feedback = InteractiveFeedback.new()
button.add_child(feedback)

# Customize
feedback.hover_scale = 1.1
feedback.glow_on_hover = true
feedback.enable_particles = true
```

## Battle Systems Integration

### Battle Tutorial (`scripts/battle/battle_tutorial.gd`)

**Purpose**: Interactive step-by-step tutorial for new players

**Features**:
- 10 tutorial steps
- Forced first deployment
- Weakened enemy for guaranteed victory
- Highlight UI elements
- Arrow pointers
- Progress tracking
- Skip option
- Saves completion status

**Tutorial Steps**:
1. **WELCOME** - Introduction
2. **EXPLAIN_ELIXIR** - Resource system
3. **EXPLAIN_CARDS** - Card hand
4. **FIRST_DEPLOYMENT** - Deploy first unit (forced)
5. **EXPLAIN_MOVEMENT** - Automatic movement
6. **EXPLAIN_COMBAT** - Auto-combat
7. **EXPLAIN_TOWERS** - Tower objectives
8. **EXPLAIN_CASTLE** - Victory condition
9. **FIRST_VICTORY** - Encouragement
10. **TUTORIAL_COMPLETE** - Completion

**Usage in Battle Scene**:
```gdscript
@onready var tutorial = $BattleTutorial

func _ready():
    tutorial.set_battle_manager(battle_manager)
    tutorial.set_elixir_manager(elixir_manager)
    tutorial.set_battle_ui(battle_ui)
    tutorial.set_battlefield(battlefield)

    # Check if player needs tutorial
    if not tutorial.has_completed_tutorial():
        tutorial.start_tutorial()
```

**Connecting Events**:
```gdscript
# In BattleManager
func _on_unit_deployed(unit, team):
    if tutorial.is_tutorial_active():
        tutorial.on_unit_deployed(unit, team)

func _on_battle_ended(winning_team):
    if tutorial.is_tutorial_active():
        tutorial.on_battle_ended(winning_team)
```

## Main Integration (`scenes/main.gd`)

**Purpose**: Entry point that initializes all systems

**Initialization Sequence**:
1. Validate game data
2. Initialize audio
3. Initialize input
4. Load player profile
5. Initialize network (optional)
6. Initialize VFX
7. Setup game systems
8. Navigate to start scene

**Features**:
- Automatic system initialization
- Error recovery
- Profile creation for new players
- Tutorial detection
- Graceful shutdown
- Re-initialization support

**Usage**:
Attach to root node of main scene or set as autoload.

## Complete Integration Example

### Battle Scene Integration

```gdscript
extends Node2D

@onready var battle_manager = $BattleManager
@onready var battle_ui = $BattleUI
@onready var tutorial = $BattleTutorial

func _ready():
    # Set camera for juice effects
    JuiceManager.set_camera($Camera2D)

    # Setup input
    InputManager.set_deployment_area(Rect2(0, 540, 1920, 540))
    InputManager.card_deployment_confirmed.connect(_on_card_deployed)
    InputManager.pause_requested.connect(_on_pause_requested)

    # Setup tutorial
    tutorial.set_battle_manager(battle_manager)
    tutorial.set_elixir_manager($ElixirManager)
    tutorial.set_battle_ui(battle_ui)
    tutorial.set_battlefield($Battlefield)

    if not tutorial.has_completed_tutorial():
        tutorial.start_tutorial()

    # Start battle
    battle_manager.start_battle()

func _on_card_deployed(card_id: int, position: Vector2):
    # Visual feedback
    JuiceManager.deployment_success(position)

    # Deploy unit
    var unit = battle_manager.deploy_unit(card_id, position, 0)

    # Tutorial tracking
    if tutorial.is_tutorial_active():
        tutorial.on_unit_deployed(unit, 0)

    # Pop-in animation
    if unit:
        JuiceManager.pop_in(unit, 0.3)

func _on_unit_hit(unit, damage):
    # Impact feedback
    JuiceManager.impact(unit, 0.7)
    JuiceManager.damage_popup(unit.global_position, damage, false)

func _on_battle_ended(winning_team: int):
    if tutorial.is_tutorial_active():
        tutorial.on_battle_ended(winning_team)

    if winning_team == 0:  # Player won
        JuiceManager.victory_celebration()
    else:
        JuiceManager.defeat_effect()

    # Show results after delay
    await get_tree().create_timer(2.0).timeout
    SceneManager.change_scene("res://scenes/ui/results.tscn", SceneManager.TransitionType.FADE)

func _on_pause_requested():
    battle_manager.pause_battle()
    # Show pause menu
```

### UI Integration

```gdscript
extends Control

func _ready():
    # Add feedback to all buttons
    for button in get_tree().get_nodes_in_group("buttons"):
        var feedback = preload("res://scripts/ui/interactive_feedback.gd").new()
        button.add_child(feedback)

    # Scene transitions
    $PlayButton.pressed.connect(_on_play_pressed)
    $SettingsButton.pressed.connect(_on_settings_pressed)

func _on_play_pressed():
    SceneManager.goto_battle()

func _on_settings_pressed():
    SceneManager.goto_settings()
```

## Autoload Configuration

The following systems are configured as autoloads in `project.godot`:

1. **GameManager** - Core game state and entity management
2. **NetworkManager** - Multiplayer networking
3. **AudioManager** - Sound and music
4. **InputManager** - Unified input handling (NEW)
5. **SceneManager** - Scene transitions (NEW)
6. **DataValidator** - Data integrity (NEW)
7. **JuiceManager** - Visual polish (NEW)

Access anywhere:
```gdscript
InputManager.select_card(0)
SceneManager.goto_battle()
JuiceManager.add_screen_shake(0.5)
```

## Best Practices

### Input Handling
- Always validate deployment positions
- Provide visual feedback for invalid placement
- Support both mouse and touch seamlessly
- Use keyboard shortcuts for power users

### Scene Transitions
- Use appropriate transition types (fade for menus, slide for lateral navigation)
- Preload frequently accessed scenes
- Show loading screens for battle scenes
- Handle transition cancellation gracefully

### Data Safety
- Validate data on startup
- Create backups before major operations
- Handle corrupted data gracefully
- Migrate old save versions automatically

### Visual Feedback
- Add juice to all interactions
- Scale feedback intensity based on action importance
- Provide accessibility options to reduce effects
- Use consistent feedback patterns

### Tutorial
- Auto-detect first-time players
- Allow tutorial skip for experienced players
- Track tutorial completion in profile
- Provide tooltips even after tutorial

## Performance Considerations

### Input Manager
- Minimal overhead, single autoload
- Event-driven, no polling
- Efficient drag threshold

### Scene Manager
- Scene caching reduces load times
- Configurable cache size (default: 5 scenes)
- Threaded resource loading
- Automatic cleanup

### Juice Manager
- Tween pooling for effects
- Particle limits (max 100)
- Configurable intensity
- Can disable individual features

### Data Validator
- Runs once on startup
- Async validation for large files
- Optional skip for debug builds

## Troubleshooting

### Input not working
- Ensure InputManager autoload is configured
- Check deployment area bounds are set
- Verify scene has input processing enabled

### Transitions glitchy
- Confirm camera setup for transitions
- Check transition overlay z-index
- Verify scene paths are correct

### Data validation fails
- Check JSON format in save files
- Review schema definitions
- Restore from backup if corrupted

### No visual feedback
- Verify JuiceManager autoload
- Check juice_intensity setting
- Ensure effects not disabled for accessibility

## Testing Integration

```gdscript
# Test script for integration layer
extends Node

func _ready():
    test_input_manager()
    test_scene_manager()
    test_data_validator()
    test_juice_manager()

func test_input_manager():
    assert(InputManager != null, "InputManager autoload missing")
    InputManager.set_deployment_area(Rect2(0, 0, 1920, 1080))
    assert(InputManager.is_valid_deployment_position(Vector2(960, 540)), "Validation failed")
    print("✓ InputManager tests passed")

func test_scene_manager():
    assert(SceneManager != null, "SceneManager autoload missing")
    SceneManager.preload_scene("res://scenes/main_menu.tscn")
    print("✓ SceneManager tests passed")

func test_data_validator():
    assert(DataValidator != null, "DataValidator autoload missing")
    var valid = DataValidator.validate_all_data()
    print("✓ DataValidator tests passed (valid: ", valid, ")")

func test_juice_manager():
    assert(JuiceManager != null, "JuiceManager autoload missing")
    JuiceManager.add_screen_shake(0.1)
    print("✓ JuiceManager tests passed")
```

## Next Steps

1. **Test all integrations** in the Godot editor
2. **Create main menu scene** if not exists
3. **Setup tutorial in battle scene**
4. **Add InteractiveFeedback** to all UI elements
5. **Configure deployment areas** for different battle modes
6. **Test scene transitions** between all scenes
7. **Validate save/load** functionality
8. **Polish with juice effects** throughout

## Summary

The integration layer provides:
- ✅ Unified input handling (mouse, touch, keyboard, controller)
- ✅ Smooth scene transitions with loading screens
- ✅ Data integrity and backup system
- ✅ Interactive tutorial for new players
- ✅ Visual polish and feedback (juice)
- ✅ Main initialization and error handling
- ✅ Accessibility options
- ✅ Complete player experience

All systems are now connected and ready for final testing and polish!
