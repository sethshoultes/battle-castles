# Battle Castles - Comprehensive Build Plan

## Executive Summary

Battle Castles is a real-time multiplayer strategy game inspired by Clash Royale, designed for PC, Mac, Linux, and Raspberry Pi 5 platforms. This document outlines the complete technical implementation plan following SOLID, DRY, KISS, YAGNI, and clean code principles.

### Project Goals
- Deliver a polished, cross-platform strategy game in 9 months
- Support single-player and LAN multiplayer modes
- Achieve 60+ FPS on target platforms (30+ FPS on Raspberry Pi 5)
- Build a maintainable, extensible codebase
- Create engaging gameplay with 3-minute matches

## Technology Architecture

### Game Engine Selection: Godot 4.3

**Rationale for Godot:**
- Native ARM64 support (critical for Raspberry Pi 5)
- Lightweight runtime (~50MB)
- Open source with no licensing fees
- Built-in networking with ENet
- Deterministic physics for replays
- Excellent 2D performance
- GDScript for rapid development
- C++ extensions for performance-critical code

### Programming Languages

#### Client-Side Stack
```
Primary Development (80%):
└── GDScript
    ├── Game logic
    ├── UI systems
    ├── Network client
    └── AI behavior

Performance Critical (20%):
└── C++ (GDExtension)
    ├── Combat calculations
    ├── Pathfinding (A*)
    ├── Network packet processing
    └── Deterministic simulation
```

#### Server-Side Stack
```
Game Server:
└── Node.js + TypeScript
    ├── Battle simulation
    ├── WebSocket management
    └── State synchronization

Matchmaking Service:
└── Go
    ├── Queue management
    ├── Skill-based matching
    └── High concurrency

Economy Service:
└── Python + FastAPI
    ├── Currency transactions
    ├── Reward calculations
    └── Analytics processing
```

### Architecture Pattern

#### Hybrid ECS + Command Pattern

```gdscript
# Entity-Component-System for game objects
class_name Entity
    var components: Dictionary = {}

    func add_component(component: Component):
        components[component.get_class()] = component

# Command Pattern for networking and replay
class_name Command
    var timestamp: float
    var player_id: int

    func execute(state: GameState) -> void:
        pass  # Override in subclasses

    func validate(state: GameState) -> bool:
        pass  # Server-side validation
```

### Database Architecture

```yaml
PostgreSQL 14 (Primary Data):
  - Player profiles
  - Match history
  - Card collections
  - Clan data
  - Transaction logs

Redis 7 (Caching & Real-time):
  - Session management
  - Matchmaking queues
  - Live leaderboards
  - Temporary battle states
  - Rate limiting
```

## Core Game Systems

### 1. Battle System

```gdscript
# Battle Loop (60 FPS client, 20 Hz server)
class_name BattleManager extends Node
    const TICK_RATE = 0.05  # 20 Hz
    const MATCH_DURATION = 180.0  # 3 minutes

    var elapsed_time: float = 0.0
    var game_state: GameState
    var command_buffer: Array[Command] = []

    func _physics_process(delta):
        # Client prediction
        predict_next_state(delta)

        # Process server updates
        if has_server_update():
            reconcile_with_server()

    func server_tick():
        # Authoritative simulation
        process_commands()
        update_physics()
        check_collisions()
        apply_damage()
        check_victory_conditions()
        broadcast_state()
```

### 2. Unit System

```gdscript
# Data-driven unit definitions
class_name UnitResource extends Resource
    @export var unit_name: String
    @export var elixir_cost: int
    @export var deploy_time: float = 1.0

    @export_group("Stats")
    @export var health: int
    @export var damage: int
    @export var attack_speed: float
    @export var move_speed: float
    @export var range: float

    @export_group("Targeting")
    @export var targets_buildings_only: bool = false
    @export var targets_air: bool = false

    @export_group("Level Scaling")
    @export var health_per_level: int
    @export var damage_per_level: int
```

### 3. Elixir System

```gdscript
class_name ElixirManager extends Node
    signal elixir_changed(amount: float)

    const MAX_ELIXIR = 10.0
    const BASE_REGEN_RATE = 1.0 / 2.8  # 1 elixir per 2.8 seconds
    const DOUBLE_ELIXIR_TIME = 120.0  # Last minute

    var current_elixir: float = 5.0
    var is_double_elixir: bool = false

    func _process(delta):
        var regen_rate = BASE_REGEN_RATE
        if is_double_elixir:
            regen_rate *= 2.0

        current_elixir = min(current_elixir + regen_rate * delta, MAX_ELIXIR)
        elixir_changed.emit(current_elixir)
```

### 4. AI System (Single-Player)

```gdscript
# Hierarchical Task Network for AI
class_name AIController extends Node
    enum Difficulty { EASY, NORMAL, HARD }

    var difficulty: Difficulty
    var decision_interval: float = 1.0  # Seconds between decisions

    func make_decision(game_state: GameState) -> Command:
        var evaluation = evaluate_board_state(game_state)

        match difficulty:
            Difficulty.EASY:
                return random_valid_move(game_state)
            Difficulty.NORMAL:
                return tactical_decision(evaluation)
            Difficulty.HARD:
                return strategic_decision(evaluation)

    func evaluate_board_state(state: GameState) -> BoardEvaluation:
        var eval = BoardEvaluation.new()
        eval.threat_level = calculate_threat()
        eval.elixir_advantage = calculate_elixir_advantage()
        eval.tower_health_diff = calculate_tower_diff()
        return eval
```

## Network Architecture

### LAN Multiplayer Design

```
┌─────────────────────────────┐
│     HOST (Player 1)         │
│  ┌────────────────────┐     │
│  │ Authoritative State│     │
│  │ Input Validation   │     │
│  │ Physics Simulation │     │
│  └────────────────────┘     │
└──────────┬──────────────────┘
           │ WebSocket
    ┌──────┴──────┐
    │             │
┌───▼──┐      ┌───▼──┐
│Client│      │Client│
│  P2  │      │  P3  │
└──────┘      └──────┘
```

### Network Protocol

```gdscript
# Message types
enum MessageType {
    JOIN_ROOM,
    LEAVE_ROOM,
    GAME_STATE,
    PLAYER_INPUT,
    UNIT_DEPLOY,
    GAME_END
}

# Serialization format (binary for efficiency)
class_name NetworkMessage
    var type: MessageType
    var timestamp: float
    var payload: Dictionary

    func serialize() -> PackedByteArray:
        var buffer = PackedByteArray()
        buffer.append(type)
        buffer.append_array(var_to_bytes(timestamp))
        buffer.append_array(var_to_bytes(payload))
        return buffer
```

### Lag Compensation

```gdscript
class_name ClientPrediction extends Node
    var state_buffer: Array[GameState] = []
    var input_buffer: Array[Command] = []
    const BUFFER_SIZE = 10

    func predict_movement(delta: float):
        # Continue moving based on last known velocity
        for unit in local_units:
            unit.position += unit.velocity * delta

    func server_reconciliation(server_state: GameState):
        # Find the matching state in our buffer
        var index = find_state_index(server_state.timestamp)

        # Replay all inputs from that point
        for i in range(index, input_buffer.size()):
            apply_input(input_buffer[i])
```

## Performance Optimization

### Platform-Specific Settings

```gdscript
class_name QualitySettings extends Node
    enum Platform { PC_HIGH, PC_MID, MAC, RASPBERRY_PI }

    func detect_platform() -> Platform:
        if OS.get_name() == "Linux" and OS.get_processor_name().contains("ARM"):
            return Platform.RASPBERRY_PI
        elif OS.get_name() == "macOS":
            return Platform.MAC
        else:
            return Platform.PC_HIGH if OS.get_processor_count() >= 8 else Platform.PC_MID

    func apply_settings(platform: Platform):
        match platform:
            Platform.PC_HIGH:
                Engine.max_fps = 144
                RenderingServer.set_default_clear_color(Color.BLACK)
                ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_2d", 2)
            Platform.RASPBERRY_PI:
                Engine.max_fps = 30
                ProjectSettings.set_setting("rendering/quality/shadows/enabled", false)
                ProjectSettings.set_setting("rendering/limits/max_lights_per_object", 4)
```

### Memory Management

```gdscript
# Object pooling for frequently spawned objects
class_name ObjectPool extends Node
    var pools: Dictionary = {}

    func _ready():
        # Pre-allocate common objects
        create_pool("Goblin", preload("res://units/goblin.tscn"), 30)
        create_pool("Arrow", preload("res://projectiles/arrow.tscn"), 50)
        create_pool("Explosion", preload("res://effects/explosion.tscn"), 20)

    func get_object(type: String):
        if not pools.has(type) or pools[type].available.is_empty():
            return pools[type].scene.instantiate()
        return pools[type].available.pop_back()

    func return_object(type: String, obj: Node):
        obj.reset()  # Reset to default state
        pools[type].available.push_back(obj)
```

## Development Workflow

### Git Workflow

```bash
# Feature development
git checkout -b feature/elixir-system
# ... make changes ...
git add .
git commit -m "feat(battle): implement elixir regeneration system"
git push origin feature/elixir-system
# Create PR for review

# Hotfix for production
git checkout -b hotfix/crash-on-deploy
# ... fix issue ...
git commit -m "fix(battle): prevent null reference on unit deploy"
git push origin hotfix/crash-on-deploy
# Fast-track merge after review
```

### CI/CD Pipeline

```yaml
name: Build and Test
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: GDScript Linting
        run: gdformat --check client/

  test:
    runs-on: ubuntu-latest
    steps:
      - name: Run Unit Tests
        run: godot --headless --script res://tests/run_tests.gd

  build:
    strategy:
      matrix:
        platform: [windows, linux, macos, raspberry-pi]
    steps:
      - name: Build for ${{ matrix.platform }}
        run: |
          godot --export "${{ matrix.platform }}" \
                builds/battle_castles_${{ matrix.platform }}
```

## Testing Strategy

### Test Categories

#### 1. Unit Tests (GdUnit4)
```gdscript
class_name TestCombatSystem extends GdUnitTestSuite

func test_damage_calculation():
    var attacker = create_test_unit("Knight", 1)
    var defender = create_test_unit("Goblin", 1)

    var damage = CombatSystem.calculate_damage(attacker, defender)
    assert_that(damage).is_equal(75)

func test_critical_hit():
    # Set RNG seed for deterministic test
    seed(12345)
    var damage = CombatSystem.calculate_damage_with_crit(attacker, defender)
    assert_that(damage).is_greater_than(75)
```

#### 2. Integration Tests
```gdscript
func test_network_sync():
    var server = create_test_server()
    var client1 = create_test_client()
    var client2 = create_test_client()

    client1.connect_to_server(server.address)
    client2.connect_to_server(server.address)

    client1.deploy_unit("Knight", Vector2(100, 100))

    await wait_for_sync()

    assert_that(client2.get_unit_count()).is_equal(1)
    assert_that(client2.get_unit_at(Vector2(100, 100))).is_not_null()
```

#### 3. Performance Tests
```gdscript
func test_frame_rate_with_max_units():
    var battle = create_test_battle()

    # Spawn maximum units
    for i in range(40):
        battle.spawn_unit("Goblin", Vector2(randf() * 500, randf() * 800))

    # Measure frame time
    var start = Time.get_ticks_msec()
    for i in range(60):  # Simulate 1 second
        battle._physics_process(0.016)  # 60 FPS
    var elapsed = Time.get_ticks_msec() - start

    assert_that(elapsed).is_less(1100)  # Should complete in ~1 second
```

## Sprint Plan (9 Months)

### Phase 1: Foundation (Months 1-2)
**Sprints 0-3: Core Systems**
- Sprint 0: Setup and prototyping
- Sprint 1: Basic combat and movement
- Sprint 2: Four units implemented
- Sprint 3: Network foundation

**Deliverables:**
- Playable prototype with 2 units
- Basic multiplayer over LAN
- Combat system working
- Elixir management

### Phase 2: Vertical Slice (Month 3)
**Sprints 4-5: Polish Core Loop**
- Sprint 4: Full battle flow
- Sprint 5: Art and audio integration

**Deliverables:**
- Complete battle experience
- One polished arena
- All 4 units with animations
- Sound effects and music

### Phase 3: Features (Months 4-5)
**Sprints 6-9: Progression & Social**
- Sprint 6: Card collection system
- Sprint 7: Economy and rewards
- Sprint 8: Matchmaking
- Sprint 9: Social features

**Deliverables:**
- Progression systems
- 8+ units total
- 3 complete arenas
- Clan system

### Phase 4: Content (Month 6)
**Sprints 10-11: Complete Content**
- Sprint 10: All arenas complete
- Sprint 11: Polish pass

**Deliverables:**
- 10 arenas
- Tutorial
- All audio/visual polish

### Phase 5: Testing (Month 7)
**Sprints 12-13: QA & Balance**
- Sprint 12: Internal testing
- Sprint 13: Closed beta

**Deliverables:**
- Bug-free build
- Balanced gameplay
- Performance optimized

### Phase 6: Launch (Months 8-9)
**Sprints 14-17: Soft & Global Launch**
- Sprint 14-15: Soft launch preparation
- Sprint 16-17: Global launch

**Deliverables:**
- Live game
- Marketing materials
- Post-launch support plan

## Raspberry Pi 5 Deployment

### Compatibility Assessment
✅ **Fully Compatible with Godot 4.3**
- ARM64 native support
- 30-60 FPS achievable at 1080p
- 16GB RAM more than sufficient
- Excellent for LAN parties

### Optimization Strategy
```gdscript
# RPi5-specific settings
func configure_for_raspberry_pi():
    Engine.max_fps = 30
    ProjectSettings.set_setting("rendering/quality/driver/driver_name", "GLES3")
    ProjectSettings.set_setting("rendering/quality/shadows/filter_mode", 0)
    ProjectSettings.set_setting("rendering/quality/reflections/texture_array_reflections", false)

    # Reduce particle counts
    for emitter in get_tree().get_nodes_in_group("particle_emitters"):
        emitter.amount = emitter.amount / 2
```

### Deployment Package
```bash
#!/bin/bash
# Build script for Raspberry Pi

# Export ARM64 binary
godot --export "Linux ARM64" battle_castles_arm64

# Create .deb package
mkdir -p debian/usr/local/bin
mkdir -p debian/usr/share/applications
mkdir -p debian/DEBIAN

cp battle_castles_arm64 debian/usr/local/bin/battle-castles
cp battle-castles.desktop debian/usr/share/applications/

cat > debian/DEBIAN/control << EOF
Package: battle-castles
Version: 1.0.0
Architecture: arm64
Maintainer: Your Name
Description: Real-time strategy battle game
Depends: libgles2, libasound2
EOF

dpkg-deb --build debian battle-castles_1.0.0_arm64.deb
```

## Quality Metrics

### Performance Targets
| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| Frame Rate (PC) | 144 FPS | 60 FPS | 30 FPS |
| Frame Rate (RPi5) | 60 FPS | 30 FPS | 24 FPS |
| Network Latency | <50ms | <100ms | <150ms |
| Memory Usage | <400MB | <600MB | <1GB |
| Load Time | <3s | <5s | <10s |

### Code Quality Standards
- Test Coverage: 80% minimum
- Cyclomatic Complexity: <10 per function
- Documentation: All public APIs documented
- Code Review: 2 approvals for features
- Performance: Profile weekly

## Risk Mitigation

### Technical Risks
1. **Network Desync**
   - Mitigation: Deterministic simulation
   - Fallback: Force resync from server

2. **Performance on RPi5**
   - Mitigation: LOD system, reduced effects
   - Fallback: 720p resolution option

3. **Memory Leaks**
   - Mitigation: Object pooling, profiling
   - Fallback: Periodic garbage collection

### Project Risks
1. **Scope Creep**
   - Mitigation: YAGNI principle, clear MVP
   - Fallback: Post-launch features

2. **Team Scaling**
   - Mitigation: Clear documentation
   - Fallback: Contractor support

## Success Criteria

### Launch Requirements
- [ ] 4 fully functional units
- [ ] 3-minute battle loop polished
- [ ] LAN multiplayer stable
- [ ] Single-player AI (3 difficulties)
- [ ] 60 FPS on target platforms
- [ ] <100ms network latency
- [ ] Zero critical bugs
- [ ] 10 complete arenas

### Post-Launch Goals
- 10,000 downloads in first month
- 4.0+ star rating
- 30% D7 retention
- Active community

## Conclusion

This comprehensive build plan provides a clear roadmap for developing Battle Castles using Godot Engine with support for PC, Mac, Linux, and Raspberry Pi 5. The architecture emphasizes clean code principles, performance optimization, and cross-platform compatibility while maintaining a realistic 9-month development timeline.

The plan prioritizes:
1. Technical excellence through SOLID principles
2. Performance across all platforms
3. Maintainable, extensible codebase
4. Engaging gameplay mechanics
5. Robust multiplayer support

With this foundation, Battle Castles is positioned to deliver a high-quality gaming experience that runs smoothly on everything from high-end PCs to Raspberry Pi 5 devices.