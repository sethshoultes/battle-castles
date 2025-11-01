# Coding Standards Guide

## Core Principles

### SOLID Principles
- **S**ingle Responsibility: Each class/function does ONE thing well
- **O**pen/Closed: Open for extension, closed for modification
- **L**iskov Substitution: Derived classes must be substitutable for base classes
- **I**nterface Segregation: Many specific interfaces over one general interface
- **D**ependency Inversion: Depend on abstractions, not concretions

### Additional Principles
- **DRY** (Don't Repeat Yourself): Single source of truth
- **KISS** (Keep It Simple, Stupid): Avoid unnecessary complexity
- **YAGNI** (You Aren't Gonna Need It): Don't add functionality until needed
- **Clean Code**: Readable, maintainable, testable

## GDScript Standards (Godot)

### Naming Conventions

```gdscript
# Classes: PascalCase
class_name BattleManager

# Constants: UPPER_SNAKE_CASE
const MAX_UNITS = 40
const ELIXIR_REGEN_RATE = 1.0 / 2.8

# Variables: snake_case
var current_health: int
var is_attacking: bool

# Private variables: underscore prefix
var _internal_state: Dictionary

# Signals: snake_case, descriptive
signal unit_deployed(unit: BattleUnit)
signal battle_ended(winner: int)

# Functions: snake_case, verb phrases
func calculate_damage(attacker: Unit, defender: Unit) -> int:
    pass

# Private functions: underscore prefix
func _process_internal() -> void:
    pass
```

### File Organization

```gdscript
# File structure template
extends Node2D
class_name ExampleClass

## Brief description of the class
## @tutorial: Link to relevant documentation

# Signals (grouped at top)
signal example_signal(param: int)

# Constants
const MAX_VALUE = 100

# Export variables (for inspector)
@export_group("Combat Stats")
@export var attack_damage: int = 50
@export var attack_speed: float = 1.0

# Public variables
var public_property: String

# Private variables
var _private_property: bool

# Onready variables (node references)
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# Godot lifecycle methods (in order of execution)
func _init() -> void:
    pass

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

# Public methods
func public_method() -> void:
    pass

# Private methods
func _private_method() -> void:
    pass

# Signal callbacks
func _on_signal_received() -> void:
    pass
```

### Best Practices

```gdscript
# GOOD: Type hints everywhere
func calculate_damage(attacker: Unit, defender: Unit) -> int:
    return attacker.damage - defender.armor

# BAD: No type hints
func calculate_damage(attacker, defender):
    return attacker.damage - defender.armor

# GOOD: Early returns for clarity
func can_deploy_unit(unit: Unit, position: Vector2) -> bool:
    if not has_enough_elixir(unit.cost):
        return false
    if not is_valid_position(position):
        return false
    return true

# BAD: Nested if statements
func can_deploy_unit(unit: Unit, position: Vector2) -> bool:
    if has_enough_elixir(unit.cost):
        if is_valid_position(position):
            return true
    return false

# GOOD: Use built-in functions
var clamped_value = clamp(input, 0, 100)

# BAD: Reinventing the wheel
var clamped_value = input
if input < 0:
    clamped_value = 0
elif input > 100:
    clamped_value = 100
```

## TypeScript Standards (Node.js Server)

### File Structure

```typescript
// src/services/BattleService.ts

import { Injectable } from '@decorators/injectable';
import { Logger } from '../utils/Logger';
import { GameState, Player, Command } from '../types';

/**
 * Service responsible for battle logic and state management
 */
@Injectable()
export class BattleService {
    private readonly logger = new Logger(BattleService.name);
    private readonly tickRate = 20; // Hz

    constructor(
        private readonly validator: CommandValidator,
        private readonly physics: PhysicsEngine
    ) {}

    /**
     * Process a player command
     * @param command - The command to execute
     * @param state - Current game state
     * @returns Updated game state
     */
    public processCommand(
        command: Command,
        state: GameState
    ): GameState {
        // Implementation
    }

    private validateCommand(command: Command): boolean {
        // Private implementation
    }
}
```

### Naming Conventions

```typescript
// Interfaces: PascalCase with 'I' prefix (optional, team decision)
interface IPlayer {
    id: string;
    name: string;
}

// Types: PascalCase
type GameState = {
    players: Player[];
    units: Unit[];
};

// Enums: PascalCase with singular names
enum MessageType {
    Connect = 'CONNECT',
    Disconnect = 'DISCONNECT',
    GameUpdate = 'GAME_UPDATE'
}

// Classes: PascalCase
class BattleManager {
    // Private properties: underscore prefix or 'private' keyword
    private _state: GameState;

    // Public methods: camelCase
    public startBattle(): void {}

    // Private methods: camelCase with private keyword
    private processUpdate(): void {}
}

// Functions: camelCase
function calculateDistance(a: Vector2, b: Vector2): number {
    return Math.sqrt((b.x - a.x) ** 2 + (b.y - a.y) ** 2);
}

// Constants: UPPER_SNAKE_CASE
const MAX_PLAYERS = 4;
const DEFAULT_PORT = 3001;
```

### Error Handling

```typescript
// GOOD: Specific error types
class ValidationError extends Error {
    constructor(message: string, public field?: string) {
        super(message);
        this.name = 'ValidationError';
    }
}

// GOOD: Proper error handling
async function deployUnit(
    playerId: string,
    unitType: string,
    position: Vector2
): Promise<Unit> {
    try {
        const player = await getPlayer(playerId);
        if (!player) {
            throw new NotFoundError(`Player ${playerId} not found`);
        }

        if (!canAfford(player, unitType)) {
            throw new ValidationError('Insufficient elixir', 'elixir');
        }

        return await spawnUnit(unitType, position);
    } catch (error) {
        logger.error('Failed to deploy unit', { playerId, unitType, error });
        throw error;
    }
}

// BAD: Generic error handling
async function deployUnit(playerId, unitType, position) {
    try {
        // ... code
    } catch (e) {
        console.log(e);
        return null;
    }
}
```

## Go Standards (Matchmaking Service)

### Package Structure

```go
// internal/matchmaking/queue.go
package matchmaking

import (
    "context"
    "sync"
    "time"

    "github.com/battle-castles/internal/models"
    "github.com/battle-castles/pkg/logger"
)

// QueueService manages the matchmaking queue
type QueueService struct {
    mu      sync.RWMutex
    players []models.Player
    logger  logger.Logger
}

// NewQueueService creates a new queue service instance
func NewQueueService(log logger.Logger) *QueueService {
    return &QueueService{
        players: make([]models.Player, 0),
        logger:  log,
    }
}

// AddPlayer adds a player to the matchmaking queue
func (q *QueueService) AddPlayer(ctx context.Context, player models.Player) error {
    q.mu.Lock()
    defer q.mu.Unlock()

    // Validation
    if err := q.validatePlayer(player); err != nil {
        return fmt.Errorf("invalid player: %w", err)
    }

    q.players = append(q.players, player)
    q.logger.Info("player added to queue", "playerID", player.ID)
    return nil
}
```

### Error Handling

```go
// GOOD: Wrapped errors with context
func ProcessMatch(matchID string) error {
    match, err := GetMatch(matchID)
    if err != nil {
        return fmt.Errorf("failed to get match %s: %w", matchID, err)
    }

    if err := ValidateMatch(match); err != nil {
        return fmt.Errorf("invalid match %s: %w", matchID, err)
    }

    return nil
}

// GOOD: Custom error types
type ErrPlayerNotFound struct {
    PlayerID string
}

func (e ErrPlayerNotFound) Error() string {
    return fmt.Sprintf("player not found: %s", e.PlayerID)
}

// GOOD: Error checking
if err != nil {
    switch {
    case errors.Is(err, ErrPlayerNotFound{}):
        // Handle specific error
    case errors.Is(err, context.Canceled):
        // Handle cancellation
    default:
        // Handle generic error
    }
}
```

## Python Standards (Economy Service)

### File Structure

```python
# app/services/transaction_service.py
"""
Transaction service for handling in-game economy transactions.
"""

from typing import Optional, List
from datetime import datetime
from decimal import Decimal

from sqlalchemy.orm import Session
from fastapi import HTTPException

from ..models import Transaction, Player
from ..schemas import TransactionCreate
from ..utils.logger import get_logger

logger = get_logger(__name__)


class TransactionService:
    """Service for managing game economy transactions."""

    def __init__(self, db: Session):
        self.db = db

    async def create_transaction(
        self,
        player_id: str,
        transaction_data: TransactionCreate
    ) -> Transaction:
        """
        Create a new transaction for a player.

        Args:
            player_id: The player's unique identifier
            transaction_data: Transaction details

        Returns:
            The created transaction

        Raises:
            HTTPException: If player not found or insufficient funds
        """
        player = await self._get_player(player_id)
        if not player:
            raise HTTPException(404, f"Player {player_id} not found")

        # Validate transaction
        if not self._can_afford(player, transaction_data.amount):
            raise HTTPException(400, "Insufficient funds")

        # Create transaction
        transaction = Transaction(
            player_id=player_id,
            **transaction_data.dict()
        )

        self.db.add(transaction)
        self.db.commit()

        logger.info(f"Transaction created for player {player_id}")
        return transaction

    def _can_afford(
        self,
        player: Player,
        amount: Decimal
    ) -> bool:
        """Check if player can afford the transaction."""
        return player.balance >= amount
```

### Naming Conventions

```python
# Classes: PascalCase
class BattleManager:
    pass

# Functions and methods: snake_case
def calculate_damage(attacker: Unit, defender: Unit) -> int:
    return attacker.damage - defender.armor

# Constants: UPPER_SNAKE_CASE
MAX_UNITS = 40
DEFAULT_TIMEOUT = 30.0

# Private methods/variables: single underscore prefix
class GameState:
    def __init__(self):
        self._internal_state = {}

    def _process_internal(self) -> None:
        pass

# Module-private: double underscore prefix (rarely used)
__private_module_var = "internal"
```

## SQL Standards

### Schema Design

```sql
-- Table names: plural, snake_case
CREATE TABLE players (
    -- Primary key: 'id' or table_singular_id
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Columns: snake_case
    username VARCHAR(32) NOT NULL,
    email VARCHAR(255) NOT NULL,
    trophy_count INTEGER DEFAULT 0,

    -- Timestamps: always include
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Constraints: descriptive names
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

-- Indexes: idx_table_column(s)
CREATE INDEX idx_players_trophy_count ON players(trophy_count DESC);
CREATE INDEX idx_players_created_at ON players(created_at);

-- Foreign keys: fk_table_column
ALTER TABLE player_stats
    ADD CONSTRAINT fk_player_stats_player_id
    FOREIGN KEY (player_id) REFERENCES players(id)
    ON DELETE CASCADE;
```

### Query Standards

```sql
-- GOOD: Readable formatting
SELECT
    p.id,
    p.username,
    ps.trophy_count,
    ps.win_rate
FROM players p
INNER JOIN player_stats ps ON ps.player_id = p.id
WHERE p.created_at >= NOW() - INTERVAL '30 days'
    AND ps.trophy_count > 1000
ORDER BY ps.trophy_count DESC
LIMIT 100;

-- BAD: Everything on one line
SELECT p.id,p.username,ps.trophy_count FROM players p JOIN player_stats ps ON ps.player_id=p.id WHERE p.created_at>=NOW()-INTERVAL '30 days' ORDER BY ps.trophy_count DESC;
```

## Git Commit Standards

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code formatting (no logic change)
- **refactor**: Code restructuring
- **test**: Test additions/changes
- **chore**: Build process/auxiliary tools

### Examples

```bash
# Good commits
git commit -m "feat(battle): implement elixir regeneration system"
git commit -m "fix(network): resolve desync issue on high latency"
git commit -m "docs(api): update matchmaking endpoint documentation"
git commit -m "test(combat): add unit tests for damage calculation"

# Bad commits
git commit -m "fixed stuff"
git commit -m "WIP"
git commit -m "asdfasdf"
```

## Code Review Checklist

### Before Submitting PR
- [ ] Code follows naming conventions
- [ ] All functions have type hints/annotations
- [ ] Complex logic has comments
- [ ] No hardcoded values (use constants)
- [ ] Error handling is comprehensive
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] No commented-out code
- [ ] No console.log/print statements
- [ ] Performance impact considered

### Review Focus Areas
1. **Correctness**: Does it work as intended?
2. **Performance**: Is it efficient?
3. **Security**: Are there vulnerabilities?
4. **Maintainability**: Is it easy to understand?
5. **Testing**: Is it properly tested?
6. **Documentation**: Is it well-documented?

## Performance Guidelines

### Optimization Rules
1. **Measure first**: Profile before optimizing
2. **Optimize algorithms**: Better algorithm > micro-optimizations
3. **Cache expensive operations**: Don't recalculate unchanged data
4. **Pool objects**: Reuse instead of create/destroy
5. **Batch operations**: Reduce API calls and database queries

### Anti-Patterns to Avoid

```gdscript
# BAD: Creating objects every frame
func _process(delta):
    var temp_vector = Vector2(x, y)  # Allocation every frame

# GOOD: Reuse objects
var _temp_vector = Vector2()
func _process(delta):
    _temp_vector.x = x
    _temp_vector.y = y

# BAD: Multiple database calls
for player_id in player_ids:
    player = get_player(player_id)  # N queries

# GOOD: Batch query
players = get_players(player_ids)  # 1 query
```

## Documentation Standards

### Code Comments

```gdscript
## Calculate damage between two units accounting for armor and bonuses.
## @param attacker The unit dealing damage
## @param defender The unit receiving damage
## @return The final damage value after all modifiers
func calculate_damage(attacker: Unit, defender: Unit) -> int:
    # Base damage reduced by armor percentage
    var base_damage = attacker.damage
    var armor_reduction = defender.armor * 0.01  # 1% per armor point

    # Critical hit check (10% chance)
    if randf() < 0.1:
        base_damage *= 1.5  # 50% bonus damage

    return int(base_damage * (1.0 - armor_reduction))
```

### API Documentation

```typescript
/**
 * Deploy a unit to the battlefield
 * @param {string} playerId - The player's unique identifier
 * @param {UnitType} unitType - Type of unit to deploy
 * @param {Vector2} position - Deployment position
 * @returns {Promise<Unit>} The deployed unit
 * @throws {ValidationError} If position is invalid
 * @throws {InsufficientResourcesError} If not enough elixir
 * @example
 * const unit = await deployUnit('player123', 'Knight', {x: 100, y: 200});
 */
```

## Security Guidelines

### Never Do This
```javascript
// NEVER: SQL injection vulnerability
const query = `SELECT * FROM players WHERE id = '${playerId}'`;

// NEVER: Hardcoded secrets
const JWT_SECRET = "my-secret-key";

// NEVER: Unvalidated input
app.post('/api/transaction', (req, res) => {
    processTransaction(req.body);  // No validation!
});

// NEVER: Password in plain text
const password = req.body.password;  // Store hashed only
```

### Always Do This
```javascript
// ALWAYS: Parameterized queries
const query = 'SELECT * FROM players WHERE id = $1';
db.query(query, [playerId]);

// ALWAYS: Environment variables
const JWT_SECRET = process.env.JWT_SECRET;

// ALWAYS: Input validation
const schema = Joi.object({
    amount: Joi.number().positive().required(),
    currency: Joi.string().valid('gold', 'gems').required()
});
const { error, value } = schema.validate(req.body);

// ALWAYS: Hash passwords
const hashedPassword = await bcrypt.hash(password, 10);
```

## Summary

These coding standards ensure:
- **Consistency** across the codebase
- **Maintainability** for future developers
- **Quality** through best practices
- **Security** by avoiding common pitfalls
- **Performance** through efficient patterns

All team members must follow these standards. Code reviews will enforce compliance. When in doubt, prioritize readability and simplicity over cleverness.