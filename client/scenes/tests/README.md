# Test Scenes

This directory contains test and development scenes that are used for testing specific features and systems during development.

## Purpose

Test scenes in this directory are:
- **Development-only**: Used for testing and debugging specific features
- **Not for production**: Excluded from game builds via export_presets.cfg
- **Isolated testing**: Each scene tests a specific system or feature

## Current Test Scenes

### 1. audio_test.tscn
Tests the audio system including:
- Background music playback
- Sound effect triggers
- Volume controls
- Audio bus management

### 2. network_test_ui.tscn
Tests the networking system including:
- WebSocket connection to game server
- Matchmaking queue functionality
- Command buffer and synchronization
- Connection state management

See: `/client/scripts/network/README.md` for usage instructions

### 3. progression_test.tscn
Tests the progression systems including:
- Player profile creation and management
- Card collection and upgrades
- Deck management
- Currency system (gold/gems)
- Chest system
- Trophy calculations
- Achievement tracking

See: `/client/scripts/progression/README.md` for usage instructions

## Running Test Scenes

To run a test scene:
1. Open Godot Editor
2. Navigate to `res://scenes/tests/`
3. Double-click the test scene you want to run
4. Press F5 or click "Run Current Scene"

**Note**: Some test scenes may require backend services (like network_test_ui.tscn requires the game server running).

## Build Exclusion

All files in this directory are automatically excluded from production builds via the `export_presets.cfg` configuration:

```
exclude_filter="*.md, res://scenes/tests/*, res://.git/*, res://addons/gd-plug/*"
```

This ensures test scenes are never included in:
- Windows builds
- Linux builds
- macOS builds
- Any other platform exports

## Adding New Test Scenes

When creating new test scenes:
1. Place them in this directory (`/client/scenes/tests/`)
2. Name them with a `_test.tscn` suffix for clarity
3. Document their purpose in this README
4. Include usage instructions if the test requires setup
5. Ensure they don't have dependencies on production code that would break without the test

## Best Practices

- **Isolated**: Test scenes should be self-contained
- **Documented**: Add descriptions of what each scene tests
- **Minimal**: Keep test scenes simple and focused
- **Clean**: Don't leave test scenes with hardcoded paths or temporary data
- **Independent**: Test scenes shouldn't depend on each other

## Directory Structure

```
scenes/tests/
├── README.md              # This file
├── audio_test.tscn       # Audio system testing
├── network_test_ui.tscn  # Networking system testing
└── progression_test.tscn # Progression system testing
```

---

**Last Updated**: November 4, 2025
**Maintained By**: Development Team
