extends Control

# Example script showing how to use the networking system
# Attach this to a UI scene to test the network components

@onready var network_manager = get_node("/root/NetworkManager")
@onready var battle_sync = get_node("/root/BattleSynchronizer")
@onready var command_buffer = get_node("/root/CommandBuffer")
@onready var matchmaking = get_node("/root/MatchmakingClient")

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var connect_button: Button = $VBoxContainer/ConnectButton
@onready var matchmaking_button: Button = $VBoxContainer/MatchmakingButton
@onready var spawn_unit_button: Button = $VBoxContainer/SpawnUnitButton
@onready var build_tower_button: Button = $VBoxContainer/BuildTowerButton

var is_connected := false
var in_match := false

func _ready() -> void:
	# Connect network signals
	network_manager.connected.connect(_on_connected)
	network_manager.disconnected.connect(_on_disconnected)
	network_manager.connection_error.connect(_on_connection_error)
	network_manager.state_received.connect(_on_state_received)

	# Connect matchmaking signals
	matchmaking.queue_joined.connect(_on_queue_joined)
	matchmaking.queue_updated.connect(_on_queue_updated)
	matchmaking.match_found.connect(_on_match_found)
	matchmaking.match_ready.connect(_on_match_ready)
	matchmaking.match_cancelled.connect(_on_match_cancelled)

	# Connect battle sync signals
	battle_sync.unit_spawned.connect(_on_unit_spawned)
	battle_sync.tower_built.connect(_on_tower_built)
	battle_sync.battle_ended.connect(_on_battle_ended)

	# Connect command buffer signals
	command_buffer.command_acknowledged.connect(_on_command_acknowledged)
	command_buffer.command_rejected.connect(_on_command_rejected)

	# Setup UI
	connect_button.pressed.connect(_on_connect_pressed)
	matchmaking_button.pressed.connect(_on_matchmaking_pressed)
	spawn_unit_button.pressed.connect(_on_spawn_unit_pressed)
	build_tower_button.pressed.connect(_on_build_tower_pressed)

	_update_ui()

func _update_ui() -> void:
	if not is_connected:
		status_label.text = "Disconnected"
		connect_button.text = "Connect"
		matchmaking_button.disabled = true
		spawn_unit_button.disabled = true
		build_tower_button.disabled = true
	else:
		var state = network_manager.get_connection_state()
		match state:
			NetworkManager.ConnectionState.CONNECTING:
				status_label.text = "Connecting..."
			NetworkManager.ConnectionState.CONNECTED:
				status_label.text = "Connected (Player: " + network_manager.get_player_id() + ")"
			NetworkManager.ConnectionState.RECONNECTING:
				status_label.text = "Reconnecting..."

		connect_button.text = "Disconnect"
		matchmaking_button.disabled = false
		spawn_unit_button.disabled = not in_match
		build_tower_button.disabled = not in_match

	# Update matchmaking button
	if matchmaking.is_searching():
		matchmaking_button.text = "Cancel Search"
	elif matchmaking.is_in_match():
		matchmaking_button.text = "Leave Match"
	else:
		matchmaking_button.text = "Find Match"

# Connection handlers
func _on_connect_pressed() -> void:
	if not is_connected:
		network_manager.connect_to_server()
		status_label.text = "Connecting..."
	else:
		network_manager.disconnect_from_server()

func _on_connected() -> void:
	is_connected = true
	_update_ui()
	print("Successfully connected to server")

func _on_disconnected() -> void:
	is_connected = false
	in_match = false
	_update_ui()
	print("Disconnected from server")

func _on_connection_error(error: String) -> void:
	status_label.text = "Error: " + error
	print("Connection error: " + error)

# Matchmaking handlers
func _on_matchmaking_pressed() -> void:
	if matchmaking.is_searching():
		matchmaking.leave_queue()
	elif matchmaking.is_in_match():
		matchmaking.leave_match()
		in_match = false
		_update_ui()
	else:
		matchmaking.join_queue("1v1")

func _on_queue_joined(position: int) -> void:
	status_label.text = "In queue - Position: " + str(position)

func _on_queue_updated(position: int, total: int) -> void:
	status_label.text = "Queue position: " + str(position) + "/" + str(total)
	var search_time = matchmaking.get_search_time()
	status_label.text += " (" + str(int(search_time)) + "s)"

func _on_match_found(room_id: String, opponent: Dictionary) -> void:
	status_label.text = "Match found! Opponent: " + opponent.get("name", "Unknown")
	print("Match found in room: " + room_id)

	# Auto-accept for this example
	await get_tree().create_timer(1.0).timeout
	matchmaking.accept_match()

func _on_match_ready(initial_state: Dictionary) -> void:
	in_match = true
	status_label.text = "In match - Room: " + matchmaking.get_room_id()
	_update_ui()

	# Initialize battle synchronizer with game references
	# In a real game, you'd pass actual node references here
	battle_sync.initialize(null, null, null, null)

	print("Match ready! Initial state: " + str(initial_state))

func _on_match_cancelled(reason: String) -> void:
	status_label.text = "Match cancelled: " + reason
	in_match = false
	_update_ui()

# Game command handlers
func _on_spawn_unit_pressed() -> void:
	if not in_match:
		return

	# Queue a spawn unit command
	var command_id = command_buffer.queue_command("spawnUnit", {
		"unitType": "warrior",
		"lane": randi() % 3  # Random lane 0-2
	})

	print("Spawning unit - Command ID: " + command_id)

func _on_build_tower_pressed() -> void:
	if not in_match:
		return

	# Queue a build tower command
	var random_pos = Vector2(randf() * 800, randf() * 600)
	var command_id = command_buffer.queue_command("buildTower", {
		"towerType": "archer",
		"position": {"x": random_pos.x, "y": random_pos.y}
	})

	print("Building tower - Command ID: " + command_id)

# State and event handlers
func _on_state_received(state: Dictionary) -> void:
	# State updates are handled by BattleSynchronizer
	# This is just for debugging
	var tick = state.get("tick", 0)
	print("Received state update - Tick: " + str(tick))

func _on_unit_spawned(unit_data: Dictionary) -> void:
	print("Unit spawned: " + str(unit_data.get("type", "unknown")) + " at lane " + str(unit_data.get("lane", 0)))

func _on_tower_built(tower_data: Dictionary) -> void:
	var pos = tower_data.get("position", {})
	print("Tower built: " + str(tower_data.get("type", "unknown")) + " at (" + str(pos.get("x", 0)) + ", " + str(pos.get("y", 0)) + ")")

func _on_battle_ended(winner_id: String) -> void:
	in_match = false
	_update_ui()
	if winner_id == network_manager.get_player_id():
		status_label.text = "Victory!"
	else:
		status_label.text = "Defeat"
	print("Battle ended. Winner: " + winner_id)

func _on_command_acknowledged(command_id: String) -> void:
	print("Command acknowledged: " + command_id)

func _on_command_rejected(command_id: String, reason: String) -> void:
	print("Command rejected: " + command_id + " - Reason: " + reason)