# Battle Castles - Project Memory

## Project Overview
**Game:** Battle Castles - Real-time Multiplayer Strategy Battle Game
**Genre:** Tower Defense / RTS (Clash Royale-inspired)
**Platforms:** PC (Windows/Linux), Mac, Raspberry Pi 5
**Modes:** Single-player (vs AI), Local Network Multiplayer (LAN)
**Timeline:** 9-month development cycle
**Status:** Pre-Production Phase

## Core Game Mechanics
- 3-minute real-time battles on vertical battlefield
- Deploy medieval fantasy units using elixir resource system
- Destroy opponent's castle while defending your own
- 4 core units at launch: Knight, Goblin Squad, Archer Pair, Giant
- Elixir regeneration: 1 per 2.8 seconds (doubles in final minute)
- Victory conditions: Destroy enemy castle or most damage when timer expires

## Technology Stack

### Game Engine & Language
- **Engine:** Godot 4.3 (chosen for cross-platform support and Raspberry Pi compatibility)
- **Primary Language:** GDScript (rapid development)
- **Performance Critical:** C++ GDExtensions (combat, pathfinding, networking)
- **Architecture:** Hybrid ECS + Command Pattern

### Backend Services
- **Game Server:** Node.js + Socket.io (WebSocket real-time sync)
- **Matchmaking:** Go/Golang (high-concurrency)
- **Authentication:** Node.js + JWT tokens
- **Economy Service:** Python + FastAPI
- **Databases:** PostgreSQL 14 (primary), Redis 7 (caching/sessions)
- **Infrastructure:** Docker, AWS ECS (future production)

### Development Tools
- **Version Control:** Git + GitHub (GitHub Flow branching)
- **CI/CD:** GitHub Actions
- **Task Management:** Jira/Linear (2-week sprints)
- **Communication:** Slack/Discord
- **Documentation:** Markdown files, Notion/Confluence
- **Testing:** GdUnit4 (Godot), Jest (Node.js), pytest (Python)

## Architecture Decisions

### Network Architecture
- **Model:** Authoritative Host with Client Prediction
- **Protocol:** WebSocket (reliable) + UDP (position updates)
- **Tick Rate:** Server 20Hz, Client 60Hz
- **LAN Discovery:** Automatic via UDP broadcast
- **Synchronization:** Command Pattern for deterministic replay

### AI System Design
- **Approach:** Hierarchical Task Network (HTN)
- **Layers:** Strategic → Tactical → Execution
- **Difficulties:** Easy, Normal, Hard
- **Behavior:** Composition-based (SOLID principles)

### Data Management
- **Game Data:** Godot Resources (.tres files)
- **Save System:** Compressed, encrypted local saves
- **Configuration:** JSON/YAML for balance data
- **No Hardcoded Values:** Everything data-driven

## Coding Principles
1. **SOLID** - Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
2. **DRY** - Don't Repeat Yourself (single source of truth)
3. **KISS** - Keep It Simple, Stupid (avoid over-engineering)
4. **YAGNI** - You Aren't Gonna Need It (no speculative features)
5. **Clean Code** - Readable, maintainable, testable

## Platform Specifications

### PC/Mac Requirements
- **Minimum:** Windows 10, Intel i3, 4GB RAM
- **Recommended:** Windows 11, Intel i5, 8GB RAM
- **Target FPS:** 144 (PC), 120 (Mac M1+)

### Raspberry Pi 5 (16GB RAM + Hailo Kit)
- **Feasibility:** ✅ Fully compatible with Godot
- **Expected FPS:** 30-60 FPS at 1080p
- **Max Units:** 40 simultaneous
- **Network Latency:** 1-5ms (LAN)
- **Optimization:** LOD system, reduced particles
- **Deployment:** .deb package or AppImage

## Development Phases

### Current Phase: Pre-Production (Month 1)
- [x] Game design documentation review
- [x] Technology stack selection
- [x] Architecture planning
- [ ] Team structure definition
- [ ] Development environment setup
- [ ] Initial prototype

### Upcoming Milestones
1. **Month 1:** Prototype with 2 units
2. **Month 3:** Vertical Slice (4 units, 1 arena, polished)
3. **Month 5:** Alpha Build (feature-complete)
4. **Month 6:** Beta Build (content-complete)
5. **Month 7:** Release Candidate (testing phase)
6. **Month 8:** Soft Launch (test markets)
7. **Month 9:** Global Launch

## Team Requirements
- **Minimum Size:** 12-15 people
- **Core Roles:** Tech Lead, 2 Client Engineers, 2 Backend Engineers, QA Engineer
- **Design:** Game Designer, UI/UX Designer, 2x 2D Artists
- **Management:** Producer, Product Manager, Community Manager (Month 7+)

## Project Structure
```
battle-castles/
├── CLAUDE.md (this file)
├── README.md
├── docs/
│   ├── architecture/
│   ├── api/
│   ├── game-design/
│   └── progress/
├── client/ (Godot project)
│   ├── project.godot
│   ├── assets/
│   ├── scenes/
│   └── scripts/
├── server/
│   ├── game-server/ (Node.js)
│   ├── matchmaking/ (Go)
│   ├── auth-service/ (Node.js)
│   └── economy/ (Python)
├── shared/
│   └── protocols/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── performance/
└── deployment/
    ├── docker/
    └── kubernetes/
```

## Current Sprint: Sprint 0 (Weeks 1-2)
**Goals:** Foundation and setup
**Tasks:**
- [ ] Git repository setup
- [ ] Docker Compose configuration
- [ ] CI/CD pipeline
- [ ] Godot project initialization
- [ ] Server scaffolding
- [ ] Database schema

## Key Design Patterns

### Entity-Component-System (ECS)
```gdscript
# Components: Data containers
class_name HealthComponent extends Component
class_name AttackComponent extends Component

# Systems: Logic processors
class_name CombatSystem extends System
class_name MovementSystem extends System
```

### Command Pattern (Networking)
```gdscript
class_name DeployUnitCommand extends Command
    var player_id: int
    var unit_type: String
    var position: Vector2

    func execute(game_state: GameState):
        # Validate and execute
```

### Object Pooling (Performance)
```gdscript
class_name ObjectPool extends Node
    func get_projectile() -> Projectile
    func return_projectile(p: Projectile)
```

## Performance Targets

| Platform | Target FPS | Min Units | Max Units |
|----------|------------|-----------|-----------|
| PC High | 144 | 40 | 100 |
| PC Mid | 60 | 40 | 80 |
| Mac M1 | 120 | 40 | 100 |
| RPi5 | 30 | 20 | 40 |

## Network Specifications
- **Update Rate:** Position 10Hz, Combat immediate
- **Latency Target:** <100ms optimal, <150ms playable
- **Bandwidth:** ~50KB/s per battle
- **Concurrent Battles:** 10-20 per RPi5 server

## Testing Strategy
1. **Unit Tests:** Core game logic, damage calculations
2. **Integration Tests:** Network synchronization, database
3. **Performance Tests:** Load testing, FPS monitoring
4. **Determinism Tests:** Replay consistency
5. **Platform Tests:** PC, Mac, Raspberry Pi

## Risk Assessment
1. **Network Desync:** Mitigated by authoritative server
2. **Performance on RPi:** Mitigated by LOD system
3. **Balance Issues:** Mitigated by data-driven design
4. **Scope Creep:** Mitigated by YAGNI principle

## Progress Tracking
- **Completion:** 5% (Planning phase)
- **Next Actions:** Environment setup, prototype development
- **Blockers:** None currently
- **Last Updated:** 2025-11-01

## Important Notes
- NO mock data - all data must come from real services
- NO authentication bypasses in any environment
- Delete old code immediately when replacing
- Test with real data, real tokens, real permissions
- Follow clean code practices strictly

## References
- Game Design Docs: `/game-design/`
- Architecture Plans: `/docs/architecture/`
- API Documentation: `/docs/api/`
- Progress Reports: `/docs/progress/`

---
*This file serves as the project's memory and should be updated regularly with progress, decisions, and important information.*