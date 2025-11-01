# Battle Castles Progression System

Complete progression and economy system for Battle Castles, a tower defense battle game inspired by Clash Royale.

## System Components

### 1. Player Profile (`player_profile.gd`)
Manages player data and statistics:
- **Level System**: Players progress from level 1 to 50
- **Experience Points**: Earned from battles and activities
- **Battle Statistics**: Wins, losses, draws, three-crown victories
- **Trophy Tracking**: Current and highest trophy counts
- **Data Persistence**: Automatic save/load with backup system

### 2. Card Collection (`card_collection.gd`)
Handles card ownership and upgrades:
- **Card Rarities**: Common, Rare, Epic, Legendary
- **Card Levels**: 1-9 for Common/Rare, 1-7 for Epic, 1-6 for Legendary
- **Upgrade System**: Cards require duplicates and gold to upgrade
- **Collection Progress**: Track unlocked cards and max-level cards
- **Starter Cards**: New players receive initial card set

### 3. Deck Manager (`deck_manager.gd`)
Manages player deck configurations:
- **8 Cards per Deck**: Standard deck size
- **3 Deck Slots**: Save multiple deck configurations
- **Deck Validation**: Ensures legal deck composition
- **Average Elixir**: Calculates deck elixir cost
- **Import/Export**: Share decks via deck codes
- **Battle Statistics**: Track wins/losses per deck

### 4. Currency Manager (`currency_manager.gd`)
Handles in-game economy:
- **Gold**: Soft currency for upgrades and purchases
- **Gems**: Premium currency for speed-ups and special items
- **Transaction Logging**: Complete history of all transactions
- **Validation**: Prevents negative balances and exploits
- **Statistics**: Track total earned, spent, and current balance

### 5. Chest System (`chest_system.gd`)
Timer-based reward system:
- **Chest Types**:
  - Wooden (5 seconds unlock)
  - Silver (3 minutes)
  - Golden (8 minutes)
  - Giant (12 minutes)
  - Magical (12 minutes)
  - Super Magical (24 minutes)
  - Legendary (24 minutes)
- **4 Chest Slots**: Limited storage space
- **Timer Unlocking**: One chest unlocks at a time
- **Gem Speed-up**: Instant unlock option
- **Chest Cycle**: Predictable chest rewards pattern

### 6. Trophy System (`trophy_system.gd`)
Arena progression and competitive ranking:
- **10 Arenas**: From Training Camp to Legendary Arena
- **ELO-based Calculation**: Fair trophy gains/losses
- **Season System**: 30-day competitive seasons
- **Trophy Reset**: End-of-season reset for high-trophy players
- **Milestones**: Rewards for reaching trophy thresholds
- **Win Streaks**: Bonus trophies for consecutive wins

### 7. Achievement System (`achievement_system.gd`)
Goals and rewards system:
- **Categories**: Battle, Collection, Social, Progression, Special
- **Tiers**: Bronze, Silver, Gold, Platinum, Diamond
- **Progress Tracking**: Real-time achievement updates
- **Reward Claims**: Gold and gem rewards for completion
- **Statistics**: Track completion percentage per category

## Data Storage

All progression data is saved locally in the `user://` directory:
- `player_profile.json` - Player stats and level
- `card_collection.json` - Owned cards and levels
- `deck_data.json` - Deck configurations
- `currency_data.json` - Gold and gem balances
- `transaction_log.json` - Currency transaction history
- `chest_data.json` - Current chest queue
- `trophy_data.json` - Trophy and arena progress
- `achievement_data.json` - Achievement progress

## Testing

Run the test scene to verify all systems:
```gdscript
# Load the test scene
res://scenes/progression_test.tscn
```

The test script demonstrates:
1. Player profile creation
2. Currency management
3. Card collection and upgrades
4. Deck creation and validation
5. Battle simulation
6. Chest rewards
7. Trophy calculations
8. Achievement tracking

## Usage Example

```gdscript
# Initialize systems
var player_profile = PlayerProfile.new()
var card_collection = CardCollection.new()
var deck_manager = DeckManager.new()
var currency_manager = CurrencyManager.new()

# Create player
player_profile.create_new_profile("PlayerName")

# Add cards
card_collection.add_cards("knight", 10)

# Create deck
var cards = ["knight", "archer", "goblin", "giant",
             "fireball", "arrows", "cannon", "musketeer"]
deck_manager.create_deck(0, "My Deck", cards)

# Record battle win
player_profile.record_battle_result("win", 3, 0)
player_profile.add_experience(50)

# Add currency
currency_manager.add_gold(100)
```

## Card Definitions

The system includes 26 predefined cards:

**Troops** (12):
- Common: Knight, Archer, Goblin, Barbarian
- Rare: Giant, Musketeer, Wizard
- Epic: Prince, Baby Dragon, P.E.K.K.A
- Legendary: Ice Wizard, Princess

**Spells** (7):
- Common: Arrows, Zap, Rage
- Rare: Fireball
- Epic: Lightning, Freeze, Poison

**Buildings** (7):
- Common: Cannon, Tesla, Mortar
- Rare: Bomb Tower, Inferno Tower
- Epic: X-Bow

## Balance Configuration

Key balance parameters:
- Max Player Level: 50
- Cards per Deck: 8
- Deck Slots: 3
- Chest Slots: 4
- Max Gold: 999,999,999
- Max Gems: 999,999
- Trophy Reset Threshold: 4000
- Season Duration: 30 days

## Save Data Migration

The system includes data migration support for future updates:
- Version tracking in all save files
- Automatic migration of old save formats
- Backup system (3 backups per save file)
- Data validation on load

## Signal Events

Each system emits signals for UI updates:
- `level_up` - Player gains a level
- `card_unlocked` - New card discovered
- `deck_created` - New deck saved
- `currency_changed` - Gold/gems updated
- `chest_opened` - Chest rewards received
- `arena_changed` - Player enters new arena
- `achievement_unlocked` - Achievement completed

## Performance Considerations

- JSON save files for easy debugging
- Automatic saves on important actions
- Backup system prevents data loss
- Efficient stat tracking
- Minimal memory footprint

## Future Enhancements

Potential additions:
- Clan system integration
- Battle pass progression
- Special events and challenges
- Card trading system
- Emote collection
- Profile customization
- Leaderboard integration
- Cloud save synchronization