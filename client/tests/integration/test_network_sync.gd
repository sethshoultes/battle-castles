extends GdUnitTestSuite

class_name TestNetworkSync

var client1: Node
var client2: Node
var server: Node
var network_manager: Node

func before_each() -> void:
	# Mock network components
	network_manager = Node.new()
	network_manager.latency = 50  # 50ms latency
	network_manager.packet_loss = 0.0  # No packet loss for tests

	client1 = create_mock_client("player1")
	client2 = create_mock_client("player2")
	server = create_mock_server()

func after_each() -> void:
	if client1:
		client1.queue_free()
	if client2:
		client2.queue_free()
	if server:
		server.queue_free()
	if network_manager:
		network_manager.queue_free()

func test_client_server_synchronization() -> void:
	# Client 1 deploys a unit
	var deploy_action = {
		"type": "deploy",
		"player_id": "player1",
		"card": "knight",
		"position": Vector2(500, 400),
		"timestamp": Time.get_ticks_msec()
	}

	# Send to server
	client1.send_action(deploy_action)

	# Server receives and validates
	await simulate_network_delay()
	var received = server.receive_action()
	assert_equal(deploy_action.card, received.card)
	assert_equal(deploy_action.position, received.position)

	# Server broadcasts to all clients
	server.broadcast_action(received)

	# Both clients receive the action
	await simulate_network_delay()
	var client1_received = client1.receive_broadcast()
	var client2_received = client2.receive_broadcast()

	assert_not_null(client1_received)
	assert_not_null(client2_received)
	assert_equal("knight", client2_received.card)

func test_action_prediction_and_rollback() -> void:
	# Client performs action with prediction
	var predicted_action = {
		"type": "deploy",
		"card": "archer",
		"position": Vector2(400, 400),
		"predicted": true,
		"sequence": 1
	}

	client1.predict_action(predicted_action)
	client1.send_action(predicted_action)

	# Client immediately shows predicted result
	assert_true(client1.has_predicted_unit("archer"))

	# Server validates and responds
	await simulate_network_delay()
	var server_response = {
		"sequence": 1,
		"approved": true,
		"server_position": Vector2(400, 400),  # Server agrees with position
		"server_timestamp": Time.get_ticks_msec()
	}

	server.send_validation(server_response)

	# Client receives validation
	await simulate_network_delay()
	client1.receive_validation(server_response)

	# Predicted action was correct, no rollback needed
	assert_true(client1.has_confirmed_unit("archer"))
	assert_false(client1.needs_rollback)

func test_rollback_on_server_rejection() -> void:
	# Client predicts invalid action
	var invalid_action = {
		"type": "deploy",
		"card": "giant",
		"position": Vector2(500, 100),  # Invalid position (enemy territory)
		"predicted": true,
		"sequence": 2
	}

	client1.predict_action(invalid_action)
	assert_true(client1.has_predicted_unit("giant"))

	# Server rejects
	await simulate_network_delay()
	var rejection = {
		"sequence": 2,
		"approved": false,
		"reason": "invalid_position"
	}

	server.send_validation(rejection)

	# Client rolls back
	await simulate_network_delay()
	client1.receive_validation(rejection)
	client1.rollback_action(invalid_action)

	assert_false(client1.has_predicted_unit("giant"))
	assert_false(client1.has_confirmed_unit("giant"))

func test_lag_compensation() -> void:
	# Record client latency
	var ping_start = Time.get_ticks_msec()
	client1.send_ping()

	await simulate_network_delay()
	server.receive_ping()
	server.send_pong()

	await simulate_network_delay()
	var ping_end = Time.get_ticks_msec()
	var round_trip = ping_end - ping_start
	var latency = round_trip / 2

	assert_in_range(latency, 45, 55)  # Should be around 50ms

	# Server compensates for lag when processing actions
	var action = {
		"client_timestamp": Time.get_ticks_msec() - latency,
		"position": Vector2(500, 400),
		"velocity": Vector2(0, -50)  # Moving up
	}

	# Server extrapolates position based on latency
	var compensated_position = action.position + (action.velocity * (latency / 1000.0))
	assert_not_equal(action.position, compensated_position)

func test_state_synchronization() -> void:
	# Server maintains authoritative state
	var server_state = {
		"match_time": 180,
		"player1_elixir": 7.5,
		"player2_elixir": 8.0,
		"player1_crowns": 0,
		"player2_crowns": 1,
		"units": [
			{"id": 1, "type": "knight", "position": Vector2(500, 300), "health": 800},
			{"id": 2, "type": "archer", "position": Vector2(450, 350), "health": 200}
		]
	}

	# Periodic state sync
	server.broadcast_state(server_state)

	await simulate_network_delay()

	# Clients update their state
	client1.sync_state(server_state)
	client2.sync_state(server_state)

	# Verify synchronization
	assert_equal(180, client1.match_time)
	assert_equal(180, client2.match_time)
	assert_equal(7.5, client1.my_elixir)
	assert_equal(8.0, client2.my_elixir)

func test_reconnection_handling() -> void:
	# Client disconnects
	client1.disconnect()
	assert_false(client1.is_connected)

	# Server marks player as disconnected
	server.mark_player_disconnected("player1")
	assert_true(server.is_player_disconnected("player1"))

	# Continue game with AI or pause
	server.start_disconnect_timer("player1", 5.0)  # 5 second grace period

	# Client reconnects
	await simulate_time(2.0)  # Reconnect after 2 seconds
	client1.reconnect()

	# Server sends full state update
	var full_state = server.get_full_state()
	client1.receive_full_state(full_state)

	# Client is back in sync
	assert_true(client1.is_connected)
	assert_false(server.is_player_disconnected("player1"))

func test_packet_loss_handling() -> void:
	# Enable packet loss simulation
	network_manager.packet_loss = 0.1  # 10% packet loss

	var sent_actions = []
	var received_actions = []

	# Send 10 actions
	for i in 10:
		var action = {
			"sequence": i,
			"type": "deploy",
			"card": "skeleton"
		}
		sent_actions.append(action)
		client1.send_reliable(action)  # Reliable transmission

	# Simulate network with packet loss
	await simulate_network_delay()

	# Server should eventually receive all (with retransmission)
	for i in 10:
		var received = server.receive_with_retransmission()
		if received:
			received_actions.append(received)

	# All actions should arrive (reliable transmission)
	assert_equal(sent_actions.size(), received_actions.size())

func test_spectator_sync() -> void:
	# Add spectator client
	var spectator = create_mock_client("spectator")
	spectator.is_spectator = true

	# Spectator receives all updates with delay
	var action = {
		"type": "deploy",
		"card": "wizard",
		"timestamp": Time.get_ticks_msec()
	}

	server.broadcast_action(action)

	# Normal clients receive immediately
	await simulate_network_delay()
	assert_not_null(client1.receive_broadcast())

	# Spectator has additional delay (e.g., 2 seconds)
	await simulate_time(2.0)
	var spectator_received = spectator.receive_broadcast()
	assert_not_null(spectator_received)
	assert_equal("wizard", spectator_received.card)

	spectator.queue_free()

func test_bandwidth_optimization() -> void:
	# Test delta compression
	var full_state = {
		"units": [],
		"size": 1024  # bytes
	}

	var delta_update = {
		"changes": [
			{"id": 1, "position": Vector2(510, 300)}  # Only position changed
		],
		"size": 64  # Much smaller
	}

	assert_less(delta_update.size, full_state.size)

	# Test update frequency throttling
	var update_rate = 10  # 10 updates per second max
	var time_between_updates = 1.0 / update_rate

	var last_update = 0.0
	var current_time = 0.1
	var can_send = (current_time - last_update) >= time_between_updates

	assert_true(can_send)

func test_input_buffering() -> void:
	# Client buffers inputs during high latency
	client1.input_buffer = []

	# Queue multiple actions quickly
	for i in 3:
		var action = {
			"sequence": i,
			"type": "deploy",
			"card": "goblin",
			"timestamp": Time.get_ticks_msec() + i * 100
		}
		client1.buffer_input(action)

	assert_equal(3, client1.input_buffer.size())

	# Send buffered inputs when connection improves
	client1.flush_input_buffer()

	await simulate_network_delay()

	# Server processes buffered inputs in order
	for i in 3:
		var received = server.receive_action()
		assert_equal(i, received.sequence)

# Helper functions
func create_mock_client(id: String) -> Node:
	var client = Node.new()
	client.player_id = id
	client.is_connected = true
	client.predicted_actions = {}
	client.confirmed_actions = {}
	client.my_elixir = 5.0
	client.match_time = 180
	client.is_spectator = false
	client.input_buffer = []

	client.send_action = func(action): pass
	client.receive_broadcast = func(): return {}
	client.predict_action = func(action):
		client.predicted_actions[action.card] = action
	client.has_predicted_unit = func(card):
		return client.predicted_actions.has(card)
	client.has_confirmed_unit = func(card):
		return client.confirmed_actions.has(card)
	client.receive_validation = func(validation): pass
	client.rollback_action = func(action):
		client.predicted_actions.erase(action.card)
	client.send_ping = func(): pass
	client.disconnect = func():
		client.is_connected = false
	client.reconnect = func():
		client.is_connected = true
	client.receive_full_state = func(state): pass
	client.sync_state = func(state):
		client.match_time = state.match_time
		if state.has("player1_elixir") and id == "player1":
			client.my_elixir = state.player1_elixir
		elif state.has("player2_elixir") and id == "player2":
			client.my_elixir = state.player2_elixir
	client.send_reliable = func(action): pass
	client.buffer_input = func(action):
		client.input_buffer.append(action)
	client.flush_input_buffer = func():
		client.input_buffer.clear()

	return client

func create_mock_server() -> Node:
	var server = Node.new()
	server.connected_players = {}
	server.disconnected_players = {}
	server.action_queue = []

	server.receive_action = func():
		if server.action_queue.size() > 0:
			return server.action_queue.pop_front()
		return {}
	server.broadcast_action = func(action): pass
	server.send_validation = func(validation): pass
	server.broadcast_state = func(state): pass
	server.mark_player_disconnected = func(player_id):
		server.disconnected_players[player_id] = true
	server.is_player_disconnected = func(player_id):
		return server.disconnected_players.has(player_id)
	server.start_disconnect_timer = func(player_id, timeout): pass
	server.get_full_state = func(): return {}
	server.receive_ping = func(): pass
	server.send_pong = func(): pass
	server.receive_with_retransmission = func(): return {}

	return server

func simulate_network_delay() -> void:
	await get_tree().create_timer(network_manager.latency / 1000.0).timeout

func simulate_time(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout