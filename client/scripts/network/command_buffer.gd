extends Node

# Buffers and manages player commands for network transmission
class_name CommandBuffer

signal command_acknowledged(command_id: String)
signal command_rejected(command_id: String, reason: String)
signal rollback_required(to_tick: int)

const MAX_BUFFER_SIZE := 60  # Store up to 1 second at 60 FPS
const COMMAND_TIMEOUT := 2.0  # Seconds before command is considered lost
const MAX_UNACKNOWLEDGED := 10

var _network_manager: NetworkManager
var _battle_synchronizer: BattleSynchronizer
var _command_buffer := []
var _unacknowledged_commands := {}
var _command_counter := 0
var _local_tick := 0
var _last_acknowledged_tick := 0
var _rollback_state := {}

func _ready() -> void:
	_network_manager = get_node("/root/NetworkManager")
	if _network_manager:
		_network_manager.message_received.connect(_on_message_received)

	# Get battle synchronizer when available
	var sync_node = get_node_or_null("/root/BattleSynchronizer")
	if sync_node:
		_battle_synchronizer = sync_node

func _physics_process(_delta: float) -> void:
	_local_tick += 1
	_process_timeouts()
	_send_buffered_commands()

func queue_command(action: String, params: Dictionary) -> String:
	# Generate unique command ID
	_command_counter += 1
	var command_id = str(_network_manager.get_player_id()) + "_" + str(_command_counter)

	var command = {
		"id": command_id,
		"action": action,
		"params": params,
		"tick": _local_tick,
		"timestamp": Time.get_unix_time_from_system(),
		"predicted": true
	}

	# Add to buffer
	_command_buffer.append(command)

	# Trim buffer if too large
	if _command_buffer.size() > MAX_BUFFER_SIZE:
		_command_buffer.pop_front()

	# Track unacknowledged
	_unacknowledged_commands[command_id] = {
		"command": command,
		"sent_at": Time.get_unix_time_from_system(),
		"retries": 0
	}

	# Apply prediction locally
	_apply_prediction(command)

	return command_id

func _send_buffered_commands() -> void:
	if not _network_manager.is_connected():
		return

	# Check if we have too many unacknowledged commands
	if _unacknowledged_commands.size() >= MAX_UNACKNOWLEDGED:
		return  # Wait for acknowledgments

	# Send commands that haven't been sent yet
	for cmd_data in _command_buffer:
		if cmd_data.get("sent", false):
			continue

		var message = {
			"type": "command",
			"data": {
				"id": cmd_data["id"],
				"action": cmd_data["action"],
				"params": cmd_data["params"],
				"tick": cmd_data["tick"],
				"timestamp": cmd_data["timestamp"]
			}
		}

		if _network_manager.send_message(message):
			cmd_data["sent"] = true

func _apply_prediction(command: Dictionary) -> void:
	if not _battle_synchronizer:
		return

	var action = command.get("action", "")
	var params = command.get("params", {})

	match action:
		"spawnUnit":
			var unit_type = params.get("unitType", "")
			var lane = params.get("lane", 0)
			_battle_synchronizer.predict_unit_spawn(
				unit_type,
				lane,
				_network_manager.get_player_id()
			)

		"buildTower":
			var tower_type = params.get("towerType", "")
			var position = params.get("position", {})
			var pos_vector = Vector2(position.get("x", 0), position.get("y", 0))
			_battle_synchronizer.predict_tower_build(
				tower_type,
				pos_vector,
				_network_manager.get_player_id()
			)

		"useAbility":
			# Predict ability effects
			pass

func _on_message_received(type: String, data: Dictionary) -> void:
	match type:
		"commandAck":
			_handle_acknowledgment(data)

		"commandReject":
			_handle_rejection(data)

		"stateCorrection":
			_handle_state_correction(data)

func _handle_acknowledgment(data: Dictionary) -> void:
	var command_id = data.get("commandId", "")
	var server_tick = data.get("tick", 0)

	if _unacknowledged_commands.has(command_id):
		_unacknowledged_commands.erase(command_id)
		_last_acknowledged_tick = max(_last_acknowledged_tick, server_tick)
		command_acknowledged.emit(command_id)

		# Remove from buffer once acknowledged
		_remove_command_from_buffer(command_id)

func _handle_rejection(data: Dictionary) -> void:
	var command_id = data.get("commandId", "")
	var reason = data.get("reason", "Unknown")

	if _unacknowledged_commands.has(command_id):
		_unacknowledged_commands.erase(command_id)
		command_rejected.emit(command_id, reason)

		# Remove from buffer
		_remove_command_from_buffer(command_id)

		# Rollback prediction if needed
		_rollback_prediction(command_id)

func _handle_state_correction(data: Dictionary) -> void:
	var correction_tick = data.get("tick", 0)
	var state = data.get("state", {})

	# Check if we need to rollback
	if correction_tick < _local_tick:
		print("State correction received. Rolling back from tick " + str(_local_tick) + " to " + str(correction_tick))

		# Store rollback state
		_rollback_state = state

		# Emit rollback signal
		rollback_required.emit(correction_tick)

		# Replay commands from correction point
		_replay_commands_from(correction_tick)

func _rollback_prediction(command_id: String) -> void:
	# Find and remove the predicted effects of this command
	for cmd in _command_buffer:
		if cmd.get("id") == command_id:
			var tick = cmd.get("tick", 0)
			# Trigger rollback from this point
			if _battle_synchronizer:
				rollback_required.emit(tick)
			break

func _replay_commands_from(from_tick: int) -> void:
	# Replay all commands after the rollback point
	var commands_to_replay = []

	for cmd in _command_buffer:
		var tick = cmd.get("tick", 0)
		if tick > from_tick:
			commands_to_replay.append(cmd)

	# Re-apply predictions
	for cmd in commands_to_replay:
		_apply_prediction(cmd)

func _remove_command_from_buffer(command_id: String) -> void:
	var index_to_remove = -1
	for i in range(_command_buffer.size()):
		if _command_buffer[i].get("id") == command_id:
			index_to_remove = i
			break

	if index_to_remove >= 0:
		_command_buffer.remove_at(index_to_remove)

func _process_timeouts() -> void:
	var current_time = Time.get_unix_time_from_system()
	var timed_out = []

	for command_id in _unacknowledged_commands:
		var cmd_data = _unacknowledged_commands[command_id]
		var sent_at = cmd_data.get("sent_at", 0)

		if current_time - sent_at > COMMAND_TIMEOUT:
			if cmd_data.get("retries", 0) < 3:
				# Retry sending
				cmd_data["retries"] += 1
				cmd_data["sent_at"] = current_time
				var command = cmd_data.get("command", {})
				command["sent"] = false  # Mark for resending
			else:
				# Give up on this command
				timed_out.append(command_id)

	# Remove timed out commands
	for command_id in timed_out:
		_unacknowledged_commands.erase(command_id)
		command_rejected.emit(command_id, "Timeout")
		_remove_command_from_buffer(command_id)
		_rollback_prediction(command_id)

func clear_buffer() -> void:
	_command_buffer.clear()
	_unacknowledged_commands.clear()
	_command_counter = 0
	_local_tick = 0
	_last_acknowledged_tick = 0

func get_buffer_size() -> int:
	return _command_buffer.size()

func get_unacknowledged_count() -> int:
	return _unacknowledged_commands.size()

func get_local_tick() -> int:
	return _local_tick

func get_last_acknowledged_tick() -> int:
	return _last_acknowledged_tick

func get_latency_estimate() -> float:
	# Estimate based on round-trip time of acknowledgments
	if _unacknowledged_commands.is_empty():
		return 0.0

	var total_latency = 0.0
	var count = 0

	for cmd_id in _unacknowledged_commands:
		var cmd_data = _unacknowledged_commands[cmd_id]
		var sent_at = cmd_data.get("sent_at", 0)
		total_latency += Time.get_unix_time_from_system() - sent_at
		count += 1

	return total_latency / count if count > 0 else 0.0