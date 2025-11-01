# Battle Castles - Developer Guide

Version 0.1.0 | For Developers & Contributors

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Technology Stack](#technology-stack)
4. [Core Systems](#core-systems)
5. [Adding New Units](#adding-new-units)
6. [Adding New Arenas](#adding-new-arenas)
7. [Extending the AI System](#extending-the-ai-system)
8. [Network Protocol](#network-protocol)
9. [Testing & Debugging](#testing--debugging)
10. [Performance Optimization](#performance-optimization)

---

## Architecture Overview

### Design Philosophy

Battle Castles follows these core architectural principles:

- **SOLID Principles** - Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **DRY** (Don't Repeat Yourself) - Code reusability and abstraction
- **KISS** (Keep It Simple, Stupid) - Simplicity over complexity
- **YAGNI** (You Aren't Gonna Need It) - Build what's needed now
- **Clean Code** - Readable, maintainable, testable

### High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                  GODOT CLIENT                       │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │  Game Logic  │  │     UI       │  │  Network  │ │
│  │  (GDScript)  │  │  (Scenes)    │  │  (WebRTC) │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
└─────────────────────────────────────────────────────┘
                       ↕ WebSocket
┌─────────────────────────────────────────────────────┐
│              GAME SERVER (Node.js)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │Battle Logic  │  │ Matchmaking  │  │   State   │ │
│  │(TypeScript)  │  │    Queue     │  │  Manager  │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
└─────────────────────────────────────────────────────┘
```

### Architecture Patterns

#### 1. Entity-Component-System (ECS)

All game entities (units, towers, projectiles) use an ECS architecture:

```gdscript
# Base Entity class
class_name Entity
extends Node2D

var components: Dictionary = {}

func add_component(component: Component) -> void:
    components[component.get_class()] = component
    add_child(component)

func get_component(component_class: String) -> Component:
    return components.get(component_class)

func has_component(component_class: String) -> bool:
    return components.has(component_class)
```

**Benefits:**
- Composition over inheritance
- Modular, reusable components
- Easy to extend and modify
- Better performance (cache-friendly)

#### 2. Command Pattern

All player actions are encapsulated as commands for networking and replay support:

```gdscript
class_name Command
extends RefCounted

var timestamp: float
var player_id: int

func execute(game_state: GameState) -> void:
    pass  # Override in subclasses

func validate(game_state: GameState) -> bool:
    pass  # Server-side validation
```

#### 3. State Machine

Units and game flow use finite state machines:

```gdscript
enum UnitState {
    IDLE,
    MOVING,
    ATTACKING,
    DYING,
    DEAD
}

var current_state: UnitState = UnitState.IDLE

func change_state(new_state: UnitState) -> void:
    _exit_state(current_state)
    current_state = new_state
    _enter_state(new_state)
```

---

## Project Structure

### Repository Layout

```
battle-castles/
├── client/                  # Godot game client
│   ├── assets/             # Art, audio, fonts
│   │   ├── sprites/        # Unit and building sprites
│   │   ├── audio/          # Music and sound effects
│   │   └── fonts/          # UI fonts
│   ├── scenes/             # Godot scene files (.tscn)
│   │   ├── battle/         # Battle arena scenes
│   │   ├── ui/             # Menu and HUD scenes
│   │   ├── units/          # Unit prefabs
│   │   └── vfx/            # Visual effects
│   ├── scripts/            # GDScript source code
│   │   ├── core/           # Core systems (ECS, managers)
│   │   ├── battle/         # Battle logic
│   │   ├── ui/             # UI controllers
│   │   ├── units/          # Unit behaviors
│   │   ├── ai/             # AI opponent logic
│   │   └── network/        # Multiplayer networking
│   ├── autoload/           # Singleton scripts
│   └── project.godot       # Godot project file
│
├── server/                  # Backend services
│   ├── game-server/        # Node.js + TypeScript
│   │   ├── src/
│   │   │   ├── index.ts            # Entry point
│   │   │   ├── types.ts            # Type definitions
│   │   │   ├── config.ts           # Configuration
│   │   │   ├── BattleState.ts      # Game state manager
│   │   │   ├── GameRoom.ts         # Match room handler
│   │   │   ├── MatchmakingQueue.ts # Matchmaking logic
│   │   │   └── CommandValidator.ts # Input validation
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── README.md
│
├── shared/                  # Shared code/protocols
│   └── protocol/           # Network message definitions
│
├── docs/                    # Documentation
│   ├── USER_MANUAL.md
│   ├── DEVELOPER_GUIDE.md  # This file
│   ├── API_DOCUMENTATION.md
│   ├── DEPLOYMENT.md
│   ├── BUILD_PLAN.md
│   └── architecture/
│
├── tests/                   # Test suites
│   ├── unit/               # Unit tests
│   ├── integration/        # Integration tests
│   └── e2e/                # End-to-end tests
│
├── deployment/              # Deployment configs
│   ├── docker/             # Docker files
│   ├── kubernetes/         # K8s manifests
│   └── scripts/            # Build/deploy scripts
│
├── game-design/             # Design documents
│   ├── battle_game_gdd.md
│   ├── unit_specifications.md
│   └── ...
│
├── .github/                 # GitHub configs
│   └── workflows/          # CI/CD pipelines
│
├── README.md
└── package.json
```

### Key Directories Explained

**client/scripts/core/**
- `entity.gd` - Base entity class
- `component.gd` - Base component class
- `game_manager.gd` - Global game state
- Components in `core/components/`:
  - `health_component.gd`
  - `attack_component.gd`
  - `movement_component.gd`
  - `stats_component.gd`
  - `team_component.gd`

**client/scripts/battle/**
- `battle_manager.gd` - Battle flow controller
- `battlefield.gd` - Arena manager
- `elixir_manager.gd` - Elixir regeneration system
- `tower.gd` - Tower behavior
- `castle.gd` - Castle (King's Tower) behavior

**client/scripts/units/**
- `base_unit.gd` - Base class for all units
- `knight.gd` - Knight unit implementation
- `goblin.gd` - Individual goblin
- `goblin_squad.gd` - Squad spawner
- `archer.gd` - Archer unit
- `giant.gd` - Giant unit

**server/game-server/src/**
- `index.ts` - Express + Socket.IO server setup
- `types.ts` - TypeScript interfaces and enums
- `BattleState.ts` - Authoritative game state
- `GameRoom.ts` - Match room management
- `MatchmakingQueue.ts` - Player queue handling

---

## Technology Stack

### Client Technologies

| Technology | Purpose | Version |
|------------|---------|---------|
| **Godot Engine** | Game engine | 4.3+ |
| **GDScript** | Primary scripting language | 2.0 |
| **C++ (GDExtension)** | Performance-critical code | 17+ |

**Why Godot?**
- Open source, no licensing fees
- Native ARM64 support (Raspberry Pi 5)
- Lightweight (~50MB runtime)
- Excellent 2D performance
- Built-in networking (ENet)
- Deterministic physics for replays

### Server Technologies

| Technology | Purpose | Version |
|------------|---------|---------|
| **Node.js** | Game server runtime | 18 LTS+ |
| **TypeScript** | Type-safe JavaScript | 5.0+ |
| **Express** | HTTP server | 4.18+ |
| **Socket.IO** | WebSocket communication | 4.6+ |
| **Winston** | Logging | 3.11+ |
| **Jest** | Testing framework | 29+ |

**Why Node.js?**
- Event-driven, perfect for real-time games
- Large ecosystem (npm)
- Same language as client (JavaScript/GDScript similarity)
- Good performance for I/O-bound operations

### Development Tools

- **Git** - Version control
- **Docker** - Containerization
- **Docker Compose** - Local development
- **GitHub Actions** - CI/CD
- **ESLint** - Code linting (TypeScript)
- **Prettier** - Code formatting

---

## Core Systems

### 1. Entity-Component-System (ECS)

#### Component Base Class

```gdscript
# client/scripts/core/component.gd
class_name Component
extends Node

## The entity this component belongs to
var entity: Entity

func _ready() -> void:
    entity = get_parent() as Entity
    if not entity:
        push_error("Component must be child of Entity")

## Called when component is added to entity
func on_added() -> void:
    pass

## Called when component is removed from entity
func on_removed() -> void:
    pass

## Update component (called by entity)
func update(delta: float) -> void:
    pass
```

#### Example: Health Component

```gdscript
# client/scripts/core/components/health_component.gd
class_name HealthComponent
extends Component

signal health_changed(new_health: int, max_health: int)
signal damage_taken(amount: int, source: Entity)
signal death()

@export var max_health: int = 100
@export var current_health: int = 100
@export var is_invulnerable: bool = false

func take_damage(amount: int, source: Entity = null) -> void:
    if is_invulnerable or current_health <= 0:
        return

    var old_health = current_health
    current_health = max(0, current_health - amount)

    damage_taken.emit(amount, source)
    health_changed.emit(current_health, max_health)

    if current_health <= 0 and old_health > 0:
        death.emit()

func heal(amount: int) -> void:
    var old_health = current_health
    current_health = min(max_health, current_health + amount)

    if current_health != old_health:
        health_changed.emit(current_health, max_health)

func get_health_percent() -> float:
    return float(current_health) / float(max_health) if max_health > 0 else 0.0

func is_alive() -> bool:
    return current_health > 0
```

### 2. Command Pattern for Networking

#### Command Structure

```typescript
// server/game-server/src/types.ts
export enum CommandType {
  DEPLOY_UNIT = 'deploy_unit',
  CAST_SPELL = 'cast_spell',
  SURRENDER = 'surrender'
}

export interface DeployUnitCommand {
  type: CommandType.DEPLOY_UNIT;
  unitType: UnitType;
  position: Vector2;
  timestamp: number;
}

export type GameCommand =
  | DeployUnitCommand
  | CastSpellCommand
  | SurrenderCommand;
```

#### Server-Side Validation

```typescript
// server/game-server/src/CommandValidator.ts
export class CommandValidator {
  static validateDeployUnit(
    command: DeployUnitCommand,
    player: Player,
    gameState: GameState
  ): ValidationResult {
    // Check elixir cost
    const unitCost = UNIT_COSTS[command.unitType];
    if (player.elixir < unitCost) {
      return { valid: false, error: 'Insufficient elixir' };
    }

    // Check deployment zone
    const isInZone = this.isInDeploymentZone(
      command.position,
      player.team,
      gameState
    );
    if (!isInZone) {
      return { valid: false, error: 'Invalid deployment position' };
    }

    // Check unit count limit
    const playerUnits = Array.from(gameState.units.values())
      .filter(u => u.team === player.team);
    if (playerUnits.length >= 8) {
      return { valid: false, error: 'Maximum units deployed' };
    }

    return { valid: true };
  }
}
```

### 3. Battle Manager

The Battle Manager orchestrates the entire battle flow:

```gdscript
# client/scripts/battle/battle_manager.gd
class_name BattleManager
extends Node

signal battle_started()
signal battle_ended(winner: int)
signal elixir_changed(player_id: int, amount: float)
signal tower_destroyed(tower: Tower)

@export var battle_duration: float = 180.0  # 3 minutes
@export var double_elixir_time: float = 60.0  # Last 60 seconds

var battlefield: Battlefield
var elixir_manager: ElixirManager
var battle_time: float = 0.0
var is_active: bool = false
var winner: int = -1  # -1 = none, 0 = player, 1 = opponent

func _ready() -> void:
    battlefield = $Battlefield
    elixir_manager = $ElixirManager
    _connect_signals()

func start_battle() -> void:
    is_active = true
    battle_time = 0.0
    winner = -1

    # Initialize elixir
    elixir_manager.start_regeneration()

    # Spawn towers
    battlefield.spawn_towers()

    battle_started.emit()

func _process(delta: float) -> void:
    if not is_active:
        return

    battle_time += delta

    # Check for double elixir mode
    if battle_time >= battle_duration - double_elixir_time:
        elixir_manager.set_double_elixir_mode(true)

    # Check for time limit
    if battle_time >= battle_duration:
        end_battle_by_time()

func deploy_unit(
    unit_type: String,
    position: Vector2,
    team: int
) -> void:
    var cost = _get_unit_cost(unit_type)

    if not elixir_manager.try_spend_elixir(team, cost):
        push_warning("Not enough elixir to deploy unit")
        return

    battlefield.spawn_unit(unit_type, position, team)

func end_battle_by_time() -> void:
    is_active = false
    winner = _determine_winner_by_damage()
    battle_ended.emit(winner)

func end_battle_by_castle_destruction(team: int) -> void:
    is_active = false
    winner = 1 - team  # Opposite team wins
    battle_ended.emit(winner)

func _determine_winner_by_damage() -> int:
    var player_towers = battlefield.count_destroyed_towers(1)
    var opponent_towers = battlefield.count_destroyed_towers(0)

    if player_towers > opponent_towers:
        return 0  # Player wins
    elif opponent_towers > player_towers:
        return 1  # Opponent wins
    else:
        # Compare total damage dealt
        var player_damage = battlefield.get_total_damage_dealt(0)
        var opponent_damage = battlefield.get_total_damage_dealt(1)

        if player_damage > opponent_damage:
            return 0
        elif opponent_damage > player_damage:
            return 1
        else:
            return -1  # Draw
```

### 4. Elixir System

```gdscript
# client/scripts/battle/elixir_manager.gd
class_name ElixirManager
extends Node

signal elixir_changed(player_id: int, amount: float)

const MAX_ELIXIR: float = 10.0
const STARTING_ELIXIR: float = 5.0
const BASE_REGEN_RATE: float = 1.0 / 2.8  # 1 per 2.8 seconds

var player_elixir: float = STARTING_ELIXIR
var opponent_elixir: float = STARTING_ELIXIR
var is_double_elixir: bool = false
var is_active: bool = false

func _process(delta: float) -> void:
    if not is_active:
        return

    var regen_rate = BASE_REGEN_RATE * (2.0 if is_double_elixir else 1.0)

    # Regenerate player elixir
    if player_elixir < MAX_ELIXIR:
        player_elixir = min(MAX_ELIXIR, player_elixir + regen_rate * delta)
        elixir_changed.emit(0, player_elixir)

    # Regenerate opponent elixir
    if opponent_elixir < MAX_ELIXIR:
        opponent_elixir = min(MAX_ELIXIR, opponent_elixir + regen_rate * delta)
        elixir_changed.emit(1, opponent_elixir)

func try_spend_elixir(player_id: int, amount: float) -> bool:
    var current = get_elixir(player_id)

    if current >= amount:
        set_elixir(player_id, current - amount)
        return true

    return false

func get_elixir(player_id: int) -> float:
    return player_elixir if player_id == 0 else opponent_elixir

func set_elixir(player_id: int, amount: float) -> void:
    amount = clamp(amount, 0.0, MAX_ELIXIR)

    if player_id == 0:
        player_elixir = amount
    else:
        opponent_elixir = amount

    elixir_changed.emit(player_id, amount)

func start_regeneration() -> void:
    is_active = true
    player_elixir = STARTING_ELIXIR
    opponent_elixir = STARTING_ELIXIR

func set_double_elixir_mode(enabled: bool) -> void:
    is_double_elixir = enabled
```

---

## Adding New Units

### Step-by-Step Guide

#### 1. Create Unit Specification

First, define the unit's stats in the game design docs:

```yaml
# game-design/unit_specifications.md
## WIZARD (Rare)

### Base Stats (Level 1)
- Hitpoints: 340 HP
- Damage: 130 per hit
- Attack Speed: 1.4 seconds
- Movement Speed: Medium (55 units/sec)
- Range: Long (5 tiles)
- Elixir Cost: 4
- Deploy Time: 1 second
- Target Type: Ground only
- Special: Splash damage (1.5 tile radius)
```

#### 2. Create GDScript Unit Class

```gdscript
# client/scripts/units/wizard.gd
class_name Wizard
extends BaseUnit

const SPLASH_RADIUS: float = 1.5

@export var projectile_scene: PackedScene

func _ready() -> void:
    super._ready()

    # Initialize with Wizard stats (Level 1)
    initialize(
        340,    # HP
        130,    # Damage
        1.4,    # Attack speed
        55,     # Move speed
        5.0,    # Attack range
        4,      # Elixir cost
        "Wizard"
    )

## Override attack behavior for splash damage
func _perform_attack() -> void:
    if not current_target or not is_instance_valid(current_target):
        return

    # Launch projectile instead of instant damage
    _launch_projectile(current_target.global_position)
    attack_component.last_attack_time = Time.get_ticks_msec() / 1000.0

func _launch_projectile(target_pos: Vector2) -> void:
    if not projectile_scene:
        return

    var projectile = projectile_scene.instantiate()
    get_parent().add_child(projectile)

    projectile.global_position = global_position
    projectile.initialize(
        target_pos,
        attack_component.damage,
        SPLASH_RADIUS,
        team_component.team_id
    )

## Custom animation handling
func _update_animation() -> void:
    match current_state:
        State.ATTACKING:
            sprite.play("cast")
        State.MOVING:
            sprite.play("walk")
        State.IDLE:
            sprite.play("idle")
        State.DYING:
            sprite.play("death")
```

#### 3. Create Wizard Projectile

```gdscript
# client/scripts/units/wizard_projectile.gd
class_name WizardProjectile
extends Node2D

@export var speed: float = 200.0
@export var arc_height: float = 50.0

var target_position: Vector2
var damage: int
var splash_radius: float
var team_id: int
var start_position: Vector2
var travel_time: float = 0.0
var duration: float = 1.0

func initialize(
    target: Vector2,
    dmg: int,
    radius: float,
    team: int
) -> void:
    target_position = target
    damage = dmg
    splash_radius = radius
    team_id = team
    start_position = global_position

    var distance = global_position.distance_to(target)
    duration = distance / speed

func _process(delta: float) -> void:
    travel_time += delta
    var progress = travel_time / duration

    if progress >= 1.0:
        _explode()
        return

    # Parabolic arc movement
    var linear_pos = start_position.lerp(target_position, progress)
    var arc_offset = sin(progress * PI) * arc_height
    global_position = linear_pos + Vector2(0, -arc_offset)

func _explode() -> void:
    # Find all units in splash radius
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsShapeQueryParameters2D.new()
    var circle = CircleShape2D.new()
    circle.radius = splash_radius * 64  # Convert to pixels

    query.shape = circle
    query.transform = Transform2D(0, global_position)
    query.collision_mask = 2  # Units layer

    var hits = space_state.intersect_shape(query)

    for hit in hits:
        var unit = hit.collider as BaseUnit
        if unit and unit.team_component.team_id != team_id:
            var health = unit.get_component("HealthComponent")
            if health:
                health.take_damage(damage, self)

    # Spawn explosion VFX
    var explosion = preload("res://scenes/vfx/explosion_effect.tscn").instantiate()
    get_parent().add_child(explosion)
    explosion.global_position = global_position

    queue_free()
```

#### 4. Create Godot Scene

Create `client/scenes/units/wizard.tscn`:

```
Wizard (Node2D)
├── AnimatedSprite2D
│   └── SpriteFrames (idle, walk, cast, death)
├── CollisionShape2D (for area detection)
├── AttackArea (Area2D)
│   └── CollisionShape2D (attack range circle)
└── HealthBar (ProgressBar)
```

#### 5. Add to Unit Registry

```gdscript
# client/scripts/core/unit_registry.gd
extends Node

const UNITS = {
    "knight": preload("res://scenes/units/knight.tscn"),
    "goblin_squad": preload("res://scenes/units/goblin_squad.tscn"),
    "archer": preload("res://scenes/units/archer.tscn"),
    "giant": preload("res://scenes/units/giant.tscn"),
    "wizard": preload("res://scenes/units/wizard.tscn"),  # NEW
}

const UNIT_COSTS = {
    "knight": 3,
    "goblin_squad": 2,
    "archer": 3,
    "giant": 5,
    "wizard": 4,  # NEW
}

func spawn_unit(unit_type: String, position: Vector2, team: int) -> BaseUnit:
    if not UNITS.has(unit_type):
        push_error("Unknown unit type: " + unit_type)
        return null

    var unit_scene = UNITS[unit_type]
    var unit = unit_scene.instantiate()
    unit.global_position = position
    unit.team_component.team_id = team

    return unit
```

#### 6. Update Server Types

```typescript
// server/game-server/src/types.ts
export enum UnitType {
  KNIGHT = 'knight',
  ARCHER = 'archer',
  WIZARD = 'wizard',  // NEW
  GIANT = 'giant',
  GOBLIN = 'goblin',
  DRAGON = 'dragon'
}

export const UNIT_COSTS: Record<UnitType, number> = {
  [UnitType.KNIGHT]: 3,
  [UnitType.ARCHER]: 3,
  [UnitType.WIZARD]: 4,  // NEW
  [UnitType.GIANT]: 5,
  [UnitType.GOBLIN]: 2,
  [UnitType.DRAGON]: 6,
};
```

#### 7. Add Art Assets

Place sprite sheets in:
- `client/assets/sprites/units/wizard_idle.png`
- `client/assets/sprites/units/wizard_walk.png`
- `client/assets/sprites/units/wizard_cast.png`
- `client/assets/sprites/units/wizard_death.png`

Configure in AnimatedSprite2D's SpriteFrames resource.

#### 8. Test the Unit

Create a test scene:

```gdscript
# tests/unit/test_wizard.gd
extends GutTest

func test_wizard_splash_damage():
    var wizard = preload("res://scenes/units/wizard.tscn").instantiate()
    add_child_autofree(wizard)

    wizard.global_position = Vector2(100, 100)
    wizard.team_component.team_id = 0

    # Spawn enemy units in splash radius
    var enemy1 = preload("res://scenes/units/knight.tscn").instantiate()
    var enemy2 = preload("res://scenes/units/knight.tscn").instantiate()

    add_child_autofree(enemy1)
    add_child_autofree(enemy2)

    enemy1.global_position = Vector2(200, 100)
    enemy2.global_position = Vector2(220, 120)
    enemy1.team_component.team_id = 1
    enemy2.team_component.team_id = 1

    wizard.current_target = enemy1
    wizard._perform_attack()

    await wait_seconds(1.5)

    # Both enemies should take damage
    assert_lt(enemy1.health_component.current_health, 1400)
    assert_lt(enemy2.health_component.current_health, 1400)
```

---

## Adding New Arenas

### Arena Structure

Arenas are visual themes applied to the same gameplay space. They don't change mechanics, only aesthetics.

#### 1. Create Arena Scene

```
Forest Arena (Node2D)
├── Background (Sprite2D)
│   └── Texture: forest_background.png
├── GroundTiles (TileMap)
│   └── Tileset: forest_tileset.tres
├── River (AnimatedSprite2D)
│   └── Animation: water_flow
├── Decorations (Node2D)
│   ├── Tree1 (Sprite2D)
│   ├── Tree2 (Sprite2D)
│   ├── Rocks (Sprite2D)
│   └── Bushes (Sprite2D)
├── TowerPositions (Node2D)
│   ├── PlayerLeft (Marker2D)
│   ├── PlayerCastle (Marker2D)
│   ├── PlayerRight (Marker2D)
│   ├── OpponentLeft (Marker2D)
│   ├── OpponentCastle (Marker2D)
│   └── OpponentRight (Marker2D)
└── SpawnZones (Node2D)
    ├── PlayerZone (Area2D)
    └── OpponentZone (Area2D)
```

#### 2. Standardized Tower Positions

**CRITICAL:** All arenas must use the exact same tower positions:

```gdscript
# Standardized positions (in pixels at 1920x1080)
const PLAYER_LEFT_TOWER = Vector2(400, 800)
const PLAYER_CASTLE = Vector2(960, 980)
const PLAYER_RIGHT_TOWER = Vector2(1520, 800)

const OPPONENT_LEFT_TOWER = Vector2(400, 280)
const OPPONENT_CASTLE = Vector2(960, 100)
const OPPONENT_RIGHT_TOWER = Vector2(1520, 280)
```

#### 3. Create Arena Script

```gdscript
# client/scripts/battle/arenas/forest_arena.gd
class_name ForestArena
extends Battlefield

@export var ambient_sound: AudioStream
@export var wind_particles: GPUParticles2D

func _ready() -> void:
    super._ready()
    _setup_ambient_effects()

func _setup_ambient_effects() -> void:
    # Play forest ambience
    if ambient_sound:
        var player = AudioStreamPlayer.new()
        player.stream = ambient_sound
        player.autoplay = true
        player.volume_db = -10
        add_child(player)

    # Spawn falling leaves
    if wind_particles:
        wind_particles.emitting = true

## Override tower spawn to use forest-themed towers
func spawn_towers() -> void:
    super.spawn_towers()

    # Apply forest skin to towers
    for tower in get_tree().get_nodes_in_group("towers"):
        _apply_forest_skin(tower)

func _apply_forest_skin(tower: Tower) -> void:
    # Change tower sprites to wood/nature theme
    var sprite = tower.get_node("Sprite2D")
    if sprite:
        sprite.texture = preload("res://assets/sprites/buildings/forest_tower.png")
```

#### 4. Register Arena

```gdscript
# client/scripts/core/arena_registry.gd
extends Node

const ARENAS = {
    "classic": preload("res://scenes/battle/arenas/classic_arena.tscn"),
    "forest": preload("res://scenes/battle/arenas/forest_arena.tscn"),
    "desert": preload("res://scenes/battle/arenas/desert_arena.tscn"),
    "ice": preload("res://scenes/battle/arenas/ice_arena.tscn"),
}

func get_random_arena() -> PackedScene:
    var keys = ARENAS.keys()
    return ARENAS[keys[randi() % keys.size()]]

func get_arena(arena_id: String) -> PackedScene:
    return ARENAS.get(arena_id, ARENAS["classic"])
```

---

## Extending the AI System

### AI Architecture

The AI opponent uses a behavior tree for decision-making:

```
AI Root
├── Selector (Pick first success)
│   ├── Sequence: Emergency Defense
│   │   ├── Condition: Tower under heavy attack
│   │   └── Action: Deploy counter unit
│   ├── Sequence: Exploit Opening
│   │   ├── Condition: Opponent low elixir
│   │   └── Action: Launch aggressive push
│   ├── Sequence: Build Push
│   │   ├── Condition: Have 7+ elixir
│   │   └── Action: Deploy tank + support
│   └── Action: Cycle cheap unit
```

### Creating Custom AI Behavior

#### 1. Define AI Difficulty Stats

```gdscript
# client/scripts/ai/ai_config.gd
extends Resource
class_name AIConfig

enum Difficulty {
    BEGINNER,
    INTERMEDIATE,
    EXPERT
}

@export var difficulty: Difficulty = Difficulty.BEGINNER
@export var reaction_delay: float = 1.0
@export var placement_accuracy: float = 0.7
@export var elixir_management_skill: float = 0.5
@export var target_priority_skill: float = 0.5

static func get_config(difficulty: Difficulty) -> AIConfig:
    var config = AIConfig.new()
    config.difficulty = difficulty

    match difficulty:
        Difficulty.BEGINNER:
            config.reaction_delay = 1.5
            config.placement_accuracy = 0.6
            config.elixir_management_skill = 0.4
            config.target_priority_skill = 0.5

        Difficulty.INTERMEDIATE:
            config.reaction_delay = 0.8
            config.placement_accuracy = 0.8
            config.elixir_management_skill = 0.7
            config.target_priority_skill = 0.75

        Difficulty.EXPERT:
            config.reaction_delay = 0.3
            config.placement_accuracy = 0.95
            config.elixir_management_skill = 0.9
            config.target_priority_skill = 0.9

    return config
```

#### 2. Implement AI Controller

```gdscript
# client/scripts/ai/ai_controller.gd
class_name AIController
extends Node

@export var config: AIConfig
@export var battle_manager: BattleManager

var elixir_manager: ElixirManager
var battlefield: Battlefield
var decision_timer: float = 0.0
var decision_interval: float = 0.5

func _ready() -> void:
    if not config:
        config = AIConfig.get_config(AIConfig.Difficulty.INTERMEDIATE)

    elixir_manager = battle_manager.elixir_manager
    battlefield = battle_manager.battlefield

func _process(delta: float) -> void:
    decision_timer += delta

    if decision_timer >= decision_interval:
        decision_timer = 0.0
        _make_decision()

func _make_decision() -> void:
    # Check for urgent threats
    if _should_defend_urgently():
        _execute_emergency_defense()
        return

    # Check for offensive opportunities
    if _should_attack():
        _execute_attack()
        return

    # Cycle cards or build elixir
    if _should_cycle():
        _execute_cycle()

func _should_defend_urgently() -> bool:
    # Check if any tower is under attack
    var player_towers = battlefield.get_player_towers(1)  # AI is player 1

    for tower in player_towers:
        var enemies_near = _get_enemies_near_position(
            tower.global_position,
            300  # pixels
        )

        if enemies_near.size() >= 2:
            return true

        # Check for high-value threats
        for enemy in enemies_near:
            if enemy is Giant:
                return true

    return false

func _execute_emergency_defense() -> void:
    var threat = _get_highest_threat()
    if not threat:
        return

    var counter_unit = _get_best_counter(threat)
    var placement = _calculate_defensive_placement(threat)

    # Add reaction delay based on difficulty
    await get_tree().create_timer(config.reaction_delay).timeout

    _deploy_unit(counter_unit, placement)

func _get_best_counter(enemy: BaseUnit) -> String:
    # Simple counter logic
    if enemy is Giant:
        return "goblin_squad"  # Swarm counters tank
    elif enemy is GoblinSquad:
        return "knight"  # Tank counters swarm
    elif enemy is Archer:
        return "knight"  # Melee counters ranged
    else:
        return "knight"  # Default

func _calculate_defensive_placement(threat: BaseUnit) -> Vector2:
    # Place unit between threat and nearest tower
    var nearest_tower = _get_nearest_friendly_tower(threat.global_position)

    var direction = (threat.global_position - nearest_tower.global_position).normalized()
    var placement = nearest_tower.global_position + direction * 100

    # Add randomness based on difficulty
    var accuracy = config.placement_accuracy
    var jitter = (1.0 - accuracy) * 100
    placement.x += randf_range(-jitter, jitter)
    placement.y += randf_range(-jitter, jitter)

    # Clamp to AI deployment zone
    placement = _clamp_to_deployment_zone(placement)

    return placement

func _should_attack() -> bool:
    var ai_elixir = elixir_manager.get_elixir(1)
    var skill = config.elixir_management_skill

    # More skilled AI attacks at optimal elixir levels
    var threshold = lerp(5.0, 7.0, skill)

    return ai_elixir >= threshold

func _execute_attack() -> void:
    # Choose attack strategy
    var strategy = _choose_attack_strategy()

    match strategy:
        "tank_push":
            _deploy_tank_push()
        "dual_lane":
            _deploy_dual_lane_attack()
        "rush":
            _deploy_rush()

func _deploy_tank_push() -> void:
    var ai_elixir = elixir_manager.get_elixir(1)

    if ai_elixir >= 5:
        # Deploy Giant
        var lane = _choose_attack_lane()
        var position = _get_lane_position(lane)
        _deploy_unit("giant", position)

        await get_tree().create_timer(2.0).timeout

        # Add support units
        if elixir_manager.get_elixir(1) >= 3:
            _deploy_unit("archer", position + Vector2(-50, 0))

func _choose_attack_lane() -> String:
    # Attack the lane with fewest defenses
    var left_threats = _count_enemies_in_lane("left")
    var right_threats = _count_enemies_in_lane("right")

    return "left" if left_threats < right_threats else "right"

func _deploy_unit(unit_type: String, position: Vector2) -> void:
    battle_manager.deploy_unit(unit_type, position, 1)  # Team 1 = AI
```

#### 3. Adding New AI Strategies

```gdscript
# Add to ai_controller.gd

func _deploy_bait_strategy() -> void:
    """
    Advanced strategy: Bait opponent's counter, then attack opposite lane
    """
    var bait_lane = "left"
    var real_lane = "right"

    # Deploy cheap unit as bait
    var bait_pos = _get_lane_position(bait_lane)
    _deploy_unit("goblin_squad", bait_pos)

    # Wait for opponent to react
    await get_tree().create_timer(2.0).timeout

    # Launch real push on opposite lane
    var attack_pos = _get_lane_position(real_lane)
    if elixir_manager.get_elixir(1) >= 8:
        _deploy_unit("giant", attack_pos)
        await get_tree().create_timer(1.0).timeout
        _deploy_unit("archer", attack_pos + Vector2(-50, 0))
```

---

## Network Protocol

### WebSocket Communication

Battle Castles uses WebSocket (Socket.IO) for real-time multiplayer.

#### Connection Flow

```
Client                          Server
  │                               │
  ├── WS Connect ─────────────────>│
  │<──── Connection Confirmed ─────┤
  │                               │
  ├── JOIN_QUEUE ─────────────────>│
  │    { playerName: "Alice" }    │
  │<──── QUEUE_JOINED ─────────────┤
  │                               │
  │      (Server matches players) │
  │                               │
  │<──── GAME_FOUND ───────────────┤
  │    { roomId, opponentName }   │
  │                               │
  ├── GAME_COMMAND ───────────────>│
  │    { type: "deploy_unit", ... }│
  │<──── GAME_STATE_UPDATE ────────┤
  │    { units, towers, time, ... }│
  │                               │
```

### Server Events

```typescript
// server/game-server/src/types.ts
export enum SocketEvent {
  // Client -> Server
  JOIN_QUEUE = 'join_queue',
  LEAVE_QUEUE = 'leave_queue',
  GAME_COMMAND = 'game_command',
  PING = 'ping',

  // Server -> Client
  QUEUE_JOINED = 'queue_joined',
  QUEUE_LEFT = 'queue_left',
  GAME_FOUND = 'game_found',
  GAME_STATE_UPDATE = 'game_state_update',
  GAME_ENDED = 'game_ended',
  ERROR = 'error',
  PONG = 'pong'
}
```

### Message Formats

#### Deploy Unit Command

```typescript
{
  type: "game_command",
  payload: {
    command: {
      type: "deploy_unit",
      unitType: "knight",
      position: { x: 500, y: 600 },
      timestamp: 1699999999999
    }
  }
}
```

#### Game State Update

```typescript
{
  type: "game_state_update",
  payload: {
    roomId: "abc123",
    gameTime: 45.2,
    units: [
      {
        id: "unit_1",
        type: "knight",
        team: "left",
        position: { x: 520, y: 650 },
        health: 1200,
        maxHealth: 1400
      }
    ],
    towers: [
      {
        id: "tower_left_player",
        type: "left",
        team: "left",
        health: 1400,
        isDestroyed: false
      }
    ],
    players: [
      {
        id: "player_1",
        name: "Alice",
        team: "left",
        elixir: 7.2,
        crowns: 0
      }
    ]
  }
}
```

### Client-Side Networking

```gdscript
# client/scripts/network/network_client.gd
extends Node

signal connected()
signal disconnected()
signal game_found(room_id: String, opponent: String)
signal state_updated(game_state: Dictionary)

var socket: WebSocketClient
var server_url: String = "ws://localhost:8002"

func _ready() -> void:
    socket = WebSocketClient.new()
    socket.connect("connection_established", _on_connected)
    socket.connect("connection_closed", _on_disconnected)
    socket.connect("message_received", _on_message_received)

func connect_to_server() -> void:
    socket.connect_to_url(server_url)

func join_queue(player_name: String) -> void:
    _send_message("join_queue", {"playerName": player_name})

func send_deploy_command(unit_type: String, position: Vector2) -> void:
    var command = {
        "type": "deploy_unit",
        "unitType": unit_type,
        "position": {"x": position.x, "y": position.y},
        "timestamp": Time.get_ticks_msec()
    }
    _send_message("game_command", {"command": command})

func _send_message(event: String, data: Dictionary) -> void:
    var message = JSON.stringify({
        "type": event,
        "payload": data
    })
    socket.send_text(message)

func _on_message_received(message: String) -> void:
    var json = JSON.parse_string(message)
    if not json:
        return

    var event_type = json.get("type")
    var payload = json.get("payload", {})

    match event_type:
        "game_found":
            game_found.emit(payload.roomId, payload.opponentName)

        "game_state_update":
            state_updated.emit(payload)

        "game_ended":
            _handle_game_ended(payload)

        "error":
            push_error("Server error: " + str(payload))
```

---

## Testing & Debugging

### Unit Testing with GUT

```gdscript
# tests/unit/test_elixir_manager.gd
extends GutTest

var elixir_manager: ElixirManager

func before_each():
    elixir_manager = ElixirManager.new()
    add_child_autofree(elixir_manager)
    elixir_manager.start_regeneration()

func test_elixir_regenerates():
    var initial = elixir_manager.get_elixir(0)
    await wait_seconds(2.8)
    var after = elixir_manager.get_elixir(0)

    assert_gt(after, initial, "Elixir should regenerate over time")

func test_cannot_overspend():
    elixir_manager.set_elixir(0, 3.0)
    var success = elixir_manager.try_spend_elixir(0, 5.0)

    assert_false(success, "Should not spend more elixir than available")

func test_double_elixir_doubles_rate():
    elixir_manager.set_elixir(0, 0.0)
    elixir_manager.set_double_elixir_mode(true)

    await wait_seconds(1.4)
    var elixir = elixir_manager.get_elixir(0)

    assert_almost_eq(elixir, 1.0, 0.1, "Double elixir should regen 1 per 1.4s")
```

### Integration Testing

```gdscript
# tests/integration/test_battle_flow.gd
extends GutTest

func test_complete_battle():
    var battle_manager = preload("res://scenes/battle/battle_manager.tscn").instantiate()
    add_child_autofree(battle_manager)

    battle_manager.start_battle()
    await wait_for_signal(battle_manager.battle_started, 1.0)

    # Deploy units
    battle_manager.deploy_unit("knight", Vector2(500, 600), 0)
    battle_manager.deploy_unit("knight", Vector2(500, 400), 1)

    # Wait for battle to progress
    await wait_seconds(5.0)

    # Verify units are fighting
    var units = get_tree().get_nodes_in_group("units")
    assert_gt(units.size(), 0, "Units should be spawned")
```

### Debug Tools

```gdscript
# client/scripts/debug/debug_overlay.gd
extends CanvasLayer

@onready var fps_label = $FPSLabel
@onready var elixir_label = $ElixirLabel
@onready var unit_count_label = $UnitCountLabel

func _process(delta: float) -> void:
    fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

    if GameManager.battle_manager:
        var elixir = GameManager.battle_manager.elixir_manager.get_elixir(0)
        elixir_label.text = "Elixir: %.1f" % elixir

        var units = get_tree().get_nodes_in_group("units")
        unit_count_label.text = "Units: " + str(units.size())
```

### Logging Best Practices

```gdscript
# Use appropriate log levels
push_error("Critical error: " + error_msg)  # Red
push_warning("Unit deployed without target")  # Yellow
print("Battle started")  # White (info)
print_debug("Frame time: " + str(delta))  # Gray (debug)
```

---

## Performance Optimization

### 1. Object Pooling

Reuse objects instead of constant instantiation:

```gdscript
# client/scripts/core/object_pool.gd
class_name ObjectPool
extends Node

var pool: Array[Node] = []
var scene: PackedScene
var initial_size: int = 10

func _ready() -> void:
    _populate_pool()

func _populate_pool() -> void:
    for i in range(initial_size):
        var obj = scene.instantiate()
        obj.set_meta("pooled", true)
        pool.append(obj)

func get_object() -> Node:
    if pool.is_empty():
        return scene.instantiate()

    return pool.pop_back()

func return_object(obj: Node) -> void:
    obj.hide()
    obj.set_process(false)
    pool.append(obj)
```

Usage:

```gdscript
# Projectile pooling
var projectile_pool: ObjectPool

func _ready():
    projectile_pool = ObjectPool.new()
    projectile_pool.scene = preload("res://scenes/projectile.tscn")
    add_child(projectile_pool)

func shoot():
    var projectile = projectile_pool.get_object()
    projectile.show()
    projectile.set_process(true)
    # ... use projectile

func _on_projectile_hit():
    projectile_pool.return_object(projectile)
```

### 2. Level of Detail (LOD)

Reduce quality for distant/off-screen objects:

```gdscript
func _process(delta: float) -> void:
    var camera_pos = get_viewport().get_camera_2d().global_position
    var distance = global_position.distance_to(camera_pos)

    if distance > 1000:
        # Far LOD: disable animations, reduce update rate
        sprite.visible = false
        set_process_mode(Node.PROCESS_MODE_DISABLED)
    elif distance > 500:
        # Medium LOD: simple animations
        sprite.visible = true
        sprite.speed_scale = 0.5
    else:
        # Near LOD: full quality
        sprite.visible = true
        sprite.speed_scale = 1.0
```

### 3. Batch Processing

Update in groups instead of individually:

```gdscript
# Instead of updating 100 units every frame:
func _physics_process(delta):
    for unit in units:
        unit.update(delta)  # BAD: 100 calls/frame

# Batch by team:
var update_index = 0
func _physics_process(delta):
    # Update 25 units per frame (spread over 4 frames)
    var batch_size = 25
    var start = update_index
    var end = min(start + batch_size, units.size())

    for i in range(start, end):
        units[i].update(delta)

    update_index = (update_index + batch_size) % units.size()
```

### 4. Optimize Collision Detection

```gdscript
# Use collision layers wisely
# Layer 1: Player units
# Layer 2: Enemy units
# Layer 3: Buildings
# Layer 4: Projectiles

# Units only collide with opposite team + buildings
player_unit.collision_layer = 1
player_unit.collision_mask = 2 | 3  # Enemy units + buildings

enemy_unit.collision_layer = 2
enemy_unit.collision_mask = 1 | 3
```

### 5. Profiling

```gdscript
# Measure function performance
var start_time = Time.get_ticks_usec()

# ... expensive operation ...

var end_time = Time.get_ticks_usec()
var elapsed = (end_time - start_time) / 1000.0  # Convert to ms
print("Operation took: ", elapsed, "ms")
```

Use Godot's built-in profiler:
- Debug > Profiler
- Monitor CPU, memory, and network usage
- Identify bottlenecks

---

## Conclusion

This developer guide covers the essential systems and patterns used in Battle Castles. For more detailed information:

- **API Documentation:** See `API_DOCUMENTATION.md`
- **Deployment Guide:** See `DEPLOYMENT.md`
- **Game Design Specs:** See `game-design/` directory
- **User Manual:** See `USER_MANUAL.md`

### Best Practices Summary

1. **Follow SOLID principles** - Keep code modular and testable
2. **Use ECS architecture** - Composition over inheritance
3. **Server-authoritative** - Never trust client input
4. **Profile before optimizing** - Measure, don't guess
5. **Write tests** - Unit, integration, and E2E tests
6. **Document as you go** - Code comments and documentation
7. **Git workflow** - Feature branches, PRs, code reviews

### Getting Help

- **Discord:** [discord.gg/battlecastles](https://discord.gg/battlecastles)
- **GitHub Issues:** Report bugs and request features
- **Docs:** Read architecture and API documentation

**Happy coding!**

---

**Version:** 0.1.0
**Last Updated:** November 1, 2025
**Maintainers:** Battle Castles Development Team
