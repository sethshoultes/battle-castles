# Configuration System Documentation

## Overview

The configuration system replaces hardcoded values throughout the Battle Castles codebase with data-driven resource files. This implements the project's core principle: **"NO Hardcoded Values - everything data-driven"**.

## Architecture

### Config Resource Classes

#### 1. BattlefieldConfig (`battlefield_config.gd`)
**Location:** `/client/scripts/resources/battlefield_config.gd`

Manages all battlefield layout and grid configuration:

**Grid Settings:**
- `tile_size` (64) - Size of each grid tile in pixels
- `grid_width` (18) - Number of tiles horizontally
- `grid_height` (28) - Number of tiles vertically

**River Settings:**
- `river_position_tile` (14) - Y-position of river in tiles
- `river_width` (64) - Width of river visual in pixels

**Deployment Zones:**
- `player_deploy_start_y` (16) - Player zone start tile
- `player_deploy_end_y` (27) - Player zone end tile
- `opponent_deploy_start_y` (1) - Opponent zone start tile
- `opponent_deploy_end_y` (12) - Opponent zone end tile

**Unit Limits:**
- `max_units_total` (50) - Maximum total units on battlefield
- `max_units_per_team` (30) - Maximum units per team

**Team Configuration:**
- `team_player` (0) - Player team ID
- `team_opponent` (1) - Opponent team ID

**Tower Positions:**
- Player towers: Left (3,20), Right (14,20), Castle (8,23)
- Opponent towers: Left (14,4), Right (3,4), Castle (8,3)

**Visual Settings:**
- Grid colors, deployment zone colors, river colors

#### 2. GameBalanceConfig (`game_balance_config.gd`)
**Location:** `/client/scripts/resources/game_balance_config.gd`

Manages all gameplay balance and tuning values:

**Elixir System:**
- `starting_elixir` (5.0) - Starting elixir for both players
- `max_elixir` (10.0) - Maximum elixir capacity
- `elixir_generation_rate` (0.357) - Elixir per second (1 per 2.8s)
- `double_elixir_start_time` (120.0) - When double elixir starts

**Battle Timing:**
- `match_duration` (180.0) - Battle duration in seconds (3 minutes)
- `overtime_duration` (60.0) - Overtime duration if tied

**AI Configuration:**
- `ai_starting_elixir` (5.0) - AI starting elixir
- `ai_max_elixir` (10.0) - AI maximum elixir
- `ai_elixir_reserve` (1.5) - AI keeps this much in reserve
- `ai_decision_interval` (1.0) - AI checks for actions every N seconds

**AI Difficulty Modifiers:**
- Easy: 2.0s reaction delay, 2.0 elixir reserve
- Medium: 1.0s reaction delay, 1.5 elixir reserve
- Hard: 0.5s reaction delay, 0.5 elixir reserve

**Unit Physics:**
- `unit_collision_radius` (12.0) - Unit collision radius
- `unit_separation_force` (50.0) - Force pushing units apart
- `unit_max_speed` (100.0) - Maximum unit movement speed
- `unit_acceleration` (200.0) - Unit acceleration

**Combat Settings:**
- `tower_threat_radius` (400.0) - Range for AI threat detection
- `aggro_range_multiplier` (1.2) - Multiplier for unit aggro range
- `attack_cooldown_variance` (0.1) - Random variance in attack timing

**Visual and UI Settings:**
- `health_bar_width` (60.0) - Width of unit health bars
- `health_bar_height` (6.0) - Height of unit health bars
- `health_bar_offset_y` (-1.0) - Offset above unit head
- `unit_sprite_scale_multiplier` (3.0) - Sprite scale multiplier

**Deployment Settings:**
- `deployment_zone_margin` (100.0) - Margin from deployment zone edges
- `min_deployment_spacing` (32.0) - Minimum space between unit spawns

**Camera Settings:**
- `default_camera_zoom` (Vector2(1.0, 1.0)) - Default camera zoom
- `camera_smoothing` (5.0) - Camera movement smoothing

**Performance Settings:**
- `max_projectiles` (100) - Maximum active projectiles
- `max_effects` (50) - Maximum active visual effects
- `particle_quality` (1.0) - Particle quality multiplier

### Resource Instances

#### Default Config Files
**Location:** `/client/resources/configs/`

1. **battlefield_default.tres** - Default battlefield configuration
2. **game_balance_default.tres** - Default game balance configuration

These `.tres` files are Godot resource instances that can be edited in the Godot editor or text editor.

## Usage

### Loading Configs

#### In GameManager (Global Access)
```gdscript
# Configs are loaded automatically in GameManager._ready()
func _ready() -> void:
    _load_game_configs()
    # ...

# Access globally via GameManager
var battlefield_config = GameManager.get_battlefield_config()
var balance_config = GameManager.get_balance_config()
```

#### In Battlefield (Local Access)
```gdscript
# Configs loaded in _ready()
func _ready() -> void:
    _load_configs()
    # ...

func _load_configs() -> void:
    battlefield_config = load("res://resources/configs/battlefield_default.tres")
    balance_config = load("res://resources/configs/game_balance_default.tres")
```

### Accessing Config Values

#### Using Configs in Code
```gdscript
# Access battlefield settings
var tile_size = battlefield_config.tile_size
var grid_width = battlefield_config.grid_width

# Access balance settings
var elixir_rate = balance_config.elixir_generation_rate
var ai_reserve = balance_config.ai_elixir_reserve

# Use helper functions
var world_pos = battlefield_config.grid_to_world(Vector2i(5, 10))
var in_zone = battlefield_config.is_in_deployment_zone(mouse_pos, team)

# Get AI settings for difficulty
var ai_settings = balance_config.get_ai_settings_for_difficulty(GameManager.ai_difficulty)
print(ai_settings.elixir_reserve)  # 1.5 for medium
```

## Benefits

### 1. No Hardcoded Values
All magic numbers are eliminated and moved to data files, following the project's core principle.

### 2. Data-Driven Design
Gameplay values can be tuned without code changes:
- Edit `.tres` files in Godot editor
- Reload game to see changes
- No recompilation needed

### 3. Easy Balance Tuning
Game designers can adjust values without touching code:
- Elixir generation rates
- Unit limits
- AI difficulty parameters
- Visual settings

### 4. Flexibility
Multiple config files can be created:
- `battlefield_small.tres` - Smaller battlefield
- `balance_fast.tres` - Faster-paced gameplay
- `balance_easy.tres` - Easier difficulty preset

### 5. Maintainability
- Single source of truth for all values
- Clear organization of related settings
- Self-documenting through `@export` annotations
- Fallback values prevent crashes if configs fail to load

## Migration Strategy

### Before (Hardcoded)
```gdscript
const TILE_SIZE := 64
const GRID_WIDTH := 18
const MAX_UNITS_TOTAL := 50
var ai_elixir_reserve: float = 1.5

# Usage
var pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
if units.size() >= MAX_UNITS_TOTAL:
    return
```

### After (Config-Based)
```gdscript
var battlefield_config: BattlefieldConfig
var balance_config: GameBalanceConfig

# Computed properties with fallbacks
var TILE_SIZE: int:
    get: return battlefield_config.tile_size if battlefield_config else 64

# Usage (unchanged in calling code)
var pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
if units.size() >= MAX_UNITS_TOTAL:
    return
```

## Extending the System

### Adding New Config Values

1. **Add to Resource Class:**
```gdscript
# In battlefield_config.gd or game_balance_config.gd
@export var new_setting: float = 100.0
```

2. **Update .tres File:**
```
# In battlefield_default.tres or game_balance_default.tres
new_setting = 100.0
```

3. **Use in Code:**
```gdscript
var value = balance_config.new_setting
```

### Creating Custom Configs

1. **Duplicate .tres file:**
   - Copy `battlefield_default.tres` to `battlefield_custom.tres`

2. **Edit values:**
   - Open in Godot editor or text editor
   - Modify exported properties

3. **Load custom config:**
```gdscript
battlefield_config = load("res://resources/configs/battlefield_custom.tres")
```

## Testing

### Verifying Config Loading
Check console output when game starts:
```
GameManager: Loading game configurations...
  ✓ Battlefield config loaded
  ✓ Game balance config loaded
GameManager: Configurations loaded successfully

Configs loaded successfully
  - Battlefield: 18x28 tiles @ 64px
  - Unit limits: 50 total, 30 per team
  - AI elixir reserve: 1.5
```

### Testing Different Configs
1. Create test config files
2. Modify load path in code
3. Run game and verify behavior changes
4. Restore default configs

## Files Modified

### Created Files
- `/client/scripts/resources/battlefield_config.gd`
- `/client/scripts/resources/game_balance_config.gd`
- `/client/resources/configs/battlefield_default.tres`
- `/client/resources/configs/game_balance_default.tres`

### Modified Files
- `/client/scripts/battle/battlefield.gd` - Uses configs instead of constants
- `/client/scripts/core/game_manager.gd` - Loads and exposes configs globally

## Best Practices

1. **Always provide fallback values** - Config properties should have sensible defaults
2. **Use computed properties** - Make configs feel like constants in calling code
3. **Load early** - Load configs in `_ready()` before other initialization
4. **Check for null** - Always verify config loaded before accessing
5. **Document exports** - Use comments to explain what each value does
6. **Group related settings** - Use `@export_group()` and `@export_subgroup()`
7. **Provide helper methods** - Add utility functions to config classes

## Future Enhancements

- **Config profiles** - Switch between config sets at runtime
- **Hot reloading** - Reload configs without restarting game
- **Config validation** - Verify values are in valid ranges
- **Config editor UI** - In-game settings editor for designers
- **Config versioning** - Handle config format changes gracefully
- **Config inheritance** - Base configs with overrides for variants

## Troubleshooting

### Config Not Loading
```gdscript
# Check file path
print(load("res://resources/configs/battlefield_default.tres"))
# Should not print null

# Verify class name
print(battlefield_config is BattlefieldConfig)  # Should print true
```

### Values Not Updating
1. Verify `.tres` file was saved
2. Check config is loaded before use
3. Ensure using config value, not hardcoded fallback
4. Restart game to reload configs

### Missing Config Properties
1. Add to resource class first
2. Update `.tres` file
3. If using existing `.tres`, add property manually or recreate file

## Summary

The configuration system successfully eliminates hardcoded values from the Battle Castles codebase by:

1. Creating resource classes for battlefield and balance settings
2. Providing default `.tres` resource instances
3. Loading configs in GameManager for global access
4. Updating battlefield.gd to use config values
5. Maintaining backward compatibility with fallback values

All hardcoded values are now data-driven, making the game easier to tune, maintain, and extend.
