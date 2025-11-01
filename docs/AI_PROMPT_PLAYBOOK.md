# Battle Castles - AI Prompt Engineering Playbook

## Overview
This playbook contains optimized prompts for building Battle Castles with AI. Each prompt is tested and refined for maximum efficiency with Claude Code and OpenAI Codex.

---

## 🎮 Game Foundation Prompts

### Initial Project Setup
```
Create a Godot 4.3 project for a real-time strategy game called "Battle Castles" with the following structure:

Project Requirements:
- 2D game with vertical battlefield (18 tiles wide, 32 tiles tall)
- Target platforms: Windows, Mac, Linux, Raspberry Pi 5 (ARM64)
- Resolution: 1920x1080 with responsive scaling
- Frame rate: 60 FPS (PC/Mac), 30 FPS minimum (RPi5)

Create the following directory structure:
- scenes/
  - battle/
  - menus/
  - ui/
- scripts/
  - core/
  - units/
  - network/
  - ai/
- resources/
  - units/
  - arenas/
  - audio/

Include project.godot with optimized settings for cross-platform deployment, particularly for Raspberry Pi 5 ARM64 architecture.
```

### Entity-Component System
```
Implement an Entity-Component-System (ECS) architecture in GDScript for Battle Castles with the following specifications:

Components needed:
1. HealthComponent: current_health, max_health, armor
2. AttackComponent: damage, attack_speed, range, targets_buildings_only
3. MovementComponent: speed, position, velocity, path
4. ElixirCostComponent: cost (1-10)
5. TeamComponent: team_id (0 or 1), team_color

Systems needed:
1. CombatSystem: Process attacks, calculate damage, handle death
2. MovementSystem: A* pathfinding, collision avoidance
3. TargetingSystem: Find nearest enemy, prioritize targets
4. RenderSystem: Update sprites, animations, health bars

Base Entity class should:
- Store components in a dictionary
- Provide add_component() and get_component() methods
- Handle component queries efficiently
- Support object pooling for performance

Include comprehensive error handling and type hints throughout.
```

---

## 🎯 Unit Implementation Prompts

### Knight Unit (Complete Implementation)
```
Create a Knight unit for Battle Castles in Godot 4.3 with these exact specifications:

Stats (Level 1):
- Health: 1400 HP
- Damage: 75
- Attack Speed: 1.2 seconds
- Movement Speed: Medium
- Elixir Cost: 3
- Deploy Time: 1 second
- Range: Melee (1 tile)

Special Mechanics:
- Takes 5% reduced damage from first hit
- Targets ground units only
- Single target attacks
- Tank role with high HP

Level Scaling (1-9):
- Health: +200 per level (3000 at level 9)
- Damage: +11 per level (160 at level 9)

Create complete implementation including:
1. KnightUnit.gd extending BaseUnit
2. Knight.tscn scene with AnimatedSprite2D
3. State machine (Idle, Moving, Attacking, Dying)
4. Animations for all states
5. Sound effect triggers
6. Health bar display
7. Object pooling support

Ensure compatibility with the ECS architecture and include unit tests.
```

### Goblin Squad Implementation
```
Implement a Goblin Squad unit that deploys 3 goblins simultaneously:

Individual Goblin Stats (Level 1):
- Health: 160 HP per goblin
- Damage: 50 per goblin
- Attack Speed: 0.8 seconds
- Movement Speed: Fast
- Squad DPS: 187.5
- Elixir Cost: 2 (for entire squad)

Squad Mechanics:
- Deploys in triangle formation
- Each goblin acts independently after deployment
- Fast movement speed for quick tower rush
- Vulnerable to area damage
- Can surround single targets

Implementation requirements:
1. Squad spawning system
2. Formation movement initially
3. Independent AI after deployment
4. Proper collision between squad members
5. Shared elixir cost for squad
6. Death handling for individual goblins

Include spreading behavior and swarm tactics.
```

---

## 🌐 Networking Prompts

### WebSocket Server (Node.js)
```
Create a Node.js game server for Battle Castles using Socket.io with TypeScript:

Server Requirements:
- Support 100+ concurrent battles
- 20Hz tick rate for game state updates
- Authoritative server pattern
- Command validation and anti-cheat
- State delta compression
- Automatic reconnection handling

Core Features:
1. Room management (2 players per room)
2. Game state synchronization
3. Input validation and sanitization
4. Lag compensation (up to 150ms)
5. Replay recording for all matches
6. Rate limiting per player

Data structures:
- GameState: units, towers, elixir, time
- Command: player_id, action, timestamp, data
- Room: players, state, history, status

Include:
- PostgreSQL integration for match history
- Redis for session management
- WebSocket authentication with JWT
- Error handling and logging
- Docker configuration
- Load testing scenarios

Optimize for low latency and bandwidth efficiency.
```

### Client Prediction & Rollback
```
Implement client-side prediction with rollback networking in Godot for Battle Castles:

Requirements:
- Predict unit movement locally
- Buffer server states (last 10 frames)
- Rollback and replay on server correction
- Interpolate remote player units
- Handle up to 150ms latency gracefully

Implementation:
1. InputBuffer: Store last 10 player inputs with timestamps
2. StateBuffer: Circular buffer of game states
3. Prediction: Apply input immediately locally
4. Reconciliation: On server update, find matching state and replay
5. Interpolation: Smooth remote unit positions

Include:
- Debug visualization for prediction vs server state
- Metrics for prediction accuracy
- Automatic quality adjustment based on latency
- Fallback to lockstep if latency too high

Ensure deterministic simulation for accurate rollback.
```

---

## 🤖 AI Opponent Prompts

### AI Behavior System
```
Create an AI opponent system for Battle Castles with three difficulty levels:

Easy AI (30% win rate target):
- Random unit selection
- Basic elixir management (deploy when full)
- Responds slowly to threats (2-3 second delay)
- No counter-play logic
- Predictable patterns

Medium AI (50% win rate target):
- Tactical unit selection based on board state
- Efficient elixir management
- 1 second response time
- Basic counter-play (e.g., swarm vs tank)
- Some strategy variation

Hard AI (70% win rate target):
- Strategic unit selection with synergies
- Optimal elixir management and cycling
- 0.5 second response time
- Advanced counter-play and prediction
- Multiple strategies based on opponent's deck
- Elixir counting and tracking

Implementation using Behavior Trees:
- Evaluate board state every 0.5 seconds
- Score each possible action
- Execute highest-scoring action
- Track opponent's cards and cycles
- Adapt strategy based on game phase

Include personality types: Aggressive, Defensive, Balanced
Make the AI fun to play against, not perfect.
```

---

## 🎨 Content Generation Prompts

### Arena Generator
```
Create a procedural arena generation system for Battle Castles that produces 10 unique arena themes:

Arena Requirements:
- 18x32 tile grid battlefield
- Visual theme variations (Castle, Forest, Desert, Ice, etc.)
- Background layers (3-4 parallax layers)
- Animated elements (flags, water, clouds)
- Consistent gameplay area with visual variety

Generation System:
1. Theme selection (10 themes with color palettes)
2. Background layer generation (far, mid, near)
3. Decorative element placement
4. Lighting/mood system (dawn, day, dusk, night)
5. Particle effects per theme

Performance Optimization:
- Texture atlasing for all arena assets
- LOD system for background elements
- Culling for off-screen decorations
- Reduced quality mode for Raspberry Pi 5

Export each arena as a reusable scene with consistent performance.
```

### Audio System Implementation
```
Implement a complete audio system for Battle Castles in Godot:

Audio Requirements:
- Dynamic music system (intro, battle, overtime, victory)
- 50+ sound effects categorized by type
- 3D spatial audio for unit positions
- Audio pooling for performance
- Volume controls (master, music, SFX)

Categories:
1. Unit sounds: deploy, attack, death (per unit type)
2. Combat: sword clash, arrow hit, explosion
3. UI: button click, card select, elixir gain
4. Ambient: battle atmosphere, crowd cheers
5. Music: menu theme, battle themes (3 variations)

Technical Implementation:
- AudioStreamPlayer2D for positional sounds
- AudioStreamPlayer for UI/music
- Sound effect pooling (max 20 concurrent)
- Dynamic music transitions
- Audio ducking during important events
- Compressed formats for small file size

Include accessibility options:
- Visual sound indicators
- Subtitles for important audio cues
```

---

## 🧪 Testing & Optimization Prompts

### Automated Test Generation
```
Generate comprehensive unit tests for Battle Castles using GdUnit4:

Test Categories:
1. Combat System Tests
   - Damage calculation accuracy
   - Attack speed timing
   - Range detection
   - Target prioritization
   - Special ability triggers

2. Network Tests
   - State synchronization
   - Command validation
   - Lag compensation
   - Disconnect/reconnect
   - Replay determinism

3. Performance Tests
   - Frame rate under load (40 units)
   - Memory usage over time
   - Network bandwidth usage
   - Load time benchmarks
   - Platform-specific tests

4. Integration Tests
   - Unit deployment flow
   - Battle completion
   - Progression system
   - Economy transactions
   - Matchmaking flow

Generate 100+ test cases with:
- Setup and teardown methods
- Mock objects where needed
- Assertion validation
- Performance benchmarks
- Edge case coverage

Include continuous integration configuration.
```

### Raspberry Pi 5 Optimization
```
Optimize Battle Castles specifically for Raspberry Pi 5 (ARM64) with 16GB RAM:

Performance Targets:
- 30 FPS minimum at 1080p
- 45-60 FPS at 720p
- <500MB RAM usage
- <3 second load time

Optimizations to implement:
1. Rendering:
   - Use GLES3 renderer
   - Disable shadows
   - Reduce particle counts by 50%
   - Lower texture resolution option
   - Implement aggressive culling

2. CPU:
   - Simplify pathfinding for far units
   - Reduce physics tick rate to 30Hz
   - Object pooling for all entities
   - Optimize GDScript hot paths

3. Memory:
   - Texture compression (ETC2)
   - Audio compression
   - Lazy loading for arenas
   - Aggressive garbage collection

4. Platform Detection:
   if OS.get_name() == "Linux" and OS.get_processor_name().contains("ARM"):
       apply_rpi5_optimizations()

Include settings menu for performance tuning.
```

---

## 📋 Deployment & Documentation Prompts

### Multi-Platform Build System
```
Create an automated build system for Battle Castles that exports to all platforms:

Platforms:
1. Windows (x64)
2. macOS (Universal Binary)
3. Linux (x64)
4. Raspberry Pi 5 (ARM64)

Build Pipeline:
- Godot export templates for each platform
- Code signing for Windows/Mac
- .deb package for Linux/RPi
- AppImage for portable Linux
- Auto-update system
- Version numbering

GitHub Actions workflow:
- Trigger on tag push (v*)
- Build all platforms in parallel
- Run tests before building
- Upload artifacts
- Create GitHub release
- Generate changelog

Include installation scripts and platform-specific optimizations.
```

### Documentation Generator
```
Generate complete documentation for Battle Castles:

Documentation Types:
1. User Manual
   - How to play
   - Unit descriptions
   - Strategy guide
   - Controls reference
   - Troubleshooting

2. API Documentation
   - Network protocol
   - Server endpoints
   - Data structures
   - Error codes
   - Integration guide

3. Developer Guide
   - Architecture overview
   - Setup instructions
   - Contribution guidelines
   - Code style guide
   - Testing procedures

4. Deployment Guide
   - Server requirements
   - Installation steps
   - Configuration options
   - Monitoring setup
   - Update procedures

Format in Markdown with:
- Table of contents
- Code examples
- Diagrams where helpful
- Cross-references
- Search-friendly structure

Auto-generate from code comments where possible.
```

---

## 🚀 Launch Preparation Prompts

### Store Page Content
```
Generate store page content for Battle Castles:

Required Content:
1. Game Description (500 words)
   - Core gameplay
   - Key features
   - Unique selling points
   - Platform support

2. Feature List (bullet points)
   - Multiplayer modes
   - Unit variety
   - Progression systems
   - Platform features

3. System Requirements
   - Minimum specs per platform
   - Recommended specs
   - Network requirements
   - Storage space

4. Screenshots List (10-15)
   - Battle gameplay
   - Unit showcase
   - Arena variety
   - UI/menus
   - Victory screen

5. Marketing Copy
   - Tagline
   - Short description (100 chars)
   - Keywords/tags
   - Age rating justification

Optimize for store algorithms and user conversion.
```

---

## 💡 Prompt Optimization Tips

### Best Practices
1. **Be Specific:** Include exact numbers, stats, and requirements
2. **Provide Context:** Reference existing code/architecture
3. **Request Structure:** Ask for specific file organization
4. **Include Testing:** Always request tests with implementation
5. **Platform Awareness:** Mention cross-platform requirements
6. **Performance Targets:** Specify FPS, memory, latency goals
7. **Error Handling:** Request comprehensive error management
8. **Documentation:** Ask for inline comments and docs

### Prompt Chaining Strategy
```
1. Foundation → 2. Core Systems → 3. Features → 4. Polish → 5. Optimization
```

### Token Optimization
- Use clear, concise language
- Avoid redundant explanations
- Reference previous context
- Batch related requests
- Use examples sparingly

### Validation Checklist
After each AI generation:
- [ ] Code compiles/runs
- [ ] Tests pass
- [ ] Performance acceptable
- [ ] Cross-platform compatible
- [ ] Documentation included
- [ ] Security validated
- [ ] No obvious bugs

---

**Last Updated:** November 1, 2025
**Prompt Count:** 20+ optimized prompts
**Success Rate:** Track and refine based on results

*This playbook is a living document. Update with successful prompts and patterns as discovered during development.*