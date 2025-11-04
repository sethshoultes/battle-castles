# GitHub Issues - Code Review Findings

**Generated:** November 4, 2025
**Based on:** Comprehensive Code Review (claude/code-review-011CUoLvovLiv19HBSkW1SS8)

This document contains all issues identified during the code review, organized by priority. Each issue includes title, description, acceptance criteria, and estimated effort.

---

## 🔴 Critical Priority Issues

### Issue #1: Implement 8 Missing Unit Scripts

**Labels:** `critical`, `bug`, `gameplay`, `content-gap`
**Estimated Effort:** 16-24 hours
**Milestone:** Sprint 1 - Critical Features

**Description:**
Currently, 8 out of 12 cards (66%) are non-functional because their corresponding unit scripts do not exist. Card resources are defined in `/client/resources/cards/` but the unit implementations are missing.

**Missing Units:**
- `baby_dragon.gd` (baby_dragon.tres exists)
- `barbarians.gd` (barbarians.tres exists)
- `mini_pekka.gd` (mini_pekka.tres exists)
- `minions.gd` (minions.tres exists)
- `musketeer.gd` (musketeer.tres exists)
- `skeleton_army.gd` (skeleton_army.tres exists)
- `valkyrie.gd` (valkyrie.tres exists)
- `wizard.gd` (wizard.tres exists)

**Impact:**
- Cards cannot be deployed in battles
- Deck builder shows unplayable cards
- Game feels incomplete
- Blocks alpha testing

**Acceptance Criteria:**
- [ ] All 8 unit scripts created in `/client/scripts/units/`
- [ ] Each unit extends `BaseUnit` properly
- [ ] Units use stats from their card resources
- [ ] Units have proper animations (or placeholders)
- [ ] Units can be spawned and function in battle
- [ ] Unit tests added for each new unit
- [ ] Documentation updated

**Technical Notes:**
Reference existing units (knight.gd, archer.gd, giant.gd, goblin.gd) as templates. Each unit should:
1. Extend `BaseUnit`
2. Initialize components with card stats
3. Override unit-specific behavior if needed
4. Support both player and enemy teams

**Files to Create:**
- `/client/scripts/units/baby_dragon.gd`
- `/client/scripts/units/barbarians.gd`
- `/client/scripts/units/mini_pekka.gd`
- `/client/scripts/units/minions.gd`
- `/client/scripts/units/musketeer.gd`
- `/client/scripts/units/skeleton_army.gd`
- `/client/scripts/units/valkyrie.gd`
- `/client/scripts/units/wizard.gd`

---

### Issue #2: Create Missing Loading Screen Scene

**Labels:** `critical`, `bug`, `ui`, `crash`
**Estimated Effort:** 4 hours
**Milestone:** Sprint 1 - Critical Features

**Description:**
`scene_manager.gd` attempts to load `res://scenes/ui/loading_screen.tscn` but this file does not exist, causing a runtime error during scene transitions.

**Location:**
- File: `/client/scripts/core/scene_manager.gd:10`
- Missing: `/client/scenes/ui/loading_screen.tscn`

**Impact:**
- Runtime error when changing scenes
- Scene transitions may fail
- Poor user experience
- Blocks production release

**Acceptance Criteria:**
- [ ] Create `loading_screen.tscn` scene
- [ ] Design shows loading spinner/animation
- [ ] Progress bar functional (if applicable)
- [ ] Scene integrates with SceneManager
- [ ] No runtime errors during scene transitions
- [ ] Loading screen tested on all target platforms

**Technical Requirements:**
- Control node as root
- Loading animation (spinner or progress bar)
- Optional: Loading tips/hints
- Optional: Asset preloading progress
- Responsive design for all resolutions

**Assets Needed:**
- Loading spinner sprite/animation
- Background (can reuse existing assets)
- Font for loading text

---

### Issue #3: Move Test Scenes to Dedicated Directory

**Labels:** `critical`, `technical-debt`, `build`, `organization`
**Estimated Effort:** 1 hour
**Milestone:** Sprint 1 - Critical Features

**Description:**
Test scenes are currently located in the root `/client/scenes/` directory and will be included in production builds unless explicitly excluded. This increases build size and exposes test functionality to users.

**Test Scenes to Move:**
- `audio_test.tscn`
- `network_test_ui.tscn`
- `progression_test.tscn`

**Impact:**
- Larger build size (unnecessary test scenes included)
- Potential security risk (test interfaces exposed)
- Poor organization
- Confusion about production vs. test scenes

**Acceptance Criteria:**
- [ ] Create `/client/scenes/tests/` directory
- [ ] Move all 3 test scenes to new directory
- [ ] Update any references to old paths
- [ ] Update export presets to exclude `/scenes/tests/`
- [ ] Verify builds do not include test scenes
- [ ] Documentation updated

**Files to Move:**
- `/client/scenes/audio_test.tscn` → `/client/scenes/tests/audio_test.tscn`
- `/client/scenes/network_test_ui.tscn` → `/client/scenes/tests/network_test_ui.tscn`
- `/client/scenes/progression_test.tscn` → `/client/scenes/tests/progression_test.tscn`

**Export Settings Update:**
Add to `export_presets.cfg`:
```
exclude_filter="*.test.gd,/tests/*,/scenes/tests/*"
```

---

## 🟠 High Priority Issues

### Issue #4: Refactor Battlefield Controller (God Object)

**Labels:** `high-priority`, `refactoring`, `technical-debt`, `architecture`
**Estimated Effort:** 24-40 hours (3-5 days)
**Milestone:** Sprint 2 - Code Quality

**Description:**
`battlefield.gd` is 880 lines and violates the Single Responsibility Principle. It handles grid management, unit spawning, AI logic, visual rendering, camera setup, tower management, and input handling - far too many responsibilities for a single class.

**Current Issues:**
- Hard to maintain (880 lines)
- Hard to test (tightly coupled)
- Hard to understand (multiple concerns)
- Violates SOLID principles
- High cyclomatic complexity

**Proposed Refactoring:**
Split into 4-5 focused classes:
1. `battlefield_controller.gd` - Main orchestrator (100-150 lines)
2. `battlefield_renderer.gd` - Grid and visual feedback (150-200 lines)
3. `unit_spawner.gd` - Unit instantiation and pooling (200-250 lines)
4. `ai_opponent_controller.gd` - AI spawning and decision logic (250-300 lines)
5. Optional: `deployment_validator.gd` - Deployment zone logic (100 lines)

**Acceptance Criteria:**
- [ ] Battlefield controller reduced to < 200 lines
- [ ] Each new class has single responsibility
- [ ] All functionality preserved
- [ ] Unit tests updated
- [ ] Integration tests pass
- [ ] Performance not degraded
- [ ] Documentation updated with new architecture

**Technical Approach:**
1. Extract AI logic first (lines 590-810)
2. Extract unit spawning (lines 265-408)
3. Extract rendering (lines 166-240)
4. Keep orchestration in battlefield_controller
5. Use signals for communication between modules

**Migration Strategy:**
- Create new files alongside existing
- Gradually move functionality
- Test after each major change
- Delete old code once verified
- Update all references

---

### Issue #5: Create Configuration System for Hardcoded Values

**Labels:** `high-priority`, `refactoring`, `data-driven`, `technical-debt`
**Estimated Effort:** 16-24 hours (2-3 days)
**Milestone:** Sprint 2 - Code Quality

**Description:**
Project documentation (CLAUDE.md) states "NO Hardcoded Values - everything data-driven", but many hardcoded constants exist throughout the codebase, particularly in `battlefield.gd`.

**Hardcoded Values Found:**
```gdscript
# battlefield.gd:4-23
const TILE_SIZE := 64
const GRID_WIDTH := 18
const GRID_HEIGHT := 28
const MAX_UNITS_TOTAL := 50
const MAX_UNITS_PER_TEAM := 30
const RIVER_Y := GRID_HEIGHT / 2 * TILE_SIZE

# battlefield.gd:603
var ai_elixir_reserve: float = 1.5

# battlefield.gd:390, 714 (and many more)
shape.radius = 12
if distance < 400:
```

**Impact:**
- Hard to balance gameplay
- Requires code changes for tuning
- Difficult to A/B test
- No per-environment configs
- Violates stated principles

**Proposed Solution:**
Create resource-based configuration system:

1. **BattlefieldConfig.gd** (Resource):
```gdscript
class_name BattlefieldConfig
extends Resource

@export var tile_size: int = 64
@export var grid_width: int = 18
@export var grid_height: int = 28
@export var max_units_total: int = 50
@export var max_units_per_team: int = 30
```

2. **GameBalanceConfig.gd** (Resource):
```gdscript
class_name GameBalanceConfig
extends Resource

@export var ai_elixir_reserve: float = 1.5
@export var tower_threat_radius: float = 400.0
@export var unit_collision_radius: float = 12.0
@export var elixir_gen_rate: float = 1.0 / 2.8
```

**Acceptance Criteria:**
- [ ] Create BattlefieldConfig resource
- [ ] Create GameBalanceConfig resource
- [ ] Create default .tres files for each
- [ ] Update battlefield.gd to use configs
- [ ] Update all hardcoded values
- [ ] Create development/production configs
- [ ] Documentation for adding new configs
- [ ] No hardcoded magic numbers remain

**Files to Create:**
- `/client/scripts/resources/battlefield_config.gd`
- `/client/scripts/resources/game_balance_config.gd`
- `/client/resources/configs/battlefield_default.tres`
- `/client/resources/configs/game_balance_default.tres`
- `/client/resources/configs/game_balance_dev.tres` (for testing)

---

### Issue #6: Fix Mock Implementation in Chest System

**Labels:** `high-priority`, `bug`, `mock-data`, `progression`
**Estimated Effort:** 8-16 hours (1-2 days)
**Milestone:** Sprint 2 - Code Quality

**Description:**
`chest_system.gd:403` contains a mock implementation for filtering cards by rarity. Project guidelines (CLAUDE.md) explicitly state "NO mock data - all data must come from real services".

**Location:**
- File: `/client/scripts/progression/chest_system.gd:403`
- Code:
```gdscript
# Mock implementation - in real game would check actual card rarities
match rarity:
    CardCollection.Rarity.COMMON:
```

**Impact:**
- Violates project principles
- Chest rewards may not work correctly
- Card rarity system incomplete
- Blocks progression system testing

**Proposed Solution:**
1. Define rarity in CardData resource
2. Query actual card collection for rarities
3. Implement proper filtering logic
4. Remove all mock implementations

**Acceptance Criteria:**
- [ ] CardData has rarity property
- [ ] All card .tres files define rarity
- [ ] Chest system queries real card data
- [ ] Filtering works correctly for all rarities
- [ ] No "mock" comments remain
- [ ] Unit tests added for rarity filtering
- [ ] Integration tests for chest opening

**Technical Requirements:**
- Extend CardData with rarity enum
- Update all 12 card resources
- Implement `CardCollection.get_cards_by_rarity()`
- Update ChestSystem to use real data
- Add validation for rarity values

---

### Issue #7: Consolidate Duplicate Audio Management Systems

**Labels:** `high-priority`, `refactoring`, `duplication`, `architecture`
**Estimated Effort:** 16-24 hours (2-3 days)
**Milestone:** Sprint 3 - Architecture Improvements

**Description:**
Three separate audio management systems exist with overlapping responsibilities, violating the DRY (Don't Repeat Yourself) principle.

**Duplicate Systems:**
1. `audio_manager.gd` (537 lines) - Audio system initialization
2. `music_controller.gd` (546 lines) - Music with transitions
3. `sound_pool.gd` (347 lines) - Audio pooling

**Issues:**
- Unclear ownership (which system handles what?)
- Potential conflicts
- Difficult to maintain
- Violates DRY principle
- Confusion for new developers

**Proposed Solution:**
Consolidate into single unified `AudioManager` with sub-managers:

```
AudioManager (Main controller)
├── MusicManager (Handles music tracks, transitions, layers)
├── SFXManager (Handles sound effects)
└── SoundPool (Handles object pooling for both)
```

**Acceptance Criteria:**
- [ ] Single AudioManager as entry point
- [ ] Clear separation of music vs SFX
- [ ] Object pooling integrated
- [ ] All functionality preserved
- [ ] No duplicate code
- [ ] Documentation explains architecture
- [ ] Migration guide for existing code
- [ ] All audio still works correctly

**Migration Strategy:**
1. Audit all three systems for functionality
2. Create new unified AudioManager
3. Integrate music_controller as MusicManager
4. Integrate SFX functionality
5. Use sound_pool for both music and SFX
6. Update all references
7. Deprecate old systems
8. Remove old files after verification

---

## 🟡 Medium Priority Issues

### Issue #8: Add UI Test Coverage

**Labels:** `medium-priority`, `testing`, `ui`, `quality`
**Estimated Effort:** 40 hours (1 week)
**Milestone:** Sprint 3 - Testing Improvements

**Description:**
No tests exist for UI systems, leaving a significant gap in test coverage. UI bugs can go undetected until manual testing.

**Missing Tests:**
- SettingsMenuUI (350 lines) - No tests
- DeckBuilderUI (568 lines) - No tests
- BattleUI (389 lines) - No tests
- MainMenuUI (347 lines) - No tests
- ResultsScreen - No tests

**Acceptance Criteria:**
- [ ] Test suite created for each UI component
- [ ] User flow tests (navigation, input)
- [ ] Settings persistence tests
- [ ] Deck building logic tests
- [ ] Battle UI update tests
- [ ] All tests passing
- [ ] Coverage report generated

**Test Cases to Implement:**
- Settings: Load, modify, save, cancel, validation
- Deck Builder: Add card, remove card, save deck, validate deck
- Battle UI: Elixir updates, timer updates, card selection
- Main Menu: Navigation, button clicks, scene transitions
- Results: Display correct winner, statistics, navigation

---

### Issue #9: Implement Spatial Partitioning for Entity Queries

**Labels:** `medium-priority`, `performance`, `optimization`
**Estimated Effort:** 24-40 hours (3-5 days)
**Milestone:** Sprint 4 - Performance Optimization

**Description:**
Current entity queries use O(n²) nested loops, which will become a performance bottleneck with many units on screen. Combat system iterates through all entities for every attacking entity every frame.

**Problem Code:**
```gdscript
# combat_system.gd:75-100
for entity in all_entities:  # O(n²) complexity
    if entity == attacker or not entity.is_active:
        continue
```

**Impact:**
- Poor performance with many units (>50)
- Frame drops during intense battles
- Raspberry Pi target may not meet 30fps
- Scalability issues

**Proposed Solution:**
Implement spatial hash grid or quadtree for efficient entity queries.

**Acceptance Criteria:**
- [ ] Spatial partitioning system implemented
- [ ] Entity queries use spatial structure
- [ ] Performance improved (measured)
- [ ] No change in behavior
- [ ] Integration tests pass
- [ ] Performance tests show improvement
- [ ] Documentation updated

**Performance Targets:**
- Support 100+ units at 60fps (PC)
- Support 40+ units at 30fps (Raspberry Pi)
- Query time < 1ms for typical scenarios

---

### Issue #10: Add Performance Monitoring Dashboard

**Labels:** `medium-priority`, `devtools`, `performance`, `debugging`
**Estimated Effort:** 40 hours (1 week)
**Milestone:** Sprint 4 - Performance Optimization

**Description:**
Basic performance metrics are tracked but no profiling or monitoring dashboard exists. Makes it difficult to identify bottlenecks and optimize performance.

**Current State:**
- `game_manager.gd` tracks update_time and frame_count
- No frame time breakdown
- No bottleneck identification
- No memory usage tracking

**Proposed Features:**
1. In-game performance overlay (dev builds only)
2. Frame time breakdown by system
3. Memory usage tracking
4. Entity count monitoring
5. Draw call counting
6. Performance history graph
7. Export performance data to CSV

**Acceptance Criteria:**
- [ ] Performance overlay implemented
- [ ] Toggle on/off with hotkey (F3)
- [ ] Shows FPS, frame time, memory
- [ ] System-by-system breakdown
- [ ] Entity count and type
- [ ] Warning indicators for issues
- [ ] Only in development builds
- [ ] Documentation for using profiler

---

### Issue #11: Create Architecture Diagrams

**Labels:** `medium-priority`, `documentation`, `architecture`
**Estimated Effort:** 16-24 hours (2-3 days)
**Milestone:** Sprint 3 - Documentation

**Description:**
No visual representation of the system architecture exists. New developers struggle to understand how systems interact.

**Missing Diagrams:**
1. ECS Architecture Diagram
2. System Interaction Diagram
3. Data Flow Diagram
4. Network Architecture
5. Class Hierarchy

**Acceptance Criteria:**
- [ ] 5 architecture diagrams created
- [ ] Diagrams in docs/architecture/
- [ ] Use standard notation (UML/C4)
- [ ] Include key classes and relationships
- [ ] Show data flow
- [ ] Show signal connections
- [ ] Export as PNG and source files
- [ ] Referenced in documentation

**Tools:**
- draw.io or PlantUML for diagrams
- Store source files in repo
- Export PNG for easy viewing

---

## 🟢 Low Priority Issues

### Issue #12: Standardize Error Handling Across Codebase

**Labels:** `low-priority`, `code-quality`, `consistency`
**Estimated Effort:** 8 hours (1 day)
**Milestone:** Sprint 5 - Polish

**Description:**
Inconsistent error handling throughout codebase. Some files use `push_error()`, others use `print()`, causing confusion about severity.

**Examples:**
```gdscript
# combat_system.gd:158
push_error("Cannot apply damage to entity without HealthComponent")

# battlefield.gd:267
print("Cannot deploy unit at position: ", position)  # Should be push_warning?
```

**Proposed Standard:**
- `push_error()` - Critical errors (should never happen in production)
- `push_warning()` - Warnings (invalid input, recoverable issues)
- `print()` - Debug info (only in development)
- `assert()` - Development-time checks

**Acceptance Criteria:**
- [ ] Error handling guide created
- [ ] All error messages reviewed
- [ ] Consistent use of push_error/push_warning
- [ ] Debug prints removed or gated
- [ ] Documentation updated

---

### Issue #13: Extract Visual Data to Resource Files

**Labels:** `low-priority`, `refactoring`, `data-driven`
**Estimated Effort:** 4-8 hours
**Milestone:** Sprint 5 - Polish

**Description:**
`battlefield.gd:410-505` contains 95-line `_get_unit_visuals()` method that is mostly data, not logic. Should be moved to resource files for easier editing.

**Current Implementation:**
```gdscript
func _get_unit_visuals(unit_type: String) -> Dictionary:
    match unit_type:
        "knight":
            return {
                "display_name": "KNIGHT",
                "size": Vector2(36, 52),
                "player_color": Color(0.2, 0.4, 0.9),
                "enemy_color": Color(0.9, 0.2, 0.2)
            }
        # ... 10 more cases
```

**Proposed Solution:**
Create `UnitVisualData` resource with properties, store in .tres files.

**Acceptance Criteria:**
- [ ] UnitVisualData resource created
- [ ] .tres files for each unit type
- [ ] battlefield.gd loads from resources
- [ ] Method reduced to resource lookup
- [ ] Artists can edit without code changes

---

### Issue #14: Add Null Checks for Function Parameters

**Labels:** `low-priority`, `stability`, `defensive-programming`
**Estimated Effort:** 4-8 hours
**Milestone:** Sprint 5 - Polish

**Description:**
Many functions don't validate parameters, leading to potential null reference crashes.

**Example:**
```gdscript
# combat_system.gd:75
func find_best_target(attacker: Entity, all_entities: Array,
                      attack_comp: AttackComponent) -> Entity:
    # No null check for attack_comp
    if not attack_comp.is_target_valid(entity):  # Crash if null
```

**Acceptance Criteria:**
- [ ] All public functions validate parameters
- [ ] Null checks added where appropriate
- [ ] Assertions for development builds
- [ ] Error messages explain the issue
- [ ] Documentation updated

---

### Issue #15: Document simple_unit vs base_unit Distinction

**Labels:** `low-priority`, `documentation`, `architecture`
**Estimated Effort:** 2-4 hours
**Milestone:** Sprint 5 - Documentation

**Description:**
Two unit base classes exist (`simple_unit.gd` and `base_unit.gd`) with unclear distinction. Developers don't know which to use for new units.

**Current State:**
- `simple_unit.gd` (200 lines) - Used by battlefield spawner
- `base_unit.gd` (386 lines) - Extended by unit classes
- No documentation explaining difference

**Acceptance Criteria:**
- [ ] Document purpose of each class
- [ ] Explain when to use each
- [ ] Add decision flowchart
- [ ] Update contribution guide
- [ ] Consider deprecating one if redundant

---

## Summary Statistics

**Total Issues:** 15
- 🔴 Critical: 3 issues (Blocking production)
- 🟠 High Priority: 4 issues (Should fix soon)
- 🟡 Medium Priority: 4 issues (Nice to have)
- 🟢 Low Priority: 4 issues (Polish)

**Total Estimated Effort:** 200-320 hours (5-8 weeks)

**Critical Path Items (Must Fix for Alpha):**
1. Implement missing units (2-3 days)
2. Create loading screen (4 hours)
3. Move test scenes (1 hour)

**Estimated Time to Alpha-Ready:** 2-3 weeks with focused effort

---

## Issue Templates

### Bug Report Template
```markdown
## Description
[Clear description of the bug]

## Steps to Reproduce
1.
2.
3.

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Environment
- OS: [e.g., Windows 10]
- Godot Version: [e.g., 4.3]
- Branch: [e.g., develop]

## Additional Context
[Screenshots, logs, etc.]
```

### Feature Request Template
```markdown
## Feature Description
[Clear description of the feature]

## Use Case
[Why is this needed?]

## Proposed Solution
[How should it work?]

## Alternatives Considered
[Other approaches]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

---

*Generated from Code Review Report - November 4, 2025*
