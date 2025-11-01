# Contributing to Battle Castles

Thank you for your interest in contributing to Battle Castles! This document provides guidelines and instructions for contributing to the project.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Code Style Guidelines](#code-style-guidelines)
5. [Pull Request Process](#pull-request-process)
6. [Testing Requirements](#testing-requirements)
7. [Bug Reporting](#bug-reporting)
8. [Feature Requests](#feature-requests)
9. [Community](#community)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of experience level, gender, gender identity, sexual orientation, disability, personal appearance, race, ethnicity, age, religion, or nationality.

### Expected Behavior

- Be respectful and considerate
- Welcome newcomers and help them get started
- Provide constructive feedback
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling or deliberately derailing discussions
- Publishing others' private information
- Any conduct that would be inappropriate in a professional setting

### Reporting

If you experience or witness unacceptable behavior, please report it to conduct@battlecastles.game.

---

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Development Environment**
   - Godot 4.3+ (for client development)
   - Node.js 18 LTS (for server development)
   - Git and Git LFS
   - Docker and Docker Compose (optional)

2. **Accounts**
   - GitHub account
   - Discord account (for community chat)

3. **Knowledge**
   - Familiarity with GDScript (for client) or TypeScript (for server)
   - Understanding of real-time multiplayer concepts
   - Git workflow basics

### Setting Up Your Development Environment

1. **Fork the Repository**

   Click the "Fork" button on GitHub to create your own copy.

2. **Clone Your Fork**

   ```bash
   git clone https://github.com/YOUR_USERNAME/battle-castles.git
   cd battle-castles
   ```

3. **Add Upstream Remote**

   ```bash
   git remote add upstream https://github.com/battle-castles/battle-castles.git
   ```

4. **Install Git LFS**

   ```bash
   git lfs install
   git lfs pull
   ```

5. **Install Dependencies**

   ```bash
   # Server dependencies
   cd server/game-server
   npm install
   cd ../..

   # Client: Open in Godot
   godot client/project.godot
   ```

6. **Run Tests**

   ```bash
   # Server tests
   cd server/game-server
   npm test

   # Client tests (in Godot)
   godot --headless --script client/tests/run_tests.gd
   ```

---

## Development Workflow

### Branch Strategy

We use **GitHub Flow** - a simple, branch-based workflow:

1. `main` branch is always deployable
2. Create descriptive feature branches
3. Open pull requests early for feedback
4. Merge to `main` after review

### Creating a Branch

```bash
# Update main
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

**Branch Naming Convention:**

- `feature/` - New features (e.g., `feature/add-wizard-unit`)
- `fix/` - Bug fixes (e.g., `fix/elixir-regen-timing`)
- `docs/` - Documentation (e.g., `docs/update-api-docs`)
- `refactor/` - Code refactoring (e.g., `refactor/ecs-system`)
- `test/` - Test additions/fixes (e.g., `test/unit-ai-behavior`)

### Making Changes

1. **Make your changes**

   Follow our [Code Style Guidelines](#code-style-guidelines).

2. **Commit regularly**

   ```bash
   git add .
   git commit -m "Add wizard unit with splash damage"
   ```

3. **Write good commit messages**

   ```
   Add wizard unit with splash damage

   - Implement WizardProjectile class with area damage
   - Add wizard sprite animations (idle, walk, cast, death)
   - Create wizard stats matching design doc
   - Add unit tests for splash damage behavior

   Resolves #123
   ```

### Staying Up-to-Date

```bash
# Fetch upstream changes
git fetch upstream

# Rebase your branch
git rebase upstream/main

# Force push (if needed)
git push --force-with-lease origin feature/your-feature
```

---

## Code Style Guidelines

### General Principles

We follow these core principles (see `CLAUDE.md` for details):

- **SOLID** - Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **DRY** - Don't Repeat Yourself
- **KISS** - Keep It Simple, Stupid
- **YAGNI** - You Aren't Gonna Need It
- **Clean Code** - Readable, maintainable, testable

### GDScript Style (Client)

**Formatting:**

```gdscript
# Use tabs for indentation (Godot standard)
# Class names: PascalCase
# Functions: snake_case
# Variables: snake_case
# Constants: SCREAMING_SNAKE_CASE

class_name MyUnitClass
extends BaseUnit

## Documentation comments use double ##
## Describe what the class/function does

const MAX_HEALTH: int = 1000
const ATTACK_RANGE: float = 5.0

var current_target: Entity = null
var _private_variable: int = 0  # Leading underscore for private


## Brief description of what this function does
## @param target - The entity to attack
## @return true if attack was successful
func attack_target(target: Entity) -> bool:
	if not target or not target.is_alive():
		return false

	# Clear, descriptive variable names
	var damage_amount: int = stats_component.damage
	var health = target.get_component("HealthComponent")

	if health:
		health.take_damage(damage_amount, self)
		return true

	return false


## Private functions use leading underscore
func _calculate_distance_to_target() -> float:
	if not current_target:
		return INF

	return global_position.distance_to(current_target.global_position)
```

**Best Practices:**

- Use type hints everywhere: `var health: int = 100`
- Prefer composition over inheritance
- Keep functions short (<50 lines)
- One responsibility per function
- Avoid nested conditionals (max 3 levels deep)

### TypeScript Style (Server)

**Formatting:**

```typescript
// Use 2 spaces for indentation
// Classes/Interfaces: PascalCase
// Functions/Variables: camelCase
// Constants: SCREAMING_SNAKE_CASE

/**
 * Documentation comments use JSDoc format
 * Describe the class/function purpose
 */
export class GameRoom {
  private readonly roomId: string;
  private players: Map<string, Player>;
  private gameState: GameState;

  constructor(roomId: string) {
    this.roomId = roomId;
    this.players = new Map();
    this.gameState = this.initializeGameState();
  }

  /**
   * Add a player to the room
   * @param socket - Socket.IO socket instance
   * @param playerName - Display name of the player
   * @returns The created player object
   */
  public addPlayer(socket: Socket, playerName: string): Player {
    const player: Player = {
      id: uuid(),
      socketId: socket.id,
      name: playerName,
      team: this.assignTeam(),
      elixir: INITIAL_ELIXIR,
      maxElixir: MAX_ELIXIR,
      elixirRegenRate: BASE_ELIXIR_REGEN,
      lastElixirUpdate: Date.now(),
      isConnected: true,
      crowns: 0
    };

    this.players.set(player.id, player);
    return player;
  }

  private assignTeam(): TeamSide {
    // Assign to team with fewer players
    const leftCount = Array.from(this.players.values())
      .filter(p => p.team === TeamSide.LEFT).length;

    return leftCount === 0 ? TeamSide.LEFT : TeamSide.RIGHT;
  }
}
```

**Best Practices:**

- Use `const` by default, `let` when needed, never `var`
- Prefer `async/await` over callbacks
- Use interfaces for type definitions
- Avoid `any` type - use proper typing
- Extract magic numbers to named constants

### Linting

**GDScript:**

We use Godot's built-in warnings. Enable all warnings in Project Settings:

```
Project > Project Settings > GDScript
✓ Enable all warnings
✓ Treat warnings as errors (optional, but recommended)
```

**TypeScript:**

```bash
# Run ESLint
npm run lint

# Auto-fix issues
npm run lint -- --fix
```

ESLint configuration (`.eslintrc.json`):

```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "rules": {
    "semi": ["error", "always"],
    "quotes": ["error", "single"],
    "no-console": "warn",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "@typescript-eslint/no-unused-vars": "error"
  }
}
```

---

## Pull Request Process

### Before Submitting

1. **Test your changes**
   - All tests pass
   - No new warnings or errors
   - Manual testing completed

2. **Update documentation**
   - Code comments
   - README if needed
   - API docs if changed

3. **Rebase on latest main**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

4. **Run linters**
   ```bash
   npm run lint    # Server
   # Check Godot warnings in editor
   ```

### Creating a Pull Request

1. **Push your branch**

   ```bash
   git push origin feature/your-feature
   ```

2. **Open PR on GitHub**

   - Go to https://github.com/battle-castles/battle-castles
   - Click "New Pull Request"
   - Select your fork and branch

3. **Fill out PR template**

   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   - [ ] All tests pass
   - [ ] Added new tests
   - [ ] Manual testing completed

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added to complex code
   - [ ] Documentation updated
   - [ ] No new warnings

   ## Screenshots (if applicable)
   Add screenshots for UI changes

   ## Related Issues
   Closes #123
   ```

### Review Process

1. **Automated checks run**
   - CI/CD pipeline runs tests
   - Linters check code style
   - Build verification

2. **Code review**
   - At least 1 approval required
   - Maintainers review code
   - Feedback provided

3. **Address feedback**
   - Make requested changes
   - Push updates to same branch
   - Respond to comments

4. **Merge**
   - Maintainer merges PR
   - Branch can be deleted

### PR Guidelines

**Good PR:**
- Small, focused changes
- Clear description
- Tests included
- Documentation updated
- Passing CI/CD

**Avoid:**
- Massive PRs (>500 lines changed)
- Multiple unrelated changes
- Missing tests
- Breaking existing functionality
- Merge conflicts

---

## Testing Requirements

### Client Tests (GDScript)

Use **GUT** (Godot Unit Test) framework:

```gdscript
# tests/unit/test_elixir_manager.gd
extends GutTest

var elixir_manager: ElixirManager

func before_each():
	elixir_manager = ElixirManager.new()
	add_child_autofree(elixir_manager)
	elixir_manager.start_regeneration()

func test_elixir_regenerates_over_time():
	var initial = elixir_manager.get_elixir(0)
	await wait_seconds(3.0)
	var after = elixir_manager.get_elixir(0)

	assert_gt(after, initial, "Elixir should increase over time")

func test_cannot_exceed_max_elixir():
	elixir_manager.set_elixir(0, 10.0)
	await wait_seconds(5.0)
	var final = elixir_manager.get_elixir(0)

	assert_eq(final, 10.0, "Elixir should not exceed maximum")
```

Run tests:
```bash
godot --headless --script res://tests/run_tests.gd
```

### Server Tests (Jest)

```typescript
// tests/unit/CommandValidator.test.ts
import { CommandValidator } from '../src/CommandValidator';
import { DeployUnitCommand, UnitType } from '../src/types';

describe('CommandValidator', () => {
  describe('validateDeployUnit', () => {
    it('should reject deployment with insufficient elixir', () => {
      const command: DeployUnitCommand = {
        type: 'deploy_unit',
        unitType: UnitType.GIANT,
        position: { x: 500, y: 600 },
        timestamp: Date.now()
      };

      const player = createMockPlayer({ elixir: 2 });
      const gameState = createMockGameState();

      const result = CommandValidator.validateDeployUnit(
        command,
        player,
        gameState
      );

      expect(result.valid).toBe(false);
      expect(result.error).toBe('Insufficient elixir');
    });

    it('should accept valid deployment command', () => {
      const command: DeployUnitCommand = {
        type: 'deploy_unit',
        unitType: UnitType.KNIGHT,
        position: { x: 500, y: 600 },
        timestamp: Date.now()
      };

      const player = createMockPlayer({ elixir: 5 });
      const gameState = createMockGameState();

      const result = CommandValidator.validateDeployUnit(
        command,
        player,
        gameState
      );

      expect(result.valid).toBe(true);
    });
  });
});
```

Run tests:
```bash
npm test                  # Run all tests
npm test -- --watch       # Watch mode
npm test -- --coverage    # Coverage report
```

### Coverage Requirements

- **Target:** 80% code coverage
- **Minimum:** 70% for PR approval
- **Critical paths:** 100% coverage (combat, elixir, networking)

---

## Bug Reporting

### Before Reporting

1. **Search existing issues** - Your bug may already be reported
2. **Update to latest version** - Bug might be fixed
3. **Reproduce consistently** - Ensure it's not a one-time glitch

### Bug Report Template

Use the GitHub issue template:

```markdown
**Describe the Bug**
Clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Start a battle against AI
2. Deploy Knight at position X
3. Wait 30 seconds
4. Observe crash

**Expected Behavior**
Knight should attack enemy tower.

**Actual Behavior**
Game crashes with "NullReferenceException".

**Screenshots/Logs**
Add screenshots or error logs.

**Environment:**
- Platform: Windows 10
- Game Version: 0.1.0
- Godot Version: 4.3.0
- Hardware: Intel i5, 8GB RAM

**Additional Context**
Only happens when deploying Knight in left lane.
```

### Priority Labels

Maintainers will add priority labels:

- `critical` - Game-breaking, affects all users
- `high` - Major feature broken
- `medium` - Minor feature affected
- `low` - Cosmetic issue

---

## Feature Requests

### Suggesting Features

1. **Check roadmap** - Feature might be planned
2. **Search existing issues** - Avoid duplicates
3. **Consider scope** - Does it fit the game's vision?

### Feature Request Template

```markdown
**Feature Description**
Clear description of the feature.

**Problem it Solves**
What problem does this address?

**Proposed Solution**
How would you implement it?

**Alternatives Considered**
Other ways to solve the problem.

**Additional Context**
Mockups, examples from other games, etc.

**Estimated Scope**
- [ ] Small (< 1 day)
- [ ] Medium (1-3 days)
- [ ] Large (> 1 week)
```

---

## Community

### Communication Channels

- **GitHub Issues** - Bug reports, feature requests
- **GitHub Discussions** - General questions, ideas
- **Discord** - Real-time chat, community
- **Email** - contribute@battlecastles.game

### Getting Help

- Read documentation first
- Search existing issues/discussions
- Ask specific questions
- Provide context and code samples

### Recognition

Contributors are recognized in:
- `CONTRIBUTORS.md` file
- Release notes
- In-game credits (for significant contributions)

---

## License

By contributing to Battle Castles, you agree that your contributions will be licensed under the project's license (see `LICENSE` file).

---

## Questions?

If you have questions about contributing, please:

1. Check this guide
2. Search GitHub Discussions
3. Ask on Discord
4. Email contribute@battlecastles.game

**Thank you for contributing to Battle Castles!**

---

**Version:** 0.1.0
**Last Updated:** November 1, 2025
