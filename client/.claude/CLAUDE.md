# Battle Castles Client - AI Assistant Context

This file contains context specific to the Godot 4 game client.

**For full project context, see**: `/../.claude/CLAUDE.md` (project root)

## Client Directory Structure

```
client/                          ← YOU ARE HERE
├── .claude/                     ← This file
├── addons/                      ← Godot plugins
├── assets/                      ← Game assets
│   ├── sprites/
│   │   ├── units/              ← Unit sprites (player/enemy versions)
│   │   └── icons/              ← Card icons
│   ├── audio/
│   └── fonts/
├── resources/                   ← Godot resources (.tres files)
│   └── cards/                  ← Card data resources
├── scenes/                      ← Godot scenes (.tscn files)
│   ├── battle/                 ← Battle scenes
│   │   └── battlefield.tscn
│   ├── ui/                     ← UI scenes
│   │   ├── settings_menu.tscn
│   │   ├── battle_ui.tscn
│   │   └── main_menu.tscn
│   └── main_menu.tscn
├── scripts/                     ← GDScript code
│   ├── ai/                     ← AI system
│   │   └── ai_difficulty.gd
│   ├── battle/                 ← Battle logic
│   │   ├── battlefield.gd      ← Main battle controller + AI
│   │   ├── simple_unit.gd      ← Unit behavior
│   │   ├── tower.gd            ← Tower behavior
│   │   └── castle.gd           ← Castle (extends Tower)
│   ├── cards/                  ← Card system
│   ├── core/                   ← Core systems (autoloads)
│   │   ├── game_manager.gd     ← Global game state
│   │   ├── scene_manager.gd    ← Scene transitions
│   │   └── audio_manager.gd
│   ├── network/                ← Networking
│   ├── progression/            ← Player progression
│   ├── resources/              ← Resource scripts
│   │   └── card_data.gd        ← Card data class
│   ├── ui/                     ← UI controllers
│   │   ├── battle_ui.gd        ← Battle HUD
│   │   ├── settings_menu_ui.gd ← Settings controller
│   │   └── main_menu_ui.gd
│   └── vfx/                    ← Visual effects
├── tests/                       ← Unit tests
└── project.godot               ← Godot project file
```

## Critical Client Information

### Documentation Location
**Client code lives here**, but **documentation lives in `../docs/`** at project root!

When creating docs:
```bash
cd ..
# Create/edit files in docs/
cd client
```

### Branching
See `../docs/BRANCHING.md` for full workflow.

Current branch: `feature/settings-page-fixes`

Never commit directly to `main` or `develop`!

## Godot-Specific Conventions

### File Organization
- **Scripts** go in `scripts/` organized by system (ai/, battle/, ui/, etc.)
- **Scenes** go in `scenes/` organized by purpose
- **Resources** (.tres) go in `resources/` organized by type
- **Assets** go in `assets/` organized by type (sprites, audio, fonts)

### Script Structure
```gdscript
extends Node2D
class_name MyClass  # Optional, for global access

# Constants (SCREAMING_SNAKE_CASE)
const MAX_VALUE := 100

# Exports (configurable in editor)
@export var speed: float = 100.0

# Onready variables (node references)
@onready var sprite: Sprite2D = $Sprite2D

# Private variables
var _internal_value: int = 0

# Public variables
var public_value: int = 0

func _ready() -> void:
    # Initialization

func _process(delta: float) -> void:
    # Per-frame updates

# Public functions
func public_function() -> void:
    pass

# Private functions
func _private_function() -> void:
    pass
```

### Naming Conventions
- **Files**: `snake_case.gd`, `snake_case.tscn`
- **Classes**: `PascalCase`
- **Variables**: `snake_case`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Private**: `_leading_underscore`
- **Signals**: `signal_name` (past tense: `signal player_died`)

### Node Paths
Use `@onready` for node references:
```gdscript
@onready var button: Button = $Panel/Container/Button
```

Not:
```gdscript
var button = get_node("Panel/Container/Button")  # ❌
```

## Key Systems

### Settings System (CURRENT TASK)
- **Script**: `scripts/ui/settings_menu_ui.gd`
- **Scene**: `scenes/ui/settings_menu.tscn`
- **Storage**: `user://settings.cfg` (Godot user data)
- **Controls**: Audio, Graphics, Gameplay (AI Difficulty)

### Battle System
- **Main Controller**: `scripts/battle/battlefield.gd`
  - Handles grid, deployment, towers, units
  - Contains AI system (spawn logic, difficulty)
- **Units**: `scripts/battle/simple_unit.gd`
- **Towers**: `scripts/battle/tower.gd`
- **Castle**: `scripts/battle/castle.gd` (extends Tower)

### AI System
- **Difficulty Config**: `scripts/ai/ai_difficulty.gd` (detailed configs)
- **AI Logic**: `scripts/battle/battlefield.gd` (lines 565+)
- **Current Implementation**: Phase 1 - Basic strategic decisions
  - Threat analysis
  - Defensive vs offensive choices
  - Elixir management

### Card System
- **Card Data**: `scripts/resources/card_data.gd` (class definition)
- **Card Resources**: `resources/cards/*.tres` (individual cards)
- **Properties**: elixir_cost, damage, attack_range, etc.

### Autoloads (Global Singletons)
Access via their names in any script:
- `GameManager` - Global game state, entity management
- `SceneManager` - Scene transitions with loading screens
- `AudioManager` - Sound and music management

## Common Tasks

### Adding a New Setting
1. Edit `scripts/ui/settings_menu_ui.gd`:
   - Add @onready var for UI element
   - Add to settings dictionary
   - Add setup in _setup_ui()
   - Add signal handler
   - Add to save/load functions
2. Edit `scenes/ui/settings_menu.tscn`:
   - Add UI element to scene
3. Apply setting in relevant system (e.g., GameManager)

### Creating a New Unit
1. Create card resource: `resources/cards/unit_name.tres`
2. Set properties (stats, attack_range, movement_speed)
3. Add sprites: `assets/sprites/units/unit_name_player.png` and `_enemy.png`
4. Load card in battlefield AI deck

### Adjusting Balance
- **Unit Stats**: Edit `resources/cards/*.tres` files
- **Tower Stats**: Edit `scripts/battle/tower.gd` or `castle.gd`
- **AI Behavior**: Edit `scripts/battle/battlefield.gd` AI functions
- **Timings**: Edit battle constants (BATTLE_DURATION, etc.)

## Testing Checklist

Before committing, test:
- [ ] Game starts without errors
- [ ] Changes work as expected
- [ ] No console errors/warnings
- [ ] Settings persist across restarts (if settings change)
- [ ] AI behaves correctly (if AI change)
- [ ] Battle timer works (if timer change)
- [ ] All attack ranges feel right (if balance change)

## Common Mistakes

### ❌ Wrong Documentation Location
```bash
# DON'T DO THIS:
echo "docs" > client/BRANCHING.md  # ❌

# DO THIS:
cd .. && echo "docs" > docs/BRANCHING.md  # ✅
cd client
```

### ❌ Hardcoding Values
```gdscript
# DON'T:
var speed = 100  # ❌ Magic number

# DO:
const DEFAULT_SPEED := 100  # ✅ Named constant
@export var speed: float = DEFAULT_SPEED
```

### ❌ Not Using @onready
```gdscript
# DON'T:
func _ready():
    var button = get_node("Button")  # ❌

# DO:
@onready var button: Button = $Button  # ✅
```

### ❌ Breaking Signals
```gdscript
# DON'T:
button_pressed.emit()  # ❌ Signal doesn't exist

# DO:
# Define signal first
signal button_pressed
# Then emit
button_pressed.emit()  # ✅
```

## Current Work

**Branch**: `feature/settings-page-fixes`
**Task**: Fix and improve settings menu
**Recent Changes**:
- Added AI difficulty selector
- Fixed AI spawning variety
- Fixed battle timer
- Reduced attack ranges

**Known Issues**:
- Settings page needs improvements (current focus)

## Quick Reference

| Task | File(s) to Edit |
|------|----------------|
| Add setting | `scripts/ui/settings_menu_ui.gd`, `scenes/ui/settings_menu.tscn` |
| Balance unit | `resources/cards/unit_name.tres` |
| AI behavior | `scripts/battle/battlefield.gd` (AI section) |
| Battle timer | `scripts/battle/battle_manager.gd` |
| Unit behavior | `scripts/battle/simple_unit.gd` |
| Tower stats | `scripts/battle/tower.gd` or `castle.gd` |
| UI scene | `scenes/ui/scene_name.tscn` |
| Main menu | `scripts/ui/main_menu_ui.gd` |

## Resources

- **Project Docs**: `../docs/` (one level up)
- **Branching**: `../docs/BRANCHING.md`
- **Project Structure**: `../docs/PROJECT_STRUCTURE.md`
- **Godot Docs**: https://docs.godotengine.org/en/stable/

---

**Last Updated**: November 3, 2025
**Working Directory**: `/client/`
