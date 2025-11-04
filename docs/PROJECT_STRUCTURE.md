# Battle Castles - Project Structure

**Last Updated**: November 3, 2025

This document outlines the organization of the Battle Castles project repository.

## Repository Root

```
battle-castles/
├── .github/          # GitHub-specific files (workflows, templates)
├── builds/           # Build outputs and artifacts
├── client/           # Godot 4 game client
├── deployment/       # Deployment configurations and scripts
├── docs/             # 📚 ALL PROJECT DOCUMENTATION (YOU ARE HERE)
├── game-design/      # Game design documents and planning
├── server/           # Backend server code (if applicable)
├── shared/           # Shared resources between client/server
└── tests/            # Test suites
```

## Documentation (`/docs/`)

**Important**: All project documentation lives in `/docs/`, not in individual folders.

### Key Documentation Files

#### Development & Workflow
- **`BRANCHING.md`** - Git branching strategy and workflow (main, develop, feature/*)
- **`DEVELOPER_GUIDE.md`** - Comprehensive development guide
- **`CONTRIBUTING.md`** - Contribution guidelines
- **`BUILD_PLAN.md`** - Project build and development plan

#### Installation & Setup
- **`QUICKSTART.md`** - Quick setup guide
- **`INSTALL_MAC.md`** - macOS installation
- **`INSTALL_WINDOWS.md`** - Windows installation
- **`INSTALL_LINUX.md`** - Linux installation
- **`INSTALL_RASPBERRY_PI.md`** - Raspberry Pi installation

#### Integration & Deployment
- **`INTEGRATION_GUIDE.md`** - Integration instructions
- **`DEPLOYMENT.md`** - Deployment procedures
- **`PLATFORM_BUILD_GUIDE.md`** - Cross-platform build guide

#### Reference
- **`API_DOCUMENTATION.md`** - API documentation
- **`USER_MANUAL.md`** - User manual
- **`PROJECT_COMPLETION_REPORT.md`** - Project status report

#### AI Development (For AI Assistants)
- **`AI_DEVELOPMENT_CHECKLIST.md`** - Development tasks checklist
- **`AI_PROMPT_PLAYBOOK.md`** - Guidelines for AI assistance
- **`AI_BUILD_COMPLETE.md`** - Build completion status

#### Checklists
- **`MASTER_CHECKLIST.md`** - Master project checklist
- **`EXECUTIVE_CHECKLIST.md`** - Executive summary checklist

### Documentation Subdirectories
- **`docs/api/`** - API-specific documentation
- **`docs/architecture/`** - Architecture diagrams and documents
- **`docs/guides/`** - Detailed guides and tutorials
- **`docs/progress/`** - Progress tracking documents

## Client Structure (`/client/`)

The Godot 4 game client:

```
client/
├── assets/           # Game assets (sprites, sounds, etc.)
│   ├── sprites/
│   │   ├── units/   # Unit sprites (player & enemy versions)
│   │   └── icons/   # UI icons and card images
│   ├── audio/
│   └── ...
├── scenes/          # Godot scene files (.tscn)
│   ├── battle/      # Battle-related scenes
│   ├── ui/          # UI scenes
│   └── main_menu.tscn
├── scripts/         # GDScript code
│   ├── ai/          # AI system scripts
│   ├── battle/      # Battle logic (battlefield, units, towers)
│   ├── cards/       # Card system
│   ├── core/        # Core systems (managers, autoloads)
│   ├── network/     # Networking code
│   ├── progression/ # Player progression systems
│   ├── resources/   # Resource scripts (CardData, etc.)
│   ├── ui/          # UI controllers
│   └── vfx/         # Visual effects
├── resources/       # Godot resource files (.tres)
│   └── cards/       # Card data files
├── tests/           # Unit tests
│   └── unit/
├── addons/          # Godot plugins/addons
└── project.godot    # Godot project file
```

## Game Design (`/game-design/`)

Game design documents and planning materials:

```
game-design/
├── cards/                    # Card design documents
├── mechanics/                # Game mechanics documentation
├── balance/                  # Balance spreadsheets and data
├── issue_fixes_plan.md       # Current issues and fixes
└── new_unit_sprites_prompts.md  # AI prompts for generating sprites
```

## Deployment (`/deployment/`)

Deployment configurations:

```
deployment/
├── docker/          # Docker configurations
├── kubernetes/      # Kubernetes manifests
└── scripts/         # Deployment scripts
```

## Important File Locations

### Branching & Git Workflow
- **Location**: `/docs/BRANCHING.md`
- **Purpose**: Defines Git workflow (main → develop → feature/*)

### Game Configuration
- **Godot Project**: `/client/project.godot`
- **Autoload Scripts**: `/client/scripts/core/` (GameManager, SceneManager, etc.)

### Card Definitions
- **Card Scripts**: `/client/scripts/resources/card_data.gd`
- **Card Resources**: `/client/resources/cards/*.tres`

### Unit Sprites
- **Player Units**: `/client/assets/sprites/units/*_player.png`
- **Enemy Units**: `/client/assets/sprites/units/*_enemy.png`

### Settings System
- **Settings UI Script**: `/client/scripts/ui/settings_menu_ui.gd`
- **Settings Scene**: `/client/scenes/ui/settings_menu.tscn`
- **User Settings File**: `user://settings.cfg` (on user's machine)

### AI System
- **AI Difficulty**: `/client/scripts/ai/ai_difficulty.gd`
- **AI in Battle**: `/client/scripts/battle/battlefield.gd` (AI logic section)

## Project Conventions

### File Naming
- **Scripts**: `snake_case.gd` (e.g., `settings_menu_ui.gd`)
- **Scenes**: `snake_case.tscn` (e.g., `settings_menu.tscn`)
- **Resources**: `snake_case.tres` (e.g., `archer.tres`)
- **Classes**: `PascalCase` (e.g., `SettingsMenuUI`, `CardData`)

### Branch Naming
- Feature: `feature/feature-name`
- Bugfix: `bugfix/bug-description`
- Hotfix: `hotfix/critical-issue`

### Commit Messages
Follow Conventional Commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Tests
- `chore:` Maintenance

## Quick Reference

| Need to find...              | Look in...                        |
|------------------------------|-----------------------------------|
| Branching strategy           | `/docs/BRANCHING.md`              |
| Development guide            | `/docs/DEVELOPER_GUIDE.md`        |
| How to contribute            | `/docs/CONTRIBUTING.md`           |
| Game scripts                 | `/client/scripts/`                |
| Card data                    | `/client/resources/cards/`        |
| UI scenes                    | `/client/scenes/ui/`              |
| Unit sprites                 | `/client/assets/sprites/units/`   |
| Settings system              | `/client/scripts/ui/settings_*`   |
| AI system                    | `/client/scripts/ai/`             |
| Game design docs             | `/game-design/`                   |

## Notes for AI Assistants

When working on this project:

1. **Documentation goes in `/docs/`** - Not in `/client/` or other folders
2. **Check `/docs/BRANCHING.md`** for Git workflow before committing
3. **Use `/game-design/`** for design discussions and planning
4. **Follow naming conventions** listed above
5. **Test on feature branches** before merging to develop
6. **Update this file** if project structure changes significantly

---

**Maintained by**: Development Team
**Repository**: https://github.com/sethshoultes/battle-castles
