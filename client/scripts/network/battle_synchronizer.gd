extends Node

# Handles synchronization of battle state with server
class_name BattleSynchronizer

signal unit_spawned(unit_data: Dictionary)
signal tower_built(tower_data: Dictionary)
signal castle_damaged(player_id: String, damage: int, new_health: int)
signal resource_updated(player_id: String, resources: Dictionary)
signal battle_ended(winner_id: String)

const INTERPOLATION_SPEED := 10.0
const STATE_BUFFER_SIZE := 10
const MAX_PREDICTION_FRAMES := 5

var _network_manager: NetworkManager
var _current_state: Dictionary = {}
var _state_buffer := []
var _last_confirmed_tick := 0
var _predicted_state: Dictionary = {}
var _unit_positions := {}  # Track unit positions for interpolation
var _pending_spawns := []
var _reconciling := false

# References to game systems
var battle_scene: Node
var unit_manager: Node
var tower_manager: Node
var resource_manager: Node

func _ready() -> void:
	_network_manager = get_node("/root/NetworkManager")
	if _network_manager:
		_network_manager.state_received.connect(_on_state_received)
		_network_manager.message_received.connect(_on_message_received)
	else:
		push_error("NetworkManager not found!")

func initialize(battle: Node, units: Node, towers: Node, resources: Node) -> void:
	battle_scene = battle
	unit_manager = units
	tower_manager = towers
	resource_manager = resources
	print("Battle synchronizer initialized")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(battle_scene):
		return

	# Interpolate unit positions
	_interpolate_units(delta)

	# Process pending spawns
	_process_pending_spawns()

func _on_state_received(state: Dictionary) -> void:
	# Server state is authoritative
	var tick = state.get("tick", 0)

	if tick <= _last_confirmed_tick:
		return  # Old state, ignore

	_last_confirmed_tick = tick
	_current_state = state

	# Add to buffer for interpolation
	_state_buffer.append(state)
	if _state_buffer.size() > STATE_BUFFER_SIZE:
		_state_buffer.pop_front()

	# Reconcile with server state
	_reconcile_state(state)

func _reconcile_state(server_state: Dictionary) -> void:
	_reconciling = true

	# Update game state
	_sync_game_state(server_state.get("gameState", {}))

	# Sync units
	_sync_units(server_state.get("units", {}))

	# Sync towers
	_sync_towers(server_state.get("towers", {}))

	# Sync resources
	_sync_resources(server_state.get("resources", {}))

	# Sync castles
	_sync_castles(server_state.get("castles", {}))

	_reconciling = false

func _sync_game_state(game_state: Dictionary) -> void:
	if game_state.is_empty():
		return

	var current_phase = game_state.get("currentPhase", "")
	var time_remaining = game_state.get("timeRemaining", 0)

	# Update battle scene with current phase
	if battle_scene and battle_scene.has_method("update_phase"):
		battle_scene.update_phase(current_phase, time_remaining)

func _sync_units(units: Dictionary) -> void:
	if not unit_manager:
		return

	# Dictionary of unit_id -> unit_data from server
	var server_units = {}

	for player_id in units:
		var player_units = units[player_id]
		if player_units is Array:
			for unit_data in player_units:
				var unit_id = unit_data.get("id", "")
				if unit_id != "":
					server_units[unit_id] = unit_data
					server_units[unit_id]["owner"] = player_id

	# Remove units that don't exist on server
	if unit_manager.has_method("get_all_units"):
		var local_units = unit_manager.get_all_units()
		for unit in local_units:
			if unit.has_method("get_unit_id"):
				var unit_id = unit.get_unit_id()
				if not server_units.has(unit_id):
					# Unit doesn't exist on server, remove it
					if unit_manager.has_method("remove_unit"):
						unit_manager.remove_unit(unit_id)

	# Update or spawn units from server
	for unit_id in server_units:
		var unit_data = server_units[unit_id]
		_sync_unit(unit_id, unit_data)

func _sync_unit(unit_id: String, unit_data: Dictionary) -> void:
	if not unit_manager:
		return

	# Check if unit exists locally
	var existing_unit = null
	if unit_manager.has_method("get_unit"):
		existing_unit = unit_manager.get_unit(unit_id)

	if existing_unit:
		# Update existing unit
		_update_unit_state(existing_unit, unit_data)
	else:
		# Spawn new unit
		_spawn_unit_from_server(unit_data)

func _update_unit_state(unit: Node, unit_data: Dictionary) -> void:
	if not is_instance_valid(unit):
		return

	var server_pos = unit_data.get("position", {})
	if not server_pos.is_empty():
		var target_position = Vector2(server_pos.get("x", 0), server_pos.get("y", 0))

		# Store for interpolation
		var unit_id = unit_data.get("id", "")
		if not _unit_positions.has(unit_id):
			_unit_positions[unit_id] = {}

		_unit_positions[unit_id]["target"] = target_position
		_unit_positions[unit_id]["current"] = unit.position if unit.has_method("position") else Vector2.ZERO
		_unit_positions[unit_id]["unit"] = unit

	# Update unit health
	if unit.has_method("set_health"):
		unit.set_health(unit_data.get("health", 100))

	# Update unit state
	if unit.has_method("set_state"):
		unit.set_state(unit_data.get("state", "idle"))

func _spawn_unit_from_server(unit_data: Dictionary) -> void:
	# Add to pending spawns to be processed in next frame
	_pending_spawns.append(unit_data)

func _process_pending_spawns() -> void:
	for unit_data in _pending_spawns:
		if unit_manager and unit_manager.has_method("spawn_unit_from_data"):
			unit_manager.spawn_unit_from_data(unit_data)
			unit_spawned.emit(unit_data)

	_pending_spawns.clear()

func _interpolate_units(delta: float) -> void:
	for unit_id in _unit_positions:
		var pos_data = _unit_positions[unit_id]
		var unit = pos_data.get("unit")

		if not is_instance_valid(unit):
			_unit_positions.erase(unit_id)
			continue

		var current = pos_data.get("current", Vector2.ZERO)
		var target = pos_data.get("target", Vector2.ZERO)

		# Smooth interpolation
		var new_position = current.lerp(target, INTERPOLATION_SPEED * delta)
		if unit.has_method("set_position"):
			unit.set_position(new_position)
		else:
			unit.position = new_position

		pos_data["current"] = new_position

func _sync_towers(towers: Dictionary) -> void:
	if not tower_manager:
		return

	for player_id in towers:
		var player_towers = towers[player_id]
		if player_towers is Array:
			for tower_data in player_towers:
				_sync_tower(player_id, tower_data)

func _sync_tower(player_id: String, tower_data: Dictionary) -> void:
	if not tower_manager:
		return

	var tower_id = tower_data.get("id", "")
	if tower_id == "":
		return

	# Check if tower exists locally
	if tower_manager.has_method("get_tower"):
		var existing_tower = tower_manager.get_tower(tower_id)

		if not existing_tower:
			# Spawn new tower
			if tower_manager.has_method("spawn_tower_from_data"):
				tower_data["owner"] = player_id
				tower_manager.spawn_tower_from_data(tower_data)
				tower_built.emit(tower_data)
		else:
			# Update existing tower
			if existing_tower.has_method("update_from_data"):
				existing_tower.update_from_data(tower_data)

func _sync_resources(resources: Dictionary) -> void:
	if not resource_manager:
		return

	for player_id in resources:
		var player_resources = resources[player_id]
		if resource_manager.has_method("set_player_resources"):
			resource_manager.set_player_resources(player_id, player_resources)
			resource_updated.emit(player_id, player_resources)

func _sync_castles(castles: Dictionary) -> void:
	if not battle_scene:
		return

	for player_id in castles:
		var castle_data = castles[player_id]
		var health = castle_data.get("health", 100)
		var max_health = castle_data.get("maxHealth", 100)

		if battle_scene.has_method("update_castle_health"):
			battle_scene.update_castle_health(player_id, health, max_health)

		# Check for damage
		var previous_health = _get_previous_castle_health(player_id)
		if previous_health > health:
			castle_damaged.emit(player_id, previous_health - health, health)

func _get_previous_castle_health(player_id: String) -> int:
	# Get from previous state in buffer
	if _state_buffer.size() >= 2:
		var prev_state = _state_buffer[-2]
		var castles = prev_state.get("castles", {})
		var castle = castles.get(player_id, {})
		return castle.get("health", 100)
	return 100

func _on_message_received(type: String, data: Dictionary) -> void:
	match type:
		"unitSpawned":
			# Individual unit spawn notification
			if not _reconciling:
				_spawn_unit_from_server(data)

		"towerBuilt":
			# Individual tower build notification
			if not _reconciling:
				var player_id = data.get("playerId", "")
				_sync_tower(player_id, data)

		"battleEnd":
			var winner = data.get("winner", "")
			battle_ended.emit(winner)

# Client-side prediction helpers
func predict_unit_spawn(unit_type: String, lane: int, player_id: String) -> void:
	# Create predicted unit locally (will be reconciled with server)
	var predicted_unit = {
		"id": "pred_" + str(Time.get_unix_time_from_system()),
		"type": unit_type,
		"lane": lane,
		"owner": player_id,
		"position": {"x": 0, "y": lane * 100},  # Approximate starting position
		"health": 100,
		"predicted": true
	}

	if unit_manager and unit_manager.has_method("spawn_predicted_unit"):
		unit_manager.spawn_predicted_unit(predicted_unit)

func predict_tower_build(tower_type: String, position: Vector2, player_id: String) -> void:
	# Create predicted tower locally
	var predicted_tower = {
		"id": "pred_" + str(Time.get_unix_time_from_system()),
		"type": tower_type,
		"position": {"x": position.x, "y": position.y},
		"owner": player_id,
		"predicted": true
	}

	if tower_manager and tower_manager.has_method("spawn_predicted_tower"):
		tower_manager.spawn_predicted_tower(predicted_tower)

func get_current_tick() -> int:
	return _last_confirmed_tick

func get_server_state() -> Dictionary:
	return _current_state

func is_reconciling() -> bool:
	return _reconciling