# Battle Castles

A real-time multiplayer strategy battle game inspired by Clash Royale, built with Godot Engine for PC, Mac, Linux, and Raspberry Pi 5.

## Game Overview

Battle Castles is a fast-paced 1v1 strategy game where players deploy medieval fantasy units to destroy their opponent's castle while defending their own. Matches last 3 minutes with an elixir-based resource system controlling the pace of unit deployment.

### Key Features
- **Real-time PvP battles** with deterministic simulation
- **Local network multiplayer** support (LAN play)
- **Single-player mode** with AI opponents
- **4 unique units** at launch (Knight, Goblin Squad, Archer Pair, Giant)
- **Cross-platform** support (PC, Mac, Linux, Raspberry Pi 5)
- **60 FPS** smooth gameplay

## Quick Start

### Prerequisites
- Godot 4.3+ (for development)
- Git and Git LFS
- Docker and Docker Compose (for backend services)
- Node.js 18+ LTS
- Go 1.21+
- Python 3.11+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/battle-castles.git
cd battle-castles
```

2. Install Git LFS and pull assets:
```bash
git lfs install
git lfs pull
```

3. Start backend services:
```bash
docker-compose up -d
```

4. Open the Godot project:
```bash
# Open Godot and import the project from client/project.godot
```

5. Run the game:
- Press F5 in Godot to run the project

## Project Structure

```
battle-castles/
├── client/          # Godot game client
├── server/          # Backend microservices
├── shared/          # Shared protocols and definitions
├── docs/            # Documentation
├── tests/           # Test suites
└── deployment/      # Deployment configurations
```

## Development

### Coding Standards
We follow strict coding principles:
- **SOLID** - Single Responsibility, Open/Closed, etc.
- **DRY** - Don't Repeat Yourself
- **KISS** - Keep It Simple, Stupid
- **YAGNI** - You Aren't Gonna Need It
- **Clean Code** - Readable, maintainable, testable

### Branch Strategy
- `main` - Production-ready code
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Critical production fixes

### Running Tests
```bash
# Client tests (Godot)
godot --headless --script res://tests/run_tests.gd

# Server tests
cd server/game-server && npm test
cd server/matchmaking && go test ./...
cd server/economy && pytest
```

## Deployment

### PC/Mac/Linux
```bash
# Build for target platform
godot --export "Windows Desktop" builds/battle_castles.exe
godot --export "Mac OSX" builds/battle_castles.app
godot --export "Linux/X11" builds/battle_castles
```

### Raspberry Pi 5
```bash
# Build ARM64 binary
godot --export "Linux ARM64" builds/battle_castles_arm64

# Create .deb package
./deployment/scripts/build_deb.sh
```

## Network Play

### Hosting a LAN Game
1. Start the game on host machine
2. Select "Host Game" from multiplayer menu
3. Share the room code with other players

### Joining a LAN Game
1. Select "Join Game" from multiplayer menu
2. Enter the host's room code or use auto-discovery
3. Ready up and wait for host to start

## Performance

| Platform | Target FPS | Resolution | Max Units |
|----------|------------|------------|-----------|
| PC High | 144 | 1920x1080+ | 100 |
| PC Mid | 60 | 1920x1080 | 80 |
| Mac M1+ | 120 | 2560x1440 | 100 |
| RPi 5 | 30-60 | 1920x1080 | 40 |

## Documentation

- [Architecture Overview](docs/architecture/README.md)
- [API Documentation](docs/api/README.md)
- [Development Guide](docs/guides/development.md)
- [Network Protocol](docs/architecture/network.md)
- [Game Design Document](game-design/)

## Contributing

Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Development Team
- Technical Lead
- Client Engineers (2)
- Backend Engineers (2)
- Game Designer
- UI/UX Designer
- 2D Artists (2)
- QA Engineer
- Producer

## Roadmap

### Current Phase: Pre-Production
- [x] Game design documentation
- [x] Technology stack selection
- [ ] Prototype development
- [ ] Team assembly

### Upcoming Milestones
- **Month 3:** Vertical Slice Demo
- **Month 5:** Alpha Build
- **Month 7:** Beta Testing
- **Month 9:** Launch

## License

This project is proprietary software. All rights reserved.

## Support

For bug reports and feature requests, please use the [issue tracker](https://github.com/yourusername/battle-castles/issues).

## Acknowledgments

- Inspired by Supercell's Clash Royale
- Built with Godot Engine
- Community feedback and testing

---

**Project Status:** 🚧 Under Development
**Last Updated:** November 1, 2025