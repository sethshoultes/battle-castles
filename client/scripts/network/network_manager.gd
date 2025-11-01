extends Node

# Singleton for managing WebSocket connection to game server
class_name NetworkManager

signal connected()
signal disconnected()
signal connection_error(error: String)
signal state_received(state: Dictionary)
signal message_received(type: String, data: Dictionary)
signal match_found(room_id: String, players: Array)
signal game_started(initial_state: Dictionary)

enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	RECONNECTING
}

const SERVER_URL := "ws://localhost:3001"
const MAX_RECONNECT_ATTEMPTS := 5
const INITIAL_RECONNECT_DELAY := 1.0
const MAX_RECONNECT_DELAY := 30.0
const HEARTBEAT_INTERVAL := 5.0

var _websocket: WebSocketPeer
var _connection_state := ConnectionState.DISCONNECTED
var _reconnect_attempts := 0
var _reconnect_timer: Timer
var _heartbeat_timer: Timer
var _reconnect_delay := INITIAL_RECONNECT_DELAY
var _player_id: String = ""
var _room_id: String = ""
var _pending_commands := []
var _last_received_state_tick := 0

func _ready() -> void:
	set_process(false)
	_setup_timers()

func _setup_timers() -> void:
	# Reconnection timer
	_reconnect_timer = Timer.new()
	_reconnect_timer.one_shot = true
	_reconnect_timer.timeout.connect(_attempt_reconnect)
	add_child(_reconnect_timer)

	# Heartbeat timer
	_heartbeat_timer = Timer.new()
	_heartbeat_timer.wait_time = HEARTBEAT_INTERVAL
	_heartbeat_timer.timeout.connect(_send_heartbeat)
	add_child(_heartbeat_timer)

func connect_to_server() -> void:
	if _connection_state != ConnectionState.DISCONNECTED:
		push_warning("Already connected or connecting")
		return

	_connection_state = ConnectionState.CONNECTING
	_websocket = WebSocketPeer.new()

	var error = _websocket.connect_to_url(SERVER_URL)
	if error != OK:
		push_error("Failed to initiate connection: " + str(error))
		_handle_connection_error("Failed to connect to server")
		return

	set_process(true)
	print("Connecting to server at: " + SERVER_URL)

func disconnect_from_server() -> void:
	if _websocket:
		_websocket.close()
	_cleanup_connection()
	_connection_state = ConnectionState.DISCONNECTED
	disconnected.emit()

func _process(_delta: float) -> void:
	if not _websocket:
		return

	_websocket.poll()

	var state = _websocket.get_ready_state()

	match state:
		WebSocketPeer.STATE_CONNECTING:
			pass  # Still connecting

		WebSocketPeer.STATE_OPEN:
			if _connection_state == ConnectionState.CONNECTING:
				_on_connected()
			_process_incoming_messages()

		WebSocketPeer.STATE_CLOSING:
			pass  # Closing in progress

		WebSocketPeer.STATE_CLOSED:
			var code = _websocket.get_close_code()
			var reason = _websocket.get_close_reason()
			_handle_disconnection(code, reason)
			set_process(false)

func _on_connected() -> void:
	_connection_state = ConnectionState.CONNECTED
	_reconnect_attempts = 0
	_reconnect_delay = INITIAL_RECONNECT_DELAY
	_heartbeat_timer.start()

	print("Connected to game server")
	connected.emit()

	# Send initial handshake
	var handshake = {
		"type": "handshake",
		"data": {
			"client_version": "1.0.0",
			"timestamp": Time.get_unix_time_from_system()
		}
	}
	send_message(handshake)

func _process_incoming_messages() -> void:
	while _websocket.get_available_packet_count() > 0:
		var packet = _websocket.get_packet()
		if packet.size() > 0:
			var json_string = packet.get_string_from_utf8()
			var json = JSON.new()
			var parse_result = json.parse(json_string)

			if parse_result != OK:
				push_error("Failed to parse server message: " + json.get_error_message())
				continue

			var message = json.data
			if message is Dictionary:
				_handle_server_message(message)

func _handle_server_message(message: Dictionary) -> void:
	if not message.has("type"):
		push_warning("Received message without type")
		return

	var msg_type = message.get("type", "")
	var data = message.get("data", {})

	match msg_type:
		"welcome":
			_player_id = data.get("playerId", "")
			print("Received player ID: " + _player_id)

		"state":
			_handle_state_update(data)

		"matchFound":
			_handle_match_found(data)

		"gameStart":
			_handle_game_start(data)

		"error":
			push_error("Server error: " + str(data.get("message", "Unknown error")))
			connection_error.emit(data.get("message", "Unknown error"))

		"pong":
			pass  # Heartbeat response

		"unitSpawned":
			message_received.emit("unitSpawned", data)

		"towerBuilt":
			message_received.emit("towerBuilt", data)

		"battleEnd":
			message_received.emit("battleEnd", data)

		_:
			message_received.emit(msg_type, data)

func _handle_state_update(state: Dictionary) -> void:
	var tick = state.get("tick", 0)
	if tick > _last_received_state_tick:
		_last_received_state_tick = tick
		state_received.emit(state)

func _handle_match_found(data: Dictionary) -> void:
	_room_id = data.get("roomId", "")
	var players = data.get("players", [])
	print("Match found! Room: " + _room_id)
	match_found.emit(_room_id, players)

func _handle_game_start(data: Dictionary) -> void:
	print("Game starting!")
	game_started.emit(data)

func send_message(message: Dictionary) -> bool:
	if _connection_state != ConnectionState.CONNECTED:
		push_warning("Cannot send message: Not connected")
		_pending_commands.append(message)
		return false

	var json_string = JSON.stringify(message)
	var error = _websocket.send_text(json_string)

	if error != OK:
		push_error("Failed to send message: " + str(error))
		return false

	return true

func send_command(command: Dictionary) -> bool:
	var message = {
		"type": "command",
		"data": command,
		"timestamp": Time.get_unix_time_from_system(),
		"tick": Engine.get_physics_frames()
	}
	return send_message(message)

func _send_heartbeat() -> void:
	send_message({"type": "ping", "timestamp": Time.get_unix_time_from_system()})

func _handle_disconnection(code: int, reason: String) -> void:
	print("Disconnected from server. Code: " + str(code) + ", Reason: " + reason)
	_cleanup_connection()

	if _should_reconnect():
		_start_reconnection()
	else:
		_connection_state = ConnectionState.DISCONNECTED
		disconnected.emit()

func _cleanup_connection() -> void:
	_heartbeat_timer.stop()
	if _websocket:
		_websocket = null
	set_process(false)

func _should_reconnect() -> bool:
	return _reconnect_attempts < MAX_RECONNECT_ATTEMPTS and _connection_state == ConnectionState.CONNECTED

func _start_reconnection() -> void:
	_connection_state = ConnectionState.RECONNECTING
	_reconnect_attempts += 1

	print("Attempting reconnection " + str(_reconnect_attempts) + "/" + str(MAX_RECONNECT_ATTEMPTS) + " in " + str(_reconnect_delay) + " seconds")

	_reconnect_timer.wait_time = _reconnect_delay
	_reconnect_timer.start()

	# Exponential backoff
	_reconnect_delay = min(_reconnect_delay * 2, MAX_RECONNECT_DELAY)

func _attempt_reconnect() -> void:
	print("Reconnecting...")
	_connection_state = ConnectionState.DISCONNECTED
	connect_to_server()

func _handle_connection_error(error: String) -> void:
	push_error("Connection error: " + error)
	connection_error.emit(error)
	_cleanup_connection()

	if _should_reconnect():
		_start_reconnection()
	else:
		_connection_state = ConnectionState.DISCONNECTED
		disconnected.emit()

func get_connection_state() -> ConnectionState:
	return _connection_state

func is_connected() -> bool:
	return _connection_state == ConnectionState.CONNECTED

func get_player_id() -> String:
	return _player_id

func get_room_id() -> String:
	return _room_id

func reset_reconnection() -> void:
	_reconnect_attempts = 0
	_reconnect_delay = INITIAL_RECONNECT_DELAY

# Send any pending commands after reconnection
func _flush_pending_commands() -> void:
	for command in _pending_commands:
		send_message(command)
	_pending_commands.clear()