# Battle Castles - AI Assistant Context

This file contains project-specific instructions and context for AI assistants working on Battle Castles.

## Critical Project Information

### Documentation Location
**ALL project documentation lives in `/docs/` at the project root**, not in `/client/` or other folders.

Key documentation files:
- **`/docs/BRANCHING.md`** - Git branching strategy (main → develop → feature/*)
- **`/docs/PROJECT_STRUCTURE.md`** - Complete project structure and file locations
- **`/docs/DEVELOPER_GUIDE.md`** - Development guidelines
- **`/docs/CONTRIBUTING.md`** - Contribution process

### Repository Structure

```
battle-castles/                  ← Project root
├── .claude/                     ← AI context (YOU ARE HERE)
│   └── CLAUDE.md               ← This file
├── docs/                        ← ALL DOCUMENTATION
│   ├── BRANCHING.md            ← Git workflow strategy
│   └── PROJECT_STRUCTURE.md    ← Project map
├── client/                      ← Godot 4 game (working directory)
│   ├── scripts/                ← GDScript code
│   ├── scenes/                 ← Godot scenes
│   ├── assets/                 ← Game assets
│   └── resources/              ← Godot resources
├── game-design/                 ← Design docs and planning
├── server/                      ← Backend server
└── deployment/                  ← Deployment configs
```

### Branching Strategy

Battle Castles uses Git Flow:

- **`main`** - Protected, stable builds only (no direct commits)
- **`develop`** - Integration branch for testing features
- **`feature/*`** - Feature branches (branch from develop)
- **`bugfix/*`** - Bug fix branches

**Always work on feature branches!** Never commit directly to main or develop.

**Current branch**: `feature/settings-page-fixes`

See `/docs/BRANCHING.md` for complete workflow.

### Working Directory

The primary working directory is `/client/` where the Godot game code lives.

However, when creating documentation, navigate to project root and put files in `/docs/`.

## Project Conventions

### File Naming
- Scripts: `snake_case.gd`
- Scenes: `snake_case.tscn`
- Resources: `snake_case.tres`
- Classes: `PascalCase`

### Commit Messages
Use Conventional Commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Tests
- `chore:` Maintenance

Always end with:
```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Code Standards
- Follow KISS, DRY, YAGNI, SOLID principles
- No authentication bypasses (even in dev)
- No mock data - use real backend APIs
- Delete legacy code immediately when replacing
- Test before committing

## Key File Locations

### Settings System
- Script: `/client/scripts/ui/settings_menu_ui.gd`
- Scene: `/client/scenes/ui/settings_menu.tscn`
- User data: `user://settings.cfg` (on user's machine)

### AI System
- AI Difficulty: `/client/scripts/ai/ai_difficulty.gd`
- Battle AI: `/client/scripts/battle/battlefield.gd` (AI logic section)

### Card System
- Card Script: `/client/scripts/resources/card_data.gd`
- Card Resources: `/client/resources/cards/*.tres`

### Unit Sprites
- Player Units: `/client/assets/sprites/units/*_player.png`
- Enemy Units: `/client/assets/sprites/units/*_enemy.png`

### Core Systems (Autoloads)
- GameManager: `/client/scripts/core/game_manager.gd`
- SceneManager: `/client/scripts/core/scene_manager.gd`
- AudioManager: `/client/scripts/core/audio_manager.gd`

## Workflow for AI Assistants

### Starting Work
1. Check current branch: `git branch`
2. If on main/develop, create feature branch: `git checkout -b feature/task-name`
3. Understand task requirements
4. Check relevant docs in `/docs/`

### During Work
1. Work in `/client/` directory for code
2. Create docs in `/docs/` directory
3. Commit frequently with clear messages
4. Test changes before committing
5. Use TodoWrite tool to track progress

### Completing Work
1. Test thoroughly
2. Commit all changes
3. Push feature branch
4. Create PR to `develop` (not main!)
5. Document any new features

### Common Mistakes to Avoid
- ❌ Putting docs in `/client/` instead of `/docs/`
- ❌ Committing directly to main
- ❌ Not testing before committing
- ❌ Forgetting to update documentation
- ❌ Creating mock data instead of using real APIs
- ❌ Leaving commented-out legacy code

## Current Project Status

### Active Development
- Branch: `feature/settings-page-fixes`
- Focus: Improving settings menu functionality
- Next: Settings page fixes and improvements

### Recent Changes
- Implemented AI difficulty selector in settings
- Fixed AI spawning variety (elixir reserve)
- Fixed battle timer not ending at 3 minutes
- Reduced excessive attack ranges for units/towers
- Established branching strategy and documentation

### Known Issues
- Settings page needs improvements (current task)

## Getting Help

If you need to understand the codebase:
1. Check `/docs/PROJECT_STRUCTURE.md` for file locations
2. Check `/docs/DEVELOPER_GUIDE.md` for development info
3. Check `/docs/BRANCHING.md` for Git workflow
4. Read relevant script files in `/client/scripts/`

## Notes

This file should be updated when:
- Project structure changes significantly
- New major systems are added
- Workflow or conventions change
- Important context needs to be preserved

**Last Updated**: November 3, 2025
**Maintained By**: Development Team with AI Assistance
