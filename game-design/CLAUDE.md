# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Battle Castles is a real-time multiplayer strategy battle game inspired by Clash Royale. Players deploy medieval fantasy units in 3-minute 1v1 battles to destroy their opponent's castle.

**Current Status:** Documentation phase - no code implementation yet
**Target Platforms:** iOS, Android (primary), PC (secondary)
**Development Timeline:** 9 months (pre-production to launch)

## Documentation Structure

This repository contains comprehensive game design documentation (267 pages total):

- `battle_game_gdd.md` - Core game design, mechanics, modes, monetization
- `unit_specifications.md` - Unit stats, balancing, progression (levels 1-9)
- `economy_progression.md` - Currency systems, chests, progression loops
- `uiux_design.md` - Screen layouts, interaction patterns, visual design
- `technical_specifications.md` - System architecture, tech stack, infrastructure
- `project_roadmap.md` - Development phases, team structure, budget

**Always reference these documents when implementing features** - they contain the authoritative specifications.

## Technology Stack (Planned)

### Client
- **Engine:** Unity 2022.3 LTS (C#)
- **Networking:** Unity Netcode for GameObjects + WebSocket (Socket.io)
- **Libraries:** DOTween (animations), TextMeshPro (UI), Unity IAP, Firebase SDK

### Server
- **Game Server:** Node.js + Express (real-time battle logic)
- **Matchmaking:** Go/Golang (high-performance matching algorithms)
- **Authentication:** Node.js + Passport.js (JWT tokens)
- **Economy Service:** Python + FastAPI (data processing, fraud detection)
- **Analytics:** Python + Apache Spark

### Infrastructure
- **Primary DB:** PostgreSQL 14 (player data, match results)
- **Cache:** Redis 7 (sessions, matchmaking queues, leaderboards)
- **Logging:** MongoDB (events, player behavior)
- **Event Stream:** Apache Kafka (real-time event processing)
- **Storage:** AWS S3 / Cloudflare R2 (replays, assets)
- **CDN:** Cloudflare
- **Load Balancer:** NGINX

## Core Game Mechanics

### Battle System
- **Match Duration:** 3 minutes
- **Elixir System:** 0-10 capacity, regenerates 1 per 2.8 seconds
- **Double Elixir:** Last 60 seconds = 2x generation rate
- **Victory Conditions:** Destroy King's Castle OR most tower damage when timer expires

### Launch Units (4 core units)
1. **Knight** - Melee tank (4 elixir)
2. **Goblin Squad** - Fast swarm (3 elixir, deploys 3 units)
3. **Archer Pair** - Ranged support (3 elixir, deploys 2 units)
4. **Giant** - Heavy tank (5 elixir)

### Progression
- **Card Levels:** 1-9 (see unit_specifications.md for level curves)
- **Arenas:** 10 tiers (0-4000+ trophies)
- **Player Levels:** 1-50

## Architecture Guidelines

### Client-Server Synchronization
- **Authoritative Server:** All combat calculations run server-side to prevent cheating
- **Client Prediction:** Local simulation for immediate feedback, server validates
- **Deterministic Simulation:** Same inputs = same outputs (critical for anti-cheat)
- **Tick Rate:** 20 ticks/second server, 60 FPS client
- **Latency Tolerance:** Designed for <100ms, must handle up to 150ms

### Performance Targets
- **Mobile:** 60 FPS (target), 45 FPS (acceptable)
- **PC:** 144 FPS (target), 60 FPS (acceptable)
- **Match Start:** <15s (target), <30s (acceptable)
- **Network Latency:** <50ms (target), <100ms (acceptable)

### Microservices Architecture
When implementing backend services, maintain strict separation:
- **Game Server** (Node.js port 8002): Battle logic, real-time sync
- **Matchmaking** (Go port 8003): Queue management, ELO matching
- **Auth** (Node.js port 8004): JWT tokens, social OAuth
- **Economy** (Python port 8005): Card upgrades, purchases, rewards
- **Analytics** (Python port 8006): Events, metrics, dashboards
- **API Gateway** (port 8001): Unified entry point, rate limiting

Each service should be independently deployable and communicate via REST/WebSocket.

## Development Workflow

### Phase 0: Pre-Production (Weeks 1-4)
- Build working prototype with 2 basic units
- Implement movement and combat systems
- Basic networking (local multiplayer)
- Set up CI/CD pipeline

### Phase 1: Vertical Slice (Weeks 5-12)
- One complete polished battle experience
- All 4 core units implemented
- Basic progression loop (matches → rewards → upgrades)
- Online matchmaking functional

### Testing Requirements
- **Unity Test Framework** for client logic
- **Integration tests** for server APIs
- **Load testing** for matchmaking (must handle 10,000 concurrent battles)
- **Security testing** for anti-cheat validation
- **Playtesting** at each milestone (see project_roadmap.md for schedule)

## Security & Anti-Cheat

**Critical:** All game-critical calculations MUST run server-side
- Never trust client input for damage, elixir costs, unit stats
- Validate all unit placements (within deployment zone, sufficient elixir)
- Detect impossible actions (timing violations, speed hacks)
- Log suspicious behavior to MongoDB for analysis

## Monetization Implementation

**F2P Friendly Philosophy:**
- No pay-to-win mechanics
- All content unlockable through gameplay
- Monetization via Battle Pass ($5), cosmetics, time-savers

**Conversion Targets:**
- 5-8% paying users
- $1.50-2.50 ARPU per month

See `economy_progression.md` for detailed pricing, reward curves, and chest systems.

## File Organization (When Code Exists)

Expected structure for Unity client:
```
Assets/
├── Scripts/
│   ├── Battle/          # Combat, elixir, tower logic
│   ├── Units/           # Unit behaviors, stats
│   ├── UI/              # Menus, HUD, animations
│   ├── Networking/      # Client-side netcode
│   └── Managers/        # Game state, scene management
├── Prefabs/
├── Scenes/
└── Resources/
```

Expected structure for backend services:
```
server/
├── game-server/         # Node.js battle logic
├── matchmaking/         # Go matching service
├── auth-service/        # Node.js authentication
├── economy-service/     # Python rewards/upgrades
├── analytics/           # Python data processing
└── shared/              # Shared types, utilities
```

## Key Design Principles

1. **3-Minute Matches** - All features must support quick session play
2. **Skill-Based Gameplay** - Higher level cards give advantage, but skill matters most
3. **Strategic Depth** - Simple mechanics, complex interactions (unit counters, placement, timing)
4. **Fair Matchmaking** - Trophy-based ELO, never match new players with veterans
5. **Respectful Monetization** - Never lock competitive advantage behind paywall

## Reference the Specs

Before implementing ANY feature:
1. Check relevant .md file for specifications
2. Verify against technical_specifications.md for architecture
3. Cross-reference unit_specifications.md for balancing values
4. Consult uiux_design.md for UI patterns

**All stat values, formulas, and progression curves are defined in the documentation - do not make up numbers.**
