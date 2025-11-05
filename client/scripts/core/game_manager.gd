## Singleton GameManager that coordinates all game systems and entities
## Add this to Project Settings -> Autoload as "GameManager"
extends Node

## Signal emitted when an entity is spawned
signal entity_spawned(entity: Entity)

## Signal emitted when an entity is destroyed
signal entity_destroyed(entity: Entity)

## Signal emitted when the game state changes
signal game_state_changed(new_state: GameState, old_state: GameState)

## Signal emitted when the game starts
signal game_started()

## Signal emitted when the game ends
signal game_ended(winning_team: int)

## Enum for game states
enum GameState {
	MENU,
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER
}

## Current game state
var current_state: GameState = GameState.MENU

## All active entities in the game
var entities: Array[Entity] = []

## Entity pools for object pooling
var entity_pools: Dictionary = {}

## Game systems
var combat_system: CombatSystem
var movement_system: MovementSystem
var targeting_system: TargetingSystem

## Progression systems
var player_profile: PlayerProfile = null
var trophy_system: TrophySystem = null
var currency_manager: CurrencyManager = null

## Configuration resources (loaded from data files - NO HARDCODED VALUES)
var battlefield_config: BattlefieldConfig = null
var balance_config: GameBalanceConfig = null

## Game configuration
var max_entities: int = 200
var enable_object_pooling: bool = true
var pool_sizes: Dictionary = {
	"Unit": 50,
	"Projectile": 100,
	"Effect": 30
}
var ai_difficulty: int = 1  # 0: Easy, 1: Medium, 2: Hard

## Performance monitoring
var entity_count: int = 0
var update_time: float = 0.0
var frame_count: int = 0

## Game time tracking
var game_time: float = 0.0
var match_duration: float = 180.0  # 3 minutes default

## Team scores
var team_scores: Dictionary = {
	0: 0,  # Blue team
	1: 0   # Red team
}


func _ready() -> void:
	set_process(false)
	_load_game_configs()
	_initialize_systems()
	_initialize_progression_systems()
	_initialize_pools()


func _load_game_configs() -> void:
	"""Load game configuration resources from data files"""
	print("GameManager: Loading game configurations...")

	# Load battlefield configuration
	battlefield_config = load("res://resources/configs/battlefield_default.tres")
	if not battlefield_config:
		push_error("GameManager: Failed to load battlefield config! Creating default...")
		battlefield_config = BattlefieldConfig.new()
	else:
		print("  ✓ Battlefield config loaded")

	# Load game balance configuration
	balance_config = load("res://resources/configs/game_balance_default.tres")
	if not balance_config:
		push_error("GameManager: Failed to load game balance config! Creating default...")
		balance_config = GameBalanceConfig.new()
	else:
		print("  ✓ Game balance config loaded")

	# Update match duration from config
	if balance_config:
		match_duration = balance_config.match_duration

	print("GameManager: Configurations loaded successfully")


## Initializes all game systems
func _initialize_systems() -> void:
	# Create combat system
	combat_system = CombatSystem.new()
	combat_system.initialize(self)
	add_child(combat_system)

	# Create movement system
	movement_system = MovementSystem.new()
	movement_system.initialize(self)
	add_child(movement_system)

	# Create targeting system
	targeting_system = TargetingSystem.new()
	targeting_system.initialize(self)
	add_child(targeting_system)

	print("Game systems initialized")


## Initializes progression systems
func _initialize_progression_systems() -> void:
	# Create player profile
	player_profile = PlayerProfile.new()
	add_child(player_profile)

	# Create trophy system
	trophy_system = TrophySystem.new()
	add_child(trophy_system)

	# Create currency manager
	currency_manager = CurrencyManager.new()
	add_child(currency_manager)

	# Connect trophy system signals
	trophy_system.trophies_changed.connect(_on_trophies_changed)
	trophy_system.arena_changed.connect(_on_arena_changed)
	trophy_system.milestone_reached.connect(_on_trophy_milestone_reached)

	print("Progression systems initialized")


## Initializes object pools
func _initialize_pools() -> void:
	if not enable_object_pooling:
		return

	for pool_name in pool_sizes:
		entity_pools[pool_name] = []
		var pool_size: int = pool_sizes[pool_name]

		# Pre-create entities for the pool
		for i in range(pool_size):
			var entity: Entity = _create_pooled_entity(pool_name)
			entity.is_active = false
			entity.visible = false
			entity_pools[pool_name].append(entity)

	print("Object pools initialized")


## Creates a pooled entity based on type
func _create_pooled_entity(entity_type: String) -> Entity:
	var entity: Entity = Entity.new()
	entity.name = entity_type + "_Pooled"

	# Add components based on entity type
	match entity_type:
		"Unit":
			entity.add_component(HealthComponent.new())
			entity.add_component(AttackComponent.new())
			entity.add_component(MovementComponent.new())
			entity.add_component(TeamComponent.new())
			entity.add_component(ElixirCostComponent.new())

		"Projectile":
			entity.add_component(MovementComponent.new())
			entity.add_component(TeamComponent.new())

		"Effect":
			pass  # Effects might not need components

	add_child(entity)
	return entity


## Main update loop
func _process(delta: float) -> void:
	if current_state != GameState.PLAYING:
		return

	var start_time: float = Time.get_ticks_msec()

	# Update game time
	game_time += delta

	# Check for match end
	if game_time >= match_duration:
		_end_match()
		return

	# Update all systems
	_update_systems(delta)

	# Update performance metrics
	update_time = Time.get_ticks_msec() - start_time
	frame_count += 1


## Updates all game systems
func _update_systems(delta: float) -> void:
	# Get active entities
	var active_entities: Array = []
	for entity in entities:
		if entity.is_active:
			active_entities.append(entity)

	# Process systems in order
	movement_system.process_movement(active_entities, delta)
	combat_system.process_combat(active_entities, delta)


## Starts a new game
func start_game() -> void:
	if current_state == GameState.PLAYING:
		return

	_change_state(GameState.PLAYING)
	game_time = 0.0
	team_scores[0] = 0
	team_scores[1] = 0
	set_process(true)
	game_started.emit()
	print("Game started")


## Pauses the game
func pause_game() -> void:
	if current_state != GameState.PLAYING:
		return

	_change_state(GameState.PAUSED)
	set_process(false)
	print("Game paused")


## Resumes the game
func resume_game() -> void:
	if current_state != GameState.PAUSED:
		return

	_change_state(GameState.PLAYING)
	set_process(true)
	print("Game resumed")


## Ends the current match
func _end_match() -> void:
	_change_state(GameState.GAME_OVER)
	set_process(false)

	# Determine winner
	var winning_team: int = -1
	if team_scores[0] > team_scores[1]:
		winning_team = 0
	elif team_scores[1] > team_scores[0]:
		winning_team = 1

	game_ended.emit(winning_team)
	print("Game ended. Winner: Team " + str(winning_team))


## Changes the game state
func _change_state(new_state: GameState) -> void:
	var old_state: GameState = current_state
	current_state = new_state
	game_state_changed.emit(current_state, old_state)


## Spawns an entity from the pool or creates a new one
func spawn_entity(entity_type: String, position: Vector2, team: int = 0) -> Entity:
	var entity: Entity = null

	# Try to get from pool first
	if enable_object_pooling and entity_pools.has(entity_type):
		var pool: Array = entity_pools[entity_type]
		for pooled_entity in pool:
			if not pooled_entity.is_active:
				entity = pooled_entity
				break

	# Create new entity if pool is exhausted or not available
	if not entity:
		if entity_count >= max_entities:
			push_warning("Maximum entity limit reached")
			return null

		entity = _create_entity(entity_type)

	# Configure and activate entity
	entity.global_position = position
	entity.is_active = true
	entity.visible = true

	# Set team
	var team_comp: TeamComponent = entity.get_component("TeamComponent") as TeamComponent
	if team_comp:
		team_comp.set_team(team)

	# Reset all components
	for component in entity.get_all_components():
		component.reset()

	# Add to active entities
	if not entities.has(entity):
		entities.append(entity)
		entity_count += 1

	entity_spawned.emit(entity)
	return entity


## Creates a new entity based on type
func _create_entity(entity_type: String) -> Entity:
	var entity: Entity = _create_pooled_entity(entity_type)
	return entity


## Destroys an entity and returns it to the pool
func destroy_entity(entity: Entity) -> void:
	if not entity:
		return

	entity.is_active = false
	entity.visible = false

	# Remove from active entities
	var index: int = entities.find(entity)
	if index >= 0:
		entities.remove_at(index)
		entity_count -= 1

	entity_destroyed.emit(entity)

	# Return to pool if using pooling
	if enable_object_pooling:
		for pool_name in entity_pools:
			var pool: Array = entity_pools[pool_name]
			if entity in pool:
				# Entity is already in pool, just deactivated
				return

	# Otherwise free the entity
	if not enable_object_pooling:
		entity.queue_free()


## Gets all active entities
func get_all_entities() -> Array:
	var active: Array = []
	for entity in entities:
		if entity.is_active:
			active.append(entity)
	return active


## Gets all entities on a specific team
func get_team_entities(team_id: int) -> Array[Entity]:
	var team_entities: Array[Entity] = []

	for entity in entities:
		if not entity.is_active:
			continue

		var team_comp: TeamComponent = entity.get_component("TeamComponent") as TeamComponent
		if team_comp and team_comp.team_id == team_id:
			team_entities.append(entity)

	return team_entities


## Gets all entities within a radius of a position
func get_entities_in_radius(position: Vector2, radius: float) -> Array[Entity]:
	var nearby_entities: Array[Entity] = []

	for entity in entities:
		if not entity.is_active:
			continue

		var distance: float = entity.global_position.distance_to(position)
		if distance <= radius:
			nearby_entities.append(entity)

	return nearby_entities


## Adds score to a team
func add_team_score(team_id: int, points: int) -> void:
	if team_scores.has(team_id):
		team_scores[team_id] += points


## Gets the current score for a team
func get_team_score(team_id: int) -> int:
	if team_scores.has(team_id):
		return team_scores[team_id]
	return 0


## Gets performance statistics
func get_performance_stats() -> Dictionary:
	var active_entity_count: int = 0
	for entity in entities:
		if entity.is_active:
			active_entity_count += 1

	return {
		"total_entities": entity_count,
		"active_entities": active_entity_count,
		"update_time_ms": update_time,
		"frame_count": frame_count,
		"game_time": game_time,
		"combat_stats": combat_system.get_statistics(),
		"movement_stats": movement_system.get_statistics(),
		"targeting_stats": targeting_system.get_statistics()
	}


## Clears all entities from the game
func clear_all_entities() -> void:
	for entity in entities:
		if enable_object_pooling:
			entity.is_active = false
			entity.visible = false
		else:
			entity.queue_free()

	entities.clear()
	entity_count = 0


## Resets the game manager
func reset() -> void:
	clear_all_entities()
	game_time = 0.0
	team_scores[0] = 0
	team_scores[1] = 0
	frame_count = 0
	combat_system.reset_statistics()
	movement_system.reset_statistics()
	targeting_system.reset_statistics()
	_change_state(GameState.MENU)
	set_process(false)


## Get battlefield configuration (globally accessible)
func get_battlefield_config() -> BattlefieldConfig:
	return battlefield_config


## Get game balance configuration (globally accessible)
func get_balance_config() -> GameBalanceConfig:
	return balance_config


## Process battle results and award trophies
func process_battle_result(result: String, opponent_trophies: int) -> void:
	if not trophy_system:
		push_error("Trophy system not initialized")
		return

	# Calculate and apply trophy change
	var trophy_change = trophy_system.record_battle_result(result, opponent_trophies)

	print("Battle result: %s | Trophy change: %+d | New total: %d" % [
		result.to_upper(),
		trophy_change,
		trophy_system.trophy_data.current_trophies
	])

	# Award gold based on result and arena
	if currency_manager:
		var base_gold = 0
		match result.to_lower():
			"win":
				base_gold = 100
			"draw":
				base_gold = 30
			"loss":
				base_gold = 10

		# Apply arena multiplier
		var arena_multiplier = trophy_system.get_arena_rewards_multiplier()
		var final_gold = int(base_gold * arena_multiplier)

		currency_manager.add_gold(
			final_gold,
			CurrencyManager.TransactionType.BATTLE_REWARD,
			"Battle %s reward" % result
		)

		print("  Gold reward: %d (base: %d x %.1fx arena bonus)" % [
			final_gold,
			base_gold,
			arena_multiplier
		])


## Trophy changed handler
func _on_trophies_changed(new_count: int, change: int) -> void:
	print("Trophies updated: %+d (Total: %d)" % [change, new_count])


## Arena changed handler - show celebration/notification
func _on_arena_changed(new_arena: int, arena_name: String) -> void:
	print("=================================")
	print("ARENA UNLOCKED: %s" % arena_name)
	print("=================================")

	# Check if we progressed or dropped
	var current_arena = trophy_system.trophy_data.current_arena
	if new_arena > current_arena:
		print("Congratulations! You've advanced to a new arena!")
	else:
		print("You've dropped to a lower arena.")

	# Award unlock bonus for progressing to new arena
	if currency_manager and new_arena > current_arena:
		var unlock_bonus = new_arena * 50  # 50 gold per arena level
		currency_manager.add_gold(
			unlock_bonus,
			CurrencyManager.TransactionType.ACHIEVEMENT_REWARD,
			"Unlocked %s" % arena_name
		)
		print("  Arena unlock bonus: %d gold" % unlock_bonus)


## Trophy milestone reached handler
func _on_trophy_milestone_reached(milestone: Dictionary) -> void:
	print("=================================")
	print("TROPHY MILESTONE REACHED!")
	print("  Trophies: %d" % milestone.trophies)
	print("  Gold reward: %d" % milestone.reward_gold)
	print("  Gem reward: %d" % milestone.reward_gems)
	print("=================================")

	# Auto-claim milestone rewards
	if currency_manager and trophy_system:
		trophy_system.claim_milestone(milestone.trophies, currency_manager)
		print("Milestone rewards claimed automatically!")
