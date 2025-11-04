# Changelog

All notable changes to Battle Castles will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned Features
- Online multiplayer with matchmaking
- Additional units (Wizard, Dragon, Archer Tower)
- More arenas (Desert, Ice, Volcanic)
- Progression system (player levels, card upgrades)
- Replay system
- Tournament mode

---

## [0.1.0] - 2025-11-01

### Initial Release - LAN Multiplayer MVP

This is the first public release of Battle Castles, featuring local network multiplayer and AI opponents.

### Added

#### Core Gameplay
- **3-minute real-time battles** - Fast-paced 1v1 matches with double elixir in final minute
- **Elixir system** - Resource management with 10 max capacity, regenerating at 1 per 2.8 seconds
- **4 playable units:**
  - Knight (3 elixir) - Versatile melee tank
  - Goblin Squad (2 elixir) - Fast swarm unit (deploys 3 goblins)
  - Archer Pair (3 elixir) - Ranged support (deploys 2 archers)
  - Giant (5 elixir) - Heavy tank, targets buildings only
- **Tower defense mechanics** - Destroy opponent's King's Castle to win instantly
- **Victory conditions:**
  - Destroy King's Castle (instant win)
  - Most towers destroyed when time expires
  - Most damage dealt (tiebreaker)

#### Game Modes
- **Practice vs AI** - Three difficulty levels (Beginner, Intermediate, Expert)
- **LAN Multiplayer** - Local network play with room codes
- **Deck Builder** - Customize your 8-card deck

#### Technical Features
- **Entity-Component-System architecture** - Modular, maintainable codebase
- **Command pattern networking** - Deterministic, server-authoritative gameplay
- **Real-time state synchronization** - 20 ticks per second for smooth gameplay
- **WebSocket communication** - Low-latency multiplayer via Socket.IO
- **Client-side prediction** - Responsive controls with server validation

#### Platform Support
- **Windows** (64-bit) - Tested on Windows 10/11
- **macOS** (Intel & Apple Silicon) - Tested on macOS 12+
- **Linux** (x86_64) - Tested on Ubuntu 20.04+
- **Raspberry Pi 5** (ARM64) - Optimized for 4GB and 16GB models
  - 30-60 FPS at 1080p
  - .deb package installer
  - Kiosk mode support for dedicated stations

#### User Interface
- **Main Menu** - Clean navigation to all game modes
- **Battle UI** - Real-time elixir display, unit cards, timer
- **Deck Builder** - Visual card selection and deck management
- **Results Screen** - Victory/defeat display with match statistics
- **Settings Menu** - Graphics, audio, and control customization
  - Resolution settings (720p, 1080p, 1440p, 2160p)
  - Fullscreen/windowed mode
  - Graphics quality presets (Low, Medium, High, Ultra)
  - Audio volume controls (Master, Music, SFX)
  - VSync toggle

#### Graphics & Effects
- **Visual effects:**
  - Deploy animations with particle effects
  - Attack impact effects
  - Explosion effects for unit deaths
  - Arrow trails for ranged attacks
  - Victory confetti
- **Animations:**
  - Unit idle, walk, attack, and death animations
  - Tower attack animations
  - Smooth unit movement with pathfinding

#### Audio
- **Sound effects:**
  - Unit deployment sounds
  - Attack impact sounds
  - Building destruction
  - UI click/hover sounds
  - Victory/defeat fanfares
- **Music:**
  - Menu background music
  - Battle music (increases intensity in double elixir)
  - Victory/defeat themes

#### AI System
- **Behavior tree AI** - Smart opponent decision-making
- **Difficulty scaling:**
  - Beginner: Slow reactions, basic strategies
  - Intermediate: Balanced gameplay, counters player moves
  - Expert: Quick reactions, advanced tactics, elixir management
- **Strategic behaviors:**
  - Emergency defense when towers threatened
  - Elixir advantage exploitation
  - Lane selection based on defenses
  - Counter-unit deployment

#### Developer Tools
- **Debug overlay** - FPS counter, unit count, elixir display (F3)
- **Developer console** - Command execution for testing (backtick key)
- **Comprehensive logging** - Error tracking and debugging
- **Hot reload support** - Fast iteration during development

#### Documentation
- **User Manual** - Complete gameplay guide with controls and strategies
- **Developer Guide** - Architecture overview and extension guides
- **API Documentation** - WebSocket protocol and message formats
- **Deployment Guide** - Server setup and platform-specific instructions
- **Contributing Guide** - Code style, PR process, testing requirements

#### Testing
- **Unit tests** - Core systems (elixir, combat, state management)
- **Integration tests** - Multiplayer flow, matchmaking
- **GUT framework** - Godot Unit Test for client testing
- **Jest framework** - TypeScript/Node.js server testing

#### Infrastructure
- **Docker support** - Containerized deployment
- **Docker Compose** - Easy local development setup
- **systemd service** - Linux server deployment
- **Health check endpoints** - Monitoring server status
- **Log rotation** - Automatic log management

### Technical Specifications

#### Performance Targets
- **PC (High-End):** 144 FPS @ 1920x1080+
- **PC/Mac (Mid-Range):** 60 FPS @ 1920x1080
- **Raspberry Pi 5 (16GB):** 60 FPS @ 1920x1080
- **Raspberry Pi 5 (4GB):** 30 FPS @ 1280x720

#### Network Requirements
- **Latency:** <100ms (LAN), <150ms acceptable
- **Bandwidth:** ~50KB/s per player
- **Update Rate:** 20 ticks/second (50ms)

#### Stack
- **Client:** Godot 4.3, GDScript
- **Server:** Node.js 18, TypeScript, Express, Socket.IO
- **Protocols:** WebSocket (Socket.IO), HTTP REST

### Known Issues

#### Gameplay
- Goblin Squad pathfinding occasionally gets stuck on obstacles (workaround: redeploy)
- Tower retargeting can be delayed by 1 tick (~50ms) when multiple units enter range simultaneously
- Giant may briefly attack ground units if they're directly in path to building

#### Performance
- Frame drops on Raspberry Pi 4GB when >30 units on screen (limitation: use quality settings)
- Memory usage increases slowly during extended play sessions (10+ matches) - restart recommended

#### Multiplayer
- Connection timeout if server takes >15s to respond (check network)
- Rare desync when player disconnects during unit deployment (server handles gracefully)
- Room codes are case-sensitive (UX improvement planned)

#### UI
- Deck builder card tooltip overlaps edge of screen at 720p resolution
- Settings menu does not save custom keybindings (feature planned for 0.2.0)

#### Platform-Specific
- **macOS:** First launch requires "Open" from right-click menu (Gatekeeper security)
- **Linux:** Wayland users may experience input lag (X11 recommended)
- **Raspberry Pi:** GPU driver must be updated to latest for optimal performance

### Fixed Issues (During Development)

- Fixed elixir regeneration rate being 10% too slow
- Fixed Giant ignoring King's Castle when Princess Towers still alive
- Fixed Archer attack animation not syncing with damage application
- Fixed memory leak in projectile pooling system
- Fixed server crash when player disconnects during matchmaking
- Fixed WebSocket reconnection failing after network interruption
- Fixed collision layers causing friendly fire between units

### Security

- **Server-authoritative validation** - All game commands validated server-side
- **Anti-cheat measures:**
  - Elixir spending validated
  - Unit placement zones enforced
  - Command timestamps checked for impossible actions
  - Rate limiting on deployments (20/second max)
- **No client trust** - All critical calculations on server
- **Input sanitization** - Player names and commands validated

### Breaking Changes

None (initial release)

---

## Version History Summary

| Version | Release Date | Key Features | Status |
|---------|--------------|--------------|--------|
| 0.1.0   | 2025-11-01   | LAN multiplayer, 4 units, AI opponents | Released |
| 0.2.0   | TBD          | Online play, progression, 2 new units | Planned |
| 0.3.0   | TBD          | Clans, tournaments, 5 new arenas | Planned |
| 1.0.0   | TBD          | Feature-complete, mobile support | Planned |

---

## Upgrade Notes

### From Development to 0.1.0

No upgrade path (initial release).

### Future Upgrades

Upgrade instructions will be provided with each release.

---

## Credits

### Development Team
- **AI Development** - Claude (Anthropic) assisted in architecture and implementation
- **Game Design** - Based on Clash Royale-inspired mechanics
- **Engine** - Godot Engine 4.3
- **Assets** - [Attribution will be added for final assets]

### Special Thanks
- Godot community for engine support
- Socket.IO team for real-time networking
- Open source contributors

---

## Links

- **GitHub Repository:** https://github.com/yourusername/battle-castles
- **Documentation:** https://docs.battlecastles.game
- **Issue Tracker:** https://github.com/yourusername/battle-castles/issues
- **Discord Community:** https://discord.gg/battlecastles
- **Website:** https://battlecastles.game

---

## Versioning Policy

Battle Castles follows [Semantic Versioning](https://semver.org/):

- **MAJOR version** (1.0.0 → 2.0.0) - Incompatible API changes or major gameplay overhauls
- **MINOR version** (0.1.0 → 0.2.0) - New features, backward-compatible
- **PATCH version** (0.1.0 → 0.1.1) - Bug fixes, backward-compatible

### Pre-1.0 Releases

Versions before 1.0.0 are considered beta quality:
- **0.x.0** releases may introduce breaking changes
- **0.x.y** patches are always backward-compatible
- Save data compatibility is not guaranteed until 1.0.0

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to Battle Castles.

---

**Current Version:** 0.1.0
**Last Updated:** November 1, 2025
**Status:** Initial Release - LAN Ready
