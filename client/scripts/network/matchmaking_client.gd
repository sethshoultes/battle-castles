extends Node

# Handles matchmaking queue and room management
class_name MatchmakingClient

signal queue_joined(position: int)
signal queue_updated(position: int, total: int)
signal queue_left()
signal match_found(room_id: String, opponent: Dictionary)
signal match_ready(initial_state: Dictionary)
signal match_cancelled(reason: String)
signal search_started()
signal search_stopped()

enum MatchmakingState {
	IDLE,
	SEARCHING,
	MATCH_FOUND,
	PREPARING,
	IN_MATCH
}

var _network_manager: NetworkManager
var _current_state := MatchmakingState.IDLE
var _current_room_id := ""
var _opponent_data := {}
var _queue_position := 0
var _search_start_time := 0.0
var _update_timer: Timer
var _timeout_timer: Timer

const QUEUE_UPDATE_INTERVAL := 2.0
const SEARCH_TIMEOUT := 300.0  # 5 minutes
const PREPARATION_TIMEOUT := 30.0  # 30 seconds to prepare after match found

func _ready() -> void:
	_network_manager = get_node("/root/NetworkManager")
	if _network_manager:
		_network_manager.message_received.connect(_on_message_received)
		_network_manager.match_found.connect(_on_match_found)
		_network_manager.game_started.connect(_on_game_started)
		_network_manager.disconnected.connect(_on_disconnected)
	else:
		push_error("NetworkManager not found!")

	_setup_timers()

func _setup_timers() -> void:
	# Timer for requesting queue updates
	_update_timer = Timer.new()
	_update_timer.wait_time = QUEUE_UPDATE_INTERVAL
	_update_timer.timeout.connect(_request_queue_update)
	add_child(_update_timer)

	# Timeout timer
	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.timeout.connect(_on_search_timeout)
	add_child(_timeout_timer)

func join_queue(game_mode: String = "1v1", preferences: Dictionary = {}) -> bool:
	if _current_state != MatchmakingState.IDLE:
		push_warning("Already in matchmaking process")
		return false

	if not _network_manager.is_connected():
		push_error("Not connected to server")
		return false

	var message = {
		"type": "joinQueue",
		"data": {
			"gameMode": game_mode,
			"preferences": preferences,
			"playerId": _network_manager.get_player_id()
		}
	}

	if _network_manager.send_message(message):
		_current_state = MatchmakingState.SEARCHING
		_search_start_time = Time.get_unix_time_from_system()
		_update_timer.start()
		_timeout_timer.start(SEARCH_TIMEOUT)
		search_started.emit()
		print("Joined matchmaking queue for mode: " + game_mode)
		return true

	return false

func leave_queue() -> bool:
	if _current_state != MatchmakingState.SEARCHING:
		return false

	var message = {
		"type": "leaveQueue",
		"data": {
			"playerId": _network_manager.get_player_id()
		}
	}

	if _network_manager.send_message(message):
		_stop_searching()
		queue_left.emit()
		print("Left matchmaking queue")
		return true

	return false

func accept_match() -> bool:
	if _current_state != MatchmakingState.MATCH_FOUND:
		push_warning("No match to accept")
		return false

	var message = {
		"type": "acceptMatch",
		"data": {
			"roomId": _current_room_id,
			"playerId": _network_manager.get_player_id()
		}
	}

	if _network_manager.send_message(message):
		_current_state = MatchmakingState.PREPARING
		print("Accepted match in room: " + _current_room_id)
		return true

	return false

func decline_match() -> bool:
	if _current_state != MatchmakingState.MATCH_FOUND:
		return false

	var message = {
		"type": "declineMatch",
		"data": {
			"roomId": _current_room_id,
			"playerId": _network_manager.get_player_id()
		}
	}

	if _network_manager.send_message(message):
		_reset_matchmaking()
		match_cancelled.emit("Player declined")
		return true

	return false

func request_rematch() -> bool:
	if _current_state != MatchmakingState.IN_MATCH:
		return false

	var message = {
		"type": "requestRematch",
		"data": {
			"roomId": _current_room_id,
			"playerId": _network_manager.get_player_id()
		}
	}

	return _network_manager.send_message(message)

func leave_match() -> bool:
	if _current_state != MatchmakingState.IN_MATCH:
		return false

	var message = {
		"type": "leaveMatch",
		"data": {
			"roomId": _current_room_id,
			"playerId": _network_manager.get_player_id()
		}
	}

	if _network_manager.send_message(message):
		_reset_matchmaking()
		return true

	return false

func _request_queue_update() -> void:
	if _current_state != MatchmakingState.SEARCHING:
		return

	var message = {
		"type": "queueStatus",
		"data": {
			"playerId": _network_manager.get_player_id()
		}
	}

	_network_manager.send_message(message)

func _on_message_received(type: String, data: Dictionary) -> void:
	match type:
		"queueJoined":
			_handle_queue_joined(data)

		"queueUpdate":
			_handle_queue_update(data)

		"queueLeft":
			_handle_queue_left(data)

		"matchDeclined":
			_handle_match_declined(data)

		"matchCancelled":
			_handle_match_cancelled(data)

		"opponentDisconnected":
			_handle_opponent_disconnected(data)

		"rematchRequested":
			_handle_rematch_requested(data)

		"rematchAccepted":
			_handle_rematch_accepted(data)

func _handle_queue_joined(data: Dictionary) -> void:
	_queue_position = data.get("position", 0)
	queue_joined.emit(_queue_position)
	print("Queue joined. Position: " + str(_queue_position))

func _handle_queue_update(data: Dictionary) -> void:
	_queue_position = data.get("position", 0)
	var total_in_queue = data.get("total", 0)
	queue_updated.emit(_queue_position, total_in_queue)

func _handle_queue_left(data: Dictionary) -> void:
	_stop_searching()
	queue_left.emit()

func _on_match_found(room_id: String, players: Array) -> void:
	_current_state = MatchmakingState.MATCH_FOUND
	_current_room_id = room_id
	_update_timer.stop()
	_timeout_timer.stop()

	# Find opponent data
	var my_id = _network_manager.get_player_id()
	for player in players:
		if player.get("id", "") != my_id:
			_opponent_data = player
			break

	# Start preparation timeout
	_timeout_timer.start(PREPARATION_TIMEOUT)

	match_found.emit(room_id, _opponent_data)
	print("Match found! Room: " + room_id + ", Opponent: " + str(_opponent_data.get("name", "Unknown")))

func _on_game_started(initial_state: Dictionary) -> void:
	_current_state = MatchmakingState.IN_MATCH
	_timeout_timer.stop()
	match_ready.emit(initial_state)
	print("Match started!")

func _handle_match_declined(data: Dictionary) -> void:
	var decliner = data.get("playerId", "")
	if decliner == _network_manager.get_player_id():
		return  # We declined

	# Opponent declined
	_reset_matchmaking()
	match_cancelled.emit("Opponent declined the match")

	# Auto-rejoin queue
	join_queue()

func _handle_match_cancelled(data: Dictionary) -> void:
	var reason = data.get("reason", "Unknown reason")
	_reset_matchmaking()
	match_cancelled.emit(reason)

func _handle_opponent_disconnected(data: Dictionary) -> void:
	if _current_state == MatchmakingState.IN_MATCH:
		# Handle in-game disconnection
		push_warning("Opponent disconnected during match")
		# Game should handle this
	else:
		# Pre-game disconnection
		_reset_matchmaking()
		match_cancelled.emit("Opponent disconnected")

func _handle_rematch_requested(data: Dictionary) -> void:
	var requester = data.get("playerId", "")
	if requester != _network_manager.get_player_id():
		# Opponent requested rematch
		print("Opponent requested a rematch")
		# Could emit signal for UI to handle

func _handle_rematch_accepted(data: Dictionary) -> void:
	print("Rematch accepted! Starting new game...")
	_current_state = MatchmakingState.PREPARING

func _on_search_timeout() -> void:
	if _current_state == MatchmakingState.SEARCHING:
		leave_queue()
		match_cancelled.emit("Search timeout")
	elif _current_state == MatchmakingState.MATCH_FOUND:
		decline_match()
		match_cancelled.emit("Preparation timeout")

func _on_disconnected() -> void:
	if _current_state != MatchmakingState.IDLE:
		_reset_matchmaking()
		match_cancelled.emit("Connection lost")

func _stop_searching() -> void:
	_current_state = MatchmakingState.IDLE
	_update_timer.stop()
	_timeout_timer.stop()
	_queue_position = 0
	search_stopped.emit()

func _reset_matchmaking() -> void:
	_stop_searching()
	_current_room_id = ""
	_opponent_data = {}

func get_state() -> MatchmakingState:
	return _current_state

func is_searching() -> bool:
	return _current_state == MatchmakingState.SEARCHING

func is_in_match() -> bool:
	return _current_state == MatchmakingState.IN_MATCH

func get_queue_position() -> int:
	return _queue_position

func get_search_time() -> float:
	if _current_state == MatchmakingState.SEARCHING:
		return Time.get_unix_time_from_system() - _search_start_time
	return 0.0

func get_room_id() -> String:
	return _current_room_id

func get_opponent_data() -> Dictionary:
	return _opponent_data