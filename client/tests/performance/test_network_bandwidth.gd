extends GdUnitTestSuite

class_name TestNetworkBandwidth

var bandwidth_metrics: Dictionary = {}
var packet_sizes: Array = []
var network_simulator: Node

func before_each() -> void:
	bandwidth_metrics.clear()
	packet_sizes.clear()
	network_simulator = create_network_simulator()

func after_each() -> void:
	if network_simulator:
		network_simulator.queue_free()

func test_match_state_packet_size() -> void:
	# Test size of complete match state updates
	var match_state = create_full_match_state()

	# Serialize to bytes
	var serialized = serialize_match_state(match_state)
	var packet_size = serialized.size()
	var size_kb = packet_size / 1024.0

	bandwidth_metrics["full_state_size"] = size_kb
	assert_less(size_kb, 5.0, "Full match state should be under 5KB")
	print("Full match state size: %.2f KB" % size_kb)

	# Test compressed version
	var compressed = serialized.compress(FileAccess.COMPRESSION_GZIP)
	var compressed_kb = compressed.size() / 1024.0
	var compression_ratio = (1.0 - compressed_kb / size_kb) * 100

	bandwidth_metrics["compressed_size"] = compressed_kb
	bandwidth_metrics["compression_ratio"] = compression_ratio
	assert_greater(compression_ratio, 30, "Should achieve >30% compression")
	print("Compressed size: %.2f KB (%.1f%% reduction)" % [compressed_kb, compression_ratio])

func test_action_packet_size() -> void:
	# Test individual action packet sizes
	var actions = [
		create_deploy_action("knight", Vector2(500, 400)),
		create_spell_action("fireball", Vector2(500, 200)),
		create_emote_action("laugh")
	]

	for action in actions:
		var serialized = serialize_action(action)
		var size_bytes = serialized.size()
		packet_sizes.append(size_bytes)

		assert_less(size_bytes, 256, "%s action should be under 256 bytes" % action.type)
		print("%s action size: %d bytes" % [action.type, size_bytes])

	var avg_size = packet_sizes.reduce(func(a, b): return a + b) / packet_sizes.size()
	bandwidth_metrics["avg_action_size"] = avg_size

func test_bandwidth_per_second() -> void:
	# Simulate typical match bandwidth usage
	var updates_per_second = 10  # Server tick rate
	var actions_per_second = 2   # Average player actions
	var seconds_to_simulate = 10

	var total_bytes = 0

	for second in seconds_to_simulate:
		# State updates
		for update in updates_per_second:
			var delta_update = create_delta_update()
			total_bytes += serialize_delta(delta_update).size()

		# Player actions
		for action in actions_per_second:
			var player_action = create_random_action()
			total_bytes += serialize_action(player_action).size()

	var avg_bandwidth = total_bytes / seconds_to_simulate
	var bandwidth_kbps = (avg_bandwidth * 8) / 1024.0  # Convert to kilobits per second

	bandwidth_metrics["avg_bandwidth_kbps"] = bandwidth_kbps
	assert_less(bandwidth_kbps, 50, "Average bandwidth should be under 50 kbps")
	print("Average bandwidth: %.2f kbps" % bandwidth_kbps)

func test_peak_bandwidth() -> void:
	# Test peak bandwidth during intense moments
	var peak_duration = 1.0  # 1 second of peak activity
	var peak_updates = 30  # Higher update rate during combat
	var peak_actions = 10  # Rapid unit deployment

	var peak_bytes = 0

	# Simulate peak activity
	for update in peak_updates:
		var state = create_combat_state()
		peak_bytes += serialize_match_state(state).size()

	for action in peak_actions:
		var deploy = create_deploy_action("skeleton", Vector2.ZERO)
		peak_bytes += serialize_action(deploy).size()

	var peak_kbps = (peak_bytes * 8) / 1024.0
	bandwidth_metrics["peak_bandwidth_kbps"] = peak_kbps

	assert_less(peak_kbps, 200, "Peak bandwidth should be under 200 kbps")
	print("Peak bandwidth: %.2f kbps" % peak_kbps)

func test_delta_compression_efficiency() -> void:
	# Test delta update efficiency
	var full_state = create_full_match_state()
	var full_size = serialize_match_state(full_state).size()

	# Create delta with minimal changes
	var delta = {
		"timestamp": Time.get_ticks_msec(),
		"changes": [
			{"unit_id": 1, "position": Vector2(510, 400)},
			{"unit_id": 2, "health": 90}
		]
	}

	var delta_size = serialize_delta(delta).size()
	var efficiency = (1.0 - delta_size / float(full_size)) * 100

	bandwidth_metrics["delta_efficiency"] = efficiency
	assert_greater(efficiency, 80, "Delta updates should be >80% smaller than full state")
	print("Delta compression efficiency: %.1f%%" % efficiency)

func test_message_batching() -> void:
	# Test batching multiple messages
	var individual_total = 0
	var messages = []

	# Create individual messages
	for i in 5:
		var msg = create_random_action()
		messages.append(msg)
		individual_total += serialize_action(msg).size()

	# Create batched message
	var batched = {
		"type": "batch",
		"messages": messages
	}
	var batched_size = serialize_batch(batched).size()

	var batching_overhead = ((batched_size - individual_total) / float(individual_total)) * 100
	bandwidth_metrics["batching_overhead"] = batching_overhead

	assert_less(batching_overhead, 10, "Batching overhead should be <10%")
	print("Batching overhead: %.1f%%" % batching_overhead)

func test_network_protocol_overhead() -> void:
	# Test protocol overhead (headers, checksums, etc.)
	var payload = create_random_bytes(1000)
	var packet = create_network_packet(payload)

	var overhead_bytes = packet.size() - payload.size()
	var overhead_percent = (overhead_bytes / float(payload.size())) * 100

	bandwidth_metrics["protocol_overhead"] = overhead_percent
	assert_less(overhead_percent, 5, "Protocol overhead should be <5%")
	print("Protocol overhead: %.1f%% (%d bytes)" % [overhead_percent, overhead_bytes])

func test_unreliable_vs_reliable_packets() -> void:
	# Compare reliable vs unreliable packet sizes
	var test_data = create_random_bytes(500)

	# Unreliable packet (UDP-like)
	var unreliable = {
		"sequence": 12345,
		"data": test_data
	}
	var unreliable_size = serialize_simple(unreliable).size()

	# Reliable packet (TCP-like, with ACK info)
	var reliable = {
		"sequence": 12345,
		"ack": 12344,
		"ack_bits": 0xFFFF,
		"retry_count": 0,
		"timestamp": Time.get_ticks_msec(),
		"data": test_data
	}
	var reliable_size = serialize_simple(reliable).size()

	var reliability_overhead = reliable_size - unreliable_size
	var overhead_percent = (reliability_overhead / float(unreliable_size)) * 100

	bandwidth_metrics["reliability_overhead"] = overhead_percent
	assert_less(overhead_percent, 15, "Reliability overhead should be <15%")
	print("Reliability overhead: %.1f%% (%d bytes)" % [overhead_percent, reliability_overhead])

func test_spectator_bandwidth() -> void:
	# Test bandwidth for spectator mode
	var spectator_updates = []
	var simulation_time = 5.0

	# Spectators receive all player actions
	for i in int(simulation_time * 2):  # 2 actions per second per player
		spectator_updates.append(create_random_action())
		spectator_updates.append(create_random_action())  # Two players

	# Plus state updates
	for i in int(simulation_time * 10):  # 10 updates per second
		spectator_updates.append(create_delta_update())

	var total_bytes = 0
	for update in spectator_updates:
		total_bytes += serialize_simple(update).size()

	var spectator_kbps = (total_bytes * 8) / (simulation_time * 1024)
	bandwidth_metrics["spectator_bandwidth_kbps"] = spectator_kbps

	assert_less(spectator_kbps, 100, "Spectator bandwidth should be under 100 kbps")
	print("Spectator bandwidth: %.2f kbps" % spectator_kbps)

func test_replay_file_size() -> void:
	# Test replay file sizes
	var replay_data = {
		"metadata": {
			"version": "1.0.0",
			"duration": 180,
			"players": ["Player1", "Player2"],
			"result": "victory"
		},
		"actions": []
	}

	# Simulate 3-minute match
	var actions_per_minute = 60
	for minute in 3:
		for action in actions_per_minute:
			replay_data.actions.append({
				"time": minute * 60 + action,
				"player": randi() % 2,
				"action": create_random_action()
			})

	var serialized = serialize_simple(replay_data)
	var uncompressed_kb = serialized.size() / 1024.0

	var compressed = serialized.compress(FileAccess.COMPRESSION_GZIP)
	var compressed_kb = compressed.size() / 1024.0

	bandwidth_metrics["replay_uncompressed_kb"] = uncompressed_kb
	bandwidth_metrics["replay_compressed_kb"] = compressed_kb

	assert_less(compressed_kb, 100, "Compressed replay should be under 100KB")
	print("Replay size - Uncompressed: %.2f KB, Compressed: %.2f KB" % [uncompressed_kb, compressed_kb])

func test_bandwidth_throttling() -> void:
	# Test bandwidth limiting/throttling
	var max_bandwidth_bps = 10000  # 10KB/s limit
	var messages_to_send = []
	var sent_bytes = 0
	var time_window = 1.0  # 1 second

	# Queue many messages
	for i in 50:
		messages_to_send.append(create_random_action())

	# Simulate sending with throttling
	var messages_sent = 0
	for msg in messages_to_send:
		var msg_size = serialize_action(msg).size()

		if sent_bytes + msg_size <= max_bandwidth_bps:
			sent_bytes += msg_size
			messages_sent += 1
		else:
			break  # Would exceed limit

	var utilization = (sent_bytes / float(max_bandwidth_bps)) * 100
	bandwidth_metrics["bandwidth_utilization"] = utilization

	assert_less_equal(sent_bytes, max_bandwidth_bps, "Should not exceed bandwidth limit")
	assert_greater(utilization, 80, "Should efficiently use available bandwidth")
	print("Bandwidth utilization: %.1f%% (%d/%d messages sent)" % [utilization, messages_sent, messages_to_send.size()])

# Helper functions
func create_network_simulator() -> Node:
	var sim = Node.new()
	sim.set_meta("latency", 50)
	sim.set_meta("packet_loss", 0.01)
	return sim

func create_full_match_state() -> Dictionary:
	return {
		"timestamp": Time.get_ticks_msec(),
		"match_time": 180,
		"player1": {
			"elixir": 7.5,
			"crowns": 1,
			"tower_health": [0, 800, 2000]  # Left destroyed, right damaged, king full
		},
		"player2": {
			"elixir": 8.0,
			"crowns": 0,
			"tower_health": [1000, 1000, 2500]
		},
		"units": []
	}

func create_delta_update() -> Dictionary:
	return {
		"type": "delta",
		"timestamp": Time.get_ticks_msec(),
		"changes": [
			{"entity": "unit_1", "field": "position", "value": Vector2(500, 400)},
			{"entity": "elixir_1", "field": "value", "value": 7.5}
		]
	}

func create_combat_state() -> Dictionary:
	var state = create_full_match_state()
	# Add many units for combat scenario
	for i in 20:
		state.units.append({
			"id": i,
			"type": "knight",
			"position": Vector2(randf() * 1000, randf() * 500),
			"health": randi() % 100 + 50,
			"state": "combat"
		})
	return state

func create_deploy_action(unit_type: String, position: Vector2) -> Dictionary:
	return {
		"type": "deploy",
		"unit": unit_type,
		"position": position,
		"timestamp": Time.get_ticks_msec()
	}

func create_spell_action(spell_type: String, position: Vector2) -> Dictionary:
	return {
		"type": "spell",
		"spell": spell_type,
		"position": position,
		"timestamp": Time.get_ticks_msec()
	}

func create_emote_action(emote: String) -> Dictionary:
	return {
		"type": "emote",
		"emote": emote,
		"timestamp": Time.get_ticks_msec()
	}

func create_random_action() -> Dictionary:
	var actions = [
		create_deploy_action("knight", Vector2(randf() * 1000, randf() * 500)),
		create_spell_action("arrow", Vector2(randf() * 1000, randf() * 500)),
		create_emote_action("thumbs_up")
	]
	return actions[randi() % actions.size()]

func create_random_bytes(size: int) -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(size)
	for i in size:
		bytes[i] = randi() % 256
	return bytes

func create_network_packet(payload: PackedByteArray) -> PackedByteArray:
	var packet = PackedByteArray()

	# Add header (8 bytes)
	packet.append_array([0x42, 0x43])  # Magic number "BC"
	packet.append(1)  # Version
	packet.append(0)  # Flags
	packet.append_array(var_to_bytes(payload.size()))  # Payload size (4 bytes)

	# Add payload
	packet.append_array(payload)

	# Add checksum (4 bytes)
	var checksum = calculate_checksum(payload)
	packet.append_array(var_to_bytes(checksum))

	return packet

func calculate_checksum(data: PackedByteArray) -> int:
	var sum = 0
	for byte in data:
		sum = (sum + byte) % 0xFFFFFFFF
	return sum

func serialize_match_state(state: Dictionary) -> PackedByteArray:
	return var_to_bytes(state)

func serialize_action(action: Dictionary) -> PackedByteArray:
	return var_to_bytes(action)

func serialize_delta(delta: Dictionary) -> PackedByteArray:
	return var_to_bytes(delta)

func serialize_batch(batch: Dictionary) -> PackedByteArray:
	return var_to_bytes(batch)

func serialize_simple(data) -> PackedByteArray:
	return var_to_bytes(data)